# Some tools for generating ByteArrays from Securestrings and working with securestrings
Class CredSafeTools {
  
  static [String] ConvertSecureStringToPlainText([SecureString]$SecureString) {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  }
    
  static [Byte[]] NewKey() {
    $hasher = new-object System.Security.Cryptography.SHA256Managed
    $toHash = [System.Text.Encoding]::UTF8.GetBytes([CredSafeTools]::ConvertSecureStringToPlainText($(Read-Host -AsSecureString "Enter Masterkey")))
    return $hasher.ComputeHash($toHash)
  }
  
  static [Byte[]] NewKey([SecureString]$SecureString) {
    $hasher = new-object System.Security.Cryptography.SHA256Managed
    $toHash = [System.Text.Encoding]::UTF8.GetBytes([CredSafeTools]::ConvertSecureStringToPlainText($SecureString))
    return $hasher.ComputeHash($toHash)
  }  

}

# This is how Credentials are stored - The main idea is, to take the 32-Byte Array received from
# hashing and use it to convertfrom-securestring
# The constructors take PSCredential, PSObject (the ones you get from Import-CliXML) or Datarows
# as Input, so you can either save your Credentials in a Database or a CliXML
# The ToString-Method is mainly for Identification-Purposes
Class SafeCredential {
  [String]$CreatedBy
  [DateTime]$WhenCreated
  [DateTime]$WhenChanged
  [String]$Domain
  [String]$Username
  [String]$EncryptedPassword
  
  SafeCredential ([System.Management.Automation.PSCredential]$PSCredential,[Byte[]]$Key) {
    $this.EncryptedPassword = $PSCredential.Password|ConvertFrom-SecureString -Key $Key
    if ($PSCredential.Username.indexof("\") -gt 0) {
      $this.Domain   = $PSCredential.username.split("\")[0]
      $this.Username = $PSCredential.username.split("\")[1]
    } else {
      $this.Domain   = "."
      $this.Username = $PSCredential.UserName
    }
    $now                    = Get-Date
    $this.WhenCreated       = $now
    $this.WhenChanged       = $now
    $this.CreatedBy         = $env:USERNAME
  }
  
  SafeCredential ([Psobject]$Deserialized) {
    $this.CreatedBy         = $Deserialized.CreatedBy
    $this.Domain            = $Deserialized.Domain
    $this.EncryptedPassword = $Deserialized.EncryptedPassword
    $this.Username          = $Deserialized.Username
    $this.WhenChanged       = $Deserialized.WhenChanged
    $this.WhenCreated       = $Deserialized.WhenCreated
  }
  
  SafeCredential ([System.Data.DataRow]$DataRow) {
    $this.CreatedBy         = $DataRow.CreatedBy
    $this.Domain            = $DataRow.Domain
    $this.EncryptedPassword = $DataRow.EncryptedPassword
    $this.Username          = $DataRow.Username
    $this.WhenChanged       = $DataRow.WhenChanged
    $this.WhenCreated       = $DataRow.WhenCreated
  }
  
  [string] ToString() {
    return ('{0}\{1}' -f $this.Domain,$this.Username)
  }
}

# This is where you store your credentials and retrieve them when you need to
Class CredSafe {
  [String] $Name                                     = '{0}_CredSafe' -f $env:username
  [String] $Checksum                                 
  [String] $CreatedBy                                = $env:USERNAME
  [DateTime] $WhenCreated                            = $(Get-Date)
  hidden             [Bool] $IsLocked                = $true
  hidden             [Bool] $IsLocal                 = $true
  hidden           [Byte[]] $Key
  hidden           [String] $SavedKeyLocation        
  hidden [SafeCredential[]] $StoredCredentials       
  hidden           [String] $Location
  hidden           [String] $ConnectionString        = [CredSafe]::DefaultConnectionString
  hidden static    [String] $KeyFolder               = (Join-Path $env:LOCALAPPDATA "CredSafe\Keys")                          
  hidden static    [String] $DefaultConnectionString = 'Server = Localhost\SQLExpress;Database = Master;Trusted_Connection = True;'
  
  CredSafe () {
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key ([CredSafeTools]::NewKey())
  }
  
  CredSafe ([SecureString]$Passphrase) {
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key ([CredSafeTools]::NewKey($Passphrase))
  }
  
  CredSafe ([String]$Name) {
    $this.Name     = $Name
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key ([CredSafeTools]::NewKey())
  }
  
  CredSafe ([String]$Name,[SecureString]$Passphrase) {
    $this.Name     = $Name
    $this.Checksum = ConvertTo-SecureString -String (Get-Date) -AsPlainText -Force|ConvertFrom-SecureString -Key ([CredSafeTools]::NewKey($Passphrase))
  }
  
  CredSafe ([PSObject]$Deserialized) {
    $this.Name              = $Deserialized.Name
    $this.Checksum          = $Deserialized.CheckSum
    $this.CreatedBy         = $Deserialized.CreatedBy
    $this.WhenCreated       = $Deserialized.WhenCreated
    $this.SavedKeyLocation  = $Deserialized.SavedKeyLocation
    $this.StoredCredentials = $Deserialized.StoredCredentials
  }
  
  static  [CredSafe] LoadFromXML() {
    $path     = '{0}\{1}\{2}' -f $env:LOCALAPPDATA,"CredSafe","$($env:username)_Credsafe"
    $CredSafe = [CredSafe]::new((Import-Clixml $path))
    $CredSafe.Unlock()
    return $CredSafe
  }
  
  static  [CredSafe] LoadFromXML([String]$Name) {
    $path     = '{0}\{1}\{2}' -f $env:LOCALAPPDATA,"CredSafe","$name"
    $CredSafe = [CredSafe]::new((Import-Clixml $path))
    $CredSafe.Unlock()
    return $CredSafe
  }
   
  static  [CredSafe] LoadFromXML([SecureString]$passphrase) {
    $path = '{0}\{1}\{2}' -f $env:LOCALAPPDATA,"CredSafe","$($env:username)_Credsafe"
    $CredSafe = [CredSafe]::new((Import-Clixml $path))
    $CredSafe.Unlock($passphrase)
    return $CredSafe
  }
  
  
  
  [void] Unlock() {
    Try {
      if ($this.IsLocal) {
        if (Test-Path $this.SavedKeyLocation) {
          $this.Key = [CredSafeTools]::ConvertSecureStringToPlainText((Get-Content $this.SavedKeyLocation|ConvertTo-SecureString)) -split ";" -as [Byte[]]
        } else {
          $this.Key = [CredSafeTools]::NewKey()
        }
      } else {
        try {
          # needs implementation
          #$this.Key = [CredSafeTools]::ConvertSecureStringToPlainText((Get-SQLDataRow -ConnectionString $this.ConnectionString -from <insert-Tablename> -where "OriginatingComputer = $($Env:computername)" -Schema $env:USERNAME).EncryptedPassword)
        } catch {
          $this.Key = [CredSafeTools]::NewKey()
        }
        if (Test-Path $this.SavedKeyLocation) {
          $this.Key = [CredSafeTools]::ConvertSecureStringToPlainText((Get-Content $this.SavedKeyLocation|ConvertTo-SecureString)) -split ";" -as [Byte[]]
        } else {
          $this.Key = [CredSafeTools]::NewKey()
        }
      }
     
     
      ConvertTo-SecureString -String $this.Checksum -Key $this.Key -ErrorAction Stop
      $this.IsLocked = $false
    } catch {
      $this.Key = $null
      Throw 'You entered the Wrong PassPhrase, try again ...'
    }
  }
  
  [void] Unlock([SecureString]$PassPhrase) {
    Try {
      $this.Key      = [CredSafeTools]::NewKey($PassPhrase)
      ConvertTo-SecureString -String $this.Checksum -Key $this.key -ErrorAction stop
      $this.IsLocked = $false
    } catch {
      $this.Key = $null
      Throw 'You entered the Wrong PassPhrase, try again ...'
    }
  }
  
  [void] Lock() {
    $this.IsLocked = $true
    $this.Key      = $null
  }
  
  [void] Save() {
    if ([String]::IsNullOrEmpty($this.Location)) {
      $this.Location = '{0}\{1}\{2}' -f $env:LOCALAPPDATA,"CredSafe",$this.Name    
    }
    if (-not $this.IsLocked) {
      $CurrentKey    = $this.Key
      $this.Key      = $null
      $this.IsLocked = $true
      $removedKey    = $true
    } else {
      $removedKey = $false
      $CurrentKey = $null
    }
    if ($this.Islocal) {
      if (-not (Test-Path $this.Location)) {
        New-Item -Path $this.Location -ItemType File -Force
      }
      $this|Export-Clixml $this.Location
    } else {
      #Needs Implementation
      #Should look something like this
      #$this|ConvertTo-SQLObject -properties Name,Checksum,CreatedBy,WhenCreated|Write-SQL -ConnectionString $this.Location -KeyColumn Name
    }
    
    if ($removedKey) {
      $this.Key      = $CurrentKey
      $this.IsLocked = $false
    }
  }
  
  [void] Save([SafeCredential[]]$CredentialsToRemove) {
    if ($this.IsLocal) {
      $this.Save()
    } else {
      #Needs Implentation
      #Should look something like this
      <#
          $CredentialsToRemove.foreach{
          Remove-SQLEntry -ConnectionString ([CredSafe]::ConnectionString) -From SafeCredential -Schema $env:username -KeyColumn Name -KeyValue $_.ToString()
          }
      #>
      
    }
  }
  
  [void] SaveKey() {
    if ($this.IsLocked) {
      $this.Unlock()
    }
    if ($this.IsLocal) {
      if (-not (Test-Path ([CredSafe]::KeyFolder))) {
        New-Item -Path ([Credsafe]::KeyFolder) -ItemType Directory
      }
      $this.SavedKeyLocation = (Join-Path ([CredSafe]::KeyFolder) $this.Name)   
      $this.Key -join ";"|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString|out-file -FilePath $this.SavedKeyLocation
      $this.save()
    } else {
      #needs implementation
      #should look something like
      <#
      $this.Key -join ";"|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString|Write-SQL -ConnectionString $this.ConnectionString -Schema $env:username -Table $this.SavedKeyLocation -KeyColumn OriginatingComputer -KeyValue $env:computername
      #>
    }
    $this.Lock
  }
  
  [void] AddCredential([System.Management.Automation.PSCredential]$PScredential) {
    if ($this.IsLocked) {
      $this.Unlock()
    }
    $NewCredential = ([SafeCredential]::new($PScredential,$this.Key))
    Write-Verbose "adding $newcredential"
    if ($this.StoredCredentials.where{$_.tostring() -eq $NewCredential.tostring()}) {
      throw ('A credential with the desired username {0} already exists`nUse Update() instead' -f $NewCredential.ToString())
    } else {
      $this.StoredCredentials += $NewCredential
      $this.Save()
    }
  }
  
  [void] UpdateCredential([System.Management.Automation.PSCredential]$PScredential) {
    if ($this.IsLocked) {
      $this.Unlock()
    }
    $NewCredential = ([SafeCredential]::new($PScredential,$this.Key))
    $this.RemoveCredential($NewCredential.ToString())
    $this.AddCredential($PScredential)
  }
  
  [void] RemoveCredential([String]$Username) {
    if ($this.IsLocked) {
      $this.Unlock()
    }
    $CredentialToRemove    = $this.StoredCredentials.where{$_.tostring() -eq $username}
    if ($CredentialToRemove) {
      Write-Verbose "removing $CredentialToRemove"
      $this.StoredCredentials = $this.StoredCredentials.where{$_.tostring() -ne $username}
      $this.Save($CredentialToRemove)
    } else {
      throw "No Credential found with Indetifier $username"
    }
  }
   
  [System.Management.Automation.PSCredential] GetCredential([String]$Username) {
    if ($this.IsLocked) {
      throw "You need to unlock the safe before usage"
    }
    if ($SafeCredential = $this.StoredCredentials.where{$_.tostring() -eq $username}) {
      return (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, ($SafeCredential.EncryptedPassword | ConvertTo-SecureString -Key $this.Key))
    } else {
      throw "No stored Credential for $Username available"
    }
  }
  
  [System.Management.Automation.PSCredential[]] GetCredential() {
    if ($this.IsLocked) {
      $this.Unlock()
    }
    Return $(
      ($this.StoredCredentials|Out-GridView -OutputMode Multiple).foreach{
        (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $_.UserName, ($_.EncryptedPassword | ConvertTo-SecureString -Key $this.Key)
        )
      }
    )
  }
}