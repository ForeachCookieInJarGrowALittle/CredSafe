# Some tools for generating ByteArrays from Securestrings and working with securestrings
Class PSVaultTools {
  
  static [String] ConvertSecureStringToPlainText([SecureString]$SecureString) {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
    
  static [Byte[]] NewKey() {
    $hasher = new-object System.Security.Cryptography.SHA256Managed
    $SecureString = $(Read-Host -AsSecureString "Enter VaultPassword")
    $toHash = [System.Text.Encoding]::UTF8.GetBytes([PSVaultTools]::ConvertSecureStringToPlainText($SecureString))
    return $hasher.ComputeHash($toHash)
  }
  
  static [Byte[]] NewKey([SecureString]$SecureString) {
    $hasher = new-object System.Security.Cryptography.SHA256Managed
    $toHash = [System.Text.Encoding]::UTF8.GetBytes([PSVaultTools]::ConvertSecureStringToPlainText($SecureString))
    return $hasher.ComputeHash($toHash)
  }  

}

# This is how Credentials are stored - The main idea is, to take the 32-Byte Array received from
# hashing and use it to convertfrom-securestring
# The constructors take PSCredential, PSObject (the ones you get from Import-CliXML) or Datarows
# as Input, so you can either save your Credentials in a Database or a CliXML
# The ToString-Method is mainly for Identification-Purposes
Class VaultCredential {
  [String]   $CreatedBy
  [String]   $ModifiedBy
  [DateTime] $WhenCreated
  [DateTime] $WhenChanged
  [String]   $Username
  [String]   $EncryptedPassword
  
  VaultCredential ([System.Management.Automation.PSCredential]$PSCredential,[Byte[]]$Key) {
    $this.EncryptedPassword = $PSCredential.Password|ConvertFrom-SecureString -Key $Key
    $this.Username          = $PSCredential.UserName
    $now                    = Get-Date
    $this.WhenCreated       = $now
    $this.WhenChanged       = $now
    $this.CreatedBy         = $env:USERNAME
    $this.ModifiedBy        = $env:USERNAME
  }
  
  VaultCredential ([Psobject]$Deserialized) {
    $this.CreatedBy         = $Deserialized.CreatedBy
    $this.EncryptedPassword = $Deserialized.EncryptedPassword
    $this.Username          = $Deserialized.Username
    $this.WhenChanged       = $Deserialized.WhenChanged
    $this.WhenCreated       = $Deserialized.WhenCreated
    $this.ModifiedBy        = $Deserialized.ModifiedBy
  }
  
  VaultCredential ([System.Data.DataRow]$DataRow) {
    $this.CreatedBy         = $DataRow.CreatedBy
    $this.EncryptedPassword = $DataRow.EncryptedPassword
    $this.Username          = $DataRow.Username
    $this.WhenChanged       = $DataRow.WhenChanged
    $this.WhenCreated       = $DataRow.WhenCreated
    $this.ModifiedBy        = $DataRow.ModifiedBy
  }
  
  [string] ToString() {
    return $this.Username
  }
}

# This is where you store your credentials and retrieve them when you need to
Class PSVault {
                    [String] $Name               = [PSVault]::GetDefaultVaultName()
                    [String] $Checksum           #is used to validate provided vaultpasswords
                    [String] $CreatedBy          = $Env:USERNAME
                    [String] $ModifiedBy         = $Env:USERNAME
                  [DateTime] $WhenCreated        = $(Get-Date)
                  [DateTime] $WhenChanged        = $(Get-Date)
         [VaultCredential[]] $StoredCredentials
  hidden            [Byte[]] $Key
  hidden            [String] $SavedKeyLocation   #may well be deprecated...inestigate
  hidden            [String] $Location           #marks the location the vault has been loaded from

  #region helpermethods
         hidden [String] GetSavedKeyLocation() {
    return (Join-Path $Env:PSVaultKeyLocation ($this.Name + '.key'))
  }

  static hidden [String] GetDefaultVaultName() {
    return ('{0}.psvault' -f $env:username)
  }

  static hidden [String] GetDefaultVaultLocation() {
    return (Join-Path $Env:PSVaultLocation ('{0}.psvault' -f $env:username) )
  }

  static hidden [String] GetDefaultVaultLocation([String] $identifier) {
    return (Join-Path $Env:PSVaultLocation ('{0}.psvault' -f $identifier) )
  }

  hidden [void] Unlock() {
    Try {
      if (Test-Path $this.GetSavedKeyLocation()) {
        $this.Key = [PSVaultTools]::ConvertSecureStringToPlainText((Get-Content $this.GetSavedKeyLocation()|ConvertTo-SecureString)) -split ";" -as [Byte[]]
      } else {
        $this.Key = [PSVaultTools]::NewKey()
      }
      ConvertTo-SecureString -String $this.Checksum -Key $this.Key -ErrorAction Stop
    } catch {
      $this.Key = $null
      Throw 'You entered the Wrong PassPhrase, try again ...'
    }
  }
  
  hidden [void] Unlock([SecureString]$PassPhrase) {
    Try {
      $this.Key      = [PSVaultTools]::NewKey($PassPhrase)
      ConvertTo-SecureString -String $this.Checksum -Key $this.key -ErrorAction stop
    } catch {
      $this.Key = $null
      Throw 'You entered the Wrong PassPhrase, try again ...'
    }
  }

  static [String] Parse([String]$path) {
    if ($path.split('.')[1] -ne 'PSVault') {
      $path = "$path.PSVault"
    }
    return $path
  }
  #endregion

  #region Constructors
  #Create PSVault - Defaultname - Ask for Password
  
  PSVault () {
    $this.Key      = [PSVaultTools]::NewKey()
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key $this.Key
    $this.Save()
  }
  #Create PSVault - Defaultname
  
  PSVault ([SecureString]$Passphrase) {
    $this.Key      = [PSVaultTools]::NewKey($Passphrase)
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key $this.Key
    $this.Save()
  }
  #Create PSVault - Ask for Password
  
  PSVault ([String]$Path) {
    $this.Key      = [PSVaultTools]::NewKey()
    $this.Name     = (Split-Path -Leaf $Path).Split('.')[0]
    $this.Location = $Path
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key $this.Key
    $this.Save()
  }
  #Create PSVault with given Name and provided Passphrase
  
  PSVault ([String]$Path,[SecureString]$Passphrase) {
    $this.Key      = [PSVaultTools]::NewKey($Passphrase)
    $this.Name     = (Split-Path -Leaf $Path).Split('.')[0]
    $this.Location = $Path
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key $this.Key
    $this.Save()
  }
  
  PSVault ([PSObject]$Deserialized) {
    $this.Name              = $Deserialized.Name
    $this.Checksum          = $Deserialized.CheckSum
    $this.CreatedBy         = $Deserialized.CreatedBy
    $this.WhenCreated       = $Deserialized.WhenCreated
    $this.WhenChanged       = $Deserialized.WhenChanged
    $this.StoredCredentials = $Deserialized.StoredCredentials
    $this.Location          = $Deserialized.Location
    $this.ModifiedBy        = $Deserialized.ModifiedBy
  }
  #endregion

  #region Loading
  static [PSVault] LoadFromPath([string]$Path) {
    $Vault          = [PSVault]::new((Import-Clixml $path))
    $Vault.Location = $path
    $Vault.Unlock()
    return $Vault
  }

  static [PSVault] LoadFromPath([string]$Path,[SecureString]$passphrase) {
    $Vault          = [PSVault]::new((Import-Clixml $path))
    $Vault.Location = $path
    $Vault.Unlock($passphrase)
    return $Vault
  }
  #endregion
  
  #region Access

  
  [void] Save([String]$Path) {
    $this.Location = $Path
    $CurrentKey    = $this.Key
    $this.Key      = $null
    if (-not (Test-Path $this.Location)) {
      New-Item -Path $this.Location -ItemType File -Force
    }
    $this|Export-Clixml $this.Location
    $this.Key      = $CurrentKey

  }

  [void] Save() {
    if ([String]::IsNullOrEmpty($this.Location)) {
      $this.Location = [PSVault]::GetDefaultVaultLocation($this.Name)
    }
    $this.Save($this.Location)
  }
  
  [void] SaveKey() {
    if (-not (Test-Path ($env:PSVaultKeyLocation))) {
      New-Item -Path ($env:PSVaultKeyLocation) -ItemType Directory
    }  
    $this.Key -join ";"|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString|out-file -FilePath $this.GetSavedKeyLocation()
    $this.Save()
  }
  #endregion

  #region Credentialoperations
  [void] AddCredential([System.Management.Automation.PSCredential]$PScredential) {
    $NewCredential = ([VaultCredential]::new($PScredential,$this.Key))
    Write-Verbose "adding $newcredential"
    if ($this.StoredCredentials.where{$_.tostring() -eq $NewCredential.tostring()}) {
      throw ('A credential with the desired username {0} already exists`nUse Update() instead' -f $NewCredential.ToString())
    } else {
      $this.StoredCredentials += $NewCredential
      $this.Save()
    }
  }
  
  [void] UpdateCredential([string]$Username,[System.Security.SecureString]$NewPassword) {
    #if ($VaultCredential = $this.StoredCredentials.where{$_.tostring() -eq $username}) { -> System.Collections.ObjectModel.Collection`1[[System.Management.Automation.PSObject, System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]]
    if ($VaultCredential = $this.StoredCredentials|where-object {$_.tostring() -eq $username}) {
      $VaultCredential.ModifiedBy  = $env:username
      $VaultCredential.WhenChanged = (Get-Date)
      $VaultCredential.EncryptedPassword = $NewPassword|ConvertFrom-SecureString -Key $this.Key
    } else {
      throw "No stored Credential for $Username available"
    }
  }
  
  [void] RemoveCredential([String]$Username) {
    $CredentialToRemove = $this.StoredCredentials.where{$_.tostring() -eq $username}
    if ($CredentialToRemove) {
      Write-Verbose "removing $CredentialToRemove"
      $this.StoredCredentials = $this.StoredCredentials.where{$_.tostring() -ne $username}
      $this.Save()
    } else {
      throw "No Credential found with Identifier $username"
    }
  }
   
  [System.Management.Automation.PSCredential] GetCredential([String]$Username) {
    if ($VaultCredential = $this.StoredCredentials.where{$_.tostring() -eq $username}) {
      return (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, ($VaultCredential.EncryptedPassword | ConvertTo-SecureString -Key $this.Key))
    } else {
      throw "No stored Credential for $Username available"
    }
  }
  
  [System.Management.Automation.PSCredential[]] GetCredential() {
    Return $(
      ($this.StoredCredentials|Out-GridView -OutputMode Multiple).foreach{
        (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $_.UserName, ($_.EncryptedPassword | ConvertTo-SecureString -Key $this.Key)
        )
      }
    )
  }
  #endregion
}