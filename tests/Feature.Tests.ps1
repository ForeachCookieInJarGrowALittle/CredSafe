$script:ModuleName = 'PSVault'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path

# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'Tests') {
  $ModuleBase = Split-Path $ModuleBase -Parent
}

#Variables
$SecurePassPhrase       = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential1            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
#$Credential2            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2withnewpass = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "newpass"    -AsPlainText -Force)



Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null
Describe "Basic function feature tests" -Tags Build {
  #Remove Artifacts from previous runs
  Get-ChildItem $Env:PSVaultLocation -filter DemoPSVault -Recurse|remove-item -force

  
  Context 'Locally'   {
    Initialize-PSVaultDemo -ErrorAction SilentlyContinue
    #Here are the values that are initialized by the command above

    It 'The PSVault Context should be set' {
      $Global:PSVault | should not BeNullOrEmpty
    }
    It 'There Should be 3 Credential in the Store' {
      $Global:PSVault.StoredCredentials.count | should Be 3
    }
    It 'Removing credential should decrease count'     {
      Remove-PSVaultCredential -Username 'Contoso\SomeRandomUserID' -force
      $Global:PSVault.StoredCredentials.count | should Be 2
    }
    It 'Removing nonexistent should throw'     {
      {Remove-PSVaultCredential -Username 'Contoso\SomeRandomUserID' -force}|should Throw
    }
    it 'Re-adding the credential should work' {
      Add-PSVaultCredential -Credential $Credential3 
    }
    It 'Adding duplicate credential should throw'     {
      {Add-PSVaultCredential -Credential $Credential3}|should Throw
      $Global:PSVault.StoredCredentials.count | should Be 3
    }
    It 'Updating credential should not throw'     {
      {Set-PSVaultCredential -Credential $Credential2withnewpass} | should not Throw
    }
    It 'Retrieving a credential'     {
      (Get-PSVaultCredential -Username "SomeRandomUserID").GetType().fullname | should Be $credential1.GetType().fullname
    }
    It 'Save key locally' {
      Save-PSVaultKey -PSVault $Global:PSVault
      Test-Path $Global:PSVault.GetSavedKeyLocation() | should Be $true
    }   
  }

  Context 'Remote' {
    It 'Connecting to a "remote" Vault works' {
      {Connect-PSVault -Path $ModuleBase\Docs\ReferencePSVault -VaultPassword $SecurePassPhrase}|should not Throw
    }
  }
}
