This directory contains LightScript's functions for Divoom's [Pixoo64](https://www.divoom.com/products/pixoo-64).

~~~PipeScript {
    Import-Module ../../LightScript.psd1 -Global
    [PSCustomObject]@{
        Table = Get-Command -Module LightScript | 
            Where-Object { $_.ScriptBlock.File -like "$pwd*" } |
            .Name .Verb .Noun .Source {
                $relativePath = $_.ScriptBlock.File.Substring("$pwd".Length) -replace '^[\\/]'
                "[$relativePath]($relativePath)"
            }
    }
    
}
~~~