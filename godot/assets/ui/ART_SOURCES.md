# UI artwork and fonts

## Native interface

The hangar/research layout is based on the two user-supplied references
`Без имени.png` and `Иследование.png`. Actual buttons, labels, progress bars,
filters, prices and vehicle state are editable Godot controls, not baked artwork.
There are four real vehicles per nation; the additional fictional vehicles shown
in the reference were not represented by non-functional cards.

`portraits/*.png` are transparent GPU renders of the authored Godot vehicle
scenes. Recreate with `editor/capture_vehicle_portraits.gd` using a GPU renderer,
then reimport. These are not AI-generated tanks.

Font: Exo 2, Google Fonts / Exo 2 Project Authors, SIL Open Font License 1.1.
Upstream: https://github.com/google/fonts/tree/main/ofl/exo2
Original font and license are stored in `../fonts/`.

## Generated background plates

Built-in imagegen was used only for the workshop illustration. Tank models and
in-game surface textures are not generated bitmap replacements.

File: `research-workshop.png`.
Reference: user-supplied `Иследование.png`.
Prompt:

> Use case: precise-object-edit. Asset type: clean 16:9 background plate for a real Godot tank-game research interface. Image 1 is the edit target. Remove ALL interface overlays, text, logos, tabs, buttons, panels, tank thumbnails, cards, arrows, currency, and the preview tank. Reconstruct only the realistic industrial military workshop visible behind the interface: tall steel beams and windows, warm hanging lamps, tool storage, subtle dusty light rays, dark olive steel crates and a drafting table with technical drawings at the bottom foreground. Preserve the reference's exact perspective, warm muted amber/charcoal palette and background composition. No vehicles, no people, no text, no UI, no frame, no watermark. Photoreal detailed materials, restrained contrast. This is background artwork only, with unobtrusive central space that will sit behind translucent native UI panels.
