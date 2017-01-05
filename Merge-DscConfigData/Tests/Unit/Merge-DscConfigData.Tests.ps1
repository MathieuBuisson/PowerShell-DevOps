$ModuleName = 'Merge-DscConfigData'
Remove-Module -Name $ModuleName
Import-Module "$($PSScriptRoot)\..\..\$($ModuleName).psm1" -Force
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
}
'@
$TestOverrideConfig = $TestOverrideConfigData | Invoke-Expression

$NodesNotAlreadyPresentInBaseConfig = Compare-Object $TestBaseConfig.AllNodes.NodeName $TestOverrideConfig.AllNodes.NodeName

Describe 'General Module behaviour' {
       
    $ModuleInfo = Get-Module -Name $ModuleName

    It 'Exports only the function "Merge-DscConfigData"' {

        $ModuleInfo.ExportedFunctions.Values.Name |
        Should Be 'Merge-DscConfigData'
    }
}
Describe 'Merge-DscConfigData' {
    
    Context 'General Function behaviour' {
                
        Mock -ModuleName $ModuleName Get-Content {
            return $TestBaseConfigData } -ParameterFilter {$Path -eq 'TestBase'}

        Mock -ModuleName $ModuleName Get-Content {
            return [string]::Empty } -ParameterFilter {$Path -eq 'TestEmpty'}

        Mock -ModuleName $ModuleName Get-Content {
            return $TestOverrideConfigData } -ParameterFilter {$Path -eq 'TestsOverride'}

        $Output = Merge-DscConfigData -BaseConfigFilePath 'TestBase' -OverrideConfigFilePath 'TestsOverride'

        It 'Should throw if the base config data file is empty' {
            { Merge-DscConfigData -BaseConfigFilePath 'TestEmpty' -OverrideConfigFilePath 'TestsOverride' } |
            Should Throw 'The base configuration data file is empty. This is not allowed.'
        }
        It 'Should Add the nodes which are not already present in the base config' {
            
            $Output.AllNodes.Count | Should Be ($TestBaseConfig.AllNodes.Count + $NodesNotAlreadyPresentInBaseConfig.Count)            
        }
        It 'Should Add the nodenames which are not already present in the base config' {
            
            Foreach ( $NodeName in $NodesNotAlreadyPresentInBaseConfig.InputObject ) {
                
                $Output.AllNodes.NodeName | Where-Object { $_ -eq $NodeName } |
                Should Not BeNullOrEmpty
            }
        }
        It 'Should keep the nodenames which are already present in the base config' {
            
            $Output.AllNodes.NodeName | Where-Object { $_ -eq '*' } |
            Should Not BeNullOrEmpty
        }
        It 'Should add settings which are absent in the base config for existing nodes' {
            
            $Expected = ($TestOverrideConfig.AllNodes | Where-Object { $_.NodeName -eq '*' }).LocalAdministrators
            $Actual = ($Output.AllNodes | Where-Object { $_.NodeName -eq '*' }).LocalAdministrators

            $Actual | Should Be $Expected
        }
        It 'Should override settings which are already present in the base config for existing nodes' {
            
            $Expected = ($TestOverrideConfig.AllNodes | Where-Object { $_.NodeName -eq '*' }).DefaultLogLevel
            $Actual = ($Output.AllNodes | Where-Object { $_.NodeName -eq '*' }).DefaultLogLevel

            $Actual | Should Be $Expected
        }
    }
}