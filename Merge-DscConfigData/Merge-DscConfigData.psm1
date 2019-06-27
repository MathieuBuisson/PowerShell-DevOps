﻿#Requires -Version 4
Function Merge-DscConfigData {
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]$BaseConfigFilePath,

        [Parameter(Mandatory=$True,Position=1)]
        [string]$OverrideConfigFilePath,

        [boolean]$MergeNonNodeData = $false
    )

    $BaseConfigText = (Get-Content $BaseConfigFilePath | Out-String).Trim()

    # The base config should never be null or empty
    If ( -not($BaseConfigText) ) {
        Throw "The base configuration data file is empty. This is not allowed."
    }
    $OverrideConfigText = (Get-Content $OverrideConfigFilePath | Out-String).Trim()

    # When we standardize on PowerShell 5.x, we'll be able to use the much safer Import-PowerShellDataFile
    $BaseConfig = $BaseConfigText | Invoke-Expression

    # Merge the environment specific config only if it is NOT null or empty
    If ( $OverrideConfigText ) {

        Write-Verbose "Content of the override config data file : `r`n$OverrideConfigText"
        Try {
            $OverrideConfig = $OverrideConfigText | Invoke-Expression -ErrorAction Stop
        }
        Catch {
            throw "An error occurred when evaluating the content of $OverrideConfigFilePath as a PowerShell expression"
        }

        # Proceeding with the merge only if $OverrideConfig is not null and has been evaluated as a hashtable
        If ( $OverrideConfig -and ($OverrideConfig -is [hashtable]) ) {

            #Casting the AllNodes array to a list in order to add elements to it
            $BaseNodes = $BaseConfig.AllNodes -as [System.Collections.ArrayList]

            Foreach ( $Node in $OverrideConfig.AllNodes ) {

                $NodeInBaseConfig = $BaseNodes | Where-Object { $_.NodeName -eq $Node.NodeName }

                If ( $NodeInBaseConfig ) {

                    Write-Verbose "The node $($Node.NodeName) is already present in the base config."

                    # Removing the NodeName entry from the current Node to keep only the actual settings
                    $Node.Remove('NodeName')

                    Foreach ($OverrideSettingKey in $Node.keys) {

                        # Checking if the setting already exists in the Base config
                        $KeyExistsInBaseNode = $NodeInBaseConfig.ContainsKey($OverrideSettingKey)

                        If ( $KeyExistsInBaseNode ) {
                            Write-Verbose "$($NodeInBaseConfig.NodeName).$OverrideSettingKey, in node $($NodeInBaseConfig.NodeName) is present in the base config, overriding its value."
                            $NodeInBaseConfig.$($OverrideSettingKey) = $Node.$($OverrideSettingKey)
                        }
                        Else {
                            Write-Verbose "The setting $OverrideSettingKey, in node $($NodeInBaseConfig.NodeName) is absent in the base config, adding it."
                            $NodeInBaseConfig.add($OverrideSettingKey, $Node.$($OverrideSettingKey))
                        }
                    }
                }
                Else { # If the node is not already present in the base base config

                    Write-Verbose "The node $($Node.NodeName) is absent in the base config, adding it."
                    $Null = $BaseNodes.Add($Node)
                }
            }
			
            if ($MergeNonNodeData) {

              if ($OverrideConfig.NonNodeData -ne $null) {

                if ($BaseConfig.NonNodeData -eq $null) {

                  # Use NonNodeData, in its entirety, from the Override configuration if NonNodeData does not exist in the Base configuration
                  $BaseConfig.NonNodeData = $OverrideConfig.NonNodeData

                } else {

                  foreach ($NonNodeSetting in $OverrideConfig.NonNodeData.GetEnumerator()) {

                    # Checking if the setting already exists in the Base config
                    if ($BaseConfig.NonNodeData.ContainsKey($NonNodeSetting.name))
                    {
                      Write-Verbose -Message "The setting $($NonNodeSetting.name) is present in the base config, overring its value."
                      $BaseConfig.NonNodeData.Set_Item($NonNodeSetting.Name, $NonNodeSetting.value)
                    }
                    else
                    {
                      Write-Verbose -Message "The setting $($NonNodeSetting.name) is absent in the base config, ading it."
                      $BaseConfig.NonNodeData.Add($NonNodeSetting.Name, $NonNodeSetting.value)
                    }
                  }
                }
              }
            }
            $MergedConfig = $BaseConfig
            # Converting AllNodes back to an [array] because PSDesiredStateConfiguration doesn't accept an [ArrayList]
            $NodesBackToArray = $BaseNodes -as [array]
            $MergedConfig.AllNodes = $NodesBackToArray
            return $MergedConfig
        }
        Else {
            return $BaseConfig
        }
    }
}