# Register event handler for Ctrl+C interruption
$global:vlcProcess = $null

# Define trap for Ctrl+C
trap {
    # Only handle break events (Ctrl+C)
    if ($_.Exception.GetType().Name -eq "OperationCanceledException" -or 
        $_.Exception.GetType().FullName -like "*Break*") {
        
        Write-Host "`n`nInterrupted by user. Stopping playback..." -ForegroundColor Yellow
        # Stop VLC process if it's running
        if ($global:vlcProcess -and !$global:vlcProcess.HasExited) {
            try {
                $global:vlcProcess.Kill()
                Write-Host "VLC playback stopped successfully." -ForegroundColor Green
            } catch {
                Write-Error "Failed to stop VLC: $_"
            }
        }
        # Clean up resources
        if ($fileStream) {
            $fileStream.Close()
            $fileStream.Dispose()
        }
        if ($client) {
            $client.Dispose()
        }
        exit
    } else {
        # For other exceptions, continue normal error handling
        throw
    }
}

# Define your Groq API Key
$apiKey = "TODO"  # Replace with your actual key
# Create a welcome banner that adapts to window size
$windowWidth = $host.UI.RawUI.WindowSize.Width
# Use shorter banner if window is narrow
if ($windowWidth -lt 50) {
    $banner = @"
$("-" * $windowWidth)
 ♪ GROQ LYRICS ♪ 
$("-" * $windowWidth)
"@
} else {
    $banner = @"
$("=" * $windowWidth)
 ♪ ♫  GROQ LYRICS VISUALIZER USING OPENAI MODEL(whisper-large-v3-turbo)♫ ♪ 
$("=" * $windowWidth)
"@
}
Write-Host $banner -ForegroundColor Magenta

