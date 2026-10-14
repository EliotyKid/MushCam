// Checks the calculation code with mocked APIs, not the GameMaker compiler
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const root = path.resolve(__dirname, '..')
const cameraSource = fs.readFileSync(path.join(root, 'objects/obj_camera/Create_0.gml'), 'utf8')
const managerSource = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')

function runSource(source, scope) {
  for (const match of source.matchAll(/^(\w+) = /gm)) scope[match[1]] = undefined
  const adapted = source
    .replace(/enum\s+\w+\s*\{[^}]*\}/g, '')
    .replace(/\[\$\s*/g, '[')
    .replace(/i mod _cols/g, 'i % _cols')
    .replace(/i div _cols/g, 'Math.floor(i / _cols)')
    .replace(/if _layout < 0 \|\| _layout >= LAYOUT.LENGHT return false/g,
      'if (_layout < 0 || _layout >= LAYOUT.LENGHT) return false')
  new Function('scope', `with (scope) { ${adapted} }`)(scope)
  return scope
}

function Vec2(x, y = x) {
  this.x = x
  this.y = y
}

const common = {
  Vec2,
  CAM_MODE: { FOLLOW_OBJECT: 0, TO_TARGET: 1, FIXED: 2, MANUAL: 3, FOLLOW_GROUP: 4 },
  LAYOUT: { SINGLE: 0, SPLIT_VERTICAL: 1, SPLIT_HORIZONTAL: 2, GRID: 3, LENGHT: 4 },
  min: Math.min, max: Math.max, floor: Math.floor, ceil: Math.ceil,
  sqrt: Math.sqrt, round: Math.round,
  abs: Math.abs,
  power: Math.pow,
  delta_time: 1000000 / 60,
  lerp: (a, b, t) => a + (b - a) * t,
  point_distance: (x1, y1, x2, y2) => Math.hypot(x2 - x1, y2 - y1),
  clamp: (v, lo, hi) => Math.max(lo, Math.min(hi, v)),
  array_length: a => a.length,
  array_push: (a, item) => a.push(item),
  array_delete: (a, index, count) => a.splice(index, count),
  is_array: Array.isArray,
  is_struct: v => v !== null && typeof v === 'object' && !Array.isArray(v),
  is_numeric: v => typeof v === 'number',
  string: String,
  object_exists: () => false,
  variable_instance_get: (target, key) => target[key],
  CameraFocusGroup: function() {
    const source = fs.readFileSync(path.join(root, 'scripts/CameraFocusGroup/CameraFocusGroup.gml'), 'utf8')
    const body = source.slice(source.indexOf('{') + 1, source.lastIndexOf('}')).replace(/^  /gm, '')
    return runSource(body, { ...common })
  },
  is_string: v => typeof v === 'string',
  is_real: v => typeof v === 'number',
  is_nan: Number.isNaN,
  is_infinity: v => v === Infinity || v === -Infinity,
  is_undefined: v => v === undefined,
  variable_struct_exists: (s, k) => Object.hasOwn(s, k),
  instance_exists: v => v !== null && v !== -4 && v?.destroyed !== true,
  noone: -4,
  room_width: 1000, room_height: 800
}

function makeCamera() {
  const native = { x: 0, y: 0, width: 320, height: 380, writes: 0 }
  const scope = {
    ...common, cam: native,
    camera_get_view_x: cam => cam.x,
    camera_get_view_y: cam => cam.y,
    camera_get_view_width: cam => cam.width,
    camera_get_view_height: cam => cam.height,
    camera_set_view_size: (cam, width, height) => {
      Object.assign(cam, { width, height })
      cam.writes++
    },
    camera_set_view_pos: (cam, x, y) => {
      Object.assign(cam, { x, y })
      cam.writes++
    }
  }
  runSource(cameraSource, scope)
  return scope
}

const camera = makeCamera()
camera.update_camera()
assert.deepEqual([camera.cam.x, camera.cam.y], [0, 0])
camera.set_follow_target({ x: 500, y: 400 })
camera.set_smoothing(1)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [500, 400])

const free = makeCamera()
const freeCenter = [free.pos.x, free.pos.y]
free.zoom_spd = 1
free.set_viewport_size(new Vec2(640, 380), 380)
free.set_zoom_percent(1)
free.update_camera()
assert.deepEqual([free.pos.x, free.pos.y], freeCenter)
assert.deepEqual([free.cam.x + free.cam.width / 2, free.cam.y + free.cam.height / 2], freeCenter)
const smooth = makeCamera()
smooth.set_follow_target({ x: 500, y: 400 })
smooth.update_camera()
assert.deepEqual([smooth.pos.x, smooth.pos.y], [194, 211])
assert.deepEqual([smooth.desired_pos.x, smooth.desired_pos.y], [500, 400])
assert.deepEqual([camera.cam.x, camera.cam.y], [340, 210])

