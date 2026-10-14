const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { runSource, common, makeCamera } = require('./camera_core.test.cjs')
const root = path.resolve(__dirname, '..')
const managerSource = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const debugSource = fs.readFileSync(path.join(root, 'scripts/CameraDebug/CameraDebug.gml'), 'utf8')
const player1 = { x: 320, y: 192 }
const player2 = { x: 448, y: 192 }
const buttons = new Map()
const clicked = new Set()
const watches = new Map()
const views = new Set()
let temporary
let configuredFps = 60
let drawColor = 99
let drawAlpha = .4
const rectangles = []
const manager = runSource(managerSource.slice(0, managerSource.indexOf('create_camera("main"')), {
  ...common,
  variable_struct_get_names: Object.keys,
  variable_struct_remove: (s, k) => delete s[k],
  obj_camera: 1,
  view_visible: [], view_xport: [], view_yport: [], view_wport: [], view_hport: [],
  delta_time: 1000000 / 60,
  view_set_camera: () => {},
  array_delete: (a, index, count) => a.splice(index, count),
  instance_destroy: instance => { instance.destroyed = true },
  camera_destroy: () => {},
  camera_create_view: (x, y, width, height) => ({ x, y, width, height, writes: 0 }),
  instance_create_depth: (x, y, depth, object, options) => {
    const camera = makeCamera()
    camera.cam = options.cam
    camera.size = new common.Vec2(options.cam.width, options.cam.height)
    camera.pos = new common.Vec2(options.cam.width / 2, options.cam.height / 2)
    return camera
  }
})
manager.create_camera('main')
manager.create_camera('player2')
manager.create_viewport(0, 'main', new common.Vec2(0), new common.Vec2(640, 380), true)
manager.create_viewport(1, 'player2', new common.Vec2(320, 0), new common.Vec2(320, 380), true)
const panel = {
  ...common,
  _manager: manager,
  gamespeed_fps: 0,
  game_get_speed: () => configuredFps,
  game_set_speed: value => { configuredFps = value },
  view_current: 0,
  view_visible: manager.view_visible,
  c_lime: 123,
  draw_get_color: () => drawColor,
  draw_get_alpha: () => drawAlpha,
  draw_set_color: value => { drawColor = value },
  draw_set_alpha: value => { drawAlpha = value },
  draw_rectangle: (...args) => rectangles.push(args),
  obj_player: 2, obj_player2: 3,
  is_struct: value => value !== null && typeof value === 'object',
  variable_struct_get_names: Object.keys,
  instance_find: object => object === 2 ? player1 : player2,
  instance_destroy: instance => { instance.destroyed = true },
  instance_create_depth: (x, y) => { temporary = { x, y }; return temporary },
  ref_create: (owner, field) => {
    assert.ok(Object.hasOwn(owner, field), `Missing referenced variable: ${field}`)
    return { owner, field }
  },
  dbg_view: name => { views.add(name); return name },
  dbg_view_delete: name => views.delete(name),
  dbg_button: (label, callback) => {
    assert.equal(typeof callback, 'function')
    assert.equal(buttons.has(label), false)
    buttons.set(label, callback)
  },
  dbg_watch: (reference, label) => watches.set(label, reference),
  dbg_section: () => {}, dbg_text_input: () => {}, dbg_checkbox: () => {},
  dbg_drop_down: () => {}, dbg_slider: () => {}, dbg_slider_int: () => {}, dbg_text: () => {}
}
panel.self = panel
const constructorBody = debugSource.slice(debugSource.indexOf('{') + 1, debugSource.lastIndexOf('}')).replace(/^  /gm, '')
runSource(constructorBody, panel)
function click(label, expected = true) {
  assert.ok(buttons.has(label), `Missing button: ${label}`)
  clicked.add(label)
  buttons.get(label)()
  assert.equal(panel.last_result, expected, `Unexpected result: ${label}`)
}
click('Carregar camera')
panel.point_x = 600
panel.point_y = 300
click('Mover ate ponto')
assert.equal(manager.cameras.main.obj.mode, common.CAM_MODE.TO_TARGET)
click('Parar')
click('Definir posicao fixa')
panel.delta_x = 20
panel.delta_y = -10
click('Mover manualmente')
assert.deepEqual([manager.cameras.main.obj.pos.x, manager.cameras.main.obj.pos.y], [620, 290])
panel.selected_mode = common.CAM_MODE.FIXED
click('Aplicar estado')
click('Seguir jogador 1')
assert.equal(manager.cameras.main.obj.object_to_follow, player1)
click('Seguir jogador 2')
assert.equal(manager.cameras.main.obj.object_to_follow, player2)
click('Seguir ID')
click('Seguir noone')
panel.zoom_percent = .5
click('Aplicar zoom')
assert.equal(manager.cameras.main.obj.new_zoom_percent, .5)
click('Aproximar')
assert.equal(manager.cameras.main.obj.new_zoom_percent, .6)
click('Afastar')
assert.equal(manager.cameras.main.obj.new_zoom_percent, .5)
panel.offset_y = -60
click('Aplicar offset')
assert.equal(manager.cameras.main.obj.target_offset.y, -60)
panel.can_outside_room = false
panel.move_spd_x = .2
panel.move_spd_y = .04
panel.zoom_spd = .07
panel.zoom_input_spd = 2
click('Aplicar ajustes')
assert.equal(manager.cameras.main.obj.can_outside_room, false)
assert.deepEqual([manager.cameras.main.obj.spd.x, manager.cameras.main.obj.spd.y], [.2, .04])
assert.equal(manager.cameras.main.obj.zoom_spd, .07)
assert.equal(manager.cameras.main.obj.zoom_input_spd, 2)
panel.dead_zone_width = 120
panel.dead_zone_height = 80
panel.dead_zone_enabled = true
click('Aplicar dead zone')
panel.update()
assert.equal(panel.camera_dead_zone_enabled, true)
panel.draw()
assert.equal(rectangles.length, 1)
const zone = manager.cameras.main.obj.get_dead_zone()
assert.deepEqual(rectangles[0], [zone.pos.x, zone.pos.y, zone.pos.x + zone.size.x, zone.pos.y + zone.size.y, true])
assert.deepEqual([drawColor, drawAlpha], [99, .4], 'Debug drawing must restore drawing state')
panel.show_dead_zone = false
panel.draw()
assert.equal(rectangles.length, 1)
panel.dead_zone_width = -1
click('Aplicar dead zone', false)
panel.dead_zone_enabled = false
click('Aplicar ativacao da dead zone')
assert.equal(manager.cameras.main.obj.dead_zone_enabled, false)
panel.bounds_x = 100
panel.bounds_y = 80
panel.bounds_width = 500
panel.bounds_height = 400
click('Aplicar area personalizada')
panel.update()
assert.equal(panel.camera_limits_enabled, true)
assert.equal(panel.camera_uses_room, false)
assert.deepEqual([panel.camera_bounds.pos.x, panel.camera_bounds.size.x], [100, 500])
panel.bounds_width = 0
click('Aplicar area personalizada', false)
panel.can_outside_room = true
click('Aplicar ativacao dos limites')
assert.equal(manager.cameras.main.obj.can_outside_room, true)
assert.notEqual(manager.cameras.main.obj.bounds, undefined)
click('Usar area da room')
assert.equal(manager.cameras.main.obj.bounds, undefined)
assert.equal(manager.cameras.main.obj.can_outside_room, false)
panel.selected_fps = 30
click('Aplicar FPS')
panel.update()
assert.equal(panel.current_fps, 30)
click('Restaurar FPS')
assert.equal(configuredFps, 60)
click('Criar alvo no ponto')
click('Seguir alvo temporario')
assert.equal(manager.cameras.main.obj.object_to_follow, temporary)
click('Destruir alvo temporario')
manager.cameras.main.obj.update_camera()
assert.equal(manager.cameras.main.obj.mode, common.CAM_MODE.FIXED)
assert.notEqual(player1.destroyed, true)
assert.notEqual(player2.destroyed, true)
panel.selected_layout = common.LAYOUT.SPLIT_VERTICAL
click('Aplicar layout')
assert.equal(manager.layout_transition, true)
panel.screen_width = 800
click('Aplicar tamanho tela')
assert.equal(manager.screen_size.x, 800)
click('Carregar viewport')
click('Aplicar ativacao')
click('Ativar via alias')
click('Associar camera selecionada')
click('Ativar camera na main')
click('Ajustar proporcao pela viewport')
click('Ajustar cameras visiveis')
panel.camera_name = 'test'
click('Criar camera')
panel.viewport_id = 3
panel.viewport_overlay = true
click('Criar viewport')
panel.update()
assert.equal(panel.camera_exists, true)
click('Destruir camera selecionada')
panel.update()
assert.equal(panel.camera_exists, false)
assert.equal(panel.camera_pos, undefined)
click('Carregar camera', false)
click('Mover ate ponto', false)
click('Destruir viewport')
click('Criar camera')
click('Criar camera', false)
click('Criar alvo no ponto')
panel.selected_fps = 144
click('Aplicar FPS')
panel.destroy()
assert.equal(configuredFps, 60, 'Cleanup must restore the original FPS')
assert.equal(views.size, 0)
assert.equal(temporary.destroyed, true)
assert.equal(clicked.size, buttons.size, 'Every debug button must be exercised')
assert.ok(!/return\s*\r?\n|;\s*$/m.test(debugSource))
console.log(`All ${buttons.size} debug buttons, references, missing cameras and cleanup passed (mocked APIs, not GameMaker)`)
