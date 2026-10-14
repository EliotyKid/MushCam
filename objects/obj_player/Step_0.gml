if  (is_keyboard_used_debug_overlay())  {
  exit
}

inputs()
apply_velocity()



var _frame_scale = max(0, delta_time / 1000000) * 60
x+=hsp * _frame_scale
y+=vsp * _frame_scale


if keyboard_check_pressed(ord("B")){
  with (obj_camera_manager) {
    camera_follow("main", other.id)
  }
}

with (obj_camera_manager)  {
  var _data = get_camera("main")
  if  (!is_undefined(_data) && instance_exists(_data.obj))  {
    var _following = _data.obj.mode == CAM_MODE.FOLLOW_OBJECT && _data.obj.object_to_follow == other.id
    var _in_group = _data.obj.mode == CAM_MODE.FOLLOW_GROUP && _data.obj.focus_group.contains_target(other.id)
    if  (_following || _in_group)  {
      var _zoom_input = keyboard_check(ord("Y")) - keyboard_check(ord("H"))
      var _seconds = max(0, delta_time / 1000000)
      camera_adjust_zoom("main", _zoom_input * _data.obj.zoom_input_spd * _seconds)
    }
  }
}
