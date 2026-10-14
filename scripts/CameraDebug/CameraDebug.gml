function CameraDebug(_manager) constructor {
  manager = _manager
  camera_name = "main"
  camera_width = 320
  camera_height = 380
  point_x = 600
  point_y = 300
  delta_x = 32
  delta_y = 0
  follow_target = instance_find(obj_player, 0)
  snap = false
  selected_mode = CAM_MODE.FIXED
  selected_layout = LAYOUT.SINGLE
  offset_x = 0
  offset_y = 0
  zoom_percent = 0
  zoom_range = .5
  zoom_spd = .05
  move_spd_x = .1
  move_spd_y = .1
  zoom_input_spd = 3
  zoom_step = .1
  original_fps = game_get_speed(gamespeed_fps)
  selected_fps = original_fps
  current_fps = original_fps
  frame_ms = 0
  fps_changed = false
  arrival_distance = .5
  can_outside_room = true
  bounds_x = 0
  bounds_y = 0
  bounds_width = room_width
  bounds_height = room_height
  camera_bounds = undefined
  camera_limits_enabled = false
  camera_uses_room = true
  dead_zone_width = 120
  dead_zone_height = 80
  dead_zone_enabled = false
  show_dead_zone = true
  camera_dead_zone = undefined
  camera_dead_zone_enabled = false
  look_ahead_enabled = false
  look_ahead_time_x = .25
  look_ahead_time_y = .25
  look_ahead_max_x = 80
  look_ahead_max_y = 50
  look_ahead_spd_x = .1
  look_ahead_spd_y = .1
  teleport_distance = 256
  camera_look_ahead = new Vec2(0)
  camera_look_ahead_desired = new Vec2(0)
  camera_target_velocity = new Vec2(0)
  camera_look_ahead_enabled = false
  group_index = 0
  group_margin_x = 32
  group_margin_y = 32
  group_min_scale = .5
  group_max_scale = 0
  group_framing_enabled = true
  camera_group_sources = []
  camera_group_count = 0
  camera_group_center = undefined
  camera_group_bounds = undefined
  camera_group_fits = false
  camera_group_max_reached = false
  shake_amplitude_x = 8
  shake_amplitude_y = 8
  shake_duration = .35
  shake_frequency = 25
  shake_falloff = 2
  camera_shake_active = false
  camera_shake_progress = 0
  camera_shake_offset = new Vec2(0)
  camera_shake_applied = new Vec2(0)
  screen_width = 640
  screen_height = 380
  viewport_id = 0
  viewport_x = 0
  viewport_y = 0
  viewport_width = 320
  viewport_height = 380
  viewport_active = true
  viewport_overlay = false
  candidate_priority = 10
  candidate_enabled = true
  viewport_camera = ""
  viewport_candidates = []
  candidate_registered = false
  candidate_current_priority = undefined
  candidate_current_enabled = false
  priority_test_name = ""
  priority_test_active = false
  priority_test_camera = ""
  priority_test_binding = false
  priority_test_visible = false
  temporary_target = noone
  last_action = "Pronto"
  last_result = true
  camera_exists = false
  camera_names = []
  camera_pos = new Vec2(0)
  camera_follow_center = new Vec2(0)
  camera_desired_pos = new Vec2(0)
  camera_render_pos = new Vec2(0)
  camera_size = new Vec2(0)
  camera_size_zoom = new Vec2(0)
  camera_offset = new Vec2(0)
  camera_mode = CAM_MODE.FIXED
  camera_target = noone
  camera_target_pos = new Vec2(0)
  camera_follow_pos = new Vec2(0)
  camera_zoom = 0
  camera_zoom_target = 0
  camera_smoothing = new Vec2(.1)
  camera_zoom_smoothing = .05
  current_layout = LAYOUT.SINGLE
  layout_transition = false
  layout_progress = 0
  viewport_index = -1
  viewport_data = undefined
  debug_view = undefined

  report = function(_action, _result)  {
    last_action = _action
    last_result = _result
  }

  get_selected = function()  {
    var _data = manager.get_camera(camera_name)
    if  (is_undefined(_data) || !instance_exists(_data.obj))  return undefined
    return _data
  }

  update = function()  {
    current_fps = game_get_speed(gamespeed_fps)
    frame_ms = delta_time / 1000
    camera_names = variable_struct_get_names(manager.cameras)
    current_layout = manager.current_layout
    layout_transition = manager.layout_transition
    layout_progress = manager.layout_progress
    viewport_index = manager.find_viewport_index(viewport_id)
    viewport_data = viewport_index == -1 ? undefined : manager.viewports[viewport_index]
    viewport_camera = is_undefined(viewport_data) ? "" : viewport_data.camera_name
    viewport_candidates = is_undefined(viewport_data) ? [] : viewport_data.selector.candidates
    var _candidate_index = is_undefined(viewport_data) ? -1 : viewport_data.selector.find(camera_name)
    candidate_registered = _candidate_index != -1
    candidate_current_priority = candidate_registered ? viewport_candidates[_candidate_index].priority : undefined
    candidate_current_enabled = candidate_registered && viewport_candidates[_candidate_index].enabled
    var _test_index = manager.find_viewport_index(manager.main_view)
    priority_test_camera = _test_index == -1 ? "" : manager.viewports[_test_index].camera_name
    priority_test_active = priority_test_name != "" && priority_test_camera == priority_test_name
    var _test_data = manager.get_camera(priority_test_camera)
    priority_test_binding = _test_index != -1 && !is_undefined(_test_data) && view_get_camera(manager.main_view) == _test_data.cam
    priority_test_visible = _test_index != -1 && view_visible[manager.main_view]
    var _data = get_selected()
    camera_exists = !is_undefined(_data)
    if  (!camera_exists)  {
      camera_pos = undefined
      camera_follow_center = undefined
      camera_desired_pos = undefined
      camera_render_pos = undefined
      camera_size = undefined
      camera_size_zoom = undefined
      camera_offset = undefined
      camera_mode = -1
      camera_target = noone
      camera_target_pos = undefined
      camera_follow_pos = undefined
      camera_zoom = undefined
      camera_zoom_target = undefined
      camera_smoothing = undefined
      camera_zoom_smoothing = undefined
      camera_bounds = undefined
      camera_limits_enabled = false
      camera_uses_room = false
      camera_dead_zone = undefined
      camera_dead_zone_enabled = false
      camera_look_ahead = undefined
      camera_look_ahead_desired = undefined
      camera_target_velocity = undefined
      camera_look_ahead_enabled = false
      camera_group_sources = []
      camera_group_count = 0
      camera_group_center = undefined
      camera_group_bounds = undefined
      camera_group_fits = false
      camera_group_max_reached = false
      camera_shake_active = false
      camera_shake_progress = 0
      camera_shake_offset = undefined
      camera_shake_applied = undefined
      return undefined
    }
    var _obj = _data.obj
    camera_pos = new Vec2(_obj.pos.x, _obj.pos.y)
    camera_follow_center = new Vec2(_obj.follow_pos.x, _obj.follow_pos.y)
    camera_desired_pos = new Vec2(_obj.desired_pos.x, _obj.desired_pos.y)
    camera_render_pos = new Vec2(_obj.render_pos.x, _obj.render_pos.y)
    camera_size = new Vec2(_obj.size.x, _obj.size.y)
    camera_size_zoom = new Vec2(_obj.size_zoom.x, _obj.size_zoom.y)
    camera_offset = new Vec2(_obj.target_offset.x, _obj.target_offset.y)
    camera_mode = _obj.mode
    camera_target = _obj.object_to_follow
    camera_target_pos = new Vec2(_obj.to_target_pos.x, _obj.to_target_pos.y)
    camera_follow_pos = new Vec2(_obj.follow_target_pos.x, _obj.follow_target_pos.y)
    camera_zoom = _obj.zoom_percent
    camera_zoom_target = _obj.new_zoom_percent
    camera_smoothing = new Vec2(_obj.spd.x, _obj.spd.y)
    camera_zoom_smoothing = _obj.zoom_spd
    camera_bounds = _obj.get_bounds()
    camera_limits_enabled = !_obj.can_outside_room
    camera_uses_room = is_undefined(_obj.bounds)
    camera_dead_zone = _obj.get_dead_zone()
    camera_dead_zone_enabled = _obj.dead_zone_enabled
    camera_look_ahead = new Vec2(_obj.look_ahead.x, _obj.look_ahead.y)
    camera_look_ahead_desired = new Vec2(_obj.look_ahead_desired.x, _obj.look_ahead_desired.y)
    camera_target_velocity = new Vec2(_obj.target_velocity.x, _obj.target_velocity.y)
    camera_look_ahead_enabled = _obj.look_ahead_enabled
    camera_group_sources = _obj.focus_group.sources
    camera_group_count = _obj.focus_group.count
    camera_group_center = new Vec2(_obj.focus_group.pos.x, _obj.focus_group.pos.y)
    camera_group_bounds = _obj.focus_group.bounds
    camera_group_fits = _obj.group_fits
    camera_group_max_reached = _obj.group_max_reached
    camera_shake_active = _obj.shake.active
    camera_shake_progress = _obj.shake.progress
    camera_shake_offset = new Vec2(_obj.shake.offset.x, _obj.shake.offset.y)
    camera_shake_applied = new Vec2(
      _obj.render_pos.x + _obj.size_zoom.x * .5 - _obj.pos.x,
      _obj.render_pos.y + _obj.size_zoom.y * .5 - _obj.pos.y
    )
  }

  load_camera = function()  {
    var _data = get_selected()
    report("get_camera", !is_undefined(_data))
    if  (is_undefined(_data))  return undefined
    var _obj = _data.obj
    camera_width = _data.size.x
    camera_height = _data.size.y
    point_x = _obj.pos.x
    point_y = _obj.pos.y
    offset_x = _obj.target_offset.x
    offset_y = _obj.target_offset.y
    selected_mode = _obj.mode
    zoom_percent = _obj.new_zoom_percent
    zoom_range = _obj.zoom_range
    zoom_spd = _obj.zoom_spd
    move_spd_x = _obj.spd.x
    move_spd_y = _obj.spd.y
    zoom_input_spd = _obj.zoom_input_spd
    arrival_distance = _obj.arrival_distance
    can_outside_room = _obj.can_outside_room
    dead_zone_width = _obj.dead_zone_size.x
    dead_zone_height = _obj.dead_zone_size.y
    dead_zone_enabled = _obj.dead_zone_enabled
    look_ahead_enabled = _obj.look_ahead_enabled
    look_ahead_time_x = _obj.look_ahead_time.x
    look_ahead_time_y = _obj.look_ahead_time.y
    look_ahead_max_x = _obj.look_ahead_max.x
    look_ahead_max_y = _obj.look_ahead_max.y
    look_ahead_spd_x = _obj.look_ahead_spd.x
    look_ahead_spd_y = _obj.look_ahead_spd.y
    teleport_distance = _obj.teleport_distance
    group_margin_x = _obj.group_margin.x
    group_margin_y = _obj.group_margin.y
    group_min_scale = _obj.group_min_scale
    group_max_scale = _obj.group_max_scale
    group_framing_enabled = _obj.group_framing_enabled
    shake_amplitude_x = _obj.shake.amplitude.x
    shake_amplitude_y = _obj.shake.amplitude.y
    shake_duration = _obj.shake.duration
    shake_frequency = _obj.shake.frequency
    shake_falloff = _obj.shake.falloff
    var _bounds = _obj.get_bounds()
    bounds_x = _bounds.pos.x
    bounds_y = _bounds.pos.y
    bounds_width = _bounds.size.x
    bounds_height = _bounds.size.y
    if  (instance_exists(_obj.object_to_follow))  follow_target = _obj.object_to_follow
    update()
  }

  apply_settings = function()  {
    var _data = get_selected()
    report("Ajustes", !is_undefined(_data))
    if  (is_undefined(_data))  return undefined
    manager.camera_set_zoom_settings(camera_name, zoom_range, zoom_input_spd)
    manager.camera_set_smoothing(camera_name, move_spd_x, move_spd_y, zoom_spd)
    _data.obj.arrival_distance = max(0, arrival_distance)
    manager.camera_set_limits_enabled(camera_name, !can_outside_room)
  }

  load_viewport = function()  {
    var _index = manager.find_viewport_index(viewport_id)
    report("find_viewport_index", _index != -1)
    if  (_index == -1)  return undefined
    var _vp = manager.viewports[_index]
    camera_name = _vp.camera_name
    viewport_x = _vp.pos.x
    viewport_y = _vp.pos.y
    viewport_width = _vp.size.x
    viewport_height = _vp.size.y
    viewport_active = _vp.active
    viewport_overlay = _vp.overlay
    update()
  }

  create_target = function()  {
    if  (instance_exists(temporary_target))  instance_destroy(temporary_target)
    temporary_target = instance_create_depth(point_x, point_y, -10099, obj_player)
    follow_target = temporary_target
    report("Criar alvo temporario", instance_exists(temporary_target))
  }

  destroy_target = function()  {
    var _exists = instance_exists(temporary_target)
    if  (_exists)  instance_destroy(temporary_target)
    temporary_target = noone
    report("Destruir alvo temporario", _exists)
  }

  draw = function()  {
    if  (!show_dead_zone)  return undefined
    for(var i=0; i<array_length(manager.viewports); i++)  {
      var _vp = manager.viewports[i]
      if  (_vp.id != view_current || !view_visible[_vp.id])  continue
      var _data = manager.get_camera(_vp.camera_name)
      if  (is_undefined(_data) || !instance_exists(_data.obj))  continue
      if  (!_data.obj.dead_zone_enabled)  continue
      var _zone = _data.obj.get_dead_zone()
      var _color = draw_get_color()
      var _alpha = draw_get_alpha()
      draw_set_color(c_lime)
      draw_set_alpha(1)
      draw_rectangle(_zone.pos.x, _zone.pos.y, _zone.pos.x + _zone.size.x, _zone.pos.y + _zone.size.y, true)
      draw_set_color(_color)
      draw_set_alpha(_alpha)
    }
  }

  load_candidate = function()  {
    update()
    if  (candidate_registered)  {
      candidate_priority = candidate_current_priority
      candidate_enabled = candidate_current_enabled
    }
    report("Carregar candidata selecionada", candidate_registered)
  }

  start_priority_test = function()  {
    var _index = manager.find_viewport_index(manager.main_view)
    if  (_index == -1 || !manager.viewports[_index].active)  {
      report("Teste de prioridade: viewport principal ausente ou desativada", false)
      return undefined
    }
    var _vp = manager.viewports[_index]
    var _base = manager.get_camera(_vp.camera_name)
    if  (is_undefined(_base) || !instance_exists(_base.obj))  {
      report("Teste de prioridade: nenhuma camera base disponivel", false)
      return undefined
    }
    var _priority = 0
    for(var i=0; i<array_length(_vp.selector.candidates); i++)  {
      _priority = max(_priority, _vp.selector.candidates[i].priority)
    }
    _priority += 1
    if  (!_vp.selector.valid_priority(_priority))  {
      report("Teste de prioridade: prioridade fora do intervalo", false)
      return undefined
    }
    var _data = manager.get_camera(priority_test_name)
    if  (!is_undefined(_data) && !instance_exists(_data.obj))  {
      manager.destroy_camera(priority_test_name)
      _data = undefined
    }
    if  (is_undefined(_data))  {
      priority_test_name = "debug_priority"
      var _suffix = 0
      while (!is_undefined(manager.get_camera(priority_test_name)))  {
        _suffix += 1
        priority_test_name = "debug_priority_" + string(_suffix)
      }
      _data = manager.create_camera(priority_test_name, _base.size)
      if  (!is_struct(_data))  {
        priority_test_name = ""
        report("Teste de prioridade: nao foi possivel criar a camera", false)
        return undefined
      }
      manager.camera_set_position(priority_test_name, _base.obj.pos.x + max(160, _base.obj.size_zoom.x * .65), _base.obj.pos.y)
    }
    var _result = manager.viewport_add_camera(manager.main_view, priority_test_name, _priority, true)
    viewport_id = manager.main_view
    camera_name = priority_test_name
    update()
    report("Teste de prioridade: camera de teste assume a tela principal", _result && priority_test_active && priority_test_binding && priority_test_visible)
  }

  stop_priority_test = function()  {
    var _result = priority_test_name != "" && manager.viewport_set_camera_enabled(manager.main_view, priority_test_name, false)
    viewport_id = manager.main_view
    update()
    if  (priority_test_camera != "")  camera_name = priority_test_camera
    report("Teste de prioridade: retorno automatico", _result && !priority_test_active && priority_test_camera != "" && priority_test_binding)
    update()
  }

  clear_priority_test = function()  {
    var _result = priority_test_name != "" && manager.destroy_camera(priority_test_name)
    priority_test_name = ""
    update()
    report("Teste de prioridade: camera temporaria removida", _result)
  }

  destroy = function()  {
    if  (fps_changed)  game_set_speed(original_fps, gamespeed_fps)
    if  (!is_undefined(debug_view))  dbg_view_delete(debug_view)
    if  (instance_exists(temporary_target))  instance_destroy(temporary_target)
    if  (priority_test_name != "")  manager.destroy_camera(priority_test_name)
    debug_view = undefined
    temporary_target = noone
  }

  debug_view = dbg_view("MushCam - Testes", true)

  dbg_section("Selecao e resultado")
  dbg_text_input(ref_create(self, "camera_name"), "Camera", "s")
  dbg_button("Carregar camera", load_camera)
  dbg_watch(ref_create(self, "camera_names"), "Cameras registradas")
  dbg_watch(ref_create(self, "camera_exists"), "Camera existe")
  dbg_watch(ref_create(self, "last_action"), "Ultima chamada")
  dbg_watch(ref_create(self, "last_result"), "Sucesso")

  dbg_section("Teste rapido de prioridade")
  dbg_text("1. Iniciar: muda a tela principal para uma camera deslocada para a direita")
  dbg_text("2. Voltar: desabilita a candidata e retorna automaticamente")
  dbg_watch(ref_create(self, "priority_test_camera"), "Camera na tela principal")
  dbg_watch(ref_create(self, "priority_test_active"), "Camera de teste assumiu")
  dbg_watch(ref_create(self, "priority_test_binding"), "Camera associada corretamente")
  dbg_watch(ref_create(self, "priority_test_visible"), "Tela principal visivel")
  dbg_button("Iniciar teste de prioridade", start_priority_test)
  dbg_button("Voltar para camera anterior", stop_priority_test)
  dbg_button("Remover camera de teste", clear_priority_test)

  dbg_section("Infos")
  dbg_watch(ref_create(self, "camera_pos"), "Centro base")
  dbg_watch(ref_create(self, "camera_follow_center"), "Centro de acompanhamento sem antecipacao")
  dbg_watch(ref_create(self, "camera_desired_pos"), "Centro desejado")
  dbg_watch(ref_create(self, "camera_render_pos"), "Posicao nativa")
  dbg_watch(ref_create(self, "camera_size"), "Size")
  dbg_watch(ref_create(self, "camera_size_zoom"), "Size with zoom")
  dbg_watch(ref_create(self, "camera_offset"), "Offset atual")

  dbg_section("Cam modes")
  dbg_watch(ref_create(self, "camera_mode"), "Estado atual")
  dbg_drop_down(ref_create(self, "selected_mode"), "FollowObject:0,ToTarget:1,Fixed:2,Manual:3,FollowGroup:4", "Novo estado")
  dbg_button("Aplicar estado", function()  {
    report("camera_set_mode", manager.camera_set_mode(camera_name, selected_mode))
  })
  dbg_watch(ref_create(self, "camera_target"), "Object to follow")
  dbg_watch(ref_create(self, "camera_follow_pos"), "Ultimo ponto do alvo seguido")
  dbg_watch(ref_create(self, "camera_target_pos"), "Target - ponto de destino")
  dbg_text_input(ref_create(self, "follow_target"), "ID do alvo", "i")
  dbg_checkbox(ref_create(self, "snap"), "Centralizar imediatamente")
  dbg_button("Seguir ID", function()  {
    report("camera_follow", manager.camera_follow(camera_name, follow_target, snap))
  })
  dbg_button("Seguir jogador 1", function()  {
    follow_target = instance_find(obj_player, 0)
    report("camera_follow jogador 1", follow_target != noone && manager.camera_follow(camera_name, follow_target, snap))
  })
  dbg_button("Seguir jogador 2", function()  {
    follow_target = instance_find(obj_player2, 0)
    report("camera_follow jogador 2", follow_target != noone && manager.camera_follow(camera_name, follow_target, snap))
  })
  dbg_button("Seguir noone", function()  {
    report("camera_follow noone", manager.camera_follow(camera_name, noone))
  })

  dbg_section("Foco em grupo")
  dbg_watch(ref_create(self, "camera_group_sources"), "Fontes registradas na ordem dos indices")
  dbg_watch(ref_create(self, "camera_group_count"), "Pontos e alvos validos")
  dbg_watch(ref_create(self, "camera_group_center"), "Centro da regiao do grupo")
  dbg_watch(ref_create(self, "camera_group_bounds"), "Regiao que contem o grupo")
  dbg_watch(ref_create(self, "camera_group_fits"), "Enquadramento base inclui fontes e margens")
  dbg_watch(ref_create(self, "camera_group_max_reached"), "Limite de afastamento atingido")
  dbg_button("Grupo jogadores 1 e 2", function()  {
    var _player1 = instance_find(obj_player, 0)
    var _player2 = instance_find(obj_player2, 0)
    if  (_player1 == noone || _player2 == noone)  {
      report("camera_follow_group", false)
      return undefined
    }
    report("camera_follow_group", manager.camera_follow_group(camera_name, [{instance: _player1}, {instance: _player2}], snap))
  })
  dbg_button("Grupo dois pontos", function()  {
    report("camera_follow_group", manager.camera_follow_group(camera_name, [new Vec2(point_x, point_y), new Vec2(point_x + delta_x, point_y + delta_y)], snap))
  })
  dbg_button("Adicionar ID ao grupo", function()  {
    report("camera_add_group_target", manager.camera_add_group_target(camera_name, {instance: follow_target}))
  })
  dbg_button("Adicionar ponto ao grupo", function()  {
    report("camera_add_group_target", manager.camera_add_group_target(camera_name, new Vec2(point_x, point_y)))
  })
  dbg_text_input(ref_create(self, "group_index"), "Indice da fonte (inicia em zero)", "i")
  dbg_button("Mover ponto do grupo", function()  {
    report("camera_set_group_point", manager.camera_set_group_point(camera_name, group_index, point_x, point_y))
  })
  dbg_button("Remover fonte do grupo", function()  {
    report("camera_remove_group_target", manager.camera_remove_group_target(camera_name, group_index))
  })
  dbg_button("Limpar grupo", function()  {
    report("camera_clear_group", manager.camera_clear_group(camera_name))
  })
  dbg_text_input(ref_create(self, "group_margin_x"), "Margem horizontal por lado", "f")
  dbg_text_input(ref_create(self, "group_margin_y"), "Margem vertical por lado", "f")
  dbg_text_input(ref_create(self, "group_min_scale"), "Escala minima do campo de visao", "f")
  dbg_text_input(ref_create(self, "group_max_scale"), "Escala maxima (zero sem limite)", "f")
  dbg_checkbox(ref_create(self, "group_framing_enabled"), "Enquadramento automatico")
  dbg_button("Aplicar enquadramento do grupo", function()  {
    var _result = manager.camera_set_group_framing(camera_name, group_margin_x, group_margin_y, group_min_scale, group_max_scale)
    if  (_result)  _result = manager.camera_set_group_framing_enabled(camera_name, group_framing_enabled)
    report("camera_set_group_framing", _result)
  })
  dbg_button("Aplicar ativacao do enquadramento", function()  {
    report("camera_set_group_framing_enabled", manager.camera_set_group_framing_enabled(camera_name, group_framing_enabled))
  })
  dbg_text("Use Ponto X/Y e Deslocamento X/Y da secao Posicao e movimento")
  dbg_text("Zoom manual pode afastar mais; aproximar preserva o grupo")

  dbg_section("Posicao e movimento")
  dbg_text_input(ref_create(self, "point_x"), "Ponto X", "f")
  dbg_text_input(ref_create(self, "point_y"), "Ponto Y", "f")
  dbg_button("Mover ate ponto", function()  {
    report("camera_move_to", manager.camera_move_to(camera_name, point_x, point_y))
  })
  dbg_button("Definir posicao fixa", function()  {
    report("camera_set_position", manager.camera_set_position(camera_name, point_x, point_y))
  })
  dbg_button("Parar", function()  {
    report("camera_stop", manager.camera_stop(camera_name))
  })
  dbg_text_input(ref_create(self, "delta_x"), "Deslocamento X", "f")
  dbg_text_input(ref_create(self, "delta_y"), "Deslocamento Y", "f")
  dbg_button("Mover manualmente", function()  {
    report("camera_move", manager.camera_move(camera_name, delta_x, delta_y))
  })

  dbg_section("Zoom e offset")
  dbg_watch(ref_create(self, "camera_zoom"), "Zoom manual atual")
  dbg_watch(ref_create(self, "camera_zoom_target"), "Zoom manual desejado atual")
  dbg_slider(ref_create(self, "zoom_percent"), -1, 1, "Zoom percent", .01)
  dbg_button("Aplicar zoom", function()  {
    report("camera_set_zoom", manager.camera_set_zoom(camera_name, zoom_percent))
  })
  dbg_slider(ref_create(self, "zoom_step"), .01, 1, "Passo de zoom", .01)
  dbg_button("Aproximar", function()  {
    report("camera_adjust_zoom", manager.camera_adjust_zoom(camera_name, zoom_step))
  })
  dbg_button("Afastar", function()  {
    report("camera_adjust_zoom", manager.camera_adjust_zoom(camera_name, -zoom_step))
  })
  dbg_text_input(ref_create(self, "offset_x"), "Offset X", "f")
  dbg_text_input(ref_create(self, "offset_y"), "Offset Y", "f")
  dbg_button("Aplicar offset", function()  {
    report("camera_set_offset", manager.camera_set_offset(camera_name, offset_x, offset_y))
  })
  dbg_slider(ref_create(self, "zoom_range"), 0, .95, "Zoom Range", .01)
  dbg_slider(ref_create(self, "zoom_spd"), 0, 1, "Suavizacao zoom", .01)
  dbg_slider(ref_create(self, "move_spd_x"), 0, 1, "Suavizacao X", .01)
  dbg_slider(ref_create(self, "move_spd_y"), 0, 1, "Suavizacao Y", .01)
  dbg_text_input(ref_create(self, "zoom_input_spd"), "Velocidade zoom por segundo", "f")
  dbg_watch(ref_create(self, "camera_smoothing"), "Suavizacao X/Y atual")
  dbg_watch(ref_create(self, "camera_zoom_smoothing"), "Suavizacao zoom atual")
  dbg_text_input(ref_create(self, "arrival_distance"), "Distancia de chegada", "f")
  dbg_button("Aplicar ajustes", apply_settings)

  dbg_section("Limites da area")
  dbg_watch(ref_create(self, "camera_bounds"), "Retangulo atual")
  dbg_watch(ref_create(self, "camera_limits_enabled"), "Limites ativos")
  dbg_watch(ref_create(self, "camera_uses_room"), "Usa area da room")
  dbg_text_input(ref_create(self, "bounds_x"), "Area X", "f")
  dbg_text_input(ref_create(self, "bounds_y"), "Area Y", "f")
  dbg_text_input(ref_create(self, "bounds_width"), "Area largura", "f")
  dbg_text_input(ref_create(self, "bounds_height"), "Area altura", "f")
  dbg_button("Aplicar area personalizada", function()  {
    var _result = manager.camera_set_bounds(camera_name, bounds_x, bounds_y, bounds_width, bounds_height)
    if  (_result)  can_outside_room = false
    report("camera_set_bounds", _result)
  })
  dbg_button("Usar area da room", function()  {
    var _result = manager.camera_use_room_bounds(camera_name)
    if  (_result)  {
      can_outside_room = false
      bounds_x = 0
      bounds_y = 0
      bounds_width = room_width
      bounds_height = room_height
    }
    report("camera_use_room_bounds", _result)
  })
  dbg_checkbox(ref_create(self, "can_outside_room"), "Desativar limites")
  dbg_button("Aplicar ativacao dos limites", function()  {
    report("camera_set_limits_enabled", manager.camera_set_limits_enabled(camera_name, !can_outside_room))
  })

  dbg_section("Dead zone")
  dbg_watch(ref_create(self, "camera_dead_zone"), "Retangulo efetivo no mundo")
  dbg_watch(ref_create(self, "camera_dead_zone_enabled"), "Dead zone ativa")
  dbg_text_input(ref_create(self, "dead_zone_width"), "Dead zone largura", "f")
  dbg_text_input(ref_create(self, "dead_zone_height"), "Dead zone altura", "f")
  dbg_checkbox(ref_create(self, "dead_zone_enabled"), "Ativar dead zone")
  dbg_button("Aplicar dead zone", function()  {
    report("camera_set_dead_zone", manager.camera_set_dead_zone(camera_name, dead_zone_width, dead_zone_height, dead_zone_enabled))
  })
  dbg_button("Aplicar ativacao da dead zone", function()  {
    report("camera_set_dead_zone_enabled", manager.camera_set_dead_zone_enabled(camera_name, dead_zone_enabled))
  })
  dbg_checkbox(ref_create(self, "show_dead_zone"), "Mostrar contorno nas viewports")
  dbg_text("Atua em FollowObject e FollowGroup. Zero em um eixo segue normalmente")

  dbg_section("Look ahead")
  dbg_watch(ref_create(self, "camera_look_ahead_enabled"), "Look ahead ativo")
  dbg_watch(ref_create(self, "camera_look_ahead"), "Antecipacao atual")
  dbg_watch(ref_create(self, "camera_look_ahead_desired"), "Antecipacao desejada")
  dbg_watch(ref_create(self, "camera_target_velocity"), "Velocidade estimada em pixels/s")
  dbg_checkbox(ref_create(self, "look_ahead_enabled"), "Ativar look ahead")
  dbg_text_input(ref_create(self, "look_ahead_time_x"), "Antecipacao X em segundos", "f")
  dbg_text_input(ref_create(self, "look_ahead_time_y"), "Antecipacao Y em segundos", "f")
  dbg_text_input(ref_create(self, "look_ahead_max_x"), "Deslocamento maximo X", "f")
  dbg_text_input(ref_create(self, "look_ahead_max_y"), "Deslocamento maximo Y", "f")
  dbg_button("Aplicar look ahead", function()  {
    var _result = manager.camera_set_look_ahead(camera_name, look_ahead_time_x, look_ahead_time_y, look_ahead_max_x, look_ahead_max_y)
    if  (_result)  _result = manager.camera_set_look_ahead_enabled(camera_name, look_ahead_enabled)
    report("camera_set_look_ahead", _result)
  })
  dbg_button("Aplicar ativacao do look ahead", function()  {
    report("camera_set_look_ahead_enabled", manager.camera_set_look_ahead_enabled(camera_name, look_ahead_enabled))
  })
  dbg_slider(ref_create(self, "look_ahead_spd_x"), 0, 1, "Suavizacao antecipacao X", .01)
  dbg_slider(ref_create(self, "look_ahead_spd_y"), 0, 1, "Suavizacao antecipacao Y", .01)
  dbg_button("Aplicar suavizacao do look ahead", function()  {
    report("camera_set_look_ahead_smoothing", manager.camera_set_look_ahead_smoothing(camera_name, look_ahead_spd_x, look_ahead_spd_y))
  })
  dbg_text_input(ref_create(self, "teleport_distance"), "Distancia para detectar teleporte", "f")
  dbg_button("Aplicar distancia de teleporte", function()  {
    report("camera_set_teleport_distance", manager.camera_set_teleport_distance(camera_name, teleport_distance))
  })
  dbg_button("Zerar estimativa de movimento", function()  {
    report("camera_reset_look_ahead", manager.camera_reset_look_ahead(camera_name))
  })

  dbg_section("Screenshake")
  dbg_watch(ref_create(self, "camera_shake_active"), "Shake ativo")
  dbg_watch(ref_create(self, "camera_shake_progress"), "Progresso do shake")
  dbg_watch(ref_create(self, "camera_shake_offset"), "Deslocamento gerado no mundo")
  dbg_watch(ref_create(self, "camera_shake_applied"), "Deslocamento aplicado apos limites")
  dbg_text_input(ref_create(self, "shake_amplitude_x"), "Amplitude X em pixels do mundo", "f")
  dbg_text_input(ref_create(self, "shake_amplitude_y"), "Amplitude Y em pixels do mundo", "f")
  dbg_text_input(ref_create(self, "shake_duration"), "Duracao em segundos", "f")
  dbg_text_input(ref_create(self, "shake_frequency"), "Frequencia por segundo", "f")
  dbg_text_input(ref_create(self, "shake_falloff"), "Expoente da reducao (zero constante)", "f")
  dbg_button("Iniciar screenshake", function()  {
    report("camera_shake", manager.camera_shake(camera_name, shake_amplitude_x, shake_amplitude_y, shake_duration, shake_frequency, shake_falloff))
  })
  dbg_button("Parar screenshake", function()  {
    report("camera_stop_shake", manager.camera_stop_shake(camera_name))
  })
  dbg_text("Um novo shake substitui o anterior. Nao desloca as viewports")

  dbg_section("Teste de FPS")
  dbg_watch(ref_create(self, "current_fps"), "FPS configurado")
  dbg_watch(ref_create(self, "frame_ms"), "Tempo do frame em ms")
  dbg_drop_down(ref_create(self, "selected_fps"), "30 FPS:30,60 FPS:60,120 FPS:120,144 FPS:144", "FPS de teste")
  dbg_button("Aplicar FPS", function()  {
    game_set_speed(selected_fps, gamespeed_fps)
    fps_changed = true
    report("game_set_speed", true)
  })
  dbg_button("Restaurar FPS", function()  {
    game_set_speed(original_fps, gamespeed_fps)
    selected_fps = original_fps
    fps_changed = false
    report("Restaurar FPS", true)
  })

  dbg_section("Perda do alvo")
  dbg_watch(ref_create(self, "temporary_target"), "Alvo temporario")
  dbg_button("Criar alvo no ponto", create_target)
  dbg_button("Seguir alvo temporario", function()  {
    report("Seguir alvo temporario", instance_exists(temporary_target) && manager.camera_follow(camera_name, temporary_target, snap))
  })
  dbg_button("Destruir alvo temporario", destroy_target)
  dbg_button("Teleportar alvo temporario", function()  {
    var _exists = instance_exists(temporary_target)
    if  (_exists)  {
      temporary_target.x = point_x
      temporary_target.y = point_y
    }
    report("Teleportar alvo temporario", _exists)
  })

  dbg_section("Layout e tela")
  dbg_watch(ref_create(self, "current_layout"), "Layout atual")
  dbg_watch(ref_create(self, "layout_transition"), "Transicao ativa")
  dbg_watch(ref_create(self, "layout_progress"), "Progresso")
  dbg_drop_down(ref_create(self, "selected_layout"), "Single:0,Vertical:1,Horizontal:2,Grid:3", "Novo layout")
  dbg_button("Aplicar layout", function()  {
    report("set_layout", manager.set_layout(selected_layout))
  })
  dbg_text_input(ref_create(self, "screen_width"), "Largura tela", "f")
  dbg_text_input(ref_create(self, "screen_height"), "Altura tela", "f")
  dbg_button("Aplicar tamanho tela", function()  {
    report("set_screen_size", manager.set_screen_size(screen_width, screen_height))
  })

  dbg_section("Viewports")
  dbg_text("Layouts calculam posicao/tamanho das viewports sem overlay")
  dbg_slider_int(ref_create(self, "viewport_id"), 0, 7, "Viewport ID")
  dbg_watch(ref_create(self, "viewport_index"), "Indice registrado")
  dbg_watch(ref_create(self, "viewport_data"), "Viewport atual")
  dbg_button("Carregar viewport", load_viewport)
  dbg_text_input(ref_create(self, "viewport_x"), "Viewport X", "f")
  dbg_text_input(ref_create(self, "viewport_y"), "Viewport Y", "f")
  dbg_text_input(ref_create(self, "viewport_width"), "Viewport largura", "f")
  dbg_text_input(ref_create(self, "viewport_height"), "Viewport altura", "f")
  dbg_checkbox(ref_create(self, "viewport_active"), "Ativa")
  dbg_checkbox(ref_create(self, "viewport_overlay"), "Overlay")
  dbg_button("Criar viewport", function()  {
    report("create_viewport", manager.create_viewport(viewport_id, camera_name, new Vec2(viewport_x, viewport_y), new Vec2(viewport_width, viewport_height), viewport_active, viewport_overlay))
  })
  dbg_button("Aplicar ativacao", function()  {
    report("viewport_set_active", manager.viewport_set_active(viewport_id, viewport_active))
  })
  dbg_button("Ativar via alias", function()  {
    report("activate_viewport", manager.activate_viewport(viewport_id))
  })
  dbg_text("Associacao exclusiva remove as outras candidatas desta viewport")
  dbg_button("Usar somente esta camera", function()  {
    report("set_viewport_camera", manager.set_viewport_camera(viewport_id, camera_name))
  })
  dbg_button("Usar somente esta camera na main", function()  {
    report("camera_activate", manager.camera_activate(camera_name))
  })
  dbg_button("Destruir viewport", function()  {
    report("destroy_viewport", manager.destroy_viewport(viewport_id))
  })

  dbg_section("Prioridades por viewport")
  dbg_text("Usa o Camera e o Viewport ID selecionados acima")
  dbg_watch(ref_create(self, "viewport_camera"), "Camera exibida")
  dbg_watch(ref_create(self, "viewport_candidates"), "Candidatas, prioridades e ativacao")
  dbg_watch(ref_create(self, "candidate_registered"), "Camera selecionada registrada como candidata")
  dbg_watch(ref_create(self, "candidate_current_priority"), "Prioridade registrada da camera selecionada")
  dbg_watch(ref_create(self, "candidate_current_enabled"), "Ativacao registrada da camera selecionada")
  dbg_button("Carregar candidata selecionada", load_candidate)
  dbg_text_input(ref_create(self, "candidate_priority"), "Nova prioridade (aplicar pelo botao)", "f")
  dbg_checkbox(ref_create(self, "candidate_enabled"), "Nova ativacao (aplicar pelo botao)")
  dbg_button("Registrar candidata", function()  {
    report("viewport_add_camera", manager.viewport_add_camera(viewport_id, camera_name, candidate_priority, candidate_enabled))
    update()
  })
  dbg_button("Aplicar prioridade da candidata", function()  {
    report("viewport_set_camera_priority", manager.viewport_set_camera_priority(viewport_id, camera_name, candidate_priority))
    update()
  })
  dbg_button("Aplicar ativacao da candidata", function()  {
    report("viewport_set_camera_enabled", manager.viewport_set_camera_enabled(viewport_id, camera_name, candidate_enabled))
    update()
  })
  dbg_button("Remover candidata", function()  {
    report("viewport_remove_camera", manager.viewport_remove_camera(viewport_id, camera_name))
    update()
  })
  dbg_text("Maior prioridade habilitada assume. Empate conserva a camera atual")
  dbg_text("Carregar candidata copia sua prioridade e ativacao para os parametros")

  dbg_section("Criar e destruir cameras")
  dbg_text("Para criar outra camera, escreva um nome novo no campo Camera")
  dbg_text_input(ref_create(self, "camera_width"), "Largura base", "f")
  dbg_text_input(ref_create(self, "camera_height"), "Altura base", "f")
  dbg_button("Criar camera", function()  {
    report("create_camera", is_struct(manager.create_camera(camera_name, new Vec2(camera_width, camera_height))))
    update()
  })
  dbg_button("Ajustar proporcao pela viewport", function()  {
    var _index = manager.find_viewport_index(viewport_id)
    if  (_index == -1)  {
      report("fit_camera", false)
      return undefined
    }
    report("fit_camera", manager.fit_camera(manager.viewports[_index]) == true)
  })
  dbg_button("Ajustar cameras visiveis", function()  {
    manager.fit_visible_cameras()
    report("fit_visible_cameras", true)
  })
  dbg_button("Destruir camera selecionada", function()  {
    report("destroy_camera", manager.destroy_camera(camera_name))
    update()
  })

  update()
}
