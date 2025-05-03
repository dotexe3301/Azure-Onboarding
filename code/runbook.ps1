param(
    [string] $displayName,
    [string] $groupName,
    [string] $role
)

function Generate-Password {
    param(
        [int]$Length = 12,
        [string]$CharacterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%"
    )
    $Password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $Password += $CharacterSet[(Get-Random -Maximum $CharacterSet.Length)]
    }
    return $Password
}
  
$password = Generate-Password -Length 10
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$usp = (($displayName -split ' ') -join '') + "@YOUR-DOMAIN"

# User Creation
Connect-AzAccount -Identity
$user = New-AzADUser -DisplayName $displayName -UserPrincipalName $usp -Password $securePassword -MailNickname (($displayName -split ' ') -join '')
$group = Get-AzADGroup -DisplayName $groupName
Add-AzADGroupMember -TargetGroupObjectId $group.Id -MemberObjectId $user.Id
  
# Resource Provisioning
$uri = "YOUR-BLOB-SAS-URL"
$vmName = "vm-" + (($displayName -split ' ') -join '')
$templateParams = @{
    vmName        = $vmName
    location      = "centralindia"
    adminUsername = (($displayName -split ' ') -join '')
    adminPassword = $password
}

New-AzResourceGroupDeployment -Name "EmployeeVMProvising" -ResourceGroupName "users" -TemplateUri $uri -TemplateParameterObject $templateParams 
New-AzRoleAssignment -ObjectId $user.Id -RoleDefinitionName "Virtual Machine Contributor" -Scope "/subscriptions/76b9c2ae-23b7-4d4e-aec7-52a7e0b85f8c/resourceGroups/users/providers/Microsoft.Compute/virtualMachines/$vmName"

# Outputs to Logic App
$output = @{
    UserName = $usp
    Password = $password
    VM = "You are assigned to VM located at: /subscriptions/SUBSCRIPTION-ID/resourceGroups/users/providers/Microsoft.Compute/virtualMachines/$vmName"
}
$output | ConvertTo-Json