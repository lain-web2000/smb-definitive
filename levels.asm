;-------------------------------------------------------------------------------------

LoadAreaPointer:
             jsr FindAreaPointer  ;find it and store it here
             sta AreaPointer
GetAreaType: and #%01100000       ;mask out all but d6 and d5
             asl
             rol
             rol
             rol                  ;make %0xx00000 into %000000xx
             sta AreaType         ;save 2 MSB as area type
             rts

FindAreaPointer:
      lda WorldNumber        ;load offset from world variable
      tay
      lda LevelSet           ;are we playing 2J levels?
      bne FindAreaPointerJ   ;yes, use 2J offsets instead
      lda WorldAddrOffsets,y
      clc
      adc AreaNumber         ;add area number used to find data
      tay
      lda AreaAddrOffsets,y  ;from there we have our area pointer
      rts
FindAreaPointerJ:
      lda WorldAddrOffsetsJ,y
      clc
      adc AreaNumber          ;add area number used to find data
      tay
      lda AreaAddrOffsetsJ,y  ;from there we have our area pointer
      rts

GetAreaPointer:
     lda LevelSet               ;are we playing 2J levels?
     bne GetAreaPointerJ        ;yes, use 2J offsets instead
     ldx WorldAddrOffsets,y     ;get offset to where this world's area offsets are
     ldy AreaAddrOffsets,x      ;get area offset based on world offset
     rts
GetAreaPointerJ:
     ldx WorldAddrOffsetsJ,y    ;get offset to where this world's area offsets are
     ldy AreaAddrOffsetsJ,x     ;get area offset based on world offset
     rts

GetAreaDataAddrs:
            lda AreaPointer            ;use 2 MSB for Y
            jsr GetAreaType
            tay
            lda AreaPointer            ;mask out all but 5 LSB
            and #%00011111
            sta AreaAddrsLOffset       ;save as low offset
            lda LevelSet               ;check if playing 2J levels
            bne GetAreaDataAddrsJ      ;if so, refer to alternate offsets
            lda EnemyAddrHOffsets,y    ;load base value with 2 altered MSB,
            clc                        ;then add base value to 5 LSB, result
            adc AreaAddrsLOffset       ;becomes offset for level data
            asl
            tay
            lda EnemyDataAddrs+1,y     ;use offset to load pointer
            sta EnemyDataHigh
            lda EnemyDataAddrs,y
            sta EnemyDataLow
            ldy AreaType               ;use area type as offset
            lda AreaDataHOffsets,y     ;do the same thing but with different base value
            clc
            adc AreaAddrsLOffset
            asl
            tay
            lda AreaDataAddrs+1,y      ;use this offset to load another pointer
            sta AreaDataHigh
            lda AreaDataAddrs,y
            sta AreaDataLow
            jmp ContinueAreaDataAddrs
GetAreaDataAddrsJ:
            lda HardWorldFlag          ;playing 2J letter worlds?
            bne GetAreaDataAddrsL      ;yes, alternate offsets
            lda EnemyAddrHOffsetsJ,y   ;load base value with 2 altered MSB,
            clc                        ;then add base value to 5 LSB, result
            adc AreaAddrsLOffset       ;becomes offset for level data
            asl
            tay
            lda EnemyDataAddrsJ+1,y    ;use offset to load pointer
            sta EnemyDataHigh
            lda EnemyDataAddrsJ,y
            sta EnemyDataLow
            ldy AreaType               ;use area type as offset
            lda AreaDataHOffsetsJ,y    ;do the same thing but with different base value
            clc
            adc AreaAddrsLOffset
            asl
            tay
            lda AreaDataAddrsJ+1,y     ;use this offset to load another pointer
            sta AreaDataHigh
            lda AreaDataAddrsJ,y
            sta AreaDataLow
            jmp ContinueAreaDataAddrs
GetAreaDataAddrsL:
            lda EnemyAddrHOffsetsL,y   ;load base value with 2 altered MSB,
            clc                        ;then add base value to 5 LSB, result
            adc AreaAddrsLOffset       ;becomes offset for level data
            asl
            tay
            lda EnemyDataAddrsL+1,y    ;use offset to load pointer
            sta EnemyDataHigh
            lda EnemyDataAddrsL,y
            sta EnemyDataLow
            ldy AreaType               ;use area type as offset
            lda AreaDataHOffsetsL,y    ;do the same thing but with different base value
            clc
            adc AreaAddrsLOffset
            asl
            tay
            lda AreaDataAddrsL+1,y     ;use this offset to load another pointer
            sta AreaDataHigh
            lda AreaDataAddrsL,y
            sta AreaDataLow
ContinueAreaDataAddrs:
            ldy #$00                 ;load first byte of header
            lda (AreaData),y     
            pha                      ;save it to the stack for now
            and #%00000111           ;save 3 LSB for foreground scenery or bg color control
            cmp #$04
            bcc StoreFore
            sta BackgroundColorCtrl  ;if 4 or greater, save value here as bg color control
            lda #$00
