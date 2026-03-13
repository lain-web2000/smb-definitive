.segment "LOADER"
.org $8000

NameTableDestination = $08
TitleScrollOffset = $0a
TitleScrollAmount = $0b

StartLoader:
        ldx #$00                    ;disable NMIs and rendering
        stx PPU_CTRL
        stx PPU_MASK
        dex
        txs                         ;reset stack pointer
        ldy #WarmBootOffset         ;clear memory up to $07D6
        jsr InitializeMemory
        sta ContinueMenuSelect      ;reset menu selection
        jsr CheckSaveData
        lda #CHR_MENU               ;load CHR tiles for menu
        jsr FetchCHRPacketGroup
        lda #VRAM_PAL_MENU          ;queue menu palette
        sta VRAM_Buffer_AddrCtrl
        inc DisableScreenFlag       ;tell NMI to keep rendering disabled
        lda #$e7                    ;set IRQ timer value for scroll split
        sta IRQTimer_Low
        lda #$32
        sta IRQTimer_High
        lda #%10001000              ;set up pattern table arrangment
        jsr WritePPUReg1            ;and enable NMIs
@nmi_wait:
        lda NMIAckFlag              ;wait until NMI finishes
        beq @nmi_wait
        inc FrameCounter            ;increment frame counter for flashing palette
        jsr MenuStateMachine        ;run menu
        jsr ChangePalette
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
        .word PrepMenu
        .word RunMenu
        .word ScrollNewTitle
        .word LoadIntoGame

SubMenuStateMachine:
        lda OperMode_Task
        jsr JumpEngine

        .word RenderSubTilemap
        .word RunSubmenu
        .word DoNothing

;-------------------------------------------------------------------------------------

MainMenuSelections:
        .byte $20,$a6,20,"SUPER MARIO COMPLETE"
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

PrepMenu:
        lda #$00
        sta DisableScreenFlag
        jsr DrawMainMenuCursor
        inc IRQUpdateFlag
        inc OperMode_Task
        rts

MenuCursorData:
  .byte $04, $02

MenuCursorY:
  .byte $27, $2f, $37, $3f

MenuCursorX:
  .byte $27, $27, $27, $27

RunMenu:
        lda #<ContinueMenuSelect
        sta $00
        lda #>ContinueMenuSelect
        sta $01
        lda ContinueMenuSelect
        sta $03
        lda #$03
        jsr MenuSelectionLogic
        bcs CheckForSelection
        cpx #$00
        bne UpdateMenuSelection
        rts
UpdateMenuSelection:
        ldy #$08
        lda #0
        cpx #$02
        beq :+
        ldy #$f8
        lda #31
:       sty TitleScrollAmount
        sta TitleScrollOffset
        lda NameTableDestination
        eor #%00000001
        sta NameTableDestination
        inc OperMode_Task
DrawMainMenuCursor:
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

CheckForSelection:
        lda PressedJoypadBits
        and #Start_Button+A_Button
        bne DoSelection
        rts
DoSelection:
        inc DisableScreenFlag
        dec IRQUpdateFlag
        lda ContinueMenuSelect
        cmp #$03
        bne :+
        inc OperMode
        lda #$fe
        sta OperMode_Task
:       inc OperMode_Task
        inc OperMode_Task
        rts

WriteAttributeData:
        ldx VRAM_Buffer_Offset
        lda NameTableDestination
        asl
        asl
        clc
        adc #$23
        sta VRAM_Buffer,x
        lda #$d8
        sta VRAM_Buffer+1,x
        lda #$40+32
        sta VRAM_Buffer+2,x
        ldy #32
        lda #$55
        sta VRAM_Buffer+3,x
        lda #$00
        sta VRAM_Buffer+4,x
        txa
        clc
        adc #4
        sta VRAM_Buffer_Offset
        jmp SkipTitleColumn

ScrollNewTitle:
        lda ScreenEdge_X_Pos  ; lil' hacky
        beq WriteAttributeData
        lda TitleScrollOffset
        cmp #4
        bcc SkipTitleColumn
        cmp #29
        bcs SkipTitleColumn
        sta $00 ; col index
        sec
        sbc #4
        ldx #$02
        ldy #4
        jsr MultByPow2
        lda ContinueMenuSelect
        asl
        tax
        lda GameTitlePointers,x
        clc
        adc $02
        sta $02
        lda GameTitlePointers+1,x
        adc $03
        sta $03
        lda NameTableDestination
        asl
        asl
        sta $01 ; nt << 2
        ldx VRAM_Buffer_Offset
        lda #$80
        clc
        adc $00
        sta VRAM_Buffer+1,x
        lda #$21
        adc $01
        sta VRAM_Buffer,x
        lda #$80+16
        sta VRAM_Buffer+2,x
        ldy #$00
