table.insert( actions,
{
    id          = "GKBRKN_SPELL_MERGE",
    name 		= "Spell Merge",
    description = "Cast 2 spells, the first merged with the second",
    sprite 		= "files/gkbrkn/action_spell_merge.png",
    sprite_unidentified = "files/gkbrkn/action_spell_merge.png",
    type 		= ACTION_TYPE_MODIFIER,
    spawn_level                       = "1,2,3,4,5,6",
    spawn_probability                 = "1,1,1,1,1,1",
    price = 190,
    mana = 7,
    action 		= function()
        stack_next_action( 1 );
        draw_actions( 1, true );
    end,
});