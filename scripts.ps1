$git_token = $env:GIT_TOKEN

# Define your GitHub username, repository names, branch name, and file path
$githubUsername = "rajeshjanapati"
$sourceRepo = "AES-Encryption-Jsonfile-github"
$branchName = "encrypt/keys"
$filePath = "jsonfile/encrypted_data.json"

# Define the GitHub API URL for fetching the file content from a specific branch
$apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$sourceRepo+"/contents/"+$filePath+"?ref="+$branchName

# Set the request headers with your PAT
$headers = @{
    Authorization = "Bearer $git_token"
}

# Make a GET request to fetch the file content
$fileContent = Invoke-RestMethod $apiUrl -Headers $headers

# Parse and display the file content (in this case, it's assumed to be JSON)
$jsonContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fileContent.content))

# Parse the JSON content into a PowerShell object
$jsonObject = $jsonContent | ConvertFrom-Json


# Convert the modified JSON data back to a PowerShell object
$encryptedJsonData = $jsonContent | ConvertFrom-Json


# Specify the fields you want to decrypt
$fieldsToDecrypt = @("consumerKey", "consumerSecret")

# Decryption key (use the same key you used for encryption)
$keyHex = $env:key

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Loop through the specified fields and decrypt their values
foreach ($field in $fieldsToDecrypt) {
    # Check if the field contains a valid Base64 string
    if ($encryptedJsonData.credentials[0].$field -ne "System.Collections.Hashtable") {
        $encryptedValueBase64 = $encryptedJsonData.credentials[0].$field.EncryptedValue
        $IVBase64 = $encryptedJsonData.credentials[0].$field.IV

        # Convert IV and encrypted value to bytes
        $IV = [System.Convert]::FromBase64String($IVBase64)
        $encryptedBytes = [System.Convert]::FromBase64String($encryptedValueBase64)

        # Create a decryptor
        $decryptor = $AES.CreateDecryptor($AES.Key, $IV)

        # Decrypt the data
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)
        $decryptedText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

        # Update the JSON object with the decrypted value
        $encryptedJsonData.credentials[0].$field = $decryptedText

    }
}

# Display the JSON object with decrypted values
$decrypteddata = $encryptedJsonData | ConvertTo-Json -Depth 10

Write-Host $decrypteddata

# Define the local file path and file name
$filePath = "jsonfile/decrypted_data.json"

# Write the JSON data to the file
$encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8

# # Clone the other repo to your local machine.
# git clone https://github.com/rajeshjanapati/AES-decrypt-json-github-read.git

# # Change the working directory to the cloned repo.
# # cd myrepo

# # Copy the `decrypted_data.json` file from the first repo to the second repo.
# Copy-Item .\jsonfile/decrypted_data.json



# # Commit the changes to the second repo.
# git add .
# git commit -m "Add decrypted data file."

# # Push the changes to the remote repository.
# git push origin main
