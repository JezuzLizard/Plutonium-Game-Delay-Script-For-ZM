#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;
#include maps\mp\zombies\_zm;


init()
{
	initialize_game_delay_vars();
}

initialize_game_delay_vars()
{
	level.wait_time = getDvarIntDefault( "zombies_first_round_delay", 10 ); //change this to adjust the start time once the player quota is met
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
	players = get_players();
	foreach ( player in players )
	{
		player playlocalsound( "zmb_perks_packa_ready" );
	}
	level notify( "game_delay_done" );
    flag_set( "start_zombie_round_logic" );
}

wait_message()
{   
	level endon( "end_game" );
   	Waiting = create_simple_hud();
   	Waiting.horzAlign = "center";
   	Waiting.vertAlign = "middle";
   	Waiting.alignX = "center";
   	Waiting.alignY = "middle";
   	Waiting.y = 0;
   	Waiting.x = -1;
   	Waiting.foreground = 1;
   	Waiting.fontscale = 3.0;
   	Waiting.alpha = 1;
   	Waiting.color = ( 1.000, 1.000, 1.000 );
	waiting.hidewheninmenu = 1;
	
	if ( level.player_quota == 1 )
	{
		player_text = "player";
	}
   	else 
	{
		player_text = "players";
	}
	Waiting SetText( "Waiting for " + level.player_quota + " more " + player_text );
	level waittill( "player_quota_reached" );
	Waiting destroy();
}

countdown_timer()
{   
	level endon( "end_game" );
	Remaining = create_simple_hud();
  	Remaining.horzAlign = "center";
  	Remaining.vertAlign = "middle";
   	Remaining.alignX = "center";
   	Remaining.alignY = "middle";
   	Remaining.y = 20;
   	Remaining.x = 0;
   	Remaining.foreground = 1;
   	Remaining.fontscale = 2.0;
   	Remaining.alpha = 1;
   	Remaining.color = ( 0.98, 0.549, 0 );
	Remaining.hidewheninmenu = 1;

   	Countdown = create_simple_hud();
   	Countdown.horzAlign = "center"; 
   	Countdown.vertAlign = "middle";
   	Countdown.alignX = "center";
   	Countdown.alignY = "middle";
   	Countdown.y = -20;
   	Countdown.x = 0;
   	Countdown.foreground = 1;
   	Countdown.fontscale = 2.0;
   	Countdown.alpha = 1;
   	Countdown.color = ( 1.000, 1.000, 1.000 );
	Countdown.hidewheninmenu = 1;
   	Countdown SetText( "Match begins in" );
   	
   	timer = level.wait_time;
	for ( timer = level.wait_time; timer >= 0; timer-- )
	{
		Remaining SetValue( timer ); 
		wait 1;
		if ( timer <= 0 )
		{
			Countdown destroy();
			Remaining destroy();
			break;
		}
	}
}