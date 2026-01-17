.segment "LOADER"
.org $8000

StartLoader:
        ; copied most of this from SMB init...
        ldy #$ff
        jsr InitializeMemory
		sta SND_DELTA_REG+1
		inc DisableScreenFlag
		ldx #FONT_SMB2_INDEX
		lda #TITLE_INDEX
		jsr FetchCHRPacket_AX
		ldx #BORDER_INDEX
		lda #SPR_SMB2_INDEX
		jsr FetchCHRPacket_AX
		cli
		lda Mirror_PPU_CTRL
        ora #%10000000
        jsr WritePPUReg1
@nmi_wait:
        lda NMIAckFlag
		beq @nmi_wait
        jsr MainMenuStateMachine
		lda #$00
		sta NMIAckFlag
		jmp @nmi_wait

;-------------------------------------------------------------------------------------

MainMenuStateMachine:
        lda OperMode_Task
		jsr JumpEngine

		.word PrepScreen
		.word RenderTilemap
		.word RunMenu
		.word LoadIntoGame

;-------------------------------------------------------------------------------------

MainMenuPalette:
        .byte $3f,$00,$20
        .byte $0f,$30,$12,$0c
		.byte $0f,$36,$17,$07
		.byte $0f,$0f,$0f,$0f
		.byte $0f,$27,$17,$07
		.byte $0f,$16,$27,$18
		.byte $0f,$1a,$30,$27
		.byte $0f,$16,$30,$27
		.byte $0f,$0f,$30,$10
		.byte $00

PrepScreen:
        jsr MoveAllSpritesOffscreen
        jsr InitializeNameTables
		; (TO-DO: replace this with a proper VRAM addr reference)
		ldy #0
		ldx VRAM_Buffer_Offset
:		lda MainMenuPalette,y
		sta VRAM_Buffer,x
		inx
		iny
		cpy #36
		bcc :-
		dex
		stx VRAM_Buffer_Offset
		inc OperMode_Task
		rts

MainMenuTilemap:
        ; border
        .byte $20,$84,$80+6,$c9,$cd,$cd,$cd,$cd,$ca
		.byte $20,$85,$40+22,$cb
		.byte $20,$9b,$80+6,$cc,$cd,$cd,$cd,$cd,$ce
		.byte $21,$25,$40+22,$cb
		; selection names
		.byte $20,$a6,14,"MARIO COMPLETE"
		.byte $20,$c6,19,"SUPER MARIO BROS. 1"
		.byte $20,$e6,19,"SUPER MARIO BROS. 2"
		.byte $21,$06,7,"OPTIONS"
		.byte $00
MainMenuTilemap_End:

RenderTilemap:
        ldy #0
		ldx VRAM_Buffer_Offset
:		lda MainMenuTilemap,y
		sta VRAM_Buffer,x
		inx
		iny
		cpy #MainMenuTilemap_End-MainMenuTilemap
		bcc :-
		dex
		stx VRAM_Buffer_Offset
		lda #$00
		sta DisableScreenFlag
        inc OperMode_Task
        rts

MenuCursorData:
  .byte $04, $02, $27

MenuCursorY:
  .byte $27, $2f, $37, $3f

RunMenu:
        lda PressedJoypadBits
		and #Start_Button
		bne LoadIntoGame
		ldy ContinueMenuSelect
		lda PressedJoypadBits
		and #Down_Dir+Select_Button
		beq :+
		iny
		bne SetMenuSelect
:       lda PressedJoypadBits
		and #Up_Dir
		beq :+
		dey
SetMenuSelect:
            lda #$02                     ;keep menu option in range
            cpy #$00
            bmi SetSelM
            lda #$00
            cpy #$03
            bcs SetSelM
            tya
SetSelM:    sta ContinueMenuSelect
:		    ldy #$02
:           lda MenuCursorData,y     ;set up cursor sprite tile, attribute
            sta Sprite_Data+1,y          ;and X position in sprite OAM data
            dey
            bpl :-
            ldy ContinueMenuSelect
            lda MenuCursorY,y        ;set Y position based on the selection
            sta Sprite_Data
            rts

;-------------------------------------------------------------------------------------

LoadIntoGame:
        lda ContinueMenuSelect
		sta CurrentGame
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
		.byte $03, $07, $0B	;note that offsets point to last byte
 
LuigiPaletteOffsets:
		.byte $03, $07, $0B, $03 ;note that offsets point to last byte

FireMarioPaletteOffsets:
		.byte $03, $07, $03	;note that offsets point to last byte

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