function CameraFocusGroup() constructor {
  sources = []
  pos = new Vec2(0)
  bounds = undefined
  count = 0
  revision = 0
  active_key = ""

  valid_point = function(_x, _y)  {
    if  (!is_numeric(_x) || !is_numeric(_y))  return false
    return !is_nan(_x) && !is_nan(_y) && !is_infinity(_x) && !is_infinity(_y)
  }

  create_source = function(_source)  {
    var _target = _source
    if  (is_struct(_source))  {
      if  (variable_struct_exists(_source, "instance"))  {
        _target = _source.instance
      }else{
        if  (!variable_struct_exists(_source, "x") || !variable_struct_exists(_source, "y"))  return undefined
        if  (!valid_point(_source.x, _source.y))  return undefined
        return {target: noone, point: new Vec2(_source.x, _source.y)}
      }
    }
    if  (is_string(_target) || is_array(_target) || is_undefined(_target))  return undefined
    if  (_target == noone)  return undefined
    if  (object_exists(_target))  _target = instance_find(_target, 0)
    if  (!instance_exists(_target))  return undefined
    return {target: _target, point: undefined}
  }

  set_sources = function(_sources)  {
    if  (!is_array(_sources))  return false
    var _entries = []
    for(var i=0; i<array_length(_sources); i++)  {
      var _entry = create_source(_sources[i])
      if  (is_undefined(_entry))  return false
      array_push(_entries, _entry)
    }
    sources = _entries
    revision++
    return true
  }

  add_source = function(_source)  {
    var _entry = create_source(_source)
    if  (is_undefined(_entry))  return false
    array_push(sources, _entry)
    revision++
    return true
  }

  remove_source = function(_index)  {
    if  (!is_numeric(_index))  return false
    if  (_index < 0 || _index >= array_length(sources) || _index != floor(_index))  return false
    array_delete(sources, _index, 1)
    revision++
    return true
  }

  set_point = function(_index, _x, _y)  {
    if  (!is_numeric(_index))  return false
    if  (_index < 0 || _index >= array_length(sources) || _index != floor(_index))  return false
    if  (is_undefined(sources[_index].point) || !valid_point(_x, _y))  return false
    sources[_index].point = new Vec2(_x, _y)
    return true
  }

  clear = function()  {
    sources = []
    revision++
    return true
  }

  contains_target = function(_target)  {
    for(var i=0; i<array_length(sources); i++)  {
      if  (sources[i].target == _target)  return true
    }
    return false
  }

  update = function()  {
    var _min = new Vec2(0)
    var _max = new Vec2(0)
    var _key = ""
    count = 0
    for(var i=0; i<array_length(sources); i++)  {
      var _entry = sources[i]
      var _point = _entry.point
      if  (is_undefined(_point))  {
        if  (!instance_exists(_entry.target))  continue
        _point = new Vec2(variable_instance_get(_entry.target, "x"), variable_instance_get(_entry.target, "y"))
      }
      if  (!valid_point(_point.x, _point.y))  continue
      if  (count == 0)  {
        _min = new Vec2(_point.x, _point.y)
        _max = new Vec2(_point.x, _point.y)
      }else{
        _min.x = min(_min.x, _point.x)
        _min.y = min(_min.y, _point.y)
        _max.x = max(_max.x, _point.x)
        _max.y = max(_max.y, _point.y)
      }
      _key += string(i) + ","
      count++
    }
    if  (_key != active_key)  revision++
    active_key = _key
    if  (count == 0)  {
      bounds = undefined
      return false
    }
    pos = new Vec2((_min.x + _max.x) * .5, (_min.y + _max.y) * .5)
    bounds = {pos: _min, size: new Vec2(_max.x - _min.x, _max.y - _min.y)}
    return true
  }
}