StoreFore:  sta ForegroundScenery    ;if less, save value here as foreground scenery
            pla                      ;pull byte from stack and push it back
            pha
            and #%00111000           ;save player entrance control bits
            lsr                      ;shift bits over to LSBs
            lsr
            lsr
            sta PlayerEntranceCtrl   ;save value here as player entrance control
            pla                      ;pull byte again but do not push it back
            and #%11000000           ;save 2 MSB for game timer setting
            clc
            rol                      ;rotate bits over to LSBs
            rol
            rol
            sta GameTimerSetting     ;save value here as game timer setting
            iny
            lda (AreaData),y         ;load second byte of header
            pha                      ;save to stack
            and #%00001111           ;mask out all but lower nybble
            sta TerrainControl
            pla                      ;pull and push byte to copy it to A
            pha
            and #%00110000           ;save 2 MSB for background scenery type
            lsr
            lsr                      ;shift bits to LSBs
            lsr
            lsr
            sta BackgroundScenery    ;save as background scenery
            pla           
            and #%11000000
            clc
            rol                      ;rotate bits over to LSBs
            rol
            rol
            cmp #%00000011           ;if set to 3, store here
            bne StoreStyle           ;and nullify other value
            sta CloudTypeOverride    ;otherwise store value in other place
            lda #$00
StoreStyle: sta AreaStyle
            ldy #$00                 ;init counter
ADataLoop:  lda (AreaData),y         ;store area data into region of RAM
            sta AreaDataCopy,y
            iny                      ;increment Y for next byte
            cmp #$fd                 ;did we just store a $fd byte?
            bne ADataLoop            ;if not, we aren't done storing area data yet
            lda #>AreaDataCopy       ;now move area data pointers to RAM
            sta AreaDataHigh
            lda #<AreaDataCopy
            sta AreaDataLow
            ldy #$00                 ;init counter
EDataLoop:  lda (EnemyData),y        ;store enemy data into region of RAM
            sta EnemyDataCopy,y
            iny                      ;increment Y for next byte
            cmp #$ff                 ;did we just store a $ff byte?
            bne EDataLoop            ;if not, we aren't done storing enemy data yet
            lda #>EnemyDataCopy      ;now move enemy data pointers to RAM
            sta EnemyDataHigh
            lda #<EnemyDataCopy
            sta EnemyDataLow         ;(credit to threecreepio for this code)
            lda AreaDataLow          ;increment area data address by 2 bytes
            clc
            adc #$02
            sta AreaDataLow
            lda AreaDataHigh
            adc #$00
            sta AreaDataHigh
            rts

;-------------------------------------------------------------------------------------

WorldAddrOffsets:
      .byte World1Areas-AreaAddrOffsets, World2Areas-AreaAddrOffsets
      .byte World3Areas-AreaAddrOffsets, World4Areas-AreaAddrOffsets
      .byte World5Areas-AreaAddrOffsets, World6Areas-AreaAddrOffsets
      .byte World7Areas-AreaAddrOffsets, World8Areas-AreaAddrOffsets
      .byte World9Areas-AreaAddrOffsets

AreaAddrOffsets:
World1Areas: .byte $25, $29, $c0, $26, $60
World2Areas: .byte $28, $29, $01, $27, $62
World3Areas: .byte $24, $35, $20, $63
World4Areas: .byte $22, $29, $41, $2c, $61
World5Areas: .byte $2a, $31, $26, $62
World6Areas: .byte $2e, $23, $2d, $60
World7Areas: .byte $33, $29, $01, $27, $64
World8Areas: .byte $30, $32, $21, $65
World9Areas: .byte $03, $04, $05, $43

;bonus area data offsets, included here for comparison purposes
;underground bonus area  - c2
;cloud area 1 (day)      - 2b
;cloud area 2 (night)    - 34
;water area (5-2/6-2)    - 00
;water area (8-4)        - 02
;warp zone area (4-2)    - 2f

EnemyAddrHOffsets:
      .byte $00, $06, $1c, $20

EnemyDataAddrs:
      .word E_WaterArea1_, E_WaterArea2_, E_WaterArea3_, E_WaterArea4_, E_WaterArea5_, E_WaterArea6_
      .word E_GroundArea1_, E_GroundArea2_, E_GroundArea3_
      .word E_GroundArea4_, E_GroundArea5_, E_GroundArea6_, E_GroundArea7_, E_GroundArea8_, E_GroundArea9_
      .word E_GroundArea10_, E_GroundArea11_, E_GroundArea12_, E_GroundArea13_, E_GroundArea14_, E_GroundArea15_
      .word E_GroundArea16_, E_GroundArea17_, E_GroundArea18_, E_GroundArea19_, E_GroundArea20_, E_GroundArea21_
      .word E_GroundArea22_, E_UndergroundArea1_, E_UndergroundArea2_, E_UndergroundArea3_, E_UndergroundArea4_
      .word E_CastleArea1_, E_CastleArea2_, E_CastleArea3_, E_CastleArea4_, E_CastleArea5_, E_CastleArea6_

AreaDataHOffsets:
      .byte $00, $06, $1c, $20

