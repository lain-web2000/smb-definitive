.include "inc/famistudio.inc"
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
        ldy #<Memory_ColdBoot       ;clear memory up to $07fe
        ldx #>Memory_ColdBoot
        jsr InitializeMemory
        jsr CheckSaveData
        lda #$03
        sta FME7Command
        lda #CHR_MENU               ;load CHR tiles for menu
        sta FME7Parameter
        lda #VRAM_PAL_MENU          ;queue menu palette
        sta VRAM_Buffer_AddrCtrl
        inc DisableScreenFlag       ;tell NMI to keep rendering disabled
        lda #0
        sta Mirror_PPU_SCROLL1      ;set scroll before split
        sta Mirror_PPU_SCROLL2
        lda #0                      ;init famistudio sound driver
        sta SoundEngineSet
        ldy #>music_data_smb_complete_menu
        ldx #<music_data_smb_complete_menu
        jsr famistudio_init
        lda #0                      ;play menu song
        jsr famistudio_music_play
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
        .word RenderTitleScreen
        .word PrepMenu
        .word RunMenu
        .word ScrollNewTitle
        .word LoadIntoGame

SubMenuStateMachine:
        lda OperMode_Task
        jsr JumpEngine

        .word Opt_Init
        .word Opt_ClearScreen
        .word Opt_Prep
        .word Opt_Run

DoNothing:
        rts

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
        lda #0
        sta $06
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
        lda #0
        sta IRQUpdateFlag
        rts

RenderTitleScreen:
        lda TitleScrollOffset
        bne DrawNextFiveColumns
        sta NameTableDestination
        jsr WriteAttributeData
        lda #4
        sta TitleScrollOffset
DrawNextFiveColumns:
        clc
        adc #5
        sta $04
        cmp #30
        bcs DoneWithTitleScreen
DrawTitleColumnsLoop:
        jsr WriteTitleColumn
        inc TitleScrollOffset
        lda TitleScrollOffset
        cmp $04
        bcc DrawTitleColumnsLoop
        rts
DoneWithTitleScreen:
        inc OperMode_Task
        rts

PrepMenu:
        lda #$00
        sta DisableScreenFlag
        jsr DrawMainMenuCursor
        lda #$40                    ;set IRQ select for scroll split
        sta IRQSelect
        lda #$e7                    ;set IRQ timer value for scroll split
        sta IRQTimer_Low
        lda #$32
        sta IRQTimer_High
        inc IRQUpdateFlag
        lda #$00                    ;set scroll position before split
        sta Mirror_PPU_SCROLL1
        sta Mirror_PPU_SCROLL2
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
        jsr WriteAttributeData
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
        rts

ScrollNewTitle:
        jsr WriteTitleColumn
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

WriteTitleColumn:
        lda TitleScrollOffset
        cmp #4
        bcc SkipTitleColumn
        cmp #29
        bcs SkipTitleColumn
        sta $00 ; col index
        ldy ContinueMenuSelect
        cpy #$03
        bne UseScrollOffset
        lda #4
UseScrollOffset:
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
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24

;-------------------------------------------------------------------------------------

Opt_RowIndex = $e0
Opt_GfxAddr = $e1
Opt_GfxPtr = $e3
Opt_TopRow = $e6
Opt_CursorY = $e7
Opt_ScrollType = $e8
Opt_TargetRow = $e9

Opt_SelIndex = $ea
; sel struct
Opt_SelStruct = $eb
Opt_SelMemory = $ed
Opt_OptionCount = $ef

Opt_GfxAddrLo = Opt_GfxAddr
Opt_GfxAddrHi = Opt_GfxAddr+1
Opt_GfxPtrLo = Opt_GfxPtr
Opt_GfxPtrHi = Opt_GfxPtr+1
Opt_SelStructLo = Opt_SelStruct
Opt_SelStructHi = Opt_SelStruct+1
Opt_SelMemoryLo = Opt_SelMemory
Opt_SelMemoryHi = Opt_SelMemory+1

Opt_VisibleRows = 20

Opt_GfxBlank:
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
Opt_GfxTop:
        .byte $c9, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb
        .byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb
        .byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cc
Opt_GfxEmpty:
        .byte $cd, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $cd
