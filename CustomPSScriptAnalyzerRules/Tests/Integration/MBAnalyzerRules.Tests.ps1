
Describe "Testing rule Measure-PascalCase against ExampleScript.ps1" {

    $ExampleResults = Invoke-ScriptAnalyzer -Path "$($PSScriptRoot)\..\..\ExampleScript.ps1" -CustomRulePath "$($PSScriptRoot)\..\..\MBAnalyzerRules.psm1"

    $VariableNames = $ExampleResults.Extent.Text | ForEach-Object { ($_ -split ' = ')[0].Trim('$') }
    $TestCases = @(
            @{ ExpectedViolation  = 'statusUrl' },
            @{ ExpectedViolation  = 'errorUrl' },
            @{ ExpectedViolation  = 'NAMESPACE' },
            @{ ExpectedViolation  = 'uwfInstance' },
            @{ ExpectedViolation  = 'UWFEnabled' }
    )

    It "Should return 6 violations" {
        $ExampleResults.Count | Should Be 6
    }
    It "Detected violations should contain <ExpectedViolation>" -TestCases $TestCases {
        Param($ExpectedViolation)
        $VariableNames -contains $ExpectedViolation | Should Be $True
    }
}