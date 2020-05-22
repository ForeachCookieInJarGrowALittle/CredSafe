$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase        = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}
$script:WarningPreference = 'SilentlyContinue'
#Variables
$SecureString      = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$NewPassword       = ConvertTo-SecureString -AsPlainText -Force -String "FeelFreeToShareWithYourTeam"
# Those Credentials are in the DemoVault as well
$Credential1       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

Describe "Update-PSVaultPassword" -Tags Build , Unit{
  #remove artifacts from previous runs
  Get-ChildItem $env:LOCALAPPDATA\PSVault -filter pester* -Recurse|Remove-Item
  Get-ChildItem $env:LOCALAPPDATA\PSvault -Recurse -Include * -Exclude Keys -Directory|Remove-Item -force -Recurse
  
  $TemporaryFolder  = New-Item "$env:LOCALAPPDATA\PSVault\Test_$(Get-date -Format yyyyMMddHHmm)\Pester" -ItemType Directory
  
  $aftereachContext = {
    if (-not [String]::IsNullOrEmpty($KeyLocation)) {
      remove-item $KeyLocation -Force -ErrorAction SilentlyContinue
      remove-variable -Name KeyLocation -ErrorAction SilentlyContinue
    } 
    if (-not [String]::IsNullOrEmpty($location)) {
      remove-item $location -Force -ErrorAction SilentlyContinue
      Remove-Variable -Name Location -ErrorAction SilentlyContinue
    }
  }
  
    
  context '
    $NewPassword = ConvertTo-SecureString -AsPlainText -Force -String "FeelFreeToShareWithYourTeam"
    Initialize-PSVaultDemo
    Update-PSVaultPassword -Vault $Global:PSVault -NewPassword $NewPassword
  ' {
    Mock Read-Host {return $NewPassword}
    Initialize-PSVaultDemo -Force
    $Global:PSVault.ModifiedBy = 'RandomOtherUser'
    it 'decrypts all your passwords with the old key and encrypts them again with the new one.' {
      $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Update-PSVaultPassword -NewPassword $NewPassword -force
      } | should not throw
    }
    it 'You can provide the password as a [SecureString] or enter it when prompted' {
      Test-Path $location|should be true
    }
    it '_Connecting with the old VaultPassword stops working' {
      Connect-PSVault -Name Demo -VaultPassword $SecureString | should be $false
    }
    it 'Also saves the new key, if the old one has been saved as well' {
      Connect-PSVault -Name Demo | should be $true
    }
    it '_Also updates the WhenChanged' {
      $Global:PSVault.WhenChanged | should not be $Global:PSVault.WhenCreated
    }
    it '_and ModifiedBy attributes of the vault.' {
      $Global:PSVault.ModifiedBy | should be $env:username
    }
  }
  & $aftereachContext

  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
