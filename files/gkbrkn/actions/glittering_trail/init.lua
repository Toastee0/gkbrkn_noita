dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
table.insert( actions, generate_action_entry(
    "GKBRKN_GLITTERING_TRAIL", "glittering_trail", ACTION_TYPE_MODIFIER,
    "0,1,2,3,4,5,6", "1,1,1,1,1,1,1", 120, 10, -1,
    nil,
    function()
        c.extra_entities = c.extra_entities.."mods/gkbrkn_noita/files/gkbrkn/actions/glittering_trail/trail_builder.xml,";
        draw_actions( 1, true );
    end
) );