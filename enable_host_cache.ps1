<#
    Title: Host Cache Enable
    Description: Enable Read/Write cache on Azure VM Data Dislk.
#>

# required variables
$subscription_id = "subscription-name"
$resource_group = "rsg-name"
$az_vm_list = @("vm1","vm-002")


# logger functions
function infoMsg([string]$msg){
    Write-Host $msg -foregroundcolor "green"
}

function errorMsg([string]$msg){
    Write-Host $msg -foregroundcolor "red"
}
function warningMsg([string]$msg){
    Write-Host $msg -foregroundcolor "yellow"
}

# Disk Host cache Enable function
function enableCache() {
    # set azure subscription
    infoMsg("connecting to -> "+$subscription_id)
    Set-AzContext -SubscriptionName $subscription_id | Out-null

    try {
        # check resource group exists or not
        if ((az group exists --name $resource_group) -eq 'true') {
            infoMsg("$resource_group is exists on $subscription_id")
            infoMsg("Checking vm is exists or not . . .")
            foreach ($vm in $az_vm_list) {
                $get_vm =Get-AzVM -Name "$vm" -ResourceGroupName "$resource_group" -ErrorVariable notPresent -ErrorAction SilentlyContinue
                if ($notPresent) {
                   errorMsg("$vm is not exists")
                }else{
                    infoMsg("$vm is exists.")
                    infoMsg("Checking all DataDisk Available on $vm")
                    $data_disks = (Get-AzVM -Name $vm -ResourceGroupName $resource_group).StorageProfile.DataDisks
                    foreach ($disk in $data_disks) {
                        infoMsg("Availble Data Disk on $vm")
                        infoMsg($disk.Name)
                        if(($disk.Caching -eq "None") -OR ($disk.Caching -eq "ReadOnly") ){
                            infoMsg("Current Host Cache type of $vm is " + $disk.Caching)
                            infoMsg("Enable Read/Write Cache . . .")
                            $VM_name = Get-AzVM -ResourceGroupName $resource_group -VMName $vm
                            Set-AzVMDataDisk -VM $VM_name -Name $disk.Name -Caching ReadWrite | Update-AzVM
                        }else{
                            warningMsg("$vm data disks already have Read/Write Cache, no need to update.")
                        }
                    }
                }
            }

        }else {
            errorMsg("$resource_group is not exists")
        }
    }
    catch {
       errorMsg($_)
    }
}
enableCache
