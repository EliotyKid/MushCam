main_view = 0
debug_enabled = true
debug_panel = undefined
cameras = {}
viewports = []
screen_size = new Vec2(640, 360)
window_set_size(1024,576)

enum LAYOUT {
  SINGLE,
  SPLIT_VERTICAL,
  SPLIT_HORIZONTAL,
  GRID,
  LENGHT
}

current_layout = LAYOUT.SINGLE
split = false
view_enabled = true
layout_duration = .3
layout_transition = false
layout_progress = 0
layout_axis = LAYOUT.SPLIT_VERTICAL
layout_start = 0
layout_target = 0
layout_division = 0
layout_views = []

find_viewport_index = function(_id) {
  for(var i=0; i<array_length(viewports); i++){
    if  (viewports[i].id == _id)  return i
  }
  return -1
}

get_camera = function(_name)  {
  if  (!is_string(_name) || !variable_struct_exists(cameras, _name))  return undefined
  return cameras[$ _name]
}

update_camera_selection = function()  {
  var _available = []
  var _names = variable_struct_get_names(cameras)
  for(var i=0; i<array_length(_names); i++)  {
    var _data = get_camera(_names[i])
    if  (instance_exists(_data.obj))  array_push(_available, _names[i])
  }
  var _layout_changed = false
  var _changed = false
  for(var i=0; i<array_length(viewports); i++)  {
    var _vp = viewports[i]
    var _selected = _vp.selector.select(_available, _vp.camera_name)
    if  (_selected == _vp.camera_name)  continue
    if  ((_selected == "") != (_vp.camera_name == ""))  _layout_changed = true
    _vp.camera_name = _selected
    var _data = get_camera(_selected)
    view_set_camera(_vp.id, is_undefined(_data) ? -1 : _data.cam)
    _changed = true
  }
  if  (_layout_changed)  {
    set_layout(current_layout, false)
  }else if  (_changed)  {
    fit_visible_cameras()
  }
  return _changed
}

viewport_add_camera = function(_id, _name, _priority = 0, _enabled = true)  {
  var _index = find_viewport_index(_id)
  var _data = get_camera(_name)
  if  (_index == -1 || is_undefined(_data) || !instance_exists(_data.obj))  return false
  if  (!viewports[_index].selector.add(_name, _priority, _enabled))  return false
  update_camera_selection()
  return true
}

viewport_remove_camera = function(_id, _name)  {
  var _index = find_viewport_index(_id)
  if  (_index == -1 || !viewports[_index].selector.remove(_name))  return false
  update_camera_selection()
  return true
}

viewport_set_camera_priority = function(_id, _name, _priority)  {
  var _index = find_viewport_index(_id)
  if  (_index == -1 || !viewports[_index].selector.set_priority(_name, _priority))  return false
  update_camera_selection()
  return true
}

viewport_set_camera_enabled = function(_id, _name, _enabled = true)  {
  var _index = find_viewport_index(_id)
  if  (_index == -1 || !viewports[_index].selector.set_enabled(_name, _enabled))  return false
  update_camera_selection()
  return true
}

create_camera = function(_name, _size = screen_size)  {
  if  (!is_string(_name) || _name == "" || !is_undefined(get_camera(_name)))  return false
  if  (_size.x <=0 || _size.y <=0)  return  false
  var _cam = camera_create_view(0,0,_size.x, _size.y)
  var _obj = instance_create_depth(0,0,-9999, obj_camera, {cam: _cam})
  var _data = {
    name: _name,
    obj: _obj,
    cam: _cam,
    size: new Vec2(_size.x, _size.y)
  }
  cameras[$ _name] = _data
  return _data
}

