<#PSScriptInfo
.VERSION 1
.GUID *Use New-Guid to generate new GUID*
.AUTHOR Eric Duncan
.COMPANYNAME kalyeri
.COPYRIGHT
MIT License

Copyright (c) 2024 Eric Duncan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
.TAGS
.LICENSEURI https://mit-license.org/
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.TODO
#>
<#
.SYNOPSIS PS-Template
.DESCRIPTION
.PARAMETER 
.INPUTS
.OUTPUTS
.EXAMPLE
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $False)] [Switch] $UseCfgFile,
	[Parameter(Mandatory = $False)] [String] $cfgFile,
	[Parameter(Mandatory = $False)] [Switch] $TestMode,
	[switch]$WhatIf
)

<# SCRIPT SETUP #>
Clear-Host
[string]$Script:ScriptFile=$MyInvocation.MyCommand.name
[string]$Script:ScriptName=($ScriptFile).replace(".ps1",'')
[string]$Script:ScriptPath=($MyInvocation.MyCommand.Source).replace("\$ScriptFile",'')
if (!($TestMode -and $cfgFile)) {[string]$Script:cfgFile="$ScriptName.cfg.json"}
$script:stopwatch=[system.diagnostics.stopwatch]::startnew() #time script

#Environment checks
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8 #Console output encoding
$Script:IsElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Script:IsSystem = [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem #Check if running account is system
Set-Location $ScriptPath

#TLS Fix
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #TLS fix for older PS
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

<#Log file#>
$scriptlogpath="$ScriptPath\log"
$scriptlogfile="$scriptlogpath\$ScriptName.log"
if (!(test-path $scriptlogpath)) {mkdir $scriptlogpath}
if (test-path $scriptlogfile) {
$logrolldate=(get-date).AddMonths(-1) | get-date -Format yyyyMM
$logdate=(get-childitem $scriptlogfile).LastWriteTime | get-date -Format yyyyMM
if ($logdate -eq $logrolldate) {Rename-Item $scriptlogfile "$scriptlogfile.$logrolldate" -Verbose -Force}
}
try {Stop-Transcript | Out-Null} catch {} #fix log when script is prematurely stopped
Start-Transcript $scriptlogfile -force -Append -NoClobber

<# Configuration File/Variables Load #>
if ($UseCfgFile.IsPresent) {
if (test-path $cfgFile) {
	"Using $cfgFile..."
	$varList=get-content $cfgFile -raw | convertfrom-json -ErrorAction Stop
	foreach ($varSet in $varList.PSObject.Properties) {
		$varName="$(($varSet).name)"
		$varValue=if ($varSet.value.count -gt 1) {"$($varset.value | select -First 1)"} ELSE {"$(($varSet).value)"}
		$varScope=if ($varSet.value.count -gt 1) {"$($varset.value | select -skip 1)"} ELSE {"Local"}
		$varHT=@{}
		$varHT.Add('name',$varName)
		$varHT.Add('value',$varValue)
		$varHT.Add('Scope',$varScope)
		if (!(Get-Variable $varName -ErrorAction SilentlyContinue)) {Set-Variable @varHT -PassThru | Get-Variable | select name,value} ELSE {"Variable $varName is already in use in this PowerShell Environment."}
		Remove-Variable varSet,varHT,varName,varValue,varScope -ErrorAction SilentlyContinue
		} #End var foreach
	} ELSE {"Configuration file $cfgFile is missing."; break}
} ELSE {"Not using an external configuration/variable file."} #End UseCfgFile

<# LOAD LOCAL FUNCTIONS #>
$script:extFunctions="$ScriptPath\functions"
if (!(test-path $extFunctions)) {mkdir $extFunctions}
$extFunctList=Get-ChildItem $extFunctions -Exclude "main.ps1"
IF ($extFunctList) {
	"Loading functions..."
	$extFunctList | ForEach-Object { . $_.FullName } -ErrorAction SilentlyContinue
	}

<# LOAD MODULES #>
#import-module ..\mod\email\sendgrid.ps1 -force #For sending emails through SendGrid

<# MAIN #>
"Script is running in test mode: $TestMode. Executing main..."
if ($WhatIf.IsPresent) {}
if ($TestMode.IsPresent) {}
if (test-path $extFunctions\main.ps1) {. $extFunctions\main.ps1}

<# End #>
#$LastExitCode
if ($varList) {foreach ($varSet in $varList.PSObject.Properties) {Remove-Variable "$(($varSet).name)" -force -ErrorAction SilentlyContinue}}
$stopwatch.stop()
Write-host "Script execution duration: $($stopwatch.elapsed)"
stop-Transcript
"Type get-help $ScriptName for script information and options."