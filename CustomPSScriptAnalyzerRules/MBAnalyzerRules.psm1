#Requires -Version 3.0
Function Measure-PascalCase {
<#
.SYNOPSIS
    The variables names should be in PascalCase.

.DESCRIPTION
    Variable names should use a consistent capitalization style, i.e. : PascalCase.
    In PascalCase, only the first letter is capitalized. Or, if the variable name is made of multiple concatenated words, only the first letter of each concatenated word is capitalized.
    To fix a violation of this rule, please consider using PascalCase for variable names.

.EXAMPLE
    Measure-PascalCase -ScriptBlockAst $ScriptBlockAst

.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

.NOTES
    https://msdn.microsoft.com/en-us/library/dd878270(v=vs.85).aspx
    https://msdn.microsoft.com/en-us/library/ms229043(v=vs.110).aspx
#>

    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    Process {

        $Results = @()

        try {
            #region Define predicates to find ASTs.

            [ScriptBlock]$Predicate = {
                Param ([System.Management.Automation.Language.Ast]$Ast)

                [bool]$ReturnValue = $False
                If ($Ast -is [System.Management.Automation.Language.AssignmentStatementAst]) {

                    [System.Management.Automation.Language.AssignmentStatementAst]$VariableAst = $Ast
                    If ($VariableAst.Left.VariablePath.UserPath -cnotmatch '^([A-Z][a-z]+)+$') {
                        $ReturnValue = $True
                    }
                }
                return $ReturnValue
            }
            #endregion

            #region Finds ASTs that match the predicates.
            [System.Management.Automation.Language.Ast[]]$Violations = $ScriptBlockAst.FindAll($Predicate, $True)

            If ($Violations.Count -ne 0) {

                Foreach ($Violation in $Violations) {

                    $Result = New-Object `
                            -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                            -ArgumentList "$((Get-Help $MyInvocation.MyCommand.Name).Description.Text)",$Violation.Extent,$PSCmdlet.MyInvocation.InvocationName,Information,$Null

                    $Results += $Result
                }
            }
            return $Results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Export-ModuleMember -Function Measure-*