Opt_GfxBottom:
        .byte $ca, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb
        .byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb
        .byte $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $cb, $ce

Opt_GfxDifficulty:
        .byte $cd, $24
        .byte "DIFFICULTY"
        .byte "................"
        .byte $24, $cd
Opt_GfxMarioPalette:
        .byte $cd, $24
        .byte "MARIO PALETTE"
        .byte "............."
        .byte $24, $cd
Opt_GfxLuigiPalette:
        .byte $cd, $24
        .byte "LUIGI PALETTE"
        .byte "............."
        .byte $24, $cd
Opt_GfxLuigiPhysics:
        .byte $cd, $24
        .byte "LUIGI PHYSICS"
        .byte "............."
        .byte $24, $cd
Opt_GfxSpinyEggBehavior1:
        .byte $cd, $24
        .byte "SPINY EGG"
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24
        .byte $24, $cd
Opt_GfxSpinyEggBehavior2:
        .byte $cd, $24
        .byte "BEHAVIOR"
        .byte ".................."
        .byte $24, $cd
Opt_GfxWarpZoneScroll:
        .byte $cd, $24
        .byte "WARP ZONE SCROLL"
        .byte ".........."
        .byte $24, $cd
Opt_GfxTimerSpeed:
        .byte $cd, $24
        .byte "TIMER SPEED"
        .byte "..............."
        .byte $24, $cd
Opt_GfxFontSelection:
        .byte $cd, $24
        .byte "FONT SELECTION"
        .byte "............"
        .byte $24, $cd
Opt_GfxTilesetSelection1:
        .byte $cd, $24
        .byte "TILESET"
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $24, $24, $24, $24, $24, $24, $24, $24
        .byte $24, $cd
Opt_GfxTilesetSelection2:
        .byte $cd, $24
        .byte "SELECTION"
        .byte "................."
        .byte $24, $cd
Opt_GfxAnimatedTiles:
        .byte $cd, $24
        .byte "ANIMATED TILES"
        .byte "............"
        .byte $24, $cd

Opt_GfxTable:
        .word Opt_GfxBlank              ; 0
        .word Opt_GfxBlank              ; 1
        .word Opt_GfxTop                ; 2
        .word Opt_GfxEmpty              ; 3
        .word Opt_GfxDifficulty         ; 4
        .word Opt_GfxEmpty              ; 5
        .word Opt_GfxMarioPalette       ; 6
        .word Opt_GfxEmpty              ; 7
        .word Opt_GfxLuigiPalette       ; 8
        .word Opt_GfxEmpty              ; 9
        .word Opt_GfxLuigiPhysics       ; 10
        .word Opt_GfxEmpty              ; 11
        .word Opt_GfxSpinyEggBehavior1  ; 12
        .word Opt_GfxSpinyEggBehavior2  ; 13
        .word Opt_GfxEmpty              ; 14
        .word Opt_GfxWarpZoneScroll     ; 15
        .word Opt_GfxEmpty              ; 16
        .word Opt_GfxTimerSpeed         ; 17
        .word Opt_GfxEmpty              ; 18
        .word Opt_GfxFontSelection      ; 19
        .word Opt_GfxEmpty              ; 20
        .word Opt_GfxTilesetSelection1  ; 21
        .word Opt_GfxTilesetSelection2  ; 22
        .word Opt_GfxEmpty              ; 23
        .word Opt_GfxAnimatedTiles      ; 24
        .word Opt_GfxEmpty              ; 25
        .word Opt_GfxBottom             ; 26
Opt_GfxTableEnd:

Opt_QueueRowGfx:
        sta $00
        jsr Opt_CalcGfxAddr
        lda $00
        asl                     ; get gfx pointer
        tax
        lda Opt_GfxTable,x
        sta Opt_GfxPtrLo
        lda Opt_GfxTable+1,x
        sta Opt_GfxPtrHi
        lda VRAM_Buffer_Offset  ; adjust buffer offset
        clc
        adc #33
        tax
        sta VRAM_Buffer_Offset
        lda Opt_GfxAddrHi       ; ppu hi
        sta VRAM_Buffer-33,x
        lda Opt_GfxAddrLo       ; ppu lo
        sta VRAM_Buffer-32,x
        lda #30
        sta VRAM_Buffer-31,x    ; literal 30
        ldy #29                 ; prep Y for loop
