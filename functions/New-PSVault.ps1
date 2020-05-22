<#
.Synopsis
Creates a new vault
.Description
Creates a new vault and saves it to either the default location or a specified one.
You can provide the VaultPassword via a [SecureString] or enter it when prompted.
The resulting key can be saved immediatly by using the -SaveKey [switch]
.Parameter Path
Fullpath to where you want the PSVault to be stored, if you ommit the .psvault extension
it will be appended. Can be any target where you can write to.
.Parameter Name
By providing a name you will create a Vault in the default location that goes by the name
<chosen_name>.PSVault
.Parameter VaultPassword
Password used to encrypt the key used for vault-encryption.
.Parameter SaveKey
Saves the key for future use, so you won't be prompted.
#>
function New-PSVault {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    Param(
        # Path where you want the PSVault to be stored  
        [Parameter(ParameterSetName = 'Path')]
        [ValidateScript({-not (Test-Path -Path $_)})]
        [String]
        $Path = ([PSVault]::GetDefaultVaultLocation())
        ,
        [Parameter(ParameterSetName = 'Name')]
        [ValidateScript({-not (Test-Path -Path ([PSVault]::GetDefaultVaultLocation($_)))})]
        [String]
        $Name = $Env:Username
        ,
        [SecureString]
        $VaultPassword
        ,
        [Switch]$SaveKey
    )
    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $Path = [PSVault]::GetDefaultVaultLocation($Name)
    } else {
        $Path = [PSVault]::Parse($Path)
    }
    if ($PSBoundParameters.ContainsKey('VaultPassword')) {
        $Vault = [PSVault]::New($Path,$VaultPassword)
    } else {
        $Vault = [PSVault]::New($Path)
    }
    if ($SaveKey) {
        Save-PSVaultKey -Vault $Vault
    }
    return $Vault
}