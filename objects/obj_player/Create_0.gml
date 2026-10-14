hsp = 0
vsp = 0
spd = 3

right = 0
left = 0
up = 0
down = 0
inputs = function(){
    right = keyboard_check(ord("D"))
    left = keyboard_check(ord("A"))
    up = keyboard_check(ord("W"))
    down = keyboard_check(ord("S"))
}
apply_velocity = function(){
    hsp = (right-left)*spd
    vsp = (down-up)*spd
}