dofile_once( "mods/gkbrkn_noita/files/gkbrkn/config.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/lib/variables.lua" );
dofile_once( "mods/gkbrkn_noita/files/gkbrkn/helper.lua" );

function shot( projectile_entity )
    local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
    local player = GetUpdatedEntityID();
    local damage_multiplier =  EntityGetVariableNumber( player, "gkbrkn_damage_multiplier", 1.0 );
    ComponentAdjustValue( projectile, "damage", function( value ) return tonumber( value ) * damage_multiplier; end );

    local demolitionist_bonus = EntityGetVariableNumber( player, "gkbrkn_demolitionist_bonus", 0.0 ) + EntityGetVariableNumber( projectile_entity, "gkbrkn_demolitionist_bonus", 0.0 );
    if demolitionist_bonus ~= 0 then
        local explosion_multiplier = demolitionist_bonus + 1;
        ComponentObjectAdjustValues( projectile, "config_explosion", {
            knockback_force=function( value ) return tonumber( value ) * explosion_multiplier; end,
            explosion_radius=function( value ) return tonumber( value ) * explosion_multiplier; end,
            max_durability_to_destroy=function( value ) return tonumber( value ) + demolitionist_bonus; end,
            ray_energy=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_power=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_radius_min=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_radius_max=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_velocity_min=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_damage_required=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_probability=function( value ) return tonumber( value ) * explosion_multiplier; end,
            cell_explosion_power_ragdoll_coeff=function( value ) return tonumber( value ) * explosion_multiplier; end,
        });

        local lightning = EntityGetFirstComponent( projectile_entity, "LightningComponent" );
        if lightning ~= nil then
            ComponentObjectAdjustValues( lightning, "config_explosion", {
                knockback_force=function( value ) return tonumber( value ) * explosion_multiplier; end,
                explosion_radius=function( value ) return tonumber( value ) * explosion_multiplier; end,
                max_durability_to_destroy=function( value ) return tonumber( value ) + demolitionist_bonus; end,
                ray_energy=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_power=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_radius_min=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_radius_max=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_velocity_min=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_damage_required=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_probability=function( value ) return tonumber( value ) * explosion_multiplier; end,
                cell_explosion_power_ragdoll_coeff=function( value ) return tonumber( value ) * explosion_multiplier; end,
            });
        end
    end

    local hyper_casting_bonus = EntityGetVariableNumber( player, "gkbrkn_hyper_casting", 0.0 );
    if hyper_casting_bonus > 0 then
        local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
        if velocity ~= nil then
            ComponentAdjustValues( velocity, {
                air_friction=function( value ) return math.min( tonumber( value ), 0 ); end,
                gravity_y=function( value ) return 0; end,
                apply_terminal_velocity=function( value ) return 1; end,
                terminal_velocity=function( value ) return 2000; end,
            } );
        end
        if projectile ~= nil then
            ComponentAdjustValues( projectile, {
                knockback_force=function( value ) return 0; end,
                ragdoll_force_multiplier=function( value ) return 0; end,
                hit_particle_force_multiplier=function( value ) return 0; end,
                bounce_energy=function( value ) return 1.0; end,
            } );
        end
    end

    if projectile ~= nil then
        EntitySetVariableNumber( projectile_entity, "gkbrkn_bounces_last", ComponentGetValue( projectile, "bounces_left" ) );
        EntitySetVariableNumber( projectile_entity, "gkbrkn_bounce_damage_remaining", 10 );
        EntitySetVariableNumber( projectile_entity, "gkbrkn_initial_damage", ComponentGetValue( projectile, "damage" ) );
        EntitySetVariableNumber( projectile_entity, "gkbrkn_damage_plus_lifetime_limit", GameGetFrameNum() + 300 );
        local active_types = {};
        local damage_by_types = ComponentObjectGetMembers( projectile, "damage_by_type" ) or {};
        for type,_ in pairs( damage_by_types ) do
            local amount = tonumber( ComponentObjectGetValue( projectile, "damage_by_type", type ) );
            if amount == amount and amount ~= 0 then
                table.insert( active_types, type.."="..amount );
            end
        end
        if #active_types > 0 then
            EntitySetVariableString( projectile_entity, "gkbrkn_initial_damage_types", table.concat( active_types, "," ) );
        end
    end

    EntityAddComponent( projectile_entity, "LuaComponent", {
        script_source_file="mods/gkbrkn_noita/files/gkbrkn/misc/player_projectile_update.lua",
        execute_every_n_frame="1",
    } );


    if CONTENT[TWEAKS.BloodAmount].enabled() then
        local add = EntityLoad( "mods/gkbrkn_noita/files/gkbrkn/misc/blood_tweak/projectile_extra_entity.xml" );
        EntityAddChild( projectile_entity, add );
    end

    if EntityGetVariableNumber( projectile_entity, "gkbrkn_guided_shot", 0 ) == 1 then
        local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
        if velocity ~= nil then
            local projectile = EntityGetFirstComponent( projectile_entity, "ProjectileComponent" );
            if projectile ~= nil then
                local aim_angle = 0;
                local components = EntityGetAllComponents( player ) or {};
                for _,component in pairs( components ) do
                    if ComponentGetTypeName( component ) == "ControlsComponent" then
                        local ax, ay = ComponentGetValueVector2( component, "mAimingVector" );
                        aim_angle = math.atan2( ay, ax );
                        break;
                    end
                end
                local vx,vy = ComponentGetValueVector2( velocity, "mVelocity", vx, vy );
                local magnitude = math.sqrt( vx * vx + vy * vy );
                ComponentSetValueVector2( velocity, "mVelocity", math.cos( aim_angle ) * magnitude, math.sin( aim_angle ) * magnitude );
            end
        end
    end

    if EntityGetVariableNumber( projectile_entity, "gkbrkn_magic_hand", 0 ) == 1 then

        if projectile ~= nil then
            ComponentSetValue( projectile, "die_on_low_velocity", "0" );
        end

        local initial_angle = nil;
        local aim_angle = 0;

        local velocity = EntityGetFirstComponent( projectile_entity, "VelocityComponent" );
        if velocity ~= nil then
            local vx, vy = ComponentGetValueVector2( velocity, "mVelocity" );
            if vx ~= 0 or vy ~= 0 then
                initial_angle = math.atan2( vy, vx );
                ComponentSetValueVector2( velocity, "mVelocity", 0, 0 );
            end
            ComponentSetValue( velocity, "gravity_y", 0 );
        end

        local components = EntityGetAllComponents( player ) or {};
        for _,component in pairs( components ) do
            if ComponentGetTypeName( component ) == "ControlsComponent" then
                local ax, ay = ComponentGetValueVector2( component, "mAimingVector" );
                aim_angle = math.atan2( ay, ax );
            end
        end

        local x, y = EntityGetTransform( projectile_entity );
        local active_wand = WandGetActive( player );
        if active_wand ~= nil then
            local wx, wy = EntityGetTransform( active_wand );
            local distance = math.sqrt( math.pow( wx - x, 2 ) + math.pow( wy - y, 2 ) ) + 8;
            EntitySetVariableNumber( projectile_entity, "gkbrkn_magic_hand_distance", distance );
        end

        if initial_angle ~= nil then
            EntitySetVariableNumber( projectile_entity, "gkbrkn_magic_hand_angle_offset", initial_angle - aim_angle );
        else
            EntitySetVariableNumber( projectile_entity, "gkbrkn_magic_hand_angle_offset", 0 );
        end
    end

    if HasFlagPersistent( MISC.LessParticles.PlayerProjectilesEnabled ) then
        reduce_particles( projectile_entity, HasFlagPersistent( MISC.LessParticles.DisableEnabled ) );
    end

    if HasFlagPersistent( MISC.RainbowProjectiles.Enabled ) then
        SetRandomSeed( projectile_entity, projectile_entity );
        local color = 0xFF000000 + math.floor( Random() * 0xFFFFFF );
        local r = bit.band( 0xFF, color );
        local g = bit.rshift( bit.band( 0xFF00, color ), 8 );
        local b = bit.rshift( bit.band( 0xFF0000, color ), 16 );
        local particle_emitters = EntityGetComponent( projectile_entity, "ParticleEmitterComponent" ) or {};
        for _,particle_emitter in pairs( particle_emitters ) do
            ComponentSetValue( particle_emitter, "color", tostring( color ) );
        end
        if ComponentGetValue2 and ComponentSetValue2 then
            local sprite_particle_emitters = EntityGetComponent( projectile_entity, "SpriteParticleEmitterComponent" ) or {};
            for _,sprite_particle_emitter in pairs( sprite_particle_emitters ) do
                local color = {ComponentGetValue2( sprite_particle_emitter, "color" )};
                local color_change = {ComponentGetValue2( sprite_particle_emitter, "color_change" )};
                local ratio_r = r / 255;
                local ratio_g = g / 255;
                local ratio_b = b / 255;
                ComponentSetValue2( sprite_particle_emitter, "color", ratio_r, ratio_g, ratio_b, color[4] );
            end
        end
    end
end