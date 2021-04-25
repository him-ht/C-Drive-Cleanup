<# 
.SYNOPSIS
Automate cleaning up a C:\ drive with low disk space

.DESCRIPTION
Cleans the C: drive's Window Temperary files, Windows SoftwareDistribution folder, 
the local users Temperary folder and empties the recycling bin. 
All deleted files will go into a log transcript in $env:TEMP.

.EXAMPLE
PS C:\> .\C_Drive_Cleanup.ps1
Save the file to your hard drive with a .PS1 extention and run the file from an elavated PowerShell prompt.

.NOTES
This script will typically clean up anywhere from 1GB up to 15GB of space from a C: drive.

.FUNCTIONALITY
PowerShell v3+

.Author
Himanshu Tripathi
#>

$Starters = (Get-Date)
$VMname=Read-host "Enter the Server Name"
$cred=Get-Credential

$logfile="C:\Temp\${VMname}_C_drive_CleanUp_"+ (get-date -format "MM-d-yy-HH-mm") + '.log'
$VerbosePreference = "Continue"
$ErrorActionPreference = "SilentlyContinue"

$a = “#############################################################

          C drive cleanup for Server $VMname started...

#############################################################"

$a.PadLeft( “{0:N0}” -f ((100 – ($a | measure).count)/2),” “)

Write-Host " " 

## Tests if the log file already exists and renames the old file if it does exist
if(Test-Path $LogFile){
	## Renames the log to be .old
	Rename-Item $LogFile $LogFile.old -Verbose -Force
} else {
	## Starts a transcript in C:\temp so you can see which files were deleted
	Write-Host (Start-Transcript -Path $LogFile) -ForegroundColor Green
}

## Gathers the amount of disk space used before running the script
$Before = Get-WmiObject Win32_LogicalDisk -ComputerName $VMname -Filter "DeviceID='C:'" -Credential $cred | Select-Object SystemName,
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f ( $_.Size / 1gb)}},
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f ( $_.Freespace / 1gb ) } },
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f ( $_.FreeSpace / $_.Size ) } } |Format-Table -AutoSize|Out-String 

Write-Host "Retriving current disk percent free for comparison once the script has completed." -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black

Write-Host " "
## Stops the windows update service so that c:\windows\softwaredistribution can be cleaned up
Invoke-Command -ComputerName $VMname -ScriptBlock {Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose} -Credential $cred

Write-Host " "
## Deletes the contents of the Windows Temp folder(Not modified in last 10 days)
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\Windows\Temp\") {
Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue|Where-Object { ($_.LastAccesstime -lt $(Get-Date).AddDays(-1))}| Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "The Contents of Windows Temp have been Older than 10 days removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Windows\Temp\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Deletes the contents of the Windows Temp folder(Not modified in last 180 days)
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\Windows\Logs\") {
Get-ChildItem "C:\Windows\Logs\*" -Recurse -Force -ErrorAction SilentlyContinue|Where-Object { ($_.LastAccesstime -lt $(Get-Date).AddDays(-180))}|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "The Contents of Windows Log have been Older than 180 days removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Windows\Logs\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Deletes the contents of the Windows download folder
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\Windows\SoftwareDistribution\download\") {
Get-ChildItem "C:\Windows\SoftwareDistribution\download\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "The Contents of Windows download have been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Windows\SoftwareDistribution\download\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Deletes all files and folders in user's Temp folder
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\users\*\AppData\Local\Temp\") {
Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-Host "The contents of C:\users\*\AppData\Local\Temp\ have been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\users\*\AppData\Local\Temp\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Removes all files and folders in user's Temporary Internet Files
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\") {
Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-Host "All Temporary Internet Files have been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Removes all files and folders in WER Directory older than 30 days
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\ProgramData\Microsoft\Windows\WER\") {
Get-ChildItem "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue|Where-Object { ($_.Lastwritetime -lt $(Get-Date).AddDays(-30))}|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-Host "All WER files older than 30 days have been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\ProgramData\Microsoft\Windows\WER\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Remove MEMORY.DMP file Older than 60 days
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\Windows\MEMORY.DMP") {
Get-ChildItem "C:\Windows\MEMORY.DMP" -Recurse -Force -ErrorAction SilentlyContinue| Where-Object {($_.Lastwritetime -lt $(Get-Date).AddDays(-60))}|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-Host "MEMORY DUMP older than 60 days has been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Windows\MEMORY.DMP does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Removes all files and folders in MINIDUMP Directory older than 60 days
Invoke-Command -ComputerName $Vmname -ScriptBlock {
if (Test-Path "C:\Windows\Minidump\") {
Get-ChildItem "C:\Windows\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue| Where-Object {($_.Lastwritetime -lt $(Get-Date).AddDays(-60))}|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-Host "All MINIDUMP files older than 60 days have been removed successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Windows\Minidump\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred


Write-Host " "
## Removes all files from Folder IECompatCache
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted IECompatCache files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Removes all files from Folder IECompatUaCache
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted IECompatUaCache files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
	Write-Host "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
	Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred


Write-Host " "
## Removes all files from Folder IEDownloadHistory
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted IEDownloadHistory files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
	Write-Host "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
	Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
} 
} -Credential $cred

