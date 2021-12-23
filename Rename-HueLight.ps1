function Rename-HueLight
{
    <#
    .Synopsis
        Renames Hue Lights
    .Description
        Renames one or more Hue lights.
    .Example
        Rename-HueLight
    .Link
        Get-HueBridge
    .Link
        Get-HueLight
    #>
    [OutputType([PSObject])]
    param(
    # The old name of the light.  This can be a wildcard or regular expression.
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $OldName,

    # The new name of the light.  A number sign will be replaced with the match number.
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $NewName
    )

    begin {
        $lights = Get-HueLight
        $bridges = Get-HueBridge
    }

    process {
        $lights |
            Where-Object {
                #region Find matching lights
                $_.Name -like $Name
                try {
                    $_.Name -match $Name
                } catch {
                    Write-Verbose "$_"
                }
                #endregion Find matching lights
            } |
            ForEach-Object -Begin {
                $matchCount = 0
            } -Process {
                #region Rename the lights
                $MatchCount++
                $realNewName = $NewName -replace '#', $MatchCount

                $bridges | Send-HueBridge -Command "lights/$($_.Lightid)" -Method PUT -Data @{Name=$realNewName}
                #endregion Rename the lights
            }
    }
}