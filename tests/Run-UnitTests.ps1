dir C:\PSGalleryInspired\PSVault\tests\unit|foreach {
  write-host -ForegroundColor DarkMagenta $_.Fullname
  invoke-pester -Script $_.Fullname
}