Opt_WriteBuffer:
        lda (Opt_GfxPtr),y      ; write option line
        sta VRAM_Buffer-1,x
        dex
        dey
        bpl Opt_WriteBuffer

        ; may need to write option text
        ldx #(Opt_SelTableEnd-Opt_SelTable-1)/2
Opt_ChkForSelRow:
        txa                     ; mult by 2
        asl
        tay
        lda Opt_SelTable,y      ; get struct ptr
        sta Opt_SelStructLo
        lda Opt_SelTable+1,y
        sta Opt_SelStructHi
        ldy #Opt_TextRowOffset
        lda $00                 ; compare printed row number
        cmp (Opt_SelStruct),y   ; match with cursor row?
        beq Opt_GetTextAddr     ; yes, more work to do
        dex
        bpl Opt_ChkForSelRow
        rts

Opt_QueueText:
        asl
        tay
        lda Opt_SelTable,y      ; get struct ptr
        sta Opt_SelStructLo
        lda Opt_SelTable+1,y
        sta Opt_SelStructHi
        ldy #Opt_TextRowOffset
        lda (Opt_SelStruct),y
        jsr Opt_CalcGfxAddr
Opt_GetTextAddr:
        ldx VRAM_Buffer_Offset  ; load buffer offset
        ldy #Opt_TextLengthOffset
        lda (Opt_SelStruct),y   ; get text length
        sta VRAM_Buffer+2,x
        lda #28                 ; set ppu addr lo
        sec
        sbc VRAM_Buffer+2,x
        clc
        adc Opt_GfxAddrLo
        sta VRAM_Buffer+1,x
        lda Opt_GfxAddrHi       ; set ppu addr hi
        sta VRAM_Buffer,x
        txa                     ; adjust buffer offset
        clc
        adc VRAM_Buffer+2,x
        adc #3
        sta VRAM_Buffer_Offset
        ldy #Opt_MemoryAddrOffset ; get pointer to memory addr
        lda (Opt_SelStruct),y
        sta Opt_SelMemoryLo
        iny
        lda (Opt_SelStruct),y
        sta Opt_SelMemoryHi
        ldy #0                  ; fetch correct text pointer
        lda (Opt_SelMemory),y
        asl
        clc
        adc #Opt_TextAddrOffset
        tay
        lda (Opt_SelStruct),y
        sta Opt_GfxAddrLo
        iny
        lda (Opt_SelStruct),y
        sta Opt_GfxAddrHi
        lda VRAM_Buffer+2,x     ; prep for loop
        tay
        ldx VRAM_Buffer_Offset
        dex
        dey
Opt_WriteText:
        lda (Opt_GfxAddr),y     ; write option text
        sta VRAM_Buffer,x
        dex
        dey
        bpl Opt_WriteText
        rts

Opt_CalcGfxAddr:
        ldx #Opt_GfxAddr        ; mult index by 32
        ldy #5
        jsr MultByPow2
        lda Opt_GfxAddrLo
        clc
        adc #$01
        sta Opt_GfxAddrLo
        lda Opt_GfxAddrHi
        adc #$20
        sta Opt_GfxAddrHi
Opt_AddrRangeChk:
        cmp #$23
        bcc Opt_ReturnGfxAddr   ; addr in range
        bne Opt_SubFromAddr     ; addr outside range
        lda Opt_GfxAddrLo
        cmp #$c0
        bcc Opt_ReturnGfxAddr   ; addr in range
Opt_SubFromAddr:
        lda Opt_GfxAddrLo       ; keep addr in range
        sbc #$c0
        sta Opt_GfxAddrLo
        lda Opt_GfxAddrHi
        sbc #$03
        sta Opt_GfxAddrHi
        bne Opt_AddrRangeChk
Opt_ReturnGfxAddr:
        rts

Opt_Init:
        lda #0
        sta Opt_RowIndex        ; init opt index
        sta Opt_SelIndex        ; init sel index
        inc DisableScreenFlag   ; disable rendering
        inc OperMode_Task       ; next task
        rts

Opt_ClearScreen:
        jsr MoveAllSpritesOffscreen     ; init all sprites
        jsr InitializeNameTables        ; init nametables
        inc OperMode_Task               ; next task
        rts

