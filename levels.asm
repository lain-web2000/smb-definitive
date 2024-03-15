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
      lda HardWorldFlag      ;are we playing 2J levels?
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
      adc AreaNumber         ;add area number used to find data
      tay
      lda AreaAddrOffsetsJ,y  ;from there we have our area pointer
      rts

GetAreaPointer:
     lda HardWorldFlag         ;are we playing 2J levels?
     bne GetAreaPointerJ       ;yes, use 2J offsets instead
     ldx WorldAddrOffsets,y    ;get offset to where this world's area offsets are
     ldy AreaAddrOffsets,x     ;get area offset based on world offset
     rts
GetAreaPointerJ:
     ldx WorldAddrOffsetsJ,y    ;get offset to where this world's area offsets are
     ldy AreaAddrOffsetsJ,x     ;get area offset based on world offset
     rts

GetAreaDataAddrs:
            lda AreaPointer          ;use 2 MSB for Y
            jsr GetAreaType
            tay
            lda AreaPointer            ;mask out all but 5 LSB
            and #%00011111
            sta AreaAddrsLOffset       ;save as low offset
            lda HardWorldFlag          ;check if playing 2J levels
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
            lda WorldNumber           ;playing 2J letter worlds?
            cmp #WorldA
            bcs GetAreaDataAddrsL     ;yes, alternate offsets
            lda EnemyAddrHOffsetsJ,y  ;load base value with 2 altered MSB,
            clc                        ;then add base value to 5 LSB, result
            adc AreaAddrsLOffset       ;becomes offset for level data
            asl
            tay
            lda EnemyDataAddrsJ+1,y   ;use offset to load pointer
            sta EnemyDataHigh
            lda EnemyDataAddrsJ,y
            sta EnemyDataLow
            ldy AreaType               ;use area type as offset
            lda AreaDataHOffsetsJ,y   ;do the same thing but with different base value
            clc
            adc AreaAddrsLOffset
            asl
            tay
            lda AreaDataAddrsJ+1,y    ;use this offset to load another pointer
            sta AreaDataHigh
            lda AreaDataAddrsJ,y
            sta AreaDataLow
            jmp ContinueAreaDataAddrs
GetAreaDataAddrsL:
            lda EnemyAddrHOffsetsL,y  ;load base value with 2 altered MSB,
            clc                        ;then add base value to 5 LSB, result
            adc AreaAddrsLOffset       ;becomes offset for level data
            asl
            tay
            lda EnemyDataAddrsL+1,y   ;use offset to load pointer
            sta EnemyDataHigh
            lda EnemyDataAddrsL,y
            sta EnemyDataLow
            ldy AreaType               ;use area type as offset
            lda AreaDataHOffsetsL,y   ;do the same thing but with different base value
            clc
            adc AreaAddrsLOffset
            asl
            tay
            lda AreaDataAddrsL+1,y    ;use this offset to load another pointer
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
      .db World1Areas-AreaAddrOffsets, World2Areas-AreaAddrOffsets
      .db World3Areas-AreaAddrOffsets, World4Areas-AreaAddrOffsets
      .db World5Areas-AreaAddrOffsets, World6Areas-AreaAddrOffsets
      .db World7Areas-AreaAddrOffsets, World8Areas-AreaAddrOffsets
      .db World9Areas-AreaAddrOffsets

AreaAddrOffsets:
World1Areas: .db $25, $29, $c0, $26, $60
World2Areas: .db $28, $29, $01, $27, $62
World3Areas: .db $24, $35, $20, $63
World4Areas: .db $22, $29, $41, $2c, $61
World5Areas: .db $2a, $31, $26, $62
World6Areas: .db $2e, $23, $2d, $60
World7Areas: .db $33, $29, $01, $27, $64
World8Areas: .db $30, $32, $21, $65
World9Areas: .db $03, $04, $05, $43

;bonus area data offsets, included here for comparison purposes
;underground bonus area  - c2
;cloud area 1 (day)      - 2b
;cloud area 2 (night)    - 34
;water area (5-2/6-2)    - 00
;water area (8-4)        - 02
;warp zone area (4-2)    - 2f

EnemyAddrHOffsets:
      .db $00, $06, $1c, $20

EnemyDataAddrs:
      .dw E_WaterArea1_, E_WaterArea2_, E_WaterArea3_, E_WaterArea4_, E_WaterArea5_, E_WaterArea6_
      .dw E_GroundArea1_, E_GroundArea2_, E_GroundArea3_
      .dw E_GroundArea4_, E_GroundArea5_, E_GroundArea6_, E_GroundArea7_, E_GroundArea8_, E_GroundArea9_
      .dw E_GroundArea10_, E_GroundArea11_, E_GroundArea12_, E_GroundArea13_, E_GroundArea14_, E_GroundArea15_
      .dw E_GroundArea16_, E_GroundArea17_, E_GroundArea18_, E_GroundArea19_, E_GroundArea20_, E_GroundArea21_
      .dw E_GroundArea22_, E_UndergroundArea1_, E_UndergroundArea2_, E_UndergroundArea3_, E_UndergroundArea4_
      .dw E_CastleArea1_, E_CastleArea2_, E_CastleArea3_, E_CastleArea4_, E_CastleArea5_, E_CastleArea6_

AreaDataHOffsets:
      .db $00, $06, $1c, $20

AreaDataAddrs:
      .dw L_WaterArea1_, L_WaterArea2_, L_WaterArea3_, L_WaterArea4_, L_WaterArea5_, L_WaterArea6_
      .dw L_GroundArea1_, L_GroundArea2_, L_GroundArea3_
      .dw L_GroundArea4_, L_GroundArea5_, L_GroundArea6_, L_GroundArea7_, L_GroundArea8_, L_GroundArea9_
      .dw L_GroundArea10_, L_GroundArea11_, L_GroundArea12_, L_GroundArea13_, L_GroundArea14_, L_GroundArea15_
      .dw L_GroundArea16_, L_GroundArea17_, L_GroundArea18_, L_GroundArea19_, L_GroundArea20_, L_GroundArea21_
      .dw L_GroundArea22_, L_UndergroundArea1_, L_UndergroundArea2_, L_UndergroundArea3_, L_UndergroundArea4_
      .dw L_CastleArea1_, L_CastleArea2_, L_CastleArea3_, L_CastleArea4_, L_CastleArea5_, L_CastleArea6_

;-------------------------------------------------------------------------------------

WorldAddrOffsetsJ:
  .db World1JAreas-AreaAddrOffsetsJ, World2JAreas-AreaAddrOffsetsJ
  .db World3JAreas-AreaAddrOffsetsJ, World4JAreas-AreaAddrOffsetsJ
  .db World5JAreas-AreaAddrOffsetsJ, World6JAreas-AreaAddrOffsetsJ
  .db World7JAreas-AreaAddrOffsetsJ, World8JAreas-AreaAddrOffsetsJ
  .db World9JAreas-AreaAddrOffsetsJ
  .db WorldAAreas-AreaAddrOffsetsJ, WorldBAreas-AreaAddrOffsetsJ
  .db WorldCAreas-AreaAddrOffsetsJ, WorldDAreas-AreaAddrOffsetsJ

AreaAddrOffsetsJ:
World1JAreas: .db $20, $29, $40, $21, $60
World2JAreas: .db $22, $23, $24, $61
World3JAreas: .db $25, $29, $00, $26, $62
World4JAreas: .db $27, $28, $2a, $63
World5JAreas: .db $2b, $29, $43, $2c, $64
World6JAreas: .db $2d, $29, $01, $2e, $65
World7JAreas: .db $2f, $30, $31, $66
World8JAreas: .db $32, $35, $36, $67
World9JAreas: .db $38, $06, $68, $07

WorldAAreas: .db $20, $2c, $40, $21, $60
WorldBAreas: .db $22, $2c, $00, $23, $61
WorldCAreas: .db $24, $25, $26, $62
WorldDAreas: .db $27, $28, $29, $63

EnemyAddrHOffsetsJ:
  .db $2c, $0a, $27, $00

EnemyDataAddrsJ:
  .dw E_CastleArea1, E_CastleArea2, E_CastleArea3, E_CastleArea4, E_CastleArea5, E_CastleArea6
  .dw E_CastleArea7, E_CastleArea8, E_CastleArea9, E_CastleArea10, E_GroundArea1, E_GroundArea2
  .dw E_GroundArea3, E_GroundArea4, E_GroundArea5, E_GroundArea6, E_GroundArea7, E_GroundArea8
  .dw E_GroundArea9, E_GroundArea10, E_GroundArea11, E_GroundArea12, E_GroundArea13, E_GroundArea14
  .dw E_GroundArea15, E_GroundArea16, E_GroundArea17, E_GroundArea18, E_GroundArea19, E_GroundArea20
  .dw E_GroundArea21, E_GroundArea22, E_GroundArea23, E_GroundArea24, E_GroundArea25, E_GroundArea26
  .dw E_GroundArea27, E_GroundArea28, E_GroundArea29, E_UndergroundArea1, E_UndergroundArea2
  .dw E_UndergroundArea3, E_UndergroundArea4, E_UndergroundArea5, E_WaterArea1, E_WaterArea2
  .dw E_WaterArea3, E_WaterArea4, E_WaterArea5, E_WaterArea6, E_WaterArea7, E_WaterArea8

AreaDataHOffsetsJ:
  .db $2c, $0a, $27, $00

AreaDataAddrsJ:
  .dw L_CastleArea1, L_CastleArea2, L_CastleArea3, L_CastleArea4, L_CastleArea5, L_CastleArea6
  .dw L_CastleArea7, L_CastleArea8, L_CastleArea9, L_CastleArea10, L_GroundArea1, L_GroundArea2
  .dw L_GroundArea3, L_GroundArea4, L_GroundArea5, L_GroundArea6, L_GroundArea7, L_GroundArea8
  .dw L_GroundArea9, L_GroundArea10, L_GroundArea11, L_GroundArea12, L_GroundArea13, L_GroundArea14
  .dw L_GroundArea15, L_GroundArea16, L_GroundArea17, L_GroundArea18, L_GroundArea19, L_GroundArea20
  .dw L_GroundArea21, L_GroundArea22, L_GroundArea23, L_GroundArea24, L_GroundArea25, L_GroundArea26
  .dw L_GroundArea27, L_GroundArea28, L_GroundArea29, L_UndergroundArea1, L_UndergroundArea2
  .dw L_UndergroundArea3, L_UndergroundArea4, L_UndergroundArea5, L_WaterArea1, L_WaterArea2
  .dw L_WaterArea3, L_WaterArea4, L_WaterArea5, L_WaterArea6, L_WaterArea7, L_WaterArea8

EnemyAddrHOffsetsL:
     .db $14, $04, $12, $00

EnemyDataAddrsL:
     .dw E_CastleArea11, E_CastleArea12, E_CastleArea13, E_CastleArea14, E_GroundArea30, E_GroundArea31
     .dw E_GroundArea32, E_GroundArea33, E_GroundArea34, E_GroundArea35, E_GroundArea36, E_GroundArea37
     .dw E_GroundArea38, E_GroundArea39, E_GroundArea40, E_GroundArea41, E_GroundArea10, E_GroundArea28
     .dw E_UndergroundArea6, E_UndergroundArea7, E_WaterArea9

AreaDataHOffsetsL:
     .db $14, $04, $12, $00

AreaDataAddrsL:
     .dw L_CastleArea11, L_CastleArea12, L_CastleArea13, L_CastleArea14, L_GroundArea30, L_GroundArea31
     .dw L_GroundArea32, L_GroundArea33, L_GroundArea34, L_GroundArea35, L_GroundArea36, L_GroundArea37
     .dw L_GroundArea38, L_GroundArea39, L_GroundArea40, L_GroundArea41, L_GroundArea10, L_GroundArea28
     .dw L_UndergroundArea6, L_UndergroundArea7, L_WaterArea9

;-------------------------------------------------------------------------------------

;ENEMY OBJECT DATA

;level 1-4/6-4
E_CastleArea1_:
      .incbin "levels/E_1-4_6-4.bin"

;level 4-4
E_CastleArea2_:
      .incbin "levels/E_4-4.bin"

;level 2-4/5-4
E_CastleArea3_:
      .incbin "levels/E_2-4_5-4.bin"

;level 3-4
E_CastleArea4_:
      .incbin "levels/E_3-4.bin"

;level 7-4
E_CastleArea5_:
      .incbin "levels/E_7-4.bin"

;level 8-4
E_CastleArea6_:
      .incbin "levels/E_8-4.bin"

;level 3-3
E_GroundArea1_:
      .incbin "levels/E_3-3.bin"

;level 8-3
E_GroundArea2_:
      .incbin "levels/E_8-3.bin"

;level 4-1
E_GroundArea3_:
      .incbin "levels/E_4-1.bin"

;level 6-2
E_GroundArea4_:
      .incbin "levels/E_6-2.bin"

;level 3-1
E_GroundArea5_:
      .incbin "levels/E_3-1.bin"

;level 1-1
E_GroundArea6_:
      .incbin "levels/E_1-1.bin"

;level 1-3/5-3
E_GroundArea7_:
      .incbin "levels/E_1-3_5-3.bin"

;level 2-3/7-3
E_GroundArea8_:
      .incbin "levels/E_2-3_7-3.bin"

;level 2-1
E_GroundArea9_:
      .incbin "levels/E_2-1.bin"
;end of data terminator here is also used by pipe intro area
E_GroundArea10_:
      .db $ff

;level 5-1
E_GroundArea11_:
      .incbin "levels/E_5-1.bin"

;cloud level used in levels 2-1 and 5-2
E_GroundArea12_:
      .incbin "levels/E_CLOUD1.bin"

