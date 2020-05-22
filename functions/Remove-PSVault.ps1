<#
.Synopsis
Deletes a vault by removing corresponding files
.Description
Deletes a vault by removing corresponding files
.Parameter PSVault
PSVault Object to delete
.Parameter Force
If used allows for deletion without being prompted.
#>
function Remove-PSVault {
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Vault
        ,
        [Switch]
        $force
    )
    if ($force -or $PSCmdlet.ShouldContinue('{0}' -f $Vault.Name, 'Do you really want to delete the PSVault with the Name')) {
        if (-not [string]::IsNullOrEmpty($global:PSVault)) {
            if ($vault.location -eq $global:PSVault.location) {
                $global:PSVault = $null
            }
        }
        Remove-Item -Path $Vault.GetSavedKeyLocation() -force
        Remove-Item -Path $Vault.Location -force
    }
}