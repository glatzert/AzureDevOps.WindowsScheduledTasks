#Requires -Version 3.0
# Requires -RunAsAdministrator # Commented out because this directive was introduced in PowerShell v4 and we want to be compatible with v3.

function Install-WindowsScheduledTask
{
	[CmdletBinding(DefaultParameterSetName='Inline')]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to install.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler where the Windows Scheduled Task should be installed.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$true,HelpMessage="The username of the account that should be used to run the Scheduled Task.")]
		[ValidateNotNull()]
		[string] $AccountToRunScheduledTaskAsUsername,

		[parameter(Mandatory=$false,HelpMessage="The password of the account that should be used to run the Scheduled Task.")]
		[string] $AccountToRunScheduledTaskAsPassword,

		[parameter(ParameterSetName="Xml",Mandatory=$true,HelpMessage="The path to the XML file containing the Scheduled Task definition.")]
		[string] $Xml,

		[parameter(ParameterSetName="Inline",Mandatory=$false,HelpMessage="The description for the Scheduled Task.")]
		[string] $ScheduledTaskDescription,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task action.")]
		[ValidateNotNull()]
		[CimInstance[]] $ScheduledTaskAction,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task settings.")]
		[ValidateNotNull()]
		[CimInstance] $ScheduledTaskSettings,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task trigger.")]
		[ValidateNotNull()]
		[CimInstance[]] $ScheduledTaskTrigger,

		[parameter(ParameterSetName="Inline",Mandatory=$true,HelpMessage="The Scheduled Task run level (i.e. admin or regular user).")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskRunLevel,

		[parameter(Mandatory=$false,HelpMessage="If the Scheduled Task should be ran immediately after installation or not.")]
		[bool] $ShouldScheduledTaskRunAfterInstall,

		[parameter(Mandatory = $false, HelpMessage = "The settings used to connect to remote computers.")]
		[hashtable] $WinRmSettings
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskPath = $ScheduledTaskPath
			ScheduledTaskDescription = $ScheduledTaskDescription
			AccountToRunScheduledTaskAsUsername = $AccountToRunScheduledTaskAsUsername
			AccountToRunScheduledTaskAsPassword = $AccountToRunScheduledTaskAsPassword
			Xml = $Xml
			ScheduledTaskAction = $ScheduledTaskAction
			ScheduledTaskSettings = $ScheduledTaskSettings
			ScheduledTaskTrigger = $ScheduledTaskTrigger
			ScheduledTaskRunLevel = $ScheduledTaskRunLevel
			ShouldRunScheduledTaskAfterInstallation = $ShouldScheduledTaskRunAfterInstall
		}

		Invoke-InstallWindowsScheduledTaskOnComputers -scheduledTaskSettings $scheduledTaskSettings -winRmSettings $WinRmSettings
	}

	Begin
	{
		# Turn on Strict Mode to help catch syntax-related errors.
		Set-StrictMode -Version Latest

		function Invoke-InstallWindowsScheduledTaskOnComputers([hashtable] $scheduledTaskSettings, [hashtable] $winRmSettings)
		{
			[string] $installTaskCommand = 'Invoke-Command -ScriptBlock $installScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $winRmSettings.Computers -and $winRmSettings.Computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$installTaskCommand += ' -ComputerName $($winRmSettings.Computers)'

				# Only provide the Authentication and SessionOption when connecting to remote computers, otherwise we get an ambiguous parameter set error.
				$installTaskCommand += ' -Authentication $($winRmSettings.AuthenticationMechanism) -SessionOption $($winRmSettings.PsSessionOptions)'
			}

			[bool] $credentialWasSpecified = ($null -ne $winRmSettings.Credential)
			if ($credentialWasSpecified)
			{
				$installTaskCommand += ' -Credential $($winRmSettings.Credential)'
			}

			if ($winRmSettings.UseSsl)
			{
				$installTaskCommand += ' -UseSSL'
			}

			Write-Debug "About to invoke expression '$installTaskCommand'."
			Invoke-Expression -Command $installTaskCommand -Verbose
		}

		[scriptblock] $installScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			[bool] $installFromXml = !([string]::IsNullOrWhiteSpace($scheduledTaskSettings.Xml))
			[string] $taskPathAndName = $scheduledTaskSettings.ScheduledTaskPath + $scheduledTaskSettings.ScheduledTaskName
			[bool] $userWasSupplied = !([string]::IsNullOrWhiteSpace($scheduledTaskSettings.AccountToRunScheduledTaskAsUsername))
			[bool] $passwordWasSupplied = !([string]::IsNullOrEmpty($scheduledTaskSettings.AccountToRunScheduledTaskAsPassword))

			# An empty description will fail the Register-ScheduledTask parameter validation, so make it a space if it's empty.
			if ([string]::IsNullOrEmpty($scheduledTaskSettings.ScheduledTaskDescription))
			{
				$scheduledTaskSettings.ScheduledTaskDescription = ' '
			}

			$scheduledTask = $null
			$installError = $null

			$registerParams = @{
				TaskName = $scheduledTaskSettings.ScheduledTaskName;
				TaskPath = $scheduledTaskSettings.ScheduledTaskPath;
				Force = $true;
			}

			if($userWasSupplied) {
				$registerParams.Add("User", $scheduledTaskSettings.AccountToRunScheduledTaskAsUsername)

				if($passwordWasSupplied) {
					$registerParams.Add("Password", $scheduledTaskSettings.AccountToRunScheduledTaskAsPassword)
				}
			}

			if($installFromXml) {
				Write-Output "Installing Scheduled Task '$taskPathAndName' on computer '$computerName' using specifed XML definition." -Verbose
				$registerParams.Add("Xml", $scheduledTaskSettings.Xml)
			} 
			else {
				Write-Output "Installing Scheduled Task '$taskPathAndName' on computer '$computerName' using inline definition." -Verbose
				$registerParams.Add("Description", $scheduledTaskSettings.ScheduledTaskDescription)
				$registerParams.Add("Action", $scheduledTaskSettings.ScheduledTaskAction)
				$registerParams.Add("Settings", $scheduledTaskSettings.ScheduledTaskSettings)
				$registerParams.Add("Trigger", $scheduledTaskSettings.ScheduledTaskTrigger)
				$registerParams.Add("RunLevel", $scheduledTaskSettings.ScheduledTaskRunLevel)
			}
			
			$scheduledTask = Register-ScheduledTask @registerParams -ErrorVariable installError -ErrorAction SilentlyContinue

			# If an error occurred installing the Scheduled Task, throw the error before trying to start the task.
			if ($installError)
			{
				throw "Error occurred installing task '$taskPathAndName' on computer '$computerName': '$installError'."
			}

			if ($scheduledTaskSettings.ShouldRunScheduledTaskAfterInstallation)
			{
				Write-Verbose "Triggering the Scheduled Task '$taskPathAndName' on computer '$computerName' to run now." -Verbose
				$scheduledTask | Start-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Install-WindowsScheduledTask
