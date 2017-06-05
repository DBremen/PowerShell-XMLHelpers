function Test-XPath {
     <#    
    .SYNOPSIS
       Learning aid for XPath expression. Visualize XPath expression using a windows forms application that shows the XML in a tree view.
    .DESCRIPTION
       Test-XPath loads XML into a tree-view and provides a combobox to type an XPath expression that is used to query parts of the XML, 
       matching XML nodes are then highlighted within the tree-view. 
       If no XML argument is provided Test-XPath will load the mentioned inventory.XML and populate the combobox with most of the example XPath expressions
       from the Microsoft XPath reference. Test-XPath will hopefully help you to get a better grasp of XPath by example
	.PARAMETER XML
		XML to load into the tree view of the GUI. Defaults to load the example xml inside the \data sub-folder (Get-Content "$PSScriptRoot\data\inventory.xml" -Raw).
	.EXAMPLE
        #start the GUI with the example XML
        Test-XPath
    .LINK
        https://powershellone.wordpress.com/2016/03/14/powershell-and-xml-part-1-visualize-xpath-expression/
    .LINK
        https://msdn.microsoft.com/en-us/library/ms256471%28v=vs.110%29.aspx
    #>
    [CmdletBinding()]
    Param(
        [xml]$XML = (Get-Content "$PSScriptRoot\data\inventory.xml" -Raw) 
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.Text = "XML"
    $treeView = New-Object System.Windows.Forms.TreeView
    $tablePanel = New-Object System.Windows.Forms.TableLayoutPanel
    $tablePanel.RowCount = 2
    $tablePanel.ColumnCount = 1
    $tablePanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $comboXPath = New-Object System.Windows.Forms.ComboBox
    #check if we are using the example xml and load the example XPath expressions
    if ($xml.DocumentElement.magazine){
        $items = Import-Csv -Path "$PSScriptroot\data\XPathExamples.csv"
        $comboXPath.Items.AddRange($items.Example)
        $comboXPath.AutoCompleteCustomSource.AddRange($items)
        $comboXPath.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::SuggestAppend
        $comboXPath.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::CustomSource
        #add tooltips http://stackoverflow.com/questions/680373/tooltip-for-each-items-in-a-combo-box
        $toolTip = New-Object System.Windows.Forms.ToolTip
        $comboXPath.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown
        $comboXPath.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
        $htExampleDescription = $items | group Example -AsHashTable -AsString
        $comboXPath.Add_DrawItem({
            if ($_.Index -lt 0) { return } 
            $text = $htExampleDescription."$($this.GetItemText($this.Items[$_.Index]))".Description
            $_.DrawBackground()
            $brush = New-Object System.Drawing.SolidBrush($_.ForeColor)
            $_.Graphics.DrawString($this.GetItemText($this.Items[$_.Index]), $_.Font, $brush, (New-Object System.Drawing.PointF($_.Bounds.X, $_.Bounds.Y)))
            if (($_.State -and [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected){ 
                $toolTip.Show($text, $this, $_.Bounds.Right, $_.Bounds.Bottom)
            }
            $_.DrawFocusRectangle()
        })
        $comboXPath.Add_DropDownClosed({
            $toolTip.Hide($comboXPath)
        })
    }
    
    $comboXPath.Add_KeyDown({
        if ($_.KeyCode -eq 'Enter'){
            function ResetBackColor($nodes) {
                foreach ($node in $nodes){
                    ResetBackColor $node.Nodes
                    $node.BackColor = [System.Drawing.Color]::White
                }
            }
            ResetBackColor $treeView.Nodes 
            try{
                $xml | Select-Xml $comboXPath.Text | foreach { 
                        if (!$_.Node."__id"){ 
                            $_.Node.OwnerElement."__id"
                        }
                        else{
                            $_.Node."__id" 
                        }
                    }  | foreach {
                        $treeview.Nodes.Find($_, $true) | foreach { 
                           $_.BackColor = [System.Drawing.Color]::YellowGreen 
                        }
                    }
            }catch{}
        }
    })
    $comboXPath.Dock = [System.Windows.Forms.DockStyle]::Fill
    $treeView.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tablePanel.Controls.Add($comboXPath , 0, 0)
    $tablePanel.Controls.Add($treeView, 1, 0)
    #$tablePanel.SetColumnSpan($treeView, 2)
    #$null = $tablePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,80)))
    $form.Controls.Add( $tablePanel ) 
    $form.add_Load({
        function AddChildNodes($treeViewNodes , $xml){
            foreach ($childNode in $xml.ChildNodes){
                if ($childNode.LocalName -eq '#text'){
                    $node = $treeViewNodes.Add($childNode.Value)
                    $node.Parent.Collapse()
                    $node.Name = $childNode.Value
                }
                else{
                    $txt = $childNode.LocalName
                    $ht = @{}
                    foreach ($attribute in $childNode.Attributes){
                        $txt += " $($attribute.OuterXml)"
                    }
                    $node = $treeViewNodes.Add($txt)
                    $idVal = [guid]::NewGuid().Guid
                    $childNode.SetAttribute('__id', $idVal)
                    $node.Name = $idVal
                    if ($node.Parent){ $node.Parent.Expand() }
                }
                AddChildNodes $node.Nodes $childNode
            }
        }
        $treeView.Nodes.Clear()
        AddChildNodes $treeView.Nodes $xml
    })
    $form.ShowDialog()| Out-Null
} 
