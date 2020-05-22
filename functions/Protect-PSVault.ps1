<#
.Synopsis
Protects a vault from beeing tampered with.
.Description
Modifies the ACL of the vault so only spefied users or groups can write to it.
.Parameter Vault
Vault to protect
.Parameter Users
Users to be able to write
.Parameter Groups
Groups to be able to write
#>
function Protect-PSVault {
Param(
    [Parameter(Mandatory)]
    [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
    $Vault
    ,
    $Users
    ,
    $Groups
)
 #needs implementation
}