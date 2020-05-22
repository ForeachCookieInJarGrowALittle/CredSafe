$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase        = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$SecureString      = ConvertTo-SecureString -AsPlainText -Force -String "encryptme"

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

Describe "Convert-SecureStringToPlainText" -Tags Build , Unit{
  Context 'ConvertTo-SecureString -AsPlainText -Force -String "encryptme"|Convert-SecureStringToPlainText' {
    it 'decrypts the provided securestring back to plaintext' {
      ConvertTo-SecureString -AsPlainText -Force -String "encryptme"|Convert-SecureStringToPlainText
    }
  }
}
