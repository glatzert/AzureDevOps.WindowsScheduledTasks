# Windows Scheduled Tasks Azure DevOps Extension

This is an extension for Azure DevOps (i.e. TFS) that allows Windows Scheduled Tasks to easily be installed and uninstalled on the local or remote computer(s).

Current build status: [![Build Status](https://dev.azure.com/deadlydog/AzureDevOps.WindowsScheduledTasks/_apis/build/status/AzureDevOps.WindowsScheduledTasks?branchName=master)](https://dev.azure.com/deadlydog/AzureDevOps.WindowsScheduledTasks/_build/latest?definitionId=17&branchName=master)


## Features

* Install a Windows Scheduled Task by specifying properties inline or from an XML file.
* Replace an existing Windows Scheduled Task by overwriting it.
* Uninstall a Windows Scheduled Task.
  * Supports wildcards for removing many Schedules Tasks easily, or when you only know part of the Scheduled Task's name.
* Multiple computers can be specified to easily run the task against all of them.
* Supports connecting to remote computers via WinRM and optionally using [CredSSP][CredSspDocumentationUrl].


## Remote computer requirements

Windows PowerShell uses WinRM to connect to remote computers, and the PowerShell cmdlets used by this task require PowerShell v3.0. In short, this means the remote computer must meet at least these requirements:

* Have PowerShell v3.0 or later installed.
* Have Microsoft .Net 4.0 or later installed.
* Have Windows Remote Management 3.0 or later installed.
* You may need to enable PowerShell Remoting on the remote computer by running `Enable-PSRemoting` from an administrator PowerShell command prompt.

For more information, [read Microsoft's documentation][PowerShellRemotingRequirementsDocumentationUrl].


## Defining the Scheduled Task definition properties inline vs. using an XML file

Reasons you may want to define all of the properties inline in the Build/Release task:

* Convenience and ease of use.
* No need to include an XML file in your source control or build artifacts for the deployment to use.

Reasons you may want to use an XML file instead:

* Not all Scheduled Task properties can be specified inline. If you want to configure properties that are not available inline, you _must_ use an XML file.
* Using an XML file allows you to have the Scheduled Task definition committed to source control so you can track changes to it.

When using an XML file you will still need to define inline the `Scheduled Task Name` and `User To Run As`.

### How to create your Scheduled Task XML definition file

If your Scheduled Task already exists in the Windows `Task Scheduler`, simply right-click on the Scheduled Task and choose `Export`.

![Export Windows Scheduled Task screenshot][ExportWindowsScheduledTaskScreenshotImage]

If your Scheduled Task does not already exist, create a new Scheduled Task in the Windows `Task Scheduler`, configure it the way you want, test it (if possible), and the export the XML file.

If you prefer, you can also export the Scheduled Task via [the `Export-ScheduledTask` PowerShell cmdlet][PowerShellExportScheduledTaskDocumentationUrl].


## Implementation

Under the hood this extension uses the [PowerShell ScheduledTasks cmdlets][PowerShellScheduledTasksDocumentationUrl], so the functionality it can offer is limited to what those cmdlets provide. This also means that the target computer must have at least PowerShell v3.0 installed in order for the cmdlets to be present.


## Additional ideas to implement

* Allow task to be deleted immediately after installing it and running it.
* Support task having multiple actions when specifying properties inline.


## Donate

Buy me some maple syrup for providing this extension for free :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=SW7LX32CWQJKN)


<!-- Links -->
[PowerShellScheduledTasksDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/?view=win10-ps
[PowerShellExportScheduledTaskDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/export-scheduledtask?view=win10-ps
[CredSspDocumentationUrl]: https://docs.microsoft.com/en-us/windows/desktop/secauthn/credential-security-support-provider
[PowerShellRemotingRequirementsDocumentationUrl]: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_requirements?view=powershell-6
[ExportWindowsScheduledTaskScreenshotImage]: src/Images/ExportWindowsScheduledTaskScreenshot.png