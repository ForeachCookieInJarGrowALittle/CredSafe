<#
.Synopsis
Initialize a Demo PSVault
.Description
Initialize a PSVault either for testing or demo purposes
#>
function Initialize-PSVaultDemo {
  [Cmdletbinding()]
  Param(
    [Switch]$force
  )
  $SecurePassPhrase       = ConvertTo-SecureString -AsPlainText -Force -String "Don't tell anyone"
  $Credential1            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "SomeRandomUserID",         (ConvertTo-SecureString "securepass" -AsPlainText -Force)
  $Credential2            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ".\ServiceAccount", (ConvertTo-SecureString "securepass" -AsPlainText -Force)
  $Credential3            = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "Contoso\SomeRandomUserID",   (ConvertTo-SecureString "securepass" -AsPlainText -Force)
  if ($force) {
    Get-ChildItem $Env:LOCALAPPDATA\PSVault -filter Demo.* -File|Remove-Item -Force
  }
  Try {
    Write-Verbose 'Creating DemoPSVault'
    $null = New-PSVault -Name Demo -VaultPassword $SecurePassPhrase -SaveKey
    $null = Connect-PSVault -Name Demo
    Write-Verbose 'Adding Credential .\SomeRandomUserID'
    Add-PSVaultCredential -Credential $Credential1
    Write-Verbose 'Adding Credential .\ServiceAccount'
    Add-PSVaultCredential -Credential $Credential2
    Write-Verbose 'Adding Credential Contoso\SomeRandomUserID'
    Add-PSVaultCredential -Credential $Credential3
  } catch {
    Write-verbose 'DemoPSVault already existed... loading'
    Connect-PSVault -Name Demo
  } 
}