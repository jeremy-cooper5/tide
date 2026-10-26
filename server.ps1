# Tide local server.
# Serves the "app" folder at http://127.0.0.1:8457 so Spotify sign-in works
# (Spotify only accepts 127.0.0.1 or https addresses for sign-in).
# Uses only what ships with Windows. Close this window to stop it.

$ErrorActionPreference = 'Stop'
$Port = 8457
$Root = Join-Path $PSScriptRoot 'app'
$Url = "http://127.0.0.1:$Port/"
$RootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$Ordinal = [System.StringComparison]::Ordinal

$Types = @{
  '.html'        = 'text/html; charset=utf-8'
  '.js'          = 'text/javascript; charset=utf-8'
  '.css'         = 'text/css; charset=utf-8'
  '.json'        = 'application/json; charset=utf-8'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.svg'         = 'image/svg+xml'
  '.png'         = 'image/png'
  '.ico'         = 'image/x-icon'
  '.woff2'       = 'font/woff2'
  '.txt'         = 'text/plain; charset=utf-8'
}

function Test-TideRunning {
  try {
    $req = [System.Net.HttpWebRequest]::Create($Url + '__tide')
    $req.Proxy = $null
    $req.Timeout = 2000
    $res = $req.GetResponse()
    $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
    $body = $reader.ReadToEnd()
    $res.Close()
    return ($body -eq 'tide')
  } catch { return $false }
}

function Send-Response($Stream, [int]$Code, [string]$Reason, [string]$Type, [byte[]]$Body, [bool]$HeadOnly) {
  $header = "HTTP/1.1 $Code $Reason`r`nContent-Type: $Type`r`nContent-Length: $($Body.Length)`r`nCache-Control: no-cache`r`nX-Content-Type-Options: nosniff`r`nConnection: close`r`n`r`n"
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($header)
  $Stream.Write($bytes, 0, $bytes.Length)
  if (-not $HeadOnly -and $Body.Length -gt 0) { $Stream.Write($Body, 0, $Body.Length) }
  $Stream.Flush()
}

function Send-Text($Stream, [int]$Code, [string]$Reason, [string]$Text, [bool]$HeadOnly) {
  Send-Response $Stream $Code $Reason 'text/plain; charset=utf-8' ([System.Text.Encoding]::UTF8.GetBytes($Text)) $HeadOnly
}

function Invoke-Client($Client) {
  try {
    $Client.ReceiveTimeout = 3000
    $Client.SendTimeout = 10000
    $stream = $Client.GetStream()
    $buffer = New-Object byte[] 8192
    $request = ''
    while ($request.IndexOf("`r`n`r`n", $Ordinal) -lt 0 -and $request.Length -lt 65536) {
      $n = $stream.Read($buffer, 0, $buffer.Length)
      if ($n -le 0) { break }
      $request += [System.Text.Encoding]::ASCII.GetString($buffer, 0, $n)
    }
    $lineEnd = $request.IndexOf("`r`n", $Ordinal)
    if ($lineEnd -lt 0) { return }
    $parts = $request.Substring(0, $lineEnd).Split(' ')
    if ($parts.Length -lt 2) { return }
    $method = $parts[0]
    $headOnly = $method -eq 'HEAD'
    if ($method -ne 'GET' -and -not $headOnly) { Send-Text $stream 405 'Method Not Allowed' 'Method not allowed' $false; return }

    $path = $parts[1].Split('?')[0].Split('#')[0]
    try { $path = [System.Uri]::UnescapeDataString($path) } catch { }
    if ($path -eq '/__tide') { Send-Text $stream 200 'OK' 'tide' $headOnly; return }
    if ($path -eq '/' -or $path -eq '/callback' -or $path -eq '/callback/') { $path = '/index.html' }

    $relative = $path.TrimStart('/').Replace('/', [string][System.IO.Path]::DirectorySeparatorChar)
    $full = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($RootFull, $relative))
    if (-not $full.StartsWith($RootFull, [System.StringComparison]::OrdinalIgnoreCase) -or -not [System.IO.File]::Exists($full)) {
      Send-Text $stream 404 'Not Found' 'Not found' $headOnly
      return
    }
    $type = $Types[[System.IO.Path]::GetExtension($full).ToLowerInvariant()]
    if (-not $type) { $type = 'application/octet-stream' }
    Send-Response $stream 200 'OK' $type ([System.IO.File]::ReadAllBytes($full)) $headOnly
  } catch {
  } finally {
    try { $Client.Close() } catch { }
  }
}

function Open-Tide {
  if ($env:TIDE_NO_BROWSER) { return }
  try { Start-Process $Url } catch { Write-Host "  Open $Url in your browser." }
}

try { $Host.UI.RawUI.WindowTitle = 'Tide' } catch { }

if (-not [System.IO.File]::Exists((Join-Path $Root 'index.html'))) {
  Write-Host "Tide can't find its 'app' folder. Keep all the files from the zip together and try again." -ForegroundColor Red
  exit 1
}

$listener = $null
try {
  $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
  $listener.Start()
} catch {
  if (Test-TideRunning) {
    Write-Host 'Tide is already running, opening it.'
    Open-Tide
    exit 0
  }
  Write-Host "Another program is using port $Port, so Tide can't start." -ForegroundColor Red
  Write-Host "Close that program and try again, or change the port at the top of server.ps1"
  Write-Host "and update the redirect URI in your Spotify app to match."
  exit 1
}

Write-Host ''
Write-Host "  Tide is running at $Url" -ForegroundColor Green
Write-Host '  Leave this window open while you use Tide. You can minimise it.'
Write-Host '  Close it to stop the server. After the first run Tide also opens without it.'
Write-Host ''

Open-Tide

# Browsers often open a spare connection and send nothing on it, so each
# connection waits in a list until its request arrives. That keeps a quiet
# connection from holding up the others.
$pending = New-Object System.Collections.ArrayList
try {
  while ($true) {
    while ($listener.Pending()) {
      $c = $listener.AcceptTcpClient()
      [void]$pending.Add(@{ Client = $c; Since = [DateTime]::UtcNow })
    }
    for ($i = $pending.Count - 1; $i -ge 0; $i--) {
      $entry = $pending[$i]
      $c = $entry.Client
      $ready = $false
      $drop = $false
      try {
        if ($c.Available -gt 0) { $ready = $true }
        elseif ($c.Client.Poll(0, [System.Net.Sockets.SelectMode]::SelectRead)) { $drop = $true }
        elseif (([DateTime]::UtcNow - $entry.Since).TotalSeconds -gt 30) { $drop = $true }
      } catch { $drop = $true }
      if ($ready) { $pending.RemoveAt($i); Invoke-Client $c }
      elseif ($drop) { $pending.RemoveAt($i); try { $c.Close() } catch { } }
    }
    Start-Sleep -Milliseconds 20
  }
} finally {
  $listener.Stop()
}
