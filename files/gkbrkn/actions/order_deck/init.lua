dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua");
table.insert( actions, generate_action_entry(
    "GKBRKN_ORDER_DECK", "order_deck", ACTION_TYPE_MODIFIER,
    "0,1,2,3,4,5,6", "1,1,1,1,1,1,1", 100, 1, -1,
    nil,
    function()
        local before = gun.shuffle_deck_when_empty;
        gun.shuffle_deck_when_empty = false;
        order_deck();
        gun.shuffle_deck_when_empty = before;
        draw_actions( 1, true );
    end
) );
