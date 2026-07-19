frame = 1;
shade_assets = [spr_festival_ferriswheel_1, spr_festival_flowerking_cart_empty, spr_festival_flowerking_cart_flowers_1, spr_festival_flowerking_cart_flowers_2, spr_festival_flowerking_cart_flowers_3, spr_festival_flowerking_cart_flowers_3_roofless, spr_festival_flowerking_truck_figure, spr_festival_flowerking_truck_nofigure, spr_festival_flowers_daisies, spr_festival_flowers_hydrangea, spr_festival_flowers_tulips, spr_festival_foodstand_front, spr_festival_foodstand_back, spr_festival_sans_stall, spr_festival_sunflowers_basket_1, spr_festival_sunflowers_basket_2, spr_festival_takoyaki_1, spr_festival_temtable, spr_festival_flags_stick_mid, scr_84_get_sprite("spr_festival_arch"), spr_festival_archback, bg_building_blookhouse, spr_town_strength_tester, spr_festival_church_props_pumpkin, spr_festival_church_props_pumpkin_big, spr_festival_church_props_pumpkin_med, spr_lw_fix_tape, scr_84_get_sprite("spr_lw_fix_barricade")];

function set_assets_shadow_frame(arg0)
{
    for (var i = 0; i < array_length(shade_assets); i++)
    {
        var found_asset_array = findsprite_all(shade_assets[i]);
        
        if (array_length(found_asset_array) > 0)
        {
            for (var ii = 0; ii < array_length(found_asset_array); ii++)
                layer_sprite_index(found_asset_array[ii], arg0);
        }
    }
}

set_assets_shadow_frame(frame);
