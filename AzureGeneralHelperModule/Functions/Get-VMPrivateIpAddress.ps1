function Get-VMPrivateIpAddress {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VMName
    )

    $VM = Get-AzVM -Name $VMName
    $NIC = $VM | Get-AzNetworkInterface
    $IPConfig = $NIC.IpConfigurations | Select-Object -First 1
    return $IPConfig.PrivateIpAddress
}