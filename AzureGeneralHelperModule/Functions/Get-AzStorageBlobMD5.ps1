Function Get-AzStorageBlobMD5{
<#
		.SYNOPSIS
			Retrieves the MD5 hash of an Azure Storage blob in hexadecimal format.

		.DESCRIPTION
			This function extracts the MD5 hash from an Azure Storage blob object's properties and converts it from Base64 encoding to a hexadecimal string format. The MD5 hash is automatically calculated and stored by Azure Storage when a blob is uploaded.

		.PARAMETER Blob
			An Azure Storage blob object of type Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob from which to retrieve the MD5 hash.

		.EXAMPLE
			PS C:\> $storageAccount = Get-AzStorageAccount -ResourceGroupName "MyRG" -Name "mystorageaccount"
			PS C:\> $blob = Get-AzStorageBlob -Container "mycontainer" -Blob "myfile.txt" -Context $storageAccount.Context
			PS C:\> Get-AzStorageBlobMD5 -Blob $blob

			Retrieves the MD5 hash of the specified blob in hexadecimal format.

		.EXAMPLE
			PS C:\> Get-AzStorageBlob -Container "documents" -Context $ctx | Get-AzStorageBlobMD5

			Gets the MD5 hash for all blobs in the "documents" container using pipeline input.

		.INPUTS
			Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob

		.OUTPUTS
			System.String
			Returns the MD5 hash as a hexadecimal string (32 characters).

		.NOTES
			The function requires that the blob object contains MD5 hash information in its properties. If the blob was uploaded without MD5 hash calculation, the ContentMD5 property may be null.

#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory, ValueFromPipeline=$true, Position=0)]
		[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob]$Blob
	)
	Begin {
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"
	}
	Process {
        #$Blob.ICloudBlob.Properties.ContentMD5
        $MD5Sum = [convert]::FromBase64String($Blob.ICloudBlob.Properties.ContentMD5)
        $hdhash = [BitConverter]::ToString($MD5Sum).Replace('-','')
    }
    End{
        $hdhash
    }
}