Opt_Prep:
        lda Opt_RowIndex
        cmp #Opt_VisibleRows
        bcs Opt_Prep_Done
        jsr Opt_QueueRowGfx             ; draw one row
        inc Opt_RowIndex
        lda Opt_RowIndex                ; bail if all possible rows drawn
        cmp #Opt_GfxTableEnd-Opt_GfxTable
        bcs Opt_Prep_Done
        rts
Opt_Prep_Done:
        ldx #1                          ; draw text box
        ldy #Opt_VisibleRows
        lda #28
        sta $00
        lda #26-Opt_VisibleRows
        sta $01
        lda #1
        sta $06
        jsr DrawArbitraryTextbox
        lda #0
        sta Opt_TopRow                  ; set top row
        sta Opt_TargetRow               ; set target row
        sta Mirror_PPU_SCROLL1          ; set scroll
        sta Mirror_PPU_SCROLL2
        sta DisableScreenFlag           ; enable rendering
        sta Opt_ScrollType              ; disable scrolling
        lda #$00                        ; set irq select
        sta IRQSelect
        lda #$e0                        ;set irq timer value
        sta IRQTimer_Low
        lda #$4f
        sta IRQTimer_High
        inc IRQUpdateFlag
        lda #$1f
        sta Opt_CursorY                 ; set cursor Y position
        inc OperMode_Task               ; next task
        rts

Opt_SelTable:
        .word Opt_SelDifficulty         ; difficulty
        .word Opt_SelMarioPalette       ; mario palette
        .word Opt_SelLuigiPalette       ; luigi palette
        .word Opt_SelLuigiPhysics       ; luigi physics
        .word Opt_SelSpinyEggBehavior   ; spiny egg behavior
        .word Opt_SelWarpZoneScroll     ; warp zone scroll
        .word Opt_SelTimerSpeed         ; timer speed
        .word Opt_SelFontSelection      ; font selection
        .word Opt_SelTilesetSelection   ; tileset selection
        .word Opt_SelAnimatedTiles      ; animated tiles
Opt_SelTableEnd:

Opt_CursorRowOffset = 0
Opt_MemoryAddrOffset = 1
Opt_TextRowOffset = 3
Opt_TextLengthOffset = 4
Opt_OptionCountOffset = 5
Opt_TextAddrOffset = 6

Opt_SelDifficulty:
        .byte 4                         ; cursor row
        .word DifficultyFlag            ; memory addr
        .byte 4                         ; text row
        .byte 6                         ; text length
        .byte 3                         ; option count
        .word Opt_TxtDifficulty0        ; text addr #0
        .word Opt_TxtDifficulty1        ; text addr #1
        .word Opt_TxtDifficulty2        ; text addr #2
Opt_TxtDifficulty0:
        .byte "..EASY"
Opt_TxtDifficulty1:
        .byte "NORMAL"
Opt_TxtDifficulty2:
        .byte "..HARD"

Opt_SelMarioPalette:
        .byte 6                         ; cursor row
        .word MarioPalette              ; memory addr
        .byte 6                         ; text row
        .byte 11                        ; text length
        .byte 3                         ; option count
        .word Opt_TxtMarioPalette0      ; text addr #0
        .word Opt_TxtMarioPalette1      ; text addr #1
        .word Opt_TxtMarioPalette2      ; text addr #2
Opt_TxtMarioPalette0:
        .byte "...ORIGINAL"
Opt_TxtMarioPalette1:
        .byte "EARLY PROTO"
Opt_TxtMarioPalette2:
        .byte ".LATE PROTO"

Opt_SelLuigiPalette:
        .byte 8                         ; cursor row
        .word LuigiPalette              ; memory addr
        .byte 8                         ; text row
        .byte 11                        ; text length
        .byte 4                         ; option count
        .word Opt_TxtLuigiPalette0      ; text addr #0
        .word Opt_TxtLuigiPalette1      ; text addr #1
        .word Opt_TxtLuigiPalette2      ; text addr #2
        .word Opt_TxtLuigiPalette3      ; text addr #3
Opt_TxtLuigiPalette0:
        .byte "...ORIGINAL"
Opt_TxtLuigiPalette1:
        .byte "DISK WRITER"
