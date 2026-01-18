.segment "LOADER"
.org $8000

StartLoader:
        ldx #$00                    ;disable NMIs and rendering
        stx PPU_CTRL
        stx PPU_MASK
        dex
        txs                         ;reset stack pointer
        ldy #WarmBootOffset         ;clear memory up to $07D6
        jsr InitializeMemory
        sta ContinueMenuSelect      ;reset menu selection
        lda #CHR_MENU               ;load CHR tiles for menu
        jsr FetchCHRPacketGroup
        lda #$20                    ;queue menu palette
        sta VRAM_Buffer_AddrCtrl
        inc DisableScreenFlag       ;tell NMI to keep rendering disabled
        lda #%10001000              ;set up pattern table arrangment
        jsr WritePPUReg1            ;and enable NMIs
@nmi_wait:
        lda NMIAckFlag
        beq @nmi_wait
        jsr MenuStateMachine
        lda #$00                    ;clear NMI flag and wait for next NMI
        sta NMIAckFlag
        beq @nmi_wait

;-------------------------------------------------------------------------------------

MenuStateMachine:
        lda OperMode
        jsr JumpEngine

        .word MainMenuStateMachine
        .word SubMenuStateMachine

MainMenuStateMachine:
        lda OperMode_Task
        jsr JumpEngine

        .word RenderMainTilemap
        .word RunMenu
        .word LoadIntoGame

SubMenuStateMachine:
        lda OperMode_Task
        jsr JumpEngine

        .word RenderSubTilemap
        .word RunSubmenu
        .word DoNothing

;-------------------------------------------------------------------------------------

MainMenuSelections:
        .byte $20,$a6,14,"MARIO COMPLETE"
        .byte $20,$c6,19,"SUPER MARIO BROS. 1"
        .byte $20,$e6,19,"SUPER MARIO BROS. 2"
        .byte $21,$06,7,"OPTIONS"
        .byte $00
MainMenuSelections_End:

RenderMainTilemap:
        jsr MoveAllSpritesOffscreen
        jsr InitializeNameTables
        ldx #4 ; draw box
        ldy #4
        lda #22
        sta $00
        lda #4
        sta $01
        jsr DrawArbitraryTextbox
        ldy #0
        ldx VRAM_Buffer_Offset
:       lda MainMenuSelections,y
        sta VRAM_Buffer,x
        inx
        iny
        cpy #MainMenuSelections_End-MainMenuSelections
        bcc :-
        dex
        stx VRAM_Buffer_Offset
        inc OperMode_Task
        rts

MenuCursorData:
  .byte $04, $02

MenuCursorY:
  .byte $27, $2f, $37, $3f

MenuCursorX:
  .byte $27, $27, $27, $27

RunMenu:
        lda #$00
        sta DisableScreenFlag
        lda #<ContinueMenuSelect
        sta $00
        lda #>ContinueMenuSelect
        sta $01
        lda #$03
        jsr MenuSelectionLogic
        bcc DrawCursor
        lda PressedJoypadBits
        and #Start_Button+A_Button
        bne DoSelection
DrawCursor:
        ldy #$01
:       lda MenuCursorData,y     ;set up cursor sprite tile, attribute
        sta Sprite_Data+1,y      ;and X position in sprite OAM data
        dey
        bpl :-
        ldy ContinueMenuSelect
        lda MenuCursorY,y        ;set Y position based on the selection
        sta Sprite_Data
        lda MenuCursorX,y        ;set X position based on the selection
        sta Sprite_Data+3
        rts
DoSelection:
        inc DisableScreenFlag
        lda ContinueMenuSelect
        cmp #$03
        bne :+
        inc OperMode
        lda #$ff
        sta OperMode_Task
:       inc OperMode_Task
        rts

;-------------------------------------------------------------------------------------

