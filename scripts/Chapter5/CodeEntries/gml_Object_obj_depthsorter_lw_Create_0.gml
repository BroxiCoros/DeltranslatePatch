var _layer = layer_get_id("DEPTHSORT");

if (layer_exists(_layer))
{
    if (room == room_town_mid)
    {
        lay_id = layer_get_id("DEPTHSORT");
        back_id = layer_sprite_get_id(lay_id, "graphic_4D79F7C3");
        layer_sprite_change(back_id, scr_84_get_sprite("spr_festival_arch"));    
    }

    var _elements = layer_get_all_elements(_layer);
    
    for (var i = 0; i < array_length(_elements); i++)
    {
        if (layer_get_element_type(_elements[i]) == 4)
        {
            var _y = layer_sprite_get_y(_elements[i]);
            var _spr = layer_sprite_get_sprite(_elements[i]);
            var _yoff = sprite_get_yoffset(_spr);
            var _depth = 100000 - (((_y * 10) + (sprite_get_height(_spr) * 10)) - (_yoff * 10));
            var _targetLayer = layer_get_id_at_depth(_depth);
            
            if (_targetLayer[0] == -1)
                _targetLayer[0] = layer_create(_depth, "DEPTHSORT_" + string(_depth));
            
            layer_element_move(_elements[i], _targetLayer[0]);
        }
    }
}

instance_destroy();
