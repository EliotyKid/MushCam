inputs()
apply_velocity()



x+=hsp
y+=vsp


if keyboard_check_pressed(ord("B")){
  with (obj_camera_manager) {
    camera_follow("player2", other.id)
  }
}

with (obj_camera_manager)  {
  var _data = get_camera("player2")
  if keyboard_check_pressed(ord("C")) _data.obj.set_target_offset(0,-69)
  if  (!is_undefined(_data) && instance_exists(_data.obj))  {
    if  (_data.obj.mode == CAM_MODE.FOLLOW_OBJECT && _data.obj.object_to_follow == other.id)  {
      var _zoom_input = keyboard_check(ord("U")) - keyboard_check(ord("J"))
      camera_set_zoom("player2", _data.obj.new_zoom_percent + _zoom_input * _data.obj.zoom_spd)
    }
  }
}
