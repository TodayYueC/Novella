# Novella Command Reference

Novella commands are written with an `@` prefix inside `.nvs` files.

## Core

- `@var name = value`
- `@set name += value`
- `@flag set flag_name`
- `@wait 0.5`
- `@if expression then command`
- `@random label_a:70 label_b:30 seed:1`
- `@jump label`, `@call label`, `@return`

## Presentation

- `@mode adv|nvl`
- `@bg id transition:dissolve time:0.5`
- `@char id attributes... pos:left`
- `@char_move id pos:right time:0.5`
- `@char_emotion id happy`
- `@char_remove id`
- `@play_music id fade:1.0`
- `@stop_music fade:0.5`
- `@play_se id`
- `@play_voice id wait:true`
- `@camera pos:10,20 zoom:1.2`
- `@camera_reset`
- `@shake intensity:0.4 duration:0.2`
- `@flash color:#ffffff duration:0.2`
- `@nvl_clear`

## Interaction And State

- `@save slot`
- `@load slot`
- `@quick_save`
- `@quick_load`
- `@auto_save trigger`
- `@settings set text_speed:40 auto_delay:1.5 fullscreen:false`
- `@config set text_speed:40`
- `@rollback`
- `@prevent_rollback`
- `@allow_rollback`
- `@skip read|all|off`
- `@auto on|off delay:1.5`
- `@backlog_clear`
- `@choice_timeout seconds:5 target:timeout_label`
- `@quick_menu show|hide|toggle`
- `@input variable prompt:"Name"`

## Meta

- `@locale en`
- `@language en`
- `@translation en key text:"Hello."`
- `@tr_var player Yue`
- `@gallery unlock cg_school title:School asset:school.png`
- `@replay unlock intro label:start title:Intro`
- `@achievement register reader title:Reader target:3`
- `@achievement progress reader amount:1`
- `@achievement unlock first_step title:First`
- `@achieve unlock first_step title:First`
- `@meta_check achievement:first_step`

`@language` and `@achieve` remain accepted aliases for compatibility. New scripts should prefer `@locale` and `@achievement`.
## v1.7 Example Command Coverage

The full VN example at `examples/full_vn/scripts/chapter_01.nvs` demonstrates:

- `@locale`, `@translation`
- `@bg`, `@char`, `@shake`
- `@play_music`, `@stop_music`
- `@set`, `menu`, `jump`
- `@gallery`, `@achievement`
- `@mode`, `@save`

## v1.7 示例命令覆盖

完整示例 `examples/full_vn/scripts/chapter_01.nvs` 覆盖：

- `@locale`、`@translation`
- `@bg`、`@char`、`@shake`
- `@play_music`、`@stop_music`
- `@set`、`menu`、`jump`
- `@gallery`、`@achievement`
- `@mode`、`@save`
