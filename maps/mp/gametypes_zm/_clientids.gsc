#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm;


init()
{
	initialize_game_delay_vars();
}

initialize_game_delay_vars()
{
	level thread on_player_connect();
	level.gdm_wait_time = getDvarInt( "zombies_game_delay_timer" ); //change this to adjust the start time once the player quota is met
	level.gdm_player_quota = getDvarInt( "zombies_minplayers" ); //number of players required before the game starts
	level.gdm_player_num_required = level.gdm_player_quota;
	level.round_prestart_func =::round_prestart_func; //delays the rounds from starting
	setDvar( "scr_zm_enable_bots", 1 ); //this is required for the mod to work
	thread game_delay(); //this overrides the typical start time logic
	thread dvar_watcher();
	thread destroy_hud_on_game_end();
}

on_player_connect()
{
	level endon( "end_game" );
	while ( 1 )
	{
		level waittill( "connected", player );
		player thread on_player_disconnect();
		level.gdm_player_num_required--;
		level notify( "gdm_update_wait_message" );
	}
}

on_player_disconnect()
{
	self waittill( "disconnect" );
	level.gdm_player_num_required++;
	level notify( "gdm_update_wait_message" );
}

round_prestart_func()
{
	level waittill( "gdm_game_delay_done" );
}

game_delay()
{
	flag_wait( "initial_blackscreen_passed" );
	players = get_players();
	if ( !( players.size >= level.gdm_player_quota ) )
	{
		thread wait_message_text_updater();
		while ( players.size < level.gdm_player_quota )
		{
			level waittill( "gdm_update_wait_message" );
			players = get_players();
		}
		level notify( "gdm_player_quota_reached" );
		if ( isDefined( level.gdm_wait_message ) )
		{
			level.gdm_wait_message destroy();
		}
	}
	if ( level.gdm_wait_time > 0 )
	{
		thread countdown_timer_hud();
		wait level.gdm_wait_time;
	}
	level notify( "gdm_game_delay_done" );
    flag_set( "start_zombie_round_logic" );
}

create_wait_message_hud()
{
	waiting = create_simple_hud();
   	waiting.horzAlign = "center";
   	waiting.vertAlign = "middle";
   	waiting.alignX = "center";
   	waiting.alignY = "middle";
   	waiting.y = 0;
   	waiting.x = -1;
   	waiting.foreground = 1;
   	waiting.fontscale = 3.0;
   	waiting.alpha = 1;
   	waiting.color = ( 1.000, 1.000, 1.000 );
	waiting.hidewheninmenu = 1;
	return waiting;
}

wait_message_text_updater()
{
	level endon( "end_game" );
	level endon( "gdm_player_quota_reached" );
	while ( 1 )
	{
		players = get_players();
		if ( level.gdm_player_num_required > 1 )
		{
			player_text = "Players";
		}
		else 
		{
			player_text = "Player";
		}
		level.gdm_wait_message = create_wait_message_hud();
		level.gdm_wait_message setText( "Waiting For " + level.gdm_player_num_required + " More " + player_text );
		level waittill( "gdm_update_wait_message" );
		if ( isDefined( level.gdm_wait_message ) )
		{
			level.gdm_wait_message destroy();
		}
	}
}

countdown_timer_hud()
{   
	level endon( "end_game" );
	remaining = create_simple_hud();
  	remaining.horzAlign = "center";
  	remaining.vertAlign = "middle";
   	remaining.alignX = "center";
   	remaining.alignY = "middle";
   	remaining.y = 20;
   	remaining.x = 0;
   	remaining.foreground = 1;
   	remaining.fontscale = 2.0;
   	remaining.alpha = 1;
   	remaining.color = ( 0.98, 0.549, 0 );
	remaining.hidewheninmenu = 1;
	remaining maps/mp/gametypes_zm/_hud::fontpulseinit();

   	countdown = create_simple_hud();
   	countdown.horzAlign = "center"; 
   	countdown.vertAlign = "middle";
   	countdown.alignX = "center";
   	countdown.alignY = "middle";
   	countdown.y = -20;
   	countdown.x = 0;
   	countdown.foreground = 1;
   	countdown.fontscale = 2.0;
   	countdown.alpha = 1;
   	countdown.color = ( 1.000, 1.000, 1.000 );
	countdown.hidewheninmenu = 1;
   	countdown setText( "Match Begins In" );
	level.gdm_countdown_timer = remaining;
	level.gdm_countdown_text = countdown;
	timer = level.gdm_wait_time;
	while ( 1 )
	{
		level.gdm_countdown_timer setValue( timer ); 
		wait 1;
		timer--;
		if ( timer <= 5 )
		{
			countdown_pulse( level.gdm_countdown_timer, timer );
			break;
		}
	}
	if ( isDefined( level.gdm_countdown_text ) )
	{
		level.gdm_countdown_text destroy();
	}
	if ( isDefined( level.gdm_countdown_timer ) )
	{
		level.gdm_countdown_timer destroy();
	}
}

countdown_pulse( hud_elem, duration )
{
	level endon( "end_game" );
	waittillframeend;
	while ( duration > 0 && !level.gameended )
	{
		hud_elem thread maps/mp/gametypes_zm/_hud::fontpulse( level );
		wait ( hud_elem.inframes * 0.05 );
		hud_elem setvalue( duration );
		duration--;
		wait ( 1 - ( hud_elem.inframes * 0.05 ) );
	}
}

dvar_watcher()
{
	level endon( "end_game" );
	level endon( "gdm_game_delay_done" );
	old_zombies_minplayers = getDvarInt( "zombies_minplayers" );
	new_zombies_minplayers = getDvarInt( "zombies_minplayers" );
	while ( 1 )
	{
		new_zombies_minplayers = getDvarInt( "zombies_minplayers" );
		if ( new_zombies_minplayers != old_zombies_minplayers )
		{
			old_zombies_minplayers = new_zombies_minplayers;
			level.gdm_player_quota = new_zombies_minplayers;
			players = get_players();
			level.gdm_player_num_required = ( level.gdm_player_quota - players.size );
			level notify( "gdm_update_wait_message" );
		}
		wait 0.05;
	}
}

destroy_hud_on_game_end()
{
	level waittill( "end_game" );
	if ( isDefined( level.gdm_wait_message ) )
	{
		level.gdm_wait_message destroy();
	}
	if ( isDefined( level.gdm_countdown_timer ) )
	{
		level.gdm_countdown_timer destroy();
	}
	if ( isDefined( level.gdm_countdown_text ) )
	{
		level.gdm_countdown_text destroy();
	}
}
