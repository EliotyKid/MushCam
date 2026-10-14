function CameraShake() constructor {
  active = false
  amplitude = new Vec2(8)
  duration = .35
  frequency = 25
  falloff = 2
  elapsed = 0
  progress = 0
  sequence = 0
  offset = new Vec2(0)

  start = function(_x = 8, _y = _x, _duration = .35, _frequency = 25, _falloff = 2)  {
    var _values = [_x, _y, _duration, _frequency, _falloff]
    for(var i=0; i<array_length(_values); i++)  {
      if  (!is_numeric(_values[i]))  return false
      if  (is_nan(_values[i]) || is_infinity(_values[i]) || _values[i] < 0)  return false
    }
    if  (_duration <= 0 || _frequency <= 0)  return false
    if  (is_infinity(_duration * _frequency * 12.9898))  return false
    amplitude = new Vec2(_x, _y)
    duration = _duration
    frequency = _frequency
    falloff = _falloff
    elapsed = 0
    progress = 0
    sequence++
    offset = new Vec2(0)
    active = _x > 0 || _y > 0
    return true
  }

  stop = function()  {
    active = false
    elapsed = duration
    progress = 1
    offset = new Vec2(0)
    return true
  }

  sample = function(_index, _axis)  {
    // Ruido local: nao altera a sequencia aleatoria do jogo
    var _value = sin((_index + sequence * 131 + _axis * 47) * 12.9898) * 43758.5453
    return (_value - floor(_value)) * 2 - 1
  }

  update = function(_seconds)  {
    if  (!active || _seconds <= 0)  return undefined
    elapsed = min(duration, elapsed + _seconds)
    progress = min(1, elapsed / duration)
    if  (duration - elapsed <= .000000001)  {
      stop()
      return undefined
    }
    var _phase = elapsed * frequency
    var _index = floor(_phase)
    var _t = _phase - _index
    var _blend = _t * _t * (3 - 2 * _t)
    var _strength = falloff == 0 ? 1 : power(1 - progress, falloff)
    offset = new Vec2(
      lerp(sample(_index, 0), sample(_index + 1, 0), _blend) * amplitude.x * _strength,
      lerp(sample(_index, 1), sample(_index + 1, 1), _blend) * amplitude.y * _strength
    )
  }
}
