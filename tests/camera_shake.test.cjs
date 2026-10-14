const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, makeCamera, runSource } = require('./camera_core.test.cjs')
function close(v, expected, label) {
  assert.ok(Number.isFinite(v) && Math.abs(v - expected) < 1e-8, `${label}: ${v} vs ${expected}`)
}
const effect = new common.CameraShake()
assert.equal(effect.active, false)
assert.equal(effect.start(12, 6, 1, 20, 2), true)
effect.update(.25)
assert.equal(effect.active, true)
close(effect.progress, .25, 'Progress')
assert.ok(Math.abs(effect.offset.x) <= 12 * .75 ** 2)
assert.ok(Math.abs(effect.offset.y) <= 6 * .75 ** 2)
assert.ok(effect.offset.x !== 0 || effect.offset.y !== 0)
const before = [effect.elapsed, effect.offset.x, effect.offset.y]
effect.update(0)
effect.update(-1)
assert.deepEqual([effect.elapsed, effect.offset.x, effect.offset.y], before)
for (const args of [[-1, 8, 1, 20, 2], [8, 8, 0, 20, 2], [8, 8, 1, 0, 2],
  [NaN, 8, 1, 20, 2], [8, Infinity, 1, 20, 2], [8, 8, 1, 20, -1], ['8', 8, 1, 20, 2],
  [8, 8, Number.MAX_VALUE, Number.MAX_VALUE, 2]]) {
  assert.equal(effect.start(...args), false)
  assert.deepEqual([effect.elapsed, effect.offset.x, effect.offset.y], before)
}
const sequence = effect.sequence
effect.start(0, 8, 1, 20, 0)
assert.equal(effect.sequence, sequence + 1)
assert.equal(effect.elapsed, 0)
effect.update(.1)
close(effect.offset.x, 0, 'Zero amplitude axis')
assert.ok(Math.abs(effect.offset.y) <= 8)
effect.stop()
assert.equal(effect.active, false)
assert.deepEqual([effect.offset.x, effect.offset.y], [0, 0])
effect.start(0, 0)
assert.equal(effect.active, false)

const samples = []
for (const fps of [30, 60, 120, 144]) {
  const timed = new common.CameraShake()
  timed.start(12, 6, 1, 25, 2)
  for (let frame = 0; frame < fps / 2; frame++) timed.update(1 / fps)
  samples.push([timed.offset.x, timed.offset.y, timed.progress])
  for (let frame = 0; frame < fps / 2; frame++) timed.update(1 / fps)
  assert.equal(timed.active, false, `Duration at ${fps} FPS`)
  assert.deepEqual([timed.offset.x, timed.offset.y], [0, 0])
}
for (const sample of samples) sample.forEach((v, i) => close(v, samples[0][i], 'Shake sampling independent of FPS'))
const variable = new common.CameraShake()
variable.start(12, 6, 1, 25, 2)
for (const seconds of [.007, .033, .016, .044, .15, .25]) variable.update(seconds)
close(variable.offset.x, samples[0][0], 'Variable-frame sampling X')
close(variable.offset.y, samples[0][1], 'Variable-frame sampling Y')
variable.update(10)
assert.equal(variable.active, false)

function state(camera) {
  return [camera.pos.x, camera.pos.y, camera.follow_pos.x, camera.follow_pos.y,
    camera.desired_pos.x, camera.desired_pos.y, camera.size_zoom.x, camera.size_zoom.y,
    camera.look_ahead.x, camera.look_ahead.y, camera.zoom_percent, camera.group_fits, camera.mode]
}
for (const mode of ['fixed', 'manual', 'point', 'follow', 'group']) {
  const plain = makeCamera()
  const shaken = makeCamera()
  const moving = { x: 500, y: 400 }
  for (const camera of [plain, shaken]) {
    camera.set_position(500, 400)
    camera.set_target_offset(20, -30)
    camera.set_smoothing(.1, .05, .07)
    if (mode === 'manual') camera.move_by(20, 10)
    if (mode === 'point') camera.move_to(800, 600)
    if (mode === 'follow') camera.set_follow_target(moving)
    if (mode === 'group') camera.set_follow_group([{ instance: moving }, new common.Vec2(800, 600)])
    camera.set_dead_zone(120, 80)
    camera.set_look_ahead(.25)
    camera.set_zoom_percent(.5)
  }
  shaken.shake.start(12, 6, .5, 25, 2)
  let visualDisplacement = false
  for (let frame = 0; frame < 60; frame++) {
    moving.x += 2
    moving.y += 1
    plain.update_camera()
    shaken.update_camera()
    assert.deepEqual(state(shaken), state(plain), `${mode}: shake must not feed back into camera behavior`)
    if (shaken.cam.x !== plain.cam.x || shaken.cam.y !== plain.cam.y) visualDisplacement = true
    if (!shaken.shake.active) assert.deepEqual([shaken.cam.x, shaken.cam.y], [plain.cam.x, plain.cam.y])
  }
  assert.equal(visualDisplacement, true, `${mode}: native position must show the effect`)
}