AreaDataAddrs:
      .word L_WaterArea1_, L_WaterArea2_, L_WaterArea3_, L_WaterArea4_, L_WaterArea5_, L_WaterArea6_
      .word L_GroundArea1_, L_GroundArea2_, L_GroundArea3_
      .word L_GroundArea4_, L_GroundArea5_, L_GroundArea6_, L_GroundArea7_, L_GroundArea8_, L_GroundArea9_
      .word L_GroundArea10_, L_GroundArea11_, L_GroundArea12_, L_GroundArea13_, L_GroundArea14_, L_GroundArea15_
      .word L_GroundArea16_, L_GroundArea17_, L_GroundArea18_, L_GroundArea19_, L_GroundArea20_, L_GroundArea21_
      .word L_GroundArea22_, L_UndergroundArea1_, L_UndergroundArea2_, L_UndergroundArea3_, L_UndergroundArea4_
      .word L_CastleArea1_, L_CastleArea2_, L_CastleArea3_, L_CastleArea4_, L_CastleArea5_, L_CastleArea6_

;-------------------------------------------------------------------------------------

WorldAddrOffsetsJ:
  .byte World1JAreas-AreaAddrOffsetsJ, World2JAreas-AreaAddrOffsetsJ
  .byte World3JAreas-AreaAddrOffsetsJ, World4JAreas-AreaAddrOffsetsJ
  .byte World5JAreas-AreaAddrOffsetsJ, World6JAreas-AreaAddrOffsetsJ
  .byte World7JAreas-AreaAddrOffsetsJ, World8JAreas-AreaAddrOffsetsJ
  .byte World9JAreas-AreaAddrOffsetsJ
  .byte WorldAAreas-AreaAddrOffsetsJ, WorldBAreas-AreaAddrOffsetsJ
  .byte WorldCAreas-AreaAddrOffsetsJ, WorldDAreas-AreaAddrOffsetsJ

AreaAddrOffsetsJ:
World1JAreas: .byte $20, $29, $40, $21, $60
World2JAreas: .byte $22, $23, $24, $61
World3JAreas: .byte $25, $29, $00, $26, $62
World4JAreas: .byte $27, $28, $2a, $63
World5JAreas: .byte $2b, $29, $43, $2c, $64
World6JAreas: .byte $2d, $29, $01, $2e, $65
World7JAreas: .byte $2f, $30, $31, $66
World8JAreas: .byte $32, $35, $36, $67
World9JAreas: .byte $38, $06, $68, $07

WorldAAreas: .byte $20, $2c, $40, $21, $60
WorldBAreas: .byte $22, $2c, $00, $23, $61
WorldCAreas: .byte $24, $25, $26, $62
WorldDAreas: .byte $27, $28, $29, $63

EnemyAddrHOffsetsJ:
  .byte $2c, $0a, $27, $00

EnemyDataAddrsJ:
  .word E_CastleArea1, E_CastleArea2, E_CastleArea3, E_CastleArea4, E_CastleArea5, E_CastleArea6
  .word E_CastleArea7, E_CastleArea8, E_CastleArea9, E_CastleArea10, E_GroundArea1, E_GroundArea2
  .word E_GroundArea3, E_GroundArea4, E_GroundArea5, E_GroundArea6, E_GroundArea7, E_GroundArea8
  .word E_GroundArea9, E_GroundArea10, E_GroundArea11, E_GroundArea12, E_GroundArea13, E_GroundArea14
  .word E_GroundArea15, E_GroundArea16, E_GroundArea17, E_GroundArea18, E_GroundArea19, E_GroundArea20
  .word E_GroundArea21, E_GroundArea22, E_GroundArea23, E_GroundArea24, E_GroundArea25, E_GroundArea26
  .word E_GroundArea27, E_GroundArea28, E_GroundArea29, E_UndergroundArea1, E_UndergroundArea2
  .word E_UndergroundArea3, E_UndergroundArea4, E_UndergroundArea5, E_WaterArea1, E_WaterArea2
  .word E_WaterArea3, E_WaterArea4, E_WaterArea5, E_WaterArea6, E_WaterArea7, E_WaterArea8

AreaDataHOffsetsJ:
  .byte $2c, $0a, $27, $00

AreaDataAddrsJ:
  .word L_CastleArea1, L_CastleArea2, L_CastleArea3, L_CastleArea4, L_CastleArea5, L_CastleArea6
  .word L_CastleArea7, L_CastleArea8, L_CastleArea9, L_CastleArea10, L_GroundArea1, L_GroundArea2
  .word L_GroundArea3, L_GroundArea4, L_GroundArea5, L_GroundArea6, L_GroundArea7, L_GroundArea8
  .word L_GroundArea9, L_GroundArea10, L_GroundArea11, L_GroundArea12, L_GroundArea13, L_GroundArea14
  .word L_GroundArea15, L_GroundArea16, L_GroundArea17, L_GroundArea18, L_GroundArea19, L_GroundArea20
  .word L_GroundArea21, L_GroundArea22, L_GroundArea23, L_GroundArea24, L_GroundArea25, L_GroundArea26
  .word L_GroundArea27, L_GroundArea28, L_GroundArea29, L_UndergroundArea1, L_UndergroundArea2
  .word L_UndergroundArea3, L_UndergroundArea4, L_UndergroundArea5, L_WaterArea1, L_WaterArea2
  .word L_WaterArea3, L_WaterArea4, L_WaterArea5, L_WaterArea6, L_WaterArea7, L_WaterArea8

EnemyAddrHOffsetsL:
     .byte $14, $04, $12, $00

