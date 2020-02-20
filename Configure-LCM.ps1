[string]$functionsFolderPath = "$PSScriptRoot\Functions"
[string[]]$functionsScripts = (Get-ChildItem -Path $functionsFolderPath -File -Filter '*.ps1').FullName
$functionsScripts.ForEach({
    . $_
})

#Set-DSCEndpointURL -Verbose -HostName 'test' -Port 88

[DscLocalConfigurationManager()]
Configuration Configure-LCM {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $RegistrationKey,

        # Configuration names list
        [Parameter()]
        [string[]]
        $ConfigurationNames
    )

    [string]$urlConfigurationRepositoryWeb = Set-DSCEndpointURL -HostName $ConfigurationData.CommonData.ConfigurationRepositoryWeb
    [string]$urlResourceRepositoryWeb = Set-DSCEndpointURL -HostName $ConfigurationData.CommonData.ResourceRepositoryWeb
    [string]$urlReportServerWeb = Set-DSCEndpointURL -HostName $ConfigurationData.CommonData.ReportServerWeb

    if (-not $RegistrationKey) {
        $RegistrationKey = $ConfigurationData.CommonData.RegistrationKey
    }

    $ConfigurationData.AllNodes.ForEach({
        if (-not $ConfigurationNames) {
            $ConfigurationNames =  $_.ConfigurationNames
        }
        [string]$NodeName = $_.NodeName
        Node $NodeName {
            Settings {
                ActionAfterReboot = 'ContinueConfiguration'
                AllowModuleOverwrite = $true
                ConfigurationMode = 'ApplyAndAutoCorrect'
                ConfigurationModeFrequencyMins = 15
                DebugMode = 'None'
                RebootNodeIfNeeded = $true
                RefreshMode = 'Pull'
                RefreshFrequencyMins = 30
            }

            ConfigurationRepositoryWeb "$(($ConfigurationData.CommonData.ConfigurationRepositoryWeb).ToUpper())" {
                AllowUnsecureConnection = $true
                ConfigurationNames = $ConfigurationNames
                RegistrationKey = $RegistrationKey
                ServerURL = $urlConfigurationRepositoryWeb
            }

            ResourceRepositoryWeb "$(($ConfigurationData.CommonData.ResourceRepositoryWeb).ToUpper())" {
                AllowUnsecureConnection = $true
                RegistrationKey = $RegistrationKey
                ServerURL = $urlResourceRepositoryWeb
            }

            ReportServerWeb "$(($ConfigurationData.CommonData.ReportServerWeb).ToUpper())" {
                AllowUnsecureConnection = $true
                RegistrationKey = $RegistrationKey
                ServerURL = $urlReportServerWeb
            }

            if ($ConfigurationNames.Count -gt 1) {
                $ConfigurationNames.ForEach({
                    PartialConfiguration "$_" {
                        Description = "Named configuration `"$_`" for node `"$NodeName`"."
                        ConfigurationSource = "[ConfigurationRepositoryWeb]$(($ConfigurationData.CommonData.ConfigurationRepositoryWeb).ToUpper())"
                        RefreshMode = 'Pull'
                        ResourceModuleSource = "[ResourceRepositoryWeb]$(($ConfigurationData.CommonData.ResourceRepositoryWeb).ToUpper())"
                    }
                })
            }
        }
    })
}

Configure-LCM -ConfigurationData .\Configure-LCM.psd1 -Verbose -RegistrationKey 'aaaa' #-ConfigurationNames @('ConfAAA', 'ConfBBB')
#Copy-Item -Path '.\Configure-LCM\localhost.meta.mof' -Destination '\\sql-sc-00\c$\Configure-LCM' -Force -Verbose