;level 4-3
E_GroundArea13_:
      .incbin "levels/E_4-3.bin"

;level 6-3
E_GroundArea14_:
      .incbin "levels/E_6-3.bin"

;level 6-1
E_GroundArea15_:
      .incbin "levels/E_6-1.bin"

;warp zone area used in level 4-2
E_GroundArea16_:
      .db $ff

;level 8-1
E_GroundArea17_:
      .incbin "levels/E_8-1.bin"

;level 5-2
E_GroundArea18_:
      .incbin "levels/E_5-2.bin"

;level 8-2
E_GroundArea19_:
      .incbin "levels/E_8-2.bin"

;level 7-1
E_GroundArea20_:
      .incbin "levels/E_7-1.bin"

;cloud level used in levels 3-1 and 6-2
E_GroundArea21_:
      .incbin "levels/E_CLOUD2.bin"

;level 3-2
E_GroundArea22_:
      .incbin "levels/E_3-2.bin"

;level 1-2
E_UndergroundArea1_:
      .incbin "levels/E_1-2.bin"

;level 4-2
E_UndergroundArea2_:
      .incbin "levels/E_4-2.bin"

;underground bonus rooms area used in many levels
E_UndergroundArea3_:
      .incbin "levels/E_BONUS.bin"

;level 9-4
E_UndergroundArea4_:
      .incbin "levels/E_9-4.bin"

;water area used in levels 5-2 and 6-2
E_WaterArea1_:
      .incbin "levels/E_WATER.bin"

;level 2-2/7-2
E_WaterArea2_:
      .incbin "levels/E_2-2_7-2.bin"

;water area used in level 8-4
E_WaterArea3_:
      .incbin "levels/E_8-4WATER.bin"

;level 9-1
E_WaterArea4_:
      .incbin "levels/E_9-1.bin"

;level 9-2
E_WaterArea5_:
      .incbin "levels/E_9-2.bin"

;level 9-3
E_WaterArea6_:
      .incbin "levels/E_9-3.bin"

;AREA OBJECT DATA

;level 1-4/6-4
L_CastleArea1_:
      .incbin "levels/L_1-4_6-4.bin"

;level 4-4
L_CastleArea2_:
      .incbin "levels/L_4-4.bin"

;level 2-4/5-4
L_CastleArea3_:
      .incbin "levels/L_2-4_5-4.bin"

;level 3-4
L_CastleArea4_:
      .incbin "levels/L_3-4.bin"

;level 7-4
L_CastleArea5_:
      .incbin "levels/L_7-4.bin"

;level 8-4
L_CastleArea6_:
      .incbin "levels/L_8-4.bin"

;level 3-3
L_GroundArea1_:
      .incbin "levels/L_3-3.bin"

;level 8-3
L_GroundArea2_:
      .incbin "levels/L_8-3.bin"

;level 4-1
L_GroundArea3_:
      .incbin "levels/L_4-1.bin"

;level 6-2
L_GroundArea4_:
      .incbin "levels/L_6-2.bin"

;level 3-1
L_GroundArea5_:
      .incbin "levels/L_3-1.bin"

;level 1-1
L_GroundArea6_:
      .incbin "levels/L_1-1.bin"

;level 1-3/5-3
L_GroundArea7_:
      .incbin "levels/L_1-3_5-3.bin"

;level 2-3/7-3
L_GroundArea8_:
      .incbin "levels/L_2-3_7-3.bin"

;level 2-1
L_GroundArea9_:
      .incbin "levels/L_2-1.bin"

;pipe intro area
L_GroundArea10_:
      .incbin "levels/L_PIPE.bin"

;level 5-1
L_GroundArea11_:
      .incbin "levels/L_5-1.bin"

;cloud level used in levels 2-1 and 5-2
L_GroundArea12_:
      .incbin "levels/L_CLOUD1.bin"

;level 4-3
L_GroundArea13_:
      .incbin "levels/L_4-3.bin"

;level 6-3
L_GroundArea14_:
      .incbin "levels/L_6-3.bin"

;level 6-1
L_GroundArea15_:
      .incbin "levels/L_6-1.bin"

;warp zone area used in level 4-2
L_GroundArea16_:
      .incbin "levels/L_WARP.bin"

;level 8-1
L_GroundArea17_:
      .incbin "levels/L_8-1.bin"

;level 5-2
L_GroundArea18_:
      .incbin "levels/L_5-2.bin"

;level 8-2
L_GroundArea19_:
      .incbin "levels/L_8-2.bin"

;level 7-1
L_GroundArea20_:
      .incbin "levels/L_7-1.bin"

;cloud level used in levels 3-1 and 6-2
L_GroundArea21_:
      .incbin "levels/L_CLOUD2.bin"

;level 3-2
L_GroundArea22_:
      .incbin "levels/L_3-2.bin"

;level 1-2
L_UndergroundArea1_:
      .incbin "levels/L_1-2.bin"

;level 4-2
L_UndergroundArea2_:
      .incbin "levels/L_4-2.bin"

;underground bonus rooms area used in many levels
L_UndergroundArea3_:
      .incbin "levels/L_BONUS.bin"

;level 9-4
L_UndergroundArea4_:
      .incbin "levels/L_9-4.bin"

;water area used in levels 5-2 and 6-2
L_WaterArea1_:
      .incbin "levels/L_WATER.bin"

;level 2-2/7-2
L_WaterArea2_:
      .incbin "levels/L_2-2_7-2.bin"

;water area used in level 8-4
L_WaterArea3_:
      .incbin "levels/L_8-4WATER.bin"

;level 9-1
L_WaterArea4_:
      .incbin "levels/L_9-1.bin"

;level 9-2
L_WaterArea5_:
      .incbin "levels/L_9-2.bin"

;level 9-3
L_WaterArea6_:
      .incbin "levels/L_9-3.bin"

;-------------------------------------------------------------------------------------

;GAME LEVELS DATA

;level 1-4
E_CastleArea1:
  .db $35, $9d, $55, $9b, $c9, $1b, $59, $9d, $45, $9b, $c5, $1b, $26, $80, $45, $1b
  .db $b9, $1d, $f0, $15, $59, $9d, $0f, $08, $78, $2d, $96, $28, $90, $b5, $ff

;level 2-4
E_CastleArea2:
  .db $74, $80, $f0, $38, $a0, $bb, $40, $bc, $8c, $1d, $c9, $9d, $05, $9b, $1c, $0c
  .db $59, $1b, $b5, $1d, $2c, $8c, $40, $15, $7c, $1b, $dc, $1d, $6c, $8c, $bc, $0c
  .db $78, $ad, $a5, $28, $90, $b5, $ff

;level 3-4
E_CastleArea3:
  .db $0f, $04, $9c, $0c, $0f, $07, $c5, $1b, $65, $9d, $49, $9d, $5c, $8c, $78, $2d
  .db $90, $b5, $ff

;level 4-4
E_CastleArea4:
  .db $49, $9f, $67, $03, $79, $9d, $a0, $3a, $57, $9f, $bb, $1d, $d5, $25, $0f, $05
  .db $18, $1d, $74, $00, $84, $00, $94, $00, $c6, $29, $49, $9d, $db, $05, $0f, $08
  .db $05, $9b, $09, $1d, $b0, $38, $80, $95, $c0, $3c, $ec, $a8, $cc, $8c, $4a, $9b
  .db $78, $2d, $90, $b5, $ff

;level 5-4
E_CastleArea5:
  .db $2a, $a9, $6b, $0c, $cb, $0c, $15, $9c, $89, $1c, $cc, $1d, $09, $9d, $f5, $1c
  .db $6b, $a9, $ab, $0c, $db, $29, $48, $9d, $9b, $0c, $5b, $8c, $a5, $1c, $49, $9d
  .db $79, $1d, $09, $9d, $6b, $0c, $c9, $1f, $3b, $8c, $88, $95, $b9, $1c, $19, $9d
  .db $30, $cc, $78, $2d, $a6, $28, $90, $b5, $ff

;level 6-4
E_CastleArea6:
  .db $0f, $02, $09, $1f, $8b, $85, $2b, $8c, $e9, $1b, $25, $9d, $0f, $07, $09, $1d
  .db $6d, $28, $99, $1b, $b5, $2c, $4b, $8c, $09, $9f, $fb, $15, $9d, $a8, $0f, $0c
  .db $2b, $0c, $78, $2d, $90, $b5, $ff

;level 7-4
E_CastleArea7:
  .db $05, $9d, $0d, $a8, $dd, $1d, $07, $ac, $54, $2c, $a2, $2c, $f4, $2c, $42, $ac
  .db $26, $9d, $d4, $03, $24, $83, $64, $03, $2b, $82, $4b, $02, $7b, $02, $9b, $02
  .db $5b, $82, $7b, $02, $0b, $82, $2b, $02, $c6, $1b, $28, $82, $48, $02, $a6, $1b
  .db $7b, $95, $85, $0c, $9d, $9b, $0f, $0e, $78, $2d, $7a, $1d, $90, $b5, $ff

;level 8-4
E_CastleArea8:
  .db $19, $9b, $99, $1b, $2c, $8c, $59, $1b, $c5, $0f, $0e, $83, $e0, $0f, $06, $2e
  .db $67, $e7, $0f, $08, $9b, $07, $0e, $83, $e0, $39, $0e, $87, $10, $bd, $28, $59
  .db $9f, $0f, $0f, $34, $0f, $77, $10, $9e, $67, $f1, $0f, $12, $0e, $67, $e3, $78
  .db $2d, $0f, $15, $3b, $29, $57, $82, $0f, $18, $55, $1d, $78, $2d, $90, $b5, $ff

;level 9-3
E_CastleArea9:
    .db $1f, $01, $0e, $69, $00, $1f, $0b, $78, $2d, $ff

;cloud level used in level 9-3
E_CastleArea10:
    .db $1f, $01, $1e, $68, $06, $ff

;level A-4
E_CastleArea11:
  .db $2a, $9e, $6b, $0c, $8d, $1c, $ea, $1f, $1b, $8c, $e6, $1c, $8c, $9c, $bb, $0c
  .db $f3, $83, $9b, $8c, $db, $0c, $1b, $8c, $6b, $0c, $bb, $0c, $0f, $09, $40, $15
  .db $78, $ad, $90, $b5, $ff

;level B-4
E_CastleArea12:
  .db $0f, $02, $38, $1d, $d9, $1b, $6e, $e1, $21, $3a, $a8, $18, $9d, $0f, $07, $18
  .db $1d, $0f, $09, $18, $1d, $0f, $0b, $18, $1d, $7b, $15, $8e, $21, $2e, $b9, $9d
  .db $0f, $0e, $78, $2d, $90, $b5, $ff

;level C-4
E_CastleArea13:
  .db $05, $9d, $65, $1d, $0d, $a8, $dd, $1d, $07, $ac, $54, $2c, $a2, $2c, $f4, $2c
  .db $42, $ac, $26, $9d, $d4, $03, $24, $83, $64, $03, $2b, $82, $4b, $02, $7b, $02
  .db $9b, $02, $5b, $82, $7b, $02, $0b, $82, $2b, $02, $c6, $1b, $28, $82, $48, $02
  .db $a6, $1b, $7b, $95, $85, $0c, $9d, $9b, $0f, $0e, $78, $2d, $7a, $1d, $90, $b5
  .db $ff

;level D-4
E_CastleArea14:
  .db $19, $9f, $99, $1b, $2c, $8c, $59, $1b, $c5, $0f, $0f, $04, $09, $29, $bd, $1d
  .db $0f, $06, $6e, $2a, $61, $0f, $09, $48, $2d, $46, $87, $79, $07, $8e, $63, $60
  .db $a5, $07, $b8, $85, $57, $a5, $8c, $8c, $76, $9d, $78, $2d, $90, $b5, $ff

;level 1-1
E_GroundArea1:
  .db $07, $8e, $47, $03, $0f, $03, $10, $38, $1b, $80, $53, $06, $77, $0e, $83, $83
  .db $a0, $3d, $90, $3b, $90, $b7, $60, $bc, $b7, $0e, $ee, $42, $00, $f7, $80, $6b
  .db $83, $1b, $83, $ab, $06, $ff

;level 1-3
E_GroundArea2:
  .db $96, $a4, $f9, $24, $d3, $83, $3a, $83, $5a, $03, $95, $07, $f4, $0f, $69, $a8
  .db $33, $87, $86, $24, $c9, $24, $4b, $83, $67, $83, $17, $83, $56, $28, $95, $24
  .db $0a, $a4, $ff

;level 2-1
E_GroundArea3:
  .db $0f, $02, $47, $0e, $87, $0e, $c7, $0e, $f7, $0e, $27, $8e, $ee, $42, $25, $0f
  .db $06, $ac, $28, $8c, $a8, $4e, $b3, $20, $8b, $8e, $f7, $90, $36, $90, $e5, $8e
  .db $32, $8e, $c2, $06, $d2, $06, $e2, $06, $ff

;level 2-2
E_GroundArea4:
  .db $15, $8e, $9b, $06, $e0, $37, $80, $bc, $0f, $04, $2b, $3b, $ab, $0e, $eb, $0e
  .db $0f, $06, $f0, $37, $4b, $8e, $6b, $80, $bb, $3c, $4b, $bb, $ee, $42, $20, $1b
  .db $bc, $cb, $00, $ab, $83, $eb, $bb, $0f, $0e, $1b, $03, $9b, $37, $d4, $0e, $a3
  .db $86, $b3, $06, $c3, $06, $ff

;level 2-3
E_GroundArea5:
  .db $c0, $be, $0f, $03, $38, $0e, $15, $8f, $aa, $83, $f8, $07, $0f, $07, $96, $10
  .db $0f, $09, $48, $10, $ba, $03, $ff

