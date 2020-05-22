<#
.Synopsis
Adds and encrypts a credential to the vault.
.Description
Adds and encrypts a credential to the vault.
.Parameter Vault
Vault to add the credential to. Default to the connected vault.
.Parameter Credential
Credential to add.
#>
function Add-PSVaultCredential {
    [CmdletBinding(SupportsShouldProcess)]
    
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [Management.Automation.PSCredential]
        $Credential = (Get-Credential -Message 'Enter Username and Password:')
        ,
        # Path where you want the PSVault to be stored
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault = $Global:PSVault
    )
    if ([String]::IsNullOrEmpty($Vault)) {
        throw 'Not yet connect, use Connect-PSVault or specify a vault.'
    }
    if ($PSCmdlet.ShouldProcess($Vault.Name,'Add Credential with Name {0} to' -f $Credential.UserName)) {
        $Vault.AddCredential($Credential)
    }
}