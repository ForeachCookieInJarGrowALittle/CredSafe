<#
.Synopsis
Update a specific credential in a PSVault.
.Description
Update a specific credential in a PSVault.
.Parameter Credential
Credential you want to update
.Parameter Username
Username identifying the credential you want to update.
.Parameter NewPassword
When providing a credential, you can optionally provide a new password this way as well.
When providing a username the parameter is mandatory.
.Parameter PSVault
Can be omitted, defaults to $Global:PSVault
#>
function Update-PSVaultCredential {
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName = 'Username')]
    
    Param(
        # Path where you want the PSVault to be stored
        [ValidateScript({$_.Gettype().fullname -eq 'PSVault'})]
        $Vault = $Global:PSVault
        ,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName  = 'Username')]
        [string]
        $Username
        ,
        #[Parameter(ParameterSetName = 'Credential')]
        #[Parameter(ParameterSetName = 'UserName', Mandatory)]
        [System.Security.SecureString]
        $NewPassword
        ,
        [Parameter(Mandatory,ParameterSetName = 'Credential')]
        [Management.Automation.PSCredential]
        $Credential
    ) 
    Process {
        if ($PSCmdlet.ParameterSetName -eq 'Credential') {
            $Username = $Credential.UserName
            if ([String]::IsNullOrEmpty($NewPassword)) {
                $NewPassword = $Credential.Password
            }
        }
        if ($PSCmdlet.ShouldProcess($Vault.Name,'Update Credential with Name {0}' -f $Credential.UserName)) {
            $Vault.UpdateCredential($Username,$NewPassword)
        }
    }
}