;level 3-1
E_GroundArea6:
  .db $87, $85, $a3, $05, $db, $83, $fb, $03, $93, $8f, $bb, $03, $ce, $42, $42, $9b
  .db $83, $ae, $b3, $40, $db, $00, $f4, $0f, $33, $8f, $74, $0f, $10, $bc, $f5, $0f
  .db $2e, $c2, $45, $b7, $03, $f7, $03, $c8, $90, $ff

;level 3-3
E_GroundArea7:
  .db $80, $be, $83, $03, $92, $10, $4b, $80, $b0, $3c, $07, $80, $b7, $24, $0c, $a4
  .db $96, $a9, $1b, $83, $7b, $24, $b7, $24, $97, $83, $e2, $0f, $a9, $a9, $38, $a9
  .db $0f, $0b, $74, $8f, $ff

;level 4-1
E_GroundArea8:
  .db $e2, $91, $0f, $03, $42, $11, $0f, $06, $72, $11, $0f, $08, $ee, $02, $60, $02
  .db $91, $ee, $b3, $60, $d3, $86, $ff

;level 4-2
E_GroundArea9:
  .db $0f, $02, $9b, $02, $ab, $02, $0f, $04, $13, $03, $92, $11, $60, $b7, $00, $bc
  .db $00, $bb, $0b, $83, $cb, $03, $7b, $85, $9e, $c2, $60, $e6, $05, $0f, $0c, $62
  .db $10

;enemy data used by pipe intro area, warp zone area and exit area
E_GroundArea10:
E_GroundArea21:
E_GroundArea28:
  .db $ff

;level 4-3
E_GroundArea11:
  .db $e6, $a9, $57, $a8, $b5, $24, $19, $a4, $76, $28, $a2, $0f, $95, $8f, $9d, $a8
  .db $0f, $07, $09, $29, $55, $24, $8b, $17, $a9, $24, $db, $83, $04, $a9, $24, $8f
  .db $65, $0f, $ff

;level 5-1
E_GroundArea12:
  .db $1b, $82, $4b, $02, $7b, $02, $ab, $02, $0f, $03, $f9, $0e, $d0, $be, $8e, $c4
  .db $86, $f8, $0e, $c0, $ba, $0f, $0d, $3a, $0e, $bb, $02, $30, $b7, $80, $bc, $c0
  .db $bc, $0f, $12, $24, $0f, $54, $0f, $ce, $3c, $80, $d3, $0f, $cb, $8e, $f9, $0e
  .db $ff

;level 5-3
E_GroundArea13:
  .db $0a, $aa, $15, $8f, $44, $0f, $4e, $44, $80, $d8, $07, $57, $90, $0f, $06, $67
  .db $24, $8b, $17, $b9, $24, $ab, $97, $16, $87, $2a, $28, $84, $0f, $57, $a9, $a5
  .db $29, $f5, $29, $a7, $a4, $0a, $a4, $ff

;level 6-1
E_GroundArea14:
  .db $07, $82, $67, $0e, $40, $bd, $e0, $38, $d0, $bc, $6e, $84, $a0, $9b, $05, $0f
  .db $06, $bb, $05, $0f, $08, $0b, $0e, $4b, $0e, $0f, $0a, $05, $29, $85, $29, $0f
  .db $0c, $dd, $28, $ff

;level 6-3
E_GroundArea15:
  .db $0f, $02, $28, $10, $e6, $03, $d8, $90, $0f, $05, $85, $0f, $78, $83, $c8, $10
  .db $18, $83, $58, $83, $f7, $90, $0f, $0c, $43, $0f, $73, $8f, $ff

;level 7-1
E_GroundArea16:
  .db $a7, $83, $d7, $03, $0f, $03, $6b, $00, $0f, $06, $e3, $0f, $14, $8f, $3e, $44
  .db $c3, $0b, $80, $87, $05, $ab, $05, $db, $83, $0f, $0b, $07, $05, $13, $0e, $2b
  .db $02, $4b, $02, $0f, $10, $0b, $0e, $b0, $37, $90, $bc, $80, $bc, $ae, $44, $c0
  .db $ff

;level 7-2
E_GroundArea17:
  .db $0a, $aa, $d5, $8f, $03, $8f, $3e, $44, $c6, $d8, $83, $0f, $06, $a6, $11, $b9
  .db $0e, $39, $9d, $79, $1b, $a6, $11, $e8, $03, $87, $83, $16, $90, $a6, $11, $b9
  .db $1d, $05, $8f, $38, $29, $89, $29, $26, $8f, $46, $29, $ff

;level 7-3
E_GroundArea18:
  .db $0f, $04, $a3, $10, $0f, $09, $e3, $29, $0f, $0d, $55, $24, $a9, $24, $0f, $11
  .db $59, $1d, $a9, $1b, $23, $8f, $15, $9b, $ff

;level 8-1
E_GroundArea19:
  .db $0f, $01, $db, $02, $30, $b7, $80, $3b, $1b, $8e, $4a, $0e, $eb, $03, $3b, $82
  .db $5b, $02, $e5, $0f, $14, $8f, $44, $0f, $5b, $82, $0c, $85, $35, $8f, $06, $85
  .db $e3, $05, $db, $83, $3e, $84, $e0, $ff

;cloud level used in levels 2-1, 3-1 and 4-1
E_GroundArea20:
  .db $0a, $aa, $1e, $22, $29, $1e, $25, $49, $2e, $27, $66, $ff

;level 8-2
E_GroundArea22:
  .db $0f, $02, $0a, $29, $f7, $02, $80, $bc, $6b, $82, $7b, $02, $9b, $02, $ab, $02
  .db $39, $8e, $0f, $07, $ce, $35, $ec, $f5, $0f, $fb, $85, $fb, $85, $3e, $c4, $e3
  .db $a7, $02, $ff

;level 8-3
E_GroundArea23:
  .db $09, $a9, $86, $11, $d5, $10, $a3, $8f, $d5, $29, $86, $91, $2b, $83, $58, $03
  .db $5b, $85, $eb, $05, $3e, $bc, $e0, $0f, $09, $43, $0f, $74, $0f, $6b, $85, $db
  .db $05, $c6, $a4, $19, $a4, $12, $8f
;another unused area
E_GroundArea24:
  .db $ff

;level 9-1 starting area
E_GroundArea25:
    .db $1e, $05, $00, $ff

;cloud level used with level 5-1
E_GroundArea29:
  .db $0a, $aa, $2e, $2b, $98, $2e, $36, $e7, $ff

;level A-1
E_GroundArea30:
  .db $07, $83, $37, $03, $6b, $0e, $e0, $3d, $20, $be, $6e, $2b, $00, $a7, $85, $d3
  .db $05, $e7, $83, $24, $83, $27, $03, $49, $00, $59, $00, $10, $bb, $b0, $3b, $6e
  .db $c1, $00, $17, $85, $53, $05, $36, $8e, $76, $0e, $b6, $0e, $e7, $83, $63, $83
  .db $68, $03, $29, $83, $57, $03, $85, $03, $b5, $29, $ff

;level A-3
E_GroundArea31:
  .db $0f, $04, $66, $07, $0f, $06, $86, $10, $0f, $08, $55, $0f, $e5, $8f, $ff

;level B-1
E_GroundArea32:
  .db $70, $b7, $ca, $00, $66, $80, $0f, $04, $79, $0e, $ab, $0e, $ee, $2b, $20, $eb
  .db $80, $40, $bb, $fb, $00, $40, $b7, $cb, $0e, $0f, $09, $4b, $00, $76, $00, $d8
  .db $00, $6b, $8e, $73, $06, $83, $06, $c7, $0e, $36, $90, $c5, $06, $ff

;level B-3
E_GroundArea33:
  .db $84, $8f, $a7, $24, $d3, $0f, $ea, $24, $45, $a9, $d5, $28, $45, $a9, $84, $25
  .db $b4, $8f, $09, $90, $b5, $a8, $5b, $97, $cd, $28, $b5, $a4, $09, $a4, $65, $28
  .db $92, $90, $e3, $83, $ff

;level C-1
E_GroundArea34:
  .db $3a, $8e, $5b, $0e, $c3, $8e, $ca, $8e, $0b, $8e, $4a, $0e, $de, $c1, $44, $0f
  .db $08, $49, $0e, $eb, $0e, $8a, $90, $ab, $85, $0f, $0c, $03, $0f, $2e, $2b, $40
  .db $67, $86, $ff

;level C-2
E_GroundArea35:
  .db $15, $8f, $54, $07, $aa, $83, $f8, $07, $0f, $04, $14, $07, $96, $10, $0f, $07
  .db $95, $0f, $9d, $a8, $0b, $97, $09, $a9, $55, $24, $a9, $24, $bb, $17, $ff

;level C-3
E_GroundArea36:
  .db $0f, $03, $a6, $11, $a3, $90, $a6, $91, $0f, $08, $a6, $11, $e3, $a9, $0f, $0d
  .db $55, $24, $a9, $24, $0f, $11, $59, $1d, $a9, $1b, $23, $8f, $15, $9b, $ff

;level D-1
E_GroundArea37:
  .db $87, $85, $9b, $05, $18, $90, $a4, $8f, $6e, $c1, $60, $9b, $02, $d0, $3b, $80
  .db $b8, $03, $8e, $1b, $02, $3b, $02, $0f, $08, $03, $10, $f7, $05, $6b, $85, $ff

;level D-2
E_GroundArea38:
  .db $db, $82, $f3, $03, $10, $b7, $80, $37, $1a, $8e, $4b, $0e, $7a, $0e, $ab, $0e
  .db $0f, $05, $f9, $0e, $d0, $be, $2e, $c1, $62, $d4, $8f, $64, $8f, $7e, $2b, $60
  .db $ff

;level D-3
E_GroundArea39:
  .db $0f, $03, $ab, $05, $1b, $85, $a3, $85, $d7, $05, $0f, $08, $33, $03, $0b, $85
  .db $fb, $85, $8b, $85, $3a, $8e, $ff

;ground level area used with level D-4
E_GroundArea40:
  .db $0f, $02, $09, $05, $3e, $41, $64, $2b, $8e, $58, $0e, $ca, $07, $34, $87, $ff

;cloud level used with levels A-1, B-1 and D-2
E_GroundArea41:
  .db $0a, $aa, $1e, $20, $03, $1e, $22, $27, $2e, $24, $48, $2e, $28, $67, $ff

;level 1-2
E_UndergroundArea1:
  .db $0a, $8e, $de, $b4, $00, $e0, $37, $5b, $82, $2b, $a9, $aa, $29, $29, $a9, $a8
  .db $29, $0f, $08, $f0, $3c, $79, $a9, $c5, $26, $cd, $26, $ee, $3b, $01, $67, $b4
  .db $0f, $0c, $2e, $c1, $00, $ff

;warp zone area used by level 1-2
E_UndergroundArea2:
  .db $09, $a9, $19, $a9, $de, $42, $02, $7b, $83, $ff

;underground bonus rooms used in many levels
E_UndergroundArea3:
  .db $1e, $a0, $0a, $1e, $23, $2b, $1e, $28, $6b, $0f, $03, $1e, $40, $08, $1e, $25
  .db $4e, $0f, $06, $1e, $22, $25, $1e, $25, $45, $ff

;level 5-2
E_UndergroundArea4:
  .db $0b, $83, $b7, $03, $d7, $03, $0f, $05, $67, $03, $7b, $02, $9b, $02, $80, $b9
  .db $3b, $83, $4e, $b4, $80, $86, $2b, $c9, $2c, $16, $ac, $67, $b4, $de, $3b, $81
  .db $ff

;underground bonus rooms used with worlds 5-8
E_UndergroundArea5:
  .db $1e, $af, $ca, $1e, $2c, $85, $0f, $04, $1e, $2d, $a7, $1e, $2f, $ce, $1e, $35
  .db $e5, $0f, $07, $1e, $2b, $87, $1e, $30, $c5, $ff

;level A-2
E_UndergroundArea6:
  .db $bb, $a9, $1b, $a9, $69, $29, $b8, $29, $59, $a9, $8d, $a8, $0f, $07, $15, $29
  .db $55, $ac, $6b, $85, $0e, $ad, $01, $67, $34, $ff

;underground bonus rooms used with worlds A-D
E_UndergroundArea7:
  .db $1e, $a0, $09, $1e, $27, $67, $0f, $03, $1e, $28, $68, $0f, $05, $1e, $24, $48
  .db $1e, $63, $68, $ff

;level 3-2
E_WaterArea1:
  .db $0f, $01, $2a, $07, $2e, $3b, $41, $e9, $07, $0f, $03, $6b, $07, $f9, $07, $b8
  .db $80, $2a, $87, $4a, $87, $b3, $0f, $84, $87, $47, $83, $87, $07, $0a, $87, $42
  .db $87, $1b, $87, $6b, $03, $ff

;level 6-2
E_WaterArea2:
  .db $0f, $01, $2e, $3b, $a1, $5b, $07, $ab, $07, $69, $87, $ba, $07, $fb, $87, $65
  .db $a7, $6a, $27, $a6, $a7, $ac, $27, $1b, $87, $88, $07, $2b, $83, $7b, $07, $a7
  .db $90, $e5, $83, $14, $a7, $19, $27, $77, $07, $f8, $07, $47, $8f, $b9, $07, $ff

;water area used by level 4-1
E_WaterArea3:
  .db $1e, $a7, $6a, $5b, $82, $74, $07, $d8, $07, $e8, $02, $0f, $04, $26, $07, $ff

;water area used in level 8-4
E_WaterArea4:
  .db $07, $9b, $0a, $07, $b9, $1b, $66, $9b, $78, $07, $ae, $67, $e5, $ff

