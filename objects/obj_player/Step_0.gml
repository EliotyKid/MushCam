inputs()
apply_velocity()



x+=hsp
y+=vsp


if keyboard_check_pressed(ord("B")){
  with (obj_camera_manager) {
    camera_follow("main", other.id)
  }
}

with (obj_camera_manager)  {
  var _data = get_camera("main")
  if  (!is_undefined(_data) && instance_exists(_data.obj))  {
    if  (_data.obj.mode == CAM_MODE.FOLLOW_OBJECT && _data.obj.object_to_follow == other.id)  {
      var _zoom_input = keyboard_check(ord("Y")) - keyboard_check(ord("H"))
      camera_set_zoom("main", _data.obj.new_zoom_percent + _zoom_input * _data.obj.zoom_spd)
    }
  }
}