Write-Host " "
## Removes all files from Folder INetCache
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted INetCache files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

Write-Host " "
## Removes all files from Folder INetCookies
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted INetCookies files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
	Write-Host "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
	Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred


Write-Host " "
## Removes all files from Folder terminal server cache
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-Path "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\") {
Get-ChildItem "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue|Remove-Item -force -recurse -ErrorAction SilentlyContinue -Verbose
Write-host "Deleted terminal server cache files" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\* does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor Cyan
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

## Removes the hidden recycling bin.
Invoke-Command -ComputerName $VMname -ScriptBlock {
if (Test-path 'C:\$Recycle.Bin'){
Remove-Item 'C:\$Recycle.Bin' -Recurse -Force -Verbose -ErrorAction SilentlyContinue
Write-Host "The 'C:\Recycle.Bin' has been cleaned up successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
} else {
Write-Host "C:\`$Recycle.Bin does not exist, there is nothing to cleanup." -NoNewline -ForegroundColor DarkGray
Write-Host "[WARNING]" -ForegroundColor DarkYellow -BackgroundColor Black
}
} -Credential $cred

## Turns errors back on
$ErrorActionPreference = "Continue"

## Removing desktop Recycle bin
Invoke-Command -ComputerName $VMname -ScriptBlock {
if ($PSVersionTable.PSVersion.Major -le 4) {
$Recycler = (New-Object -ComObject Shell.Application).NameSpace(0xa)
$Recycler.items() | ForEach-Object { 
Remove-Item -Include $_.path -Force -Recurse -Verbose
Write-Host "The recycling bin with Powershell version 4 has been cleaned up successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
}
} elseif ($PSVersionTable.PSVersion.Major -ge 5) {
Clear-RecycleBin -DriveLetter C:\ -Force -Verbose
Write-Host "The recycling bin with Powershell version 5 has been cleaned up successfully!" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
}
} -Credential $cred


## Gathers disk usage after running the cleanup cmdlets.
$After = Get-WmiObject Win32_LogicalDisk -ComputerName $VMname -Filter "DeviceID='C:'" -Credential $cred | Select-Object SystemName,
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f ( $_.Size / 1gb)}},
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f ( $_.Freespace / 1gb ) } },
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f ( $_.FreeSpace / $_.Size ) } } |Format-Table -AutoSize|Out-String 

## Restarts Windows Update service
Invoke-Command -ComputerName $VMname -ScriptBlock {Get-Service -Name wuauserv | Start-Service -ErrorAction SilentlyContinue -Verbose} -Credential $cred
Write-Host " "

## Sends the disk usage before running the cleanup script to the console for ticketing purposes.
Write-Verbose "Before: $Before"
Write-Host " "

## Sends the disk usage after running the cleanup script to the console for ticketing purposes.
Write-Verbose "After: $After"
Write-Host " "

Write-Host (Stop-Transcript) -ForegroundColor Green

Write-host "Script finished" -NoNewline -ForegroundColor Green
Write-Host "[DONE]" -ForegroundColor Green -BackgroundColor Black
