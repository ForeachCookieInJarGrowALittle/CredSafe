# this is a Pester test file
# load the script file into memory
. ($Script:PSCommandPath -replace '\.tests\.ps1$', '.ps1')
$SecurePassPhrase       = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential1            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2withnewpass = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "newpass"    -AsPlainText -Force)

Describe 'PSVault' {

  # scenario 1: working with a Clixml-file
  Context 'Clixml'   {
    $Vault = [PSVault]::New("PesterPSVault",$SecurePassPhrase)

    It 'Unlocking with a SecureString' {
      {$Vault.Unlock($SecurePassPhrase)} | should -not -throw
    }
    It 'Adding credentials should end up with the right amount of credentials in store' {
      $Vault.AddCredential($Credential1)
      $Vault.AddCredential($Credential2)
      $Vault.AddCredential($Credential3)
      $Vault.StoredCredentials.count | should -be 3
    }
    It 'Removing credential should decrease count'     {
      $Vault.RemoveCredential('Contoso\SomeRandomUserID')
      $Vault.StoredCredentials.count | should -be 2
    }
    It 'Removing nonexistent should throw'     {
      {$Vault.RemoveCredential('Contoso\SomeRandomUserID')}|should -throw
    }
    It 'Adding duplicate credential should throw'     {
      {$Vault.AddCredential($Credential1)}|should -throw
      $Vault.StoredCredentials.count | should -be 2
    }
    It 'Updating credential should not throw'     {
      {$Vault.UpdateCredential($Credential2withnewpass)} | should -not -throw
    }
    It 'Retrieving a credential'     {
      $Vault.GetCredential(".\SomeRandomUserID").GetType().fullname | should -be $credential1.GetType().fullname
    }
    It 'Saving the PSVault'     {
      $Vault.Save()
      Test-Path ($Vault.Location)|should -be $true
    }
    It 'Save key locally' {
      $Vault.SaveKey()
      Test-Path $Vault.GetSavedKeyLocation() | should -be $true
    }
    
    $newPSVault    = [PSVault]::LoadFromPath("PesterPSVault") 
    It 'PSVault should exist'     {
      $newPSVault | should -Not -BeNullOrEmpty
    }
    It 'Unlocking it should work without prompting for the key'     {
      {$newPSVault.unlock()}|should -not -Throw
    }
    It 'There should be credentials in it'     {
      $newPSVault.StoredCredentials.count | should -BeGreaterThan 0
    }    
  }
  
  #end Context Szenario 1
  #Szenario 2 Working with Database
  Context 'SQLDB' {
    $Vault         = [PSVault]::LoadFromPath("PesterPSVault")
    $Vault.Unlock()
    $Vault.IsLocal = $false
    It 'Saving PSVault to DB should not throw' {
      {$Vault.Save()} | should -not -Throw
    }
  }
}


#Cleanup
