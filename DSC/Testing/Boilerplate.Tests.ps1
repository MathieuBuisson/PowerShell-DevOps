$Global:DSCResourceName = 'My_DSCResource'  #<----- Just change this

Import-Module "$($PSScriptRoot)\..\..\DSCResources\$($Global:DSCResourceName)\$($Global:DSCResourceName).psm1" -Force

# Helper function to list the names of mandatory parameters of *-TargetResource functions
Function Get-MandatoryParameter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$CommandName
    )
    $GetCommandData = Get-Command "$($Global:DSCResourceName)\$CommandName"
    $MandatoryParameters = $GetCommandData.Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $True }
    return $MandatoryParameters.Name
}

# Getting the names of mandatory parameters for each *-TargetResource function
$GetMandatoryParameter = Get-MandatoryParameter -CommandName "Get-TargetResource"
$TestMandatoryParameter = Get-MandatoryParameter -CommandName "Test-TargetResource"
$SetMandatoryParameter = Get-MandatoryParameter -CommandName "Set-TargetResource"

# Splatting parameters values for Get, Test and Set-TargetResource functions
$GetParams = @{
    
}
$TestParams = @{
    
}
$SetParams = @{
    
}

Describe "$($Global:DSCResourceName)\Get-TargetResource" {
    
    $GetReturn = & "$($Global:DSCResourceName)\Get-TargetResource" @GetParams

    It "Should return a hashtable" {
        $GetReturn | Should BeOfType System.Collections.Hashtable
    }
    Foreach ($MandatoryParameter in $GetMandatoryParameter) {
        
        It "Should return a hashtable with key named $MandatoryParameter" {
            $GetReturn.ContainsKey($MandatoryParameter) | Should Be $True
        }
    }
}

Describe "$($Global:DSCResourceName)\Test-TargetResource" {
    
    $TestReturn = & "$($Global:DSCResourceName)\Test-TargetResource" @TestParams

    It "Should have the same mandatory parameters as Get-TargetResource" {
        # Does not check for $True or $False but uses the output of Compare-Object.
        # That way, if this test fails Pester will show us the actual difference(s).
        (Compare-Object $GetMandatoryParameter $TestMandatoryParameter).InputObject | Should Be $Null
    }
    It "Should return a boolean" {
        $TestReturn | Should BeOfType System.Boolean
    }
}

Describe "$($Global:DSCResourceName)\Set-TargetResource" {
    
    $SetReturn = & "$($Global:DSCResourceName)\Set-TargetResource" @SetParams

    It "Should have the same mandatory parameters as Test-TargetResource" {
        (Compare-Object $TestMandatoryParameter $SetMandatoryParameter).InputObject | Should Be $Null
    }
    It "Should not return anything" {
        $SetReturn | Should Be $Null
    }
}