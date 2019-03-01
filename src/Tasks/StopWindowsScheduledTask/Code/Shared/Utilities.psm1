# This file should only be modified if it is the one in the `SharedTaskCode` directory.
# Otherwise changes here will be overwritten the next time the Copy Files script is ran.

function Get-ComputersToConnectToOrNull([string] $computerNames)
{
	[string[]] $computers = $computerNames -split '\s*,\s*'

	[bool] $arrayContainsOneBlankElement = ($computers.Count -eq 1 -and [string]::IsNullOrWhiteSpace($computers[0]))
	if ($arrayContainsOneBlankElement)
	{
		$computers = $null
	}

	return $computers
}

function Convert-UsernameAndPasswordToCredentialsOrNull([string] $username, [string] $password)
{
	if ([string]::IsNullOrWhiteSpace($username) -or [string]::IsNullOrWhiteSpace($password))
	{
		return $null
	}

	[SecureString] $securePassword = ($password | ConvertTo-SecureString -AsPlainText -Force)

	$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$securePassword
	return $credential
}

function Get-BoolValueFromString([string] $string, [switch] $required)
{
	if ([string]::IsNullOrWhiteSpace($string) -and $required.IsPresent)
	{
		throw 'A non-empty string must be provided when calling Get-BoolValueFromString.'
	}

	if ($string -ieq 'true')
	{
		return $true
	}
	return $false
}

function Get-XmlStringFromFile([string] $xmlFilePath)
{
	[string] $xml = [string]::Empty
	if (![string]::IsNullOrWhiteSpace($xmlFilePath))
	{
		if (!(Test-Path -Path $xmlFilePath -PathType Leaf))
		{
			throw "Could not find the specified XML file '$xmlFilePath' to read the Scheduled Task definition from."
		}

		Write-Verbose "Reading XML from file '$xmlFilePath'." -Verbose
		$xml = Get-Content -Path $xmlFilePath -Raw
	}
	return $xml
}

Export-ModuleMember -Function Get-ComputersToConnectToOrNull
Export-ModuleMember -Function Convert-UsernameAndPasswordToCredentialsOrNull
Export-ModuleMember -Function Get-BoolValueFromString
Export-ModuleMember -Function Get-XmlStringFromFile