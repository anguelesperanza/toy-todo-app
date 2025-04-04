package main


import "core:fmt"
import rl "vendor:raylib"
import clay "../clay-odin"
import "core:c"
import "core:strings"
import "core:unicode/utf8"
import "base:runtime"
import "base:builtin"



win_width:i32 = 640
win_height:i32 = 480

COLOR_GREEN :: clay.Color{12, 123,89, 255}
COLOR_PURPLE :: clay.Color{43, 41, 51, 255}
COLOR_GRAY :: clay.Color{90, 90, 90, 255}
COLOR_BROWN :: clay.Color{123, 80, 62, 255}

FONT_SOFTBALL_GOLD :: 0

// taken from https://github.com/nicbarker/clay/blob/main/bindings/odin/examples/clay-official-website/clay-official-website.odin
loadFont :: proc(fontId: u16, fontSize: u16, path: cstring) {
    raylibFonts[fontId] = RaylibFont {
        font   = rl.LoadFontEx(path, cast(i32)fontSize * 2, nil, 0),
        fontId = cast(u16)fontId,
    }
    rl.SetTextureFilter(raylibFonts[fontId].font.texture, rl.TextureFilter.TRILINEAR)
}

error_handler :: proc "c" (errorData: clay.ErrorData) {
    if (errorData.errorType == clay.ErrorType.DuplicateId) {
        // etc
    }
}

// ===== START OF TEXT BOX STRUCT / PROCS / VARIABLES  =====

// global buffer that will be the textbox's text. This is what will be edited
// Takes value from rl.GetCharPressed() function

TextBoxData :: struct {
	buffer: [dynamic]u8
}

tbd:TextBoxData

empty_rune: [4]u8 = {0, 0, 0, 0} // Used to check if next pressed key is empty (not space)
dynamic_textbox_buffer:[dynamic]u8 // array saving pressed key values too

// The config for the textbox (really just the text element stuff needed) 
textbox_config := clay.TextElementConfig {
    fontId    = FONT_SOFTBALL_GOLD,
    fontSize  = 24,
    textColor = {61, 26, 5, 255},
}

// The callback function for when the textbox is clicked
handle_button_clicked :: proc "c" (id: clay.ElementId, pointerData: clay.PointerData, userData:rawptr){
	context = runtime.default_context()
	data_pointer := cast(^int)userData
	data := data_pointer^
	if pointerData.state == .PressedThisFrame {
		
		fmt.println(data)
		unordered_remove(&todo_list, data)
	}
}

// The textbox itself that is displayed at the top of the window
textbox :: proc(val:string) {
	if clay.UI()({
		id = clay.ID("textbox"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(size = 50)},
			padding = {left = 16, right = 16, top = 8, bottom = 8},
		},
		backgroundColor = {140, 140, 140, 225},
		cornerRadius = clay.CornerRadiusAll(5),
	}){
		clay.TextDynamic(val, &textbox_config)
	}
}
// ===== END OF TEXT BOX STRUCT / PROCS / VARIABLES  =====

// ===== START OF LIST STRUCT / PROCS / VARIABLES  =====
todo_list: [dynamic]string // list of strings that will be the todo list

button :: proc(index:u32){
	if clay.UI()({
		id = clay.ID("button", index),
		layout = {
			sizing = {width = clay.SizingFixed(size = 60), height = clay.SizingFixed(size = 60)},
			layoutDirection = .TopToBottom,
			childGap = 16,
		},
		
		backgroundColor = clay.Hovered() ? COLOR_BROWN : COLOR_GRAY,
		// backgroundColor = COLOR_PURPLE,
		cornerRadius = clay.CornerRadiusAll(5),
	}){
		
		temp := builtin.new_clone(index)
		clay.OnHover(handle_button_clicked, temp)
	}
}

label :: proc(value:string) {
	if clay.UI()({
		id = clay.ID("todo_label"),
		layout = {
			sizing = {width = clay.SizingGrow({max = 500}), height = clay.SizingGrow({max = 60})},
			padding = clay.PaddingAll(16),
			layoutDirection = .LeftToRight,
		},
		backgroundColor = COLOR_PURPLE,
		cornerRadius = clay.CornerRadiusAll(5)
	}){
		clay.TextDynamic(value, &textbox_config)
	}
}

