// O manager possui as cameras nativas; viewports apenas as exibem.
main_view = 0;
cameras = {};
viewports = [];
screen_size = new Vec2(640, 380);
LAYOUT_SINGLE = 0;
LAYOUT_SPLIT_VERTICAL = 1;
LAYOUT_SPLIT_HORIZONTAL = 2;
LAYOUT_GRID = 3;
current_layout = LAYOUT_SPLIT_VERTICAL;
split = true;
view_enabled = true;

find_viewport_index = function(_id) {
    for (var i = 0; i < array_length(viewports); i++) {
        if (viewports[i].id == _id) return i;
    }
    return -1;
};

get_camera = function(_name) {
    if (!is_string(_name) || !variable_struct_exists(cameras, _name)) return undefined;
    return cameras[$ _name];
};

create_camera = function(_name, _size = new Vec2(640, 380)) {
    if (!is_string(_name) || _name == "" || !is_undefined(get_camera(_name))) return false;
    if (_size.x <= 0 || _size.y <= 0) return false;
    var _cam = camera_create_view(0, 0, _size.x, _size.y);
    var _obj = instance_create_depth(0, 0, -9999, obj_camera, {cam: _cam});
    var _data = {name: _name, obj: _obj, cam: _cam, size: new Vec2(_size.x, _size.y)};
    cameras[$ _name] = _data;
    return _data;
};

// Fit pela altura, preservando o percentual do zoom.
fit_camera = function(_viewport) {
    var _data = get_camera(_viewport.camera_name);
    if (is_undefined(_data) || !instance_exists(_data.obj)) return;
    var _obj = _data.obj;
    var _old_w = camera_get_view_width(_data.cam);
    var _old_h = camera_get_view_height(_data.cam);
    _obj.size = new Vec2(_data.size.y * _viewport.size.x / _viewport.size.y, _data.size.y);
    var _scale = 1 - _obj.zoom_range * _obj.zoom_percent;
    _obj.size_zoom = new Vec2(_obj.size.x * _scale, _obj.size.y * _scale);
    _obj.pos.x -= (_obj.size_zoom.x - _old_w) * 0.5;
    _obj.pos.y -= (_obj.size_zoom.y - _old_h) * 0.7;
    camera_set_view_size(_data.cam, _obj.size_zoom.x, _obj.size_zoom.y);
    camera_set_view_pos(_data.cam, _obj.pos.x, _obj.pos.y);
};

set_layout = function(_layout) {
    if (_layout != LAYOUT_SINGLE && _layout != LAYOUT_SPLIT_VERTICAL
        && _layout != LAYOUT_SPLIT_HORIZONTAL && _layout != LAYOUT_GRID) return false;
    var _selected = [];
    for (var i = 0; i < array_length(viewports); i++) {
        var _vp = viewports[i];
        if (!_vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name))) {
            if (_layout != LAYOUT_SINGLE || _vp.id == main_view) array_push(_selected, _vp);
        }
    }
    var _count = min(array_length(_selected), _layout == LAYOUT_SINGLE ? 1 : (_layout == LAYOUT_GRID ? 8 : 2));
    current_layout = _layout;
    split = _layout != LAYOUT_SINGLE;
    for (var i = 0; i < array_length(viewports); i++) {
        var _vp = viewports[i];
        view_visible[_vp.id] = _vp.overlay && _vp.active && !is_undefined(get_camera(_vp.camera_name));
    }
    var _cols = 1;
    var _rows = 1;
    if (_layout == LAYOUT_SPLIT_VERTICAL) _cols = max(1, _count);
    if (_layout == LAYOUT_SPLIT_HORIZONTAL) _rows = max(1, _count);
    if (_layout == LAYOUT_GRID && _count > 0) {
        _cols = ceil(sqrt(_count));
        _rows = ceil(_count / _cols);
    }
    for (var i = 0; i < _count; i++) {
        var _vp = _selected[i];
        var _col = i mod _cols;
        var _row = i div _cols;
        var _x = floor(_col * screen_size.x / _cols);
        var _y = floor(_row * screen_size.y / _rows);
        _vp.pos = new Vec2(_x, _y);
        _vp.size = new Vec2(floor((_col + 1) * screen_size.x / _cols) - _x,
            floor((_row + 1) * screen_size.y / _rows) - _y);
        view_xport[_vp.id] = _vp.pos.x;
        view_yport[_vp.id] = _vp.pos.y;
        view_wport[_vp.id] = _vp.size.x;
        view_hport[_vp.id] = _vp.size.y;
        view_visible[_vp.id] = true;
    }
    // Uma camera compartilhada usa a proporcao da primeira viewport visivel.
    // Para proporcoes diferentes, use cameras separadas.
    var _fitted = [];
    for (var i = 0; i < array_length(viewports); i++) {
        var _vp = viewports[i];
        if (!view_visible[_vp.id]) continue;
        var _already = false;
        for (var j = 0; j < array_length(_fitted); j++) {
            if (_fitted[j] == _vp.camera_name) _already = true;
        }
        if (!_already) {
            fit_camera(_vp);
            array_push(_fitted, _vp.camera_name);
        }
    }
    return true;
};

