// Exercises actual GML bodies with mocked APIs, not the GameMaker compiler
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { common, runSource, makeCamera } = require('./camera_core.test.cjs')
const root = path.resolve(__dirname, '..')
const source = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Create_0.gml'), 'utf8')
const bindings = []
const manager = runSource(source.slice(0, source.indexOf('create_camera("main"')), {
  ...common,
  view_visible: [], view_xport: [], view_yport: [], view_wport: [], view_hport: [],
  view_set_camera: (id, camera) => { bindings[id] = camera },
  variable_struct_remove: (data, name) => delete data[name],
  instance_destroy: camera => { camera.destroyed = true },
  camera_destroy: camera => {
    assert.ok(!bindings.includes(camera), 'Detach a native camera before destroying it')
    camera.destroyed = true
  }
})
for (const name of ['main', 'player2', 'minimap', 'boss', 'cutscene']) {
  const camera = makeCamera()
  manager.cameras[name] = { name, obj: camera, cam: camera.cam, size: new common.Vec2(320, 380) }
}
manager.create_viewport(0, 'main', new common.Vec2(0), new common.Vec2(320, 380), true)
manager.create_viewport(1, 'player2', new common.Vec2(320, 0), new common.Vec2(320, 380), true)
manager.create_viewport(2, 'minimap', new common.Vec2(440, 10), new common.Vec2(160, 95), true, true)
const selected = id => manager.viewports[manager.find_viewport_index(id)].camera_name
const geometry = () => JSON.stringify([manager.view_xport, manager.view_yport, manager.view_wport, manager.view_hport])
const main = manager.cameras.main.obj
main.set_follow_target({ x: 500, y: 300 }, true)
const mainState = JSON.stringify([main.pos, main.follow_pos, main.mode, main.object_to_follow])

assert.equal(manager.viewport_add_camera(0, 'boss', 10, false), true)
assert.equal(manager.viewport_add_camera(0, 'cutscene', 20, false), true)
assert.equal(selected(0), 'main')
manager.set_layout(common.LAYOUT.SPLIT_VERTICAL)
manager.update_layout()
const beforeSwap = geometry()
const progress = manager.layout_progress
assert.equal(manager.viewport_set_camera_enabled(0, 'boss'), true)
assert.equal(selected(0), 'boss')
assert.equal(bindings[0], manager.cameras.boss.cam)
assert.equal(manager.layout_transition, true)
assert.equal(manager.layout_progress, progress)
assert.equal(geometry(), beforeSwap)
assert.equal(selected(1), 'player2')
assert.equal(selected(2), 'minimap')
manager.viewport_set_camera_enabled(0, 'cutscene')
assert.equal(selected(0), 'cutscene')
manager.viewport_set_camera_enabled(0, 'cutscene', false)
assert.equal(selected(0), 'boss')
manager.viewport_set_camera_enabled(0, 'boss', false)
assert.equal(selected(0), 'main')
assert.equal(JSON.stringify([main.pos, main.follow_pos, main.mode, main.object_to_follow]), mainState)
for (let i = 0; i < 30; i++) manager.update_layout()
assert.equal(manager.layout_transition, false)
assert.equal(manager.view_wport[0], 320)

// Equal priorities retain the current winner; replacement never adds duplicates
manager.viewport_add_camera(0, 'boss', 0)
assert.equal(selected(0), 'main')
manager.viewport_set_camera_priority(0, 'boss', 1)
assert.equal(selected(0), 'boss')
manager.viewport_set_camera_priority(0, 'boss', 0)
assert.equal(selected(0), 'boss')
manager.viewport_add_camera(0, 'boss', -10)
assert.equal(selected(0), 'main')
assert.equal(manager.viewports[0].selector.candidates.length, 3)
const candidates = JSON.stringify(manager.viewports[0].selector.candidates)
for (const invalid of [NaN, Infinity, -Infinity, '10', undefined]) {
  assert.equal(manager.viewport_set_camera_priority(0, 'boss', invalid), false)
}
assert.equal(manager.viewport_add_camera(0, 'boss', NaN), false)
assert.equal(JSON.stringify(manager.viewports[0].selector.candidates), candidates)
assert.equal(manager.viewport_add_camera(7, 'boss'), false)
assert.equal(manager.viewport_add_camera(0, 'missing'), false)
assert.equal(manager.viewport_remove_camera(0, 'missing'), false)
assert.equal(manager.viewport_set_camera_enabled(0, 'missing'), false)