row :: proc (value:string, index:u32){
	if clay.UI()({
		id = clay.ID("row", index),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingFixed(size = 60)},
			childGap =  16,
		},
	}){

		label(value)
		button(index)
		
	}
}

todo_list_container :: proc(){

	if clay.UI()({
		id = clay.ID("todo_container_vbox"),
		layout = {
			sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})},
			childGap = 16,
			layoutDirection = .TopToBottom
		},
		scroll = {vertical = true},
		// backgroundColor = COLOR_GRAY,
		cornerRadius = clay.CornerRadiusAll(5),
	}){
		for i in 0..<len(todo_list) {
			row(todo_list[i], u32(i))
		}
	}
}

// ===== END OF LIST STRUCT / PROCS / VARIABLES  =====
main :: proc () {
	min_memm_size: c.size_t = cast(c.size_t)clay.MinMemorySize() // Get minimum memmory size
	memmory := make([^]u8, min_memm_size) // Create the memory
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(min_memm_size, memmory) // Create arena

	clay.Initialize(arena, {cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()}, {handler = error_handler})
	clay.SetMeasureTextFunction(measureText, nil)

	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI})
	
	rl.InitWindow(win_width, win_height, "Mod Manager")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)

	loadFont(FONT_SOFTBALL_GOLD, 48, "softball-gold.ttf")

	for !rl.WindowShouldClose(){
		defer free_all(context.temp_allocator)

		layout_expand:clay.Sizing = {width = clay.SizingGrow({}), height = clay.SizingGrow({})} // Sizing is just a struct so it can be assigned and used as a variable
		clay.SetPointerState(transmute(clay.Vector2)rl.GetMousePosition(),rl.IsMouseButtonDown(rl.MouseButton.LEFT))
    	clay.UpdateScrollContainers(true, transmute(clay.Vector2)rl.GetMouseWheelMoveV(),rl.GetFrameTime())
		clay.SetLayoutDimensions(dimensions = {cast(f32)rl.GetScreenWidth(), cast(f32)rl.GetScreenHeight()}) // Resizes the layout to the size of the screen

		key_pressed_rune := rl.GetCharPressed() // Get pressed keyboard key (returns a rune)
		key_pressed_encoded, _ := utf8.encode_rune(key_pressed_rune) // converts run into a [4]u8

		// checkes if coverted rune is not {0, 0, 0, 0} (empty string)
		if key_pressed_encoded != empty_rune {
			append(&tbd.buffer, key_pressed_encoded[0])
		}

		// Check if either Delete, Backspace or Enter are pressed
		// Done in a switch as if Delete was pressed, backspace would no longer work
		// Switch Statement avoid that problem (for reasons I do not to understand)
		action_key := rl.GetKeyPressed()
		#partial switch action_key {
			case .DELETE:
				if len(tbd.buffer) > 0 {
					clear(&tbd.buffer)
				}
			case .BACKSPACE:
				
				if len(tbd.buffer) > 0 {
					pop(&tbd.buffer)
				}
			case .ENTER:
				// TODO: Add remove button
				if len(tbd.buffer) > 0 {
					old_buffer_len := len(tbd.buffer)
					new_buffer, _ := make([dynamic]u8, old_buffer_len)
					// copies elements in tbd.buffer into new_buffer
					// If copy() is used, or the 'for in ...' syntax, the data
					// does not copy over properly end ends up overwritten.
					// That doesnot happen this way
					for i := 0; i < len(tbd.buffer); i += 1 {
						new_buffer[i] = tbd.buffer[i]
					}
					append(&todo_list, string(new_buffer[:]))
					clear(&tbd.buffer)
				}
			}
		
		clay.BeginLayout() // Start layout

		if clay.UI()({
			id = clay.ID("OuterContainer"),
			layout = {
				layoutDirection = .TopToBottom,
				sizing = layout_expand,
				padding = clay.PaddingAll(16),
				childGap = 16,
			},
			backgroundColor = COLOR_GREEN,
		}){
			textbox(string(tbd.buffer[:]))
			todo_list_container()
		}

		render_commands:= clay.EndLayout()
				
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		clayRaylibRender(renderCommands = &render_commands) // Render layouts
		rl.EndDrawing()
	}

}
