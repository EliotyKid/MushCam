const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, makeCamera, runSource } = require('./camera_core.test.cjs')
const camera = makeCamera()
const target = { x: 500, y: 400 }
camera.set_smoothing(1)
camera.set_position(500, 400)
camera.set_follow_target(target)
assert.equal(camera.dead_zone_enabled, false)
camera.set_dead_zone(120, 80)
for (const [x, y] of [[500, 400], [540, 420], [560, 440], [440, 360]]) {
  Object.assign(target, { x, y })
  camera.update_camera()
  assert.deepEqual([camera.pos.x, camera.pos.y], [500, 400], 'Inside and exact edges must not move')
}
for (const [x, y, expectedX, expectedY] of [
  [620, 400, 560, 400], [380, 400, 440, 400],
  [500, 500, 500, 460], [500, 300, 500, 340], [620, 500, 560, 460]
]) {
  camera.set_position(500, 400)
  camera.set_follow_target(target)
  Object.assign(target, { x, y })
  camera.update_camera()
  assert.deepEqual([camera.pos.x, camera.pos.y], [expectedX, expectedY])
}
camera.set_position(500, 400)
camera.set_follow_target(target)
camera.set_smoothing(.1, .2)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [506, 412])
Object.assign(target, { x: 505, y: 405 })
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [506, 412], 'Returning inside must stop residual tracking')
camera.set_target_offset(20, -30)
camera.set_position(500, 400)
Object.assign(target, { x: 480, y: 430 })
camera.set_follow_target(target)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [500, 400])
assert.deepEqual([camera.get_dead_zone().pos.x, camera.get_dead_zone().pos.y], [420, 390])
Object.assign(target, { x: 900, y: 700 })
camera.set_follow_target(target, true)
assert.deepEqual([camera.pos.x, camera.pos.y], [920, 670], 'Snap must bypass the dead zone')
camera.set_smoothing(1)
camera.move_to(600, 500)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [620, 470])
assert.equal(camera.mode, common.CAM_MODE.FIXED)
camera.move_by(20, 10)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [640, 480])
camera.set_target_offset(0, 0)
camera.set_position(500, 400)
camera.set_dead_zone(0, 80)
camera.set_follow_target({ x: 510, y: 420 })
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [510, 400], 'Zero width follows X normally')
const previous = camera.dead_zone_size
for (const dims of [[-1, 80], [120, -1], [NaN, 0], [Infinity, 0], ['120', 80]]) {
  assert.equal(camera.set_dead_zone(...dims), false)
  assert.equal(camera.dead_zone_size, previous)
}
camera.set_dead_zone(1000, 1000)
camera.zoom_spd = 1
camera.set_zoom_percent(1)
camera.update_camera()
assert.deepEqual([camera.get_dead_zone().size.x, camera.get_dead_zone().size.y], [160, 190])
camera.set_viewport_size(new common.Vec2(640, 190), 380)
camera.update_camera()
assert.deepEqual([camera.get_dead_zone().size.x, camera.get_dead_zone().size.y], [640, 190])
camera.set_zoom_percent(0)
camera.set_viewport_size(new common.Vec2(320, 380), 380)
camera.set_dead_zone(120, 80)
camera.set_bounds(0, 0, 800, 600)
camera.set_follow_target({ x: 3000, y: 3000 })
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [640, 410], 'Area limits take precedence')
camera.object_to_follow.destroyed = true
camera.update_camera()
assert.equal(camera.mode, common.CAM_MODE.FIXED)
assert.deepEqual([camera.pos.x, camera.pos.y], [640, 410])

const results = []
for (const fps of [30, 60, 120, 144]) {
  const smooth = makeCamera()
  smooth.set_position(500, 400)
  smooth.set_dead_zone(120, 80)
  smooth.set_follow_target({ x: 900, y: 700 })
  for (let frame = 0; frame < fps; frame++) {
    smooth.delta_time = 1000000 / fps
    smooth.update_camera()
  }
  results.push([smooth.pos.x, smooth.pos.y])
}
for (const result of results) result.forEach((v, i) => assert.ok(Math.abs(v - results[0][i]) < 1e-8))
const root = path.resolve(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const manager = runSource(source.slice(0, source.indexOf('create_camera("main"')), { ...common })
const independent = makeCamera()
manager.cameras = { main: { obj: camera }, second: { obj: independent } }
assert.equal(manager.camera_set_dead_zone('main', 100, 60), true)
assert.equal(independent.dead_zone_enabled, false)
assert.equal(manager.camera_set_dead_zone_enabled('main', false), true)
assert.deepEqual([camera.dead_zone_size.x, camera.dead_zone_size.y], [100, 60])
assert.equal(manager.camera_set_dead_zone('missing', 100, 60), false)
assert.equal(manager.camera_set_dead_zone_enabled('missing'), false)
console.log('Dead zone edges, offset, smoothing, states, bounds, zoom and FPS independence passed (mocked APIs)')
