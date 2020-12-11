print( "[goki's things] config file called - reduce these calls as much as possible" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/content/content_types.lua" );
--dofile_once( "mods/gkbrkn_noita/files/gkbrkn/misc/loadouts/helper.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/flags.lua" );
local MISC = dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/options.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/mod_settings.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/helper.lua" );

local has_content_been_cached = false;
local SETTINGS = {
    Version = "c105"
}

local CONTENT_ACTIVATION_TYPE = {
    Immediate = 1,
    Restart = 2,
    NewGame = 3
}

local SETTING_TYPE = {
    Boolean = "boolean",
    Range = "range",
    Input = "input",
    Values = "values",
    Button = "button",
}

local CONTENT = {};
local get_content_flag = function( content_id, content_table )
    if content_table == nil then content_table = CONTENT; end
    local content = content_table[content_id];
    if content ~= nil then
        local content_flag = string.lower("GKBRKN_"..find_content_type( content.type ).id.."_"..content.key);
        return content_flag;
    end
end

local register_content = function( content_table, content_type, key, display_name, description, options, enabled_by_default, deprecated, init_function, development_mode_only, tags, sprite, author, local_content )
    local content_id = #content_table + 1;
    local complete_display_name = display_name or ("missing display name: "..key);
    local complete_description = description or ("missing description: "..key);
    local settings_key = content_type .."_".. key;
    local content = {
        id = content_id,
        type = content_type,
        key = key,
        settings_key = settings_key,
        name = complete_display_name,
        description = complete_description,
        deprecated = deprecated,
        enabled_by_default = enabled_by_default,
        development_mode_only = development_mode_only,
        sprite = sprite,
        author = author or "Unknown",
        local_content = local_content or false,
        enabled = function()
            if not deprecated or setting_get( FLAGS.ShowDeprecatedContent ) == true then
                return setting_get( settings_key ) == true;
            end
            return false;
        end,
        visible = function()
            return true;
        end,
        toggle = function( force )
            local flag = get_content_flag( content_id, content_table );
            local enable = true;
            if force == true then
                enable = true;
            elseif force == false then
                enable = false;
            else
                if setting_get( settings_key ) == true then
                    enable = false;
                else
                    enable = true;
                end
            end
            if enable then
                ModSettingSet( "gkbrkn_noita."..settings_key, true );
            else
                ModSettingSet( "gkbrkn_noita."..settings_key, false );
            end
        end,
        options = options or {},
        init_function = init_function,
        tags = tags or {}
    }
    table.insert( content_table, content );
    return content.id;
end

-- Options Menu Start
    local register_option = function( key, label, tooltip, default, disable, settingType, settingTypeData, activationType, toggleCallback, tags )
        if activationType == nil then
            activationType = CONTENT_ACTIVATION_TYPE.Restart;
        end
        return {
            key = key,
            label = label,
            tooltip = tooltip,
            default = default,
            disable = disable,
            type = settingType,
            type_data = settingTypeData,
            activation_type = activationType,
            toggle_callback = toggleCallback,
            tags = tags or {},
        }
    end

    local register_option_localized = function( key, default, disable, settingType, settingTypeData, activationType, toggleCallback, tags )
        if key ~= nil then
            return register_option( key, "$option_name_"..key, "$option_desc_"..key, default, disable, settingType, settingTypeData, activationType, toggleCallback, tags );
        else
            print( "key not found "..tostring(default).."/"..settingType );
        end
    end

    local register_boolean_option_localized = function( key, default, disable, activationType, toggleCallback, tags )
        return register_option_localized( key, default, disable, SETTING_TYPE.Boolean, {}, activationType, toggleCallback, tags );
    end

    local register_range_option_localized = function( key, default, min, max, disable, value_callback, text_callback, activationType, toggleCallback, tags )
        return register_option_localized( key, default, disable, SETTING_TYPE.Range, { min = min, max = max, value_callback = value_callback, text_callback = text_callback }, activationType, toggleCallback, tags );
    end

    local register_input_option_localized = function( key, default, disable, activationType, toggleCallback, tags )
        return register_option_localized( key, default, disable, SETTING_TYPE.Input, {}, activationType, toggleCallback, tags );
    end

    local register_button_option_localized = function( key, click_callback )
        return register_option_localized( key, nil, nil, SETTING_TYPE.Button, { click_callback } );
    end

    local register_option_tab = function( key, name, ... )
        return {
            tab_key = key,
            tab_label = name,
            settings = {...}
        }
    end

    local register_option_tab_localized = function( key, ... )
        return register_option_tab( key, "$option_tab_name_"..key, ... );
    end

    local register_option_group = function( name, custom_callback, ... )
        return {
            group_label = name,
            custom_callback = custom_callback,
            settings = {...}
        }
    end

    local register_option_group_localized = function( key, custom_callback, ... )
        return register_option_group( "$option_group_name_"..key, custom_callback, ... );
    end

    local OPTIONS = {
        register_option_tab_localized( "gkbrkn_options",
            register_option_group_localized( "gkbrkn_mod_core", nil,
                register_boolean_option_localized( MISC.ManageExternalContent.EnabledFlag, true, false, CONTENT_ACTIVATION_TYPE.Restart ),
                register_boolean_option_localized( MISC.ShowModTips.EnabledFlag, true, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.AutoHide.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( FLAGS.ShowDeprecatedContent, false, false, CONTENT_ACTIVATION_TYPE.Restart ),
                register_boolean_option_localized( FLAGS.DebugMode, false, false, CONTENT_ACTIVATION_TYPE.Restart )
            ),
            register_option_group_localized( "gkbrkn_hero_mode", nil,
                register_boolean_option_localized( MISC.HeroMode.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true, ultimate_challenge = true, hero_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.HeroMode.OrbsDifficultyFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, function( enabled )
                    if not enabled then RemoveFlagPersistent( MISC.HeroMode.CarnageDifficultyFlag ); end
                end, {goki_thing = true, ultimate_challenge = true, hero_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.HeroMode.DistanceDifficultyFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, function( enabled )
                    if not enabled then RemoveFlagPersistent( MISC.HeroMode.CarnageDifficultyFlag ); end
                end, {goki_thing = true, ultimate_challenge = true, hero_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.HeroMode.CarnageDifficultyFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, function( enabled )
                    if enabled then
                        AddFlagPersistent( MISC.HeroMode.OrbsDifficultyEnabled );
                        AddFlagPersistent( MISC.HeroMode.DistanceDifficultyEnabled );
                    end
                end, {carnage = true} )
            ),
            register_option_group_localized( "gkbrkn_champion_enemies", nil,
                register_boolean_option_localized( MISC.ChampionEnemies.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true, ultimate_challenge = true, champions_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.ChampionEnemies.SuperChampionsFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true, ultimate_challenge = true, champions_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.ChampionEnemies.AlwaysChampionsFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true, ultimate_challenge = true, champions_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.ChampionEnemies.MiniBossesFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true, ultimate_challenge = true, champions_mode = true, carnage = true} ),
                register_boolean_option_localized( MISC.ChampionEnemies.ValourFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {carnage = true} ),
                register_boolean_option_localized( MISC.ChampionEnemies.ShowIconsFlag, true, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true, ultimate_challenge = true, champions_mode = true, carnage = true} )
            ),
            register_option_group_localized( "gkbrkn_random_start", nil,
                register_boolean_option_localized( MISC.RandomStart.RandomPrimaryWandFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {random_starts = true} ),
                register_boolean_option_localized( MISC.RandomStart.RandomSecondaryWandFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {random_starts = true} ),
                register_boolean_option_localized( MISC.RandomStart.RandomExtraWandFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame ),
                register_boolean_option_localized( MISC.RandomStart.CustomWandGenerationFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame ),
                register_boolean_option_localized( MISC.RandomStart.RandomCapeColorFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {random_starts = true} ),
                register_boolean_option_localized( MISC.RandomStart.RandomHealthFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame ),
                register_boolean_option_localized( MISC.RandomStart.RandomFlaskFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {random_starts = true} ),
                register_range_option_localized( MISC.RandomStart.RandomPerksFlag, 0, 0, 100, 0,
                function( value ) return math.floor( value ); end,
                function( value ) return (value == 0 and "Disabled") or (value == 1 and (value.." perk")) or (value.." perks") end,
                CONTENT_ACTIVATION_TYPE.NewGame, nil, {random_starts = true} )
            ),
            register_option_group_localized( "gkbrkn_gold", nil,
                register_boolean_option_localized( MISC.GoldPickupTracker.ShowMessageFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.GoldPickupTracker.ShowTrackerFlag, true, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.GoldDecay.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.PersistentGold.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.AutoPickupGold.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.CombineGold.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate )
            ),
            register_option_group_localized( "gkbrkn_wands", nil,
                register_boolean_option_localized( MISC.LegendaryWands.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.LooseSpellGeneration.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.AlternativeWandGeneration.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, function( enabled )
                    if enabled then
                        RemoveFlagPersistent( MISC.ChaoticWandGeneration.EnabledFlag );
                        RemoveFlagPersistent( MISC.ExtendedWandGeneration.EnabledFlag );
                    end
                end ),
                register_boolean_option_localized( MISC.ChaoticWandGeneration.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, function( enabled )
                    if enabled then
                        RemoveFlagPersistent( MISC.ExtendedWandGeneration.EnabledFlag );
                        RemoveFlagPersistent( MISC.AlternativeWandGeneration.EnabledFlag );
                    end
                end ),
                register_boolean_option_localized( MISC.ExtendedWandGeneration.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, function( enabled )
                    if enabled then
                        RemoveFlagPersistent( MISC.ChaoticWandGeneration.EnabledFlag );
                        RemoveFlagPersistent( MISC.AlternativeWandGeneration.EnabledFlag );
                    end
                end, {goki_thing = true} ),
                register_boolean_option_localized( MISC.NoPregenWands.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.PassiveRecharge.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate )
            ),
            register_option_group_localized( "gkbrkn_loadouts", nil,
                register_boolean_option_localized( MISC.Loadouts.ManageFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true,loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.CapeColorFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.PlayerSpritesFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.SelectableClassesIntegrationFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.ClassyFrameworkIntegrationFlag, false, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {loadouts = true} ),
                register_boolean_option_localized( MISC.Loadouts.UnlockLoadouts, false, false, CONTENT_ACTIVATION_TYPE.NewGame )
            ),
            register_option_group_localized( "gkbrkn_invincibility_frames", nil,
                register_range_option_localized( MISC.InvincibilityFrames.Duration, 0, 0, 60, 0,
                    function( value ) return math.floor( value ); end,
                    function( value ) return (value == 0 and "Disabled") or (value == 1 and (value.." frame")) or (value.." frames") end,
                    CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.InvincibilityFrames.FlashingFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate )
            ),
            register_option_group_localized( "gkbrkn_heal_new_health", nil,
                register_boolean_option_localized( MISC.HealOnMaxHealthUp.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.HealOnMaxHealthUp.FullHealFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate )
            ),
            register_option_group_localized( "gkbrkn_less_particles", nil,
                register_boolean_option_localized( MISC.LessParticles.PlayerProjectilesFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.LessParticles.OtherStuffFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.LessParticles.DisableCosmeticsFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate )
            ),
            register_option_group_localized( "gkbrkn_health_bars", nil,
                register_boolean_option_localized( MISC.HealthBars.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.HealthBars.PrettyHealthBarsFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} )
            ),
            register_option_group_localized( "gkbrkn_ui", nil,
                register_boolean_option_localized( MISC.ShowEntityNames.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                --register_boolean_option_localized( MISC.ShowPerkDescriptions.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.ShowDamageNumbers.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.ShowFPS.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.Badges.EnabledFlag, true, false, CONTENT_ACTIVATION_TYPE.NewGame, nil, {goki_thing = true} )
            ),
            register_option_group_localized( "gkbrkn_target_dummy", nil,
                register_boolean_option_localized( MISC.TargetDummy.EnabledFlag, true, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.TargetDummy.AllowEnvironmentalDamage, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_button_option_localized( "gkbrkn_spawn_target_dummy", function( left_click, right_click )
                    if left_click == true then
                        local player = EntityGetWithTag( "player_unit")[1];
                        if player then
                            local x,y = EntityGetTransform( player );
                            EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/dummy_target.xml", x, y - 10 );
                        end
                    end
                end ),
                register_button_option_localized( "gkbrkn_spawn_boss_target_dummy", function( left_click, right_click )
                    if left_click == true then
                        local player = EntityGetWithTag( "player_unit")[1];
                        if player then
                            local x,y = EntityGetTransform( player );
                            EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/dummy_target_final.xml", x, y - 10 );
                        end
                    end
                end )
            ),
            register_option_group_localized( "gkbrkn_misc", nil,
                register_boolean_option_localized( MISC.PackShops.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart ),
                register_boolean_option_localized( MISC.RainbowProjectiles.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.QuickSwap.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.ChestsContainPerks.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.SlotMachine.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.ShopReroll.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                --register_boolean_option_localized( MISC.Events.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate ),
                register_boolean_option_localized( MISC.FixedCamera.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} ),
                register_boolean_option_localized( MISC.FixedCamera.OldBehaviourFlag, false, false, CONTENT_ACTIVATION_TYPE.Restart, nil, nil ),
                register_boolean_option_localized( MISC.RemoveEditPrompt.EnabledFlag, false, false, CONTENT_ACTIVATION_TYPE.Immediate, nil, {goki_thing = true} )
            )
        ),
    }
-- Options Menu End

local cache_content = function()
    local content_types_id_cache = {};
    for _,content_type in pairs( content_types ) do
        content_types_id_cache[ content_type ] = ( content_types_id_cache[ content_type ] or {} );
        local content_filepath = content_type.shared_content_filepath or content_type.content_filepath;
        dofile( content_filepath );
        local content_table = _G[content_type.shared_content_table] or _G[content_type.content_table];
        print( "[goki's things] caching "..#(content_table or {}).." "..content_type.short_name );
        local content_cache = content_type.cache_table.." = {};";
        for _,cache_content in pairs(content_table or {}) do
            local keys = { {"id"}, {"name","ui_name"}, {"description","ui_description"}, {"author"}, {"item_path"}, {"deprecated"}, {"local_content"}, {"sprite","perk_icon"}, {"enabled_by_default"} };
            local content_metadata = "{";
            if content_types_id_cache[ content_type ][ cache_content.id ] == nil then
                content_types_id_cache[ content_type ][ cache_content.id ] = true;
                for _,key_groups in pairs(keys) do
                    for _,key in pairs(key_groups) do
                        local value = cache_content[key];
                        if value ~= nil then
                            if type( value ) == "string" then
                                value = "\""..value:gsub("\n","\\n").."\"";
                            elseif type( value ) == "boolean" then
                                value = tostring( value );
                            end
                            content_metadata = content_metadata..key.." = "..(tostring(value) or "nil")..",";
                            break;
                        end
                    end
                end
                if cache_content.tags then
                    content_metadata = content_metadata.. "tags={";
                    for k,v in pairs( cache_content.tags ) do
                        content_metadata = content_metadata..k.."="..tostring(v)
                    end
                    content_metadata = content_metadata.. "}";
                end
                content_metadata = content_metadata.."}";
                content_cache = content_cache .. "\r\ntable.insert("..content_type.cache_table..","..content_metadata..");"
            end
        end
        ModTextFileSetContent( content_type.cache_filepath, content_cache );
    end

    has_content_been_cached = true;
    print( "[goki's things] content cached" );
end

-- NOTE first_parse should only ever be true ONE time in goki's things. do not use it
-- TODO this needs to be handled by each content type itself
local parse_content = function( first_parse, force_cached, content_table )
    if content_table == nil then content_table = CONTENT; end
    local load_cached = force_cached;
    if load_cached == nil then
        load_cached = has_content_been_cached or GameHasFlagRun( "gkbrkn_content_cached" );
    end
    if load_cached then
        for _,content_type_data in pairs( content_types ) do dofile( content_type_data.cache_filepath ); end
    else
        for _,content_type_data in pairs( content_types ) do dofile( content_type_data.shared_content_filepath or content_type_data.content_filepath ); end
    end

    for _,content_type_data in pairs( content_types ) do
        local index = content_type_data.id;
        local starting_perk_string = "starting_perks = {};\r\n";
        local content_type_table = _G[content_type_data.shared_content_table] or _G[content_type_data.content_table] or _G[content_type_data.cache_table];
        if content_type_table then
            print( "[goki's things] registering "..#content_type_table.." "..content_type_data.short_name.. ( ( load_cached and content_type_data.cache_table and " cached" ) or "") );
            for content_index,content_data in pairs( content_type_table ) do
                local options = content_data.options or {};
                options.index = content_index;
                options.author = content_data.author;
                options.menu_note = "("..GameTextGetTranslatedOrNot(content_data.author or "Unknown")..")";
                if id == "loadout" then
                    options.display_name = string_trim(GameTextGetTranslatedOrNot(content_data.name):gsub("TYPE",""))
                end
                local content_name = content_data.ui_name or content_data.name;
                local content_description = content_data.ui_description or content_data.description;
                local content_enabled_by_default = false;
                if content_data.enabled_by_default ~= nil then
                    content_enabled_by_default = content_data.enabled_by_default or false;
                elseif index == "action" or index == "perk" or index == "champion_type" or index == "legendary_wand" or index == "loadout" or index == "pack" then
                    content_enabled_by_default = true;
                end

                local content = nil;
                local content_id = nil;
                if index == "perk" then
                    options.preview_callback = function( player_entity )
                        dofile_once( "data/scripts/perks/perk.lua" );
                        local perk_entity = perk_spawn( x, y, string.upper( content_data.id ) );
                        if perk_entity ~= nil then
                            perk_pickup( perk_entity, player_entity, EntityGetName( perk_entity ), false, false );
                            GamePlaySound( "data/audio/Desktop/event_cues.bank", "event_cues/shop_item/create", GameGetCameraPos() );
                        end
                    end
                elseif index == "action" then
                    options.preview_callback = function( player_entity )
                        local x, y = EntityGetTransform( player_entity );
                        local action_entity = CreateItemActionEntity( string.upper( content_data.id ), x, y );
                        GamePlaySound( "data/audio/Desktop/event_cues.bank", "event_cues/shop_item/create", GameGetCameraPos() );
                    end
                elseif index == "legendary_wand" then
                    options.preview_callback = function( player_entity )
                        dofile( "mods/gkbrkn_noita/files/gkbrkn/content/legendary_wands.lua" );
                        dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/wands.lua" );
                        local x, y = EntityGetTransform( player_entity );
                        local wand = EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/legendary_wands/legendary_wand.xml", x, y );
                        initialize_legendary_wand( wand, x, y, nil, find_legendary_wand( content_data.id ) );
                        GamePlaySound( "data/audio/Desktop/event_cues.bank", "event_cues/shop_item/create", GameGetCameraPos() );
                    end
                elseif index == "item" then
                    if content_data.item_path then
                        options.preview_callback = function( player_entity )
                            local x, y = EntityGetTransform( player_entity );
                            EntityLoad( content_data.item_path, x, y );
                            GamePlaySound( "data/audio/Desktop/event_cues.bank", "event_cues/shop_item/create", GameGetCameraPos() );
                        end
                    end
                elseif index == "loadout" then
                    options.preview_callback = function( player_entity )
                        dofile( "mods/gkbrkn_noita/files/gkbrkn/content/loadouts.lua" );
                        dofile_once( "mods/gkbrkn_noita/files/gkbrkn/misc/loadouts/helper.lua" );
                        handle_loadout( player_entity, find_loadout( content_data.id ) );
                        GamePlaySound( "data/audio/Desktop/event_cues.bank", "event_cues/shop_item/create", GameGetCameraPos() );
                    end
                end
                content_id = register_content( content_table, index, content_data.id, content_name, content_description, options, content_enabled_by_default, content_data.deprecated, content_data.init_function, content_data.development_mode_only, content_data.tags, content_data.perk_icon or content_data.sprite, content_data.author, content_data.local_content );
                content = content_table[ content_id ];
                if index == "starting_perk" and content then
                    --local starting_perk_content_id = register_content( content_table, "starting_perk", content_data.id, content_name, content_description, options, false, content_data.deprecated )
                    if content.enabled() then
                        starting_perk_string = starting_perk_string .. "table.insert( starting_perks, \""..content_data.id.."\" );\r\n"
                    end
                end
            end
            if index == "starting_perk" and first_parse then
                if #starting_perk_string ~= 0 then
                    ModTextFileSetContent( "mods/gkbrkn_noita/files/gkbrkn/content/starting_perks.lua", starting_perk_string );
                end
            end
        else
        print( "[goki's things] no cache or content table found for "..index );
        end
    end
end

-- This function is to be called once by init.lua at the very latest it can be to ensure that disabled content is properly removed from their files
local disable_content = function( content_table )
    print( "[goki's things] disable content" );
    if content_table == nil then content_table = CONTENT; end
    local disable_strings = {};
    for i = #content_table, 1, -1 do
        local content = content_table[i];
        for _,content_type in pairs( content_types ) do
            if content.type == content_type.id then
                if content.enabled() == false and ( content.local_content == true or setting_get( MISC.ManageExternalContent.EnabledFlag ) == true ) then
                    disable_strings[ content_type.id ] = content_type.content_disable_callback( content, (disable_strings[ content_type.id ] or "") );
                end
            end
        end
    end
    for _,content_type in pairs( content_types ) do
        if #(disable_strings[ content_type.id ] or "") > 0 then
            local disable_filepath = "mods/gkbrkn_noita/files/gkbrkn/scratch/disable_"..content_type.id..".lua";
            ModTextFileSetContent( disable_filepath, disable_strings[ content_type.id ] );
            ModLuaFileAppend( content_type.content_filepath, disable_filepath );
        end
    end
end

GKBRKN_CONFIG = {
    SETTINGS = SETTINGS,
    CONTENT_ACTIVATION_TYPE = CONTENT_ACTIVATION_TYPE,
    CONTENT = CONTENT,
    OPTIONS = OPTIONS,
    get_content = get_content,
    get_content_flag = get_content_flag,
    parse_content = parse_content,
    cache_content = cache_content,
    disable_content = disable_content,
    register_option = register_option,
    register_option_localized = register_option_localized,
    register_boolean_option_localized = register_boolean_option_localized,
    register_range_option_localized = register_range_option_localized,
    register_input_option_localized = register_input_option_localized,
    register_button_option_localized = register_button_option_localized,
    register_option_tab = register_option_tab,
    register_option_tab_localized = register_option_tab_localized,
    register_option_group = register_option_group,
    register_option_group_localized = register_option_group_localized,
};