const bounded = makeCamera()
bounded.set_bounds(0, 0, 1000, 800)
bounded.set_position(160, 190)
bounded.shake.start(100, 100, 1, 25, 0)
for (let frame = 0; frame < 60; frame++) {
  bounded.update_camera()
  assert.ok(bounded.cam.x >= 0 && bounded.cam.x + bounded.cam.width <= 1000)
  assert.ok(bounded.cam.y >= 0 && bounded.cam.y + bounded.cam.height <= 800)
  assert.deepEqual([bounded.pos.x, bounded.pos.y], [160, 190])
}
const grouped = makeCamera()
grouped.set_smoothing(1, 1, 1)
grouped.set_group_framing(0, 0)
grouped.set_follow_group([new common.Vec2(0), new common.Vec2(400, 0)], true)
grouped.update_camera()
const height = grouped.cam.height
grouped.shake.start(100, 100, 1, 25, 0)
for (let frame = 0; frame < 60; frame++) {
  grouped.update_camera()
  close(grouped.cam.height, height, 'Shake must not alter automatic framing')
  assert.ok(grouped.cam.x <= .001 && grouped.cam.x + grouped.cam.width >= 400 - .001)
  assert.ok(grouped.cam.y <= 0 && grouped.cam.y + grouped.cam.height >= 0)
}

const root = path.resolve(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const main = makeCamera()
const other = makeCamera()
const manager = runSource(source.slice(0, source.indexOf('create_camera("main"')), {
  ...common,
  view_visible: [], view_xport: [], view_yport: [], view_wport: [], view_hport: [],
  view_set_camera: () => {}
})
manager.cameras = {
  main: { obj: main, cam: main.cam, size: new common.Vec2(320, 380) },
  second: { obj: other, cam: other.cam, size: new common.Vec2(320, 380) }
}
manager.create_viewport(0, 'main', new common.Vec2(0), new common.Vec2(320, 380), true)
manager.create_viewport(1, 'second', new common.Vec2(320, 0), new common.Vec2(320, 380), true)
manager.create_viewport(2, 'main', new common.Vec2(440, 20), new common.Vec2(160, 190), true, true)
manager.set_layout(1, false)
const ports = JSON.stringify([manager.view_xport, manager.view_yport, manager.view_wport, manager.view_hport])
assert.equal(manager.camera_shake('main', 12, 6, .5), true)
assert.equal(other.shake.active, false)
for (let frame = 0; frame < 10; frame++) {
  main.update_camera()
  other.update_camera()
  assert.equal(JSON.stringify([manager.view_xport, manager.view_yport, manager.view_wport, manager.view_hport]), ports)
  assert.deepEqual([other.cam.x, other.cam.y], [0, 0])
  const elapsed = main.shake.elapsed
  main.apply_camera()
  main.apply_camera()
  assert.equal(main.shake.elapsed, elapsed, 'Multiple viewports must not advance the effect multiple times')
}
assert.equal(manager.camera_stop_shake('main'), true)
main.update_camera()
close(main.cam.x + main.cam.width / 2, main.pos.x, 'Stop restores the base center X')
close(main.cam.y + main.cam.height / 2, main.pos.y, 'Stop restores the base center Y')
assert.equal(manager.camera_shake('missing'), false)
assert.equal(manager.camera_stop_shake('missing'), false)
const component = fs.readFileSync(path.join(root, 'scripts/CameraShake/CameraShake.gml'), 'utf8')
assert.ok(!/\b(?:random|irandom|randomize|random_set_seed)\s*\(/.test(component))
assert.ok(!/return\s*\r?\n|;\s*$/m.test(component))
console.log('Screenshake timing, five states, isolation, limits, group visibility and unchanged viewports passed (mocked APIs)')
