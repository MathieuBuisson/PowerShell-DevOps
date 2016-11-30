Describe 'PSScriptAnalyzer analysis' {
    
    $ScriptAnalyzerRules = Get-ScriptAnalyzerRule -Name "PSAvoid*"

    Foreach ( $Rule in $ScriptAnalyzerRules ) {

        It "Should not return any violation for the rule : $($Rule.RuleName)" {
            Invoke-ScriptAnalyzer -Path ".\ExampleScript.ps1" -IncludeRule $Rule.RuleName |
            Should BeNullOrEmpty
        }
    }
}


    
    
    
    