;water area used in level 6-1
E_WaterArea5:
  .db $97, $87, $cb, $00, $ee, $2b, $f8, $fe, $2d, $ad, $75, $87, $d3, $27, $d9, $27
  .db $0f, $04, $56, $0f, $ff

;two unused levels that have the same enemy data address as a used level
E_GroundArea26:
E_GroundArea27:

;level 9-1 water area
E_WaterArea6:
    .db $26, $8f, $05, $ac, $46, $0f, $1f, $04, $e8, $10, $38, $90, $66, $11, $fb, $3c
    .db $9b, $b7, $cb, $85, $29, $87, $95, $07, $eb, $02, $0b, $82, $96, $0e, $c3, $0e
    .db $ff

;level 9-2
E_WaterArea7:
    .db $1f, $01, $e6, $11, $ff

;level 9-4
E_WaterArea8:
    .db $3b, $86, $7b, $00, $bb, $02, $2b, $8e, $7a, $05, $57, $87, $27, $8f, $9a, $0c
    .db $ff

;level B-2
E_WaterArea9:
  .db $ee, $ad, $21, $26, $87, $f3, $0e, $66, $87, $cb, $00, $65, $87, $0f, $06, $06
  .db $0e, $97, $07, $cb, $00, $75, $87, $d3, $27, $d9, $27, $0f, $09, $77, $1f, $46
  .db $87, $b1, $0f, $ff

;level 1-4
L_CastleArea1:
  .db $9b, $07, $05, $32, $06, $33, $07, $34, $33, $8e, $4e, $0a, $7e, $06, $9e, $0a
  .db $ce, $06, $e3, $00, $ee, $0a, $1e, $87, $53, $0e, $8e, $02, $9c, $00, $c7, $0e
  .db $d7, $37, $57, $8e, $6c, $05, $da, $60, $e9, $61, $f8, $62, $fe, $0b, $43, $8e
  .db $c3, $0e, $43, $8e, $b7, $0e, $ee, $09, $fe, $0a, $3e, $86, $57, $0e, $6e, $0a
  .db $7e, $06, $ae, $0a, $be, $06, $fe, $07, $15, $e2, $55, $62, $95, $62, $fe, $0a
  .db $0d, $c4, $cd, $43, $ce, $09, $de, $0b, $dd, $42, $fe, $02, $5d, $c7, $fd

;level 2-4
L_CastleArea2:
  .db $9b, $07, $05, $32, $06, $33, $07, $34, $03, $e2, $0e, $06, $1e, $0c, $7e, $0a
  .db $8e, $05, $8e, $82, $8a, $8e, $8e, $0a, $ee, $02, $0a, $e0, $19, $61, $23, $06
  .db $28, $62, $2e, $0b, $7e, $0a, $81, $62, $87, $30, $8e, $04, $a7, $31, $c7, $0e
  .db $d7, $33, $fe, $03, $03, $8e, $0e, $0a, $11, $62, $1e, $04, $27, $32, $4e, $0a
  .db $51, $62, $57, $0e, $5e, $04, $67, $34, $9e, $0a, $a1, $62, $ae, $03, $b3, $0e
  .db $be, $0b, $ee, $09, $fe, $0a, $2e, $82, $7a, $0e, $7e, $0a, $97, $31, $be, $04
  .db $da, $0e, $ee, $0a, $f1, $62, $fe, $02, $3e, $8a, $7e, $06, $ae, $0a, $ce, $06
  .db $fe, $0a, $0d, $c4, $11, $53, $21, $52, $24, $0b, $51, $52, $61, $52, $cd, $43
  .db $ce, $09, $dd, $42, $de, $0b, $fe, $02, $5d, $c7, $fd

;level 3-4
L_CastleArea3:
  .db $5b, $09, $05, $34, $06, $35, $6e, $06, $7e, $0a, $ae, $02, $fe, $02, $0d, $01
  .db $0e, $0e, $2e, $0a, $6e, $09, $be, $0a, $ed, $4b, $e4, $60, $ee, $0d, $5e, $82
  .db $78, $72, $a4, $3d, $a5, $3e, $a6, $3f, $a3, $be, $a6, $3e, $a9, $32, $e9, $3a
  .db $9c, $80, $a3, $33, $a6, $33, $a9, $33, $e5, $06, $ed, $4b, $f3, $30, $f6, $30
  .db $f9, $30, $fe, $02, $0d, $05, $3c, $01, $57, $73, $7c, $02, $93, $30, $a7, $73
  .db $b3, $37, $cc, $01, $07, $83, $17, $03, $27, $03, $37, $03, $64, $3b, $77, $3a
  .db $0c, $80, $2e, $0e, $9e, $02, $a5, $62, $b6, $61, $cc, $02, $c3, $33, $ed, $4b
  .db $03, $b7, $07, $37, $83, $37, $87, $37, $dd, $4b, $03, $b5, $07, $35, $5e, $0a
  .db $8e, $02, $ae, $0a, $de, $06, $fe, $0a, $0d, $c4, $cd, $43, $ce, $09, $dd, $42
  .db $de, $0b, $fe, $02, $5d, $c7, $fd

;level 4-4
L_CastleArea4:
  .db $9b, $07, $05, $32, $06, $33, $07, $34, $4e, $03, $5c, $02, $0c, $f1, $27, $00
  .db $3c, $74, $47, $0e, $fc, $00, $fe, $0b, $77, $8e, $ee, $09, $fe, $0a, $45, $b2
  .db $55, $0e, $99, $32, $b9, $0e, $fe, $02, $0e, $85, $fe, $02, $16, $8e, $2e, $0c
  .db $ae, $0a, $ee, $05, $1e, $82, $47, $0e, $07, $bd, $c4, $72, $de, $0a, $fe, $02
  .db $03, $8e, $07, $0e, $13, $3c, $17, $3d, $e3, $03, $ee, $0a, $f3, $06, $f7, $03
  .db $fe, $0e, $fe, $8a, $38, $e4, $4a, $72, $68, $64, $37, $b0, $98, $64, $a8, $64
  .db $e8, $64, $f8, $64, $0d, $c4, $71, $64, $cd, $43, $ce, $09, $dd, $42, $de, $0b
  .db $fe, $02, $5d, $c7, $fd

;level 5-4
L_CastleArea5:
  .db $9b, $07, $05, $32, $06, $33, $07, $33, $3e, $03, $4c, $50, $4e, $07, $57, $31
  .db $6e, $03, $7c, $52, $9e, $07, $fe, $0a, $7e, $89, $9e, $0a, $ee, $09, $fe, $0b
  .db $13, $8e, $1e, $09, $3e, $0a, $6e, $09, $87, $0e, $9e, $02, $c6, $07, $ca, $0e
  .db $f7, $62, $07, $8e, $08, $61, $17, $62, $1e, $0a, $4e, $06, $5e, $0a, $7e, $06
  .db $8e, $0a, $ae, $06, $be, $07, $f3, $0e, $1e, $86, $2e, $0a, $84, $37, $93, $36
  .db $a2, $45, $1e, $89, $46, $0e, $6e, $0a, $a7, $31, $db, $60, $f7, $60, $1b, $e0
  .db $37, $31, $7e, $09, $8e, $0b, $a3, $0e, $fe, $04, $17, $bb, $47, $0e, $77, $0e
  .db $be, $02, $ce, $0a, $07, $8e, $17, $31, $63, $31, $a7, $34, $c7, $0e, $13, $b1
  .db $4e, $09, $1e, $8a, $7e, $02, $97, $34, $b7, $0e, $ce, $0a, $de, $02, $d8, $61
  .db $f7, $62, $fe, $03, $07, $b4, $17, $0e, $47, $62, $4e, $0a, $5e, $03, $51, $61
  .db $67, $62, $77, $34, $b7, $62, $c1, $61, $da, $60, $e9, $61, $f8, $62, $fe, $0a
  .db $0d, $c4, $01, $52, $11, $52, $21, $52, $31, $52, $41, $52, $51, $52, $61, $52
  .db $cd, $43, $ce, $09, $de, $0b, $dd, $42, $fe, $02, $5d, $c7, $fd

;level 6-4
L_CastleArea6:
  .db $5b, $09, $05, $32, $06, $33, $4e, $0a, $87, $31, $fe, $02, $88, $f2, $c7, $33
  .db $0d, $02, $07, $0e, $17, $34, $6e, $0a, $8e, $02, $bf, $67, $ed, $4b, $b7, $b6
  .db $c3, $35, $1e, $8a, $2e, $02, $33, $3f, $37, $3f, $88, $f2, $c7, $33, $ed, $4b
  .db $0d, $06, $03, $33, $0f, $74, $47, $73, $67, $73, $7e, $09, $9e, $0a, $ed, $4b
  .db $f7, $32, $07, $8e, $97, $0e, $ae, $00, $de, $02, $e3, $35, $e7, $35, $3e, $8a
  .db $4e, $02, $53, $3e, $57, $3e, $07, $8e, $a7, $34, $bf, $63, $ed, $4b, $2e, $8a
  .db $fe, $06, $2e, $88, $34, $33, $35, $33, $6e, $06, $8e, $0c, $be, $06, $fe, $0a
  .db $01, $d2, $0d, $44, $11, $52, $21, $52, $31, $52, $41, $52, $42, $0b, $51, $52
  .db $61, $52, $cd, $43, $ce, $09, $dd, $42, $de, $0b, $fe, $02, $5d, $c7, $fd

;level 7-4
L_CastleArea7:
  .db $58, $07, $05, $35, $06, $3d, $07, $3d, $be, $06, $de, $0c, $f3, $3d, $03, $8e
  .db $6e, $43, $ce, $0a, $e1, $67, $f1, $67, $01, $e7, $11, $67, $1e, $05, $28, $39
  .db $6e, $40, $be, $01, $c7, $06, $db, $0e, $de, $00, $1f, $80, $6f, $00, $bf, $00
  .db $0f, $80, $5f, $00, $7e, $05, $a8, $37, $fe, $02, $24, $8e, $34, $30, $3e, $0c
  .db $4e, $43, $ae, $0a, $be, $0c, $ee, $0a, $fe, $0c, $2e, $8a, $3e, $0c, $7e, $02
  .db $8e, $0e, $98, $36, $b9, $34, $08, $bf, $09, $3f, $0e, $82, $2e, $86, $4e, $0c
  .db $9e, $09, $c1, $62, $c4, $0e, $ee, $0c, $0e, $86, $5e, $0c, $7e, $09, $a1, $62
  .db $a4, $0e, $ce, $0c, $fe, $0a, $28, $b4, $a6, $31, $e8, $34, $8b, $b2, $9b, $0e
  .db $fe, $07, $fe, $8a, $0d, $c4, $cd, $43, $ce, $09, $dd, $42, $de, $0b, $fe, $02
  .db $5d, $c7, $fd

;level 8-4
L_CastleArea8:
  .db $5b, $03, $05, $34, $06, $35, $07, $36, $6e, $0a, $ee, $02, $fe, $05, $0d, $01
  .db $17, $0e, $97, $0e, $9e, $02, $c6, $05, $fa, $30, $fe, $0a, $4e, $82, $57, $0e
  .db $58, $62, $68, $62, $79, $61, $8a, $60, $8e, $0a, $f5, $31, $f9, $7b, $39, $f3
  .db $97, $33, $b5, $71, $39, $f3, $4d, $48, $9e, $02, $ae, $05, $cd, $4a, $ed, $4b
  .db $0e, $81, $17, $06, $39, $73, $5c, $02, $85, $65, $95, $32, $a9, $7b, $cc, $03
  .db $5e, $8f, $6d, $47, $fe, $02, $0d, $07, $39, $73, $4e, $0a, $ae, $02, $ec, $71
  .db $07, $81, $17, $02, $39, $73, $e6, $05, $39, $fb, $4e, $0a, $c4, $31, $eb, $61
  .db $fe, $02, $07, $b0, $1e, $0a, $4e, $06, $57, $0e, $be, $02, $c9, $61, $da, $60
  .db $ed, $4b, $0e, $85, $0d, $0e, $fe, $0a, $78, $e4, $8e, $06, $b3, $06, $bf, $47
  .db $ee, $0f, $6d, $c7, $0e, $82, $39, $73, $9a, $60, $a9, $61, $ae, $06, $de, $0a
  .db $e7, $03, $eb, $79, $f7, $03, $fe, $06, $0d, $14, $fe, $0a, $5e, $82, $7f, $66
  .db $9e, $0a, $f8, $64, $fe, $0b, $9e, $84, $be, $05, $be, $82, $da, $60, $e9, $61
  .db $f8, $62, $fe, $0a, $0d, $c4, $11, $64, $51, $62, $cd, $43, $ce, $09, $dd, $42
  .db $de, $0b, $fe, $02, $5d, $c7, $fd

;level 9-3
L_CastleArea9:
    .db $55, $31, $0d, $01, $cf, $33, $fe, $39, $fe, $b2, $2e, $be, $fe, $31, $29, $8f
    .db $9e, $43, $fe, $30, $16, $b1, $23, $09, $4e, $31, $4e, $40, $d7, $e0, $e6, $61
    .db $fe, $3e, $f5, $62, $fa, $60, $0c, $df, $0c, $df, $0c, $d1, $1e, $3c, $2d, $40
    .db $4e, $32, $5e, $36, $5e, $42, $ce, $38, $0d, $0b, $8e, $36, $8e, $40, $87, $37
    .db $96, $36, $be, $3a, $cc, $5d, $06, $bd, $07, $3e, $a8, $64, $b8, $64, $c8, $64
    .db $d8, $64, $e8, $64, $f8, $64, $fe, $31, $09, $e1, $1a, $60, $6d, $41, $9f, $26
    .db $7d, $c7, $fd

