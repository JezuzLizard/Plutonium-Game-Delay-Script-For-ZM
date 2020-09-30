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
	level.wait_time = getDvarIntDefault( "zombies_game_start_timer", 10 ); //change this to adjust the start time once the player quota is met
	level.player_quota = getDvarIntDefault( "zombies_minplayers", 2 ); //number of players required before the game starts
	if ( level.player_quota > 1 )
	{
		level.round_prestart_func =::round_prestart_func; //delays the rounds from starting
		SetDvar( "scr_zm_enable_bots", 1 ); //this is required for the mod to work
		thread game_delay(); //this overrides the typical start time logic
	}
}

round_prestart_func()
{
	level waittill( "game_delay_done" );
}

game_delay()
{
	flag_wait( "initial_blackscreen_passed" );
	players = get_players();
	if ( !( players.size >= level.player_quota ) )
	{
		thread wait_message();
		while ( players.size < level.player_quota || players.size < 1)
		{
			wait 0.05;
			players = get_players();
		}
		level notify( "player_quota_reached" );
	}
	if ( level.wait_time > 0 )
	{
		thread countdown_timer();
		wait level.wait_time;
	}
	level notify( "game_delay_done" );
    flag_set( "start_zombie_round_logic" );
}

wait_message()
{   
	level endon( "end_game" );
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
	
	if ( level.player_quota == 1 )
	{
		player_text = "player";
	}
   	else 
	{
		player_text = "players";
	}
	waiting setText( "Waiting for " + level.player_quota + " more " + player_text );
	level waittill( "player_quota_reached" );
	waiting destroy();
}

countdown_timer()
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
	timer = level.wait_time;
	while ( 1 )
	{
		Remaining setValue( timer ); 
		wait 1;
		timer--;
		if ( timer <= 5 )
		{
			countdown_pulse( Remaining, timer );
			break;
		}
	}
	Countdown destroy();
	Remaining destroy();
}

countdown_pulse( hud_elem, duration )
{
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