CopyTitleColumn:
        lda ($02),y
        sta VRAM_Buffer+3,x
        inx
        iny
        cpy #16
        bcc CopyTitleColumn
        lda #$00
        sta VRAM_Buffer+3,x
        txa
        clc
        adc #3
        sta VRAM_Buffer_Offset
SkipTitleColumn:
        lda TitleScrollAmount
        bpl ScrollRight
        eor #$ff
        clc
        adc #$01
        sta $00
        lda ScreenEdge_X_Pos
        sec
        sbc $00
        sta ScreenEdge_X_Pos
        bcs :+
        lda ScreenEdge_PageLoc
        eor #%00000001
        sta ScreenEdge_PageLoc
:       dec TitleScrollOffset
        bpl ExitTitleScroll
        bmi StopTitleScroll
ScrollRight:
        clc
        adc ScreenEdge_X_Pos
        sta ScreenEdge_X_Pos
        bcc :+
        lda ScreenEdge_PageLoc
        eor #%00000001
        sta ScreenEdge_PageLoc
:       inc TitleScrollOffset
        lda TitleScrollOffset
        cmp #32
        bcc ExitTitleScroll
StopTitleScroll:
        dec OperMode_Task
        lda #$00
        sta TitleScrollOffset
ExitTitleScroll:
        rts

GameTitlePointers:
        .word SMBCompleteTitle
        .word SMB1Title
        .word SMB2Title
        .word OptionsGraphic

SMBCompleteTitle:
        ;.byte 5, $23, $d8, $40+32, $55
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $cf, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d4, $24
        .byte $d0, $de, $e0, $e2, $e4, $de, $e9, $e9, $e9, $e9, $ef, $de, $e9, $e2, $d9, $24
        .byte $d0, $df, $e1, $e3, $e5, $f6, $f2, $e9, $e9, $e9, $ef, $e8, $eb, $e8, $db, $24
        .byte $d0, $e6, $e9, $e2, $e4, $df, $f2, $e9, $e9, $e9, $ef, $de, $e9, $e2, $d9, $24
        .byte $d0, $e6, $e9, $e7, $e5, $de, $e9, $e9, $ec, $e9, $ef, $df, $f2, $e7, $da, $24
        .byte $d0, $ec, $e9, $e9, $ef, $df, $f2, $e9, $f5, $f2, $ef, $de, $e9, $e9, $d7, $24
        .byte $d0, $df, $e7, $f0, $5d, $ec, $e9, $e9, $e9, $e9, $ef, $f6, $f2, $e9, $d7, $24
        .byte $d0, $de, $e9, $e2, $e4, $df, $f2, $ed, $ee, $e9, $ef, $df, $f2, $e9, $d7, $24
        .byte $d0, $e8, $ea, $e8, $eb, $e6, $e9, $e9, $e9, $e9, $ef, $ec, $e9, $e9, $d7, $24
        .byte $d0, $ec, $e9, $e9, $ef, $de, $e9, $e9, $e9, $e2, $e4, $df, $e7, $f0, $d5, $24
        .byte $d0, $df, $ed, $ee, $ef, $df, $f2, $e9, $e9, $e7, $e5, $e6, $e9, $e2, $d9, $24
        .byte $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $e8, $db, $24
        .byte $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $ef, $de, $e9, $e2, $d9, $24
        .byte $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e7, $f0, $e8, $ea, $e8, $db, $24
        .byte $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $ef, $ec, $fb, $fd, $dc, $24
        .byte $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e9, $ef, $e8, $fc, $fe, $dd, $24
        .byte $d0, $5d, $5d, $5d, $5d, $de, $e9, $e9, $e9, $e2, $e4, $de, $e9, $e2, $d9, $24
        .byte $d0, $5d, $5d, $5d, $5d, $df, $f2, $e9, $e9, $e7, $e5, $e8, $ea, $e8, $db, $24
        .byte $d0, $5d, $5d, $5d, $5d, $de, $e9, $e0, $f4, $e2, $e4, $5d, $5d, $5d, $d5, $24
        .byte $d0, $5d, $5d, $5d, $5d, $df, $f2, $f3, $f1, $e7, $e5, $5d, $5d, $5d, $d5, $24
        .byte $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $e6, $ef, $5d, $5d, $5d, $d5, $24
        .byte $d1, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d6, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24

