$script:ModuleName         = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase                = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
while ((Split-Path $ModuleBase -Leaf) -ne $ModuleName) {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$SecureString              = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential                = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "securepass"  -AsPlainText -Force)
$CredentialWithNewPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "anotherpass" -AsPlainText -Force)
$NewPassword               = ConvertTo-SecureString -AsPlainText -Force -String "evenmoresecurepass"


## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase            = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null

## this variable is for the VSTS tasks and is to be used for referencing any mock artifacts
$Env:ModuleBase            = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null


Describe 'Update-PSVAultCredential' -Tags Build , Unit {
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
  
    
  context @'
  $SecureString              = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
  $Credential                = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "securepass"  -AsPlainText -Force)
  $CredentialWithNewPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "anotherpass" -AsPlainText -Force)
  $NewPassword               = ConvertTo-SecureString -AsPlainText -Force -String "evenmoresecurepass"
  New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
  Connect-PSVault -Name Pester
  Add-PSVaultCredential -Credential $Credential
'@ {
    $SecureString              = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
    $Credential                = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "securepass"  -AsPlainText -Force)
    $CredentialWithNewPassword = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",(ConvertTo-SecureString "anotherpass" -AsPlainText -Force)
    $NewPassword               = ConvertTo-SecureString -AsPlainText -Force -String "evenmoresecurepass"
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
    Add-PSVaultCredential -Credential $Credential
    
    it '
      Update-PSVaultCredential -Username SomeRandomUserID -NewPassword $NewPassword
      will change the password to "evenmoresecurepass"
    ' {
      Update-PSVaultCredential -Username SomeRandomUserID -NewPassword $NewPassword
      Convert-SecureStringToPlainText ($credential|Get-PSVaultCredential).Password | Should be 'evenmoresecurepass'
    }
    
    it '
      Update-PSVaultCredential -Credential $CredentialWithNewPassword
      will change the password to "anotherpass"
    ' {
      Update-PSVaultCredential -Credential $CredentialWithNewPassword
      Convert-SecureStringToPlainText ($credential|Get-PSVaultCredential).Password | Should be 'anotherpass'
    }
    
    it '
      Update-PSVaultCredential -Credential $CredentialWithNewPassword -NewPassword $NewPassword
      will change the password to "evenmoresecurepass" again
    ' {
      Update-PSVaultCredential -Credential $CredentialWithNewPassword -NewPassword $NewPassword
      Convert-SecureStringToPlainText ($credential|Get-PSVaultCredential).Password | Should be 'evenmoresecurepass'
    }
  }
  & $aftereachContext
  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
