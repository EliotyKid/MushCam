enum  CAM_MODE  {
  FOLLOW_OBJECT,
  TO_TARGET,
  FIXED,
  MANUAL
}

mode = CAM_MODE.FIXED
spd = 1
zoom_range = .5
zoom_spd = 5
can_outside_room = true
object_to_follow = noone
arrival_distance = .5

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

set_mode = function(_mode)  {
  if  (_mode != CAM_MODE.FOLLOW_OBJECT && _mode != CAM_MODE.TO_TARGET && _mode != CAM_MODE.FIXED && _mode != CAM_MODE.MANUAL)  return false
  if  (_mode == CAM_MODE.FOLLOW_OBJECT && !instance_exists(object_to_follow))  return false
  if  (_mode == mode)  return true
  desired_pos = new Vec2(pos.x, pos.y)
  if  (_mode == CAM_MODE.TO_TARGET)  {
    to_target_pos = new Vec2(pos.x - target_offset.x, pos.y - target_offset.y)
  }
  if  (_mode != CAM_MODE.FOLLOW_OBJECT)  object_to_follow = noone
  mode = _mode
  return true
}

set_follow_target = function(_target, _snap = false)  {
  if  (_target == noone)  return set_mode(CAM_MODE.FIXED)
  if  (!instance_exists(_target))  return false
  object_to_follow = _target
  set_mode(CAM_MODE.FOLLOW_OBJECT)
  if  (_snap)  {
    update_target()
    pos = new Vec2(desired_pos.x, desired_pos.y)
  }
  return true
}

move_to = function(_x, _y)  {
  set_mode(CAM_MODE.TO_TARGET)
  to_target_pos = new Vec2(_x, _y)
  return true
}

set_position = function(_x, _y)  {
  set_mode(CAM_MODE.FIXED)
  pos = new Vec2(_x, _y)
  desired_pos = new Vec2(_x, _y)
  return true
}

move_by = function(_x, _y)  {
  set_mode(CAM_MODE.MANUAL)
  pos.x += _x
  pos.y += _y
  desired_pos = new Vec2(pos.x, pos.y)
  return true
}

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
      if  (!instance_exists(object_to_follow))  {
        set_mode(CAM_MODE.FIXED)
        return false
      }
      follow_target_pos = new Vec2(object_to_follow.x, object_to_follow.y)
      desired_pos = new Vec2(
        follow_target_pos.x + target_offset.x,
        follow_target_pos.y + target_offset.y
      )
      return true
    case CAM_MODE.FIXED:
    case CAM_MODE.MANUAL:
      return false
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
  limit_position(desired_pos)
  pos.x = lerp(pos.x, desired_pos.x, spd)
  pos.y = lerp(pos.y, desired_pos.y, spd)
  if  (mode == CAM_MODE.TO_TARGET && point_distance(pos.x, pos.y, desired_pos.x, desired_pos.y) <= arrival_distance)  {
    pos = new Vec2(desired_pos.x, desired_pos.y)
    set_mode(CAM_MODE.FIXED)
  }
}

limit_position = function(_position = pos)  {
  if  (can_outside_room)  return undefined
  var _half = new Vec2(size_zoom.x * .5, size_zoom.y * .5)
  _position.x = size_zoom.x >= room_width ? room_width * .5 : clamp(_position.x, _half.x, room_width - _half.x)
  _position.y = size_zoom.y >= room_height ? room_height * .5 : clamp(_position.y, _half.y, room_height - _half.y)
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