EnemyDataAddrsL:
     .word E_CastleArea11, E_CastleArea12, E_CastleArea13, E_CastleArea14, E_GroundArea30, E_GroundArea31
     .word E_GroundArea32, E_GroundArea33, E_GroundArea34, E_GroundArea35, E_GroundArea36, E_GroundArea37
     .word E_GroundArea38, E_GroundArea39, E_GroundArea40, E_GroundArea41, E_GroundArea10, E_GroundArea28
     .word E_UndergroundArea6, E_UndergroundArea7, E_WaterArea9

AreaDataHOffsetsL:
     .byte $14, $04, $12, $00

AreaDataAddrsL:
     .word L_CastleArea11, L_CastleArea12, L_CastleArea13, L_CastleArea14, L_GroundArea30, L_GroundArea31
     .word L_GroundArea32, L_GroundArea33, L_GroundArea34, L_GroundArea35, L_GroundArea36, L_GroundArea37
     .word L_GroundArea38, L_GroundArea39, L_GroundArea40, L_GroundArea41, L_GroundArea10, L_GroundArea28
     .word L_UndergroundArea6, L_UndergroundArea7, L_WaterArea9

;-------------------------------------------------------------------------------------

;ENEMY OBJECT DATA

;level 1-4/6-4
E_CastleArea1_:
      .incbin "levels/smb1/enemies/E_1-4_6-4.bin"

;level 4-4
E_CastleArea2_:
      .incbin "levels/smb1/enemies/E_4-4.bin"

;level 2-4/5-4
E_CastleArea3_:
      .incbin "levels/smb1/enemies/E_2-4_5-4.bin"

;level 3-4
E_CastleArea4_:
      .incbin "levels/smb1/enemies/E_3-4.bin"

;level 7-4
E_CastleArea5_:
      .incbin "levels/smb1/enemies/E_7-4.bin"

;level 8-4
E_CastleArea6_:
      .incbin "levels/smb1/enemies/E_8-4.bin"

;level 3-3
E_GroundArea1_:
      .incbin "levels/smb1/enemies/E_3-3.bin"

;level 8-3
E_GroundArea2_:
      .incbin "levels/smb1/enemies/E_8-3.bin"

;level 4-1
E_GroundArea3_:
      .incbin "levels/smb1/enemies/E_4-1.bin"

;level 6-2
E_GroundArea4_:
      .incbin "levels/smb1/enemies/E_6-2.bin"

;level 3-1
E_GroundArea5_:
      .incbin "levels/smb1/enemies/E_3-1.bin"

;level 1-1
E_GroundArea6_:
      .incbin "levels/smb1/enemies/E_1-1.bin"

;level 1-3/5-3
E_GroundArea7_:
      .incbin "levels/smb1/enemies/E_1-3_5-3.bin"

;level 2-3/7-3
E_GroundArea8_:
      .incbin "levels/smb1/enemies/E_2-3_7-3.bin"

;level 2-1
E_GroundArea9_:
      .incbin "levels/smb1/enemies/E_2-1.bin"

;pipe intro area
E_GroundArea10_:
      .byte $ff

;level 5-1
E_GroundArea11_:
      .incbin "levels/smb1/enemies/E_5-1.bin"

;cloud level used in levels 2-1 and 5-2
E_GroundArea12_:
      .incbin "levels/smb1/enemies/E_CLOUD1.bin"

;level 4-3
E_GroundArea13_:
      .incbin "levels/smb1/enemies/E_4-3.bin"

;level 6-3
E_GroundArea14_:
      .incbin "levels/smb1/enemies/E_6-3.bin"

;level 6-1
E_GroundArea15_:
      .incbin "levels/smb1/enemies/E_6-1.bin"

;warp zone area used in level 4-2
E_GroundArea16_:
      .byte $ff

;level 8-1
E_GroundArea17_:
      .incbin "levels/smb1/enemies/E_8-1.bin"

;level 5-2
E_GroundArea18_:
      .incbin "levels/smb1/enemies/E_5-2.bin"

;level 8-2
E_GroundArea19_:
      .incbin "levels/smb1/enemies/E_8-2.bin"

;level 7-1
E_GroundArea20_:
      .incbin "levels/smb1/enemies/E_7-1.bin"

;cloud level used in levels 3-1 and 6-2
E_GroundArea21_:
      .incbin "levels/smb1/enemies/E_CLOUD2.bin"

;level 3-2
E_GroundArea22_:
      .incbin "levels/smb1/enemies/E_3-2.bin"

;level 1-2
E_UndergroundArea1_:
      .incbin "levels/smb1/enemies/E_1-2.bin"

;level 4-2
E_UndergroundArea2_:
      .incbin "levels/smb1/enemies/E_4-2.bin"

;underground bonus rooms area used in many levels
E_UndergroundArea3_:
      .incbin "levels/smb1/enemies/E_BONUS.bin"

;level 9-4
E_UndergroundArea4_:
      .incbin "levels/smb1/enemies/E_9-4.bin"

;water area used in levels 5-2 and 6-2
E_WaterArea1_:
      .incbin "levels/smb1/enemies/E_WATER.bin"

;level 2-2/7-2
E_WaterArea2_:
      .incbin "levels/smb1/enemies/E_2-2_7-2.bin"

