switch (mode) {
  case CAM_MODE.FOLLOW_OBJECT:
    if !instance_exists(object_to_follow) break;
    pos.x = lerp(pos.x, object_to_follow.x-size_zoom.x*.5, spd)
    pos.y = lerp(pos.y, object_to_follow.y-size_zoom.y*.7,spd)
    
    if object_to_follow.object_index == obj_player{
      new_zoom_percent += (keyboard_check(ord("Y"))-keyboard_check(ord("H")))*zoom_spd 
    }else{
      new_zoom_percent += (keyboard_check(ord("U"))-keyboard_check(ord("J")))*zoom_spd
    }
    
    break;
  case CAM_MODE.TO_TARGET: 
    pos.x = lerp(pos.x,to_target_pos.x-size_zoom.x*.5,spd)
    pos.y = lerp(pos.y,to_target_pos.y-size_zoom.y*.7,spd)
    break;
}


//new_zoom_percent += (keyboard_check(vk_down)-keyboard_check(vk_up))*zoom_spd
zoom_percent = lerp(zoom_percent, new_zoom_percent,zoom_spd)
zoom_percent = clamp(zoom_percent,-1,1)
 
var _old_size = new Vec2(camera_get_view_width(cam),camera_get_view_height(cam))
size_zoom = new Vec2(size.x-(size.x*(zoom_range*zoom_percent)),size.y-(size.y*(zoom_range*zoom_percent)))

camera_set_view_size(cam,size_zoom.x,size_zoom.y)

pos.x = pos.x-(size_zoom.x-_old_size.x)*.5
pos.y = pos.y-(size_zoom.y-_old_size.y)*.5

if !can_outside_room {
  pos.x = clamp(pos.x, 0, room_width-size_zoom.x)
  pos.y = clamp(pos.y, 0, room_height-size_zoom.y)  
}

camera_set_view_pos(cam,pos.x,pos.y)
