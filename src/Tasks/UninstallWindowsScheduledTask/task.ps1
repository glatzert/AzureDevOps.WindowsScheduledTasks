param
(
	[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to uninstall.")]
	[ValidateNotNullOrEmpty()]
	[string] $ScheduledTaskName,

	[parameter(Mandatory=$false,HelpMessage="Comma-separated list of the computer(s) to uninstall the scheduled task from.")]
	[ValidateNotNullOrEmpty()]
	[string] $ComputerNames,

	[parameter(Mandatory=$false,HelpMessage="The username to use to connect to the computer(s).")]
	[string] $Username,

	[parameter(Mandatory=$false,HelpMessage="The password to use to connect to the computer(s).")]
	[string] $Password
)

Process
{
	Write-Verbose "About to attempt to uninstall Windows Scheduled Task '$ScheduledTaskName' on '$ComputerNames'." -Verbose

	[string[]] $computers = Get-ComputersToConnectToOrNull -computerNames $ComputerNames
	[PSCredential] $credential = Convert-UsernameAndPasswordToCredentialsOrNull -username $Username -password $Password

	Uninstall-WindowsScheduledTask -ScheduledTaskName $ScheduledTaskName -ComputerName $computers -Credential $credential
}

Begin
{
	# Build paths to files/modules to import, and then import them.
	$THIS_SCRIPTS_DIRECTORY_PATH = $PSScriptRoot
	$srcDirectoryPath = Split-Path -Path (Split-Path -Path $THIS_SCRIPTS_DIRECTORY_PATH -Parent) -Parent
	$codeDirectoryPath = Join-Path -Path $srcDirectoryPath -ChildPath 'Code'

	$utilitiesFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Utilities.ps1'
	Write-Verbose "Importing file '$utilitiesFilePath'." -Verbose
	. $utilitiesFilePath

	$uninstallWindowsScheduledTaskFilePath = Join-Path -Path $codeDirectoryPath -ChildPath 'Uninstall-WindowsScheduledTask.psm1'
	Write-Verbose "Importing module '$uninstallWindowsScheduledTaskFilePath'." -Verbose
	Import-Module -Name $uninstallWindowsScheduledTaskFilePath -Force
}