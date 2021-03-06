################################################################################
# Granite-IT.net Microsoft Word AutoCorrect Importer
# Author: Dan Parr (dparr@granite-it.net)
# Date Modified: May 12 2014
#
# Based On Script From Micrsoft Scripting Guy Blog (2012/06/15): 
# Use PowerShell to Add Bulk AutoCorrect Entries to Word
# http://tinyurl.com/mp6svlt
#
# Syntax Option 1 (Full Automation):
# 	Add Entries to MSWord AutoCorrect:
#	 	.\Update-AutoCorrect.ps1 -path ".\Import.csv" -add 
#	Remove Entries from MSWord AutoCorrect:
#		.\Update-AutoCorrect.ps1 -path ".\Import.csv -remove
#
# Syntax Option 2 (Maunal Selection):
#	Running the Script without cmdline parameters will prompt to select the 
#	import file, And will also prompt to select weather to add or remove the 
#	entries contained in the file
################################################################################



#Collect Command Line Parameters if passed when executing the script
Param(

  [string]$path,

  [switch]$add,

  [switch]$remove)
  
  

Function Set-AutoCorrectEntries{

	Param(

	[string]$path,

	[switch]$add,

	[switch]$remove)

	$entry = Import-Csv -Path $path

	Write-Host "File Selected: $path"
	write-host $entry.length "Entries Have been Imported from the CSV File
	"
	$entry

	$word = New-Object -ComObject word.application

	$word.visible = $false

	$entries = $word.AutoCorrect.entries

	if($add)

	{
	Write-Host " "
	Write-Host "Adding Entries to Word AutoCorrect"
	Foreach($e in $entry)

	{

	 Try

	   { $entries.add($e.replace, $e.with) | out-null }

	 Catch [system.exception]

	   { "unable to add $($e.replace)" }

	 } #end foreach

	}#end if add

	if($remove)

	{
	Write-Host " "
	Write-Host "Removing Entries from Word AutoCorrect"
	$j = 0

	Foreach($e in $entry)

	 { $j = $j+1

	  Write-Progress -Activity "deleting entries" -Status "deleting $($e.replace)" -percentcomplete ($j/$entry.count*100)

	  foreach($i in $entries)

	   {

	    if($i.name -eq $e.replace)

	     { $i.delete() } }

	 } #end foreach entry

	} #end if remove

	$word.Quit()

	$word = $null

	[gc]::collect()

	[gc]::WaitForPendingFinalizers()

	} #end function Set-AutoCorrectEntries

Function Get-FileName($initialDirectory){   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |Out-Null

	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	 
	$OpenFileDialog.initialDirectory = $initialDirectory
	
	$OpenFileDialog.ShowHelp = $true
	 
	$OpenFileDialog.filter = "CSV Files| *.csv"
	
	$OpenFileDialog.ShowDialog() | Out-Null
	 
	$OpenFileDialog.filename
} #end function Get-FileName

Function Verify-WordRunning{

	Return (get-process | where-object {$_.name.tolower() -eq "winword"})

} # end function Verify-WordRunning

Function Collect-MenuChoice {
	Write-Host -ForegroundColor Green "What would you like to do with the Entries In the selected file?
	1. Add The Entries to MS Word AutoCorrect
	2. Remove The Entries To MS Word AutoCorrect
	3. Quit
	
	Please Enter a Number From The List and Press Enter:"
	$MenuChoice = Read-Host
	Write-Host ""
	Return $MenuChoice
	} #end function Collect-MenuChoice

### START MAIN SCRIPT ###
  
clear
Write-Host "################################################################################
Granite-IT.net Microsoft Word AutoCorrect Importer
Author: Dan Parr (dparr@granite-it.net)
Date Modified: May 12 2014

Based On Script From Micrsoft Scripting Guy Blog (2012/06/15): 
Use PowerShell to Add Bulk AutoCorrect Entries to Word
http://tinyurl.com/mp6svlt
################################################################################

"
If (-Not (Verify-WordRunning)){

	Write-Host "Word is not running: Starting Now
	"
	
	start-process winword -windowstyle minimized
	
	}
#Allow User to Browse for CSV File to Import If Path has not been passed as a param 
#Write-Host "The Path is: $path"
if ($path) {

	$Import = $path

	Write-Host -ForegroundColor Green "The Path to CSV File was Passed as a Parameter: 
$Import"

}
Else{


	Write-Host -ForegroundColor Green "You Will Need to Select a CSV File Of AutoCorrect Entries
	
Please Ensure MS Word is Running and Minimized and then Press Enter to Continue"

$x = Read-Host


$Import = Get-FileName -initialDirectory ".\"
}

#Set Initial Value for Menu Selection to 0
$MenuSelection = 0

#Launch Word to allow for Addition or Removal of Autocorrect Entries if not already running.
If (-Not (Verify-WordRunning)){

	Write-Host "Word is not running: Starting Now
	"
	
	start-process winword -windowstyle minimized
	
	}

#Menu Items will appear until a valid Choice is Selected If -add or -remove switches have not been run from command line
if (-not ($add -or $remove)){

	While (($MenuSelection -ne "1") -and ($MenuSelection -ne "2")){

		$MenuSelection = Collect-MenuChoice

		#Abort Script on Quit
		if ($MenuSelection -eq 3){Exit}
		
		If ($MenuSelection -ne "1" -and $MenuSelection -ne "2"){
			Write-Host -ForegroundColor Red "Incorrect Entry you Must Enter A Valid Menu Choice
		"
		}
	}
}

# Use Menu Choice run running Set-AutoCorrectEntries function for add or remove
If (($MenuSelection -eq "1") -or ($add)){
	
	Set-AutoCorrectEntries -Path $Import -add}

Else {

	#Write-Host "2 was selected removing"
	Set-AutoCorrectEntries -Path $Import -remove}

#Close Word to finalize changes
if (Verify-WordRunning){

	Write-Host "
Microsoft Word will now be closed to finish this process.
Please save any unsaved work and then press enter"

	Read-Host

	Get-Process winword | kill
	}

#Start Word for testing
Write-Host "Launching Word for Testing"
start Winword

#End Script