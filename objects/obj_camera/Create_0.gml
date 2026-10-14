enum  CAM_MODE  {
  FOLLOW_OBJECT,
  TO_TARGET
}

mode = CAM_MODE.FOLLOW_OBJECT
spd = 1
zoom_range = .5
zoom_spd = 5
can_outside_room = true
object_to_follow = noone

size = new Vec2(
  camera_get_view_width(cam), 
  camera_get_view_height(cam)
)
pos = new Vec2(0)


follow_target_pos = new Vec2(0)
to_target_pos = new Vec2(0)
spd = spd/10

zoom_percent = 0
new_zoom_percent = 0
zoom_spd = zoom_spd / 100

size_zoom = size