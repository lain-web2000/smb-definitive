
;-------------------------------------------------------------------------------------
;DEFINES

;NES specific hardware defines

PPU_CTRL              = $2000
PPU_MASK              = $2001
PPU_STATUS            = $2002
PPU_SPR_ADDR          = $2003
PPU_SPR_DATA          = $2004
PPU_SCROLL            = $2005
PPU_ADDRESS           = $2006
PPU_DATA              = $2007

SND_REGISTER          = $4000
SND_SQUARE1_REG       = $4000
SND_SQUARE2_REG       = $4004
SND_TRIANGLE_REG      = $4008
SND_NOISE_REG         = $400c
SND_DELTA_REG         = $4010
SND_MASTERCTRL_REG    = $4015

SPR_DMA               = $4014
JOYPAD_PORT           = $4016
JOYPAD_PORT1          = $4016
JOYPAD_PORT2          = $4017

.segment "MAIN_ZP" : zeropage
    .res 8 ; $00-$07

ObjectOffset:
    .res 1 ; $08

FrameCounter:
    .res 1 ; $09

A_B_Buttons:
    .res 1 ; $0a
Up_Down_Buttons:
    .res 1 ; $0b
Left_Right_Buttons:
    .res 1 ; $0c
PreviousA_B_Buttons:
    .res 1 ; $0d

GameEngineSubroutine:
    .res 1 ; $0e

Enemy_Flag:
    .res 6 ; $0f-$14
    .res 1 ; $15 (only read by SpawnHammerObj)
Enemy_ID:
    .res 6 ; $16-$1b
    .res 1 ; $1c (unused)

Player_State:
    .res 1 ; $1d
Enemy_State:
    .res 6 ; $1e-$23
Fireball_State:
    .res 2 ; $24-$25
Block_State:
    .res 2 ; $26-$27
    .res 2 ; $28-$29 (unused)
Misc_State:
    .res 9 ; $2a-$32

PlayerFacingDir:
    .res 1 ; $33
DestinationPageLoc:
    .res 1 ; $34
VictoryWalkControl:
    .res 1 ; $35
    .res 3 ; $36-$38 (unused)

PowerUpType:
    .res 1 ; $39

FireballBouncingFlag:
    .res 2 ; $3a-$3b

HammerBroJumpTimer:
    .res 6 ; $3c-$41
    .res 3 ; $42-$44 (unused)

Player_MovingDir:
    .res 1 ; $45
Enemy_MovingDir:
    .res 6 ; $46-$4b
    .res 11 ; $4c-$56 (unused)

SprObject_X_Speed:
Player_X_Speed:
    .res 1 ; $57
Enemy_X_Speed:
YPlatformCenterYPos:
Jumpspring_FixedYPos:
RedPTroopaCenterYPos:
XMoveSecondaryCounter:
CheepCheepMoveMFlag:
LakituMoveSpeed:
FirebarSpinState_Low:
BlooperMoveSpeed:
PiranhaPlant_Y_Speed:
ExplosionGfxCounter:
    .res 6 ; $58-$5d
Fireball_X_Speed:
    .res 2 ; $5e-$5f
Block_X_Speed:
    .res 2 ; $60-$61
    .res 2 ; $62-$63
Misc_X_Speed:
    .res 9 ; $64-$6c

SprObject_PageLoc:
Player_PageLoc:
    .res 1 ; $6d
Enemy_PageLoc:
    .res 6 ; $6e-$73
Fireball_PageLoc:
    .res 2 ; $74-$75
Block_PageLoc:
    .res 2 ; $76-$77
    .res 2 ; $78-$79
Misc_PageLoc:
    .res 9 ; $7a-$82
Bubble_PageLoc:
    .res 3 ; $83-$85

SprObject_X_Position:
Player_X_Position:
    .res 1 ; $86
Enemy_X_Position:
    .res 6 ; $87-$8c
Fireball_X_Position:
    .res 2 ; $8d-$8e
Block_X_Position:
    .res 2 ; $8f-$90
    .res 2 ; $91-$92
Misc_X_Position:
    .res 9 ; $93-$9b
Bubble_X_Position:
    .res 3 ; $9c-$9e

SprObject_Y_Speed:
Player_Y_Speed:
    .res 1 ; $9f
Enemy_Y_Speed:
XMovePrimaryCounter:
LakituMoveDirection:
FirebarSpinState_High:
BlooperMoveCounter:
PiranhaPlant_MoveFlag:
ExplosionTimerCounter:
    .res 6 ; $a0-$a5