Opt_TxtLuigiPalette2:
        .byte ".SMB DELUXE"
Opt_TxtLuigiPalette3:
        .byte ".......SMM2"

Opt_SelLuigiPhysics:
        .byte 10                        ; cursor row
        .word LuigiPhysics              ; memory addr
        .byte 10                        ; text row
        .byte 9                         ; text length
        .byte 2                         ; option count
        .word Opt_TxtLuigiPhysics0      ; text addr #0
        .word Opt_TxtLuigiPhysics1      ; text addr #1
Opt_TxtLuigiPhysics0:
        .byte ".ORIGINAL"
Opt_TxtLuigiPhysics1:
        .byte "ALL-STARS"

Opt_SelSpinyEggBehavior:
        .byte 12                        ; cursor row
        .word SpinyEggBehavior          ; memory addr
        .byte 13                        ; text row
        .byte 8                         ; text length
        .byte 2                         ; option count
        .word Opt_TxtSpinyEggBehavior0  ; text addr #0
        .word Opt_TxtSpinyEggBehavior1  ; text addr #1
Opt_TxtSpinyEggBehavior0:
        .byte "ORIGINAL"
Opt_TxtSpinyEggBehavior1:
        .byte "RESTORED"

Opt_SelWarpZoneScroll:
        .byte 15                        ; cursor row
        .word WarpZoneScroll            ; memory addr
        .byte 15                        ; text row
        .byte 8                         ; text length
        .byte 2                         ; option count
        .word Opt_TxtWarpZoneScroll0    ; text addr #0
        .word Opt_TxtWarpZoneScroll1    ; text addr #1
Opt_TxtWarpZoneScroll0:
        .byte "ORIGINAL"
Opt_TxtWarpZoneScroll1:
        .byte "RESTORED"

Opt_SelTimerSpeed:
        .byte 17                        ; cursor row
        .word CountdownSpeed            ; memory addr
        .byte 17                        ; text row
        .byte 8                         ; text length
        .byte 3                         ; option count
        .word Opt_TxtTimerSpeed0        ; text addr #0
        .word Opt_TxtTimerSpeed1        ; text addr #1
        .word Opt_TxtTimerSpeed2        ; text addr #2
Opt_TxtTimerSpeed0:
        .byte "ORIGINAL"
Opt_TxtTimerSpeed1:
        .byte ".VS.SLOW"
Opt_TxtTimerSpeed2:
        .byte ".VS.FAST"
		
Opt_SelFontSelection:
        .byte 19                        ; cursor row
        .word FontSelection             ; memory addr
        .byte 19                        ; text row
        .byte 8                         ; text length
        .byte 3                         ; option count
        .word Opt_TxtFontSelection0     ; text addr #0
        .word Opt_TxtFontSelection1     ; text addr #1
        .word Opt_TxtFontSelection2     ; text addr #2
Opt_TxtFontSelection0:
        .byte "PER GAME"
Opt_TxtFontSelection1:
        .byte ".MARIO 1"
Opt_TxtFontSelection2:
        .byte ".MARIO 2"

Opt_SelTilesetSelection:
        .byte 21                        ; cursor row
        .word TilesetSelection          ; memory addr
        .byte 22                        ; text row
        .byte 8                         ; text length
        .byte 3                         ; option count
        .word Opt_TxtTilesetSelection0  ; text addr #0
        .word Opt_TxtTilesetSelection1  ; text addr #1
        .word Opt_TxtTilesetSelection2  ; text addr #2
Opt_TxtTilesetSelection0:
        .byte "PER GAME"
Opt_TxtTilesetSelection1:
        .byte ".MARIO 1"
Opt_TxtTilesetSelection2:
        .byte ".MARIO 2"

Opt_SelAnimatedTiles:
        .byte 24                        ; cursor row
        .word AnimatedTiles             ; memory addr
        .byte 24                        ; text row
        .byte 3                         ; text length
        .byte 2                         ; option count
        .word Opt_TxtAnimatedTiles0     ; text addr #0
        .word Opt_TxtAnimatedTiles1     ; text addr #1
Opt_TxtAnimatedTiles0:
        .byte "OFF"
Opt_TxtAnimatedTiles1:
        .byte ".ON"

