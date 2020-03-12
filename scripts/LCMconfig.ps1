 [DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $True
RefreshFrequencyMins =             30
ConfigurationMode = 'ApplyAndAutoCorrect'

        }
    }
}
lcmconfig -outputpath “c:\LCMconfig”