Fireball_Y_Speed:
    .res 2 ; $a6-$a7
Block_Y_Speed:
    .res 2 ; $a8-$a9
    .res 2 ; $aa-$ab
Misc_Y_Speed:
    .res 9 ; $ac-$b4

SprObject_Y_HighPos:
Player_Y_HighPos:
    .res 1 ; $b5
Enemy_Y_HighPos:
    .res 6 ; $b6-$bb
Fireball_Y_HighPos:
    .res 2 ; $bc-$bd
Block_Y_HighPos:
    .res 2 ; $be-$bf
    .res 2 ; $c0-$c1
Misc_Y_HighPos:
    .res 9 ; $c2-$ca
Bubble_Y_HighPos:
    .res 3 ; $cb-$cd

SprObject_Y_Position:
Player_Y_Position:
    .res 1 ; $ce
Enemy_Y_Position:
    .res 6 ; $cf-$d4
Fireball_Y_Position:
    .res 2 ; $d5-$d6
Block_Y_Position:
    .res 2 ; $d7-$d8
    .res 2 ; $d9-$da
Misc_Y_Position:
    .res 9 ; $db-$e3
Bubble_Y_Position:
    .res 3 ; $e4-$e6

AreaData:
    .res 2 ; $e7-$e8
AreaDataLow = AreaData
AreaDataHigh = AreaData+1
EnemyData:
    .res 2 ; $e9-$ea
EnemyDataLow = EnemyData
EnemyDataHigh = EnemyData+1

    .res 5 ; $eb-$ef

NoteLenLookupTblOfs:
    .res 1 ; $f0
Square1SoundBuffer:
    .res 1 ; $f1
Square2SoundBuffer:
    .res 1 ; $f2
NoiseSoundBuffer:
    .res 1 ; $f3
AreaMusicBuffer:
    .res 1 ; $f4
MusicData:
    .res 2 ; $f5-$f6
MusicOffset_Square2:
    .res 1 ; $f7
MusicOffset_Square1:
    .res 1 ; $f8
MusicOffset_Triangle:
    .res 1 ; $f9
PauseSoundQueue:
    .res 1 ; $fa
AreaMusicQueue:
    .res 1 ; $fb
EventMusicQueue:
    .res 1 ; $fc
NoiseSoundQueue:
    .res 1 ; $fd
Square2SoundQueue:
    .res 1 ; $fe
Square1SoundQueue:
    .res 1 ; $ff

.segment "MAIN_RAM" : absolute
    .res 9 ; $0100-$0108 (unused)

VerticalFlipFlag:
    .res 1 ; $0109
    .res 3 ; $010a-$010c (unused)

FlagpoleFNum_Y_Pos:
    .res 1 ; $010d
FlagpoleFNum_YMFDummy:
    .res 1 ; $010e
FlagpoleScore:
    .res 1 ; $010f

FloateyNum_Control:
    .res 6 ; $0110-$0115
    .res 1 ; $0116 (unused)
FloateyNum_X_Pos:
    .res 6 ; $0117-$011c
    .res 1 ; $011d (unused)
FloateyNum_Y_Pos:
    .res 6 ; $011e-$0123
    .res 1 ; $0124 (unused)
ShellChainCounter:
    .res 6 ; $0125-$012a
    .res 1 ; $012b (unused)
FloateyNum_Timer:
    .res 6 ; $012c-$0131
    .res 1 ; $0132 (unused)

    .res 1 ; $0133 (only used by DigitsMathRoutine)
DigitModifier:
    .res 6 ; $0134-$0139

    .res 38 ; $013a-$015f (unused)
    .res 160 ; $0160-$01ff (stack)

Sprite_Data:
    .res 256 ; $0200-$02ff (shadow OAM)
Sprite_Y_Position = Sprite_Data
Sprite_Tilenumber = Sprite_Data+1
Sprite_Attributes = Sprite_Data+2
Sprite_X_Position = Sprite_Data+3

VRAM_Buffer_Offset:
    .res 1 ; $0300
VRAM_Buffer:
    .res 98 ; $0301-$0362

BowserBodyControls:
    .res 1 ; $0363
BowserFeetCounter:
    .res 1 ; $0364
BowserMovementSpeed:
    .res 1 ; $0365
BowserOrigXPos:
    .res 1 ; $0366
BowserFlameTimerCtrl:
    .res 1 ; $0367
BowserFront_Offset:
    .res 1 ; $0368