;cloud level used by level 9-3
L_CastleArea10:
    .db $00, $f1, $fe, $b5, $0d, $02, $fe, $34, $07, $cf, $ce, $00, $0d, $05, $8d, $47
    .db $fd

;level A-4
L_CastleArea11:
  .db $9b, $87, $05, $32, $06, $33, $07, $34, $ee, $0a, $0e, $86, $28, $0e, $3e, $0a
  .db $6e, $02, $8b, $0e, $97, $00, $9e, $0a, $ce, $06, $e8, $0e, $fe, $0a, $2e, $86
  .db $6e, $0a, $8e, $08, $e4, $0e, $1e, $82, $8a, $0e, $8e, $0a, $fe, $02, $1a, $e0
  .db $29, $61, $2e, $06, $3e, $09, $56, $60, $65, $61, $6e, $0c, $83, $60, $7e, $8a
  .db $bb, $61, $f9, $63, $27, $e5, $88, $64, $eb, $61, $fe, $05, $68, $90, $0a, $90
  .db $fe, $02, $3a, $90, $3e, $0a, $ae, $02, $da, $60, $e9, $61, $f8, $62, $fe, $0a
  .db $0d, $c4, $a1, $62, $b1, $62, $cd, $43, $ce, $09, $de, $0b, $dd, $42, $fe, $02
  .db $5d, $c7, $fd

;level B-4
L_CastleArea12:
  .db $9b, $07, $05, $32, $06, $33, $07, $33, $3e, $0a, $41, $3b, $42, $3b, $58, $64
  .db $7a, $62, $c8, $31, $18, $e4, $39, $73, $5e, $09, $66, $3c, $0e, $82, $28, $07
  .db $36, $0e, $3e, $0a, $ae, $02, $d7, $0e, $fe, $0c, $fe, $8a, $11, $e5, $21, $65
  .db $31, $65, $4e, $0c, $fe, $02, $16, $8e, $2e, $0e, $fe, $02, $18, $fa, $3e, $0e
  .db $fe, $02, $16, $8e, $2e, $0e, $fe, $02, $18, $fa, $3e, $0e, $fe, $02, $16, $8e
  .db $2e, $0e, $fe, $02, $18, $fa, $3e, $0e, $fe, $02, $16, $8e, $2e, $0e, $fe, $02
  .db $18, $fa, $5e, $0a, $6e, $02, $7e, $0a, $b7, $0e, $ee, $07, $fe, $8a, $0d, $c4
  .db $cd, $43, $ce, $09, $dd, $42, $de, $0b, $fe, $02, $5d, $c7, $fd

;level C-4
L_CastleArea13:
  .db $98, $07, $05, $35, $06, $3d, $07, $3d, $be, $06, $de, $0c, $f3, $3d, $03, $8e
  .db $63, $0e, $6e, $43, $ce, $0a, $e1, $67, $f1, $67, $01, $e7, $11, $67, $1e, $05
  .db $28, $39, $6e, $40, $be, $01, $c7, $06, $db, $0e, $de, $00, $1f, $80, $6f, $00
  .db $bf, $00, $0f, $80, $5f, $00, $7e, $05, $a8, $37, $fe, $02, $24, $8e, $34, $30
  .db $3e, $0c, $4e, $43, $ae, $0a, $be, $0c, $ee, $0a, $fe, $0c, $2e, $8a, $3e, $0c
  .db $7e, $02, $8e, $0e, $98, $36, $b9, $34, $08, $bf, $09, $3f, $0e, $82, $2e, $86
  .db $4e, $0c, $9e, $09, $a6, $60, $c1, $62, $c4, $0e, $ee, $0c, $0e, $86, $5e, $0c
  .db $7e, $09, $86, $60, $a1, $62, $a4, $0e, $c6, $60, $ce, $0c, $fe, $0a, $28, $b4
  .db $a6, $31, $e8, $34, $8b, $b2, $9b, $0e, $fe, $07, $fe, $8a, $0d, $c4, $cd, $43
  .db $ce, $09, $dd, $42, $de, $0b, $fe, $02, $5d, $c7, $fd

;level D-4
L_CastleArea14:
  .db $5b, $03, $05, $34, $06, $35, $39, $71, $6e, $02, $ae, $0a, $fe, $05, $17, $8e
  .db $97, $0e, $9e, $02, $a6, $06, $fa, $30, $fe, $0a, $4e, $82, $57, $0e, $58, $62
  .db $68, $62, $79, $61, $8a, $60, $8e, $0a, $f5, $31, $f9, $73, $39, $f3, $b5, $71
  .db $b7, $31, $4d, $c8, $8a, $62, $9a, $62, $ae, $05, $bb, $0e, $cd, $4a, $fe, $82
  .db $77, $fb, $de, $0f, $4e, $82, $6d, $47, $39, $f3, $0c, $ea, $08, $3f, $b3, $00
  .db $cc, $63, $f9, $30, $69, $f9, $ea, $60, $f9, $61, $fe, $07, $de, $84, $e4, $62
  .db $e9, $61, $f4, $62, $fa, $60, $04, $e2, $14, $62, $24, $62, $34, $62, $3e, $0a
  .db $7e, $0c, $7e, $8a, $8e, $08, $94, $36, $fe, $0a, $0d, $c4, $61, $64, $71, $64
  .db $81, $64, $cd, $43, $ce, $09, $dd, $42, $de, $0b, $fe, $02, $5d, $c7, $fd

;level 1-1
L_GroundArea1:
  .db $52, $31, $0f, $20, $6e, $40, $13, $e4, $23, $24, $27, $23, $37, $07, $66, $61, $ac, $74
  .db $c7, $01, $0b, $f1, $77, $73, $b6, $04, $db, $71, $5c, $82, $83, $2d, $a2, $47
  .db $a7, $0a, $b7, $29, $4f, $b3, $87, $0b, $93, $23, $cc, $06, $e3, $2c, $3a, $e0
  .db $7c, $71, $97, $01, $ac, $73, $e6, $61, $0e, $b1, $b7, $f3, $dc, $02, $d3, $25
  .db $07, $fb, $2c, $01, $e7, $73, $2c, $f2, $34, $72, $57, $00, $7c, $02, $39, $f1
  .db $bf, $37, $33, $e7, $cd, $41, $0f, $a6, $ed, $47, $fd

;level 1-3
L_GroundArea2:
  .db $50, $11, $0f, $26, $fe, $10, $47, $92, $56, $40, $ac, $16, $af, $12, $0f, $95
  .db $73, $16, $82, $44, $ec, $48, $bc, $c2, $1c, $b1, $b3, $16, $c2, $44, $86, $c0
  .db $9c, $14, $9f, $12, $a6, $40, $df, $15, $0b, $96, $43, $12, $97, $31, $d3, $12
  .db $03, $92, $27, $14, $63, $00, $c7, $15, $d6, $43, $ac, $97, $af, $11, $1f, $96
  .db $64, $13, $e3, $12, $2e, $91, $9d, $41, $ae, $42, $df, $20, $cd, $c7, $fd

;level 2-1
L_GroundArea3:
  .db $52, $21, $0f, $20, $6e, $64, $4f, $b2, $7c, $5f, $7c, $3f, $7c, $d8, $7c, $38
  .db $83, $02, $a3, $00, $c3, $02, $f7, $16, $5c, $d6, $cf, $35, $d3, $20, $e3, $0a
  .db $f3, $20, $25, $b5, $2c, $53, $6a, $7a, $8c, $54, $da, $72, $fc, $50, $0c, $d2
  .db $39, $73, $5c, $54, $aa, $72, $cc, $53, $f7, $16, $33, $83, $40, $06, $5c, $5b
  .db $09, $93, $27, $0f, $3c, $5c, $0a, $b0, $63, $27, $78, $72, $93, $09, $97, $03
  .db $a7, $03, $b7, $22, $47, $81, $5c, $72, $2a, $b0, $28, $0f, $3c, $5f, $58, $31
  .db $b8, $31, $28, $b1, $3c, $5b, $98, $31, $fa, $30, $03, $b2, $20, $04, $7f, $b7
  .db $f3, $67, $8d, $c1, $bf, $26, $ad, $c7, $fd

;level 2-2
L_GroundArea4:
  .db $54, $11, $0f, $26, $38, $f2, $ab, $71, $0b, $f1, $96, $42, $ce, $10, $1e, $91
  .db $29, $61, $3a, $60, $4e, $10, $78, $74, $8e, $11, $06, $c3, $1a, $e0, $1e, $10
  .db $5e, $11, $67, $63, $77, $63, $88, $62, $99, $61, $aa, $60, $be, $10, $0a, $f2
  .db $15, $45, $7e, $11, $7a, $31, $9a, $e0, $ac, $02, $d9, $61, $d4, $0a, $ec, $01
  .db $d6, $c2, $84, $c3, $98, $fa, $d3, $07, $d7, $0b, $e9, $61, $ee, $10, $2e, $91
  .db $39, $71, $93, $03, $a6, $03, $be, $10, $e1, $71, $e3, $31, $5e, $91, $69, $61
  .db $e6, $41, $28, $e2, $99, $71, $ae, $10, $ce, $11, $be, $90, $d6, $32, $3e, $91
  .db $5f, $37, $66, $60, $d3, $67, $6d, $c1, $af, $26, $9d, $c7, $fd

;level 2-3
L_GroundArea5:
  .db $54, $11, $0f, $26, $af, $32, $d8, $62, $e8, $62, $f8, $62, $fe, $10, $fe, $43
  .db $0c, $be, $f8, $64, $0d, $c8, $2c, $43, $98, $64, $ac, $39, $48, $e4, $6a, $62
  .db $7c, $47, $fa, $62, $3c, $b7, $ea, $62, $fc, $4d, $f6, $02, $03, $80, $06, $02
  .db $13, $02, $da, $62, $0d, $c8, $0b, $17, $97, $16, $2c, $b1, $33, $43, $6c, $31
  .db $ac, $31, $17, $93, $73, $12, $cc, $31, $1a, $e2, $2c, $4b, $67, $48, $ea, $62
  .db $ee, $40, $0d, $ca, $17, $12, $53, $12, $be, $11, $1d, $c1, $3e, $42, $6f, $20
  .db $4d, $c7, $fd

;level 3-1
L_GroundArea6:
  .db $52, $b1, $0f, $20, $6e, $75, $53, $aa, $57, $25, $b7, $0a, $c7, $23, $0c, $83
  .db $5c, $72, $87, $01, $c3, $00, $c7, $20, $dc, $65, $0c, $87, $c3, $22, $f3, $03
  .db $03, $a2, $27, $7b, $33, $03, $43, $23, $52, $42, $9c, $06, $a7, $20, $c3, $23
  .db $03, $a2, $0c, $02, $33, $09, $39, $71, $43, $23, $77, $06, $83, $67, $a7, $73
  .db $5c, $82, $c9, $11, $07, $80, $1c, $71, $98, $11, $9a, $10, $f3, $04, $16, $f4
  .db $3c, $02, $68, $7a, $8c, $01, $a7, $73, $e7, $73, $ac, $83, $09, $8f, $1c, $03
  .db $9f, $37, $13, $e7, $7c, $02, $ad, $41, $ef, $26, $0d, $0e, $39, $71, $7f, $37
  .db $f2, $68, $02, $e8, $12, $3a, $1c, $00, $68, $7a, $de, $3f, $6d, $c5, $fd

;level 3-3
L_GroundArea7:
  .db $55, $10, $0b, $1f, $0f, $26, $d6, $12, $07, $9f, $33, $1a, $fb, $1f, $f7, $94
  .db $53, $94, $71, $71, $cc, $15, $cf, $13, $1f, $98, $63, $12, $9b, $13, $a9, $71
  .db $fb, $17, $09, $f1, $13, $13, $21, $42, $59, $0f, $eb, $13, $33, $93, $40, $06
  .db $8c, $14, $8f, $17, $93, $40, $cf, $13, $0b, $94, $57, $15, $07, $93, $19, $f3
  .db $c6, $43, $c7, $13, $d3, $03, $e3, $03, $33, $b0, $4a, $72, $55, $46, $73, $31
  .db $a8, $74, $e3, $12, $8e, $91, $ad, $41, $ce, $42, $ef, $20, $dd, $c7, $fd

;level 4-1
L_GroundArea8:
  .db $52, $21, $0f, $20, $6e, $63, $a9, $f1, $fb, $71, $22, $83, $37, $0b, $36, $50
  .db $39, $51, $b8, $62, $57, $f3, $e8, $02, $f8, $02, $08, $82, $18, $02, $2d, $4a
  .db $28, $02, $38, $02, $48, $00, $a8, $0f, $aa, $30, $bc, $5a, $6a, $b0, $4f, $b6
  .db $b7, $04, $9a, $b0, $ac, $71, $c7, $01, $e6, $74, $0d, $09, $46, $02, $56, $00
  .db $6c, $01, $84, $79, $86, $02, $96, $02, $a4, $71, $a6, $02, $b6, $02, $c4, $71
  .db $c6, $02, $d6, $02, $39, $f1, $6c, $00, $77, $02, $a3, $09, $ac, $00, $b8, $72
  .db $dc, $01, $07, $f3, $4c, $00, $6f, $37, $e3, $03, $e6, $03, $5d, $ca, $6c, $00
  .db $7d, $41, $cf, $26, $9d, $c7, $fd

