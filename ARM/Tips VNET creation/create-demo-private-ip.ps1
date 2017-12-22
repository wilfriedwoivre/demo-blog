$vnet = Get-AzureRmVirtualNetwork -Name 'demo-vnet' -ResourceGroupName 'demo-blog'
$backSubnet = $vnet.Subnets | Where { $_.Name -eq 'Back' }

$ipConf = New-AzureRmNetworkInterfaceIpConfig -Name 'demo-back-ipconf' -PrivateIpAddressVersion IPv4 -PrivateIpAddress '16.0.3.4' -Subnet $backSubnet
New-AzureRmNetworkInterface -Name 'demo-back-ip' -ResourceGroupName 'demo-blog' -Location 'West Europe' -IpConfiguration $ipConf