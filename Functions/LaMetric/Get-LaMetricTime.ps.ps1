function Get-LaMetricTime
{
    <#
    .Synopsis
        Gets LaMetricTime
    .Description
        Gets LaMetricTime devices.
    .Example
        Get-LaMetricTime
    .Link
        Connect-LaMetricTime
    #>
    [CmdletBinding(PositionalBinding=$false,DefaultParameterSetName='ListDevices')]
    [OutputType([PSObject])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="Parameters used as hints for Parameter Sets")]
    param(
    # One or more IP Addresses of LaMetricTime devices.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('LaMetricTimeIPAddress')]
    [IPAddress[]]
    $IPAddress,

    # If set, will get apps from an LaMetric device.
    [Parameter(Mandatory,ParameterSetName='api/v2/device/apps')]
    [Alias('App','Apps','Applications')]
    [switch]
    $Application,

    # If set, will get display settings of an LaMetric Time device
    [Parameter(Mandatory,ParameterSetName='api/v2/device/display')]    
    [switch]
    $Display,

    # If set, will get LaMetric Time notifications
    [Parameter(Mandatory,ParameterSetName='api/v2/device/notifications')]
    [Alias('Notifications')]
    [switch]
    $Notification,

    # If set, will get details about a particular package of an LaMetric Time device.
    [Parameter(Mandatory,ParameterSetName='api/v2/device/apps/$Package',ValueFromPipelineByPropertyName)]    
    [string]
    $Package
    )

    begin {
        if (-not $script:LaMetricTimeCache) {
            $script:LaMetricTimeCache = @{}
        }
        if ($home) {
            $lightScriptRoot = Join-Path $home -ChildPath LightScript
        }
        $friendlyParameterSetNames = @{
            "api/v2/device/apps" = "Application"
            'api/v2/device/apps/$packages' = "Application.Details"            
        }
        $expandPropertiesIn = @("api/v2/device/apps")
    }
    process {
        #region Default to All Devices
        if (-not $IPAddress) { # If no -IPAddress was passed
            if ($home) {
                # Read all .LaMetricTime.clixml files beneath your LightScript directory.
                Get-ChildItem -Path $lightScriptRoot -ErrorAction SilentlyContinue -Filter *.LaMetricTime.clixml -Force |
                    Import-Clixml |                     
                    ForEach-Object {
                        if (-not $_) { return }
                        $laMetricTimeDevice = $_                        
                        $script:LaMetricTimeCache["$($laMetricTimeDevice.IPAddress)"] = $laMetricTimeDevice
                    }
                    
                $IPAddress = $script:LaMetricTimeCache.Keys # The keys of the device cache become the -IPAddress.
            }
            if (-not $IPAddress) { # If we still have no -IPAddress
                Write-Warning "No -IPAddress provided and no cached devices found" # warn
                return # and return.
            }
        }
        #endregion Default to All Devices

        if ($PSCmdlet.ParameterSetName -like 'api*') {
            foreach ($ip in $IPAddress) {
                $ipAndPort = "${ipAddress}:8080"
                $endpoint  = 
                    $ExecutionContext.SessionState.InvokeCommand.ExpandString($PSCmdlet.ParameterSetName) -replace '^api'
                $typename  = 
                    if ($friendlyParameterSetNames[$PSCmdlet.ParameterSetName]) {
                        $friendlyParameterSetNames[$PSCmdlet.ParameterSetName]
                    } else { 
                        $lastSegment = @($endpoint -split '/')[-1]
                        ($lastSegment.Substring(0,1).ToUpper() + $lastSegment.Substring(1)) -replace 's$'
                    }
                #region Connect to the Device
                
                http://$ipAndPort/api/$endpoint -Headers @{
                    Authorization = "Basic $laMetricB64Key"
                } |
                    & { process {
                        $out = $_
                        if ($expandPropertiesIn -contains $PSCmdlet.ParameterSetName) {
                            foreach ($prop in $out.psobject.properties) {
                                $prop.value.pstypenames.clear()
                                $prop.value.pstypenames.add("LaMetric.Time.$typeName")
                                $prop.value
                            }
                        } else {
                            $out.pstypenames.clear()
                            $out.pstypenames.add("LaMetric.Time.$typename")
                            $out
                        }
                        
                    } }
            }
        } 
        elseif ($PSCmdlet.ParameterSetName -eq 'ListDevices') {
            $script:LaMetricTimeCache.Values
        }
    }
}

