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

Describe "New-PSVault" -Tags Build , Unit{
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
  
  context 'New-PSVault' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault named after your user' {
      {
        $Vault           = New-PSVault
        $script:location = $Vault.location
      } | should not throw
    }
    
    it 'by asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 1
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }

  }
  & $aftereachContext
  
  context 'New-PSVault -VaultPassword $SecureString' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault named after your user' {
      {
        $vault           = New-PSVault -VaultPassword $SecureString
        $script:location = $vault.location
      } | should not throw
    }
    
    it 'without asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext
  
  context 'New-PSVault -Name Pester' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault named Pester.psvault' {
      {
        $Vault           = New-PSVault -Name Pester
        $script:location = $Vault.location
      } | should not throw
    }
    
    it 'by asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 1
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext
  
  context 'New-PSVault -Name Pester -VaultPassword $SecureString' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault named Pester.psvault' {
      {
        $vault           = New-PSVault -Name Pester -VaultPassword $SecureString
        $script:location = $vault.location
      } | should not throw
    }
    
    it 'without asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext
  
  context 'New-PSVault -Path $($temporaryFolder.Fullname)\Pester' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault in the provided location' {
      {
        $vault           = New-PSVault -Path "$($temporaryFolder.Fullname)\Pester"
        $script:location = $vault.location
      } | should not throw
    }
    
    it 'by asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 1
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext
  
  context 'New-PSVault -path $($temporaryFolder.Fullname)\Pester -VaultPassword $SecureString' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault in the provided location' {
      {
        $vault           = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
        $script:location = $vault.location
      } | should not throw
    }
    
    it 'without asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
  }
  & $aftereachContext
  
  context 'New-PSVault -path $($temporaryFolder.Fullname)\Pester -VaultPassword $SecureString -SaveKey' {
    
    Mock Read-Host {return $SecureString}
    
    it 'creates a vault in the provided location' {
      {
        $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString -SaveKey
        $script:location    = $vault.location
        $script:KeyLocation = $vault.GetSavedKeyLocation()
      } | should not throw
    }
    
    it 'without asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }   
    
    it ('It will be saved in {0}.' -f $location) {
      Test-Path $location|should be true
    }
    
    it ('But this time the key will be saved too. It will be saved in {0}.' -f $KeyLocation) {
      Test-Path $KeyLocation | Should be true
    }
  }   
  & $aftereachContext
  
  
  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}

