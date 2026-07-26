.org $6000

SaveDataHeader:
	.byte "MARIO COMPLETE", $00, $00

SaveData:
File_A:
GamesBeatenCount:
	.res 3, $00

ContinueWorld:
	.res 3, $00
	
ContinueLevel:
	.res 3, $00

ContinueArea:
	.res 3, $00
	
SavedLevelSet:
	.byte $00

SavedCompletedWorlds:
	.res 3, $00
	
ContinuePlayerStatus:
	.res 3, $00

ContinuePlayerSize:
	.res 3, $00

SavedTopScore:
    .res 6, $00
	.res 6, $00
	.res 6, $00
File_A_End:

File_B:
	.res (File_A_End-File_A), $00
File_B_End:

File_C:
	.res (File_A_End-File_A), $00
File_C_End:	

GlobalSettings:

DifficultyFlag:
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
GlobalSettings_End:
SaveData_End:

CurrentFile:
	.byte $00
	
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
	  
SoundEngineSet:
      .byte $00 ;hack
	  
AreaDataCopy:
	.res $100, $00

EnemyDataCopy:
	.res $100, $00