SMB1Title:
        ;.byte 5, $23, $d8, $40+32, $55
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $cf, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d4, $24, $24, $24
        .byte $24, $24, $d0, $de, $e0, $e2, $e4, $de, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $df, $e1, $e3, $e5, $f6, $f2, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e6, $e9, $e2, $e4, $df, $f2, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e6, $e9, $e7, $e5, $de, $e9, $e9, $ec, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $ec, $e9, $e9, $ef, $df, $f2, $e9, $f5, $f2, $d7, $24, $24, $24
        .byte $24, $24, $d0, $df, $e7, $f0, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $de, $e9, $e2, $e4, $df, $f2, $ed, $ee, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e8, $ea, $e8, $eb, $e6, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $ec, $e9, $e9, $ef, $de, $e9, $e9, $e9, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $df, $ed, $ee, $ef, $df, $f2, $e9, $e9, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $d5, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e7, $d8, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $de, $e9, $e9, $e9, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $e9, $e9, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $de, $e9, $e0, $f4, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $f3, $f1, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $e6, $d7, $24, $24, $24
        .byte $24, $24, $d1, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d6, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24

SMB2Title:
        ;.byte 36, $23, $d8, 32, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $d5, $55, $55, $55, $55, $55, $55, $55, $dd, $55, $55, $55, $55, $55, $55, $55, $55, $55
        .byte $24, $24, $cf, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $d4, $24, $24, $24
        .byte $24, $24, $d0, $de, $e0, $e2, $e4, $de, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $df, $e1, $e3, $e5, $f6, $f2, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e6, $e9, $e2, $e4, $df, $f2, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e6, $e9, $e7, $e5, $de, $e9, $e9, $ec, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $ec, $e9, $e9, $ef, $df, $f2, $e9, $f5, $f2, $d7, $24, $24, $24
        .byte $24, $24, $d0, $df, $e7, $f0, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $de, $e9, $e2, $e4, $df, $f2, $ed, $ee, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $e8, $ea, $e8, $eb, $e6, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $ec, $e9, $e9, $ef, $de, $e9, $e9, $e9, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $df, $ed, $ee, $ef, $df, $f2, $e9, $e9, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $d5, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e7, $d8, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $ec, $e9, $e9, $e9, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $ed, $ee, $e9, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $de, $e9, $e9, $e9, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $e9, $e9, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $de, $e9, $e0, $f4, $e2, $d9, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $f3, $f1, $e7, $da, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $e6, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $5d, $d5, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $de, $e9, $f7, $f9, $ec, $d7, $24, $24, $24
        .byte $24, $24, $d0, $5d, $5d, $5d, $5d, $df, $f2, $f8, $fa, $e8, $db, $24, $24, $24
        .byte $24, $24, $d1, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d3, $d6, $24, $24, $24

OptionsGraphic:

;-------------------------------------------------------------------------------------

SubMenuSelections:
        ; header
        .byte $20,$6a,12,"GAME OPTIONS"
        ; selection names
        .byte $20,$a6,10,"DIFFICULTY"
        .byte $20,$c6,13,"MARIO PALETTE"
        .byte $20,$e6,13,"LUIGI PALETTE"
        .byte $21,$06,13,"LUIGI PHYSICS"
        .byte $21,$26,18,"SPINY EGG BEHAVIOR"
        .byte $21,$46,16,"WARP ZONE SCROLL"
        .byte $21,$66,11,"TIMER SPEED"
        .byte $21,$86,14,"FONT SELECTION"
        .byte $21,$a6,17,"TILESET SELECTION"
        .byte $21,$c6,14,"ANIMATED TILES"
        .byte $00

        ;note to self - FIX THE BUFFER OVERFLOW!!!
SubMenuSelections_End:

RenderSubTilemap:
        jsr MoveAllSpritesOffscreen
        jsr InitializeNameTables
        ; draw box
        ldx #4
        ldy #4
        lda #22
        sta $00
        lda #10
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
        ldx #9*2
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
  .byte $27, $2f, $37, $3f, $47, $4f, $57, $5f, $67, $6f

SubMenuCursorX:
  .byte $27, $27, $27, $27, $27, $27, $27, $27, $27, $27