BridgeCollapseOffset:
    .res 1 ; $0369
BowserGfxFlag:
    .res 1 ; $036a

; GAME SPECIFIC DEFINES

SavedJoypadBits       = $06fc
SavedJoypad1Bits      = $06fc
SavedJoypad2Bits      = $06fd
RawJoypadBits         = $074a
RawJoypad1Bits        = $074a
RawJoypad2Bits        = $074b
PressedJoypadBits     = $074c
PressedJoypad1Bits    = $074c
PressedJoypad2Bits    = $074d
JoypadOverride        = $0758

IRQAckFlag			  = $077b
IRQTimer_Low          = $077d
IRQTimer_High         = $077e
IRQUpdateFlag		  = $0722
NMIAckFlag            = $077c

Mirror_PPU_CTRL       = $0778
Mirror_PPU_MASK       = $0779
NameTableSelect       = $077a
FileListNumber        = $07f7

OperMode              = $0770
OperMode_Task         = $0772
ScreenRoutineTask     = $073c

DiskIOTask            = $07fc
NotColdFlag           = $07fd

GamePauseStatus       = $0776
GamePauseTimer        = $0777

DemoAction            = $0717
DemoActionTimer       = $0718

TimerControl          = $0747
IntervalTimerControl  = $077f

Timers                = $0780
SelectTimer           = $0780
PlayerAnimTimer       = $0781
JumpSwimTimer         = $0782
RunningTimer          = $0783
BlockBounceTimer      = $0784
SideCollisionTimer    = $0785
JumpspringTimer       = $0786
GameTimerCtrlTimer    = $0787
ClimbSideTimer        = $0789
EnemyFrameTimer       = $078a
FrenzyEnemyTimer      = $078f
BowserFireBreathTimer = $0790
StompTimer            = $0791
AirBubbleTimer        = $0792
ScrollIntervalTimer   = $0795
EnemyIntervalTimer    = $0796
BrickCoinTimer        = $079d
InjuryTimer           = $079e
StarInvincibleTimer   = $079f
ScreenTimer           = $07a0
WorldEndTimer         = $07a1
DemoTimer             = $07a2
GameOverMsgFlag       = $07f5

ScreenEdge_PageLoc    = $071a
ScreenEdge_X_Pos      = $071c
ScreenLeft_PageLoc    = $071a
ScreenRight_PageLoc   = $071b
ScreenLeft_X_Pos      = $071c
ScreenRight_X_Pos     = $071d

ScrollFractional      = $0768
SecondaryMsgCounter   = $0749
MsgCounter            = $0719
MsgFractional         = $0749

EndControlCntr        = $0761
BlueColorOfs          = $0762
BlueDelayFlag         = $0763
MushroomRetDelay      = $0764
MRetainerOffset       = $0762
CurrentFlashMRet      = $0763

HorizontalScroll      = $073f
VerticalScroll        = $0740
ScrollLock            = $0723
ScrollThirtyTwo       = $073d
Player_X_Scroll       = $06ff
Player_Pos_ForScroll  = $0755
ScrollAmount          = $0775

AreaParserTaskNum     = $071f
ColumnSets            = $071e
CurrentPageLoc        = $0725
CurrentColumnPos      = $0726
BackloadingFlag       = $0728
BehindAreaParserFlag  = $0729
AreaObjectPageLoc     = $072a
AreaObjectPageSel     = $072b
AreaDataOffset        = $072c
AreaObjOffsetBuffer   = $072d
AreaObjectLength      = $0730
StaircaseControl      = $0734
AreaObjectHeight      = $0735
MushroomLedgeHalfLen  = $0736
EnemyDataOffset       = $0739
EnemyObjectPageLoc    = $073a
EnemyObjectPageSel    = $073b
MetatileBuffer        = $06a1
BlockBufferColumnPos  = $06a0
CurrentNTAddr_Low     = $0721
CurrentNTAddr_High    = $0720
AttributeBuffer       = $03f9

LoopCommand           = $0745

DisplayDigits         = $07d7
TopScoreDisplay       = $07d7
ScoreAndCoinDisplay   = $07dd
PlayerScoreDisplay    = $07dd
GameTimerDisplay      = $07ec
CoinDisplay           = $07e7

FlagpoleCollisionYPos = $070f
StompChainCounter     = $0484
FlagpoleMusicFlag     = $07f6

VRAM_Buffer_AddrCtrl  = $0773
Sprite0HitDetectFlag  = $0722
DisableScreenFlag     = $0774
DisableIntermediate   = $0769
ColorRotateOffset     = $06d4