;level 4-2
L_GroundArea9:
  .db $50, $a1, $0f, $26, $17, $91, $19, $11, $48, $00, $68, $11, $6a, $10, $96, $14
  .db $d8, $0a, $e8, $02, $f8, $02, $dc, $81, $6c, $81, $89, $0f, $9c, $00, $c3, $29
  .db $f8, $62, $47, $a7, $c6, $61, $0d, $07, $56, $74, $b7, $00, $b9, $11, $cc, $76
  .db $ed, $4a, $1c, $80, $37, $01, $3a, $10, $de, $20, $e9, $0b, $ee, $21, $c8, $bc
  .db $9c, $f6, $bc, $00, $cb, $7a, $eb, $72, $0c, $82, $39, $71, $b7, $63, $cc, $03
  .db $e6, $60, $26, $e0, $4a, $30, $53, $31, $5c, $58, $ed, $41, $2f, $a6, $1d, $c7
  .db $fd

;pipe intro area
L_GroundArea10:
  .db $38, $11, $0f, $26, $ad, $40, $3d, $c7, $fd

;level 4-3
L_GroundArea11:
  .db $50, $11, $0f, $26, $fe, $10, $8b, $93, $a9, $0f, $14, $c1, $cc, $16, $cf, $11
  .db $2f, $95, $b7, $14, $c7, $96, $d6, $44, $2b, $92, $39, $0f, $72, $41, $a7, $00
  .db $1b, $95, $97, $13, $6c, $95, $6f, $11, $a2, $40, $bf, $15, $c2, $40, $0b, $9f
  .db $53, $16, $62, $44, $72, $c2, $9b, $1d, $b7, $e0, $ed, $4a, $03, $e0, $8e, $11
  .db $9d, $41, $be, $42, $ef, $20, $cd, $c7, $fd

;level 5-1
L_GroundArea12:
  .db $52, $b1, $0f, $20, $6e, $75, $cc, $73, $a3, $b3, $bf, $74, $0c, $84, $83, $3f
  .db $9f, $74, $ef, $71, $ec, $01, $2f, $f1, $2c, $01, $6f, $71, $6c, $01, $a8, $91
  .db $aa, $10, $77, $fb, $56, $f4, $39, $f1, $bf, $37, $33, $e7, $43, $04, $47, $03
  .db $6c, $05, $c3, $67, $d3, $67, $e3, $67, $ed, $4c, $fc, $07, $73, $e7, $83, $67
  .db $93, $67, $a3, $67, $bc, $08, $43, $e7, $53, $67, $dc, $02, $59, $91, $c3, $33
  .db $d9, $71, $df, $72, $2d, $cd, $5b, $71, $9b, $71, $3b, $f1, $a7, $c2, $db, $71
  .db $0d, $10, $9b, $71, $0a, $b0, $1c, $04, $67, $63, $76, $64, $85, $65, $94, $66
  .db $a3, $67, $b3, $67, $cc, $09, $73, $a3, $87, $22, $b3, $09, $d6, $83, $e3, $03
  .db $fe, $3f, $0d, $15, $de, $31, $ec, $01, $03, $f7, $9d, $41, $df, $26, $0d, $18
  .db $39, $71, $7f, $37, $f2, $68, $01, $e9, $11, $39, $68, $7a, $de, $3f, $6d, $c5
  .db $fd

;level 5-3
L_GroundArea13:
  .db $50, $11, $0f, $26, $df, $32, $fe, $10, $0d, $01, $98, $74, $c8, $13, $52, $e1
  .db $63, $31, $61, $79, $c6, $61, $06, $e1, $8b, $71, $ab, $71, $e4, $19, $eb, $19
  .db $60, $86, $c8, $13, $cd, $4b, $39, $f3, $98, $13, $17, $f5, $7c, $15, $7f, $13
  .db $cf, $15, $d4, $40, $0b, $9a, $23, $16, $32, $44, $a3, $95, $b2, $43, $0d, $0a
  .db $27, $14, $3d, $4a, $a4, $40, $bc, $16, $bf, $13, $c4, $40, $04, $c0, $1f, $16
  .db $24, $40, $43, $31, $ce, $11, $dd, $41, $0e, $d2, $3f, $20, $3d, $c7, $fd
 
;level 6-1
L_GroundArea14:
  .db $52, $a1, $0f, $20, $6e, $40, $d6, $61, $e7, $07, $f7, $21, $16, $e1, $34, $63
  .db $47, $21, $54, $04, $67, $0a, $74, $63, $dc, $01, $06, $e1, $17, $26, $86, $61
  .db $66, $c2, $58, $c1, $f7, $03, $04, $f6, $8a, $10, $9c, $04, $e8, $62, $f9, $61
  .db $0a, $e0, $53, $31, $5f, $73, $7b, $71, $77, $25, $fc, $e2, $17, $aa, $23, $00
  .db $3c, $67, $b3, $01, $cc, $63, $db, $71, $df, $73, $fc, $00, $4f, $b7, $ca, $7a
  .db $c5, $31, $ec, $54, $3c, $dc, $5d, $4c, $0f, $b3, $47, $63, $6b, $f1, $8c, $0a
  .db $39, $f1, $ec, $03, $f0, $33, $0f, $e2, $29, $73, $49, $61, $58, $62, $67, $73
  .db $85, $65, $94, $66, $a3, $77, $ad, $4d, $4d, $c1, $6f, $26, $5d, $c7, $fd

;level 6-3
L_GroundArea15:
  .db $50, $11, $0f, $26, $af, $32, $d8, $62, $de, $10, $08, $e4, $0e, $43, $5a, $62
  .db $6c, $4c, $86, $43, $ad, $48, $3a, $e2, $53, $42, $88, $64, $9c, $36, $08, $e4
  .db $4a, $62, $5c, $4d, $3a, $e2, $9c, $32, $fc, $41, $3c, $b1, $83, $00, $ac, $42
  .db $2a, $e2, $3c, $46, $aa, $62, $bc, $4e, $c6, $43, $46, $c3, $aa, $62, $bd, $48
  .db $0b, $96, $47, $07, $c7, $12, $3c, $c2, $9c, $41, $cd, $48, $dc, $32, $4c, $c2
  .db $bc, $32, $1c, $b1, $5a, $62, $6c, $44, $76, $43, $ba, $62, $be, $40, $dc, $32
  .db $5d, $ca, $73, $12, $e3, $12, $8e, $91, $9d, $41, $be, $42, $ef, $20, $cd, $c7
  .db $fd

;level 7-1
L_GroundArea16:
  .db $52, $b1, $0f, $20, $6e, $76, $03, $b1, $09, $71, $0f, $71, $6f, $33, $a7, $63
  .db $b7, $34, $bc, $0e, $4d, $cc, $03, $a6, $08, $72, $3f, $72, $6d, $4c, $73, $07
  .db $77, $73, $83, $27, $ac, $00, $bf, $73, $3c, $80, $9a, $30, $ac, $5b, $c6, $3c
  .db $6a, $b0, $75, $10, $96, $74, $b6, $0a, $da, $30, $e3, $28, $ec, $5b, $ed, $48
  .db $aa, $b0, $33, $b4, $51, $79, $ad, $4a, $dd, $4d, $e3, $2c, $0c, $fa, $73, $07
  .db $b3, $04, $cb, $71, $ec, $07, $0d, $0a, $39, $71, $df, $33, $ca, $b0, $d6, $10
  .db $d7, $30, $dc, $0c, $03, $b1, $ad, $41, $ef, $26, $ed, $c7, $39, $f1, $0d, $10
  .db $7d, $4c, $0d, $13, $a8, $11, $aa, $10, $1c, $83, $d7, $7b, $f3, $67, $5d, $cd
  .db $6d, $47, $fd

;level 7-2
L_GroundArea17:
  .db $56, $11, $0f, $26, $df, $32, $fe, $11, $0d, $01, $0c, $5f, $03, $80, $0c, $52
  .db $29, $15, $7c, $5b, $23, $b2, $29, $1f, $31, $79, $1c, $de, $48, $3b, $ed, $4b
  .db $39, $f1, $cf, $b3, $fe, $10, $37, $8e, $77, $0e, $9e, $11, $a8, $34, $a9, $34
  .db $aa, $34, $f8, $62, $fe, $10, $37, $b6, $de, $11, $e7, $63, $f8, $62, $09, $e1
  .db $0e, $10, $47, $36, $b7, $0e, $be, $91, $ca, $32, $ee, $10, $1d, $ca, $7e, $11
  .db $83, $77, $9e, $10, $1e, $91, $2d, $41, $4f, $26, $4d, $c7, $fd

;level 7-3
L_GroundArea18:
  .db $57, $11, $0f, $26, $fe, $10, $4b, $92, $59, $0f, $ad, $4c, $d3, $93, $0b, $94
  .db $29, $0f, $7b, $93, $99, $0f, $0d, $06, $27, $12, $35, $0f, $23, $b1, $57, $75
  .db $a3, $31, $ab, $71, $f7, $75, $23, $b1, $87, $13, $95, $0f, $0d, $0a, $23, $35
  .db $38, $13, $55, $00, $9b, $16, $0b, $96, $c7, $75, $3b, $92, $49, $0f, $ad, $4c
  .db $29, $92, $52, $40, $6c, $15, $6f, $11, $72, $40, $bf, $15, $03, $93, $0a, $13
  .db $12, $41, $8b, $12, $99, $0f, $0d, $10, $47, $16, $46, $45, $b3, $32, $13, $b1
  .db $57, $0e, $a7, $0e, $d3, $31, $53, $b1, $a6, $31, $03, $b2, $13, $0e, $8d, $4d
  .db $ae, $11, $bd, $41, $ee, $52, $0f, $a0, $dd, $47, $fd

;level 8-1
L_GroundArea19:
  .db $52, $a1, $0f, $20, $6e, $65, $57, $f3, $60, $21, $6f, $62, $ac, $75, $07, $80
  .db $1c, $76, $87, $01, $9c, $70, $b0, $33, $cf, $66, $57, $e3, $6c, $04, $cd, $4c
  .db $9a, $b0, $ac, $0c, $83, $b1, $8f, $74, $bd, $4d, $f8, $11, $fa, $10, $83, $87
  .db $93, $22, $9f, $74, $59, $f1, $89, $61, $a9, $61, $bc, $0c, $67, $a0, $eb, $71
  .db $77, $87, $7a, $10, $86, $51, $95, $52, $a4, $53, $b6, $04, $b3, $24, $26, $85
  .db $4a, $10, $53, $23, $5c, $00, $6f, $73, $93, $08, $07, $fb, $2c, $04, $33, $30
  .db $74, $76, $eb, $71, $57, $8b, $6c, $02, $96, $74, $e3, $30, $0c, $86, $7d, $41
  .db $bf, $26, $bd, $c7, $fd

;cloud level used in levels 2-1, 3-1 and 4-1
L_GroundArea20:
  .db $00, $c1, $4c, $00, $03, $cf, $00, $d7, $23, $4d, $07, $af, $2a, $4c, $03, $cf
  .db $3e, $80, $f3, $4a, $bb, $c2, $bd, $c7, $fd

;warp zone area used in levels 1-2 and 5-2
L_GroundArea21:
  .db $10, $00, $0b, $13, $5b, $14, $6a, $42, $c7, $12, $c6, $42, $1b, $94, $2a, $42
  .db $53, $13, $62, $41, $97, $17, $a6, $45, $6e, $81, $8f, $37, $02, $e8, $12, $3a
  .db $68, $7a, $de, $0f, $6d, $c5, $fd

;level 8-2
L_GroundArea22:
  .db $50, $61, $0f, $26, $bb, $f1, $dc, $06, $23, $87, $b5, $71, $b7, $31, $d7, $28
  .db $06, $c5, $67, $08, $0d, $05, $39, $71, $7c, $00, $9e, $62, $b6, $0b, $e6, $08
  .db $4e, $e0, $5d, $4c, $59, $0f, $6c, $02, $93, $67, $ac, $56, $ad, $4c, $1f, $b1
  .db $3c, $01, $98, $0a, $9e, $20, $a8, $21, $f3, $09, $0e, $a1, $27, $20, $3e, $62
  .db $56, $08, $7d, $4d, $c6, $08, $3e, $e0, $9e, $62, $b6, $08, $1e, $e0, $4c, $00
  .db $6c, $00, $a7, $7b, $de, $2f, $6d, $c7, $fe, $10, $0b, $93, $5b, $15, $b7, $12
  .db $03, $91, $ab, $1f, $bd, $41, $ef, $26, $ad, $c7, $fd

;level 8-3
L_GroundArea23:
  .db $50, $50, $0f, $26, $0b, $1f, $57, $92, $8b, $12, $d2, $14, $4b, $92, $59, $0f
  .db $0b, $95, $bb, $1f, $be, $52, $58, $e2, $9e, $50, $97, $08, $bb, $1f, $ae, $d2
  .db $b6, $08, $bb, $1f, $dd, $4a, $f6, $07, $26, $89, $8e, $50, $98, $62, $eb, $11
  .db $07, $f3, $0b, $1d, $2e, $52, $47, $0a, $ce, $50, $eb, $1f, $ee, $52, $5e, $d0
  .db $d9, $0f, $ab, $9f, $be, $52, $8e, $d0, $ab, $1d, $ae, $52, $36, $8b, $56, $08
  .db $5e, $50, $dc, $15, $df, $12, $2f, $95, $c3, $31, $5b, $9f, $6d, $41, $8e, $52
  .db $af, $20, $ad, $c7

;three unused levels
L_GroundArea24:
L_GroundArea26:
L_GroundArea27:
  .db $fd

;level 9-1 starting area
L_GroundArea25:
    .db $50, $02, $9f, $38, $ee, $01, $12, $b9, $77, $7b, $de, $0f, $6d, $c7, $fd

;exit area used in levels 1-2, 3-2, 5-2, 6-2, A-2 and B-2
L_GroundArea28:
  .db $90, $31, $39, $f1, $bf, $37, $33, $e7, $a3, $03, $a7, $03, $cd, $41, $0f, $a6
  .db $ed, $47, $fd

