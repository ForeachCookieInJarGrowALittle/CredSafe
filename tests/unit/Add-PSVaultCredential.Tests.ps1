$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase        = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$SecureString      = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential        = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null


Describe "Add-PSVaultCredential" -Tags Build , Unit{
  #remove artifacts from previous runs
  Get-ChildItem $env:LOCALAPPDATA\PSVault -filter pester* -Recurse|Remove-Item
  Get-ChildItem $env:LOCALAPPDATA\psvault -Recurse -Include * -Exclude Keys -Directory|Remove-Item -force -Recurse
  
  $aftereachContext = {
    if (-not [String]::IsNullOrEmpty($KeyLocation)) {
      remove-item $KeyLocation -Force -ErrorAction SilentlyContinue
      remove-variable -Name KeyLocation -ErrorAction SilentlyContinue
    } 
    if (-not [String]::IsNullOrEmpty($location)) {
      remove-item $location -Force -ErrorAction SilentlyContinue
      Remove-Variable -Name Location -ErrorAction SilentlyContinue
    }
    if (-not [string]::IsNullOrEmpty($Global:PSVault)) {
      $Global:PSVault = $null
    }
  }
    
  context '
    $Vault = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Add-PSVaultCredential -Vault $Vault
  ' {
    Mock Get-Credential {return $Credential}
    it 'adds a credential to the vault.' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Add-PSVaultCredential -Vault $Vault
      } | should not throw
    }
    it 'By asking you to enter username and password.'  {
      Assert-MockCalled -CommandName Get-Credential -Times 1
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Add-PSVaultCredential
  ' {
    Mock Get-Credential {return $Credential}
    it 'will fail, because you are not yet connected to a vault.' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Add-PSVaultCredential
      } | should throw
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
    Add-PSVaultCredential
  ' {
    Mock Get-Credential {return $Credential}
    it 'will work just fine, when you are connected to a vault.' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      $null = Connect-PSVault -Name Pester
      {
        Add-PSVaultCredential
      } | should not throw
    }
    it 'By asking you to enter username and password.'  {
      Assert-MockCalled -CommandName Get-Credential -Times 1
    }
    it '_Vault will now contain 1 Credential.' {
      $Global:PSVault.StoredCredentials.count| should be 1
    }
  }
  & $aftereachContext
  
  context '
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential
    Add-PSVaultCredential -Credential $Credential
  ' {
    Mock Get-Credential {return $Credential}
    it 'Adds a Credential as well, as long as you are already connected to a vault..' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      Connect-PSVault -Name Pester
      {
        Add-PSVaultCredential -Credential $Credential
      } | should not throw
    }
    it 'Without asking you to enter username and password.'  {
      Assert-MockCalled -CommandName Get-Credential -Times 0
    }
    it ('_Vault will now contain 1 Credential.' -f $KeyLocation) {
      Test-Path $location|should be true
    }
    it 'But adding the same credential twice, or another one with the same username, will fail' {
      {
        Add-PSVaultCredential -Credential $Credential
      } | should throw
    }
  }
  & $aftereachContext
}
