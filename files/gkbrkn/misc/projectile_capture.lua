dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/constants.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua" );

local half_pi = math.pi * 0.5;

function EntitiesAverageMemberList( entities, component_type, member_list, rounded, overrides )
    local averages = {};
    local overridden = {};
    for _,member in pairs(member_list) do
        averages[member] = 0;
    end
    local components = {};
    for _,entity in pairs(entities) do
        for _,component in pairs( EntityGetComponent( entity, component_type ) or {} ) do
            table.insert( components, component );
        end
    end
    for _,component in pairs( components ) do
        local members = ComponentGetMembers( component );
        for _,member in pairs(member_list) do
            averages[member] = averages[member] + members[member];
        end
        -- iterate through all members in overrides, if any entities in the list have the value in the overrides, apply it to all entities
        for member,value in pairs( overrides or {} ) do
            if overridden[member] == nil and members[member] == value then
                overridden[member] = value;
            end
        end
    end
    for _,member in pairs(member_list) do
        averages[member] = averages[member] / #entities;
        if ( rounded or {} )[member] ~= nil then
            averages[member] = math.floor( averages[member] + 0.5 );
        end
    end
    for _,component in pairs( components ) do
        for _,member in pairs( member_list ) do
            ComponentSetValue2( component, member, averages[member] );
        end
        for member,value in pairs( overridden ) do
            ComponentSetValue2( component, member, value );
        end
    end
end

function mean_angle ( angles, magnitudes )
    local sum_sin, sum_cos, sum_magnitude = 0, 0, 0;
    for i, magnitude in pairs( magnitudes ) do
        sum_magnitude = sum_magnitude + magnitude;
    end
    for i, angle in pairs( angles ) do
        local magnitude = magnitudes[i];
        local proportion = magnitude / sum_magnitude;
        -- no velocities
        if proportion ~= proportion then
            proportion = 0;
        end
        sum_sin = sum_sin + math.sin( angle ) * proportion;
        sum_cos = sum_cos + math.cos( angle ) * proportion;
    end
    return math.atan2( sum_sin, sum_cos );
end

local get_tag_groups = function( id, projectiles )
    -- Get the projectiles we shot in order so we know separators come first
    table.sort( projectiles, function( a, b ) return a < b; end );
    local groups = {};
    local group = nil;
    local back_projectiles = {};
    for _,projectile in ipairs( projectiles ) do
        if EntityHasNamedVariable( projectile, id.."_separator" ) then
            EntityRemoveNamedVariable( projectile, id.."_separator" );
            for k,v in pairs( EntityGetComponent( projectile, "ProjectileComponent" ) or {} ) do
                ComponentSetValue2( v, "damage", 0 );
                ComponentSetValue2( v, "on_death_explode", false );
                ComponentSetValue2( v, "on_lifetime_out_explode", false );
                ComponentSetValue2( v, "collide_with_entities", false );
                ComponentSetValue2( v, "collide_with_world", false );
                ComponentSetValue2( v, "lifetime", 300 );
            end
            EntityKill( projectile );
            table.insert( groups, group );
            group = {};
            for k,v in pairs( back_projectiles ) do
                table.insert( group, v );
            end
            back_projectiles = {};
        elseif EntityHasNamedVariable( projectile, id ) and not EntityHasNamedVariable( projectile, "gkbrkn_no_projectile_capture" ) then
            EntityRemoveNamedVariable( projectile, id );
            if group ~= nil then
                table.insert( group, projectile );
            else
                table.insert( back_projectiles, projectile );
            end
        end
    end
    table.insert( groups, group );
    return groups;
end

