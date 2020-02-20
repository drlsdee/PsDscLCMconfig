@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            ConfigurationNames = @(
                'Modules'
                'WindowsFeatures'
                'FirewallRules'
            )
        }
    )
    CommonData = @{
        RegistrationKey = 'a3d00c49-7cf2-486e-9548-01e9d53499f0'
        ConfigurationRepositoryWeb = "dsc-configs"
        ResourceRepositoryWeb = "dsc-modules"
        ReportServerWeb = "dsc-reports"
    }
}
