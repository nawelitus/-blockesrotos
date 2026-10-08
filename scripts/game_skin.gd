class_name GameSkin
extends Resource
## Visual theme for the whole game. Scenes read every colour, shape and effect from
## here, so a new look only needs a new .tres file in res://skins/.

enum Background { WOOD_GRAIN, GRADIENT_BUBBLES, DARK_GRID }
## How a block is drawn: glossy candy, carved wood with grain, or a glowing neon tube.
enum BlockStyle { GLOSSY, WOOD, NEON }

@export var display_name := "Skin"

@export_group("Background")
@export var background_kind: Background = Background.WOOD_GRAIN
@export var bg_color_a := Color.BLACK
@export var bg_color_b := Color.BLACK
## Plank seams (wood), bubbles (gradient) or grid lines (dark).
@export var bg_accent := Color.WHITE

@export_group("Text")
@export var text_color := Color.WHITE
@export var text_dim_color := Color.GRAY
@export var accent_color := Color.YELLOW
@export var danger_color := Color.RED

@export_group("Panels")
@export var panel_color := Color(0, 0, 0, 0.5)
@export var panel_border_color := Color.WHITE
@export var panel_border_width := 2
@export var panel_radius := 16

@export_group("Buttons")
@export var button_color := Color.WHITE
@export var button_text_color := Color.BLACK
@export var button_border_color := Color.TRANSPARENT
@export var button_border_width := 0
@export var button_radius := 16

@export_group("Board")
@export var board_color := Color.BLACK
@export var board_border_color := Color.WHITE
@export var board_border_width := 4
@export var board_radius := 24
@export var cell_empty_color := Color(1, 1, 1, 0.08)
@export var cell_empty_border_color := Color(1, 1, 1, 0.05)
## Space between cells as a fraction of the cell size.
@export_range(0.0, 0.4) var cell_gap := 0.08
## Colour of the rows/columns that the dragged piece would complete.
@export var line_preview_color := Color(1, 1, 1, 0.25)
@export var clear_flash_color := Color(1, 1, 1, 0.8)

@export_group("Blocks")
@export var block_style: BlockStyle = BlockStyle.GLOSSY
## Palette; each piece takes one entry.
@export var block_colors := PackedColorArray([Color.RED, Color.GREEN, Color.BLUE])
## Corner radius as a fraction of the block size.
@export_range(0.0, 0.5) var block_radius := 0.18
@export var block_border_width := 3
## How much darker the border is than the fill (0..1).
@export_range(0.0, 1.0) var block_border_darken := 0.3
## Alpha of the light strip drawn on top of each block.
@export_range(0.0, 1.0) var block_gloss := 0.25
@export var block_shadow_color := Color(0, 0, 0, 0.35)
@export var block_shadow_size := 6
@export var block_shadow_offset := Vector2(0, 3)
