# Worn armor PBR material

`armor-worn-{color,normal,rough}.jpg`: original 2K JPEG maps from
[Green Metal Rust](https://polyhaven.com/a/green_metal_rust), Rob Tuytel / Poly Haven.
License: [CC0](https://polyhaven.com/license). Downloaded 2026-09-24.
API manifest: https://api.polyhaven.com/files/green_metal_rust

Source filenames: `green_metal_rust_diff_2k.jpg`,
`green_metal_rust_nor_gl_2k.jpg`, `green_metal_rust_rough_2k.jpg`.
The files are downloaded photographs/material maps, not AI generated.

The Godot armor shader preserves each vehicle's paint palette, uses metre-scaled
triplanar sampling, and combines the photographed wear, normal and roughness maps.
It replaces the former corrugated-paint appearance without modifying geometry.
Other source textures are documented in the repository's `assets/textures/SOURCES.md`.
