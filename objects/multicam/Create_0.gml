vw = 640
vh = 380

view_enabled = true

view_visible[0] = true
var _cam_p1 = camera_create_view(0,0,vw div 2, vh)
view_set_camera(0, _cam_p1)
view_xport[0] = 0
view_yport[0] = 0
view_wport[0] = vw div 2
view_hport[0] = vh


view_visible[1] = true
var _cam_p2 = camera_create_view(0,0,vw div 2, vh)
view_set_camera(1, _cam_p2)
view_xport[1] = vw div 2
view_yport[1] = 0
view_wport[1] = vw div 2
view_hport[1] = vh