# Test-XPath

## SYNOPSIS
Learning aid for XPath expression.
Visualize XPath expression using a windows forms application that shows the XML in a tree view.

## Script file
PowerShellScripts\Generate-ScriptMarkdownHelp.ps1

## Related blog post
https://powershellone.wordpress.com/2016/03/14/powershell-and-xml-part-1-visualize-xpath-expression/

## SYNTAX

```
Test-XPath [[-XML] <XmlDocument>]
```

## DESCRIPTION
Test-XPath loads XML into a tree-view and provides a combobox to type an XPath expression that is used to query parts of the XML, 
matching XML nodes are then highlighted within the tree-view. 
If no XML argument is provided Test-XPath will load the mentioned inventory.XML and populate the combobox with most of the example XPath expressions
from the Microsoft XPath reference.
Test-XPath will hopefully help you to get a better grasp of XPath by example

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
#start the GUI with the example XML
```

Test-XPath

## PARAMETERS

### -XML
XML to load into the tree view of the GUI.
Defaults to load the example xml inside the \data sub-folder (Get-Content "$PSScriptRoot\data\inventory.xml" -Raw).

```yaml
Type: XmlDocument
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Get-Content "$PSScriptRoot\data\inventory.xml" -Raw)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://powershellone.wordpress.com/2016/03/14/powershell-and-xml-part-1-visualize-xpath-expression/](https://powershellone.wordpress.com/2016/03/14/powershell-and-xml-part-1-visualize-xpath-expression/)

[https://msdn.microsoft.com/en-us/library/ms256471%28v=vs.110%29.aspx](https://msdn.microsoft.com/en-us/library/ms256471%28v=vs.110%29.aspx)

