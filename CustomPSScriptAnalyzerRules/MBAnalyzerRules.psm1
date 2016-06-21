<#
.SYNOPSIS
    The variables names should be in PascalCase.

.DESCRIPTION
    The variable names should use a consistent capitalization style, in particular for this rule : PascalCase.
    In PascalCase, only the first letter is capitalized. Or, if the name is made of multiple concatenated words, only the first letter of each concatenated word are capitalized.
    To fix a violation of this rule, please consider using PascalCase for the variable names.

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
Function Measure-PascalCase {
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
            [System.Management.Automation.Language.Ast[]]$RegexAst = $ScriptBlockAst.FindAll($Predicate, $True)

            If ($RegexAst.Count -ne 0) {
                $Result = New-Object `
                        -Typename "Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord" `
                        -ArgumentList "The variables names should be in PascalCase.",$RegexAst.Extent,$PSCmdlet.MyInvocation.InvocationName,Information,$null
          
                $Results += $Result
            }

            return $Results
            #endregion
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}
Export-ModuleMember -Function Measure*