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


Describe "Connect-PSVault" -Tags Build , Unit{
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
    New-PSVault -Name Pester
    Connect-PSVault -Name Pester
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -Name Pester
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -Name Pester -VaultPassword $SecureString
      } | should be $true
    }
    it 'By asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 1
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -Name Pester -VaultPassword $SecureString
    Connect-PSVault -Name Pester -VaultPassword $SecureString
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -Name Pester -VaultPassword $SecureString
      } | should be $true
    }
    it ('Without prompting for a password.' -f $KeyLocation) {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
    Connect-PSVault -Name Pester
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -Name Pester -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -Name Pester -VaultPassword $SecureString
      } | should be $true
    }
    it ('Without prompting for a password. Because the key has been auto-loaded.' -f $KeyLocation) {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -path "$($temporaryFolder.Fullname)\Pester"
    Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester"
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester"
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      } | should be $true
    }
    it 'By asking for a password.' {
      Assert-MockCalled -CommandName Read-Host -Times 1
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
    Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      } | should be $true
    }
    it ('Without prompting for a password.' -f $KeyLocation) {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
  }
  & $aftereachContext
  
  context '
    New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString -SaveKey
    Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester"
  ' {
    Mock Read-Host {return $SecureString}
    it 'connects to the specified vault.' {
      $vault              = New-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString -SaveKey
      $script:location    = $vault.location
      $script:KeyLocation = $vault.GetSavedKeyLocation()
      {
        Connect-PSVault -path "$($temporaryFolder.Fullname)\Pester" -VaultPassword $SecureString
      } | should be $true
    }
    it ('Without prompting for a password. Because the key has been auto-loaded.' -f $KeyLocation) {
      Assert-MockCalled -CommandName Read-Host -Times 0
    }
  }
  & $aftereachContext

  Remove-Item $TemporaryFolder.FullName -Recurse -Force    
}