;water area used in level 8-4
E_WaterArea3_:
      .incbin "levels/smb1/enemies/E_8-4WATER.bin"

;level 9-1
E_WaterArea4_:
      .incbin "levels/smb1/enemies/E_9-1.bin"

;level 9-2
E_WaterArea5_:
      .incbin "levels/smb1/enemies/E_9-2.bin"

;level 9-3
E_WaterArea6_:
      .incbin "levels/smb1/enemies/E_9-3.bin"

;AREA OBJECT DATA

;level 1-4/6-4
L_CastleArea1_:
      .incbin "levels/smb1/levels/L_1-4_6-4.bin"

;level 4-4
L_CastleArea2_:
      .incbin "levels/smb1/levels/L_4-4.bin"

;level 2-4/5-4
L_CastleArea3_:
      .incbin "levels/smb1/levels/L_2-4_5-4.bin"

;level 3-4
L_CastleArea4_:
      .incbin "levels/smb1/levels/L_3-4.bin"

;level 7-4
L_CastleArea5_:
      .incbin "levels/smb1/levels/L_7-4.bin"

;level 8-4
L_CastleArea6_:
      .incbin "levels/smb1/levels/L_8-4.bin"

;level 3-3
L_GroundArea1_:
      .incbin "levels/smb1/levels/L_3-3.bin"

;level 8-3
L_GroundArea2_:
      .incbin "levels/smb1/levels/L_8-3.bin"

;level 4-1
L_GroundArea3_:
      .incbin "levels/smb1/levels/L_4-1.bin"

;level 6-2
L_GroundArea4_:
      .incbin "levels/smb1/levels/L_6-2.bin"

;level 3-1
L_GroundArea5_:
      .incbin "levels/smb1/levels/L_3-1.bin"

;level 1-1
L_GroundArea6_:
      .incbin "levels/smb1/levels/L_1-1.bin"

;level 1-3/5-3
L_GroundArea7_:
      .incbin "levels/smb1/levels/L_1-3_5-3.bin"

;level 2-3/7-3
L_GroundArea8_:
      .incbin "levels/smb1/levels/L_2-3_7-3.bin"

;level 2-1
L_GroundArea9_:
      .incbin "levels/smb1/levels/L_2-1.bin"

;pipe intro area
L_GroundArea10_:
      .incbin "levels/smb1/levels/L_PIPE.bin"

;level 5-1
L_GroundArea11_:
      .incbin "levels/smb1/levels/L_5-1.bin"

;cloud level used in levels 2-1 and 5-2
L_GroundArea12_:
      .incbin "levels/smb1/levels/L_CLOUD1.bin"

;level 4-3
L_GroundArea13_:
      .incbin "levels/smb1/levels/L_4-3.bin"

;level 6-3
L_GroundArea14_:
      .incbin "levels/smb1/levels/L_6-3.bin"

;level 6-1
L_GroundArea15_:
      .incbin "levels/smb1/levels/L_6-1.bin"

;warp zone area used in level 4-2
L_GroundArea16_:
      .incbin "levels/smb1/levels/L_WARP.bin"

;level 8-1
L_GroundArea17_:
      .incbin "levels/smb1/levels/L_8-1.bin"

;level 5-2
L_GroundArea18_:
      .incbin "levels/smb1/levels/L_5-2.bin"

;level 8-2
L_GroundArea19_:
      .incbin "levels/smb1/levels/L_8-2.bin"

;level 7-1
L_GroundArea20_:
      .incbin "levels/smb1/levels/L_7-1.bin"

;cloud level used in levels 3-1 and 6-2
L_GroundArea21_:
      .incbin "levels/smb1/levels/L_CLOUD2.bin"

;level 3-2
L_GroundArea22_:
      .incbin "levels/smb1/levels/L_3-2.bin"

;level 1-2
L_UndergroundArea1_:
      .incbin "levels/smb1/levels/L_1-2.bin"

;level 4-2
L_UndergroundArea2_:
      .incbin "levels/smb1/levels/L_4-2.bin"

;underground bonus rooms area used in many levels
L_UndergroundArea3_:
      .incbin "levels/smb1/levels/L_BONUS.bin"

;level 9-4
L_UndergroundArea4_:
      .incbin "levels/smb1/levels/L_9-4.bin"

;water area used in levels 5-2 and 6-2
L_WaterArea1_:
      .incbin "levels/smb1/levels/L_WATER.bin"

;level 2-2/7-2
L_WaterArea2_:
      .incbin "levels/smb1/levels/L_2-2_7-2.bin"

;water area used in level 8-4
L_WaterArea3_:
      .incbin "levels/smb1/levels/L_8-4WATER.bin"

;level 9-1
L_WaterArea4_:
      .incbin "levels/smb1/levels/L_9-1.bin"

;level 9-2
L_WaterArea5_:
      .incbin "levels/smb1/levels/L_9-2.bin"

;level 9-3
L_WaterArea6_:
      .incbin "levels/smb1/levels/L_9-3.bin"

;-------------------------------------------------------------------------------------

;GAME LEVELS DATA

;level 1-4
E_CastleArea1:
  .incbin "levels/smb2/enemies/E_1-4.bin"

