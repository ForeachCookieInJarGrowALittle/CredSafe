<#
.Synopsis
Opens a previously saved vault for easy access.
.Description
Opens a previously saved vault for easy access. Target can be specified via the 
fullpath or the name of a vault existing in the default location.
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
function Connect-PSVault {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    Param(
        # Path to where the PSVault is stored
        [Parameter(ParameterSetName = "Path")]
        [ValidateScript({Test-Path ([PSVault]::Parse($_))})]
        [String]
        $Path = [PSVault]::GetDefaultVaultLocation()
        ,
        [Parameter(Mandatory=$true,ParameterSetName = 'Name',ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateScript({test-path ([PSVault]::GetDefaultVaultLocation($_))})]
        [string]
        $Name
        ,
        [Parameter(Position = 1)]
        [SecureString]
        $VaultPassword
    )
    try {
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            $Path = [PSVault]::GetDefaultVaultLocation($Name)
            write-verbose $Path
        }
        if (-not [string]::IsNullOrEmpty($VaultPassword)) {
            $Global:PSVault = Get-PSVault -Path $Path -VaultPassword $VaultPassword
        } else {
            $Global:PSVault = Get-PSVault -Path $Path
        }
        write-verbose ('You are now connected to {0}' -f $Global:PSVault.Name)
        return $true
     } catch {
        return $false
     }
}