#Requires -Version 3.0
#Requires -RunAsAdministrator

function Start-WindowsScheduledTask
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory=$true,HelpMessage="The name of the Windows Scheduled Task to start.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskName,

		[parameter(Mandatory=$true,HelpMessage="The path in the Task Scheduler of the Windows Scheduled Task to be started.")]
		[ValidateNotNullOrEmpty()]
		[string] $ScheduledTaskPath,

		[parameter(Mandatory=$false,HelpMessage="List of the computer(s) to start the scheduled task on. If null localhost will be used.")]
		[string[]] $ComputerName,

		[parameter(Mandatory=$false,HelpMessage="The credential to use to connect to the computer(s).")]
		[PSCredential] $Credential,

		[parameter(Mandatory=$false,HelpMessage="If CredSSP should be used when connecting to remote computers or not.")]
		[bool] $UseCredSsp
	)

	Process
	{
		[hashtable] $scheduledTaskSettings = @{
			ScheduledTaskName = $ScheduledTaskName
			ScheduledTaskPath = $ScheduledTaskPath
		}

		Invoke-StartWindowsScheduledTaskFromComputers -scheduledTaskSettings $scheduledTaskSettings -computers $ComputerName -credential $Credential -useCredSsp $UseCredSsp
	}

	Begin
	{
		function Invoke-StartWindowsScheduledTaskFromComputers([hashtable] $scheduledTaskSettings, [string[]] $computers, [PSCredential] $credential, [bool] $useCredSsp)
		{
			[string] $startTaskCommand = 'Invoke-Command -ScriptBlock $startScheduledTaskScriptBlock -ArgumentList $scheduledTaskSettings -Verbose'

			[bool] $computersWereSpecified = ($null -ne $computers -and $computers.Count -gt 0)
			if ($computersWereSpecified)
			{
				$startTaskCommand += ' -ComputerName $computers'
			}

			[bool] $credentialWasSpecified = ($null -ne $credential)
			if ($credentialWasSpecified)
			{
				$startTaskCommand += ' -Credential $credential'
			}

			if ($useCredSsp)
			{
				$startTaskCommand += ' -Authentication Credssp'
			}

			[string] $startTaskCommandWithVariablesExpanded = $ExecutionContext.InvokeCommand.ExpandString($startTaskCommand)
			Write-Debug "About to invoke expression '$startTaskCommandWithVariablesExpanded'."
			Invoke-Expression -Command $startTaskCommand -Verbose
		}

		[scriptblock] $startScheduledTaskScriptBlock = {
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
				Write-Warning "A Scheduled Task matching the path and name '$taskPathAndName' was not found on computer '$computerName', so no scheduled tasks will be started."
				return
			}

			foreach ($task in $tasks)
			{
				[string] $taskPathAndName = $task.TaskPath + $task.TaskName
				Write-Output "Starting Scheduled Task '$taskPathAndName' on computer '$computerName'."
				$startError = $null
				$task | Start-ScheduledTask -ErrorVariable startError -ErrorAction SilentlyContinue

				if ($startError)
				{
					throw "An error occurred while trying to start the Scheduled Task '$taskPathAndName' on computer '$computerName': '$startError'."
				}
			}
		}
	}
}

Export-ModuleMember -Function Start-WindowsScheduledTask