param([string]$Destination = 'work/polyhaven-source')
$ErrorActionPreference = 'Stop'
$assets = @('pine_sapling_small','fir_sapling','fir_sapling_medium','fern_02','grass_medium_01','rock_moss_set_02','tree_stump_01','namaqualand_boulder_02','namaqualand_boulder_04','namaqualand_cliff_02','quiver_tree_01','wild_rooibos_bush','modular_factory_facade')
foreach ($id in $assets) {
    $folder = Join-Path $Destination $id
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $manifest = Invoke-RestMethod ('https://api.polyhaven.com/files/' + $id)
    $entry = $manifest.gltf.'1k'.gltf
    if (-not $entry) { throw "No 1K glTF for $id" }
    $files = @(@{ Path = "$id.gltf"; Info = $entry })
    foreach ($dependency in $entry.include.PSObject.Properties) {
        $files += @{ Path = $dependency.Name; Info = $dependency.Value }
    }
    foreach ($file in $files) {
        $target = Join-Path $folder $file.Path
        New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
        if ((Test-Path -LiteralPath $target) -and ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -eq $file.Info.md5)) { continue }
        & curl.exe --fail --location --retry 3 --retry-all-errors --silent --show-error --output $target $file.Info.url
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $target" }
        if ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -ne $file.Info.md5) { throw "Hash mismatch: $target" }
    }
    Write-Output "Downloaded and verified $id"
}
foreach ($item in @(
    @('fern_02','Alpha','fern_02_alpha_1k.png'),
    @('fir_sapling_medium','twigs_alpha','fir_sapling_medium_twigs_alpha_1k.png'),
    @('grass_medium_01','Alpha','grass_medium_01_alpha_1k.png'),
    @('pine_sapling_small','twig_alpha','pine_sapling_small_twig_alpha_1k.png'),
    @('wild_rooibos_bush','Alpha','wild_rooibos_bush_alpha_1k.png')
)) {
    $id, $mapName, $filename = $item
    $manifest = Invoke-RestMethod ('https://api.polyhaven.com/files/' + $id)
    $entry = $manifest.$mapName.'1k'.png
    $target = Join-Path (Join-Path $Destination $id) ('textures/' + $filename)
    if ((Test-Path -LiteralPath $target) -and ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -eq $entry.md5)) { continue }
    & curl.exe --fail --location --retry 3 --retry-all-errors --silent --show-error --output $target $entry.url
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $target" }
    if ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -ne $entry.md5) { throw "Hash mismatch: $target" }
}
foreach ($id in @('forest_ground_04','rocky_trail','gravelly_sand','rock_face')) {
    $folder = 'godot/assets/polyhaven/ground'
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $manifest = Invoke-RestMethod ('https://api.polyhaven.com/files/' + $id)
    foreach ($map in @(@('Diffuse','color'),@('nor_gl','normal'),@('Rough','rough'))) {
        $entry = $manifest.($map[0]).'2k'.jpg
        $target = Join-Path $folder ($id+'-'+$map[1]+'.jpg')
        if ((Test-Path -LiteralPath $target) -and ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -eq $entry.md5)) { continue }
        & curl.exe --fail --location --retry 3 --retry-all-errors --silent --show-error --output $target $entry.url
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $target" }
        if ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash -ne $entry.md5) { throw "Hash mismatch: $target" }
    }
    Write-Output "Downloaded terrain material $id"
}
