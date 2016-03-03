update_script = "#{Chef::Config[:file_cache_path]}\\InstallUpdates.ps1"
task_name = 'CHEF Install Windows Updates'
output_file = "#{ENV['temp']}\\InstalUpdates.out.txt"

cookbook_file update_script do
  source 'InstallUpdates.ps1'
end

windows_task task_name do
  command "powershell #{update_script} > #{output_file}"
  start_time '00:00'
  start_day '10/26/2005'
  action :create
  frequency :once
  run_level :highest
end

powershell_script 'run updates tasks' do
  code <<-EOH
    $escaped_command = '#{update_script}' -replace "\\\\", "\\\\"

    $tasks=@()
    $tasks+=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$($escaped_command)%'" | select ProcessId | % { $_.ProcessId }
    if($tasks.length -gt 0 ) {
      $taskProc = $tasks[0]
      Write-output "Running task found (pid = $($taskProc))...."
    } else {
      $taskResult = schtasks /RUN /I /TN '#{task_name}'
      if($LastExitCode -gt 0){
        throw "Unable to run scheduled task. Message from task was $taskResult"
      }
      Write-output "Launched task. Waiting for task to launch command..." -Verbose
      do{
          # What if its already complete?  how do I check that?
          # Also - add timeout logic just in case????
          $taskProc=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$($escaped_command)%'" | select ProcessId| % { $_.ProcessId } | ? { !($tasks -contains $_) }

          Write-output "sleeping..."
          Start-Sleep -Second 1
      }
      Until($taskProc -ne $null)
    }
    Write-output "script launched with pid: $($taskProc)"
    Write-output "waiting for script to complete...."
    while( get-process | where { $_.id -eq $taskProc }) {
        Write-output "sleeping..."
        Start-Sleep -Second 1
    }
    Write-output "script complete!"

  EOH
  #  not_if { true }
end

#powershell_script 'run updates tasks' do
#  code <<-EOH
#    $escaped_command = '#{update_script}' -replace "\\\\", "\\\\"
#
#    $tasks=@()
#    $tasks+=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$($escaped_command)%'" | select ProcessId | % { $_.ProcessId }
#
#    $taskResult = schtasks /RUN /I /TN '#{task_name}'
#    if($LastExitCode -gt 0){
#        throw "Unable to run scheduled task. Message from task was $taskResult"
#    }
#    Write-output "Launched task. Waiting for task to launch command..." -Verbose
#     do{
#        # What if its already complete?  how do I check that?
#        # Also - add timeout logic just in case????
#        $taskProc=gwmi Win32_Process -Filter "name = 'powershell.exe' and CommandLine like '%$($escaped_command)%'" | select ProcessId| % { $_.ProcessId } | ? { !($tasks -contains $_) }
#
#        Write-output "sleeping..."
#        Start-Sleep -Second 1
#    }
#    Until($taskProc -ne $null)
#
#    Write-output "script launched with pid: $($taskProc)"
#    Write-output "waiting for script to complete...."
#    while( get-process | where { $_.id -eq $taskProc }) {
#        Write-output "sleeping..."
#        Start-Sleep -Second 1
#    }
#    Write-output "script complete!"
#
#  EOH
#  #  not_if { true }
#end

powershell_script 'check return code' do
  code <<-EOH
    ( gc #{output_file} | select-string "Install ResultCode" ) -match "Install ResultCode:\\s+(\\S+)"
    $rc = $Matches[1]

    # 2 = Succeeded, 3 = Succeeded with Errors, 4 = Failed, 5 = Aborted
    switch ($rc)
    {
        2 { write-output "Windows Updates installed successfully" }
        3 { write-output "Windows Updates succeeded but with errors" }
        4 { throw " Error - Windows Updates failed.  ResultCode: $($rc)" }
        5 { throw " Error - Windows Updates aborted.  ResultCode: $($rc)" }
        default { throw " Error - updates did not install correctly.  ResultCode: $($rc)" }
    }
  EOH
end

reboot 'reboot after patch installation' do
  action :request_reboot
  reason 'windows update (run via chef) installed patches that require a reboot'
  delay_mins 1
  guard_interpreter :powershell_script
  only_if <<-EOH
    $output = ( gc #{output_file} | select-string "Reboot Required" ) -match "Reboot Required:\\s+(\\S+)"
    $Matches[1] -eq "True"
  EOH
end
