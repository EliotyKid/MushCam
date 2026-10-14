enum  CAM_MODE  {
  FOLLOW_OBJECT,
  TO_TARGET,
  FIXED,
  MANUAL,
  FOLLOW_GROUP
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
look_ahead_enabled = false
look_ahead_time = new Vec2(.25)
look_ahead_max = new Vec2(80, 50)
look_ahead_spd = new Vec2(.1)
look_ahead = new Vec2(0)
look_ahead_desired = new Vec2(0)
target_velocity = new Vec2(0)
look_ahead_previous = new Vec2(0)
look_ahead_target = noone
look_ahead_ready = false
teleport_distance = 256
focus_group = new CameraFocusGroup()
shake = new CameraShake()
group_framing_enabled = true
group_margin = new Vec2(32)
group_min_scale = .5
group_max_scale = 0
group_view_height = undefined
group_fits = false
group_max_reached = false
look_ahead_revision = 0

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
follow_pos = new Vec2(pos.x, pos.y)
render_pos = new Vec2(0)
target_offset = new Vec2(0)
follow_target_pos = new Vec2(pos.x, pos.y)
to_target_pos = new Vec2(0)

zoom_percent = 0
new_zoom_percent = 0

size_zoom = new Vec2(size.x, size.y)
manual_view_size = new Vec2(size.x, size.y)

is_following = function()  {
  return mode == CAM_MODE.FOLLOW_OBJECT || mode == CAM_MODE.FOLLOW_GROUP
}

set_mode = function(_mode)  {
  if  (_mode != CAM_MODE.FOLLOW_OBJECT && _mode != CAM_MODE.TO_TARGET && _mode != CAM_MODE.FIXED && _mode != CAM_MODE.MANUAL && _mode != CAM_MODE.FOLLOW_GROUP)  return false
  if  (_mode == CAM_MODE.FOLLOW_OBJECT && !instance_exists(object_to_follow))  return false
  if  (_mode == CAM_MODE.FOLLOW_GROUP && !focus_group.update())  return false
  if  (_mode == mode)  return true
  desired_pos = new Vec2(pos.x, pos.y)
  follow_pos = new Vec2(pos.x, pos.y)
  if  (_mode == CAM_MODE.TO_TARGET)  {
    to_target_pos = new Vec2(pos.x - target_offset.x, pos.y - target_offset.y)
  }
  if  (_mode != CAM_MODE.FOLLOW_OBJECT)  object_to_follow = noone
  mode = _mode
  reset_look_ahead()
  return true
}

set_follow_group = function(_sources, _snap = false)  {
  if  (!focus_group.set_sources(_sources))  return false
  if  (!focus_group.update())  return set_mode(CAM_MODE.FIXED)
  set_mode(CAM_MODE.FOLLOW_GROUP)
  reset_look_ahead()
  if  (_snap)  {
    update_target()
    pos = new Vec2(desired_pos.x, desired_pos.y)
    follow_pos = new Vec2(pos.x, pos.y)
  }
  return true
}

add_group_target = function(_source)  {
  if  (!focus_group.add_source(_source))  return false
  focus_group.update()
  return set_mode(CAM_MODE.FOLLOW_GROUP)
}

remove_group_target = function(_index)  {
  if  (!focus_group.remove_source(_index))  return false
  if  (!focus_group.update() && mode == CAM_MODE.FOLLOW_GROUP)  set_mode(CAM_MODE.FIXED)
  return true
}

clear_group = function()  {
  focus_group.clear()
  focus_group.update()
  if  (mode == CAM_MODE.FOLLOW_GROUP)  set_mode(CAM_MODE.FIXED)
  return true
}

set_group_framing = function(_margin_x, _margin_y = _margin_x, _min_scale = .5, _max_scale = 0)  {
  var _values = [_margin_x, _margin_y, _min_scale, _max_scale]
  for(var i=0; i<array_length(_values); i++)  {
    if  (!is_real(_values[i]))  return false
    if  (is_nan(_values[i]) || is_infinity(_values[i]) || _values[i] < 0)  return false
  }
  if  (_min_scale <= 0 || (_max_scale > 0 && _max_scale < _min_scale))  return false
  group_margin = new Vec2(_margin_x, _margin_y)
  group_min_scale = _min_scale
  group_max_scale = _max_scale
  return true
}

set_group_framing_enabled = function(_enabled = true)  {
  group_framing_enabled = _enabled
  return true
}

set_follow_target = function(_target, _snap = false)  {
  if  (_target == noone)  return set_mode(CAM_MODE.FIXED)
  if  (!instance_exists(_target))  return false
  var _changed = object_to_follow != _target
  object_to_follow = _target
  set_mode(CAM_MODE.FOLLOW_OBJECT)
  if  (_changed || _snap)  reset_look_ahead()
  if  (_snap)  {
    update_target()
    pos = new Vec2(desired_pos.x, desired_pos.y)
    follow_pos = new Vec2(pos.x, pos.y)
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
  follow_pos = new Vec2(_x, _y)
  desired_pos = new Vec2(_x, _y)
  return true
}

move_by = function(_x, _y)  {
  set_mode(CAM_MODE.MANUAL)
  pos.x += _x
  pos.y += _y
  follow_pos = new Vec2(pos.x, pos.y)
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

reset_look_ahead = function()  {
  look_ahead = new Vec2(0)
  look_ahead_desired = new Vec2(0)
  target_velocity = new Vec2(0)
  look_ahead_ready = false
  look_ahead_target = noone
  if  (mode == CAM_MODE.FOLLOW_OBJECT && instance_exists(object_to_follow))  {
    look_ahead_ready = true
    look_ahead_target = object_to_follow
    look_ahead_previous = new Vec2(object_to_follow.x, object_to_follow.y)
    look_ahead_revision = 0
  }
  if  (mode == CAM_MODE.FOLLOW_GROUP && focus_group.count > 0)  {
    look_ahead_ready = true
    look_ahead_target = focus_group
    look_ahead_previous = new Vec2(focus_group.pos.x, focus_group.pos.y)
    look_ahead_revision = focus_group.revision
  }
  return true
}

set_look_ahead = function(_time_x, _time_y = _time_x, _max_x = 80, _max_y = 50)  {
  var _values = [_time_x, _time_y, _max_x, _max_y]
  for(var i=0; i<array_length(_values); i++)  {
    if  (!is_real(_values[i]))  return false
    if  (is_nan(_values[i]) || is_infinity(_values[i]) || _values[i] < 0)  return false
  }
  look_ahead_time = new Vec2(_time_x, _time_y)
  look_ahead_max = new Vec2(_max_x, _max_y)
  look_ahead.x = clamp(look_ahead.x, -_max_x, _max_x)
  look_ahead.y = clamp(look_ahead.y, -_max_y, _max_y)
  return set_look_ahead_enabled(true)
}

set_look_ahead_smoothing = function(_x, _y = _x)  {
  if  (!is_real(_x) || !is_real(_y))  return false
  if  (is_nan(_x) || is_nan(_y) || is_infinity(_x) || is_infinity(_y))  return false
  look_ahead_spd = new Vec2(clamp(_x, 0, 1), clamp(_y, 0, 1))
  return true
}

set_look_ahead_enabled = function(_enabled = true)  {
  if  (look_ahead_enabled != _enabled)  reset_look_ahead()
  look_ahead_enabled = _enabled
  return true
}

set_teleport_distance = function(_distance)  {
  if  (!is_real(_distance))  return false
  if  (is_nan(_distance) || is_infinity(_distance) || _distance <= 0)  return false
  teleport_distance = _distance
  return true
}

update_look_ahead = function(_seconds)  {
  if  (!look_ahead_enabled || !is_following())  {
    reset_look_ahead()
    return undefined
  }
  var _target = mode == CAM_MODE.FOLLOW_GROUP ? focus_group : object_to_follow
  var _revision = mode == CAM_MODE.FOLLOW_GROUP ? focus_group.revision : 0
  if  (!look_ahead_ready || look_ahead_target != _target || look_ahead_revision != _revision)  {
    reset_look_ahead()
    return undefined
  }
  var _distance = new Vec2(follow_target_pos.x - look_ahead_previous.x, follow_target_pos.y - look_ahead_previous.y)
  look_ahead_previous = new Vec2(follow_target_pos.x, follow_target_pos.y)
  if  (_seconds <= 0)  {
    target_velocity = new Vec2(0)
    return undefined
  }
  if  (point_distance(0, 0, _distance.x, _distance.y) > teleport_distance)  {
    reset_look_ahead()
    return undefined
  }
  target_velocity = new Vec2(_distance.x / _seconds, _distance.y / _seconds)
  look_ahead_desired = new Vec2(
    clamp(target_velocity.x * look_ahead_time.x, -look_ahead_max.x, look_ahead_max.x),
    clamp(target_velocity.y * look_ahead_time.y, -look_ahead_max.y, look_ahead_max.y)
  )
  look_ahead.x = lerp(look_ahead.x, look_ahead_desired.x, smoothing_factor(look_ahead_spd.x, _seconds))
  look_ahead.y = lerp(look_ahead.y, look_ahead_desired.y, smoothing_factor(look_ahead_spd.y, _seconds))
}

get_dead_zone = function()  {
  var _size = new Vec2(min(dead_zone_size.x, size_zoom.x), min(dead_zone_size.y, size_zoom.y))
  return {
    pos: new Vec2(pos.x - target_offset.x - _size.x * .5, pos.y - target_offset.y - _size.y * .5),
    size: _size
  }
}

apply_dead_zone = function()  {
  if  (!dead_zone_enabled || !is_following())  return undefined
  var _half = new Vec2(min(dead_zone_size.x, size_zoom.x) * .5, min(dead_zone_size.y, size_zoom.y) * .5)
  var _distance = new Vec2(desired_pos.x - follow_pos.x, desired_pos.y - follow_pos.y)
  desired_pos.x -= clamp(_distance.x, -_half.x, _half.x)
  desired_pos.y -= clamp(_distance.y, -_half.y, _half.y)
}

update_zoom = function(_seconds = delta_time / 1000000)  {
  var _factor = smoothing_factor(zoom_spd, _seconds)
  zoom_percent = lerp(zoom_percent, new_zoom_percent, _factor)
  zoom_percent = clamp(zoom_percent, -1, 1)
  var _scale = 1 - zoom_range * zoom_percent
  manual_view_size = new Vec2(size.x * _scale, size.y * _scale)
  size_zoom = new Vec2(manual_view_size.x, manual_view_size.y)
  if  (!is_undefined(group_view_height))  {
    if  (mode != CAM_MODE.FOLLOW_GROUP || !group_framing_enabled || focus_group.count == 0)  {
      group_view_height = lerp(group_view_height, manual_view_size.y, _factor)
      if  (abs(group_view_height - manual_view_size.y) < .01)  group_view_height = undefined
    }
    if  (!is_undefined(group_view_height))  size_zoom = new Vec2(group_view_height * size.x / size.y, group_view_height)
  }
}

apply_group_framing = function(_seconds)  {
  group_max_reached = false
  if  (mode != CAM_MODE.FOLLOW_GROUP || !group_framing_enabled || focus_group.count == 0)  return undefined
  var _bounds = focus_group.bounds
  var _max_x = _bounds.pos.x + _bounds.size.x
  var _max_y = _bounds.pos.y + _bounds.size.y
  var _width = 2 * (max(abs(_bounds.pos.x - pos.x), abs(_max_x - pos.x)) + group_margin.x)
  var _height = 2 * (max(abs(_bounds.pos.y - pos.y), abs(_max_y - pos.y)) + group_margin.y)
  var _target = max(_height, _width * size.y / size.x, manual_view_size.y, size.y * group_min_scale)
  if  (group_max_scale > 0)  {
    var _limit = size.y * group_max_scale
    group_max_reached = _target > _limit
    _target = min(_target, _limit)
  }
  if  (is_undefined(group_view_height))  group_view_height = size_zoom.y
  // Afasta imediatamente para preservar os pontos e aproxima pela suavizacao do zoom
  group_view_height = max(_target, lerp(group_view_height, _target, smoothing_factor(zoom_spd, _seconds)))
  if  (group_max_scale > 0)  group_view_height = min(group_view_height, size.y * group_max_scale)
  size_zoom = new Vec2(group_view_height * size.x / size.y, group_view_height)
}

update_group_visibility = function()  {
  group_fits = false
  if  (mode != CAM_MODE.FOLLOW_GROUP || focus_group.count == 0)  return undefined
  var _bounds = focus_group.bounds
  var _left = pos.x - size_zoom.x * .5
  var _top = pos.y - size_zoom.y * .5
  group_fits = _bounds.pos.x - group_margin.x >= _left - .001
    && _bounds.pos.y - group_margin.y >= _top - .001
    && _bounds.pos.x + _bounds.size.x + group_margin.x <= _left + size_zoom.x + .001
    && _bounds.pos.y + _bounds.size.y + group_margin.y <= _top + size_zoom.y + .001
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
    case CAM_MODE.FOLLOW_GROUP:
      if  (!focus_group.update())  {
        set_mode(CAM_MODE.FIXED)
        return false
      }
      follow_target_pos = new Vec2(focus_group.pos.x, focus_group.pos.y)
      desired_pos = new Vec2(follow_target_pos.x + target_offset.x, follow_target_pos.y + target_offset.y)
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

update_position = function(_seconds = delta_time / 1000000)  {
  if  (!update_target())  return undefined
  update_look_ahead(_seconds)
  apply_dead_zone()
  limit_position(desired_pos)
  var _factor_x = smoothing_factor(spd.x, _seconds)
  var _factor_y = smoothing_factor(spd.y, _seconds)
  if  (is_following())  {
    // A dead zone controla o acompanhamento, sem absorver a antecipacao
    follow_pos.x = lerp(follow_pos.x, desired_pos.x, _factor_x)
    follow_pos.y = lerp(follow_pos.y, desired_pos.y, _factor_y)
    limit_position(follow_pos)
    desired_pos.x += look_ahead.x
    desired_pos.y += look_ahead.y
    limit_position(desired_pos)
    pos = new Vec2(follow_pos.x + look_ahead.x, follow_pos.y + look_ahead.y)
  }else{
    pos.x = lerp(pos.x, desired_pos.x, _factor_x)
    pos.y = lerp(pos.y, desired_pos.y, _factor_y)
  }
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
  var _center = new Vec2(pos.x + shake.offset.x, pos.y + shake.offset.y)
  var _half = new Vec2(size_zoom.x * .5, size_zoom.y * .5)
  if  (mode == CAM_MODE.FOLLOW_GROUP && group_framing_enabled && group_fits && (shake.offset.x != 0 || shake.offset.y != 0))  {
    var _bounds = focus_group.bounds
    _center.x = clamp(_center.x, _bounds.pos.x + _bounds.size.x - _half.x, _bounds.pos.x + _half.x)
    _center.y = clamp(_center.y, _bounds.pos.y + _bounds.size.y - _half.y, _bounds.pos.y + _half.y)
  }
  limit_position(_center)
  render_pos = new Vec2(_center.x - _half.x, _center.y - _half.y)
  camera_set_view_size(cam, size_zoom.x, size_zoom.y)
  camera_set_view_pos(cam, render_pos.x, render_pos.y)
}

update_camera = function()  {
  var _seconds = max(0, delta_time / 1000000)
  update_zoom(_seconds)
  update_position(_seconds)
  apply_group_framing(_seconds)
  limit_position()
  if  (!is_following())  follow_pos = new Vec2(pos.x, pos.y)
  update_group_visibility()
  shake.update(_seconds)
  apply_camera()
}
