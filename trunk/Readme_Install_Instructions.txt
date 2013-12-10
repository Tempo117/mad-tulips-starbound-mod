This mod will replace youre spaceship with a custom one which is modable block by block. If you want to keep one of youre current characters be sure to leave nothing on youre original spaceship, it will be replaced by the modded one.

----------------------
1) Installing the mod:
----------------------
- close Starbound.
- backup "/Starbound/player/" to "/Starbound/player_backup".
- backup "/Starbound/assets/player.config".
- backup "/Starbound/assets/universe_server.config".
- delete content of "/Starbound/player/".
- copy "MadTulip/" directory into "/Starbound/assets" creating "/Starbound/assets/MadTulip".
- copy "player.config" file into "/Starbound/assets" overwriting "/Starbound/assets/player.config".
- copy "universe_server.config" file into "/Starbound/assets" overwriting "/Starbound/assets/universe_server.config".
- start Starbound.
- create a NEW CHARACTER.

-------------------------------
2) Importing pre-mod character:
-------------------------------
- close starbound.
- Copy the 2 files "<somelongercode>.shipworld" and "<somelongercode>.shipworld" (do not copy "<somelongercode>.shipworld") from your "Starbound/player_backup/" to "Starbound/player/"
- start starbound.
- log in with the character. starbound will search for the "<somelongercode>" in "Starbound/player/" and will not find it -> it will create a new default one from the "Starbound/assets/MadTulip/" directory, the new modded one.
- if you do not remove the old /Starbound/player/"<somelongercode>.shipworld" stored version of the old ship this will interfere with the new version of it and lead to a crash.

----------------------------------
3) Installing the mod on a server:
----------------------------------
- you can do the same as described under "1)Installing the mod" to ONLY THE SERVER FILES.
- clients do not need to install this mod, it will be supplied by the server.
- clients need to create a new character to join this server.
- clients can import old characters the same way as described under 2).
- clients created and first launched on the modified server will crash the game if played on not modded server (like in singleplayer) unless the same mod is installed there.

-------------------------------------
4) Static Links i have to excuse for:
-------------------------------------
- player.config

- universe_server.config

- hardcoded links which need this mod in /assets/MadTulip
  D:\Program Files (x86)\Steam\steamapps\common\Starbound\assets\MadTulip\objects\Ship Station\MadTulip_Shipstation.object (1 hit)
	Line 8:     "config" : "/MadTulip/objects/Ship Station/MadTulip_Shipstation.config",
  D:\Program Files (x86)\Steam\steamapps\common\Starbound\assets\MadTulip\objects\Rear Thruster\MadTulip_RearThruster.object (1 hit)
	Line 60:       "image" : "MadTulip/objects/Rear Thruster/MadTulip_RearThrusterON.png:<color>.<frame>",
  D:\Program Files (x86)\Steam\steamapps\common\Starbound\assets\MadTulip\objects\Small Thruster\MadTulip_SmallThruster.object (1 hit)
	Line 60:       "image" : "MadTulip/objects/Small Thruster/MadTulip_SmallThrusterON.png:<color>.<frame>",
  D:\Program Files (x86)\Steam\steamapps\common\Starbound\assets\MadTulip\objects\Ship Station\MadTulip_Shipstation.config (1 hit)
	Line 28:         "file" : "/MadTulip/objects/Ship Station/MadTulip_Shipstation_menue_icon.png",


If you are interested in participating in this mod just do so and contact me at "madtulip@gmx.de"
Have fun!