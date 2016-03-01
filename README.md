# wua_updater

## Description
Cookbook for installing windows updates. The [existing wsus-client cookbok](https://github.com/criteo-cookbooks/wsus-client)
provides an lwrp for downloading and installing windows updates, however it doesnt work when launched via winrm
(as from test-kitchen or chef-provisioning).
This cookboook attempts to get around the built-in remote patching limitation by creating and executing a scheduled task
to do the patching.  The recipe copies a powershell script, creates a scheduled task to run it, launches the task, waits
for it to complete, and reboots the machine if required.


This recipe is based around Matt Wrocks 
[excellent blog post](http://www.hurryupandwait.io/blog/safely-running-windows-automation-operations-that-typically-fail-over-winrm-or-powershell-remoting?rq=windows%20updates)
and [Boxstarter code](https://github.com/mwrock/boxstarter/blob/master/BoxStarter.Common/Invoke-FromTask.ps1)


This is a **work in progess** but please feel free to fork and contribute!

