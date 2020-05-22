<#
.Synopsis
Change the VaultPassword used to encrypt the secrets
.Description
Decrypts all Passwords and encrypts them again with the newly generated key
by providing a new password.
.Parameter Vault
Vault to change the password for.
Defaults to the currently connected one.
.Parameter NewPassword
Password used to generate new key.
.Parameter Force
Avoid beeing prompted.
#>
function Update-PSVaultPassword {
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(ValueFromPipeline)]
    [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
    $Vault = $Global:PSVault
    ,
    [Parameter(Mandatory)]
    [System.Security.SecureString]
    $NewPassword
    ,
    [Switch]
    $force
)
    Process {
        $OldKey = $Vault.Key
        $NewKey = [PSVaultTools]::NewKey($NewPassword)
        if ($force -or $PSCmdlet.ShouldContinue($Vault.Name,'Change Vaultpassword')) {
            $Vault.CheckSum = $Vault.CheckSum|ConvertTo-SecureString -Key $OldKey|ConvertFrom-SecureString -Key $NewKey
            $Vault.StoredCredentials.foreach{
                $_.EncryptedPassword = $_.EncryptedPassword|ConvertTo-SecureString -Key $OldKey|ConvertFrom-SecureString -Key $NewKey
            }
            $Vault.WhenChanged = Get-Date
            $Vault.ModifiedBy = $Env:USERNAME
            $Vault.Key = $NewKey
            $Vault.Save()
            if (Test-Path ($vault.GetSavedKeyLocation())) {
                Save-PSVaultKey -Vault $Vault
            }
            Write-Warning -Message 'Do not forget to tell everyone else about the change.'
        }
    }
}