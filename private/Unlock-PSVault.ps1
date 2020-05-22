<#
.Synopsis
Unlocks a PSVault
.Description
Tries to unlock the PSVault with a stored Masterkey.
If it can't find one, or the one stored does not work it asks for input.
If the unlocking succeeds, the PSVault is stored in $Global:PSVault
.Parameter VaultPassword
Secure.String representing the VaultPassword
#>
function Unlock-PSVault {
    [CmdletBinding(SupportsShouldProcess)]
    
    Param(
        # Path where you want the PSVault to be stored
        [Parameter(Mandatory,ValueFromPipeline = $true)]
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault
        ,
        [Parameter(ValueFromPipeline = $true)]
        [SecureString]
        $VaultPassword = (Read-Host -assecurestring 'Enter VaultPassword:')
    )
    if ($PSCmdlet.ShouldProcess($Vault.Name,'Unlock PSVault with Name {0}' -f $Vault.Name)) {
        try {
          if ($PSBoundParameters.ContainsKey('VaultPassword')) {
            $Vault.Unlock($VaultPassword)
          } else {
            $Vault.Unlock()
          }
          $Global:PSVault = $Vault
        } catch {
          throw ('The password provided could not be used to unlock the PSVault {0}' -f $Vault.Name)
        }
    }
}