SubMenuSelections:
        ; selection names
        .byte $20,$a6,10,"DIFFICULTY"
        .byte $20,$c6,13,"MARIO PALETTE"
        .byte $20,$e6,13,"LUIGI PALETTE"
        .byte $21,$06,13,"LUIGI PHYSICS"
        .byte $21,$26,18,"SPINY EGG BEHAVIOR"
        .byte $21,$46,16,"WARP ZONE SCROLL"
        .byte $21,$66,14,"FONT SELECTION"
        .byte $21,$86,17,"TILESET SELECTION"
        .byte $21,$a6,14,"ANIMATED TILES"
        .byte $00
SubMenuSelections_End:

RenderSubTilemap:
        jsr MoveAllSpritesOffscreen
        jsr InitializeNameTables
        ; draw box
        ldx #4
        ldy #4
        lda #22
        sta $00
        lda #9
        sta $01
        jsr DrawArbitraryTextbox
        ; copy selection names over
        ldy #0
        ldx VRAM_Buffer_Offset
:       lda SubMenuSelections,y
        sta VRAM_Buffer,x
        inx
        iny
        cpy #SubMenuSelections_End-SubMenuSelections
        bcc :-
        dex
        stx VRAM_Buffer_Offset
        ; draw option numbers
        ldy #$00
        ldx #8*2
:       txa
        pha
        lda SubMenuOptions,x
        sta $00
        lda SubMenuOptions+1,x
        sta $01
        txa
        lsr
        jsr RenderOptionNum
        pla
        tax
        dex
        dex
        bpl :-
        inc OperMode_Task
        lda #SettingsMusic
        sta AreaMusicQueue
        rts

SubMenuCursorY:
  .byte $27, $2f, $37, $3f, $47, $4f, $57, $5f, $67

SubMenuCursorX:
  .byte $27, $27, $27, $27, $27, $27, $27, $27, $27

SubMenuOptions:
  .word DifficultyFlag, MarioPalette, LuigiPalette
  .word LuigiPhysics, SpinyEggBehavior, WarpZoneScroll
  .word FontSelection, TilesetSelection, AnimatedTiles

SubMenuOptionCount:
  .byte 3, 3, 4
  .byte 2, 2, 2
  .byte 3, 3, 2

RunSubmenu:
        ; (TO-DO: Implement proper nesting of menus)
        lda #$00
        sta DisableScreenFlag
        lda #<ContinueMenuSelect
        sta $00
        lda #>ContinueMenuSelect
        sta $01
        lda #$08
        jsr MenuSelectionLogic
        bcc DrawSubmenuCursor
        lda PressedJoypadBits
        and #B_Button
        bne ExitSubMenu
        lda PressedJoypadBits
        and #A_Button
        bne AdvanceOption
        rts
ExitSubMenu:
        lda #$00
        sta OperMode
        sta OperMode_Task
        sta ContinueMenuSelect
        lda #Silence
        sta AreaMusicQueue
        inc DisableScreenFlag
        rts
DrawSubmenuCursor:
        ldy #$01
:       lda MenuCursorData,y     ;set up cursor sprite tile, attribute
        sta Sprite_Data+1,y      ;and X position in sprite OAM data
        dey
        bpl :-
        ldy ContinueMenuSelect
        lda SubMenuCursorY,y        ;set Y position based on the selection
        sta Sprite_Data
        lda SubMenuCursorX,y        ;set X position based on the selection
        sta Sprite_Data+3
        rts
AdvanceOption:
        lda ContinueMenuSelect
        tax
        asl
        tay
        lda SubMenuOptions,y
        sta $00
        lda SubMenuOptions+1,y
        sta $01
        ldy #$00
        lda ($00),y
        clc
        adc #$01
        cmp SubMenuOptionCount,x
        bcc :+
        lda #$00
:       sta ($00),y
        lda ContinueMenuSelect