TerrainControl        = $0727
AreaStyle             = $0733
ForegroundScenery     = $0741
BackgroundScenery     = $0742
CloudTypeOverride     = $0743
BackgroundColorCtrl   = $0744
AreaType              = $074e
AreaAddrsLOffset      = $074f
AreaPointer           = $0750

PlayerEntranceCtrl    = $0710
GameTimerSetting      = $0715
AltEntranceControl    = $0752
EntrancePage          = $0751
WarpZoneControl       = $06d6
ChangeAreaTimer       = $06de

MultiLoopCorrectCntr  = $06d9
MultiLoopPassCntr     = $06da

FetchNewGameTimerFlag = $0757
GameTimerExpiredFlag  = $0759

PrimaryHardMode       = $076a
SecondaryHardMode     = $06cc
WorldSelectNumber     = $076b
CompletedWorlds       = $07fa
HardWorldFlag         = $07fb
ContinueMenuSelect    = $07f8

SelectedPlayer        = $0753
PlayerSize            = $0754
PlayerStatus          = $0756

OnscreenPlayerInfo    = $075a
NumberofLives         = $075a ;used by current player
HalfwayPage           = $075b
LevelNumber           = $075c ;the actual dash number
Hidden1UpFlag         = $075d
CoinTally             = $075e
WorldNumber           = $075f
AreaNumber            = $0760 ;internal number used to find areas

CoinTallyFor1Ups      = $0748

BalPlatformAlignment  = $03a0
Platform_X_Scroll     = $03a1
PlatformCollisionFlag = $03a2
YPlatformTopYPos      = $0401

BrickCoinTimerFlag    = $06bc
StarFlagTaskControl   = $0746

PseudoRandomBitReg    = $07a7
WarmBootValidation    = $07ff

SprShuffleAmtOffset   = $06e0
SprShuffleAmt         = $06e1
SprDataOffset         = $06e4
Player_SprDataOffset  = $06e4
Enemy_SprDataOffset   = $06e5
Block_SprDataOffset   = $06ec
Alt_SprDataOffset     = $06ec
Bubble_SprDataOffset  = $06ee
FBall_SprDataOffset   = $06f1
Misc_SprDataOffset    = $06f3
SprDataOffset_Ctrl    = $03ee

JumpspringAnimCtrl    = $070e
JumpspringForce       = $06db

SprObject_Rel_XPos    = $03ad
Player_Rel_XPos       = $03ad
Enemy_Rel_XPos        = $03ae
Fireball_Rel_XPos     = $03af
Bubble_Rel_XPos       = $03b0
Block_Rel_XPos        = $03b1
Misc_Rel_XPos         = $03b3

SprObject_Rel_YPos    = $03b8
Player_Rel_YPos       = $03b8
Enemy_Rel_YPos        = $03b9
Fireball_Rel_YPos     = $03ba
Bubble_Rel_YPos       = $03bb
Block_Rel_YPos        = $03bc
Misc_Rel_YPos         = $03be

SprObject_SprAttrib   = $03c4
Player_SprAttrib      = $03c4
Enemy_SprAttrib       = $03c5

SprObject_X_MoveForce = $0400
Enemy_X_MoveForce     = $0401

SprObject_YMF_Dummy   = $0416
Player_YMF_Dummy      = $0416
Enemy_YMF_Dummy       = $0417
Bubble_YMF_Dummy      = $042c

SprObject_Y_MoveForce = $0433
Player_Y_MoveForce    = $0433
Enemy_Y_MoveForce     = $0434
Block_Y_MoveForce     = $043c

DisableCollisionDet   = $0716
Player_CollisionBits  = $0490
Enemy_CollisionBits   = $0491

SprObj_BoundBoxCtrl   = $0499
Player_BoundBoxCtrl   = $0499
Enemy_BoundBoxCtrl    = $049a
Fireball_BoundBoxCtrl = $04a0
Misc_BoundBoxCtrl     = $04a2

EnemyFrenzyBuffer     = $06cb
EnemyFrenzyQueue      = $06cd

