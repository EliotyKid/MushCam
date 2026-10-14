hsp = 0
vsp = 0
spd = 3

right = 0
left = 0
up = 0
down = 0
inputs = function(){
    right = keyboard_check(vk_right)
    left = keyboard_check(vk_left)
    up = keyboard_check(vk_up)
    down = keyboard_check(vk_down)
}
apply_velocity = function(){
    hsp = (right-left)*spd
    vsp = (down-up)*spd
}

image_blend = c_aqua

