<#
.Synopsis
Removes a credential from a given vault.
.Description
By providing a credential-Object via the Pipe or an unambiguous username remove the corresponding credential from the PSVault
.Parameter PSVault
Vault to remove the credentials from
.Parameter Username
Username of the credential to remove
.Parameter Force
Suppress confirmation
#>
function Remove-PSVaultCredential {
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification = "It actually is being called.")] 
    Param(
        # Path where you want the PSVault to be stored
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault = $Global:PSVault
        ,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName = $true)]
        [String]
        $Username
        ,
        [switch]
        $force
    )
    Process {
        if ($force -or $PSCmdlet.ShouldContinue($Vault.Name,'Remove Credential with Name {0} from ' -f $UserName)) {
            $Vault.RemoveCredential($UserName)
        }
    }
}