create_viewport = function(_id, _camera, _pos = new Vec2(0),
    _size = new Vec2(640, 380), _active = false, _overlay = false) {
    if (_id < 0 || _id > 7 || _id != floor(_id) || find_viewport_index(_id) != -1) return false;
    if (_size.x <= 0 || _size.y <= 0) return false;
    var _data = get_camera(_camera);
    if (is_undefined(_data)) return false;
    var _vp = {id: _id, camera_name: _camera, pos: new Vec2(_pos.x, _pos.y),
        size: new Vec2(_size.x, _size.y), active: _active, overlay: _overlay};
    array_push(viewports, _vp);
    view_xport[_id] = _pos.x;
    view_yport[_id] = _pos.y;
    view_wport[_id] = _size.x;
    view_hport[_id] = _size.y;
    view_set_camera(_id, _data.cam);
    return set_layout(current_layout);
};

viewport_set_active = function(_id, _active = true) {
    var _index = find_viewport_index(_id);
    if (_index == -1) return false;
    viewports[_index].active = _active;
    return set_layout(current_layout);
};
activate_viewport = viewport_set_active;

set_viewport_camera = function(_id, _name) {
    var _index = find_viewport_index(_id);
    var _data = get_camera(_name);
    if (_index == -1 || is_undefined(_data)) return false;
    viewports[_index].camera_name = _name;
    view_set_camera(_id, _data.cam);
    return set_layout(current_layout);
};

camera_activate = function(_name) {
    return set_viewport_camera(main_view, _name);
};

camera_follow = function(_name, _target) {
    var _data = get_camera(_name);
    if (is_undefined(_data) || !instance_exists(_data.obj)) return false;
    if (_target != noone && !instance_exists(_target)) return false;
    _data.obj.object_to_follow = _target;
    _data.obj.mode = CAM_MODE.FOLLOW_OBJECT;
    return true;
};

destroy_viewport = function(_id) {
    var _index = find_viewport_index(_id);
    if (_index == -1) return false;
    view_visible[_id] = false;
    view_set_camera(_id, -1);
    array_delete(viewports, _index, 1);
    return set_layout(current_layout);
};

// Mantem as viewports registradas, desligadas ate receberem outra camera.
destroy_camera = function(_name) {
    var _data = get_camera(_name);
    if (is_undefined(_data)) return false;
    for (var i = 0; i < array_length(viewports); i++) {
        var _vp = viewports[i];
        if (_vp.camera_name == _name) {
            _vp.camera_name = "";
            view_visible[_vp.id] = false;
            view_set_camera(_vp.id, -1);
        }
    }
    if (instance_exists(_data.obj)) instance_destroy(_data.obj);
    camera_destroy(_data.cam);
    variable_struct_remove(cameras, _name);
    return set_layout(current_layout);
};

set_screen_size = function(_width, _height) {
    // Cada celula precisa ter ao menos um pixel, inclusive na grade de 8 views.
    if (_width < 3 || _height < 3) return false;
    screen_size = new Vec2(floor(_width), floor(_height));
    return set_layout(current_layout);
};

// Demonstracao: duas telas e minimapa independente dos layouts.
create_camera("main", new Vec2(320, 380));
create_camera("player2", new Vec2(320, 380));
create_camera("minimap", new Vec2(640, 380));
create_viewport(0, "main", new Vec2(0), new Vec2(320, 380), true);
create_viewport(1, "player2", new Vec2(320, 0), new Vec2(320, 380), true);
var _s = new Vec2(640 / 3, 380 / 3);
create_viewport(2, "minimap", new Vec2(320 - _s.x * 0.5, 10), _s, false, true);