Opt_Run:
        ; cursor movement
        ldy Opt_ScrollType      ; prevent cursor movement if scrolling
        beq Opt_MoveCursor
        jmp Opt_ChkScroll

Opt_MoveCursor:
        lda #<Opt_SelIndex      ; change selection
        sta $00
        lda #>Opt_SelIndex
        sta $01
        lda #(Opt_SelTableEnd-Opt_SelTable-1)/2
        jsr MenuSelectionLogic
        
        ; cursor rendering
        lda Opt_SelIndex        ; update target row
        asl
        tay
        lda Opt_SelTable,y
        sta Opt_SelStructLo
        lda Opt_SelTable+1,y
        sta Opt_SelStructHi
        ldy #Opt_CursorRowOffset
        lda (Opt_SelStruct),y
        sta Opt_TargetRow
        sec
        sbc Opt_TopRow          ; set cursor Y position
        asl
        asl
        asl
        sec
        sbc #1
        sta Sprite_Data
        lda #$04                ; set other cursor data
        sta Sprite_Data+1
        lda #$02
        sta Sprite_Data+2
        lda #$0f
        sta Sprite_Data+3

        ; change option if necessary
        txa                             ; if moved up/down menu, handle scrolling
        bne Opt_ChkScroll
        bit PressedJoypadBits
        bvs Opt_ExitMenu                ; if B pressed, exit menu
        ldy #Opt_MemoryAddrOffset       ; get memory addr
        lda (Opt_SelStruct),y
        sta Opt_SelMemoryLo
        iny
        lda (Opt_SelStruct),y
        sta Opt_SelMemoryHi
        ldy #Opt_OptionCountOffset      ; get option count
        lda (Opt_SelStruct),y
        sta Opt_OptionCount
        ldx #0
        lda (Opt_SelMemory,x)
        tax
        lda PressedJoypadBits           ; check for left or right press
        tay
        and #Right_Dir
        bne NextOption
        tya
        and #Left_Dir
        beq Opt_ChkScroll
        dex                             ; previous option
        bpl Opt_UpdateMemory
        ldx Opt_OptionCount
        dex
        bpl Opt_UpdateMemory
NextOption:
        inx                             ; next option
        cpx Opt_OptionCount
        bcc Opt_UpdateMemory
        ldx #0
Opt_UpdateMemory:
        txa
        ldx #0
        sta (Opt_SelMemory,x)
        lda Opt_SelIndex                ; redraw option text
        jmp Opt_QueueText
Opt_ExitMenu:
        lda #0
        sta OperMode
        sta OperMode_Task
        sta IRQUpdateFlag
        sta ScreenEdge_PageLoc
        sta ContinueMenuSelect
        inc DisableScreenFlag
        rts

Opt_ChkScroll:
        ; camera movement
        lda Opt_ScrollType      ; check scroll type
        beq Opt_CheckDist
        bpl Opt_ScrollUp
        lda Mirror_PPU_SCROLL2  ; scroll 2 pixels downwards
        clc
        adc #2
        sta Mirror_PPU_SCROLL2
        cmp #240
        bcc :+
        lda #0
:       and #%00000111          ; check to stop if Y scroll div 8
        beq Opt_CheckDist
        rts
Opt_ScrollUp:
        lda Mirror_PPU_SCROLL2  ; scroll 2 pixels upwards
        sec
        sbc #2
        cmp #240
        bcc :+
        lda #238
:       sta Mirror_PPU_SCROLL2
        and #%00000111          ; check to stop if Y scroll div 8
        beq Opt_CheckDist
        rts
Opt_CheckDist:
        lda Opt_TargetRow       ; get dist from target to top
        sec
        sbc Opt_TopRow
        cmp #9                  ; scroll up if less than 9 rows or past top
        bmi CloseDist
        cmp #13                 ; scroll down if greater than 12 rows
        bcs FarDist
Opt_DisableScroll:
        lda #0
        sta Opt_ScrollType
        rts
CloseDist:
        lda Opt_TopRow          ; can't scroll if row 0 is top
        beq Opt_DisableScroll
        lda #1
        sta Opt_ScrollType
        lda #$f8                 ; hide cursor
        sta Sprite_Data
        dec Opt_TopRow
        lda Opt_TopRow
        jmp Opt_QueueRowGfx
