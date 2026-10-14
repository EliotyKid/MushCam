if (!is_keyboard_used_debug_overlay() && keyboard_check_released(vk_space)) {
  set_layout(current_layout == LAYOUT.SINGLE ? LAYOUT.SPLIT_VERTICAL : LAYOUT.SINGLE)
}

if (!is_keyboard_used_debug_overlay() && keyboard_check_released(vk_tab)) {
  set_layout((current_layout + 1) mod 4)
}

update_camera_selection()
update_layout()

if  (!is_undefined(debug_panel))  debug_panel.update()

