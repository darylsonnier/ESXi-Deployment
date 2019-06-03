& cls
[string]$server = "IP_of_ESXi_host"
$user = "username"
$pswd = "password"
$vmpath = "path_to_OVA_files"
Set-Location -Path "c:\program files\vmware\vmware ovf tool"

Connect-VIServer -Server $server -User $user -Password $pswd -Force
foreach ($vm in Get-VM)
{
    $Command = "./ovftool.exe"
    $Parms = "--noSSLVerify --skipManifestGeneration `"vi://${user}:$pswd@$server/$vm`" `"$vmpath\$vm.ova`""

    $Prms = $Parms.Split(" ")
    & "$Command" $Prms    
    #echo "$Command $Prms"
}