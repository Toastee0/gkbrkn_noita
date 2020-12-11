local entity = GetUpdatedEntityID();

local gold_value = nil;
local components = EntityGetComponent( entity, "VariableStorageComponent" ) or {};
for _,comp_id in pairs( components ) do 
    if ComponentGetValue2( comp_id, "name" ) == "gold_value" then
        gold_value = ComponentGetValueInt( comp_id, "value_int" );
    end
end

if gold_value ~= nil then
    local item = EntityGetFirstComponentIncludingDisabled( entity, "ItemComponent" );
    if item ~= nil then
        ComponentSetValue2( item, "item_name", GameTextGetTranslatedOrNot("$item_goldnugget").." ("..gold_value..")" );
    end

    local ui_info = EntityGetFirstComponentIncludingDisabled( entity, "UIInfoComponent" );
    if ui_info ~= nil then
        ComponentSetValue2( ui_info, "name", GameTextGetTranslatedOrNot("$item_goldnugget").." ("..gold_value..")" );
    end
end