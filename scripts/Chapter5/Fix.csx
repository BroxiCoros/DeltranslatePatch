#load "../BaseFix.csx"

#region Отрисовка доп. спрайтов в контроллере

{
    var room = Data.Rooms.ByName("room_town_mid");

    foreach (var layer in room.Layers)
    {
        if (layer.LayerName.Content == "TILES_Depth_993000")
        {
            layer.LayerDepth = 995400;
            break;
        }
    }
    foreach (var layer in room.Layers)
    {
        if (layer.LayerName.Content == "ASSETS_Evening_Trees_overlay_back")
        {
            layer.LayerDepth = 995350;
            break;
        }
    }
}

string room_code = @"";
foreach (var room in jsonRooms)
{
    room_code += string.Format("if (room == {0}) {{\n", room.Key);

    var new_layers = new List<string>();
    foreach (var spr in jsonRooms[room.Key])
    {
        if (spr["type"] == "tile" && !new_layers.Contains(spr["layer"])) {
            new_layers.Add(spr["layer"]);
            room_code += $@" 
            layer_create({int.Parse(spr["depth"]) - 1}, ""{spr["layer"]}tr"");
            ";
        }
    }

    foreach (var spr in jsonRooms[room.Key])
    {
        if (spr["type"] == "tile")
        {
            {
                room_code += $@"
                layer_sprite_create(""{spr["layer"]}tr"", {spr["x"]}, {spr["y"]}, scr_84_get_sprite(""{spr["sprite"]}""))
                ";
            }
        } else
        if (spr["type"] == "sprite")
        {
            
            room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_sprite_get_id(lay_id, ""{spr["spr_name"]}"");
            layer_sprite_change(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
        } else
        if (spr["type"] == "marker")
        {
            room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_sprite_get_id(lay_id, ""{spr["spr_name"]}"");
            layer_sprite_change(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
            room_code += $@"
            with (obj_marker)
                if (sprite_index == {spr["sprite"]})
                    sprite_index = scr_84_get_sprite(""{spr["sprite"]}"");
            ";
            room_code += $@"
            with (obj_marker_fancy)
                if (sprite_index == {spr["sprite"]})
                    sprite_index = scr_84_get_sprite(""{spr["sprite"]}"");
            ";
        } else
        if (spr["type"] == "plat")
        {
            room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_sprite_get_id(lay_id, ""{spr["spr_name"]}"");
            layer_sprite_change(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
            room_code += $@"
            with (obj_plat_asset)
                if (sprite_index == {spr["sprite"]})
                    sprite_index = scr_84_get_sprite(""{spr["sprite"]}"");
            ";
        } else
        if (spr["type"] == "background")
        {
            room_code += $@"
            var lay_id = layer_get_id(""{spr["layer"]}"");
            var back_id = layer_background_get_id(lay_id);
            layer_background_sprite(back_id, scr_84_get_sprite(""{spr["sprite"]}""));
            ";
        }

        IncrementProgress();
        UpdateProgressValue(GetProgress());
    }

    room_code += "}\n";
}

room_code += @"
if (room == room_town_church) {
    with (obj_marker) {
        if (sprite_index == spr_festival_church_base) {
            sprite_index = scr_84_get_sprite(""spr_festival_church_base"");
        }
    }
}
";

AddNewEvent("obj_gamecontroller", EventType.Other, (uint)EventSubtypeOther.RoomStart, room_code);

#endregion

await SaveEntries();