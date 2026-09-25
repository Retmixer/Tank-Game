# Ассеты новых карт

Модели и фототекстуры взяты из [Poly Haven](https://polyhaven.com/). На дату загрузки все перечисленные ресурсы опубликованы под [CC0](https://polyhaven.com/license); их можно включать в игру и редактировать.

| Карта | Исходники |
| --- | --- |
| Учебный полигон | [Pine Forest](https://polyhaven.com/collections/pine_forest): `fir_sapling_medium`, `fir_sapling`, `pine_sapling_small`, `fern_02`, `grass_medium_01`, `rock_moss_set_02`, `tree_stump_01`, `forest_ground_04`, `rocky_trail` |
| Пустынный полигон | [Namaqualand](https://polyhaven.com/collections/namaqualand): `namaqualand_boulder_02`, `namaqualand_boulder_04`, `namaqualand_cliff_02`, `quiver_tree_01`, `wild_rooibos_bush`, `gravelly_sand`, `rock_face` |
| Зимний завод | [Modular Factory Facade](https://polyhaven.com/a/modular_factory_facade); деревья и камни из Pine Forest |

`*.glb` — импортированные исходники 1K с уменьшенной плотностью сетки; `prepared/*.tscn` и `*.res` — отдельные редактируемые модули, которые используются на игровых картах. Исходные скачанные glTF лежат в локальной игнорируемой папке `work/polyhaven-source`. Для пересборки из корня репозитория:

```powershell
powershell -ExecutionPolicy Bypass -File tools/download-polyhaven.ps1
python tools/compose-polyhaven-alpha.py
npm install --prefix work/polyhaven-tools @gltf-transform/core@4.5.0 @gltf-transform/functions@4.5.0 @gltf-transform/extensions@4.5.0 meshoptimizer@1.2.0
node tools/prepare-polyhaven.mjs
godot --headless --path godot --editor --import
godot --headless --path godot --script res://editor/build_polyhaven_levels.gd -- --rebuild
```

Промежуточный скрипт объединяет скачанные цветные JPG с отдельными масками прозрачности Poly Haven. Python требует Pillow. Проверка маршрутов и свободных спавнов: `godot --headless --path godot --script res://editor/verify_polyhaven_levels.gd`.

Готовые игровые уровни находятся в `scenes/levels/polyhaven/`. Прежние сцены `scenes/levels/{training,desert,winter}.tscn` оставлены в проекте для сравнения. Генератор `editor/build_polyhaven_levels.gd` нужен лишь при пересборке и перезаписывает новые сцены; ручные правки новых уровней перед запуском генератора следует сохранить отдельно.