# Prompt user for audio file path with style
Write-Host "🎵 " -NoNewline -ForegroundColor Yellow
$audioFile = Read-Host "Enter the full path to your song/audio file"
if (-not (Test-Path $audioFile)) {
    Write-Error "Audio file not found: $audioFile"
    exit 1
}
# API endpoint and model
$apiUrl = "https://api.groq.com/openai/v1/audio/transcriptions"
$model = "whisper-large-v3-turbo"
# Load required .NET classes
Add-Type -AssemblyName "System.Net.Http"
# Prepare HTTP client
$client = [System.Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $apiKey)
# Build multipart form data
$content = [System.Net.Http.MultipartFormDataContent]::new()
$fileStream = [System.IO.File]::OpenRead($audioFile)
$fileContent = [System.Net.Http.StreamContent]::new($fileStream)
$fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
$content.Add($fileContent, "file", [System.IO.Path]::GetFileName($audioFile))
$content.Add([System.Net.Http.StringContent]::new($model), "model")
$content.Add([System.Net.Http.StringContent]::new("verbose_json"), "response_format")
Write-Host "`nUploading and transcribing..." -ForegroundColor Yellow
try {
    $response = $client.PostAsync($apiUrl, $content).Result
    $json = $response.Content.ReadAsStringAsync().Result
    $parsed = $json | ConvertFrom-Json
    if (-not $parsed.segments) {
        Write-Error "API Error: $($parsed.error.message)"
        return
    }
    # Start VLC playback
    Write-Host "`nStarting VLC..." -ForegroundColor Cyan
    $vlcPath = "C:\Program Files\VideoLAN\VLC\vlc.exe"  # Adjust this path if VLC is installed elsewhere
    $global:vlcProcess = Start-Process -FilePath $vlcPath -ArgumentList "`"$audioFile`" --play-and-exit --qt-start-minimized" -PassThru
    # Give VLC a second to start
    Start-Sleep -Seconds 1
    $startTime = Get-Date
    # Create a title banner for lyrics that adapts to window size
    $windowWidth = $host.UI.RawUI.WindowSize.Width
    $title = "♫ Synchronized Lyrics ♫"
    
    # Ensure title fits within window
    $adjustedWidth = $windowWidth - 4
    if ($title.Length -gt $adjustedWidth) {
        $title = "♫ Lyrics ♫"
    }
    
    $padding = " " * [Math]::Max(0, [Math]::Floor(($windowWidth - $title.Length) / 2))
    
    # For very small windows, use simpler formatting
    if ($windowWidth -lt 40) {
        Write-Host "`n$("-" * $windowWidth)" -ForegroundColor Magenta
        Write-Host "$title" -ForegroundColor Cyan
        Write-Host "$("-" * $windowWidth)`n" -ForegroundColor Magenta
    } else {
        Write-Host "`n$("=" * $windowWidth)" -ForegroundColor Magenta
        Write-Host "$padding$title" -ForegroundColor Cyan
        Write-Host "$("=" * $windowWidth)`n" -ForegroundColor Magenta
    }
    
    # Define colors to cycle through for lyrics - use fewer colors for better readability
    $textColors = @("Yellow", "Cyan", "White")
    $timestampColor = "DarkGray"
    $colorIndex = 0
    $prevSegmentEnd = 0
    
    foreach ($segment in $parsed.segments) {
        $segmentStart = [math]::Round($segment.start, 2)
        $text = $segment.text.Trim()
        
        # Wait until it's time to display this segment
        $currentWaitTime = ((Get-Date) - $startTime).TotalSeconds
        while ($currentWaitTime -lt $segmentStart) {
            Start-Sleep -Milliseconds 100
            $currentWaitTime = ((Get-Date) - $startTime).TotalSeconds
        }
        
        # Clear the current line for a cleaner look if there's a gap between lyrics
        if ($segmentStart - $prevSegmentEnd > 3) {
            # Use shorter separator for narrow windows
            $separatorWidth = [Math]::Min($windowWidth, 40)
            Write-Host "`n$("-" * $separatorWidth)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        # Format timestamp (shorter format for smaller windows)
        if ($windowWidth -lt 50) {
            $timestamp = "{0:mm\:ss}" -f [TimeSpan]::FromSeconds($segmentStart)
        } else {
            $timestamp = "{0:mm\:ss\.ff}" -f [TimeSpan]::FromSeconds($segmentStart)
        }
        
        # Use simple format for very narrow windows
        if ($windowWidth -lt 30) {
            Write-Host "[$timestamp] $text" -ForegroundColor $textColors[$colorIndex]
        } else {
            # Display with some visual formatting
            Write-Host "♪ " -NoNewline -ForegroundColor DarkCyan
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor $timestampColor
            Write-Host "$text" -ForegroundColor $textColors[$colorIndex]
        }
        
        # Rotate colors
        $colorIndex = ($colorIndex + 1) % $textColors.Count
        $prevSegmentEnd = $segmentStart
    }
    # Show a nice ending that adapts to window size
$windowWidth = $host.UI.RawUI.WindowSize.Width

# Shorter ending for narrow windows
if ($windowWidth -lt 40) {
    Write-Host "`n$("-" * $windowWidth)" -ForegroundColor Magenta
    Write-Host "♫ Complete ♫" -ForegroundColor Green
    Write-Host "$("-" * $windowWidth)" -ForegroundColor Magenta
} else {
    $endText = "♫ Performance Complete ♫"
    $padding = " " * [Math]::Max(0, [Math]::Floor(($windowWidth - $endText.Length) / 2))
    Write-Host "`n$("*" * $windowWidth)" -ForegroundColor Magenta
    Write-Host "$padding$endText" -ForegroundColor Green
    Write-Host "$("*" * $windowWidth)" -ForegroundColor Magenta
}
} catch {
    Write-Error "Transcription failed:"
    Write-Error $_.Exception.Message
}
finally {
    # Clean up resources
    if ($fileStream) {
        $fileStream.Close()
        $fileStream.Dispose()
    }
    if ($client) {
        $client.Dispose()
    }
    # Make sure VLC is stopped when script ends
    if ($global:vlcProcess -and !$global:vlcProcess.HasExited) {
        try {
            $global:vlcProcess.Kill()
            Write-Host "VLC playback stopped." -ForegroundColor Yellow
        } catch {
            # Ignore errors on cleanup
        }
    }
}