fit_camera = function(_viewport) {
  if  (_viewport.size.x <= 0 || _viewport.size.y <= 0)  return undefined
  var _data = get_camera(_viewport.camera_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return undefined
  return _data.obj.set_viewport_size(_viewport.size, _data.size.y)
}

apply_viewport = function(_vp)  {
  view_visible[_vp.id] = _vp.size.x > 0 && _vp.size.y > 0
  if  (!view_visible[_vp.id])  return undefined
  view_xport[_vp.id] = _vp.pos.x
  view_yport[_vp.id] = _vp.pos.y
  view_wport[_vp.id] = _vp.size.x
  view_hport[_vp.id] = _vp.size.y
}

fit_visible_cameras = function()  {
  var _fitted = []
  for(var i=0; i<array_length(viewports); i++)  {
    var _vp = viewports[i]
    if  (!view_visible[_vp.id])  continue
    var _already = false
    for(var j=0; j<array_length(_fitted); j++)  {
      if  (_fitted[j] == _vp.camera_name)  _already = true
    }
    if  (!_already)  {
      fit_camera(_vp)
      array_push(_fitted, _vp.camera_name)
    }
  }
}

apply_layout_division = function()  {
  var _main = layout_views[0]
  var _second = layout_views[1]
  var _division = round(layout_division)
  _main.pos = new Vec2(0)
  if  (layout_axis == LAYOUT.SPLIT_VERTICAL)  {
    _main.size = new Vec2(_division, screen_size.y)
    _second.pos = new Vec2(_division, 0)
    _second.size = new Vec2(screen_size.x - _division, screen_size.y)
  }else{
    _main.size = new Vec2(screen_size.x, _division)
    _second.pos = new Vec2(0, _division)
    _second.size = new Vec2(screen_size.x, screen_size.y - _division)
  }
  apply_viewport(_main)
  apply_viewport(_second)
  fit_visible_cameras()
}

update_layout = function()  {
  if  (!layout_transition)  return undefined
  layout_progress = min(1, layout_progress + delta_time / 1000000 / layout_duration)
  var _t = layout_progress * layout_progress * (3 - 2 * layout_progress)
  layout_division = lerp(layout_start, layout_target, _t)
  if  (layout_progress == 1)  {
    layout_division = layout_target
    layout_transition = false
  }
  apply_layout_division()
}

set_layout = function(_layout, _animate = true)  {
  if _layout < 0 || _layout >= LAYOUT.LENGHT return false
  if  (_animate && layout_transition && _layout == current_layout)  return true
  var _previous = current_layout
  var _axis = _layout == LAYOUT.SINGLE ? _previous : _layout
  if  (layout_transition && _layout == LAYOUT.SINGLE)  _axis = layout_axis
  var _pair = []
  var _main_index = find_viewport_index(main_view)
  if  (_main_index != -1)  {
    var _main = viewports[_main_index]
    if  (!_main.overlay && _main.active && !is_undefined(get_camera(_main.camera_name)))  {
      array_push(_pair, _main)
      for(var i=0; i<array_length(viewports); i++)  {
        var _vp = viewports[i]
        if  (_vp.id != main_view && !_vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name)))  {
          array_push(_pair, _vp)
          break
        }
      }
    }
  }
  var _is_split = _axis == LAYOUT.SPLIT_VERTICAL || _axis == LAYOUT.SPLIT_HORIZONTAL
  var _from_single = _previous == LAYOUT.SINGLE && _layout == _axis
  var _to_single = _layout == LAYOUT.SINGLE && (_previous == _axis || layout_transition)
  var _same_axis = !layout_transition || _axis == layout_axis
  if  (_animate && _is_split && _same_axis && (_from_single || _to_single) && array_length(_pair) == 2)  {
    var _extent = _axis == LAYOUT.SPLIT_VERTICAL ? screen_size.x : screen_size.y
    if  (!layout_transition)  {
      layout_division = _previous == LAYOUT.SINGLE ? _extent : floor(_extent / 2)
    }
    layout_axis = _axis
    layout_views = _pair
    layout_start = layout_division
    layout_target = _layout == LAYOUT.SINGLE ? _extent : floor(_extent / 2)
    layout_progress = 0
    layout_transition = true
    current_layout = _layout
    split = _layout != LAYOUT.SINGLE
    for(var i=0; i<array_length(viewports); i++)  {
      var _vp = viewports[i]
      view_visible[_vp.id] = _vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name))
    }
    apply_layout_division()
    return true
  }
  layout_transition = false
  layout_views = []
  var _selected = []
  for(var i=0; i<array_length(viewports); i++)  {
    var _vp = viewports[i]
    if  (!_vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name)))  {
      if  (_layout != LAYOUT.SINGLE || _vp.id == main_view) array_push(_selected, _vp)
    }
  }
  if  ((_layout == LAYOUT.SPLIT_VERTICAL || _layout == LAYOUT.SPLIT_HORIZONTAL) && array_length(_pair) == 2)  _selected = _pair
  
  var _count = min(array_length(_selected), _layout == LAYOUT.SINGLE ? 1 : (_layout == LAYOUT.GRID ? 8 : 2))
  current_layout = _layout
  split = _layout != LAYOUT.SINGLE
  for( var i=0; i< array_length(viewports); i++)  {
    var _vp = viewports[i]
    view_visible[_vp.id] = _vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name))
  }
  
  var _cols = 1
  var _rows = 1
  if  (_layout == LAYOUT.SPLIT_VERTICAL)  _cols = max(1, _count)
  if  (_layout == LAYOUT.SPLIT_HORIZONTAL)  _rows = max(1, _count)
  if  (_layout == LAYOUT.GRID && _count > 0)  {
    _cols = ceil(sqrt(_count))
    _rows = ceil(_count/_cols)
  }
  
  for(var i=0; i<_count; i++) {
    var _vp = _selected[i]
    var _col = i mod _cols
    var _row = i div _cols
    var _x = floor(_col * screen_size.x / _cols)
    var _y = floor(_row * screen_size.y / _rows)
    _vp.pos = new Vec2(_x, _y)
    _vp.size = new Vec2(
      floor((_col+1) * screen_size.x / _cols) - _x,
      floor((_row+1) * screen_size.y / _rows) - _y
    )
    apply_viewport(_vp)
  }
  
  fit_visible_cameras()
  return true
}

