function CameraSelector() constructor {
  candidates = []

  find = function(_name)  {
    for(var i=0; i<array_length(candidates); i++)  {
      if  (candidates[i].name == _name)  return i
    }
    return -1
  }

  valid_priority = function(_priority)  {
    return is_numeric(_priority) && !is_nan(_priority) && !is_infinity(_priority)
  }

  add = function(_name, _priority = 0, _enabled = true)  {
    if  (!is_string(_name) || _name == "" || !valid_priority(_priority))  return false
    var _index = find(_name)
    if  (_index != -1)  {
      candidates[_index].priority = _priority
      candidates[_index].enabled = _enabled
    }else{
      array_push(candidates, {name: _name, priority: _priority, enabled: _enabled})
    }
    return true
  }

  remove = function(_name)  {
    var _index = find(_name)
    if  (_index == -1)  return false
    array_delete(candidates, _index, 1)
    return true
  }

  replace = function(_name)  {
    if  (!is_string(_name) || _name == "")  return false
    candidates = []
    return add(_name)
  }

  set_priority = function(_name, _priority)  {
    var _index = find(_name)
    if  (_index == -1 || !valid_priority(_priority))  return false
    candidates[_index].priority = _priority
    return true
  }

  set_enabled = function(_name, _enabled = true)  {
    var _index = find(_name)
    if  (_index == -1)  return false
    candidates[_index].enabled = _enabled
    return true
  }

  select = function(_available, _current = "")  {
    var _selected = ""
    var _priority = 0
    for(var i=0; i<array_length(candidates); i++)  {
      var _candidate = candidates[i]
      if  (!_candidate.enabled)  continue
      var _exists = false
      for(var j=0; j<array_length(_available); j++)  {
        if  (_available[j] == _candidate.name)  {
          _exists = true
          break
        }
      }
      if  (!_exists)  continue
      if  (_selected == "" || _candidate.priority > _priority || (_candidate.priority == _priority && _candidate.name == _current))  {
        _selected = _candidate.name
        _priority = _candidate.priority
      }
    }
    return _selected
  }
}
