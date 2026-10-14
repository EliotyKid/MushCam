//function game_init(){
	//if !instance_exists(obj_window_manager) instance_create_layer(0,0,"Controllers",obj_window_manager)
	//room_goto(global.game_settings.room_start)
//}
//
//function game_set_window(){
	//if !global.game_settings.cursor_visible window_set_cursor(cr_none)
	//window_set_caption(global.game_settings.window_caption)
    //
  //window_set_size(global.game_settings.window_width, global.game_settings.window_height);
    //
    //
	//surface_resize(application_surface,global.game_settings.view_width,global.game_settings.view_height)
	//display_set_gui_size(global.game_settings.gui_width,global.game_settings.gui_height)
	//
	//var _time_source_window_center = time_source_create(time_source_game,1,time_source_units_frames,window_center)
	//time_source_start(_time_source_window_center)
	//
	//var _window_set_fullscreen = function(){
		//window_set_fullscreen(global.game_settings.start_fullscreen)
	//}
	//var _time_source_window_fullscreen = time_source_create(time_source_game,10,time_source_units_frames,_window_set_fullscreen)
	//time_source_start(_time_source_window_fullscreen)
//}
//
//
//function game_enable_view_port(){
	//global.game_settings.view_cam = view_camera[global.game_settings.view]
	//view_enabled = true
	//view_visible[global.game_settings.view ] = true
	//camera_set_view_size(global.game_settings.view_cam,global.game_settings.view_width,global.game_settings.view_height)
//}
//
//function game_toggle_fullscreen(){
    //if (os_browser != browser_not_a_browser) {
        //if (!window_get_fullscreen()) {
            //window_set_fullscreen(true);
        //} else {
            //window_set_fullscreen(false);
        //}
    //} else {
        //// Lógica original para Windows/Mac
        //window_set_fullscreen(!window_get_fullscreen());
    //}
//}