create_viewport = function(
  _id, 
  _camera, 
  _pos = new Vec2(0),
  _size = new Vec2(screen_size.x, screen_size.y),
  _active = false,
  _overlay = false
  )  {
  if  (_id < 0 || _id > 7 || _id != floor(_id) || find_viewport_index(_id) != -1)  return false
  if  (_size.x <= 0 || _size.y <= 0)  return false
  var _data = get_camera(_camera)
  if  (is_undefined(_data) || !instance_exists(_data.obj)) return false
  var _vp = {
    id: _id,
    camera_name: _camera,
    selector: new CameraSelector(),
    pos: new Vec2(_pos.x, _pos.y),
    size: new Vec2(_size.x, _size.y),
    active: _active,
    overlay: _overlay
  }
  _vp.selector.add(_camera)
  array_push(viewports, _vp)
  view_xport[_id] = _pos.x
  view_yport[_id] = _pos.y
  view_wport[_id] = _size.x
  view_hport[_id] = _size.y
  view_set_camera(_id, _data.cam)
  return set_layout(current_layout, false)
}


viewport_set_active = function(_id, _active = true) {
  var _index = find_viewport_index(_id)
  if  (_index == -1)  return false
  viewports[_index].active = _active
  return set_layout(current_layout, false)
}
activate_viewport = viewport_set_active

set_viewport_camera = function(_id, _name)  {
  var _index = find_viewport_index(_id)
  var _data = get_camera(_name)
  if  (_index == -1 || is_undefined(_data) || !instance_exists(_data.obj)) return false
  viewports[_index].selector.replace(_name)
  viewports[_index].camera_name = _name
  view_set_camera(_id, _data.cam)
  return set_layout(current_layout, false)
}

camera_activate = function (_name)  {
  return set_viewport_camera(main_view, _name)
}

camera_follow = function (_name, _target, _snap = false) {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_follow_target(_target, _snap)
}

camera_follow_group = function(_name, _sources, _snap = false)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_follow_group(_sources, _snap)
}

camera_add_group_target = function(_name, _source)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.add_group_target(_source)
}

camera_remove_group_target = function(_name, _index)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.remove_group_target(_index)
}

camera_set_group_point = function(_name, _index, _x, _y)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.focus_group.set_point(_index, _x, _y)
}

camera_clear_group = function(_name)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.clear_group()
}

camera_set_group_framing = function(_name, _margin_x, _margin_y = _margin_x, _min_scale = .5, _max_scale = 0)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_group_framing(_margin_x, _margin_y, _min_scale, _max_scale)
}

camera_set_group_framing_enabled = function(_name, _enabled = true)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_group_framing_enabled(_enabled)
}

