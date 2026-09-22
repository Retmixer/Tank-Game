# Авторы моделей и звуков

Все файлы поставляются локально; игра не обращается к сайтам авторов при запуске.

| Файлы в игре | Автор, оригинал | Лицензия |
|---|---|---|
| `models/kenney.js`: building-a…f; `models/industrial-colormap.png` | Kenney, [City Kit (Industrial) 2.0](https://kenney.nl/assets/city-kit-industrial) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `models/kenney.js`: rock_largeA…C, tree_oak, tree_pineDefaultA | Kenney, [Nature Kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 |
| `audio/engine.ogg` | Nayckron, collaborator qubodup, [Engine-loop heavy vehicle/tank](https://opengameart.org/content/engine-loop-heavy-vehicletank), original `engine_heavy_loop_1.ogg` | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/) (выбрана из предложенных автором лицензий) |
| `audio/shot.ogg` | Thimras, [Cannon fire](https://opengameart.org/content/cannon-fire), original `cannon_fire_0.ogg` | CC0 1.0 |
| `audio/hit.ogg` | Thimras, [Cannon hit cannon](https://opengameart.org/content/cannon-hit-cannon), original `cannon_hit_cannon.ogg` | CC0 1.0 |
| `audio/boom.ogg` | Thimras, [Cannon hit](https://opengameart.org/content/cannon-hit), original `cannon_hit.ogg` | CC0 1.0 |
| `audio/wind.ogg` | Luke.RUSTLTD, [wind1](https://opengameart.org/content/wind1), OGG preview of `wind1.wav` | CC0 1.0 |

Изменения: модели преобразованы из OBJ/MTL в геометрию Three.js, масштабированы под карту; деревья перекрашены. Конвертер: `tools/import-models.cjs`. Аудиофайлы переименованы без изменения содержимого; при воспроизведении меняются громкость, панорама и скорость. Движок микширует звуки, это не записи конкретных исторических моделей танков.

Это готовые **модели окружения**, которыми заменены здания и скалы существующих арен, с дополнительными деревьями. Планировка, рельеф, дороги, база и навигация карт остаются разработкой «Стального рубежа»; готовые авторские карты целиком не импортировались.

Лицензии наборов также сохранены в `licenses/`. Дата получения: 19 сентября 2026.
