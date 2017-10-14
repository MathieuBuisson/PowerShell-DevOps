# Ensuring PSScriptAnalyzer ignores the use of Invoke-Expression
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '')]
param()

$ModuleName = 'Merge-DscConfigData'
If ( Get-Module -Name $ModuleName ) {
    Remove-Module -Name $ModuleName
}
Import-Module "$($PSScriptRoot)\..\..\$($ModuleName).psm1" -Force

Describe 'Merge-DscConfigData [NonNodeData]' {
    
    InModuleScope $ModuleName {
        
        $TestBaseConfigData = @'
        @{ 
            # Node specific data 
            AllNodes = @( 
               # Common settings for all nodes  
               @{ 
                    NodeName = '*'
                    PSDscAllowPlainTextPassword = $True
                    ServicesEndpoint = 'http://localhost/Services/'
                    DefaultLogLevel = 'Debug'
                    KeepLatestBuilds = 6
               }
            );
            NonNodeData = @{
              DomainName = 'example.com'
            }
        }
'@

        $TestBaseConfig = $TestBaseConfigData | Invoke-Expression


        $TestOverrideConfigData = @'
        @{ 
            # Node specific data 
            AllNodes = @( 
               @{ 
                    NodeName = '*'
                    LocalAdministrators = 'MyLocalUser'
                    DefaultLogLevel = 'Info'
               },
               @{
                    NodeName = 'Server1'
                    Role = 'Primary'
               },
               @{
                    NodeName = 'Server2'
                    Role = 'Secondary'
                    DefaultLogLevel = 'Info'
                    KeepLatestBuilds = 3
               }
            );
            NonNodeData = @{
              DomainName = 'subdomain.example.com'
              OUPath = 'OU=Servers, DC=subdomain, DC=exampple, DC=com'
            }
        }
'@

        $TestOverrideConfig = $TestOverrideConfigData | Invoke-Expression

        Mock Get-Content { return [string]::Empty } -ParameterFilter {$Path -eq 'TestEmpty'}
        Mock Get-Content { return $TestBaseConfigData } -ParameterFilter {$Path -eq 'TestBase'}
        Mock Get-Content { return $TestOverrideConfigData } -ParameterFilter {$Path -eq 'TestsOverride'}

        $Output = Merge-DscConfigData -BaseConfigFilePath 'TestBase' -OverrideConfigFilePath 'TestsOverride' -MergeNonNodeData $true

         It 'Should add NonNodeData settings which are absent in the base config' {
            
            $Expected = ($TestOverrideConfig.NonNodeData).OUPath
            $Actual = ($Output.NonNodeData).OUPath

            $Actual | Should Be $Expected
         }

        It 'Should override NonNodeData settings which are already present in the base config' {
            
            $Expected = ($TestOverrideConfig.NonNodeData).DomainName
            $Actual = ($Output.NonNodeData).DomainName

            $Actual | Should Be $Expected
        }

        $Output = Merge-DscConfigData -BaseConfigFilePath 'TestBase' -OverrideConfigFilePath 'TestsOverride' -MergeNonNodeData $false

        It 'Should return NonNodeData settings from the base config if the parameter MergeNonNodeData is false' {

            $Expected = $TestBaseConfig.NonNodeData
            $Actual = $Output.NonNodeData

            [bool](Compare-Object $Expected $Actual) | Should Be $false
        }

        $TestBaseConfigData = @'
        @{ 
            # Node specific data 
            AllNodes = @( 
               # Common settings for all nodes  
               @{ 
                    NodeName = '*'
                    PSDscAllowPlainTextPassword = $True
               }
            );
        }
'@

        $TestBaseConfig = $TestBaseConfigData | Invoke-Expression

        Mock Get-Content { return $TestBaseConfigData } -ParameterFilter {$Path -eq 'TestBase'}

        $Output = Merge-DscConfigData -BaseConfigFilePath 'TestBase' -OverrideConfigFilePath 'TestsOverride' -MergeNonNodeData $true

        It 'Should create NonNodeData in the BaseConfig if it does not already exist' {

            $Expected = $true
            $Actual = $Output.NonNodeData

            [bool]($Actual) | Should Be $true
        }

    }

}