camera_set_mode = function(_name, _mode)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_mode(_mode)
}

camera_move_to = function(_name, _x, _y)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.move_to(_x, _y)
}

camera_set_position = function(_name, _x, _y)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_position(_x, _y)
}

camera_move = function(_name, _x, _y)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.move_by(_x, _y)
}

camera_stop = function(_name)  {
  return camera_set_mode(_name, CAM_MODE.FIXED)
}

camera_set_offset = function(_name, _x, _y)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_target_offset(_x, _y)
}

camera_set_zoom = function(_name, _percent)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_zoom_percent(_percent)
}

camera_adjust_zoom = function(_name, _amount)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.adjust_zoom(_amount)
}

camera_set_smoothing = function(_name, _x, _y = _x, _zoom = undefined)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_smoothing(_x, _y, _zoom)
}

camera_set_zoom_settings = function(_name, _range, _input_spd = undefined)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_zoom_settings(_range, _input_spd)
}

camera_set_bounds = function(_name, _x, _y, _width, _height)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_bounds(_x, _y, _width, _height)
}

camera_use_room_bounds = function(_name)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.use_room_bounds()
}

camera_set_limits_enabled = function(_name, _enabled = true)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_limits_enabled(_enabled)
}

camera_set_dead_zone = function(_name, _width, _height, _enabled = true)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_dead_zone(_width, _height, _enabled)
}

camera_set_dead_zone_enabled = function(_name, _enabled = true)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_dead_zone_enabled(_enabled)
}

camera_set_look_ahead = function(_name, _time_x, _time_y = _time_x, _max_x = 80, _max_y = 50)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_look_ahead(_time_x, _time_y, _max_x, _max_y)
}

camera_set_look_ahead_smoothing = function(_name, _x, _y = _x)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_look_ahead_smoothing(_x, _y)
}

camera_set_look_ahead_enabled = function(_name, _enabled = true)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_look_ahead_enabled(_enabled)
}

camera_set_teleport_distance = function(_name, _distance)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.set_teleport_distance(_distance)
}

camera_reset_look_ahead = function(_name)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.reset_look_ahead()
}

camera_shake = function(_name, _x = 8, _y = _x, _duration = .35, _frequency = 25, _falloff = 2)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.shake.start(_x, _y, _duration, _frequency, _falloff)
}

camera_stop_shake = function(_name)  {
  var _data = get_camera(_name)
  if  (is_undefined(_data) || !instance_exists(_data.obj))  return false
  return _data.obj.shake.stop()
}

destroy_viewport = function (_id) {
  var _index = find_viewport_index(_id)
  if  (_index == -1)  return false
  view_visible[_id] = false
  view_set_camera(_id, -1)
  array_delete(viewports, _index, 1)
  return set_layout(current_layout, false)
}

destroy_camera = function (_name) {
  var _data = get_camera(_name)
  if  (is_undefined(_data))  return false
  for(var i=0; i<array_length(viewports); i++)  {
    var _vp = viewports[i]
    _vp.selector.remove(_name)
  }
  variable_struct_remove(cameras, _name)
  update_camera_selection()
  if  (instance_exists(_data.obj)) instance_destroy(_data.obj)
  camera_destroy(_data.cam)
  return true
}

set_screen_size = function (_width, _heigth)  {
  if  (_width < 3 || _heigth < 3)  return false
  screen_size = new Vec2(floor(_width), floor(_heigth))
  return set_layout(current_layout, false)
}

create_camera("main", new Vec2(screen_size.x*.5, screen_size.y))
create_camera("player2", new Vec2(screen_size.x*.5, screen_size.y))
create_camera("minimap", new Vec2(screen_size.x, screen_size.y))
create_viewport(0, "main", new Vec2(0), new Vec2(screen_size.x*.5, screen_size.y), true)
create_viewport(1, "player2", new Vec2(screen_size.x*.5, 0), new Vec2(screen_size.x*.5, screen_size.y), true)
var _s = new Vec2(screen_size.x / 3, screen_size.y / 3)
create_viewport(2, "minimap", new Vec2(screen_size.x*.5 - _s.x * 0.5, 10), _s, true, true)

if  (debug_enabled)  debug_panel = new CameraDebug(id)
