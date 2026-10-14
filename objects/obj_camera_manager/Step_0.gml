if (keyboard_check_released(vk_space)) {
  set_layout(current_layout == LAYOUT.SINGLE ? LAYOUT.SPLIT_VERTICAL : LAYOUT.SINGLE);
}
if (keyboard_check_released(vk_tab)) {
  set_layout((current_layout + 1) mod 4)
}


