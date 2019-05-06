#Requires -Version 3.0
#Requires -RunAsAdministrator

function Disable-WindowsScheduledTask
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to disable.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be disabled.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$false,HelpMessage="The settings used to connect to the remote computers.")]
		[hashtable] $WinRmSettings
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskPath = $ScheduledTaskPath
		}

		Invoke-DisableWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -winRmSettings $WinRmSettings
	}

	Begin
	{
		function Invoke-DisableWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [hashtable] $winRmSettings)
		{
			[System.Management.Automation.Remoting.PSSessionOption] $sessionOptions = $winRmSettings.PsSessionOptions
			[string] $disableTaskCommand = 'Invoke-Command -ScriptBlock $disableScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -SessionOption $sessionOptions -Verbose'

			[bool] $computersWereSpecified = ($null -ne $winRmSettings.Computers -and $winRmSettings.Computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$disableTaskCommand += ' -ComputerName $computers'
			}
			else
			{
				$disableTaskCommand += ' -ComputerName localhost'
			}

			[bool] $credentialWasSpecified = ($null -ne $winRmSettings.Credential)
			if ($credentialWasSpecified)
			{
				$disableTaskCommand += ' -Credential $credential'
			}

			if ($winRmSettings.UseCredSsp)
			{
				$disableTaskCommand += ' -Authentication Credssp'
			}

			if ($winRmSettings.UseSsl)
			{
				$disableTaskCommand += ' -UseSSL'
			}

			[string] $disableTaskCommandWithVariablesExpanded = $ExecutionContext.InvokeCommand.ExpandString($disableTaskCommand)
			Write-Debug "About to invoke expression '$disableTaskCommandWithVariablesExpanded'."
			Invoke-Expression -Command $disableTaskCommand -Verbose
		}

		[scriptblock] $disableScheduledTaskScriptBlock = {
			param ([hashtable] $scheduledTaskSettings)
			[string] $computerName = $Env:COMPUTERNAME
			[string] $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
			[string] $operatingSystemVersion = [System.Environment]::OSVersion
			[string] $powerShellVersion = $PSVersionTable.PSVersion
			Write-Verbose "Connected to computer '$computerName' as user '$username'. It is running operating system '$operatingSystemVersion' and PowerShell version '$powerShellVersion'." -Verbose

			[string] $taskName = $scheduledTaskSettings.ScheduledTaskName
			[string] $taskPath = $scheduledTaskSettings.ScheduledTaskPath

			Write-Verbose "Searching for a Scheduled Task with the path '$taskPath' and name '$taskName'." -Verbose
			$tasks = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
			if ($null -eq $tasks)
			{
				[string] $taskPathAndName = $taskPath + $taskName
				Write-Warning "A Scheduled Task matching the path and name '$taskPathAndName' was not found on computer '$computerName', so no scheduled tasks will be disabled."
				return
			}

			foreach ($task in $tasks)
			{
				[string] $taskPathAndName = $task.TaskPath + $task.TaskName
				Write-Output "Disabling Scheduled Task '$taskPathAndName' on computer '$computerName'."
				$task | Disable-ScheduledTask
			}
		}
	}
}

Export-ModuleMember -Function Disable-WindowsScheduledTask