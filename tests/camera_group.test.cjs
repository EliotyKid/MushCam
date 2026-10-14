const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, makeCamera, runSource } = require('./camera_core.test.cjs')
function close(v, expected, label) {
  assert.ok(Number.isFinite(v) && Math.abs(v - expected) < 1e-8, `${label}: ${v} vs ${expected}`)
}
function fits(camera) {
  assert.equal(camera.group_fits, true, 'Group and its margins must fit the actual camera')
  close(camera.cam.width / camera.cam.height, camera.size.x / camera.size.y, 'Aspect ratio')
}
const first = { x: 0, y: 0 }
const second = { x: 1000, y: 600 }
const camera = makeCamera()
camera.set_smoothing(1, 1, 1)
assert.equal(camera.set_follow_group([{ instance: first }, { instance: second }], true), true)
assert.equal(camera.mode, common.CAM_MODE.FOLLOW_GROUP)
camera.update_camera()
assert.deepEqual([camera.pos.x, camera.pos.y], [500, 300])
assert.equal(camera.focus_group.count, 2)
fits(camera)
const minimum = camera.cam.width
camera.set_zoom_percent(1)
camera.update_camera()
assert.equal(camera.cam.width, minimum, 'Manual zoom must not crop the group')
camera.set_zoom_percent(-1)
camera.update_camera()
fits(camera)

const point = new common.Vec2(20, 30)
const group = new common.CameraFocusGroup()
group.set_sources([point, new common.Vec2(80, 100), { instance: first }])
point.x = 9000
group.update()
assert.deepEqual([group.pos.x, group.pos.y], [40, 50], 'Points are copied and the focus is the region midpoint')
const old = group.sources
assert.equal(group.set_sources([new common.Vec2(10), common.noone]), false)
assert.equal(group.sources, old, 'Invalid replacement must preserve the current group')
assert.equal(group.set_sources('invalid'), false)
assert.equal(group.add_source('invalid'), false)
assert.equal(group.add_source(new common.Vec2(NaN)), false)
assert.equal(group.remove_source(NaN), false)
assert.equal(group.set_point(0, Infinity, 20), false)
assert.equal(group.set_point(2, 20, 30), false, 'Instance entries cannot be changed with the fixed-point command')
assert.equal(group.set_point(0, 200, 150), true)
group.update()
assert.deepEqual([group.pos.x, group.pos.y], [100, 75])
assert.equal(group.contains_target(first), true)
assert.equal(group.contains_target(second), false)
const assetGroup = new common.CameraFocusGroup()
assetGroup.object_exists = value => value === 123
assetGroup.instance_find = () => first
assetGroup.set_sources([123])
assert.equal(assetGroup.sources[0].target, first, 'Object assets resolve once to an instance')

camera.set_look_ahead(.25)
camera.set_look_ahead_smoothing(1)
first.x += 2
second.x += 2
camera.update_camera()
assert.equal(camera.target_velocity.x, 120)
fits(camera)
second.destroyed = true
camera.update_camera()
assert.equal(camera.focus_group.count, 1)
assert.equal(camera.mode, common.CAM_MODE.FOLLOW_GROUP)
assert.equal(camera.target_velocity.x, 0, 'Losing a member must not appear as group velocity')
fits(camera)
first.destroyed = true
const lastCenter = [camera.pos.x, camera.pos.y]
camera.update_camera()
assert.equal(camera.mode, common.CAM_MODE.FIXED)
assert.deepEqual([camera.pos.x, camera.pos.y], lastCenter)
assert.equal(camera.set_mode(common.CAM_MODE.FOLLOW_GROUP), false)
camera.set_follow_group([])
assert.equal(camera.mode, common.CAM_MODE.FIXED)

const constrained = makeCamera()
constrained.set_smoothing(1, 1, 1)
constrained.set_group_framing(0, 0, .5, 1)
constrained.set_follow_group([new common.Vec2(0), new common.Vec2(1000, 0)], true)
constrained.update_camera()
assert.equal(constrained.group_max_reached, true)
assert.equal(constrained.group_fits, false)
assert.equal(constrained.cam.height, 380)
const originalFraming = constrained.group_margin
assert.equal(constrained.set_group_framing(0, 0, 2, 1), false)
assert.equal(constrained.set_group_framing(-1), false)
assert.equal(constrained.set_group_framing(Infinity), false)
assert.equal(constrained.group_margin, originalFraming)
constrained.set_group_framing(32, 32, .5, 0)
constrained.update_camera()
fits(constrained)
constrained.set_group_framing_enabled(false)
constrained.update_camera()
assert.equal(constrained.cam.height, constrained.manual_view_size.y)
assert.equal(constrained.group_fits, false, 'Disabling auto framing explicitly allows manual cropping')
constrained.set_group_framing_enabled(true)
constrained.update_camera()
fits(constrained)
constrained.set_bounds(0, 0, 1000, 800)
constrained.set_group_framing(0, 0, .5, 1)
constrained.set_follow_group([new common.Vec2(-100, 400)], true)
constrained.update_camera()
assert.equal(constrained.group_fits, false, 'Area restrictions can prevent visibility and must be reported')
assert.ok(constrained.cam.x >= 0)