PlayerGfxOffset       = $06d5
PlayerDamageFlag      = $06d8
Player_XSpeedAbsolute = $0700
FrictionAdderHigh     = $0701
FrictionAdderLow      = $0702
RunningSpeed          = $0703
SwimmingFlag          = $0704
Player_X_MoveForce    = $0705
DiffToHaltJump        = $0706
JumpOrigin_Y_HighPos  = $0707
JumpOrigin_Y_Position = $0708
VerticalForce         = $0709
VerticalForceDown     = $070a
PlayerChangeSizeFlag  = $070b
PlayerAnimTimerSet    = $070c
PlayerAnimCtrl        = $070d
DeathMusicLoaded      = $0712
FlagpoleSoundQueue    = $0713
CrouchingFlag         = $0714
MaximumLeftSpeed      = $0450
MaximumRightSpeed     = $0456

WindFlag              = $07f9

SprObject_OffscrBits  = $03d0
Player_OffscreenBits  = $03d0
Enemy_OffscreenBits   = $03d1
FBall_OffscreenBits   = $03d2
Bubble_OffscreenBits  = $03d3
Block_OffscreenBits   = $03d4
Misc_OffscreenBits    = $03d6
EnemyOffscrBitsMasked = $03d8

Cannon_Offset         = $046a
Cannon_PageLoc        = $046b
Cannon_X_Position     = $0471
Cannon_Y_Position     = $0477
Cannon_Timer          = $047d

Whirlpool_Offset      = $046a
Whirlpool_PageLoc     = $046b
Whirlpool_LeftExtent  = $0471
Whirlpool_Length      = $0477
Whirlpool_Flag        = $047d

VineFlagOffset        = $0398
VineHeight            = $0399
VineObjOffset         = $039a
VineStart_Y_Position  = $039d

Block_Orig_YPos       = $03e4
Block_BBuf_Low        = $03e6
Block_Metatile        = $03e8
Block_PageLoc2        = $03ea
Block_RepFlag         = $03ec
Block_ResidualCounter = $03f0
Block_Orig_XPos       = $03f1

BoundingBox_UL_XPos   = $04ac
BoundingBox_UL_YPos   = $04ad
BoundingBox_DR_XPos   = $04ae
BoundingBox_DR_YPos   = $04af
BoundingBox_UL_Corner = $04ac
BoundingBox_LR_Corner = $04ae
EnemyBoundingBoxCoord = $04b0

FireballCounter       = $06ce
FireballThrowingTimer = $0711

HammerEnemyOffset     = $06ae
JumpCoinMiscOffset    = $06b7

Block_Buffer_1        = $0500
Block_Buffer_2        = $05d0

HammerThrowingTimer   = $03a2
Misc_Collision_Flag   = $06be

RedPTroopaOrigXPos    = $0401

CheepCheepOrigYPos    = $0434
BitMFilter            = $06dd

LakituReappearTimer   = $06d1

FirebarSpinSpeed      = $0388
FirebarSpinDirection  = $34

DuplicateObj_Offset   = $06cf
NumberofGroupEnemies  = $06d3

BowserHitPoints       = $0483
MaxRangeFromOrigin    = $06dc

BowserFlamePRandomOfs = $0417

PiranhaPlantUpYPos    = $0417
PiranhaPlantDownYPos  = $0434

FireworksCounter      = $06d7


;sound related defines
Squ2_NoteLenBuffer    = $07b3
Squ2_NoteLenCounter   = $07b4
Squ2_EnvelopeDataCtrl = $07b5
Squ1_NoteLenCounter   = $07b6
Squ1_EnvelopeDataCtrl = $07b7
Tri_NoteLenBuffer     = $07b8
Tri_NoteLenCounter    = $07b9
Noise_BeatLenCounter  = $07ba
Squ1_SfxLenCounter    = $07bb
Squ2_SfxLenCounter    = $07bd
Sfx_SecondaryCounter  = $07be
Noise_SfxLenCounter   = $07bf

EventMusicBuffer      = $07b1
PauseSoundBuffer      = $07b2

PatternNumber         = $061d

MusicOffset_Noise     = $07b0

DAC_Counter           = $07c0
NoiseDataLoopbackOfs  = $07c1
NoteLengthTblAdder    = $07c4
AreaMusicBuffer_Alt   = $07c5
PauseModeFlag         = $07c6
GroundMusicHeaderOfs  = $07c7
AltRegContentFlag     = $07ca
ContinueMusicFlag     = $07cb

;-------------------------------------------------------------------------------------
;CONSTANTS

;sound effects constants
Sfx_BigJump           = $01
Sfx_Bump              = $02
Sfx_EnemyStomp        = $03
Sfx_EnemySmack        = $04
Sfx_PipeDown_Injury   = $05
Sfx_Fireball          = $06
Sfx_Flagpole          = $07
Sfx_SmallJump         = $08