FarDist:
        lda Opt_TopRow           ; can't scroll if hit bottom row
        cmp #((Opt_GfxTableEnd-Opt_GfxTable)/2)-Opt_VisibleRows
        bcs Opt_DisableScroll
        lda #255
        sta Opt_ScrollType
        lda #$f8                 ; hide cursor
        sta Sprite_Data
        lda Opt_TopRow
        clc
        adc #Opt_VisibleRows
        inc Opt_TopRow
        jmp Opt_QueueRowGfx

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

NametableAddrHi:
        .byte $20
        .byte $24

; X = top left corner X location
; Y = top left corner Y location
; $00 = internal width
; $01 = internal height
; $06 = nametable
DrawArbitraryTextbox:
        ; get base NT location in $02-$03
        txa
        pha
        ldx #$02
        tya
        ldy #5
        jsr MultByPow2
        pla
        ldy $06
        clc
        adc $02
        sta $02
        lda NametableAddrHi,y
        adc $03
        sta $03
        ; write base textbox packet to VRAM buffer
        ldy #0
        ldx VRAM_Buffer_Offset
        txa
        pha
:       lda BaseTextbox,y
        sta VRAM_Buffer,x
        inx
        iny
        cpy #32
        bcc :-
        stx VRAM_Buffer_Offset
        pla
        tax
        ; set border lengths
        lda $00
        clc
        adc #$40
        sta VRAM_Buffer+6,x
        sta VRAM_Buffer+26,x
        lda $01
        clc
        adc #$c0
        sta VRAM_Buffer+14,x
        sta VRAM_Buffer+18,x
        ; adjust width/height for later math
        inc $00
        inc $01
        txa
        pha
        ldx #$04
        lda $01
        ldy #5
        jsr MultByPow2
        pla
        tax
        ; set top left corner and top border
        lda $02
        sta VRAM_Buffer+1,x
        clc
        adc #$01
        sta VRAM_Buffer+5,x
        lda $03
        sta VRAM_Buffer,x
        adc #$00
        sta VRAM_Buffer+4,x
        ; set top right corner
        lda $02
        clc
        adc $00
        sta VRAM_Buffer+9,x
        lda $03
        adc #$00
        sta VRAM_Buffer+8,x
        ; set left border
        lda $02
        clc
        adc #$20
        sta VRAM_Buffer+13,x
        lda $03
        adc #$00
        sta VRAM_Buffer+12,x
        ; set right border
        lda VRAM_Buffer+9,x
        clc
        adc #$20
        sta VRAM_Buffer+17,x
        lda VRAM_Buffer+8,x
        adc #$00
        sta VRAM_Buffer+16,x
        ; set bottom left corner
        lda VRAM_Buffer+1,x
        clc
        adc $04
        sta VRAM_Buffer+21,x
        lda VRAM_Buffer,x
        adc $05
        sta VRAM_Buffer+20,x
        ; set bottom border
        lda VRAM_Buffer+5,x
        clc
        adc $04
        sta VRAM_Buffer+25,x
        lda VRAM_Buffer+4,x
        adc $05
        sta VRAM_Buffer+24,x
        ; set bottom right corner
        lda VRAM_Buffer+9,x
        clc
        adc $04
        sta VRAM_Buffer+29,x
        lda VRAM_Buffer+8,x
        adc $05
        sta VRAM_Buffer+28,x
        rts

;-------------------------------------------------------------------------------------

LoadIntoGame:
        lda ContinueMenuSelect
        sta CurrentGame
        jsr LoadFontTileset
        jsr CopyFrictionData
        jsr CopyPaletteData
        jsr CopyDemoData
        jsr CopyTopScoreDisplay
        jsr famistudio_music_stop
        jsr famistudio_update
        jmp BootIntoGame

CopyTopScoreDisplay:
            lda CurrentGame          ;multiply game index by six for correct
            asl                      ;index into top score table
            sta $00
            asl
            clc
            adc $00
            tax
            ldy #0
LdTopScore: lda SavedTopScore,x      ;restore previously saved top score
            sta TopScoreDisplay,y
            inx
            iny
            cpy #6
            bcc LdTopScore
            rts

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

.include "famistudio_ca65.s"
.include "music/menu.s"