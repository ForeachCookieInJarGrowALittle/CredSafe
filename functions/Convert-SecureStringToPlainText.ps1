<#
.Synopsis
Converts Securestring to Plaintext
.Description
Converts Securestring to Plaintext
.Example
ConvertTo-SecureString -String 'test' -AsPlainText -Force|Convert-SecureStringToPlainText
#>
function Convert-SecureStringToPlainText {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [Alias('Password')]
        [SecureString]$SecureString
    )
    process {
        if ($PSCmdlet.ShouldProcess('SecureString','Converting')) {
            [PSVaultTools]::ConvertSecureStringToPlainText($SecureString)
        }
    }
}