// Activation belongs to a candidate in one viewport, not to the camera globally
manager.viewport_add_camera(0, 'boss', 10)
manager.viewport_add_camera(1, 'boss', 10)
manager.viewport_set_camera_enabled(0, 'boss', false)
assert.equal(selected(0), 'main')
assert.equal(selected(1), 'boss')
assert.equal(selected(2), 'minimap')
manager.viewport_add_camera(2, 'cutscene', 20)
const overlayGeometry = geometry()
manager.viewport_set_camera_enabled(2, 'cutscene', false)
assert.equal(selected(2), 'minimap')
assert.equal(geometry(), overlayGeometry)
manager.viewport_set_active(1, false)
manager.viewport_set_camera_enabled(1, 'boss', false)
assert.equal(manager.view_visible[1], false)
manager.viewport_set_active(1)
assert.equal(selected(1), 'player2')

// Destruction falls back everywhere, including in the middle of a layout transition
manager.viewport_set_camera_enabled(0, 'boss')
manager.viewport_set_camera_enabled(1, 'boss')
manager.set_layout(common.LAYOUT.SINGLE)
manager.update_layout()
const beforeDestroy = geometry()
manager.destroy_camera('boss')
assert.equal(selected(0), 'main')
assert.equal(selected(1), 'player2')
assert.equal(manager.layout_transition, true)
assert.equal(geometry(), beforeDestroy)
assert.equal(manager.viewports[0].selector.find('boss'), -1)
assert.equal(manager.viewports[1].selector.find('boss'), -1)
manager.viewport_set_camera_enabled(0, 'cutscene')
manager.cameras.cutscene.obj.destroyed = true
manager.update_camera_selection()
assert.equal(selected(0), 'main', 'An externally destroyed camera cannot win')
manager.destroy_camera('cutscene')

// No candidates hides/detaches the viewport; restoring a candidate restores the layout
manager.set_layout(common.LAYOUT.SPLIT_VERTICAL, false)
manager.viewport_set_camera_enabled(0, 'main', false)
assert.equal(selected(0), '')
assert.equal(bindings[0], -1)
assert.equal(manager.view_visible[0], false)
assert.equal(manager.view_wport[1], 640)
manager.viewport_set_camera_enabled(0, 'main')
assert.equal(manager.view_visible[0], true)
assert.equal(manager.view_wport[0], 320)
manager.viewport_remove_camera(0, 'main')
assert.equal(selected(0), '')
manager.viewport_add_camera(0, 'main', -100)
assert.equal(selected(0), 'main', 'Negative priorities are valid')

// Legacy direct assignment explicitly replaces the list with a single candidate
manager.viewport_add_camera(0, 'player2', 100)
assert.equal(manager.camera_activate('main'), true)
assert.equal(selected(0), 'main')
assert.deepEqual(manager.viewports[0].selector.candidates, [{ name: 'main', priority: 0, enabled: true }])
manager.destroy_viewport(0)
assert.equal(bindings[0], -1)
assert.equal(manager.viewport_add_camera(0, 'main'), false)
manager.create_viewport(0, 'main', new common.Vec2(0), new common.Vec2(320, 380), true)
assert.equal(manager.viewports.at(-1).selector.candidates.length, 1)
const component = fs.readFileSync(path.join(root, 'scripts/CameraSelector/CameraSelector.gml'), 'utf8')
assert.ok(!/return\s*\r?\n|;\s*$/m.test(component + source))
assert.ok(!/view_set_camera|camera_set_view|obj_camera|obj_player/.test(component), 'Selector only resolves candidates')
const step = fs.readFileSync(path.join(root, 'objects/obj_camera_manager/Step_0.gml'), 'utf8')
assert.ok(step.indexOf('update_camera_selection()') < step.indexOf('update_layout()'))
assert.ok(step.includes('keyboard_check_released(vk_space)'))
console.log('Priority takeover, fallback, ties, independent viewports, lifecycle and uninterrupted split passed (mocked APIs)')
