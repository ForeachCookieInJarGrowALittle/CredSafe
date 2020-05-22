<#
.Synopsis
Retrieves a credential object from the PSVault
.Description
By providing an umambiguous username or selecting one through out-gridview retrieves information
from the PSVault to build a valid credential-object ready for use
.Parameter Username
Umambiguous username identifying a stored credential.
If ommited, you will be presented with all stored credentials
by the means of Out-Gridview -OutputMode Multiple.
#>
function Get-PSVaultCredential {
    [CmdletBinding()]
    
    Param(
        # Path where you want the PSVault to be stored
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault = $Global:PSVault
        ,
        [Parameter(ValueFromPipelineByPropertyName)]
        [String]
        $Username
    )
    Process {
        if ($PSBoundParameters.ContainsKey('Username')) {
            $Vault.GetCredential($Username)
        } else {
            $Vault.GetCredential()
        }
    }
}