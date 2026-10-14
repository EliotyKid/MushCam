if (keyboard_check_released(vk_space)) {
    set_layout(current_layout == LAYOUT_SINGLE ? LAYOUT_SPLIT_VERTICAL : LAYOUT_SINGLE);
}
if (keyboard_check_released(vk_tab)) {
    set_layout((current_layout + 1) mod 4);
}