RenderOptionNum:
        ldx #$02
        jsr MultBy32
        lda #$b9
        clc
        adc $02
        ldx VRAM_Buffer_Offset
        sta VRAM_Buffer+1,x
        lda #$20
        adc $03
        sta VRAM_Buffer,x
        lda #$01
        sta VRAM_Buffer+2,x
        lda ($00),y
        sta VRAM_Buffer+3,x
        lda #$00
        sta VRAM_Buffer+4,x
        txa
        clc
        adc #$04
        sta VRAM_Buffer_Offset
        rts

DoNothing:
        rts

;-------------------------------------------------------------------------------------
; HELPER FUNCTIONS

; A: multiplicand to be multiplied by 32
; X: location of 16-bit product in zero page
MultBy32:
    sta $00,x
    lda #$00
    sta $01,x
    asl $00,x
    rol $01,x
    asl $00,x
    rol $01,x
    asl $00,x
    rol $01,x
    asl $00,x
    rol $01,x
    asl $00,x
    rol $01,x
    rts

BaseTextbox:
        .byte $20,$00,$01,$c9 ; top left corner
        .byte $20,$01,$40,$cb ; top border
        .byte $20,$01,$01,$cc ; top right corner
        .byte $20,$20,$c0,$cd ; left border
        .byte $20,$21,$c0,$cd ; right border
        .byte $20,$20,$01,$ca ; bottom left corner
        .byte $20,$21,$40,$cb ; bottom border
        .byte $20,$21,$01,$ce ; bottom right corner

; X = top left corner X location
; Y = top left corner Y location
; $00 = internal width
; $01 = internal height
DrawArbitraryTextbox:
        ; get base NT location in $02-$03
        txa
        pha
        ldx #$02
        tya
        jsr MultBy32
        pla
        clc
        adc $02
        sta $02
        lda #$20
        adc $03
        sta $03
        ; write base textbox packet to VRAM buffer
        ldy #0
        ldx VRAM_Buffer_Offset
:       lda BaseTextbox,x
        sta VRAM_Buffer,y
        inx
        iny
        cpy #32
        bcc :-
        lda #$00
        sta VRAM_Buffer,x
        txa
        stx VRAM_Buffer_Offset
        ; set border lengths
        lda $00
        clc
        adc #$40
        sta VRAM_Buffer+6
        sta VRAM_Buffer+26
        lda $01
        clc
        adc #$c0
        sta VRAM_Buffer+14
        sta VRAM_Buffer+18
        ; adjust width/height for later math
        inc $00
        inc $01
        ldx #$04
        lda $01
        jsr MultBy32
        ; set top left corner and top border
        lda $02
        sta VRAM_Buffer+1
        clc
        adc #$01
        sta VRAM_Buffer+5
        lda $03
        sta VRAM_Buffer
        adc #$00
        sta VRAM_Buffer+4
        ; set top right corner
        lda $02
        clc
        adc $00
        sta VRAM_Buffer+9
        lda $03
        adc #$00
        sta VRAM_Buffer+8
        ; set left border
        lda $02
        clc
        adc #$20
        sta VRAM_Buffer+13
        lda $03
        adc #$00
        sta VRAM_Buffer+12
        ; set right border
        lda VRAM_Buffer+9
        clc
        adc #$20
        sta VRAM_Buffer+17
        lda VRAM_Buffer+8
        adc #$00
        sta VRAM_Buffer+16
        ; set bottom left corner
        lda VRAM_Buffer+1
        clc
        adc $04
        sta VRAM_Buffer+21
        lda VRAM_Buffer
        adc $05
        sta VRAM_Buffer+20
        ; set bottom border
        lda VRAM_Buffer+5
        clc
        adc $04
        sta VRAM_Buffer+25
        lda VRAM_Buffer+4
        adc $05
        sta VRAM_Buffer+24
        ; set bottom right corner
        lda VRAM_Buffer+9
        clc
        adc $04
        sta VRAM_Buffer+29
        lda VRAM_Buffer+8
        adc $05
        sta VRAM_Buffer+28
        rts

