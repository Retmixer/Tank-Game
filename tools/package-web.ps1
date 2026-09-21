$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$zipPath = Join-Path $projectRoot 'Yandex-Games.zip'
$archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Update)
try {
    $files = @('index.html', 'style.css', 'manifest.webmanifest') | ForEach-Object { Get-Item -LiteralPath (Join-Path $projectRoot $_) }
    foreach ($folder in @('src', 'vendor', 'assets')) {
        $files += Get-ChildItem -LiteralPath (Join-Path $projectRoot $folder) -Recurse -File
    }
    foreach ($file in $files) {
        $entryName = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        $entry = $archive.GetEntry($entryName)
        if ($entry) { $entry.Delete() }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entryName, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
Write-Output "Web archive updated: $zipPath"
