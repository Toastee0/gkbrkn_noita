table.insert( actions,
{
    id          = "GKBRKN_FORMATION_STACK",
    name 		= "Formation - Stack",
    description = "Cast 3 spells that stack vertically",
    sprite 		= "files/gkbrkn/actions/formation_stack/icon.png",
    sprite_unidentified = "files/gkbrkn/actions/formation_stack/icon.png",
    type 		= ACTION_TYPE_DRAW_MANY,
    spawn_level                       = "0,1,2,3,4,5,6",
    spawn_probability                 = "1,1,1,1,1,1,1",
    price = 160,
    mana = 2,
    action 		= function()
        c.extra_entities = c.extra_entities.."files/gkbrkn/actions/formation_stack/projectile_extra_entity.xml,"
        draw_actions( 3, true );
        add_projectile( "files/gkbrkn/actions/projectile_capture.xml" );
    end,
});