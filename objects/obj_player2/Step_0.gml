inputs()
apply_velocity()



x+=hsp
y+=vsp


if keyboard_check_pressed(ord("B")){
  with (obj_camera_manager) {
    camera_follow("player2", other.id)
  }
}
