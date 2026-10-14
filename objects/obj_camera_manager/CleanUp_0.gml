if  (!is_undefined(debug_panel))  debug_panel.destroy()

for(var i=0; i<array_length(viewports); i++)  {
  var _id = viewports[i].id
  view_visible[_id] = false
  view_set_camera(_id, -1)
}

var _names = variable_struct_get_names(cameras)
for(var i=0; i<array_length(_names); i++){
  var _data = cameras[$ _names[i]]
  if  (instance_exists(_data.obj))  instance_destroy(_data.obj)
  camera_destroy(_data.cam)
}

cameras = {}
viewports = []
