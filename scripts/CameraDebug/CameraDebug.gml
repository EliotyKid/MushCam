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
  screen_width = 640
  screen_height = 380
  viewport_id = 0
  viewport_x = 0
  viewport_y = 0
  viewport_width = 320
  viewport_height = 380
  viewport_active = true
  viewport_overlay = false
  temporary_target = noone
  last_action = "Pronto"
  last_result = true
  camera_exists = false
  camera_names = []
  camera_pos = new Vec2(0)
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
    var _data = get_selected()
    camera_exists = !is_undefined(_data)
    if  (!camera_exists)  {
      camera_pos = undefined
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
      return undefined
    }
    var _obj = _data.obj
    camera_pos = new Vec2(_obj.pos.x, _obj.pos.y)
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

  destroy = function()  {
    if  (fps_changed)  game_set_speed(original_fps, gamespeed_fps)
    if  (!is_undefined(debug_view))  dbg_view_delete(debug_view)
    if  (instance_exists(temporary_target))  instance_destroy(temporary_target)
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

  dbg_section("Infos")
  dbg_watch(ref_create(self, "camera_pos"), "Centro base")
  dbg_watch(ref_create(self, "camera_desired_pos"), "Centro desejado")
  dbg_watch(ref_create(self, "camera_render_pos"), "Posicao nativa")
  dbg_watch(ref_create(self, "camera_size"), "Size")
  dbg_watch(ref_create(self, "camera_size_zoom"), "Size with zoom")
  dbg_watch(ref_create(self, "camera_offset"), "Offset atual")

  dbg_section("Cam modes")
  dbg_watch(ref_create(self, "camera_mode"), "Estado atual")
  dbg_drop_down(ref_create(self, "selected_mode"), "FollowObject:0,ToTarget:1,Fixed:2,Manual:3", "Novo estado")
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
  dbg_watch(ref_create(self, "camera_zoom"), "Zoom atual")
  dbg_watch(ref_create(self, "camera_zoom_target"), "Zoom desejado atual")
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
  dbg_text("Atua em FollowObject. Zero em um eixo segue normalmente nesse eixo")

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
  dbg_button("Associar camera selecionada", function()  {
    report("set_viewport_camera", manager.set_viewport_camera(viewport_id, camera_name))
  })
  dbg_button("Ativar camera na main", function()  {
    report("camera_activate", manager.camera_activate(camera_name))
  })
  dbg_button("Destruir viewport", function()  {
    report("destroy_viewport", manager.destroy_viewport(viewport_id))
  })

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
