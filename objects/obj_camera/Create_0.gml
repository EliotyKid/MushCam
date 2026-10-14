enum  CAM_MODE  {
  FOLLOW_OBJECT,
  TO_TARGET,
  FIXED,
  MANUAL
}

mode = CAM_MODE.FIXED
spd = new Vec2(.1)
zoom_range = .5
zoom_spd = .05
zoom_input_spd = 3
can_outside_room = true
bounds = undefined
object_to_follow = noone
arrival_distance = .5
dead_zone_enabled = false
dead_zone_size = new Vec2(120, 80)

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

zoom_percent = 0
new_zoom_percent = 0

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

adjust_zoom = function(_amount)  {
  return set_zoom_percent(new_zoom_percent + _amount)
}

set_smoothing = function(_x, _y = _x, _zoom = undefined)  {
  spd = new Vec2(clamp(_x, 0, 1), clamp(_y, 0, 1))
  if  (!is_undefined(_zoom))  zoom_spd = clamp(_zoom, 0, 1)
  return true
}

set_zoom_settings = function(_range, _input_spd = undefined)  {
  zoom_range = clamp(_range, 0, .95)
  if  (!is_undefined(_input_spd))  zoom_input_spd = max(0, _input_spd)
  return true
}

smoothing_factor = function(_speed, _seconds)  {
  _speed = clamp(_speed, 0, 1)
  if  (_seconds <= 0 || _speed == 0)  return 0
  if  (_speed == 1)  return 1
  return 1 - power(1 - _speed, _seconds * 60)
}

get_bounds = function()  {
  if  (!is_undefined(bounds))  return bounds
  return {pos: new Vec2(0), size: new Vec2(room_width, room_height)}
}

set_bounds = function(_x, _y, _width, _height)  {
  if  (!is_real(_x) || !is_real(_y) || !is_real(_width) || !is_real(_height))  return false
  var _values = [_x, _y, _width, _height]
  for(var i=0; i<array_length(_values); i++)  {
    if  (is_nan(_values[i]) || is_infinity(_values[i]))  return false
  }
  if  (_width <= 0 || _height <= 0)  return false
  if  (is_infinity(_x + _width) || is_infinity(_y + _height))  return false
  bounds = {pos: new Vec2(_x, _y), size: new Vec2(_width, _height)}
  can_outside_room = false
  return true
}

use_room_bounds = function()  {
  bounds = undefined
  can_outside_room = false
  return true
}

set_limits_enabled = function(_enabled = true)  {
  can_outside_room = !_enabled
  return true
}

set_dead_zone = function(_width, _height, _enabled = true)  {
  if  (!is_real(_width) || !is_real(_height))  return false
  if  (is_nan(_width) || is_nan(_height) || is_infinity(_width) || is_infinity(_height))  return false
  if  (_width < 0 || _height < 0)  return false
  dead_zone_size = new Vec2(_width, _height)
  dead_zone_enabled = _enabled
  return true
}

set_dead_zone_enabled = function(_enabled = true)  {
  dead_zone_enabled = _enabled
  return true
}

get_dead_zone = function()  {
  var _size = new Vec2(min(dead_zone_size.x, size_zoom.x), min(dead_zone_size.y, size_zoom.y))
  return {
    pos: new Vec2(pos.x - target_offset.x - _size.x * .5, pos.y - target_offset.y - _size.y * .5),
    size: _size
  }
}

apply_dead_zone = function()  {
  if  (!dead_zone_enabled || mode != CAM_MODE.FOLLOW_OBJECT)  return undefined
  var _half = new Vec2(min(dead_zone_size.x, size_zoom.x) * .5, min(dead_zone_size.y, size_zoom.y) * .5)
  var _distance = new Vec2(desired_pos.x - pos.x, desired_pos.y - pos.y)
  desired_pos.x -= clamp(_distance.x, -_half.x, _half.x)
  desired_pos.y -= clamp(_distance.y, -_half.y, _half.y)
}

update_zoom = function(_seconds = delta_time / 1000000)  {
  var _factor = smoothing_factor(zoom_spd, _seconds)
  zoom_percent = lerp(zoom_percent, new_zoom_percent, _factor)
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

update_position = function(_seconds = delta_time / 1000000)  {
  if  (!update_target())  return undefined
  apply_dead_zone()
  limit_position(desired_pos)
  var _factor_x = smoothing_factor(spd.x, _seconds)
  var _factor_y = smoothing_factor(spd.y, _seconds)
  pos.x = lerp(pos.x, desired_pos.x, _factor_x)
  pos.y = lerp(pos.y, desired_pos.y, _factor_y)
  if  (mode == CAM_MODE.TO_TARGET && point_distance(pos.x, pos.y, desired_pos.x, desired_pos.y) <= arrival_distance)  {
    pos = new Vec2(desired_pos.x, desired_pos.y)
    set_mode(CAM_MODE.FIXED)
  }
}

limit_position = function(_position = pos)  {
  if  (can_outside_room)  return undefined
  var _bounds = get_bounds()
  var _half = new Vec2(size_zoom.x * .5, size_zoom.y * .5)
  var _min = new Vec2(_bounds.pos.x + _half.x, _bounds.pos.y + _half.y)
  var _max = new Vec2(_bounds.pos.x + _bounds.size.x - _half.x, _bounds.pos.y + _bounds.size.y - _half.y)
  _position.x = size_zoom.x >= _bounds.size.x ? _bounds.pos.x + _bounds.size.x * .5 : clamp(_position.x, _min.x, _max.x)
  _position.y = size_zoom.y >= _bounds.size.y ? _bounds.pos.y + _bounds.size.y * .5 : clamp(_position.y, _min.y, _max.y)
}

apply_camera = function()  {
  render_pos = new Vec2(pos.x - size_zoom.x * .5, pos.y - size_zoom.y * .5)
  camera_set_view_size(cam, size_zoom.x, size_zoom.y)
  camera_set_view_pos(cam, render_pos.x, render_pos.y)
}

update_camera = function()  {
  var _seconds = max(0, delta_time / 1000000)
  update_zoom(_seconds)
  update_position(_seconds)
  limit_position()
  apply_camera()
}