TAG_MAPPING = TAG_MAPPING or {
    ["gkbrkn_spell_merge"] = function( groups )
        for _,group in pairs( groups ) do
            local leader = group[1];
            
            EntitiesAverageMemberList( group, "ProjectileComponent", {
                "lifetime", "bounces_left", "bounce_energy",
                "knockback_force", "ragdoll_force_multiplier", "camera_shake_when_shot",
                "angular_velocity", "friction", "die_on_low_velocity_limit"
            },
            { bounces_left = true },
            { bounce_at_any_angle=true, bounce_always=true, die_on_low_velocity=false } );
            EntitiesAverageMemberList( group, "VelocityComponent", { 
                "gravity_x", "gravity_y", "mass", "air_friction", "terminal_velocity"
            } );
            local average_velocity_magnitude = 0;
            local angles = {};
            local magnitudes = {};
            for i,projectile_entity in pairs( group ) do
                local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
                local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
                local angle = math.atan2( vy, vx );
                local magnitude = math.sqrt(vx * vx + vy * vy);
                average_velocity_magnitude = average_velocity_magnitude + magnitude;

                -- ignore projectiles that don't move
                table.insert( angles, angle );
                table.insert( magnitudes, magnitude );

            end
            local average_angle = mean_angle( angles, magnitudes );
            average_velocity_magnitude = average_velocity_magnitude / #group;
            for i,projectile_entity in pairs( group ) do
                if projectile_entity == leader then
                    local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
                    local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
                    local angle = math.atan2( vy, vx );
                    ComponentSetValue2( velocity, "mVelocity", math.cos( average_angle ) * average_velocity_magnitude, math.sin( average_angle ) * average_velocity_magnitude );
                else
                    EntitySetVariableString( projectile_entity, "gkbrkn_spell_merge_soft_parent", tostring( leader ) );
                end
                EntityAddComponent( projectile_entity, "LuaComponent", {
                    execute_on_added="1",
                    execute_every_n_frame="1",
                    script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/spell_merge/projectile_update.lua",
                });
            end
        end
    end,
    ["gkbrkn_projectile_gravity_well"] = function( groups )
        for _,group in pairs( groups ) do
            local previous_projectile = nil;
            local leader = nil;
            for i,projectile_entity in pairs( group ) do
                if previous_projectile ~= nil then
                    EntitySetVariableString( projectile_entity, "gkbrkn_projectile_gravity_well_soft_parent", tostring( leader ) );
                    local leader_projectile = EntityGetFirstComponent( leader, "ProjectileComponent" );
                    local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
                    if projectile ~= nil and leader_projectile ~= nil then
                        local leader_lifetime = ComponentGetValue2( leader_projectile, "lifetime" );
                        local projectile_lifetime = ComponentGetValue2( projectile, "lifetime" );
                        ComponentSetValue2( projectile, "lifetime", leader_lifetime + projectile_lifetime );
                        EntityAddComponent2( projectile_entity, "LuaComponent", {
                            execute_on_added = true,
                            execute_every_n_frame = 1,
                            script_source_file = "mods/gkbrkn_noita/files/gkbrkn/actions/projectile_gravity_well/projectile_update.lua",
                        } );
                    end
                else
                    leader = projectile_entity;
                    local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
                    if velocity ~= nil then
                        ComponentSetValue2( velocity, "gravity_y", 0 )
                        ComponentSetValue2( velocity, "air_friction", 0 )
                    end
                end
                previous_projectile = projectile_entity;
            end
        end
    end,
    ["gkbrkn_projectile_orbit"] = function( groups )
        for _,group in pairs( groups ) do        
            local leader = group[1];
            local velocity = EntityGetFirstComponent( leader, "VelocityComponent" );
            if velocity ~= nil then
                local velocity_x, velocity_y = ComponentGetValue2( velocity, "mVelocity" );
                local previous_projectile = nil;
                local leader = nil;
                for i,projectile in pairs( group ) do
                    if previous_projectile ~= nil then
                        EntitySetVariableString( projectile, "gkbrkn_projectile_orbit_soft_parent", tostring(leader) );
                        EntityAddComponent( projectile, "VariableStorageComponent", {
                            _tags="gkbrkn_orbit",
                            name="gkbrkn_orbit",
                            value_string=tostring(#group);
                            value_int=tostring(i-1);
                        } );
                        EntityAddComponent( projectile, "LuaComponent", {
                            execute_on_added="1",
                            execute_every_n_frame="1",
                            script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/projectile_orbit/projectile_update.lua",
                        });
                        if projectile ~= leader then
                            local velocity = EntityGetFirstComponent( projectile, "VelocityComponent" );
                            local velocity_x, velocity_y = ComponentGetValue2( velocity, "mVelocity" );

                            local leader_projectile = EntityGetFirstComponent( leader, "ProjectileComponent" );
                            local projectile = EntityGetFirstComponent( projectile, "ProjectileComponent" );
                            if projectile ~= nil and leader_projectile ~= nil then
                                local leader_lifetime = ComponentGetValue2( leader_projectile, "lifetime" );
                                local projectile_lifetime = ComponentGetValue2( projectile, "lifetime" );
                                ComponentSetValue2( projectile, "lifetime", math.max( leader_lifetime, projectile_lifetime ) );
                            end
                        end
                    else
                        leader = projectile;
                    end
                    previous_projectile = projectile;
                end
            end
        end
    end,
    ["gkbrkn_formation_shield"] = function( groups )
        local now = GameGetFrameNum();
        for _,group in pairs( groups ) do        
            for i,projectile_entity in pairs( group ) do
                local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
                if projectile then
                    local leader = ComponentGetValue2( projectile, "mWhoShot" );
                    local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
                    if velocity then
                        ComponentSetValue2( velocity, "mVelocity", 0, 0 );
                    end
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_shield_soft_parent", leader );
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_shield_total", #group );
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_shield_index", i-1 );
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_shield_radius", 12 + #group * 2 );
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_shield_frame", now );
                    EntityAddComponent( projectile_entity, "LuaComponent", {
                        execute_on_added="1", execute_every_n_frame="1",
                        script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/formation_shield/projectile_update.lua",
                    } );
                end
            end
        end
    end,
    ["gkbrkn_formation_sword"] = function( groups )
        local now = GameGetFrameNum();
        for _,group in pairs( groups ) do        
            for i,projectile_entity in pairs( group ) do
                local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
                if projectile then
                    local leader = ComponentGetValue2( projectile, "mWhoShot" );
                    --local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
                    --if velocity then
                    --    ComponentSetValue2( velocity, "mVelocity", 0, 0 );
                    --end
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_sword_soft_parent", leader );
                    EntitySetVariableNumber( projectile_entity, "gkbrkn_formation_sword_index", i-1 );
                    EntityAddComponent( projectile_entity, "LuaComponent", {
                        execute_on_added="1", execute_every_n_frame="1",
                        script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/formation_sword/projectile_update.lua",
                    } );
                end
            end
        end
    end,
    ["gkbrkn_link_shot"] = function( groups )
        for _,group in pairs( groups ) do
            local leader = group[1];
            local previous_projectile = nil;
            local leader = nil;
            for i,projectile in pairs( group ) do
                if previous_projectile ~= nil then
                    EntitySetVariableNumber( projectile, "gkbrkn_soft_parent", tonumber( leader ) );
                    EntityAddComponent( projectile, "LuaComponent", {
                        execute_on_added="1",
                        execute_every_n_frame="1",
                        script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/link_shot/projectile_update.lua",
                    });
                    EntityAddComponent( projectile, "LuaComponent", {
                        execute_on_added="1",
                        execute_every_n_frame="-1",
                        script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/link_shot/child_projectile_init.lua",
                    });
                else
                    leader = projectile;
                end
                previous_projectile = projectile;
            end
        end
    end,
    ["gkbrkn_formation_stack"] = function( groups )
        for _,group in pairs( groups ) do
            local stack_distance = 5;
            local captured_projectiles = "";
            local angles = {};
            local magnitudes = {};
            local magnitudes_sum = 0;
            local velocities = {};
            for i,projectile in pairs(group) do
                local velocity = EntityGetFirstComponent( projectile, "VelocityComponent" );
                if velocity ~= nil then
                    local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
                    local angle = math.atan2( vy, vx );
                    local magnitude = ( vx ^ 2 + vy ^ 2 ) ^ 0.5;
                    if magnitude ~= 0 then table.insert( angles, angle ); end
                    magnitudes_sum = magnitudes_sum + magnitude;
                    table.insert( velocities, velocity );
                    table.insert( magnitudes, magnitude );
                end
            end
            EntitiesAverageMemberList( group, "VelocityComponent", { 
                "gravity_x", "gravity_y", "mass", "air_friction", "terminal_velocity"
            } );
            local average_angle = mean_angle( angles, magnitudes );
            for i,projectile in pairs( group ) do
                local velocity = velocities[i];
                local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
                local angle = math.atan2( vy, vx );
                local magnitude = (magnitudes_sum / #magnitudes);
                local x, y = EntityGetTransform( projectile );
                local offset = (stack_distance * #group) - stack_distance * i - stack_distance * (#group-1) / 2;
                EntityApplyTransform( projectile, x + math.cos( average_angle - math.pi / 2 ) * offset, y + math.sin( average_angle - math.pi / 2 ) * offset );
                ComponentSetValue2( velocity, "mVelocity", math.cos( average_angle ) * magnitude, math.sin( average_angle ) * magnitude );
            end
        end
    end,
    ["gkbrkn_barrage"] = function( groups )
        local now = GameGetFrameNum();
        for _,group in pairs( groups ) do
            local distance = 7.5;
            local angles = {};
            for i,projectile in pairs( group ) do
                local velocity = EntityGetFirstComponent( projectile, "VelocityComponent" );
                if velocity then
                    local vx, vy = ComponentGetValue2( velocity, "mVelocity" );
                    local angle = math.atan2( vy, vx );
                    local magnitude = ( vx * vx + vy * vy ) ^ 0.5;
                    local x, y = EntityGetTransform( projectile );
                    SetRandomSeed( x + projectile, y + now );
                    local offset = Random( -distance, distance );
                    EntityApplyTransform( projectile, x + math.cos( angle - half_pi ) * offset, y + math.sin( angle - half_pi ) * offset );
                end
            end
        end
    end,
    ["gkbrkn_trailing_shot"] = function( groups )
        for _,group in pairs( groups ) do
            local previous_projectile = nil;
            for i,projectile in pairs( group ) do
                if previous_projectile ~= nil then
                    EntitySetVariableString( projectile, "gkbrkn_trailing_shot_soft_parent", tostring( previous_projectile ) );
                    local projectile_component = EntityGetFirstComponentIncludingDisabled( projectile, "ProjectileComponent" );
                    if projectile_component then
                        ComponentSetValue2( projectile_component, "die_on_low_velocity", false );
                    end
                end
                EntityAddComponent( projectile, "LuaComponent", {
                    execute_on_added="1",
                    execute_every_n_frame="1",
                    script_source_file="mods/gkbrkn_noita/files/gkbrkn/actions/trailing_shot/projectile_update.lua",
                });
                previous_projectile = projectile;
            end
        end
    end,
}

local player_projectiles = EntityGetWithTag( "projectile_player" ) or {};
for tag,capture_callback in pairs( TAG_MAPPING ) do
    local projectiles = {};
    for _,projectile in ipairs( player_projectiles ) do
        if EntityHasNamedVariable( projectile, tag ) then
            table.insert( projectiles, projectile );
        end
    end
    if #projectiles > 0 then
        capture_callback( get_tag_groups( tag, projectiles ) );
    end
end