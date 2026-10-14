const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, makeCamera, runSource } = require('./camera_core.test.cjs')
const root = path.resolve(__dirname, '..')
function close(actual, expected, message) {
  assert.ok(Number.isFinite(actual) && Math.abs(actual - expected) < 1e-8,
    `${message}: ${actual} vs ${expected}`)
}
function followFor(steps) {
  const camera = makeCamera()
  camera.set_smoothing(.1, .03, .05)
  camera.set_follow_target({ x: 900, y: 700 })
  camera.set_target_offset(20, -40)
  camera.set_zoom_percent(.8)
  for (const seconds of steps) {
    camera.delta_time = seconds * 1000000
    camera.update_camera()
  }
  return [camera.pos.x, camera.pos.y, camera.zoom_percent, camera.cam.width, camera.cam.height]
}
const baseline = followFor(Array(60).fill(1 / 60))
for (const fps of [30, 60, 120, 144]) {
  const result = followFor(Array(fps).fill(1 / fps))
  result.forEach((v, i) => close(v, baseline[i], `Stationary follow/zoom at ${fps} FPS`))
  const camera = makeCamera()
  camera.set_smoothing(.1, .03)
  camera.move_to(600, 300)
  for (let i = 0; i < fps * 5; i++) {
    camera.delta_time = 1000000 / fps
    camera.update_camera()
  }
  assert.equal(camera.mode, common.CAM_MODE.FIXED)
  assert.deepEqual([camera.pos.x, camera.pos.y], [600, 300])
}
const variableSteps = [.007, .033, .016, .044, .15, .25, .1, .4]
close(variableSteps.reduce((a, b) => a + b, 0), 1, 'Variable frame durations')
followFor(variableSteps).forEach((v, i) => close(v, baseline[i], 'Variable FPS'))
followFor([1]).forEach((v, i) => close(v, baseline[i], 'One long frame'))

const camera = makeCamera()
camera.set_follow_target({ x: 900, y: 700 })
camera.set_smoothing(0, 1, 0)
camera.set_zoom_percent(1)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y, camera.zoom_percent], [160, 700, 0])
camera.set_smoothing(1, 1, 1)
camera.delta_time = 0
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y, camera.zoom_percent], [160, 700, 0])
camera.delta_time = -100
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y, camera.zoom_percent], [160, 700, 0])
camera.delta_time = 1000000 / 144
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y, camera.zoom_percent], [900, 700, 1])
camera.set_smoothing(-10, 10, 10)
assert.deepEqual([camera.spd.x, camera.spd.y, camera.zoom_spd], [0, 1, 1])
camera.set_smoothing(.2)
assert.deepEqual([camera.spd.x, camera.spd.y, camera.zoom_spd], [.2, .2, 1])
camera.set_zoom_settings(10, -1)
assert.deepEqual([camera.zoom_range, camera.zoom_input_spd], [.95, 0])
camera.set_zoom_settings(.4, 2)
camera.set_zoom_percent(0)
camera.adjust_zoom(.3)
close(camera.new_zoom_percent, .3, 'Relative zoom')
camera.adjust_zoom(10)
assert.equal(camera.new_zoom_percent, 1)
camera.adjust_zoom(-10)
assert.equal(camera.new_zoom_percent, -1)

const managerSource = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
for (const fps of [30, 60, 120, 144]) {
  for (const [object, name] of [['obj_player', 'main'], ['obj_player2', 'player2']]) {
    const followed = makeCamera()
    const manager = runSource(managerSource.slice(0, managerSource.indexOf('create_camera("main"')), { ...common })
    manager.cameras = { [name]: { obj: followed } }
    const player = {
      ...common,
      x: 0, y: 0, hsp: 3, vsp: 1.5,
      delta_time: 1000000 / fps,
      inputs: () => {}, apply_velocity: () => {},
      is_keyboard_used_debug_overlay: () => false,
      keyboard_check_pressed: () => false,
      keyboard_check: key => key === 'Y' || key === 'U' ? 1 : 0,
      ord: c => c,
      obj_camera_manager: manager
    }
    player.id = player
    manager.other = player
    // GML delta_time is shared by all instances
    manager.delta_time = player.delta_time
    followed.set_follow_target(player)
    assert.equal(manager.camera_set_zoom_settings(name, .5, 1), true)
    assert.equal(manager.camera_set_smoothing(name, .15, .02, .07), true)
    assert.deepEqual([followed.spd.x, followed.spd.y, followed.zoom_spd], [.15, .02, .07])
    const source = fs.readFileSync(path.join(root, `objects/${object}/Step_0.gml`), 'utf8')
      .replace(/\bexit\b/g, 'return')
      .replace(/if keyboard_check_pressed\(ord\("([BC])"\)\)/g, 'if (keyboard_check_pressed(ord("$1")))')
    const step = new Function('scope', `with(scope) { ${source} }`)
    for (let i = 0; i < fps / 2; i++) step(player)
    close(player.x, 90, `${object} movement at ${fps} FPS`)
    close(player.y, 45, `${object} movement at ${fps} FPS`)
    close(followed.new_zoom_percent, .5, `${object} held zoom at ${fps} FPS`)
    const before = [player.x, player.y, followed.new_zoom_percent]
    player.is_keyboard_used_debug_overlay = () => true
    step(player)
    assert.deepEqual([player.x, player.y, followed.new_zoom_percent], before)
    assert.equal(manager.camera_set_smoothing('missing', .1), false)
    assert.equal(manager.camera_set_zoom_settings('missing', .5), false)
    assert.equal(manager.camera_adjust_zoom('missing', .1), false)
  }
}
console.log('Timing at 30/60/120/144 FPS, variable frames, independent axes and held player inputs passed (mocked APIs)')
