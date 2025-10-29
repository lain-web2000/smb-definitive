.segment "LOADER"
.org $8000

StartLoader:
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