;-------------------------------------------------------------------------------------

LoadIntoGame:
        lda ContinueMenuSelect
        sta CurrentGame
        jsr LoadFontTileset
        jsr CopyFrictionData
        jsr CopyPaletteData
        jmp BootIntoGame

CopyFrictionData:
        lda LuigiPhysics
        beq PatchPhysics_FDS
        ldx #$02
PatchPhysics_SNES:
        lda LuigiFrictionData_SNES,x
        sta LuigiFrictionData,x
        dex
        bpl PatchPhysics_SNES
        rts
PatchPhysics_FDS:
        ldx #$02
FDSLoop:
        lda LuigiFrictionData_FDS,x
        sta LuigiFrictionData,x
        dex
        bpl FDSLoop
        rts
        
CopyPaletteData:
        ldy MarioPalette
        lda MarioPaletteOffsets,y
        tay
        ldx #$03
CopyMarioPalette:
        lda MarioPaletteData,y   ;overwrite palette with the appropriate one
        sta PlayerColors,x
        dey
        dex
        bpl CopyMarioPalette

CopyLuigiPaletteData:
        ldy LuigiPalette
        lda LuigiPaletteOffsets,y
        tay
        ldx #$03
CopyLuigiPalette:
        lda LuigiPaletteData,y   ;overwrite palette with the appropriate one
        sta PlayerColors+4,x
        dey
        dex
        bpl CopyLuigiPalette

CopyFireMarioPaletteData:
        ldy MarioPalette
        lda FireMarioPaletteOffsets,y
        tay
        ldx #$03
CopyFireMarioPalette:
        lda FireMarioPaletteData,y   ;overwrite palette with the appropriate one
        sta PlayerFireColors,x
        dey
        dex
        bpl CopyFireMarioPalette
        
CopyFireLuigiPaletteData:
        ldy LuigiPalette
        lda FireLuigiPaletteOffsets,y
        tay
        ldx #$03
CopyFireLuigiPalette:
        lda FireLuigiPaletteData,y   ;overwrite palette with the appropriate one
        sta PlayerFireColors+4,x
        dey
        dex
        bpl CopyFireLuigiPalette
        rts


LuigiFrictionData_SNES:
      .byte $e4, $98, $d0

LuigiFrictionData_FDS:
      .byte $b4, $68, $a0


MarioPaletteOffsets:
      .byte $03, $07, $0B      ;note that offsets point to last byte
 
LuigiPaletteOffsets:
      .byte $03, $07, $0B, $03 ;note that offsets point to last byte

FireMarioPaletteOffsets:
      .byte $03, $07, $03      ;note that offsets point to last byte

FireLuigiPaletteOffsets:
      .byte $03, $07, $0B, $0F ;note that offsets point to last byte

MarioPaletteData:
      .byte $22, $16, $27, $18 ;mario's normal colors
      .byte $22, $16, $35, $02 ;mario's first prototype colors
      .byte $22, $16, $27, $11 ;mario's second prototype colors
      
LuigiPaletteData:
      .byte $22, $30, $27, $19 ;luigi's normal colors
      .byte $22, $1b, $36, $18 ;luigi's disk writer colors
      .byte $22, $1a, $27, $18 ;luigi's smbdx colors
      
FireMarioPaletteData:
      .byte $22, $37, $27, $16 ;mario's colors after grabbing fire flower
      .byte $22, $27, $36, $16 ;custom fire palette to accompany prototype colors
      
FireLuigiPaletteData:
      .byte $22, $37, $27, $16 ;mario's colors after grabbing fire flower
      .byte $22, $27, $36, $16 ;custom fire palette to accompany prototype colors
      .byte $22, $30, $27, $19 ;luigi's smbdx colors after grabbing fire flower
      .byte $22, $29, $27, $16 ;luigi's smm2 colors after grabbing fire flower