"""Pack Poly Haven's downloaded RGB and transparency maps into RGBA for glTF.

Their 1K glTF references JPEGs even on BLEND materials, so the separate source
alpha maps must be packed before Godot can render needles and leaves correctly.
"""
from pathlib import Path
from PIL import Image

ROOT = Path("work/polyhaven-source")
MAPS = {
    "fern_02": ("fern_02_diff_1k.jpg", "fern_02_alpha_1k.png"),
    "fir_sapling_medium": ("fir_sapling_medium_twigs_diff_1k.jpg", "fir_sapling_medium_twigs_alpha_1k.png"),
    "grass_medium_01": ("grass_medium_01_diff_1k.jpg", "grass_medium_01_alpha_1k.png"),
    "pine_sapling_small": ("pine_sapling_small_twig_diff_1k.jpg", "pine_sapling_small_twig_alpha_1k.png"),
    "wild_rooibos_bush": ("wild_rooibos_bush_diff_1k.jpg", "wild_rooibos_bush_alpha_1k.png"),
}
for asset, (rgb_name, alpha_name) in MAPS.items():
    folder = ROOT / asset / "textures"
    with Image.open(folder / rgb_name) as rgb, Image.open(folder / alpha_name) as mask:
        color = rgb.convert("RGB")
        opacity = mask.convert("L")
        if opacity.size != color.size:
            opacity = opacity.resize(color.size, Image.Resampling.LANCZOS)
        color.putalpha(opacity)
        target = folder / (Path(rgb_name).stem + "_rgba.png")
        color.save(target, optimize=True)
        print(f"Composed {asset}: {target}")
