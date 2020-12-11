dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/mod_settings.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/flags.lua" );
local action_data = dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/action_data.lua" )( true );

local _generate_shop_item = generate_shop_item;
local _generate_shop_wand = generate_shop_wand;

function generate_shop_item( x, y, cheap_item, biomeid_, is_stealable )
    if GameHasFlagRun( FLAGS.WandShopsOnly ) then
        _generate_shop_wand( x, y, cheap_item, biomeid_ );
        local local_wands = EntityGetInRadiusWithTag( x, y, 8, "wand" ) or {};
        for _,wand in pairs( local_wands ) do
            local item_cost = EntityGetFirstComponentIncludingDisabled( wand, "ItemCostComponent" );
            if item_cost ~= nil then
                ComponentSetValue2( item_cost, "stealable", false );
            end
        end
    else
        _generate_shop_item( x, y, cheap_item, biomeid_, is_stealable );
    end

    if GameHasFlagRun( FLAGS.FreeShops ) then
        local generated_items = EntityGetInRadius( x, y, 4 ) or {};
        for _,item in pairs( generated_items ) do
            local item_cost = EntityGetFirstComponentIncludingDisabled( item, "ItemCostComponent" );
            if item_cost ~= nil then
                ComponentSetValue2( item_cost, "cost", 0 );
            end
        end
    end

    if setting_get( FLAGS.ShowSpellDescriptions ) then
        local generated_items = EntityGetInRadius( x, y, 4 ) or {};
        for _,item_entity in pairs( generated_items ) do
            local item = EntityGetFirstComponentIncludingDisabled( item_entity, "ItemComponent" );
            if item ~= nil then
                local item_action = EntityGetFirstComponentIncludingDisabled( item_entity, "ItemActionComponent" );
                if item_action then
                    local action_id = ComponentGetValue2( item_action, "action_id" );
                    local this_action_data = action_data[action_id];
                    if this_action_data then
                        ComponentSetValue2( item, "ui_display_description_on_pick_up_hint", true );
                        ComponentSetValue2( item, "ui_description", this_action_data.description );
                    end
                end
            end
        end
    end
end

function generate_shop_wand( x, y, cheap_item, biomeid_ )
    if GameHasFlagRun( FLAGS.SpellShopsOnly ) then
        -- NOTE: This could be improved by grabbing the biome id to determine if the spells should be stealable
        _generate_shop_item( x, y, cheap_item, biomeid_, true );
        
        if GameHasFlagRun( FLAGS.RebalanceShops ) then
            local generated_items = EntityGetInRadius( x, y, 4 ) or {};
            for _,item in pairs( generated_items ) do
                local item_cost = EntityGetFirstComponentIncludingDisabled( item, "ItemCostComponent" );
                if item_cost ~= nil then
                    ComponentSetValue2( item_cost, "cost", math.pow( ComponentGetValue2( item_cost, "cost" ), 0.8 ) );
                end
            end
        end
    else
        _generate_shop_wand( x, y, cheap_item, biomeid_ );
    end
    if GameHasFlagRun( FLAGS.FreeShops ) then
        local generated_items = EntityGetInRadius( x, y, 4 ) or {};
        for _,item in pairs( generated_items ) do
            local item_cost = EntityGetFirstComponentIncludingDisabled( item, "ItemCostComponent" );
            if item_cost ~= nil then
                ComponentSetValue2( item_cost, "cost", 0 );
            end
        end
    end
end