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


Describe "Remove-PSVaultCredential" -Tags Build , Unit{
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
    Remove-PSVaultCredential -Username SomeRandomUserID -force
  ' {
    $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    $script:location    = $vault.location
    $script:KeyLocation = $vault.GetSavedKeyLocation()
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential
    it '_The credential can be retrieved' {
      {
        $Credential|Get-PSVaultCredential
      } | should not throw
    }
    it 'removes a credential from the store'  {
      Remove-PSVaultCredential -Username SomeRandomUserID -force
    }
    it '_The credential is now gone' {
      {
        $Credential|Get-PSVaultCredential
      } | should throw
    }
  }
  & $aftereachContext
  
  context '
    $Credential1       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    $Credential2       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    $Credential3       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential1
    Add-PSVaultCredential -Credential $Credential2
    Add-PSVaultCredential -Credential $Credential3
    Get-PSVAultCredential|Remove-PSVaultCredential -force
  ' {
    $Credential1       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    $Credential2       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    $Credential3       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)
    $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    $script:location    = $vault.location
    $script:KeyLocation = $vault.GetSavedKeyLocation()
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential1
    Add-PSVaultCredential -Credential $Credential2
    Add-PSVaultCredential -Credential $Credential3
    
    it '_The credentials can be retrieved' {
      $Credential1,$Credential2,$Credential3|Get-PSVaultCredential|measure-object|Select-Object -ExpandProperty Count | should be 3
    }
    it 'removes selected credentials from the store'  {
      Mock Get-PSVaultCredential {return @($credential1,$Credential2)}
      {
        Get-PSvaultCredential|Remove-PSVaultCredential -force
      } | should not throw
    }
    it '_should not create vault files in the current path' {
      get-childitem | where {$_.Name -match '(SomeRandomUserID|ServiceAccount|Contoso)'} | Should -BeNullOrEmpty
    }
    it '_Two credentials are now gone' {
      $Global:PsVault.StoredCredentials.count | should be 1
    }
  }
  & $aftereachContext

  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
