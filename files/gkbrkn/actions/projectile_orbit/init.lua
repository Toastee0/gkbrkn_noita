table.insert( actions,
{
    id          = "GKBRKN_PROJECTILE_ORBIT",
    name 		= "Projectile Orbit",
    description = "Casts a spell that other spells cast at the same time will orbit",
    sprite 		= "files/gkbrkn/actions/projectile_orbit/icon.png",
    sprite_unidentified = "files/gkbrkn/actions/projectile_orbit/icon.png",
    type 		= ACTION_TYPE_MODIFIER,
    spawn_level                       = "0,1,2,3,4,5,6",
    spawn_probability                 = "1,1,1,1,1,1,1",
    price = 100,
    action 		= function()
        c.extra_entities = c.extra_entities .. "files/gkbrkn/actions/projectile_orbit/projectile_extra_entity.xml,";
        draw_actions( 1, true );
    end,
});
