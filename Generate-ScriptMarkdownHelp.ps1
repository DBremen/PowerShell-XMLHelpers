function Get-FunctionFromScript {
    [CmdletBinding(DefaultParameterSetName='File')]
    [OutputType([ScriptBlock], [PSObject])]
    param(
    # The script block containing functions
    [Parameter(Mandatory=$true,
        Position=0,
        ParameterSetName="ScriptBlock",
        ValueFromPipelineByPropertyName=$true)]    
    [ScriptBlock]
    $ScriptBlock,
    
    # A file containing functions
    [Parameter(Mandatory=$true,
        ParameterSetName="File",
        ValueFromPipelineByPropertyName=$true)]           
    [Alias('FullName')]
    [String]
    $File,
    
    # If set, outputs the command metadatas
    [switch]
    $OutputMetaData
    )
    
    process {
        if ($psCmdlet.ParameterSetName -eq "File") {
            #region Resolve the file, create a script block, and pass the data down
            $realFile = Get-Item $File
            if (-not $realFile) {
                $realFile = Get-Item -LiteralPath $File -ErrorAction SilentlyContinue
                if (-not $realFile) { 
                    return
                }
            }
            $text = [IO.File]::ReadAllText($realFile.Fullname)
            $scriptBlock = [ScriptBlock]::Create($text)
            if ($scriptBlock) {
                $functionsInScript = 
                    Get-FunctionFromScript -ScriptBlock $scriptBlock -OutputMetaData:$OutputMetaData                    
                if ($OutputMetaData) 
                {
                    $functionsInScript | 
                        Add-Member NoteProperty File $realFile.FullName -PassThru
                }
            } 
            #endregion Resolve the file, create a script block, and pass the data down
        } elseif ($psCmdlet.ParameterSetName -eq "ScriptBlock") {            
            #region Extract out core functions from a Script Block
            $text = $scriptBlock.ToString()
            $tokens = [Management.Automation.PSParser]::Tokenize($scriptBlock, [ref]$null)            
            for ($i = 0; $i -lt $tokens.Count; $i++) {
                if ($tokens[$i].Content -eq "function" -and
                    $tokens[$i].Type -eq "Keyword") {
                    $groupDepth = 0
                    $functionName = $tokens[$i + 1].Content
                    $ii = $i
                    $done = $false
                    while (-not $done) {
                        while ($tokens[$ii] -and $tokens[$ii].Type -ne 'GroupStart') { $ii++ }
                        $groupDepth++
                        while ($groupDepth -and $tokens[$ii]) {
                            $ii++
                            if ($tokens[$ii].Type -eq 'GroupStart') { $groupDepth++ } 
                            if ($tokens[$ii].Type -eq 'GroupEnd') { $groupDepth-- }
                        }
                        if (-not $tokens[$ii]) { break } 
                        if ($tokens[$ii].Content -eq "}") { 
                            $done = $true
                        }
                    }
                    if (-not $tokens[$ii] -or 
                        ($tokens[$ii].Start + $tokens[$ii].Length) -ge $Text.Length) {
                        $chunk = $text.Substring($tokens[$i].Start)
                    } else {
                        $chunk = $text.Substring($tokens[$i].Start, 
                            $tokens[$ii].Start + $tokens[$ii].Length - $tokens[$i].Start)
                    }        
                    if ($OutputMetaData) {
                        New-Object PSObject -Property @{
                            Name = $functionName
                            Definition = [ScriptBlock]::Create($chunk)
                        }                        
                    } else {
                        [ScriptBlock]::Create($chunk)
                    }
                }
            }        
            #endregion Extract out core functions from a Script Block
        }        
    }
}

function Generate-ScriptMarkdownHelp{
    <#    
    .SYNOPSIS
        The function that generated the Markdown help in this repository. (see Example for usage). 
        Generates markdown help for Github for each function containing comment based help (Description not empty) within a folder recursively and a summary table for the main README.md
    .DESCRIPTION
        Functions are extracted via Get-FunctionFromScript, dot sourced and parsed using platyPS.
	.PARAMETER Path
		Path to the folder containing the scripts
	.PARAMETER RepoUrl
        GitHub repository Url
	.EXAMPLE
       #because the functions are dot sourced within the function they are not visible wihtin the global scope
       #therefore the script needs to be called by dot-sourcing itself
       #open console
       . <PATHTOTHISSCRIPT>
       #call the function
       $Path = <PATHTOSCRIPTSTOBEDOCUMENTED>
       . Generate-ScriptMarkdownHelp($Path)
#>
    [CmdletBinding()]
    Param($Path='C:\Scripts\ps1\XML\PowerShell-XMLHelpers', $RepoUrl='https://github.com/DBremen/PowerShell-XMLHelpers')
    $summaryTable = @'
# PowerShell-XMLHelpers
Some functions (by now only one) to make it easier to work with XML through PowerShell

Test-XPath:
![](https://powershellone.files.wordpress.com/2016/03/test-xpath.gif)

| Function | Location | Synopsis | Related Blog Post | Full Documentation |
| --- | --- | --- | --- | --- |
'@
    Import-Module platyps
    $env:path += ";$Path"
    $files = Get-ChildItem $Path -File -Include ('*.ps1') -Recurse
    $htCheck = @{}
    foreach ($file in $files){
        $htCheck[$file.Name]=0
        . "$($file.FullName)"
        $functions = Get-FunctionFromScript -File $file.FullName -OutputMetaData
        foreach ($function in $functions){
            try{
                $help =Get-Help $function.Name | Where-Object {$_.Name -eq $function.Name} -ErrorAction Stop
            }catch{
                continue
            }
            if ($help.description -ne $null){
                $htCheck[$file.Name] += 1
                $link = $help.relatedLinks 
                if ($link){
                    $link = $link.navigationLink.uri | Where-Object {$_ -like '*powershellone*'}
                }
                $mdFile = $function.Name + '.md'
                $location = $("$($file.Directory.Name)\$($file.Name)")
                $summaryTable += "`n| $($function.Name) | $location |$($help.Synopsis.Replace("`n"," ")) | $(if($link){"[Link]($($link.navigationLink.uri))"}) | $("[Link]($RepoUrl/blob/master/docs/$mdFile)") |"
                $documenation = New-MarkdownHelp -Command $function.Name -OutputFolder "$Path\docs" -Force
                $text = (Get-Content -Path $documenation | Select-Object -Skip 6)
                $index = $text.IndexOf('## SYNTAX')
                $text[$index-1] += "`n## Script file`n$location`n"
                if ($link){
                    $index = $text.IndexOf('## SYNTAX')
                    $text[$index-1] += "`n## Related blog post`n$link`n"
                }
                $text | Set-Content $documenation -Force
            }
        }
    }
    $summaryTable | Set-Content "$Path/README.md" -Force
    #sanity check if help file were generated for each script
    [PSCustomObject]$htCheck
}