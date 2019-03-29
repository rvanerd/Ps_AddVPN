

#Meraki VPN Automation Script for Windows 8.1+
#Version: 2.2
#Created 2019/03/22
#
#This script was setup to automate the Windows VPN connections to Meraki MX Appliances
#
#################################
# To be Added in future release:#
#################################
#  
#-While loop for adding multiple network to split-tunnel.  Currently Additional Networks can be added manually with :
# **Add-VpnConnectionRoute -ConnectionName %ConnectionName% -DestinationPrefix %CIDRSubnet% 
#-Add Registry Backup prior to DWord additon
#
#
################################
#         Change Log           #
################################
#Modified 2019/03/26
#- Added UDP Encapsulation registry key (reboot at end of script)
#


#####Script Starts Here######

#Check for AssumeUDPEncapsulationContextOnSendRule and add if missing
$valueExists = (Get-Item HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent\).Property -contains "AssumeUDPEncapsulationContextOnSendRule"
if ($valueExists -eq $false){
New-ItemProperty -path HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent -Name "AssumeUDPEncapsulationContextOnSendRule" -PropertyType "DWORD" -Value "2" -Force | out-null
Write-Host "Registry Key 'AssumeUDPEncapsulationContextOnSendRule' has been added to your computer."`n "A reboot, of your computer will be required at the completion of this script"  -ForegroundColor Yellow 
}


#Do-While to Get Base VPN Information and allor for verification.
do
{
$connection_Name = Read-Host -Prompt "Please input the Connection Name:  " 
$server_Address = Read-Host -Prompt "Please input the Connection IP address:  " 
$preshared_Key = Read-Host -Prompt "Please input the Preshared Key:  "

Write-host `n `n "Is the Following Information Correct?" `n `n "Connection Name: "$connection_Name `n  "Server Address:"$server_Address `n "Preshared Key:"$preshared_Key `n `n
    $Readhost = Read-Host "(Y)es / (N)o " 
    Switch ($ReadHost) 
     { 
       Y {$good_Settings=$true} 
       N {$good_Settings=$false} 
       Default {$good_Settings=$true} 
     } 
    
}
while ($good_Settings -eq $false)  


#Set Split Tunneling Options
Write-host `n `n "Would you like to configure this VPN connection for Split Tunneling? (Default is No)" -ForegroundColor Yellow 
    $Readhost = Read-Host "(Y)es / (N)o " 
    Switch ($ReadHost) 
     { 
       Y {$client_Sub = Read-Host -Prompt "Please Enter the Remote Subnet (Format: 192.168.1.0/24) :  "; $publish_Settings=$true} 
       N {Write-Host "Split Tunneling will not be configured" -ForegroundColor Yellow; $publish_Settings=$false} 
       Default {Write-Host "Split Tunneling will not be configured" -ForegroundColor Yellow; $publish_Settings=$false} 
     } 


#If-statement for split-tunnel and VPN Creation
if($publish_Settings -eq $false){
    #Setup Full Tunnel VPN and output progress.
    Add-VpnConnection -Name "$connection_Name" -ServerAddress "$server_Address" -TunnelType L2tp -AllUserConnection -L2tpPsk "$preshared_Key" -EncryptionLevel Optional -AuthenticationMethod Pap -Force
    Write-Host "The VPN Connection" $connection_Name "has been created as a full tunnel VPN." -ForegroundColor Yellow
}else {
    Add-VpnConnection -Name "$connection_Name" -ServerAddress "$server_Address" -TunnelType L2tp -AllUserConnection -L2tpPsk "$preshared_Key" -SplitTunneling -EncryptionLevel Optional  -AuthenticationMethod Pap -Force
    Add-VpnConnectionRoute -ConnectionName "$connection_Name" -DestinationPrefix $client_Sub
    Write-Host "The VPN Connection" $connection_Name "has been created as a split tunnel VPN." -ForegroundColor Yellow
}

if ($valueExists -eq $false){
    Write-host `n `n "Would you like to reboot your computer? (Default is No)" -ForegroundColor Yellow 
        $Readhost = Read-Host "(Y)es / (N)o " 
        Switch ($ReadHost) 
         { 
           Y {Restart-Computer} 
           N {Write-host `n "You may close this window." -ForegroundColor Yellow} 
           Default {Write-Host `n "You may close this window" -ForegroundColor Yellow} 
         }   

}else{ Write-Host `n "You may close this window" -ForegroundColor Yellow


}


#
#####Script Ends Here#####