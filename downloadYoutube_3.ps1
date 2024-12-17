# ALLOW SCRIPT RUN
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Get the directory of the current script
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition

# Path to the text file with YouTube links
$linksFile = Join-Path $scriptDir "youtube.txt"

# Output directory for the downloaded files
$outputDir = Join-Path $scriptDir "yt-download"

# Ensure yt-dlp and ffmpeg are installed and available in PATH
$ytDlp = "yt-dlp"  # Replace with full path if yt-dlp is not in PATH
$ffmpeg = "ffmpeg" # Replace with full path if ffmpeg is not in PATH

# Create the output directory if it doesn't exist
if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

# Read links from the file and process them
if (Test-Path -Path $linksFile) {
    Get-Content $linksFile | ForEach-Object {
        $link = $_.Trim()

        # Skip lines starting with '#' or empty lines
        if ($link -eq "" -or $link.StartsWith("#")) {
            Write-Host "Skipping: $link" -ForegroundColor Yellow
            return
        }

        Write-Host "Processing: $link"

        # Download best video and audio and merge with GPU encoding
        & $ytDlp `
            --ffmpeg-location $ffmpeg `                                                            # Specify ffmpeg path
            -f "bestvideo+bestaudio/best" `                                                        # Best video and best audio
            --merge-output-format mp4 `                                                            # Ensure MP4 output
            --postprocessor-args "ffmpeg:-c:v h264_nvenc -preset p4 -b:v 5M -c:a aac -b:a 192k" `  # GPU encoding
            #--postprocessor-args "ffmpeg:-c:v libx264 -c:a aac -b:a 192k" `                       # Re-encode to H.264 and AAC
            -o "$outputDir\%(title)s.%(ext)s" `                                                    # Save output with proper naming
            $link
    }

    Write-Host "All downloads and merges complete. Files saved to $outputDir"
} else {
    Write-Host "Error: youtube.txt not found in script directory: $scriptDir" -ForegroundColor Red
}