;cloud level used with level 5-1
L_GroundArea29:
  .db $00, $c1, $4c, $00, $f3, $4f, $fa, $c6, $68, $a0, $69, $20, $6a, $20, $7a, $47
  .db $f8, $20, $f9, $20, $fa, $20, $0a, $cf, $b4, $49, $55, $a0, $56, $20, $73, $47
  .db $f5, $20, $f6, $20, $22, $a1, $41, $48, $52, $20, $72, $20, $92, $20, $b2, $20
  .db $fe, $00, $9b, $c2, $ad, $c7, $fd

;level A-1
L_GroundArea30:
  .db $52, $71, $0f, $20, $6e, $70, $e3, $64, $fc, $61, $fc, $71, $13, $86, $2c, $61
  .db $2c, $71, $43, $64, $b2, $22, $b5, $62, $c7, $28, $22, $a2, $52, $09, $56, $61
  .db $6c, $03, $db, $71, $fc, $03, $f3, $20, $03, $a4, $0f, $71, $40, $0c, $8c, $74
  .db $9c, $66, $d7, $01, $ec, $71, $89, $e1, $b6, $61, $b9, $2a, $c7, $26, $f4, $23
  .db $67, $e2, $e8, $f2, $78, $82, $88, $01, $98, $02, $a8, $02, $b8, $02, $03, $a6
  .db $07, $26, $21, $79, $4b, $71, $cf, $33, $06, $e4, $16, $2a, $39, $71, $58, $45
  .db $5a, $45, $c6, $07, $dc, $04, $3f, $e7, $3b, $71, $30, $31, $8c, $71, $ac, $01
  .db $e7, $63, $39, $8f, $63, $20, $65, $0b, $68, $62, $8c, $00, $0c, $81, $29, $63
  .db $3c, $01, $57, $65, $6c, $01, $85, $67, $9c, $04, $1d, $c1, $5f, $26, $3d, $c7
  .db $fd

;level A-3
L_GroundArea31:
  .db $50, $50, $0b, $1f, $0f, $26, $19, $96, $84, $43, $b7, $1f, $5d, $cc, $6d, $48
  .db $e0, $42, $e3, $12, $39, $9c, $56, $43, $47, $9b, $a4, $12, $c1, $06, $ed, $4d
  .db $f4, $42, $1b, $98, $b7, $13, $02, $c2, $03, $12, $47, $1f, $ad, $48, $63, $9c
  .db $82, $48, $76, $93, $08, $94, $8e, $11, $b0, $03, $c9, $0f, $1d, $c1, $2d, $4a
  .db $4e, $42, $6f, $20, $0d, $0e, $0e, $40, $39, $71, $7f, $37, $f2, $68, $01, $e9
  .db $11, $39, $68, $7a, $de, $1f, $6d, $c5, $fd

;level B-1
L_GroundArea32:
  .db $52, $21, $0f, $20, $6e, $60, $6c, $f6, $ca, $30, $dc, $02, $08, $f2, $37, $04
  .db $56, $74, $7c, $00, $dc, $01, $e7, $25, $47, $8b, $49, $20, $6c, $02, $96, $74
  .db $06, $82, $36, $02, $66, $00, $a7, $22, $dc, $02, $0a, $e0, $63, $22, $78, $72
  .db $93, $09, $97, $03, $a3, $25, $a7, $03, $b6, $24, $03, $a2, $5c, $75, $65, $71
  .db $7c, $00, $9c, $00, $63, $a2, $67, $20, $77, $03, $87, $20, $93, $0a, $97, $03
  .db $a3, $22, $a7, $20, $b7, $03, $bc, $00, $c7, $20, $dc, $00, $fc, $01, $19, $8f
  .db $1e, $20, $46, $22, $4c, $61, $63, $00, $8e, $21, $d7, $73, $46, $a6, $4c, $62
  .db $68, $62, $73, $01, $8c, $62, $d8, $62, $43, $a9, $c7, $73, $ec, $06, $57, $f3
  .db $7c, $00, $b5, $65, $c5, $65, $dc, $00, $e3, $67, $7d, $c1, $bf, $26, $ad, $c7
  .db $fd

;level B-3
L_GroundArea33:
  .db $90, $10, $0b, $1b, $0f, $26, $07, $94, $bc, $14, $bf, $13, $c7, $40, $ff, $16
  .db $d1, $80, $c3, $94, $cb, $17, $c2, $44, $29, $8f, $77, $31, $0b, $96, $76, $32
  .db $c7, $75, $13, $f7, $1b, $61, $2b, $61, $4b, $12, $59, $0f, $3b, $b0, $3a, $40
  .db $43, $12, $7a, $40, $7b, $30, $b5, $41, $b6, $20, $c6, $07, $f3, $13, $03, $92
  .db $6b, $12, $79, $0f, $cc, $15, $cf, $11, $1f, $95, $c3, $14, $b3, $95, $a3, $95
  .db $4d, $ca, $6b, $61, $7e, $11, $8d, $41, $be, $42, $df, $20, $bd, $c7, $fd

;level C-1
L_GroundArea34:
  .db $52, $31, $0f, $20, $6e, $74, $0d, $02, $03, $33, $1f, $72, $39, $71, $65, $04
  .db $6c, $70, $77, $01, $84, $72, $8c, $72, $b3, $34, $ec, $01, $ef, $72, $0d, $04
  .db $ac, $67, $cc, $01, $cf, $71, $e7, $22, $17, $88, $23, $00, $27, $23, $3c, $62
  .db $65, $71, $67, $33, $8c, $61, $dc, $01, $08, $fa, $45, $75, $63, $0a, $73, $23
  .db $7c, $02, $8f, $72, $73, $a9, $9f, $74, $bf, $74, $ef, $73, $39, $f1, $fc, $0a
  .db $0d, $0b, $13, $25, $4c, $01, $4f, $72, $73, $0b, $77, $03, $dc, $08, $23, $a2
  .db $53, $09, $56, $03, $63, $24, $8c, $02, $3f, $b3, $77, $63, $96, $74, $b3, $77
  .db $5d, $c1, $8f, $26, $7d, $c7, $fd

;level C-2
L_GroundArea35:
  .db $54, $11, $0f, $26, $cf, $32, $ee, $43, $f8, $62, $fe, $10, $3c, $b2, $bd, $48
  .db $ea, $62, $fc, $4d, $fc, $4d, $17, $c9, $da, $62, $0b, $97, $b7, $12, $2c, $b1
  .db $33, $43, $6c, $31, $ac, $41, $0b, $98, $7e, $40, $ad, $4a, $db, $30, $27, $b0
  .db $b7, $14, $c6, $42, $c7, $96, $d6, $44, $2b, $92, $39, $0f, $72, $41, $a7, $00
  .db $1b, $95, $97, $13, $6c, $95, $6f, $11, $a2, $40, $bf, $15, $c2, $40, $0b, $9a
  .db $62, $42, $63, $12, $ad, $4a, $0e, $91, $1d, $41, $4f, $26, $4d, $c7, $fd

;level C-3
L_GroundArea36:
  .db $57, $11, $0f, $26, $fe, $10, $4b, $92, $59, $0f, $ad, $4c, $d3, $93, $0b, $94
  .db $29, $0f, $7b, $93, $99, $0f, $0d, $06, $27, $12, $35, $0f, $23, $b1, $57, $75
  .db $a3, $31, $ab, $71, $f7, $75, $23, $b1, $87, $13, $95, $0f, $0d, $0a, $23, $35
  .db $38, $13, $55, $00, $9b, $16, $0b, $96, $c7, $75, $dd, $4a, $3b, $92, $49, $0f
  .db $ad, $4c, $29, $92, $52, $40, $6c, $15, $6f, $11, $72, $40, $bf, $15, $03, $93
  .db $0a, $13, $12, $41, $8b, $12, $99, $0f, $0d, $10, $47, $16, $46, $45, $b3, $32
  .db $13, $b1, $57, $0e, $a7, $0e, $d3, $31, $53, $b1, $a6, $31, $03, $b2, $13, $0e
  .db $8d, $4d, $ae, $11, $bd, $41, $ee, $52, $0f, $a0, $dd, $47, $fd

;level D-1
L_GroundArea37:
  .db $52, $a1, $0f, $20, $6e, $65, $04, $a0, $14, $07, $24, $2d, $57, $25, $bc, $09
  .db $4c, $80, $6f, $33, $a5, $11, $a7, $63, $b7, $63, $e7, $20, $35, $a0, $59, $11
  .db $b4, $08, $c0, $04, $05, $82, $15, $02, $25, $02, $3a, $10, $4c, $01, $6c, $79
  .db $95, $79, $73, $a7, $8f, $74, $f3, $0a, $03, $a0, $93, $08, $97, $73, $e3, $20
  .db $39, $f1, $94, $07, $aa, $30, $bc, $5c, $c7, $30, $24, $f2, $27, $31, $8f, $33
  .db $c6, $10, $c7, $63, $d7, $63, $e7, $63, $f7, $63, $03, $a5, $07, $25, $aa, $10
  .db $03, $bf, $4f, $74, $6c, $00, $df, $74, $fc, $00, $5c, $81, $77, $73, $9d, $4c
  .db $c5, $30, $e3, $30, $7d, $c1, $bd, $4d, $bf, $26, $ad, $c7, $fd

;level D-2
L_GroundArea38:
  .db $55, $a1, $0f, $26, $9c, $01, $4f, $b6, $b3, $34, $c9, $3f, $13, $ba, $a3, $b3
  .db $bf, $74, $0c, $84, $83, $3f, $9f, $74, $ef, $72, $ec, $01, $2f, $f2, $2c, $01
  .db $6f, $72, $6c, $01, $a8, $91, $aa, $10, $03, $b7, $61, $79, $6f, $75, $39, $f1
  .db $db, $71, $03, $a2, $17, $22, $33, $09, $43, $20, $5b, $71, $48, $8f, $4a, $30
  .db $5c, $5c, $a3, $30, $2d, $c1, $5f, $26, $3d, $c7, $fd

;level D-3
L_GroundArea39:
  .db $55, $a1, $0f, $26, $39, $91, $68, $12, $a7, $12, $aa, $10, $c7, $07, $e8, $12
  .db $19, $91, $6c, $00, $78, $74, $0e, $c2, $76, $a8, $fe, $40, $29, $91, $73, $29
  .db $77, $53, $8c, $77, $59, $91, $87, $13, $b6, $14, $ba, $10, $e8, $12, $38, $92
  .db $19, $8f, $2c, $00, $33, $67, $4e, $42, $68, $0b, $2e, $c0, $38, $72, $a8, $11
  .db $aa, $10, $49, $91, $6e, $42, $de, $40, $e7, $22, $0e, $c2, $4e, $c0, $6c, $00
  .db $79, $11, $8c, $01, $a7, $13, $bc, $01, $d5, $15, $ec, $01, $03, $97, $0e, $00
  .db $6e, $01, $9d, $41, $ce, $42, $ff, $20, $9d, $c7, $fd

;ground level area used with level D-4
L_GroundArea40:
  .db $10, $21, $39, $f1, $09, $f1, $ad, $4c, $7c, $83, $96, $30, $5b, $f1, $c8, $05
  .db $1f, $b7, $93, $67, $a3, $67, $b3, $67, $bd, $4d, $cc, $08, $54, $fe, $6e, $2f
  .db $6d, $c7, $fd

;cloud level used with levels A-1, B-1 and D-2
L_GroundArea41:
  .db $00, $c1, $4c, $00, $02, $c9, $ba, $49, $62, $c9, $a4, $20, $a5, $20, $1a, $c9
  .db $a3, $2c, $b2, $49, $56, $c2, $6e, $00, $95, $41, $ad, $c7, $fd

;level 1-2
L_UndergroundArea1:
  .db $48, $0f, $0e, $01, $5e, $02, $0a, $b0, $1c, $54, $6a, $30, $7f, $34, $c6, $64
  .db $d6, $64, $e6, $64, $f6, $64, $fe, $00, $f0, $07, $00, $a1, $1e, $02, $47, $73
  .db $7e, $04, $84, $52, $94, $50, $95, $0b, $96, $50, $a4, $52, $ae, $05, $b8, $51
  .db $c8, $51, $ce, $01, $17, $f3, $45, $03, $52, $09, $62, $21, $6f, $34, $81, $21
  .db $9e, $02, $b6, $64, $c6, $64, $c0, $0c, $d6, $64, $d0, $07, $e6, $64, $e0, $0c
  .db $f0, $07, $fe, $0a, $0d, $06, $0e, $01, $4e, $04, $67, $73, $8e, $02, $b7, $0a
  .db $bc, $03, $c4, $72, $c7, $22, $08, $f2, $2c, $02, $59, $71, $7c, $01, $96, $74
  .db $bc, $01, $d8, $72, $fc, $01, $39, $f1, $4e, $01, $9e, $04, $a7, $52, $b7, $0b
  .db $b8, $51, $c7, $51, $d7, $50, $de, $02, $3a, $e0, $3e, $0a, $9e, $00, $08, $d4
  .db $18, $54, $28, $54, $48, $54, $6e, $06, $9e, $01, $a8, $52, $af, $47, $b8, $52
  .db $c8, $52, $d8, $52, $de, $0f, $4d, $c7, $ce, $01, $dc, $01, $f9, $79, $1c, $82
  .db $48, $72, $7f, $37, $f2, $68, $01, $e9, $11, $3a, $68, $7a, $de, $0f, $6d, $c5
  .db $fd

;warp zone area used by level 1-2
L_UndergroundArea2:
  .db $0b, $0f, $0e, $01, $9c, $71, $b7, $00, $be, $00, $3e, $81, $47, $73, $5e, $00
  .db $63, $42, $8e, $01, $a7, $73, $be, $00, $7e, $81, $88, $72, $f0, $59, $fe, $00
  .db $00, $d9, $0e, $01, $39, $79, $a7, $03, $ae, $00, $b4, $03, $de, $0f, $0d, $05
  .db $0e, $02, $68, $7a, $be, $01, $de, $0f, $6d, $c5, $fd

