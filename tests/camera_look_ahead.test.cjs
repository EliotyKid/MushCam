const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, makeCamera, runSource } = require('./camera_core.test.cjs')
const camera = makeCamera()
const target = { x: 500, y: 400 }
camera.set_follow_target(target, true)
camera.set_smoothing(1)
assert.equal(camera.look_ahead_enabled, false)
camera.set_look_ahead(.25, .5, 80, 50)
camera.set_look_ahead_smoothing(1)
target.x += 2
target.y += 1
camera.update_camera()
assert.deepEqual([camera.target_velocity.x, camera.target_velocity.y], [120, 60])
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [30, 30])
assert.deepEqual([camera.pos.x, camera.pos.y], [532, 431])
target.x += 10
target.y += 10
camera.update_camera()
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [80, 50], 'Anticipation must respect its independent axis limits')
camera.set_look_ahead_smoothing(.1)
target.x -= 2
target.y -= 1
camera.update_camera()
assert.ok(camera.look_ahead.x > 0 && camera.look_ahead.x < 80, 'Reversing should blend rather than flip instantly')
assert.deepEqual([camera.look_ahead_desired.x, camera.look_ahead_desired.y], [-30, -30])
for (let i = 0; i < 120; i++) camera.update_camera()
assert.equal(camera.target_velocity.x, 0)
assert.ok(Math.abs(camera.look_ahead.x) < .001, 'Stopping should return anticipation to zero')

target.x += 1000
camera.update_camera()
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y, camera.target_velocity.x], [0, 0, 0], 'Teleport must not be treated as velocity')
const otherTarget = { x: -300, y: -200 }
camera.set_follow_target(otherTarget)
camera.update_camera()
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [0, 0], 'A new target must not inherit the old estimate')
otherTarget.x += 2
camera.set_follow_target(otherTarget)
camera.update_camera()
assert.equal(camera.target_velocity.x, 120, 'Repeated follow calls for the same target must not reset sampling')
camera.set_follow_target(otherTarget, true)
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [0, 0])
camera.move_to(600, 500)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [600, 500])
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [0, 0])
camera.move_by(20, 10)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [620, 510])
camera.set_follow_target(otherTarget)
otherTarget.destroyed = true
camera.update_camera()
assert.equal(camera.mode, common.CAM_MODE.FIXED)
assert.deepEqual([camera.look_ahead.x, camera.look_ahead.y], [0, 0])

const combined = makeCamera()
const approaching = { x: 0, y: 0 }
combined.set_follow_target(approaching, true)
combined.set_smoothing(1)
combined.set_dead_zone(120, 80)
combined.set_look_ahead(.25, 0, 80, 0)
combined.set_look_ahead_smoothing(1)
approaching.x = 50
combined.update_camera()
assert.equal(combined.follow_pos.x, 0, 'Target inside dead zone must preserve the tracking center')
assert.equal(combined.pos.x, 80, 'Dead zone must not absorb anticipation')
assert.equal(combined.get_dead_zone().pos.x, 20, 'The debug rectangle must stay anchored to the final camera center')
combined.set_target_offset(20, -30)
combined.update_camera()
assert.equal(combined.target_velocity.x, 0, 'Changing offset must not be interpreted as target movement')
combined.use_room_bounds()
approaching.x = 9000
combined.update_camera()
assert.equal(combined.pos.x, 840, 'Area limits must still constrain teleport and look ahead')
combined.set_look_ahead_enabled(false)
assert.deepEqual([combined.look_ahead.x, combined.look_ahead.y], [0, 0])

