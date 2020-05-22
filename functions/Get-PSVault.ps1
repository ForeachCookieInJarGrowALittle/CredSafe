<#
.Synopsis
Opens a previously saved vault
.Description
Opens a previously saved vault. Target can be specified via the fullpath or the name
of a vault existing in the default location.
You can provide the VaultPassword via a [SecureString] or enter it when prompted.
If the Vaultpassword has been saved before, it will be loaded automatically.
.Parameter Path
Fullpath to the vault.
.Parameter Name
Can be used, when the vault is saved in the default location.
.Parameter VaultPassword
Password used to decrypt the key used for vault-encryption.
If it has been saved before, it will be loaded automatically.
#>
function Get-PSVault {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    Param(
        # Path to where the PSVault is stored
        [Parameter(Mandatory=$false,ParameterSetName = "Path",Position=0)]
        [ValidateScript({Test-Path ([PSVault]::Parse($_))})]
        [String]
        $Path = [PSVault]::GetDefaultVaultLocation()
        ,
        [Parameter(Mandatory=$true,ParameterSetName = 'Name',Position=0)]
        [ValidateScript({Test-Path ([PSVault]::GetDefaultVaultLocation($_))})]
        [string]
        $Name = [PSVault]::GetDefaultVaultName()
        ,
        [Parameter(Position=1)]
        [System.Security.SecureString]
        $VaultPassword
    )
    if ($PSCmdlet.ParameterSetName -eq "Name") {
        $Path = [PSVault]::GetDefaultVaultLocation($Name)
    } else {
        $Path = [PSVault]::Parse($Path)
    }
    Write-Verbose ('Loading PSVault from {0}' -f $Path)
    if (-not [string]::IsNullOrEmpty($VaultPassword)) {
        return [PSVault]::LoadFromPath($Path,$VaultPassword)
    } else {
        return [PSVault]::LoadFromPath($Path)
    }
}