;level 2-4
E_CastleArea2:
  .incbin "levels/smb2/enemies/E_2-4.bin"

;level 3-4
E_CastleArea3:
  .incbin "levels/smb2/enemies/E_3-4.bin"

;level 4-4
E_CastleArea4:
  .incbin "levels/smb2/enemies/E_4-4.bin"

;level 5-4
E_CastleArea5:
  .incbin "levels/smb2/enemies/E_5-4.bin"

;level 6-4
E_CastleArea6:
  .incbin "levels/smb2/enemies/E_6-4.bin"

;level 7-4
E_CastleArea7:
  .incbin "levels/smb2/enemies/E_7-4.bin"

;level 8-4
E_CastleArea8:
  .incbin "levels/smb2/enemies/E_8-4.bin"

;level 9-3
E_CastleArea9:
  .incbin "levels/smb2/enemies/E_9-3.bin"

;cloud level used in level 9-3
E_CastleArea10:
  .incbin "levels/smb2/enemies/E_9-3CLOUD.bin"

;level A-4
E_CastleArea11:
  .incbin "levels/smb2/enemies/E_A-4.bin"

;level B-4
E_CastleArea12:
  .incbin "levels/smb2/enemies/E_B-4.bin"

;level C-4
E_CastleArea13:
  .incbin "levels/smb2/enemies/E_C-4.bin"

;level D-4
E_CastleArea14:
  .incbin "levels/smb2/enemies/E_D-4.bin"

;level 1-1
E_GroundArea1:
  .incbin "levels/smb2/enemies/E_1-1.bin"

;level 1-3
E_GroundArea2:
  .incbin "levels/smb2/enemies/E_1-3.bin"

;level 2-1
E_GroundArea3:
  .incbin "levels/smb2/enemies/E_2-1.bin"

;level 2-2
E_GroundArea4:
  .incbin "levels/smb2/enemies/E_2-2.bin"

;level 2-3
E_GroundArea5:
  .incbin "levels/smb2/enemies/E_2-3.bin"

;level 3-1
E_GroundArea6:
  .incbin "levels/smb2/enemies/E_3-1.bin"

;level 3-3
E_GroundArea7:
  .incbin "levels/smb2/enemies/E_3-3.bin"

;level 4-1
E_GroundArea8:
  .incbin "levels/smb2/enemies/E_4-1.bin"

;level 4-2
E_GroundArea9:
  .incbin "levels/smb2/enemies/E_4-2.bin"

;enemy data used by pipe intro area, warp zone area and exit area
E_GroundArea10:
E_GroundArea21:
E_GroundArea28:
  .byte $ff

;level 4-3
E_GroundArea11:
  .incbin "levels/smb2/enemies/E_4-3.bin"

;level 5-1
E_GroundArea12:
  .incbin "levels/smb2/enemies/E_5-1.bin"

;level 5-3
E_GroundArea13:
  .incbin "levels/smb2/enemies/E_5-3.bin"

;level 6-1
E_GroundArea14:
  .incbin "levels/smb2/enemies/E_6-1.bin"

;level 6-3
E_GroundArea15:
  .incbin "levels/smb2/enemies/E_6-3.bin"

;level 7-1
E_GroundArea16:
  .incbin "levels/smb2/enemies/E_7-1.bin"

;level 7-2
E_GroundArea17:
  .incbin "levels/smb2/enemies/E_7-2.bin"

;level 7-3
E_GroundArea18:
  .incbin "levels/smb2/enemies/E_7-3.bin"

;level 8-1
E_GroundArea19:
  .incbin "levels/smb2/enemies/E_8-1.bin"

;cloud level used in levels 2-1, 3-1 and 4-1
E_GroundArea20:
  .incbin "levels/smb2/enemies/E_CLOUD1.bin"

;level 8-2
E_GroundArea22:
  .incbin "levels/smb2/enemies/E_8-2.bin"

;level 8-3
E_GroundArea23:
  .incbin "levels/smb2/enemies/E_8-3.bin"

;another unused area
E_GroundArea24:
  .byte $ff

;level 9-1 starting area
E_GroundArea25:
  .incbin "levels/smb2/enemies/E_9-1GROUND.bin"

;cloud level used with levels 5-1 and 8-3
E_GroundArea29:
  .incbin "levels/smb2/enemies/E_CLOUD2.bin"

;level A-1
E_GroundArea30:
  .incbin "levels/smb2/enemies/E_A-1.bin"

;level A-3
E_GroundArea31:
  .incbin "levels/smb2/enemies/E_A-3.bin"

;level B-1
E_GroundArea32:
  .incbin "levels/smb2/enemies/E_B-1.bin"

;level B-3
E_GroundArea33:
  .incbin "levels/smb2/enemies/E_B-3.bin"

;level C-1
E_GroundArea34:
  .incbin "levels/smb2/enemies/E_C-1.bin"

;level C-2
E_GroundArea35:
  .incbin "levels/smb2/enemies/E_C-2.bin"

;level C-3
E_GroundArea36:
  .incbin "levels/smb2/enemies/E_C-3.bin"

;level D-1
E_GroundArea37:
  .incbin "levels/smb2/enemies/E_D-1.bin"

;level D-2
E_GroundArea38:
  .incbin "levels/smb2/enemies/E_D-2.bin"