Sfx_CoinGrab          = $01
Sfx_GrowPowerUp       = $02
Sfx_GrowVine          = $03
Sfx_Blast             = $04
Sfx_TimerTick         = $05
Sfx_PowerUpGrab       = $06
Sfx_ExtraLife         = $07
Sfx_BowserFall        = $08
Sfx_CorrectPath       = $09

Sfx_BrickShatter      = $01
Sfx_BowserFlame       = $02
Sfx_Wind              = $03
Sfx_Skid              = $04

;music constants
Silence               = %10000000

SettingsMusic         = %01000000
PipeIntroMusic        = %00100000
Star_CloudMusic       = %00010000
CastleMusic           = %00001000
UndergroundMusic      = %00000100
WaterMusic            = %00000010
GroundMusic           = %00000001

TimeRunningOutMusic   = %01000000
EndOfLevelMusic       = %00100000
AltGameOverMusic      = %00010000
EndOfCastleMusic      = %00001000
VictoryMusic          = %00000100
GameOverMusic         = %00000010
DeathMusic            = %00000001

;enemy object constants 
GreenKoopa            = $00
BuzzyBeetle           = $02
RedKoopa              = $03
HammerBro             = $05
Goomba                = $06
Bloober               = $07
BulletBill_FrenzyVar  = $08
GreyCheepCheep        = $0a
RedCheepCheep         = $0b
Podoboo               = $0c
PiranhaPlant          = $0d
GreenParatroopaJump   = $0e
RedParatroopa         = $0f
GreenParatroopaFly    = $10
Lakitu                = $11
Spiny                 = $12
FlyCheepCheepFrenzy   = $14
FlyingCheepCheep      = $14
BowserFlame           = $15
Fireworks             = $16
BBill_CCheep_Frenzy   = $17
Stop_Frenzy           = $18
Bowser                = $2d
PowerUpObject         = $2e
VineObject            = $2f
FlagpoleFlagObject    = $30
StarFlagObject        = $31
JumpspringObject      = $32
BulletBill_CannonVar  = $33
RetainerObject        = $35
TallEnemy             = $09
UpsideDownPiranhaP    = $04

;other constants
World1 = 0
World2 = 1
World3 = 2
World4 = 3
World5 = 4
World6 = 5
World7 = 6
World8 = 7
World9 = 8
WorldA = 9
WorldB = 10
WorldC = 11
WorldD = 12
Level1 = 0
Level2 = 1
Level3 = 2
Level4 = 3

WarmBootOffset        = <$07d6
ColdBootOffset        = <$07fe
SoundMemory           = $07b0
SwimTileRepOffset     = PlayerGraphicsTable + $9e
MusicHeaderOffsetData = MusicHeaderData - 1
MHD                   = MusicHeaderData

A_Button              = %10000000
B_Button              = %01000000
Select_Button         = %00100000
Start_Button          = %00010000
Up_Dir                = %00001000
Down_Dir              = %00000100
Left_Dir              = %00000010
Right_Dir             = %00000001

AttractMode           = 0
GameMode              = 1
VictoryMode           = 2
GameOverMode          = 3

CHRBank               = 4
SoundBank             = 6
LevelsBank            = 8
LoaderBank            = 10
MainBank              = 12
FixedBank             = 15

FME7Command           = $8000
FME7Parameter         = $a000

FME7_IRQTimer_Low	  = $0e
FME7_IRQTimer_High	  = $0f
FME7_IRQTimer_Ctrl	  = $0d

WaterAnimCurrentBank  = $013a
WaterAnimTimer		  = $0788

PrincessGfxOffset     = $1760
TitleScreenGfxOffset  = $0f30

CHR_MENU              = 12
CHR_SMB1              = 0
CHR_SMB2              = 1

VRAM_STANDARD         = 0
VRAM_PAL_WATER        = 1
VRAM_PAL_GROUND       = 2
VRAM_PAL_UNDERGROUND  = 3
VRAM_PAL_CASTLE       = 4
VRAM_PAL_SNOW         = 5
VRAM_PAL_MUSHROOM     = 6
VRAM_PAL_BOWSER       = 7
VRAM_NT_COMPLETE      = 8
VRAM_NT_SMB1          = 9
VRAM_NT_SMB2          = 10
VRAM_NT_TOAD          = 11
VRAM_NT_PEACH_1ST     = 14
VRAM_NT_PEACH_2ND     = 18
VRAM_NT_CREDITS       = 29
VRAM_PAL_MENU         = 30