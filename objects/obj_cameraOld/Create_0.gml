//enum  CAM_MODE  {
  //FOLLOW_OBJECT,
  //TO_TARGET
//}


size = new Vec2(width, height)
pos = new Vec2(0)

mode_string_to_enum = function(){
  switch (mode) {
    case "Follow Object": mode = CAM_MODE.FOLLOW_OBJECT break;
    case "To Target": mode = CAM_MODE.TO_TARGET break;
    default:show_debug_message($"não consigo converter isso: {mode}")
  }
}

mode_string_to_enum()

follow_target_pos = new Vec2(0)
to_target_pos = new Vec2(0)
spd = spd/10

zoom_percent = 0
new_zoom_percent = 0
zoom_spd = zoom_spd / 100

size_zoom = size

cam = camera_create_view(0,0,size.x, size.y)
view_set_camera(0,cam)
view_enabled = true
view_visible[0] = true

//camera_set_view_size(cam, size.x, size.y)