camera.set_target_offset(20, -60)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [520, 340])
const center = [camera.pos.x, camera.pos.y]
const writes = camera.cam.writes
assert.equal(camera.set_viewport_size(new Vec2(640, 380), 380), true)
assert.equal(camera.cam.writes, writes, 'Viewport fitting must not write to the native camera')
camera.update_camera()
assert.deepEqual([camera.cam.width, camera.cam.height], [640, 380])
assert.deepEqual([camera.pos.x, camera.pos.y], center)
assert.deepEqual([camera.cam.x + camera.cam.width / 2, camera.cam.y + camera.cam.height / 2], center)

camera.zoom_spd = 1
camera.set_zoom_percent(1)
camera.update_camera()
assert.deepEqual([camera.cam.width, camera.cam.height], [320, 190])
assert.deepEqual([camera.cam.x + camera.cam.width / 2, camera.cam.y + camera.cam.height / 2], center)
assert.equal(camera.set_viewport_size(new Vec2(0, 380), 380), false)
camera.set_zoom_percent(100)
assert.equal(camera.new_zoom_percent, 1)
camera.set_zoom_percent(-100)
assert.equal(camera.new_zoom_percent, -1)

camera.object_to_follow.destroyed = true
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], center, 'Losing a target must preserve the base center')
camera.move_to(300, 250)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [320, 190])
camera.can_outside_room = false
camera.pos = new Vec2(-100, 900)
camera.size_zoom = new Vec2(200, 100)
camera.limit_position()
assert.deepEqual([camera.pos.x, camera.pos.y], [100, 750])
camera.size_zoom = new Vec2(1200, 900)
camera.limit_position()
assert.deepEqual([camera.pos.x, camera.pos.y], [500, 400])

const main = makeCamera()
const second = makeCamera()
const minimap = makeCamera()
main.set_follow_target({ x: 500, y: 400 })
second.set_follow_target({ x: 700, y: 400 })
main.set_smoothing(1)
second.set_smoothing(1)
const manager = runSource(managerSource.slice(0, managerSource.indexOf('create_camera("main"')), {
  ...common,
  view_visible: [], view_xport: [], view_yport: [], view_wport: [], view_hport: [],
  delta_time: 1000000 / 60
})
manager.cameras = {
  main: { obj: main, cam: main.cam, size: new Vec2(320, 380) },
  player2: { obj: second, cam: second.cam, size: new Vec2(320, 380) },
  minimap: { obj: minimap, cam: minimap.cam, size: new Vec2(640, 380) }
}
manager.viewports = [
  { id: 0, camera_name: 'main', pos: new Vec2(0), size: new Vec2(640, 380), active: true, overlay: false },
  { id: 1, camera_name: 'player2', pos: new Vec2(320, 0), size: new Vec2(320, 380), active: true, overlay: false },
  { id: 2, camera_name: 'minimap', pos: new Vec2(200, 10), size: new Vec2(160, 95), active: true, overlay: true }
]
manager.set_layout(0, false)
main.update_camera()
assert.equal(main.cam.width, 640)
assert.equal(manager.view_visible[1], false)
assert.equal(manager.camera_set_offset('missing', 0, 0), false)
assert.equal(manager.camera_set_offset('main', 0, -30), true)
assert.equal(manager.camera_set_zoom('main', 0), true)
manager.set_layout(1)
manager.update_layout()
assert.ok(manager.layout_progress > 0, 'Transition must advance after Space')
assert.ok(manager.layout_division < 640)
for (let frame = 0; frame < 30; frame++) {
  manager.update_layout()
  main.update_camera()
  second.update_camera()
  assert.equal(manager.viewports[0].size.x + manager.viewports[1].size.x, 640)
  assert.equal(main.cam.x + main.cam.width / 2, 500)
  assert.equal(main.cam.y + main.cam.height / 2, 370)
  assert.equal(manager.view_visible[2], true)
  assert.deepEqual([manager.viewports[2].pos.x, manager.viewports[2].pos.y], [200, 10])
  assert.deepEqual([minimap.size.x, minimap.size.y], [640, 380])
}
assert.equal(main.cam.width, 320)
assert.equal(second.cam.width, 320)
manager.set_layout(0)
manager.update_layout()
const division = manager.layout_division
manager.set_layout(1)
assert.equal(manager.layout_division, division, 'Reversing must preserve the current division')
for (let frame = 0; frame < 30; frame++) manager.update_layout()
manager.set_layout(2)
assert.equal(manager.layout_transition, false)
assert.deepEqual([manager.viewports[0].size.x, manager.viewports[0].size.y], [640, 190])
manager.set_layout(0)
for (let frame = 0; frame < 30; frame++) manager.update_layout()
main.update_camera()
assert.equal(manager.view_visible[1], false)
assert.equal(main.cam.width, 640)
manager.set_layout(1)
manager.set_layout(1, false)
assert.equal(manager.layout_transition, false)
manager.set_layout(3)
assert.equal(manager.view_visible[1], true)

