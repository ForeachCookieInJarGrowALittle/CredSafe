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


Describe "Get-PSVaultCredential" -Tags Build , Unit{
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
    if (-not [string]::IsNullOrEmpty($Global:PSVault)) {
      $Global:PSVault = $null
    }
  }
  
  context '
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential
    Get-PSVaultCredential -Username SomeRandomUserID
  ' {
    $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    $script:location    = $vault.location
    $script:KeyLocation = $vault.GetSavedKeyLocation()
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential
    $Credential = Get-PSVaultCredential -Username SomeRandomUserID
    
    it 'Retrieves the corresponding credential from the connected vault.' {
      
      $Credential.GetType().Fullname | Should Be 'System.Management.Automation.PSCredential'
    }
    it '_The username should be SomeRandomUserID'  {
      $Credential.UserName | Should Be 'SomeRandomUserID'
    }
    it ('_The password should be securepass.' -f $KeyLocation) {
      Convert-SecureStringToPlainText $Credential.Password|should be 'securepass'
    }
  }
  & $aftereachContext
  
  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