SubMenuOptions:
  .word DifficultyFlag, MarioPalette, LuigiPalette
  .word LuigiPhysics, SpinyEggBehavior, WarpZoneScroll
  .word CountdownSpeed, FontSelection, TilesetSelection
  .word AnimatedTiles

SubMenuOptionCount:
  .byte 3, 3, 4
  .byte 2, 2, 2
  .byte 3, 3, 3
  .byte 2

RunSubmenu:
        ; (TO-DO: Implement proper nesting of menus)
        lda #$00
        sta DisableScreenFlag
        lda #<ContinueMenuSelect
        sta $00
        lda #>ContinueMenuSelect
        sta $01
        lda #$09
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
        ldy #5
        jsr MultByPow2
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

Palette3Packet:
        .byte $3f, $0d, 1, $27

Palette3Colors:
        .byte $27, $27, $27, $17, $07, $17

ChangePalette:
        lda FrameCounter
        and #%00000111
        bne :+
        ldy #$00
        ldx VRAM_Buffer_Offset
        stx $00
WritePalette3Packet:
        lda Palette3Packet,y
        sta VRAM_Buffer,x
        inx
        iny
        cpy #$04
        bcc WritePalette3Packet
        lda #$00
        sta VRAM_Buffer,x
        stx VRAM_Buffer_Offset
        inc ColorRotateOffset
        lda ColorRotateOffset
        cmp #$06
        bcc Palette3InRange
        lda #$00
Palette3InRange:
        sta ColorRotateOffset
        tay
        ldx $00
        lda Palette3Colors,y
        sta VRAM_Buffer+3,x
:       rts

;-------------------------------------------------------------------------------------
; HELPER FUNCTIONS

; A: multiplicand to be multiplied by 2^Y
; X: location of 16-bit product in zero page
; Y; exponent of multiplier 2^Y
MultByPow2:
    sta $00,x
    lda #$00
    sta $01,x
:   asl $00,x
    rol $01,x
    dey
    bne :-
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
        ldy #5
        jsr MultByPow2
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
        ldy #5
        jsr MultByPow2
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
        jsr CopyDemoData
        jmp BootIntoGame

CopyDemoData:
		lda CurrentGame
		cmp #$02
		beq isSMB2		
isSMB1orComp:
		ldx #DemoTimingDataEnd-DemoTimingData
:		lda DemoTimingData_SMB1,x
		sta DemoTimingData,x
		dex 
		bpl :-	
		ldx #DemoActionDataEnd-DemoActionData
:		lda DemoActionData_SMB1,x
		sta DemoActionData,x
		dex 
		bpl :-
		rts
isSMB2:
		ldx #DemoTimingDataEnd-DemoTimingData
:		lda DemoTimingData_SMB2,x
		sta DemoTimingData,x
		dex 
		bpl :-	
		ldx #DemoActionDataEnd-DemoActionData
:		lda DemoActionData_SMB2,x
		sta DemoActionData,x
		dex 
		bpl :-
		rts

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
	  
DemoActionData_SMB1:
      .byte $01, $80, $02, $81, $41, $80, $01
      .byte $42, $c2, $02, $80, $41, $c1, $41, $c1
      .byte $01, $c1, $01, $02, $80, $00

DemoTimingData_SMB1:
      .byte $9b, $10, $20, $09, $34, $20, $24
      .byte $15, $5a, $10, $20, $28, $30, $20, $18
      .byte $50, $20, $30, $40, $03, $7f, $00
	  
DemoActionData_SMB2:
      .byte $01, $81, $01, $81, $01, $81, $02, $01
      .byte $81, $00, $81, $00, $80, $01, $81, $01
      .byte $00, $00, $00, $00, $00

DemoTimingData_SMB2:
      .byte $b0, $10, $10, $10, $28, $10, $28, $06
      .byte $10, $10, $0c, $80, $10, $28, $08, $90
      .byte $ff, $00, $00, $00, $00, $00
  
DifficultyPresets:
      
EasyPreset:
      .byte $00, $00, $00, $01, $00, $00, $00, $00, $00, $01
NormalPreset:
      .byte $01, $00, $00, $01, $00, $00, $00, $00, $00, $01
HardPreset:
      .byte $02, $00, $00, $00, $00, $00, $01, $00, $00, $01
ExpertPreset:
      .byte $02, $00, $00, $00, $01, $01, $01, $00, $00, $01