;underground bonus rooms used with worlds 1-4
L_UndergroundArea3:
  .db $08, $8f, $0e, $01, $17, $05, $2e, $02, $30, $07, $37, $03, $3a, $49, $44, $03
  .db $58, $47, $df, $4a, $6d, $c7, $0e, $81, $00, $5a, $2e, $02, $87, $52, $97, $2f
  .db $99, $4f, $0a, $90, $93, $56, $a3, $0b, $a7, $50, $b3, $55, $df, $4a, $6d, $c7
  .db $0e, $81, $00, $5a, $2e, $00, $3e, $02, $41, $56, $57, $25, $56, $45, $68, $51
  .db $7a, $43, $b7, $0b, $b8, $51, $df, $4a, $6d, $c7, $fd

;level 5-2
L_UndergroundArea4:
  .db $48, $0f, $1e, $01, $27, $06, $5e, $02, $8f, $63, $8c, $01, $ef, $67, $1c, $81
  .db $2e, $09, $3c, $63, $73, $01, $8c, $60, $fe, $02, $1e, $8e, $3e, $02, $44, $07
  .db $45, $52, $4e, $0e, $8e, $02, $99, $71, $b5, $24, $b6, $24, $b7, $24, $fe, $02
  .db $07, $87, $17, $22, $37, $52, $37, $0b, $47, $52, $4e, $0a, $57, $52, $5e, $02
  .db $67, $52, $77, $52, $7e, $0a, $87, $52, $8e, $02, $96, $46, $97, $52, $a7, $52
  .db $b7, $52, $c7, $52, $d7, $52, $e7, $52, $f7, $52, $fe, $04, $07, $a3, $47, $08
  .db $57, $26, $c7, $0a, $e9, $71, $17, $a7, $97, $08, $9e, $01, $a0, $24, $c6, $74
  .db $f0, $0c, $fe, $04, $0c, $80, $6f, $32, $98, $62, $a8, $62, $bc, $00, $c7, $73
  .db $e7, $73, $fe, $02, $7f, $e7, $8e, $01, $9e, $00, $de, $02, $f7, $0b, $fe, $0e
  .db $4e, $82, $54, $52, $64, $51, $6e, $00, $74, $09, $9f, $00, $df, $00, $2f, $80
  .db $4e, $02, $59, $47, $ce, $0a, $07, $f5, $68, $54, $7f, $64, $88, $54, $a8, $54
  .db $ae, $01, $b8, $52, $bf, $47, $c8, $52, $d8, $52, $e8, $52, $ee, $0f, $4d, $c7
  .db $0d, $0d, $0e, $02, $68, $7a, $be, $01, $ee, $0f, $6d, $c5, $fd

;underground bonus rooms used with worlds 5-8
L_UndergroundArea5:
  .db $08, $0f, $0e, $01, $2e, $05, $38, $2c, $3a, $4f, $08, $ac, $c7, $0b, $ce, $01
  .db $df, $4a, $6d, $c7, $0e, $81, $00, $5a, $2e, $02, $b8, $4f, $cf, $65, $0f, $e5
  .db $4f, $65, $8f, $65, $df, $4a, $6d, $c7, $0e, $81, $00, $5a, $30, $07, $34, $52
  .db $3e, $02, $42, $47, $44, $47, $46, $27, $c0, $0b, $c4, $52, $df, $4a, $6d, $c7
  .db $fd

;level A-2
L_UndergroundArea6:
  .db $48, $8f, $1e, $01, $4e, $02, $00, $8c, $09, $0f, $6e, $0a, $ee, $82, $2e, $80
  .db $30, $20, $7e, $01, $87, $27, $07, $87, $17, $23, $3e, $00, $9e, $05, $5b, $f1
  .db $8b, $71, $bb, $71, $eb, $71, $3e, $82, $7f, $38, $fe, $0a, $3e, $84, $47, $29
  .db $48, $2e, $af, $71, $cb, $71, $e7, $0a, $f7, $23, $2b, $f1, $37, $51, $3e, $00
  .db $6f, $00, $8e, $04, $df, $32, $9c, $82, $ca, $12, $dc, $00, $e8, $14, $fc, $00
  .db $fe, $08, $4e, $8a, $88, $74, $9e, $01, $a8, $52, $bf, $47, $b8, $52, $c8, $52
  .db $d8, $52, $e8, $52, $ee, $0f, $4d, $c7, $0d, $0d, $0e, $02, $68, $7a, $be, $01
  .db $ee, $0f, $6d, $c5, $fd

;underground bonus rooms used with worlds A-D
L_UndergroundArea7:
  .db $08, $0f, $0e, $01, $2e, $05, $38, $20, $3e, $04, $48, $07, $55, $45, $57, $45
  .db $58, $25, $b8, $08, $be, $05, $c8, $20, $ce, $01, $df, $4a, $6d, $c7, $0e, $81
  .db $00, $5a, $2e, $02, $34, $42, $36, $42, $37, $22, $73, $54, $83, $0b, $87, $20
  .db $93, $54, $90, $07, $b4, $41, $b6, $41, $b7, $21, $df, $4a, $6d, $c7, $0e, $81
  .db $00, $5a, $14, $56, $24, $56, $2e, $0c, $33, $43, $6e, $09, $8e, $0b, $96, $48
  .db $1e, $84, $3e, $05, $4a, $48, $47, $0b, $ce, $01, $df, $4a, $6d, $c7, $fd

;level 3-2
L_WaterArea1:
  .db $41, $01, $03, $b4, $04, $34, $05, $34, $5c, $02, $83, $37, $84, $37, $85, $37
  .db $09, $c2, $0c, $02, $1d, $49, $fa, $60, $09, $e1, $18, $62, $20, $63, $27, $63
  .db $33, $37, $37, $63, $47, $63, $5c, $05, $79, $43, $fe, $06, $35, $d2, $46, $48
  .db $91, $53, $d6, $51, $fe, $01, $0c, $83, $6c, $04, $b4, $62, $c4, $62, $d4, $62
  .db $e4, $62, $f4, $62, $18, $d2, $79, $51, $f4, $66, $fe, $02, $0c, $8a, $1d, $49
  .db $31, $55, $56, $41, $77, $41, $98, $41, $c5, $55, $fe, $01, $07, $e3, $17, $63
  .db $27, $63, $37, $63, $47, $63, $57, $63, $67, $63, $78, $62, $89, $61, $9a, $60
  .db $bc, $07, $ca, $42, $3a, $b3, $46, $53, $63, $34, $66, $44, $7c, $01, $9a, $33
  .db $b7, $52, $dc, $01, $fa, $32, $05, $d4, $2c, $0d, $43, $37, $47, $35, $b7, $30
  .db $c3, $64, $23, $e4, $29, $45, $33, $64, $43, $64, $53, $64, $63, $64, $73, $64
  .db $9a, $60, $a9, $61, $b8, $62, $be, $0b, $d4, $31, $d5, $0d, $de, $0f, $0d, $ca
  .db $7d, $47, $fd

;level 6-2
L_WaterArea2:
  .db $41, $01, $27, $d3, $79, $51, $c4, $56, $00, $e2, $03, $53, $0c, $0f, $12, $3b
  .db $1a, $42, $43, $54, $6d, $49, $83, $53, $99, $53, $c3, $54, $da, $52, $0c, $84
  .db $09, $53, $53, $64, $63, $31, $67, $34, $86, $41, $8c, $01, $a3, $30, $b3, $64
  .db $cc, $03, $d9, $42, $5c, $84, $a0, $62, $a8, $62, $b0, $62, $b8, $62, $c0, $62
  .db $c8, $62, $d0, $62, $d8, $62, $e0, $62, $e8, $62, $16, $c2, $58, $52, $8c, $04
  .db $a7, $55, $d0, $63, $d7, $65, $e2, $61, $e7, $65, $f2, $61, $f7, $65, $13, $b8
  .db $17, $38, $8c, $03, $1d, $c9, $50, $62, $5c, $0b, $62, $3e, $63, $52, $8a, $52
  .db $93, $54, $aa, $42, $d3, $51, $ea, $41, $03, $d3, $1c, $04, $1a, $52, $33, $55
  .db $73, $44, $77, $44, $16, $d2, $19, $31, $1a, $32, $5c, $0f, $9a, $47, $95, $64
  .db $a5, $64, $b5, $64, $c5, $64, $d5, $64, $e5, $64, $f5, $64, $05, $e4, $40, $61
  .db $42, $35, $56, $34, $5c, $09, $a2, $61, $a6, $61, $b3, $34, $b7, $34, $fc, $08
  .db $0c, $87, $28, $54, $59, $53, $9a, $30, $a9, $61, $b8, $62, $be, $0b, $d4, $60
  .db $d5, $0d, $de, $0f, $0d, $ca, $7d, $47, $fd

;water area used by level 4-1
L_WaterArea3:
  .db $01, $01, $78, $52, $b5, $55, $da, $60, $e9, $61, $f8, $62, $fe, $0b, $fe, $81
  .db $0a, $cf, $36, $49, $62, $43, $fe, $07, $36, $c9, $fe, $01, $0c, $84, $65, $55
  .db $97, $52, $9a, $32, $a9, $31, $b8, $30, $c7, $63, $ce, $0f, $d5, $0d, $7d, $c7
  .db $fd

;water area used in level 8-4
L_WaterArea4:
  .db $07, $0f, $0e, $02, $39, $73, $05, $8e, $2e, $0b, $b7, $0e, $64, $8e, $6e, $02
  .db $ce, $06, $de, $0f, $e6, $0d, $7d, $c7, $fd

;water area used in level 6-1
L_WaterArea5:
  .db $01, $01, $77, $39, $a3, $43, $00, $bf, $29, $51, $39, $48, $61, $55, $d6, $54
  .db $d2, $44, $0c, $82, $2e, $02, $31, $66, $44, $47, $47, $32, $4a, $47, $97, $32
  .db $c1, $66, $ce, $01, $dc, $02, $fe, $0e, $0c, $8f, $08, $4f, $fe, $01, $27, $d3
  .db $5c, $02, $9a, $60, $a9, $61, $b8, $62, $c7, $63, $ce, $0f, $d5, $0d, $7d, $c7
  .db $fd

;level 9-1 water area
L_WaterArea6:
    .db $00, $a1, $0a, $60, $19, $61, $28, $62, $39, $71, $58, $62, $69, $61, $7a, $60
    .db $7c, $f5, $a5, $11, $fe, $20, $1f, $80, $5e, $21, $80, $3f, $8f, $65, $d6, $74
    .db $5e, $a0, $6f, $66, $9e, $21, $c3, $37, $47, $f3, $9e, $20, $fe, $21, $0d, $06
    .db $57, $32, $64, $11, $66, $10, $83, $a7, $87, $27, $0d, $09, $1d, $4a, $5f, $38
    .db $6d, $c1, $af, $26, $6d, $c7, $fd

;level 9-2
L_WaterArea7:
    .db $50, $11, $d7, $73, $fe, $1a, $6f, $e2, $1f, $e5, $bf, $63, $c7, $a8, $df, $61
    .db $15, $f1, $7f, $62, $9b, $2f, $a8, $72, $fe, $10, $69, $f1, $b7, $25, $c5, $71
    .db $33, $ac, $5f, $71, $8d, $4a, $aa, $14, $d1, $71, $17, $95, $26, $42, $72, $42
    .db $73, $12, $7a, $14, $c6, $14, $d5, $42, $fe, $11, $7f, $b8, $8d, $c1, $cf, $26
    .db $6d, $c7, $fd

;level 9-4
L_WaterArea8:
    .db $57, $00, $0b, $3f, $0b, $bf, $0b, $bf, $73, $36, $9a, $30, $a5, $64, $b6, $31
    .db $d4, $61, $0b, $bf, $13, $63, $4a, $60, $53, $66, $a5, $34, $b3, $67, $e5, $65
    .db $f4, $60, $0b, $bf, $14, $60, $53, $67, $67, $32, $c4, $62, $d4, $31, $f3, $61
    .db $fa, $60, $0b, $bf, $04, $30, $09, $61, $14, $65, $63, $65, $6a, $60, $0b, $bf
    .db $0f, $38, $0b, $bf, $1d, $41, $3e, $42, $5f, $20, $ce, $40, $0b, $bf, $3d, $47
    .db $fd

;level B-2
L_WaterArea9:
  .db $41, $01, $da, $60, $e9, $61, $f8, $62, $fe, $0b, $fe, $81, $47, $d3, $8a, $60
  .db $99, $61, $a8, $62, $b7, $63, $c6, $64, $d5, $65, $e4, $66, $ed, $49, $f3, $67
  .db $1a, $cb, $e3, $67, $f3, $67, $fe, $02, $31, $d6, $3c, $02, $77, $53, $ac, $02
  .db $b1, $56, $e7, $53, $fe, $01, $77, $b9, $a3, $43, $00, $bf, $29, $51, $39, $48
  .db $61, $55, $d2, $44, $d6, $54, $0c, $82, $2e, $02, $31, $66, $44, $47, $47, $32
  .db $4a, $47, $97, $32, $c1, $66, $ce, $01, $dc, $02, $fe, $0e, $0c, $8f, $08, $4f
  .db $fe, $02, $75, $e0, $fe, $01, $0c, $87, $9a, $60, $a9, $61, $b8, $62, $c7, $63
  .db $ce, $0f, $d5, $0d, $6d, $ca, $7d, $47, $fd

;-------------------------------------------------------------------------------------
