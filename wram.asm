.org $6000

SaveDataHeader:
	.byte "SMB-COMP"

SaveData:
GamesBeatenCount:
	.byte $00

ContinueWorld:
	.byte $00

ContinueLevel: ;only for easy mode
	.byte $00
	
SavedLevelSet:
	.byte $00

SavedCompletedWorlds:
	.byte $00
	
DifficultyFlag:
	.byte $00
	
LuigiPalette:
	.byte $00

LuigiPhysics:
	.byte $00
	
BGTileset:
	.byte $00

SpinyEggBehavior:
	.byte $00

WarpZoneScroll:
	.byte $00

FontSelection:
    .byte $00

TilesetSelection:
    .byte $00
SaveData_End:

CurrentGame:
	.byte $00

LevelSet:
    .byte $00

LeavesXPosCopy:
	.res $0c, $00
LeavesYPosCopy:
	.res $0c, $00

LuigiFrictionData:
	.byte $b4, $68, $a0
	  
WRAM_PlayerColors:
      .byte $22, $16, $27, $18 ;player's normal colors, may be overwritten
      .byte $22, $37, $27, $16 ;player's colors after grabbing fire flower, may be overwritten
	  
AreaDataCopy:
	.res $100, $00

EnemyDataCopy:
	.res $100, $00