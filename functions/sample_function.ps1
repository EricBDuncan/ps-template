<#
.VERSION 1
.CHANGES

#>

$script:name=($MyInvocation.MyCommand.Name).Replace('.ps1','')

function Example {
[CmdletBinding()]
param(
[Parameter(ValueFromPipeline=$true)][String] $input
)

Begin {
#Define vars and such; will only run once per call of your function.
}

Process {
#Do stuff with the func input; will process each of the values.
}

End {
#Dispose or cleanup items; runs only once.
}

} #End Function

function Example2() {
}

write-host "$name loaded..." -ForegroundColor yellow -BackgroundColor black