const manual = makeCamera()
manual.set_smoothing(1, 1, 1)
manual.set_follow_group([new common.Vec2(500, 400)], true)
manual.set_zoom_percent(1)
manual.update_camera()
assert.equal(manual.cam.height, 190)
manual.set_zoom_percent(-1)
manual.update_camera()
assert.equal(manual.cam.height, 570, 'Manual zoom may widen the automatic field of view')

const animated = makeCamera()
const moving = { x: 600, y: 400 }
animated.set_follow_group([new common.Vec2(0), { instance: moving }], true)
animated.update_camera()
fits(animated)
const previousHeight = animated.cam.height
moving.x = 200
moving.y = 0
animated.update_camera()
assert.ok(animated.cam.height < previousHeight && animated.cam.height > 400, 'Shrinking should be gradual')
for (let i = 0; i < 120; i++) {
  moving.x += 10
  moving.y += 3
  animated.set_target_offset(50, -30)
  animated.set_dead_zone(120, 80)
  animated.set_look_ahead(.25, .25, 80, 50)
  animated.update_camera()
  fits(animated)
}
animated.set_follow_target(moving)
const beforeReturn = animated.cam.height
animated.update_camera()
assert.ok(animated.cam.height < beforeReturn && animated.cam.height > animated.manual_view_size.y,
  'Leaving a group must return gradually to manual zoom')

const root = path.resolve(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const grouped = makeCamera()
const other = makeCamera()
const manager = runSource(source.slice(0, source.indexOf('create_camera("main"')), {
  ...common,
  view_visible: [], view_xport: [], view_yport: [], view_wport: [], view_hport: []
})
manager.cameras = { main: { obj: grouped, size: new common.Vec2(320, 380) }, second: { obj: other, size: new common.Vec2(320, 380) } }
manager.viewports = [
  { id: 0, camera_name: 'main', pos: new common.Vec2(0), size: new common.Vec2(640, 380), active: true, overlay: false },
  { id: 1, camera_name: 'second', pos: new common.Vec2(320, 0), size: new common.Vec2(320, 380), active: true, overlay: false }
]
assert.equal(manager.camera_follow_group('main', [new common.Vec2(0), new common.Vec2(900, 500)], true), true)
assert.equal(manager.camera_set_group_framing('main', 20), true)
manager.set_layout(0, false)
manager.set_layout(1)
for (let i = 0; i < 30; i++) {
  manager.update_layout()
  grouped.update_camera()
  fits(grouped)
}
assert.equal(other.mode, common.CAM_MODE.FIXED)
assert.equal(manager.camera_add_group_target('main', new common.Vec2(-50)), true)
assert.equal(manager.camera_set_group_point('main', 2, -100, 20), true)
assert.equal(manager.camera_remove_group_target('main', 2), true)
assert.equal(manager.camera_set_group_framing_enabled('main', false), true)
assert.equal(manager.camera_clear_group('main'), true)
assert.equal(grouped.mode, common.CAM_MODE.FIXED)
for (const [method, args] of [
  ['camera_follow_group', [[]]], ['camera_add_group_target', [new common.Vec2(0)]],
  ['camera_remove_group_target', [0]], ['camera_set_group_point', [0, 0, 0]],
  ['camera_clear_group', []], ['camera_set_group_framing', [32]], ['camera_set_group_framing_enabled', []]
]) assert.equal(manager[method]('missing', ...args), false)

const results = []
for (const fps of [30, 60, 120, 144]) {
  const timed = makeCamera()
  timed.set_smoothing(1)
  timed.set_follow_group([new common.Vec2(0), new common.Vec2(2000, 0)], true)
  timed.update_camera()
  timed.focus_group.set_point(1, 500, 0)
  timed.delta_time = 1000000 / fps
  for (let i = 0; i < fps; i++) {
    timed.update_camera()
    fits(timed)
  }
  results.push(timed.cam.height)
}
for (const value of results) close(value, results[0], 'Group zoom smoothing at different FPS')
for (let i = 0; i < 30; i++) {
  const bounded = makeCamera()
  bounded.set_bounds(100, 200, 1000, 800)
  bounded.set_target_offset(i * 30 - 400, i * 15 - 200)
  bounded.set_group_framing(20, 20)
  bounded.set_position(i * 80 - 1000, i * 60 - 500)
  bounded.set_follow_group([
    new common.Vec2(130 + i * 10, 230 + i * 5),
    new common.Vec2(1070 - i * 10, 970 - i * 5)
  ])
  for (let frame = 0; frame < 5; frame++) {
    bounded.update_camera()
    fits(bounded)
  }
}
console.log('Mixed focus groups, visibility, manual zoom, loss of targets, framing limits, split and FPS tests passed (mocked APIs)')
