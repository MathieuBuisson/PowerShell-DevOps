####################### Importing the PSReadline module
Import-Module PSReadline

function prompt {
    $origLastExitCode = $LastExitCode
    $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($curPath.ToLower().StartsWith($Home.ToLower())) {
        $curPath = "~" + $curPath.SubString($Home.Length)
    }
    Write-Host $curPath -NoNewline -ForegroundColor Black -BackgroundColor DarkGreen
    Write-Host "$([char]57520) " -NoNewline -ForegroundColor DarkGreen

    Write-VcsStatus
    "`n$('>' * ($nestedPromptLevel + 1)) "
    $LastExitCode = $origLastExitCode
}

####################### Posh-Git
Import-Module -Name 'posh-git'

# Background colors
$baseBackgroundColor = 'DarkBlue'
$GitPromptSettings.AfterStashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeIndexBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeStashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchAheadStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBehindAndAheadStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchBehindStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchGoneStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.BranchIdenticalStatusToBackgroundColor = $baseBackgroundColor
$GitPromptSettings.DelimBackgroundColor = $baseBackgroundColor
$GitPromptSettings.IndexBackgroundColor = $baseBackgroundColor
$GitPromptSettings.ErrorBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalDefaultStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalStagedStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.LocalWorkingStatusBackgroundColor = $baseBackgroundColor
$GitPromptSettings.StashBackgroundColor = $baseBackgroundColor
$GitPromptSettings.WorkingBackgroundColor = $baseBackgroundColor

# Foreground colors
$GitPromptSettings.AfterForegroundColor = $baseBackgroundColor
$GitPromptSettings.BeforeForegroundColor = "Black"
$GitPromptSettings.BranchForegroundColor = "Blue"
$GitPromptSettings.BranchGoneStatusForegroundColor = "Blue"
$GitPromptSettings.BranchIdenticalStatusToForegroundColor = "DarkYellow"
$GitPromptSettings.DefaultForegroundColor = "Gray"
$GitPromptSettings.DelimForegroundColor = "Blue"
$GitPromptSettings.IndexForegroundColor = "Green"
#$GitPromptSettings.WorkingForegroundColor = "Yellow"

# Prompt shape
$GitPromptSettings.BeforeText = "$([char]57520)"
$GitPromptSettings.AfterText = "$([char]57520) "
$GitPromptSettings.DelimText = " ॥"
$GitPromptSettings.ShowStatusWhenZero = $False

function Get-FullHelp {

    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$cmd
    )

    If ((Get-Command -Name $cmd).CommandType -eq "Cmdlet" ) {
        $cmdlet = (Get-Command -Name $cmd).Name
    }
    Elseif ((Get-Command -Name $cmd).CommandType -eq "Function" ) {
        $cmdlet = (Get-Command -Name $cmd).Name
    }
    Elseif ((Get-Command -Name $cmd).CommandType -eq "Alias" ) {

        # Resolving aliases to cmdlet names
        $cmdlet = (Get-Command -Name $cmd).Definition
    }
    Else {
        # No support for other command types, like workflows, external commands and external scripts
        throw "Could not resolve $cmd to a valid Cmdlet name. Exiting the function."
    } # End conditional statements

    Get-Help $cmdlet -Full | more

}

######################### Setting an alias for the function Get-FullHelp
New-Alias -Name gfh -Value Get-FullHelp

######################## Aliases for common git commands
function gpo {
    & git push origin master
}
function gpr {
    & git pull --rebase
}
function gpc {
    & git commit -m $args
}
function ga {
    & git add --all
}
function gst {
    & git status
}
