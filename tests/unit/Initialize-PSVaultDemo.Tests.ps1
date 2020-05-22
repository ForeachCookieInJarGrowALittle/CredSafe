$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase        = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$Credential1       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3       = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase    = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

Describe "Initialize-PSVaultDemo" -Tags Build , Unit{
  if ($vault = Get-PSVault -Name Demo) {
    $Vault | Remove-PSVault -force
  }
  Context 'Initialize-PSVaultDemo' {
    it 'creates a Demo-Vault' {
      {Initialize-PSVaultDemo} | should not throw
    }
    it 'saves the key' {
      {test-path $Global:PSVault.GetSavedKeyLocation()} | should be $true
    }
    it 'and connects to it.' {
      $Global:PSVault.Name | should be 'Demo'
    }
    it 'There are three credentials stored inside for you to play with.' {
      $Global:PSVault.StoredCredentials.count | should be 3
    }
  }
  
  Context 'Initialize-PSVaultDemo -Force' {
    it '_Setup a modified vault' {
      {
        Initialize-PSVaultDemo
        @($Credential1,$Credential2,$Credential3)|Remove-PSVaultCredential -force
      } | should not throw
    }
    it '_There should be no more credentials in the store.' {
      $Global:PSVault.StoredCredentials.count | should be 0
    }
    it 'restores a Demo-Vault to its intended state.' {
      {Initialize-PSVaultDemo -force} | should not throw
    }
    it 'saves the key' {
      {test-path $Global:PSVault.GetSavedKeyLocation()} | should be $true
    }
    it 'and connects to it.' {
      $Global:PSVault.Name | should be 'Demo'
    }
    it 'All credentials in the store have been restored.' {
      $Global:PSVault.StoredCredentials.count | should be 3
    }
  }
  
}
