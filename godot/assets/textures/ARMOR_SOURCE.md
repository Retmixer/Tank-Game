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

## National armor materials

- USSR: `surface_ee849073e7f3.tres`, Green Metal Rust above; olive paint.
- Germany: `surface_7ed8764aa1c3.tres`, `armor-german-{color,normal,rough}.jpg`
  from [Metal Plate 02](https://polyhaven.com/a/metal_plate_02), Rob Tuytel,
  CC0. Source files `metal_plate_02_{diff,nor_gl,rough}_2k.jpg`.
  API: https://api.polyhaven.com/files/metal_plate_02 . Dark steel-gray paint.
- France: `surface_d7adcffc9575.tres`, `armor-french-{color,normal,rough}.jpg`
  from [Blue Metal Plate](https://polyhaven.com/a/blue_metal_plate), Rob Tuytel,
  CC0. Source files `blue_metal_plate_{diff,nor_gl,rough}_2k.jpg`.
  API: https://api.polyhaven.com/files/blue_metal_plate . Muted blue-gray paint.

All new maps are original downloaded 2K JPGs (2026-09-24). Each national
armor resource is shared by its four vehicles, both in the hangar and battle.
The colors distinguish the fictional national rosters; they are not claimed
to reproduce a particular historical camouflage standard. Small accessories
keep their existing shared materials. Portraits are rendered from these same
vehicle scenes with `editor/capture_vehicle_portraits.gd`.
