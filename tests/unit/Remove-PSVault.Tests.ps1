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

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null


Describe "Remove-PSVault" -Tags Build , Unit{
  #remove artifacts from previous runs
  Get-ChildItem $env:LOCALAPPDATA\PSVault -filter pester* -Recurse|Remove-Item
  Get-ChildItem $env:LOCALAPPDATA\psvault -Recurse -Include * -Exclude Keys -Directory|Remove-Item -force -Recurse
  
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
    $vault = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString -SaveKey
    Remove-PSVault -Vault $vault -Force
  ' {
    it 'removes the vault' {
      $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Remove-PSVault -Vault $vault -force
      } | should not throw
    }
    it 'entirely.' {
      Test-Path $location | should be $false
      Test-Path $keylocation | should be $false
    }
  }
  & $aftereachContext

  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
