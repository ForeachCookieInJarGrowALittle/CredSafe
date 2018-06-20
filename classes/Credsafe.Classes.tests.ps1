# this is a Pester test file
# load the script file into memory
. ($Script:PSCommandPath -replace '\.tests\.ps1$', '.ps1')
$SecurePassPhrase = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
$Credential1 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\Daniel", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential3 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\Daniel", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
$Credential2withnewpass = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "newpass" -AsPlainText -Force)

Describe 'CredSafe' {

  # scenario 1: working with a Clixml-file
  Context 'Clixml'   {
    $CredentialSafe = [CredSafe]::New("PesterCredentialSafe",$SecurePassPhrase)

    It 'Unlocking with a SecureString' {
      $CredentialSafe.Unlock($SecurePassPhrase)
      $CredentialSafe.Islocked | should -be $false
    }
    It 'Adding credentials should end up with the right amount of credentials in store' {
      $CredentialSafe.AddCredential($Credential1)
      $CredentialSafe.AddCredential($Credential2)
      $CredentialSafe.AddCredential($Credential3)
      $CredentialSafe.StoredCredentials.count | should -be 3
    }
    It 'Removing credential should decrease count'     {
      $CredentialSafe.RemoveCredential('Contoso\Daniel')
      $CredentialSafe.StoredCredentials.count | should -be 2
    }
    It 'Removing nonexistent should throw'     {
      {$CredentialSafe.RemoveCredential('Contoso\Daniel')}|should -throw
    }
    It 'Adding duplicate credential should throw'     {
      {$CredentialSafe.AddCredential($Credential1)}|should -throw
      $CredentialSafe.StoredCredentials.count | should -be 2
    }
    It 'Updating credential should not throw'     {
      {$CredentialSafe.UpdateCredential($Credential2withnewpass)} | should -not -throw
    }
    It 'Retrieving a credential'     {
      $CredentialSafe.GetCredential(".\Daniel").GetType().fullname | should -be $credential1.GetType().fullname
    }
    It 'Saving the credSafe'     {
      $CredentialSafe.Save()
      Test-Path ($CredentialSafe.Location)|should -be $true
    }
    It 'Save key locally' {
      $CredentialSafe.SaveKey()
      Test-Path $CredentialSafe.SavedKeyLocation | should -be $true
    }
    
    $newCredsafe = [Credsafe]::LoadFromXML("PesterCredentialSafe") 
    It 'Credsafe should exist'     {
      $newCredsafe | should -Not -BeNullOrEmpty
    }
    It 'Unlocking it should work without prompting for the key'     {
      {$newcredsafe.unlock()}|should -not -Throw
    }
    It 'There should be credentials in it'     {
      $newCredsafe.StoredCredentials.count | should -BeGreaterThan 0
    }    
  }
  
  #end Context Szenario 1
  #Szenario 2 Working with Database
  Context 'SQLDB' {
    $CredentialSafe = [Credsafe]::LoadFromXML("PesterCredentialSafe")
    $CredentialSafe.Unlock()
    $CredentialSafe.IsLocal = $false
    It 'Saving CredentialSafe to DB should not throw' {
      {$CredentialSafe.Save()} | should -not -Throw
    }
  }
}