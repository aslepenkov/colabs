# Define the source directory dynamically for the current user's "Pictures" folder
$sourceDir = Join-Path -Path $env:USERPROFILE -ChildPath "Pictures\Screenshots"

# Ensure the source directory exists
if (-not (Test-Path -Path $sourceDir)) {
    Write-Host "Source directory does not exist: $sourceDir"
    exit
}

# Get all PNG, JPG, and JPEG files in the source directory
$files = Get-ChildItem -Path $sourceDir -Include "*.png", "*.jpg", "*.jpeg" -Recurse

# Initialize a list to keep track of directories processed
$processedDirectories = @{}

foreach ($file in $files) {
    # Extract year and month from the file's last write time
    $year = $file.LastWriteTime.Year
    $month = "{0:D2}" -f $file.LastWriteTime.Month  # Format month as two digits

    # Define the target directory based on the year and month
    $targetDir = Join-Path -Path $sourceDir -ChildPath "$year$month"

    # Create the target directory if it does not exist
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir
    }

    # Move the file to the target directory
    Move-Item -Path $file.FullName -Destination $targetDir

    # Add directory to the list if not already added
    $processedDirectories[$targetDir] = $true
}

# Zip each processed directory
foreach ($dir in $processedDirectories.Keys) {
    $zipFilePath = "$dir.zip"
    Compress-Archive -Path $dir\* -DestinationPath $zipFilePath -Force
    Write-Host "Created archive: $zipFilePath"
}