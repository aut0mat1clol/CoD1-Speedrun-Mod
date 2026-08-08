# UI: настройки мода в стоковом меню OPTIONS

Три файла внутри `z_sr_speedrun_loctext.pk3` (`ui/`). Два стоковых файла
изменены минимально, один новый. SP-меню живут в `ui/` (не `ui_mp/`!) —
движок сингла читает список из `ui/menus.txt` оригинального
`localized_english_pak0.pk3`; наш pk3 перекрывает его по алфавиту (`z_...`).

## `ui/menus.txt` (сток + 1 строка)

```diff
 	loadMenu { "ui/options.menu" }
+	loadMenu { "ui/sr_settings.menu" }	// SPEEDRUN MOD
 	loadMenu { "ui/options_look.menu" }
```

## `ui/options.menu` (сток + добавление пункта)

1. В каждый из 15 существующих action-блоков кнопок-вкладок добавлена
   строка `close sr_settings;` — чтобы панель настроек мода закрывалась
   при переключении на любую другую вкладку OPTIONS (зеркально тому, как
   сток закрывает свои панели).
2. Добавлены два `itemDef` внизу меню (ниже кнопки НАЗАД, правый нижний
   угол): декоративный заголовок `Speedrun Mod` и кнопка `Settings`,
   в action которой — `close` всех стоковых вкладок + `open sr_settings;`.

## `ui/sr_settings.menu` (новый файл)

Окно-панель слева: переключатели `sr_speedo`, `sr_spd_avg`, `sr_igt`,
`sr_debug`, список `sr_spd_dec` (0–3) и кнопка **Reset Run**, выполняющая:

```
setcvar rt_run_total 0; setcvar rt_ms_cur 0; setcvar rt_wtotal 0;
setcvar rt_wcur_int 0; setcvar rt_spd_max 0; setcvar rt_end_frozen 0;
setcvar rt_cont_real 0; setcvar rt_cont_wall 0; setcvar rt_cmd_mreset 1
```

$(rt_cmd_mreset 1) — «защёлка»: GSC-цикл примет её и переустановит якоря
таймеров на том же тике.

## Нюанс с сохранением

Меню меняет cvar'ы «вживую». Чтобы движок писал их в `config.cfg`, cvar
должен быть создан с флагом ARCHIVE — делается ОДИН раз из консоли:

```
seta sr_speedo 1; seta sr_spd_avg 1; seta sr_igt 1; seta sr_spd_dec 1; seta sr_debug 0
```

В `autoexec.cfg` мод эти строки НЕ кладёт намеренно: `seta` из autoexec
выполнялся бы при каждом запуске и затирал бы сохранённые игроком
значения.