;level D-3
E_GroundArea39:
  .incbin "levels/smb2/enemies/E_D-3.bin"

;ground level area used with level D-4
E_GroundArea40:
  .incbin "levels/smb2/enemies/E_D-4GROUND.bin"

;cloud level used with levels A-1, B-1 and D-2
E_GroundArea41:
  .incbin "levels/smb2/enemies/E_CLOUD3.bin"

;level 1-2
E_UndergroundArea1:
  .incbin "levels/smb2/enemies/E_1-2.bin"

;warp zone area used by level 1-2
E_UndergroundArea2:
  .incbin "levels/smb2/enemies/E_1-2WARP.bin"

;underground bonus rooms used in many levels
E_UndergroundArea3:
  .incbin "levels/smb2/enemies/E_BONUS1.bin"

;level 5-2
E_UndergroundArea4:
  .incbin "levels/smb2/enemies/E_5-2.bin"

;underground bonus rooms used with worlds 5-8
E_UndergroundArea5:
  .incbin "levels/smb2/enemies/E_BONUS2.bin"

;level A-2
E_UndergroundArea6:
  .incbin "levels/smb2/enemies/E_A-2.bin"

;underground bonus rooms used with worlds A-D
E_UndergroundArea7:
  .incbin "levels/smb2/enemies/E_BONUS3.bin"

;level 3-2
E_WaterArea1:
  .incbin "levels/smb2/enemies/E_3-2.bin"

;level 6-2
E_WaterArea2:
  .incbin "levels/smb2/enemies/E_6-2.bin"

;water area used by level 4-1
E_WaterArea3:
  .incbin "levels/smb2/enemies/E_WATER1.bin"

;water area used in level 8-4
E_WaterArea4:
  .incbin "levels/smb2/enemies/E_8-4WATER.bin"

;water area used in level 6-1
E_WaterArea5:
  .incbin "levels/smb2/enemies/E_WATER2.bin"

;two unused levels that have the same enemy data address as a used level
E_GroundArea26:
E_GroundArea27:

;level 9-1 water area
E_WaterArea6:
  .incbin "levels/smb2/enemies/E_9-1.bin"

;level 9-2
E_WaterArea7:
  .incbin "levels/smb2/enemies/E_9-2.bin"

;level 9-4
E_WaterArea8:
  .incbin "levels/smb2/enemies/E_9-4.bin"

;level B-2
E_WaterArea9:
  .incbin "levels/smb2/enemies/E_B-2.bin"

;level 1-4
L_CastleArea1:
  .incbin "levels/smb2/levels/L_1-4.bin"


;level 2-4
L_CastleArea2:
  .incbin "levels/smb2/levels/L_2-4.bin"

;level 3-4
L_CastleArea3:
  .incbin "levels/smb2/levels/L_3-4.bin"

;level 4-4
L_CastleArea4:
  .incbin "levels/smb2/levels/L_4-4.bin"

;level 5-4
L_CastleArea5:
  .incbin "levels/smb2/levels/L_5-4.bin"

;level 6-4
L_CastleArea6:
  .incbin "levels/smb2/levels/L_6-4.bin"

;level 7-4
L_CastleArea7:
  .incbin "levels/smb2/levels/L_7-4.bin"

;level 8-4
L_CastleArea8:
  .incbin "levels/smb2/levels/L_8-4.bin"

;level 9-3
L_CastleArea9:
  .incbin "levels/smb2/levels/L_9-3.bin"

;cloud level used by level 9-3
L_CastleArea10:
  .incbin "levels/smb2/levels/L_9-3CLOUD.bin"

;level A-4
L_CastleArea11:
  .incbin "levels/smb2/levels/L_A-4.bin"

;level B-4
L_CastleArea12:
  .incbin "levels/smb2/levels/L_B-4.bin"

;level C-4
L_CastleArea13:
  .incbin "levels/smb2/levels/L_C-4.bin"

;level D-4
L_CastleArea14:
  .incbin "levels/smb2/levels/L_D-4.bin"

;level 1-1
L_GroundArea1:
  .incbin "levels/smb2/levels/L_1-1.bin"

;level 1-3
L_GroundArea2:
  .incbin "levels/smb2/levels/L_1-3.bin"

;level 2-1
L_GroundArea3:
  .incbin "levels/smb2/levels/L_2-1.bin"

;level 2-2
L_GroundArea4:
  .incbin "levels/smb2/levels/L_2-2.bin"

;level 2-3
L_GroundArea5:
  .incbin "levels/smb2/levels/L_2-3.bin"

;level 3-1
L_GroundArea6:
  .incbin "levels/smb2/levels/L_3-1.bin"

;level 3-3
L_GroundArea7:
  .incbin "levels/smb2/levels/L_3-3.bin"

;level 4-1
L_GroundArea8:
  .incbin "levels/smb2/levels/L_4-1.bin"

;level 4-2
L_GroundArea9:
  .incbin "levels/smb2/levels/L_4-2.bin"

;pipe intro area
L_GroundArea10:
  .incbin "levels/smb2/levels/L_PIPE.bin"

;level 4-3
L_GroundArea11:
  .incbin "levels/smb2/levels/L_4-3.bin"

