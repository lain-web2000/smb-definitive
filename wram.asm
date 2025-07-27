.org $6000

SaveDataHeader:
	.byte "SM2SAVE"

GamesBeatenCount:
	.byte $00

ContinueWorld:
	.byte $00

ContinueLevel: ;only for easy mode
	.byte $00
	
SavedHardWorldFlag:
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