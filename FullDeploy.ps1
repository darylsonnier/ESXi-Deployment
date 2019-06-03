$ErrorActionPreference = 'Stop'
[string]$server = "IP_of_ESXi_host"
$user = "username"
$pswd = "password"
$vmpath = "path_to_OVA_files"
$files = (Get-ChildItem $vmpath -Filter *.ova).FullName
$vmstext = "c:\utils\esxi\scripts\vms.txt"
Set-Location -Path "c:\program files\vmware\vmware ovf tool"

Connect-VIServer -Server $server -User $user -Password $pswd -Force # Reconnect after deploying VMs
Get-VMHost $server | Get-VMHostStartPolicy | Set-VMHostStartPolicy -WaitForHeartBeat $true -Enabled $true
Clear-Host

foreach ($file in $files)
{
    $Command = "./ovftool.exe"
    $Parms = "--skipManifestCheck --disableVerification --noSSLVerify --datastore=SSD1 `"$file`" vi://${user}:$pswd@$server"

    $Prms = $Parms.Split(" ")
    & "$Command" $Prms
    #echo "$Command $Prms"
}


#Read-Host "Press ENTER to continue"

# Set Auto Start Policy for Host
Connect-VIServer -Server $server -User $user -Password $pswd -Force # Reconnect after deploying VMs
Get-AdvancedSetting -Entity $server -Name UserVars.HostClientCEIPOptIn | Set-AdvancedSetting -Value 2 -Confirm:$false

$csv = Import-Csv $vmstext # -Header @("Name","Port","Order")
$configs = New-Object "System.Collections.Generic.List``1[virtualMach]"
foreach ($line in $csv)
{
    $tmp = New-Object virtualMach($($line.Name),$($line.Port),$($line.Order))
    $configs.Add($tmp)
}

foreach ($cfg in $configs)
{
    $n = $cfg.Name
    $p = $cfg.Port
    $s = [int]$cfg.startOrder
    Write-Output "$n $p $s"
}

#ExtraOptions
$extraOptions = @{}
$extraOptions.Add('RemoteDisplay.maxConnections', '-1')
$extraOptions.Add('RemoteDisplay.vnc.enabled', 'TRUE')

foreach ($vm in Get-VM)
{
    <#do
    {
        $state = $vm.ExtensionData.guest.guestState
        Write-Output "Waiting on VM state"
    }
    until ($state -eq 'notRunning')#>

    Write-Output "Configuring remote access for $vm"
    $vmID = Get-View (Get-VM $vm).ID
    $CfgSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

    foreach ($opt in $extraOptions.GetEnumerator())
    {
        $optionValue = New-Object VMware.Vim.optionvalue
        $optionValue.Key = $($opt.Name)
        $optionValue.Value = $($opt.Value)
        $CfgSpec.ExtraConfig += $optionValue
        Write-Output "$($opt.Name) - $($opt.Value)"
    }

    $optx = New-Object VMware.Vim.OptionValue
    $optx.Key="RemoteDisplay.vnc.port"
    foreach ($cfg in $configs)
    {
        if ($cfg.Name -eq $vm)
        {
            $optx.Value = $cfg.Port
            $CfgSpec.ExtraConfig += $optx
        }
    }
    $vmID.ReconfigVM($CfgSpec)

    #Set auto start policy for each VM in $startOrder
    $vmStartPolicy = Get-VMStartPolicy -VM $vm
    foreach ($cfg in $configs)
    {
        if ($cfg.Name -eq $vm)
        {
            $order = $cfg.startOrder
            if ($order -ne 0)
            {
                Set-VMStartPolicy -StartPolicy $vmStartPolicy -StartOrder 1 -StartAction PowerOn -StopAction GuestShutDown -StartDelay 30 -StopDelay 30 -WaitForHeartBeat $false
            }
            else
            {
                Set-VMStartPolicy -StartPolicy $vmStartPolicy -StartDelay 30 -StopDelay 30 -WaitForHeartBeat $false -StartAction None
            }
        }
    }
}


foreach ($cfg in $configs | Sort-Object -Property startOrder)
{
    #Write-Output "Configuring auto start policy for $vm"
    foreach ($vm in Get-VM)
    {
        $vmStartPolicy = Get-VMStartPolicy -VM $vm
        if ($cfg.Name -eq $vm)
        {
            $order = $cfg.startOrder
            if ($order -ne 0)
            {
                Set-VMStartPolicy -StartPolicy $vmStartPolicy -StartOrder $order -StartAction PowerOn -StopAction GuestShutDown -StartDelay 30 -StopDelay 30 -WaitForHeartBeat $false
            }
        }
    }
}
Restart-VMHost $server -RunAsync -Force -Confirm:$false


class virtualMach
{
    # Optionally, add attributes to prevent invalid values
    [ValidateNotNullOrEmpty()][string]$Name
    [Int]$Port
    [Int]$startOrder
    virtualMach($Name,$Port,$startOrder)
    {
       $this.Name = $Name
       $this.Port = $Port
       $this.startOrder = $startOrder
    }
}