;level 5-1
L_GroundArea12:
  .incbin "levels/smb2/levels/L_5-1.bin"

;level 5-3
L_GroundArea13:
  .incbin "levels/smb2/levels/L_5-3.bin"
 
;level 6-1
L_GroundArea14:
  .incbin "levels/smb2/levels/L_6-1.bin"

;level 6-3
L_GroundArea15:
  .incbin "levels/smb2/levels/L_6-3.bin"

;level 7-1
L_GroundArea16:
  .incbin "levels/smb2/levels/L_7-1.bin"

;level 7-2
L_GroundArea17:
  .incbin "levels/smb2/levels/L_7-2.bin"

;level 7-3
L_GroundArea18:
  .incbin "levels/smb2/levels/L_7-3.bin"

;level 8-1
L_GroundArea19:
  .incbin "levels/smb2/levels/L_8-1.bin"

;cloud level used in levels 2-1, 3-1 and 4-1
L_GroundArea20:
  .incbin "levels/smb2/levels/L_CLOUD1.bin"

;warp zone area used in levels 1-2 and 5-2
L_GroundArea21:
  .incbin "levels/smb2/levels/L_WARP.bin"

;level 8-2
L_GroundArea22:
  .incbin "levels/smb2/levels/L_8-2.bin"

;level 8-3
L_GroundArea23:
  .incbin "levels/smb2/levels/L_8-3.bin"

;three unused levels
L_GroundArea24:
L_GroundArea26:
L_GroundArea27:
  .byte $fd

;level 9-1 starting area
L_GroundArea25:
  .incbin "levels/smb2/levels/L_9-1START.bin"

;exit area used in levels 1-2, 3-2, 5-2, 6-2, A-2 and B-2
L_GroundArea28:
  .incbin "levels/smb2/levels/L_EXIT.bin"

;cloud level used with level 5-1
L_GroundArea29:
  .incbin "levels/smb2/levels/L_CLOUD2.bin"

;level A-1
L_GroundArea30:
  .incbin "levels/smb2/levels/L_A-1.bin"

;level A-3
L_GroundArea31:
  .incbin "levels/smb2/levels/L_A-3.bin"

;level B-1
L_GroundArea32:
  .incbin "levels/smb2/levels/L_B-1.bin"

;level B-3
L_GroundArea33:
  .incbin "levels/smb2/levels/L_B-3.bin"

;level C-1
L_GroundArea34:
  .incbin "levels/smb2/levels/L_C-1.bin"

;level C-2
L_GroundArea35:
  .incbin "levels/smb2/levels/L_C-2.bin"

;level C-3
L_GroundArea36:
  .incbin "levels/smb2/levels/L_C-3.bin"

;level D-1
L_GroundArea37:
  .incbin "levels/smb2/levels/L_D-1.bin"

;level D-2
L_GroundArea38:
  .incbin "levels/smb2/levels/L_D-2.bin"

;level D-3
L_GroundArea39:
  .incbin "levels/smb2/levels/L_D-3.bin"

;ground level area used with level D-4
L_GroundArea40:
  .incbin "levels/smb2/levels/L_D-4GROUND.bin"

;cloud level used with levels A-1, B-1 and D-2
L_GroundArea41:
  .incbin "levels/smb2/levels/L_CLOUD3.bin"

;level 1-2
L_UndergroundArea1:
  .incbin "levels/smb2/levels/L_1-2.bin"

;warp zone area used by level 1-2
L_UndergroundArea2:
  .incbin "levels/smb2/levels/L_1-2WARP.bin"

;underground bonus rooms used with worlds 1-4
L_UndergroundArea3:
  .incbin "levels/smb2/levels/L_BONUS1.bin"

;level 5-2
L_UndergroundArea4:
  .incbin "levels/smb2/levels/L_5-2.bin"

;underground bonus rooms used with worlds 5-8
L_UndergroundArea5:
  .incbin "levels/smb2/levels/L_BONUS2.bin"

;level A-2
L_UndergroundArea6:
  .incbin "levels/smb2/levels/L_A-2.bin"

;underground bonus rooms used with worlds A-D
L_UndergroundArea7:
  .incbin "levels/smb2/levels/L_BONUS3.bin"

;level 3-2
L_WaterArea1:
  .incbin "levels/smb2/levels/L_3-2.bin"

;level 6-2
L_WaterArea2:
  .incbin "levels/smb2/levels/L_6-2.bin"

;water area used by level 4-1
L_WaterArea3:
  .incbin "levels/smb2/levels/L_WATER1.bin"

;water area used in level 8-4
L_WaterArea4:
  .incbin "levels/smb2/levels/L_8-4WATER.bin"

;water area used in level 6-1
L_WaterArea5:
  .incbin "levels/smb2/levels/L_WATER2.bin"

;level 9-1 water area
L_WaterArea6:
  .incbin "levels/smb2/levels/L_9-1.bin"

;level 9-2
L_WaterArea7:
  .incbin "levels/smb2/levels/L_9-2.bin"


;level 9-4
L_WaterArea8:
  .incbin "levels/smb2/levels/L_9-4.bin"

;level B-2
L_WaterArea9:
  .incbin "levels/smb2/levels/L_B-2.bin"

;-------------------------------------------------------------------------------------