// Regression: anticipation smaller than half the zone must remain visible,
// without affecting the underlying tracking or moving the overlay in the viewport
for (const fps of [30, 60, 120, 144]) {
  const plain = makeCamera()
  const predicted = makeCamera()
  const sharedTarget = { x: 500, y: 400 }
  for (const follower of [plain, predicted]) {
    follower.set_follow_target(sharedTarget, true)
    follower.set_target_offset(20, -30)
    follower.set_dead_zone(120, 80)
    follower.delta_time = 1000000 / fps
  }
  predicted.set_look_ahead(.25, .25, 80, 50)
  predicted.set_look_ahead_smoothing(1)
  for (let frame = 0; frame < fps * 3; frame++) {
    const direction = frame < fps ? 1 : frame < fps * 2 ? -1 : 0
    sharedTarget.x += direction * 30 / fps
    sharedTarget.y += direction * 15 / fps
    plain.update_camera()
    predicted.update_camera()
    assert.deepEqual([predicted.follow_pos.x, predicted.follow_pos.y], [plain.pos.x, plain.pos.y],
      'Look ahead must not feed back into dead zone tracking')
    const zone = predicted.get_dead_zone()
    assert.ok(Math.abs(zone.pos.x + zone.size.x / 2 - predicted.render_pos.x - predicted.size_zoom.x / 2 + 20) < 1e-8)
    assert.ok(Math.abs(zone.pos.y + zone.size.y / 2 - predicted.render_pos.y - predicted.size_zoom.y / 2 - 30) < 1e-8)
    if (direction !== 0) {
      assert.ok(Math.abs(predicted.pos.x - plain.pos.x - direction * 7.5) < 1e-8,
        'A small anticipation must not be swallowed by the zone')
    }else{
      assert.deepEqual([predicted.pos.x, predicted.pos.y], [plain.pos.x, plain.pos.y])
    }
  }
}
const config = combined.look_ahead_time
for (const values of [[-1, .2, 80, 50], [NaN, .2, 80, 50], [.2, .2, Infinity, 50], ['x', .2, 80, 50]]) {
  assert.equal(combined.set_look_ahead(...values), false)
  assert.equal(combined.look_ahead_time, config)
}
assert.equal(combined.set_look_ahead_smoothing(Infinity), false)
assert.equal(combined.set_teleport_distance(0), false)
assert.equal(combined.set_teleport_distance(NaN), false)
assert.equal(combined.set_teleport_distance(400), true)

const fpsResults = []
for (const fps of [30, 60, 120, 144]) {
  const smooth = makeCamera()
  const moving = { x: 500, y: 400 }
  smooth.set_follow_target(moving, true)
  smooth.set_smoothing(1)
  smooth.set_look_ahead(.25, .5, 80, 50)
  smooth.delta_time = 1000000 / fps
  for (let frame = 0; frame < fps; frame++) {
    moving.x += 120 / fps
    moving.y += 60 / fps
    smooth.update_camera()
  }
  fpsResults.push([smooth.look_ahead.x, smooth.look_ahead.y])
  const before = [smooth.pos.x, smooth.pos.y]
  smooth.delta_time = 0
  moving.x += 1000
  smooth.update_camera()
  assert.deepEqual([smooth.pos.x, smooth.pos.y], before)
  smooth.delta_time = 1000000 / fps
  smooth.update_camera()
  assert.equal(smooth.target_velocity.x, 0, 'Zero-time movement must rebase the sample')
}
for (const result of fpsResults) result.forEach((v, i) => assert.ok(Math.abs(v - fpsResults[0][i]) < 1e-8))
const root = path.resolve(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const manager = runSource(source.slice(0, source.indexOf('create_camera("main"')), { ...common })
manager.cameras = { main: { obj: camera }, second: { obj: makeCamera() } }
assert.equal(manager.camera_set_look_ahead('main', .2, 0, 60, 0), true)
assert.equal(manager.camera_set_look_ahead_smoothing('main', .2), true)
assert.equal(manager.camera_set_teleport_distance('main', 300), true)
assert.equal(manager.camera_reset_look_ahead('main'), true)
assert.equal(manager.camera_set_look_ahead_enabled('main', false), true)
assert.equal(manager.cameras.second.obj.look_ahead_enabled, false)
assert.equal(manager.camera_set_look_ahead('missing', .2), false)
assert.equal(manager.camera_set_look_ahead_smoothing('missing', .2), false)
assert.equal(manager.camera_set_teleport_distance('missing', 300), false)
assert.equal(manager.camera_reset_look_ahead('missing'), false)
assert.equal(manager.camera_set_look_ahead_enabled('missing'), false)
console.log('Look ahead velocity, reversal, stopping, reset, teleport, dead zone, bounds and FPS independence passed (mocked APIs)')
