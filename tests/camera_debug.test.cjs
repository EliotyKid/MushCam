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
panel.offset_y = -60
click('Aplicar offset')
assert.equal(manager.cameras.main.obj.target_offset.y, -60)
panel.can_outside_room = false
click('Aplicar ajustes')
assert.equal(manager.cameras.main.obj.can_outside_room, false)
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
panel.destroy()
assert.equal(views.size, 0)
assert.equal(temporary.destroyed, true)
assert.equal(clicked.size, buttons.size, 'Every debug button must be exercised')
assert.ok(!/return\s*\r?\n|;\s*$/m.test(debugSource))
console.log(`All ${buttons.size} debug buttons, references, missing cameras and cleanup passed (mocked APIs, not GameMaker)`)
