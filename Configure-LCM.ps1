[CmdletBinding()]
param (
    # Registration key
    [Parameter()]
    [string]
    $RegistrationKey,

    # Configuration names list
    [Parameter()]
    [string[]]
    $ConfigurationNames,

    # Target host name(s)
    [Parameter()]
    [string[]]
    $HostName,

    # Configuration data path
    [Parameter()]
    [string]
    $ConfigurationDataPath
)

[string]$functionsFolderPath = "$PSScriptRoot\Functions"
[string[]]$functionsScripts = (Get-ChildItem -Path $functionsFolderPath -File -Filter '*.ps1').FullName
$functionsScripts.ForEach({
    Write-Verbose -Message "Importing function script: `"$_`"..."
    . $_
})

$theScript = $MyInvocation.MyCommand.Name.Split('.')[0]

if (-not $ConfigurationDataPath) {
    [ValidateNotNullOrEmpty()]$ConfigurationDataPath = (Get-ChildItem -Path $PSScriptRoot -File -Filter '*.psd1').Where({$_.BaseName -eq $theScript}).FullName
}

[DscLocalConfigurationManager()]
Configuration Configure-LCM {
    [CmdletBinding()]
    param (
        # Registration key
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
        Write-Verbose -Message "Registration key is not set. Trying to get key from configuration data..."
        [ValidateNotNullOrEmpty()][string]$RegistrationKey = $ConfigurationData.CommonData.RegistrationKey
    }
    Write-Verbose -Message "USING REGISTRATION KEY: `"$RegistrationKey`""

    $ConfigurationData.AllNodes.ForEach({
        if (-not $ConfigurationNames) {
            Write-Verbose -Message "Configuration names are not set. Trying to get configuration names from configuration data..."
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
                Write-Verbose -Message "Found $($ConfigurationNames.Count) named configurations. Creating partial configuration blocks for each of them..."
                $ConfigurationNames.ForEach({
                    Write-Verbose -Message "Creaing block `"[PartialConfiguration]$_`"... "
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

if ($HostName) {
    $HostName.ForEach({
        Write-Verbose -Message "Creating LCM configuration for hostname `"$_`".  Result should be in folder `"$((Get-Location).Path)\$theScript\$_`""
        Configure-LCM -RegistrationKey $RegistrationKey -ConfigurationNames $ConfigurationNames -ConfigurationData $configurationDataPath -OutputPath "$theScript\$_"
    })
} else {
    Write-Verbose -Message "Hostname not specified. Creating generic LCM configuration. Result should be in folder `"$((Get-Location).Path)\$theScript`"."
    Configure-LCM -RegistrationKey $RegistrationKey -ConfigurationNames $ConfigurationNames -ConfigurationData $configurationDataPath -OutputPath "$theScript"
}
