Configuration TestConfig
{
    Param(
        
        [Parameter(Mandatory=$true)][String]$DomainName,
        [Parameter(Mandatory=$true)][String]$ResourceGroupName,
        [Parameter(Mandatory=$true)][String]$AutomationAccountName,
        [Parameter(Mandatory=$true)][String]$AdminName
    )

    Import-DscResource -ModuleName @{ModuleName='LWINConfigs';ModuleVersion='1.0.0.0'}
    Import-DscResource -ModuleName @{ModuleName='DomainConfig';ModuleVersion='1.0.0.0'}
    Import-DscResource -ModuleName @{ModuleName='PSWAWebServer';ModuleVersion='1.0.0.0'}
    Import-DscResource -ModuleName @{ModuleName='PSDesiredStateConfiguration';ModuleVersion='1.1'}

    $AdminCreds = Get-AutomationPSCredential -Name $AdminName

    Node $AllNodes.NodeName
    {
        LWINBaseConfig BaseConfig
        {

        }
                
        WindowsFeature RemoveUI
        {
            Name = "Server-Gui-Shell"
            Ensure = "Absent"
            DependsOn = "[LWINBaseConfig]BaseConfig"
        }
        
        
    }
    Node ($AllNodes.Where{$_.Role -eq "WebServer"}).NodeName
    {
            
            JoinDomain DomainJoin
            {
                DependsOn = "[WindowsFeature]RemoveUI"
                DomainName = $DomainName
                Admincreds = $Admincreds
                RetryCount = 20
                RetryIntervalSec = 60
            }

            PSWAWebServer InstallPSWAWebServer
            {
                DependsOn = "[JoinDomain]DomainJoin"
            }        
    }
    Node ($AllNodes.Where{$_.Role -eq "DomainController"}).NodeName
    {
            DomainController DCConfig
            {
                DomainName = $DomainName
                Admincreds = $Admincreds
                RetryCount = 20
                RetryIntervalSec = 60
            } 
    }
    Node ($AllNodes.Where{$PSItem.Role -eq "SQLServer"}).NodeName
    {
        JoinDomain DomainJoin
        {
            DomainName = $DomainName
            Admincreds = $Admincreds
            RetryCount = 20
            RetryIntervalSec = 60
        }
        
    }
}