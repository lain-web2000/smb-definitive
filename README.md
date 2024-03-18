# Super Mario Bros. Definitive 

A modification of the Japanese Super Mario Bros. 2 (also known as Super Mario Bros.: The Lost Levels) that combines all levels from said game and the original Super Mario Bros. into one ROM hack, allowing all levels from both games to be played back-to-back seamlessly. Levels from the original Super Mario Bros. are played first, with levels from The Lost Levels immediately following the final Super Mario Bros. level. In addition to including every level from both games, Super Mario Bros. Definitive makes several small tweaks to the levels and game engine, most of which come from Super Mario All-Stars or All Night Nippon Super Mario Bros. Super Mario Bros. Definitive uses the VRC3 mapper and is based on the codebase from recent NES conversions of Super Mario Bros.: The Lost Levels. Below is a list of the most significant changes implemented within this ROM hack:

- A brand-new World 9 has been added for the Super Mario Bros. half, accessible after clearing all 32 Super Mario Bros. levels. The World 9 stages are based on glitch levels present in Super Mario Bros., with 9-4 using the same maze pattern as 7-4 in **Vs.** Super Mario Bros.
- Worlds A through D from The Lost Levels have been increased in difficulty by implementing modifications from Super Mario All-Stars. Specifically, Hammer Brothers now always charge the player, enemies gain a speed boost, all Goombas become Buzzy Beetles, all springs in World B are now red instead of green, and all Fake Bowsers now throw hammers. Unlike Super Mario All-Stars, Bowser in World 9 and World D now shoots fire as well.
- A couple bugfixes from All Night Nippon Super Mario Bros. have been implemented, resolving an issue that occurred when finishing a castle level with no time remaining and an issue with riding moving platforms to the bottom of the screen.
- Graphical changes have been made to certain levels. 5-1 from Super Mario Bros. and 1-1 from The Lost Levels now start with a big castle for the sake of visual consistency, 3-3 from Super Mario Bros. is now a night-time snow level, all bridge levels now contain pools of water to indicate the presence of flying Cheep-Cheeps, and the water section in 8-4 from Super Mario Bros. now uses the castle palette without the water backdrop.
- As is the case with the European release of Super Mario Bros., the one-block gaps present at the end of all water areas from that game are absent to prevent the player from easily getting stuck until time runs out.
- As in Super Mario All-Stars, the player begins with five lives and receives five lives upon continuing from a Game Over. Additionally, the maximum number of lives has been capped to 128 to prevent an issue with overflowing the life count. The lives display has been modified to properly display the life count.
- Luigi inherits his physics from Super Mario All-Stars, increasing his horizontal acceleration and deceleration and making his control feel less "slippery."
- Luigi now has a distinct palette (lifted from Super Mario Deluxe).
- Player physics and firework conditions from The Lost Levels apply to levels from both games but enemy speeds and hidden 1-UP requirements are taken from the source game. However, the hidden 1-UP from 1-1 of The Lost Levels is not tied to any coin requirements.

Please note that there are two patch files present in this folder. Either one can be used to play Super Mario Bros. Definitive. smb-definitive_smb1.ips is to be patched onto a standard 40,976 byte Super Mario Bros. ROM, whereas smb-definitive_smb2j.ips is to be patched onto a standard 65,500 byte Super Mario Bros. 2 (Japan) ROM. For the SMB2J patch, note that you may need to change the file extension from ".fds" to ".nes" in order for this hack to operate correctly.

# Credits:
-Simplistic6502, who did the vast majority of programming work and created the assets used for the SMB Definitive title screen.

-SeraphmIII, who created the SMB2J VRC3 codebase used for this project and designed the levels for SMB1's World 9.

Special thanks to threecreepio, whose MMC5 conversion of SMB2J and disassembly of ANNSMB proved particularly useful for creating this ROM hack. This would not have been possible without his resources.
