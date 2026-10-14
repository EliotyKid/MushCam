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
// Posicao base e desejada representam o centro da camera no mundo
pos = new Vec2(
  camera_get_view_x(cam) + size.x * .5,
  camera_get_view_y(cam) + size.y * .5
)
desired_pos = new Vec2(pos.x, pos.y)
render_pos = new Vec2(0)
target_offset = new Vec2(0)
follow_target_pos = new Vec2(pos.x, pos.y)
to_target_pos = new Vec2(0)
spd = spd/10

zoom_percent = 0
new_zoom_percent = 0
zoom_spd = zoom_spd / 100

size_zoom = new Vec2(size.x, size.y)

set_viewport_size = function(_size, _height)  {
  if  (_size.x <= 0 || _size.y <= 0 || _height <= 0)  return false
  size = new Vec2(_height * _size.x / _size.y, _height)
  return true
}

set_target_offset = function(_x, _y)  {
  target_offset = new Vec2(_x, _y)
  return true
}

set_zoom_percent = function(_percent)  {
  new_zoom_percent = clamp(_percent, -1, 1)
  return true
}

update_zoom = function()  {
  zoom_percent = lerp(zoom_percent, new_zoom_percent, zoom_spd)
  zoom_percent = clamp(zoom_percent, -1, 1)
  var _scale = 1 - zoom_range * zoom_percent
  size_zoom = new Vec2(size.x * _scale, size.y * _scale)
}

update_target = function()  {
  switch (mode)  {
    case CAM_MODE.FOLLOW_OBJECT:
      if  (!instance_exists(object_to_follow))  return false
      follow_target_pos = new Vec2(object_to_follow.x, object_to_follow.y)
      desired_pos = new Vec2(
        follow_target_pos.x + target_offset.x,
        follow_target_pos.y + target_offset.y
      )
      return true
    case CAM_MODE.TO_TARGET:
      desired_pos = new Vec2(
        to_target_pos.x + target_offset.x,
        to_target_pos.y + target_offset.y
      )
      return true
  }
  return false
}

update_position = function()  {
  if  (!update_target())  return undefined
  pos.x = lerp(pos.x, desired_pos.x, spd)
  pos.y = lerp(pos.y, desired_pos.y, spd)
}

limit_position = function()  {
  if  (can_outside_room)  return undefined
  var _half = new Vec2(size_zoom.x * .5, size_zoom.y * .5)
  pos.x = size_zoom.x >= room_width ? room_width * .5 : clamp(pos.x, _half.x, room_width - _half.x)
  pos.y = size_zoom.y >= room_height ? room_height * .5 : clamp(pos.y, _half.y, room_height - _half.y)
}

apply_camera = function()  {
  render_pos = new Vec2(pos.x - size_zoom.x * .5, pos.y - size_zoom.y * .5)
  camera_set_view_size(cam, size_zoom.x, size_zoom.y)
  camera_set_view_pos(cam, render_pos.x, render_pos.y)
}

update_camera = function()  {
  update_zoom()
  update_position()
  limit_position()
  apply_camera()
}