const controlled = makeCamera()
assert.equal(controlled.mode, common.CAM_MODE.FIXED)
controlled.set_target_offset(10, -20)
controlled.set_position(200, 250)
controlled.update_camera()
assert.deepEqual([controlled.pos.x, controlled.pos.y], [200, 250], 'Fixed coordinates ignore the target offset')
controlled.move_to(400, 450)
controlled.update_camera()
assert.equal(controlled.mode, common.CAM_MODE.TO_TARGET)
assert.ok(controlled.pos.x > 200 && controlled.pos.x < 410)
controlled.set_mode(common.CAM_MODE.TO_TARGET)
assert.deepEqual([controlled.to_target_pos.x, controlled.to_target_pos.y], [400, 450], 'Repeating a mode must preserve its destination')
for (let frame = 0; frame < 200; frame++) controlled.update_camera()
assert.deepEqual([controlled.pos.x, controlled.pos.y], [410, 430])
assert.equal(controlled.mode, common.CAM_MODE.FIXED, 'Arrival must stop exactly at the destination')
controlled.move_to(900, 700)
controlled.update_camera()
controlled.set_mode(common.CAM_MODE.FIXED)
const stopped = [controlled.pos.x, controlled.pos.y]
for (let frame = 0; frame < 10; frame++) controlled.update_camera()
assert.deepEqual([controlled.pos.x, controlled.pos.y], stopped)
controlled.move_by(20, -30)
controlled.move_by(10, 5)
controlled.update_camera()
assert.equal(controlled.mode, common.CAM_MODE.MANUAL)
assert.deepEqual([controlled.pos.x, controlled.pos.y], [stopped[0] + 30, stopped[1] - 25])
const manuallyMoved = [controlled.pos.x, controlled.pos.y]
controlled.set_zoom_percent(1)
controlled.update_camera()
assert.deepEqual([controlled.pos.x, controlled.pos.y], manuallyMoved)
const target = { x: 300, y: 400 }
controlled.set_follow_target(target, true)
assert.deepEqual([controlled.pos.x, controlled.pos.y], [310, 380])
const previousMode = controlled.mode
assert.equal(controlled.set_mode(99), false)
assert.equal(controlled.set_follow_target({ destroyed: true }), false)
assert.equal(controlled.mode, previousMode)
assert.equal(controlled.object_to_follow, target)
target.destroyed = true
controlled.update_camera()
assert.equal(controlled.mode, common.CAM_MODE.FIXED)
assert.equal(controlled.object_to_follow, common.noone)
assert.deepEqual([controlled.pos.x, controlled.pos.y], [310, 380])
assert.equal(controlled.set_mode(common.CAM_MODE.FOLLOW_OBJECT), false)
controlled.set_follow_target({ x: 700, y: 600 })
assert.equal(controlled.set_follow_target(common.noone), true)
assert.equal(controlled.mode, common.CAM_MODE.FIXED)
controlled.can_outside_room = false
controlled.zoom_spd = 1
controlled.set_zoom_percent(0)
controlled.move_to(-100, -100)
for (let frame = 0; frame < 200; frame++) controlled.update_camera()
assert.deepEqual([controlled.pos.x, controlled.pos.y], [160, 190])
assert.equal(controlled.mode, common.CAM_MODE.FIXED, 'A destination outside the room must finish at the reachable boundary')

assert.equal(manager.camera_move_to('missing', 10, 20), false)
assert.equal(manager.camera_set_position('main', 250, 300), true)
main.update_camera()
assert.deepEqual([main.pos.x, main.pos.y], [250, 300])
assert.equal(manager.camera_move('main', 30, -10), true)
assert.deepEqual([main.pos.x, main.pos.y], [280, 290])
assert.equal(manager.camera_stop('main'), true)
assert.equal(main.mode, common.CAM_MODE.FIXED)
assert.equal(manager.camera_move_to('main', 600, 400), true)
main.update_camera()
assert.deepEqual([main.pos.x, main.pos.y], [600, 370])
assert.equal(manager.camera_follow('main', { x: 500, y: 500 }, true), true)
assert.deepEqual([main.pos.x, main.pos.y], [500, 470])
assert.equal(manager.camera_set_mode('main', common.CAM_MODE.MANUAL), true)
assert.equal(manager.camera_follow('main', common.noone), true)
assert.equal(main.mode, common.CAM_MODE.FIXED)

assert.ok(!/return\s*\r?\n/.test(cameraSource + managerSource), 'Bare returns can consume the next expression in GML')
assert.ok(!/;\s*$/m.test(cameraSource), 'Do not add semicolons at the end of GML instructions')
assert.ok(!/keyboard_check|obj_player/.test(cameraSource), 'Camera behavior must not depend on player inputs')
assert.ok(!/camera_set_view_(pos|size)/.test(managerSource), 'Manager must not apply native transforms')
const events = fs.readFileSync(path.join(root, 'objects/obj_camera/obj_camera.yy'), 'utf8')
assert.match(events, /"eventNum":2,"eventType":3/)
assert.equal(fs.readFileSync(path.join(root, 'objects/obj_camera/Step_2.gml'), 'utf8').trim(), 'update_camera()')
console.log('Camera calculations, viewport integration and architecture checks passed (mocked APIs, not GameMaker)')

module.exports = { runSource, common, makeCamera }
