<#
.Synopsis
Saves the Key for a given PSVault locally
.Description
Saves the Key for a given PSVault locally in $ENV:LOCALAPPDATA\PSVault\Keys
#>
function Save-PSVaultKey {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        # Path where you want the PSVault to be stored
        [Parameter(Mandatory,ValueFromPipeline = $true)]
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault
    )
    if ($PSCmdlet.ShouldProcess($Vault.Name,'Save Key for PSVault with the Name {0}' -f $Vault.Name)) {
        $Vault.SaveKey()
    }
}