.org $6000

SaveDataHeader:
	.byte "MARIO COMPLETE", $00, $00

SaveData:
GamesBeatenCount:
	.byte $00
	.byte $00
	.byte $00

ContinueWorld:
	.byte $00
	.byte $00
	.byte $00
	
ContinueLevel: ;only for easy mode
	.byte $00
	.byte $00
	.byte $00

ContinueArea: ;only for easy mode
	.byte $00
	.byte $00
	.byte $00
	
SavedLevelSet:
	.byte $00

SavedCompletedWorlds:
	.byte $00
	.byte $00
	.byte $00
	
DifficultyFlag:
	.byte $00
	
ContinuePlayerStatus:
	.byte $00
	.byte $00
	.byte $00

ContinuePlayerSize:
	.byte $00
	.byte $00
	.byte $00	
	
;$00 - Standard SMB1 Palette
;$01 - Protoype #1 Palette
;$02 - Protoype #2 Palette
MarioPalette:
	.byte $00
	
;$00 - Standard SMB1 Palette
;$01 - Super Mario Bros. DX Palette
;$02 - Super Mario Maker 2 Palette
LuigiPalette:
	.byte $00

LuigiPhysics:
	.byte $00
	
ProbablyCouldUseThisElsewhere:
	.byte $00

SpinyEggBehavior:
	.byte $00

WarpZoneScroll:
	.byte $00

CountdownSpeed:
	.byte $00

FontSelection:
    .byte $00

TilesetSelection:
    .byte $00

AnimatedTiles:
	.byte $00
	
SaveData_End:

CurrentGame:
	.byte $00

LevelSet:
    .byte $00

;-------------------------------------------------------------------------------------

ShadowPRGBank:
    .byte $00

NMIVector:
    .byte $00

;-------------------------------------------------------------------------------------

LeavesXPosCopy:
	.res $0c, $00
LeavesYPosCopy:
	.res $0c, $00

LuigiFrictionData:
	.byte $b4, $68, $a0

DemoActionData:
      .byte $01, $80, $02, $81, $41, $80, $01
      .byte $42, $c2, $02, $80, $41, $c1, $41, $c1
      .byte $01, $c1, $01, $02, $80, $00
DemoActionDataEnd:

DemoTimingData:
      .byte $9b, $10, $20, $09, $34, $20, $24
      .byte $15, $5a, $10, $20, $28, $30, $20, $18
      .byte $50, $20, $30, $40, $03, $7f, $00
DemoTimingDataEnd:
	  
PlayerColors:
      .byte $22, $16, $27, $18 ;mario's normal colors
      .byte $22, $30, $27, $19 ;luigi's normal colors
PlayerFireColors:
      .byte $22, $37, $27, $16 ;mario's colors after grabbing fire flower
      .byte $22, $29, $27, $16 ;luigi's colors after grabbing fire flower
	  
	  
	  
AreaDataCopy:
	.res $100, $00

EnemyDataCopy:
	.res $100, $00