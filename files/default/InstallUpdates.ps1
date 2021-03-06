$Criteria = "IsInstalled=0 and Type='Software'"

write-output "----------------------"	
write-output "Searching for updates..."
$Searcher = New-Object -ComObject Microsoft.Update.Searcher
$SearchResult = $Searcher.Search($Criteria).Updates
if($SearchResult.count -eq 0) {
	write-output "This system appears to be fully patched!!!!"
	write-output "Install ResultCode: 2"
	write-output "Reboot Required: False"
} else {
	write-output "The following updates will be downloaded and installed:"
	$SearchResult | % {
		write-output $_.Title
		if(!($_.EulaAccepted)) { 	
			$_.AcceptEula() 
		}
	}
	
	write-output "----------------------"	
	write-output "Downloading updates..."
	$Session = New-Object -ComObject Microsoft.Update.Session
	$Downloader = $Session.CreateUpdateDownloader()
	$Downloader.Updates = $SearchResult
	$download_result = $Downloader.Download()
	
	write-output "Download HResult: $($download_result.HResult)"
	write-output "Download ResultCode: $($download_result.ResultCode)"
	
	write-output "----------------------"	
	write-output "Installing updates..."
	$Installer = New-Object -ComObject Microsoft.Update.Installer
	$Installer.ForceQuiet = $true
	$Installer.Updates = $SearchResult
	
	#install_result -> 2 = Succeeded, 3 = Succeeded with Errors, 4 = Failed, 5 = Aborted
	$install_result = $Installer.Install()
	
	write-output "Install HResult: $($install_result.HResult)"
	write-output "Install ResultCode: $($install_result.ResultCode)"
	write-output "Reboot Required: $($install_result.RebootRequired)"
}
