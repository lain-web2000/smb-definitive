.reloc
;======================================================================================================================
; CONFIGURATION
;
; There are 2 main ways of configuring the engine. 
;
;   1) The simplest way is right here, in the section below. Simply comment/uncomment these defines, and move on 
;      with your life.
;
;   2) The second way is "externally", using definitions coming from elsewhere in your app or the command line. If you
;      wish do so, simply define FAMISTUDIO_CFG_EXTERNAL=1 and this whole section will be ignored. You are then 
;      responsible for providing all configuration. This is useful if you have multiple projects that needs 
;      different configurations, while pointing to the same code file. This is how the provided demos and FamiStudio
;      uses it.
;
; Note that unless specified, the engine uses "if" and not "ifdef" for all boolean values so you need to define these
; to non-zero values. Undefined values will be assumed to be zero.
;
; There are 4 main things to configure, each of them will be detailed below.
;
;   1) Segments (ZP/RAM/PRG)
;   2) Audio expansion
;   3) Global engine parameters
;   4) Supported features
;======================================================================================================================

.ifndef FAMISTUDIO_CFG_EXTERNAL 
    FAMISTUDIO_CFG_EXTERNAL = 0
.endif

; Set this to configure the sound engine from outside (in your app, or from the command line)
.if !FAMISTUDIO_CFG_EXTERNAL

;======================================================================================================================
; 1) SEGMENT CONFIGURATION
;
; You need to tell where you want to allocate the zeropage, RAM and code. This section will be slightly different for
; each assembler.
;
; For CA65, you need to specify the name of your ZEROPAGE, RAM/BSS and CODE/PRG segments as c-style macros (.define)
; like the example below.
;======================================================================================================================

.define FAMISTUDIO_CA65_ZP_SEGMENT   SOUND_ZP
.define FAMISTUDIO_CA65_RAM_SEGMENT  SOUND_RAM
.define FAMISTUDIO_CA65_CODE_SEGMENT LOADER

;======================================================================================================================
; 2) AUDIO EXPANSION CONFIGURATION
;
; You can enable up to one audio expansion (FAMISTUDIO_EXP_XXX). Enabling more than one expansion will lead to
; undefined behavior. Memory usage goes up as more complex expansions are used. The audio expansion you choose
; **MUST MATCH** with the data you will load in the engine. Loading a FDS song while enabling VRC6 will lead to
; undefined behavior.
;======================================================================================================================

; Konami VRC6 (2 extra square + saw)
; FAMISTUDIO_EXP_VRC6          = 0

; Rainbow-Net (homebrew clone of VRC6)
; FAMISTUDIO_EXP_RAINBOW       = 0

; Konami VRC7 (6 FM channels)
; FAMISTUDIO_EXP_VRC7          = 0 

; Nintendo MMC5 (2 extra squares, extra DPCM not supported)
; FAMISTUDIO_EXP_MMC5          = 0 

; Sunsoft S5B (2 extra squares, advanced features not supported.)
FAMISTUDIO_EXP_S5B           = 1 

; Famicom Disk System (extra wavetable channel)
; FAMISTUDIO_EXP_FDS           = 0 

; Namco 163 (between 1 and 8 extra wavetable channels) + number of channels.
; FAMISTUDIO_EXP_N163          = 0
; FAMISTUDIO_EXP_N163_CHN_CNT  = 0

; EPSM (Expansion Port Sound Module)
; FAMISTUDIO_EXP_EPSM          = 0
; Fine-tune control for enabling specific channels
; Default values for the channels are to enable all channels.
; FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT     = 3
; FAMISTUDIO_EXP_EPSM_FM_CHN_CNT      = 6
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN1_ENABLE = 0
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN2_ENABLE = 0
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN3_ENABLE = 0
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN4_ENABLE = 0
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN5_ENABLE = 0
; FAMISTUDIO_EXP_EPSM_RHYTHM_CHN6_ENABLE = 0

;======================================================================================================================
; 3) GLOBAL ENGINE CONFIGURATION
;
; These are parameters that configures the engine, but are independent of the data you will be importing, such as
; which platform (PAL/NTSC) you want to support playback for, whether SFX are enabled or not, etc. They all have the
; form FAMISTUDIO_CFG_XXX.
;======================================================================================================================

; One of these MUST be defined (PAL or NTSC playback). Note that only NTSC support is supported when using any of the audio expansions.
; FAMISTUDIO_CFG_PAL_SUPPORT   = 1
FAMISTUDIO_CFG_NTSC_SUPPORT  = 1

; Support for sound effects playback + number of SFX that can play at once.
FAMISTUDIO_CFG_SFX_SUPPORT   = 1
FAMISTUDIO_CFG_SFX_STREAMS   = 1

; Blaarg's smooth vibrato technique. Eliminates phase resets ("pops") on square channels. 
; FAMISTUDIO_CFG_SMOOTH_VIBRATO = 1

; Enables DPCM playback support.
; FAMISTUDIO_CFG_DPCM_SUPPORT   = 0

; Must be enabled if you are calling sound effects from a different thread than the sound engine update.
; FAMISTUDIO_CFG_THREAD         = 0

;======================================================================================================================
; 4) SUPPORTED FEATURES CONFIGURATION
;
; Every feature supported in FamiStudio is supported by this sound engine. If you know for sure that you are not using
; specific features in your music, you can disable them to save memory/processing time. Using a feature in your song
; and failing to enable it will likely lead to crashes (BRK), or undefined behavior. They all have the form
; FAMISTUDIO_USE_XXX.
;======================================================================================================================

; Must be enabled if the songs you will be importing have been created using FamiTracker tempo mode. If you are using
; FamiStudio tempo mode, this must be undefined. You cannot mix and match tempo modes, the engine can only run in one
; mode or the other. 
; More information at: https://famistudio.org/doc/song/#tempo-modes
FAMISTUDIO_USE_FAMITRACKER_TEMPO = 1

; Must be enabled if the songs uses delayed notes or delayed cuts. This is obviously only available when using
; FamiTracker tempo mode as FamiStudio tempo mode does not need this.
; FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS = 1

; Must be enabled if the songs uses release notes. 
; More information at: https://famistudio.org/doc/pianoroll/#release-point
; FAMISTUDIO_USE_RELEASE_NOTES = 1

; Must be enabled if any song uses the volume track. The volume track allows manipulating the volume at the track level
; independently from instruments.
; More information at: https://famistudio.org/doc/pianoroll/#editing-volume-tracks-effects
FAMISTUDIO_USE_VOLUME_TRACK      = 1

; Must be enabled if any song uses slides on the volume track. Volume track must be enabled too.
; More information at: https://famistudio.org/doc/pianoroll/#editing-volume-tracks-effects
FAMISTUDIO_USE_VOLUME_SLIDES     = 1

; Must be enabled if any song uses the pitch track. The pitch track allows manipulating the pitch at the track level
; independently from instruments.
; More information at: https://famistudio.org/doc/pianoroll/#pitch
FAMISTUDIO_USE_PITCH_TRACK       = 1

; Must be enabled if any song uses slide notes. Slide notes allows portamento and slide effects.
; More information at: https://famistudio.org/doc/pianoroll/#slide-notes
; FAMISTUDIO_USE_SLIDE_NOTES       = 1

; Must be enabled if any song uses slide notes on the noise channel too. 
; More information at: https://famistudio.org/doc/pianoroll/#slide-notes
; FAMISTUDIO_USE_NOISE_SLIDE_NOTES = 1

; Must be enabled if any song uses the vibrato speed/depth effect track. 
; More information at: https://famistudio.org/doc/pianoroll/#vibrato-depth-speed
FAMISTUDIO_USE_VIBRATO           = 1

; Must be enabled if any song uses arpeggios (not to be confused with instrument arpeggio envelopes, those are always
; supported).
; More information at: (TODO)
; FAMISTUDIO_USE_ARPEGGIO          = 1

; Must be enabled if any song uses the "Duty Cycle" effect (equivalent of FamiTracker Vxx, also called "Timbre").  
; FAMISTUDIO_USE_DUTYCYCLE_EFFECT  = 1

; Must be enabled if any song uses the DPCM delta counter. Only makes sense if DPCM samples
; are enabled (FAMISTUDIO_CFG_DPCM_SUPPORT).
; More information at: (TODO)
; FAMISTUDIO_USE_DELTA_COUNTER     = 1

; Must be enabled if your project uses more than 1 bank of DPCM samples.
; When using this, you must implement the "famistudio_dpcm_bank_callback" callback 
; and switch to the correct bank every time a sample is played.
; FAMISTUDIO_USE_DPCM_BANKSWITCHING = 1

; Must be enabled if your project uses more than 63 unique DPCM mappings (a mapping is DPCM sample
; assigned to a note, with a specific pitch/loop, etc.). Implied when using FAMISTUDIO_USE_DPCM_BANKSWITCHING.
; FAMISTUDIO_USE_DPCM_EXTENDED_RANGE = 1

; Allows having up to 256 instrument at the cost of slightly higher CPU usage when switching instrument.
; When this is off, the limit is 64 for regular instruments and 32 for expansion instrumnets.
; FAMISTUDIO_USE_INSTRUMENT_EXTENDED_RANGE = 1

; Must be enabled if your project uses the "Phase Reset" effect.
; FAMISTUDIO_USE_PHASE_RESET = 1

; Must be enabled if your project uses the FDS expansion and at least one instrument with FDS Auto-Mod enabled.
; FAMISTUDIO_USE_FDS_AUTOMOD  = 1

.endif

; Memory location of the DPCM samples. Must be between $c000 and $ffc0, and a multiple of 64.
.ifndef FAMISTUDIO_DPCM_OFF
    FAMISTUDIO_DPCM_OFF = $c000
.endif

;======================================================================================================================
; END OF CONFIGURATION
;
; Ideally, you should not have to change anything below this line.
;======================================================================================================================

;======================================================================================================================
; INTERNAL DEFINES (Do not touch)
;======================================================================================================================

.ifndef FAMISTUDIO_EXP_RAINBOW
    FAMISTUDIO_EXP_RAINBOW = 0
.endif

.if FAMISTUDIO_EXP_RAINBOW
    FAMISTUDIO_EXP_VRC6 = 1
.endif

.ifndef FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_EXP_VRC6 = 0
.endif

.ifndef FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_EXP_VRC7 = 0
.endif

.ifndef FAMISTUDIO_EXP_EPSM
    FAMISTUDIO_EXP_EPSM = 0
    FAMISTUDIO_EXP_EPSM_ENV_CNT = 0
    FAMISTUDIO_EXP_EPSM_RHYTHM_CNT = 0
    FAMISTUDIO_EXP_EPSM_FM_CHN_CNT = 0
    FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT = 0
    FAMISTUDIO_EXP_EPSM_TRIG_CHN = 0
.else
    .ifndef FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT
        FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT     = 3
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
        FAMISTUDIO_EXP_EPSM_FM_CHN_CNT      = 6
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN1_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN1_ENABLE = 1
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN2_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN2_ENABLE = 1
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN3_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN3_ENABLE = 1
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN4_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN4_ENABLE = 1
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN5_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN5_ENABLE = 1
    .endif
    .ifndef FAMISTUDIO_EXP_EPSM_RHYTHM_CHN6_ENABLE
        FAMISTUDIO_EXP_EPSM_RHYTHM_CHN6_ENABLE = 1
    .endif
.endif

.ifndef FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_EXP_MMC5 = 0
.endif

.ifndef FAMISTUDIO_EXP_S5B
    FAMISTUDIO_EXP_S5B = 0
.endif

.ifndef FAMISTUDIO_EXP_FDS
    FAMISTUDIO_EXP_FDS = 0
.endif

.ifndef FAMISTUDIO_EXP_N163
    FAMISTUDIO_EXP_N163 = 0
.endif

.ifndef FAMISTUDIO_EXP_N163_CHN_CNT
    FAMISTUDIO_EXP_N163_CHN_CNT = 1
.endif

.ifndef FAMISTUDIO_CFG_PAL_SUPPORT
    FAMISTUDIO_CFG_PAL_SUPPORT = 0
.endif

.ifndef FAMISTUDIO_CFG_NTSC_SUPPORT
    .if FAMISTUDIO_CFG_PAL_SUPPORT
        FAMISTUDIO_CFG_NTSC_SUPPORT = 0
    .else
        FAMISTUDIO_CFG_NTSC_SUPPORT = 1
    .endif
.endif

.if FAMISTUDIO_CFG_NTSC_SUPPORT && FAMISTUDIO_CFG_PAL_SUPPORT
    FAMISTUDIO_DUAL_SUPPORT = 1
.else
    FAMISTUDIO_DUAL_SUPPORT = 0
.endif

.ifndef FAMISTUDIO_CFG_SFX_SUPPORT
    FAMISTUDIO_CFG_SFX_SUPPORT = 0
    FAMISTUDIO_CFG_SFX_STREAMS = 0
.endif

.ifndef FAMISTUDIO_CFG_SFX_STREAMS
    FAMISTUDIO_CFG_SFX_STREAMS = 1
.endif

.ifndef FAMISTUDIO_CFG_SMOOTH_VIBRATO
    FAMISTUDIO_CFG_SMOOTH_VIBRATO = 0
.endif

.ifndef FAMISTUDIO_CFG_DPCM_SUPPORT
    FAMISTUDIO_CFG_DPCM_SUPPORT = 0
.endif

.ifndef FAMISTUDIO_CFG_EQUALIZER
    FAMISTUDIO_CFG_EQUALIZER = 0
.endif

.ifndef FAMISTUDIO_USE_FAMITRACKER_TEMPO
    FAMISTUDIO_USE_FAMITRACKER_TEMPO = 0
.endif

.ifndef FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS
    FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS = 0
.endif

.ifndef FAMISTUDIO_USE_VOLUME_TRACK
    FAMISTUDIO_USE_VOLUME_TRACK = 0
.endif

.ifndef FAMISTUDIO_USE_VOLUME_SLIDES
    FAMISTUDIO_USE_VOLUME_SLIDES = 0
.endif

.ifndef FAMISTUDIO_USE_PITCH_TRACK
    FAMISTUDIO_USE_PITCH_TRACK = 0
.endif

.ifndef FAMISTUDIO_USE_SLIDE_NOTES
    FAMISTUDIO_USE_SLIDE_NOTES = 0
.endif

.ifndef FAMISTUDIO_USE_NOISE_SLIDE_NOTES
    FAMISTUDIO_USE_NOISE_SLIDE_NOTES = 0
.endif

.ifndef FAMISTUDIO_USE_VIBRATO
    FAMISTUDIO_USE_VIBRATO = 0
.endif

.ifndef FAMISTUDIO_USE_ARPEGGIO
    FAMISTUDIO_USE_ARPEGGIO = 0
.endif

.ifndef FAMISTUDIO_USE_DUTYCYCLE_EFFECT
    FAMISTUDIO_USE_DUTYCYCLE_EFFECT = 0
.endif

.ifndef FAMISTUDIO_USE_DELTA_COUNTER
    FAMISTUDIO_USE_DELTA_COUNTER = 0
.endif

.ifndef FAMISTUDIO_USE_PHASE_RESET
    FAMISTUDIO_USE_PHASE_RESET = 0
.endif

.ifndef FAMISTUDIO_USE_FDS_AUTOMOD
    FAMISTUDIO_USE_FDS_AUTOMOD = 0
.endif

.ifndef FAMISTUDIO_USE_RELEASE_NOTES
    FAMISTUDIO_USE_RELEASE_NOTES = 0    
.endif

.ifndef FAMISTUDIO_USE_DPCM_EXTENDED_RANGE
    FAMISTUDIO_USE_DPCM_EXTENDED_RANGE = 0
.endif

.ifndef FAMISTUDIO_USE_INSTRUMENT_EXTENDED_RANGE
    FAMISTUDIO_USE_INSTRUMENT_EXTENDED_RANGE = 0
.endif

.ifndef FAMISTUDIO_USE_DPCM_BANKSWITCHING
    FAMISTUDIO_USE_DPCM_BANKSWITCHING = 0
.endif

.ifndef FAMISTUDIO_CFG_THREAD
    FAMISTUDIO_CFG_THREAD = 0
.endif

.if (FAMISTUDIO_EXP_VRC6 + FAMISTUDIO_EXP_VRC7 + FAMISTUDIO_EXP_EPSM + FAMISTUDIO_EXP_MMC5 + FAMISTUDIO_EXP_S5B + FAMISTUDIO_EXP_FDS + FAMISTUDIO_EXP_N163) = 0
    FAMISTUDIO_EXP_NONE = 1
.else
    FAMISTUDIO_EXP_NONE = 0
.endif

.if (FAMISTUDIO_EXP_VRC7 + FAMISTUDIO_EXP_EPSM + FAMISTUDIO_EXP_N163 + FAMISTUDIO_EXP_FDS + FAMISTUDIO_EXP_S5B)
    FAMISTUDIO_EXP_NOTE_START = 5
.endif
.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_EXP_NOTE_START = 7
.endif

.if FAMISTUDIO_USE_NOISE_SLIDE_NOTES && (FAMISTUDIO_USE_SLIDE_NOTES = 0)
    .error "Noise slide notes can only be used when regular slide notes are enabled too."
.endif

.if FAMISTUDIO_USE_VOLUME_SLIDES && (FAMISTUDIO_USE_VOLUME_TRACK = 0)
    .error "Volume slides can only be used when the volume track is enabled too."
.endif

.if FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS && (FAMISTUDIO_USE_FAMITRACKER_TEMPO = 0)
    .error "Delayed notes or cuts only make sense when using FamiTracker tempo."
.endif

.if (FAMISTUDIO_EXP_VRC6 + FAMISTUDIO_EXP_VRC7 + FAMISTUDIO_EXP_EPSM + FAMISTUDIO_EXP_MMC5 + FAMISTUDIO_EXP_S5B + FAMISTUDIO_EXP_FDS + FAMISTUDIO_EXP_N163) > 1
    .error "Only one audio expansion can be enabled."
.endif

.if FAMISTUDIO_EXP_N163 && ((FAMISTUDIO_EXP_N163_CHN_CNT < 1) || (FAMISTUDIO_EXP_N163_CHN_CNT > 8))
    .error "N163 only supports between 1 and 8 channels."
.endif

.if FAMISTUDIO_USE_DELTA_COUNTER && (FAMISTUDIO_CFG_DPCM_SUPPORT = 0)
    .error "Delta counter only makes sense if DPCM samples are enabled."
.endif

.if FAMISTUDIO_USE_DPCM_BANKSWITCHING && (FAMISTUDIO_CFG_DPCM_SUPPORT = 0)
    .error "DPCM bankswitching only makes sense if DPCM samples are enabled."
.endif

; This is the best way i found to test if a C-style macro is defined or not... 
.if .xmatch(.string(FAMISTUDIO_CA65_ZP_SEGMENT), "FAMISTUDIO_CA65_ZP_SEGMENT")
    .error "You must .define FAMISTUDIO_CA65_ZP_SEGMENT with the name of your zeropage segment."
.endif

.if .xmatch(.string(FAMISTUDIO_CA65_RAM_SEGMENT), "FAMISTUDIO_CA65_RAM_SEGMENT")
    .error "You must .define FAMISTUDIO_CA65_RAM_SEGMENT with the name of your RAM/BSS segment."
.endif

.if .xmatch(.string(FAMISTUDIO_CA65_CODE_SEGMENT), "FAMISTUDIO_CA65_CODE_SEGMENT")
    .error "You must .define FAMISTUDIO_CA65_CODE_SEGMENT with the name of your CODE/PRG segment."
.endif

FAMISTUDIO_DPCM_PTR = (FAMISTUDIO_DPCM_OFF & $3fff) >> 6

.if FAMISTUDIO_EXP_NONE
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 3
    FAMISTUDIO_NUM_CHANNELS         = 5
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3   
.endif
.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+3+3+3
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 6
    FAMISTUDIO_NUM_CHANNELS         = 8
    FAMISTUDIO_NUM_DUTY_CYCLES      = 6
.endif
.if FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+2+2+2+2+2+2
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 9
    FAMISTUDIO_NUM_CHANNELS         = 11
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3
.endif
.if FAMISTUDIO_EXP_EPSM
    FAMISTUDIO_EXP_EPSM_RHYTHM_CNT  = FAMISTUDIO_EXP_EPSM_RHYTHM_CHN1_ENABLE + FAMISTUDIO_EXP_EPSM_RHYTHM_CHN2_ENABLE + FAMISTUDIO_EXP_EPSM_RHYTHM_CHN3_ENABLE + FAMISTUDIO_EXP_EPSM_RHYTHM_CHN4_ENABLE + FAMISTUDIO_EXP_EPSM_RHYTHM_CHN5_ENABLE + FAMISTUDIO_EXP_EPSM_RHYTHM_CHN6_ENABLE
    FAMISTUDIO_EXP_EPSM_ENV_CNT     = FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT + FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
    FAMISTUDIO_EXP_EPSM_CHANNELS    = FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT + FAMISTUDIO_EXP_EPSM_FM_CHN_CNT + FAMISTUDIO_EXP_EPSM_RHYTHM_CNT
    FAMISTUDIO_EXP_EPSM_TRIG_CHN    = FAMISTUDIO_EXP_EPSM_FM_CHN_CNT + FAMISTUDIO_EXP_EPSM_RHYTHM_CNT

    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+(FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT * 4) + (FAMISTUDIO_EXP_EPSM_FM_CHN_CNT * 2)
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 3 + FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT + FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
    FAMISTUDIO_NUM_CHANNELS         = 5 + FAMISTUDIO_EXP_EPSM_CHANNELS
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3
.endif
.if FAMISTUDIO_EXP_FDS
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+3
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 4
    FAMISTUDIO_NUM_CHANNELS         = 6
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3   
.endif
.if FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+3+3
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 5
    FAMISTUDIO_NUM_CHANNELS         = 7
    FAMISTUDIO_NUM_DUTY_CYCLES      = 5   
.endif
.if FAMISTUDIO_EXP_N163
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+(FAMISTUDIO_EXP_N163_CHN_CNT*3)
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 3+FAMISTUDIO_EXP_N163_CHN_CNT
    FAMISTUDIO_NUM_CHANNELS         = 5+FAMISTUDIO_EXP_N163_CHN_CNT
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3   
.endif
.if FAMISTUDIO_EXP_S5B
    FAMISTUDIO_NUM_ENVELOPES        = 3+3+2+3+4+4+4
    FAMISTUDIO_NUM_PITCH_ENVELOPES  = 6
    FAMISTUDIO_NUM_CHANNELS         = 8
    FAMISTUDIO_NUM_DUTY_CYCLES      = 3
.endif

.if FAMISTUDIO_EXP_NONE
    FAMISTUDIO_NUM_VOLUME_SLIDES = 4
.else
    FAMISTUDIO_NUM_VOLUME_SLIDES = FAMISTUDIO_NUM_CHANNELS ; DPCM volume is unused.
.endif

.if FAMISTUDIO_USE_NOISE_SLIDE_NOTES
    FAMISTUDIO_NUM_SLIDES = FAMISTUDIO_NUM_PITCH_ENVELOPES + 1
.else
    FAMISTUDIO_NUM_SLIDES = FAMISTUDIO_NUM_PITCH_ENVELOPES
.endif

; Keep the noise slide at the end so the pitch envelopes/slides are in sync.
FAMISTUDIO_NOISE_SLIDE_INDEX = FAMISTUDIO_NUM_SLIDES - 1

.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_VRC6_CH0_PITCH_ENV_IDX = 3
    FAMISTUDIO_VRC6_CH1_PITCH_ENV_IDX = 4
    FAMISTUDIO_VRC6_CH2_PITCH_ENV_IDX = 5
.endif
.if FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_VRC7_CH0_PITCH_ENV_IDX = 3
    FAMISTUDIO_VRC7_CH1_PITCH_ENV_IDX = 4
    FAMISTUDIO_VRC7_CH2_PITCH_ENV_IDX = 5
    FAMISTUDIO_VRC7_CH3_PITCH_ENV_IDX = 6
    FAMISTUDIO_VRC7_CH4_PITCH_ENV_IDX = 7
    FAMISTUDIO_VRC7_CH5_PITCH_ENV_IDX = 8
.endif
.if FAMISTUDIO_EXP_FDS
    FAMISTUDIO_FDS_CH0_PITCH_ENV_IDX  = 3
.endif
.if FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_MMC5_CH0_PITCH_ENV_IDX = 3
    FAMISTUDIO_MMC5_CH1_PITCH_ENV_IDX = 4  
.endif
.if FAMISTUDIO_EXP_N163
    FAMISTUDIO_N163_CH0_PITCH_ENV_IDX = 3
    FAMISTUDIO_N163_CH1_PITCH_ENV_IDX = 4
    FAMISTUDIO_N163_CH2_PITCH_ENV_IDX = 5
    FAMISTUDIO_N163_CH3_PITCH_ENV_IDX = 6
    FAMISTUDIO_N163_CH4_PITCH_ENV_IDX = 7
    FAMISTUDIO_N163_CH5_PITCH_ENV_IDX = 8
    FAMISTUDIO_N163_CH6_PITCH_ENV_IDX = 9
    FAMISTUDIO_N163_CH7_PITCH_ENV_IDX = 10
.endif
.if FAMISTUDIO_EXP_S5B
    FAMISTUDIO_S5B_CH0_PITCH_ENV_IDX  = 3
    FAMISTUDIO_S5B_CH1_PITCH_ENV_IDX  = 4
    FAMISTUDIO_S5B_CH2_PITCH_ENV_IDX  = 5
.endif
.if FAMISTUDIO_EXP_EPSM
    FAMISTUDIO_EPSM_CH0_PITCH_ENV_IDX = 3
    FAMISTUDIO_EPSM_CH1_PITCH_ENV_IDX = 4
    FAMISTUDIO_EPSM_CH2_PITCH_ENV_IDX = 5
    FAMISTUDIO_EPSM_CH3_PITCH_ENV_IDX = 6
    FAMISTUDIO_EPSM_CH4_PITCH_ENV_IDX = 7
    FAMISTUDIO_EPSM_CH5_PITCH_ENV_IDX = 8
    FAMISTUDIO_EPSM_CH6_PITCH_ENV_IDX = 9
    FAMISTUDIO_EPSM_CH7_PITCH_ENV_IDX = 10
    FAMISTUDIO_EPSM_CH8_PITCH_ENV_IDX = 11
.endif

; TODO: Investigate reshuffling the envelopes to keep them contiguously 
; by type (all volumes envelopes, all arp envelopes, etc.) instead of 
; by channel. This *may* simplify a lot of places where we need a lookup
; table (famistudio_channel_to_volume_env, etc.)
FAMISTUDIO_CH0_ENVS = 0
FAMISTUDIO_CH1_ENVS = 3
FAMISTUDIO_CH2_ENVS = 6
FAMISTUDIO_CH3_ENVS = 8

.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_VRC6_CH0_ENVS = 11
    FAMISTUDIO_VRC6_CH1_ENVS = 14
    FAMISTUDIO_VRC6_CH2_ENVS = 17
.endif
.if FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_VRC7_CH0_ENVS = 11
    FAMISTUDIO_VRC7_CH1_ENVS = 13
    FAMISTUDIO_VRC7_CH2_ENVS = 15
    FAMISTUDIO_VRC7_CH3_ENVS = 17
    FAMISTUDIO_VRC7_CH4_ENVS = 19
    FAMISTUDIO_VRC7_CH5_ENVS = 21
.endif
.if FAMISTUDIO_EXP_FDS
    FAMISTUDIO_FDS_CH0_ENVS = 11
.endif
.if FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_MMC5_CH0_ENVS = 11
    FAMISTUDIO_MMC5_CH1_ENVS = 14
.endif
.if FAMISTUDIO_EXP_N163
    FAMISTUDIO_N163_CH0_ENVS = 11
    FAMISTUDIO_N163_CH1_ENVS = 14
    FAMISTUDIO_N163_CH2_ENVS = 17
    FAMISTUDIO_N163_CH3_ENVS = 20
    FAMISTUDIO_N163_CH4_ENVS = 23
    FAMISTUDIO_N163_CH5_ENVS = 26
    FAMISTUDIO_N163_CH6_ENVS = 29
    FAMISTUDIO_N163_CH7_ENVS = 32
.endif
.if FAMISTUDIO_EXP_S5B
    FAMISTUDIO_S5B_CH0_ENVS = 11
    FAMISTUDIO_S5B_CH1_ENVS = 15
    FAMISTUDIO_S5B_CH2_ENVS = 19
.endif
.if FAMISTUDIO_EXP_EPSM
.if FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT > 0
EPSM_ENV_CH1_INCREMENT = 4
.else
EPSM_ENV_CH1_INCREMENT = 2
.endif
.if FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT > 1
EPSM_ENV_CH2_INCREMENT = 4
.else
EPSM_ENV_CH2_INCREMENT = 2
.endif
.if FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT > 2
EPSM_ENV_CH3_INCREMENT = 4
.else
EPSM_ENV_CH3_INCREMENT = 2
.endif
    FAMISTUDIO_EPSM_CH0_ENVS = 11
    FAMISTUDIO_EPSM_CH1_ENVS =  FAMISTUDIO_EPSM_CH0_ENVS + EPSM_ENV_CH1_INCREMENT
    FAMISTUDIO_EPSM_CH2_ENVS =  FAMISTUDIO_EPSM_CH1_ENVS + EPSM_ENV_CH2_INCREMENT
    FAMISTUDIO_EPSM_CH3_ENVS =  FAMISTUDIO_EPSM_CH2_ENVS + EPSM_ENV_CH3_INCREMENT
    FAMISTUDIO_EPSM_CH4_ENVS =  FAMISTUDIO_EPSM_CH3_ENVS + 2
    FAMISTUDIO_EPSM_CH5_ENVS =  FAMISTUDIO_EPSM_CH4_ENVS + 2
    FAMISTUDIO_EPSM_CH6_ENVS =  FAMISTUDIO_EPSM_CH5_ENVS + 2
    FAMISTUDIO_EPSM_CH7_ENVS =  FAMISTUDIO_EPSM_CH6_ENVS + 2
    FAMISTUDIO_EPSM_CH8_ENVS =  FAMISTUDIO_EPSM_CH7_ENVS + 2
.endif

FAMISTUDIO_ENV_VOLUME_OFF        = 0
FAMISTUDIO_ENV_NOTE_OFF          = 1
FAMISTUDIO_ENV_DUTY_OFF          = 2
FAMISTUDIO_ENV_N163_WAVE_IDX_OFF = 2
FAMISTUDIO_ENV_FDS_WAVE_IDX_OFF  = 2
FAMISTUDIO_ENV_MIXER_IDX_OFF     = 2
FAMISTUDIO_ENV_NOISE_IDX_OFF     = 3

.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_VRC6_CH0_DUTY_IDX = 3
    FAMISTUDIO_VRC6_CH1_DUTY_IDX = 4
    FAMISTUDIO_VRC6_CH2_DUTY_IDX = 5
.endif
.if FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_MMC5_CH0_DUTY_IDX = 3
    FAMISTUDIO_MMC5_CH1_DUTY_IDX = 4
.endif

.if FAMISTUDIO_EXP_VRC6
    FAMISTUDIO_VRC6_CH0_IDX = 5
    FAMISTUDIO_VRC6_CH1_IDX = 6
    FAMISTUDIO_VRC6_CH2_IDX = 7
.else
    FAMISTUDIO_VRC6_CH0_IDX = -1
    FAMISTUDIO_VRC6_CH1_IDX = -1
    FAMISTUDIO_VRC6_CH2_IDX = -1
.endif
.if FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_VRC7_CH0_IDX = 5
    FAMISTUDIO_VRC7_CH1_IDX = 6
    FAMISTUDIO_VRC7_CH2_IDX = 7
    FAMISTUDIO_VRC7_CH3_IDX = 8
    FAMISTUDIO_VRC7_CH4_IDX = 9
    FAMISTUDIO_VRC7_CH5_IDX = 10
.endif
.if FAMISTUDIO_EXP_FDS
    FAMISTUDIO_FDS_CH0_IDX  = 5
.endif
.if FAMISTUDIO_EXP_MMC5
    FAMISTUDIO_MMC5_CH0_IDX = 5
    FAMISTUDIO_MMC5_CH1_IDX = 6
.else
    FAMISTUDIO_MMC5_CH0_IDX = -1
    FAMISTUDIO_MMC5_CH1_IDX = -1
.endif
.if FAMISTUDIO_EXP_N163
    FAMISTUDIO_N163_CH0_IDX = 5
    FAMISTUDIO_N163_CH1_IDX = 6
    FAMISTUDIO_N163_CH2_IDX = 7
    FAMISTUDIO_N163_CH3_IDX = 8
    FAMISTUDIO_N163_CH4_IDX = 9
    FAMISTUDIO_N163_CH5_IDX = 10
    FAMISTUDIO_N163_CH6_IDX = 11
    FAMISTUDIO_N163_CH7_IDX = 12
.endif
.if FAMISTUDIO_EXP_S5B
    FAMISTUDIO_S5B_CH0_IDX  = 5
    FAMISTUDIO_S5B_CH1_IDX  = 6
    FAMISTUDIO_S5B_CH2_IDX  = 7
.endif
.if FAMISTUDIO_EXP_EPSM
    FAMISTUDIO_EPSM_CH0_IDX = 5
    FAMISTUDIO_EPSM_CH1_IDX = 6
    FAMISTUDIO_EPSM_CH2_IDX = 7
    FAMISTUDIO_EPSM_CH3_IDX = 8
    FAMISTUDIO_EPSM_CH4_IDX = 9
    FAMISTUDIO_EPSM_CH5_IDX = 10
    FAMISTUDIO_EPSM_CH6_IDX = 11
    FAMISTUDIO_EPSM_CH7_IDX = 12
    FAMISTUDIO_EPSM_CH8_IDX = 13
    FAMISTUDIO_EPSM_CH9_IDX = 14
    FAMISTUDIO_EPSM_CH10_IDX = 15
    FAMISTUDIO_EPSM_CH11_IDX = 16
    FAMISTUDIO_EPSM_CH12_IDX = 17
    FAMISTUDIO_EPSM_CH13_IDX = 18
    FAMISTUDIO_EPSM_CH14_IDX = 19
    FAMISTUDIO_EPSM_CHAN_FM_START = FAMISTUDIO_EPSM_CH0_IDX + FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT
    FAMISTUDIO_EPSM_CHAN_RHYTHM_START = FAMISTUDIO_EPSM_CHAN_FM_START + FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
.endif

FAMISTUDIO_VRC7_PITCH_SHIFT = 3
FAMISTUDIO_EPSM_PITCH_SHIFT = 3

.if (FAMISTUDIO_EXP_N163_CHN_CNT > 4)
    FAMISTUDIO_N163_PITCH_SHIFT = 5
.endif
.if (FAMISTUDIO_EXP_N163_CHN_CNT > 2) & (FAMISTUDIO_EXP_N163_CHN_CNT <= 4)
    FAMISTUDIO_N163_PITCH_SHIFT = 4
.endif
.if (FAMISTUDIO_EXP_N163_CHN_CNT > 1) & (FAMISTUDIO_EXP_N163_CHN_CNT <= 2)
    FAMISTUDIO_N163_PITCH_SHIFT = 3
.endif
.if (FAMISTUDIO_EXP_N163_CHN_CNT = 1)
    FAMISTUDIO_N163_PITCH_SHIFT = 2
.endif 

.if FAMISTUDIO_EXP_VRC7
    FAMISTUDIO_PITCH_SHIFT = FAMISTUDIO_VRC7_PITCH_SHIFT
.else
    .if FAMISTUDIO_EXP_EPSM
        FAMISTUDIO_PITCH_SHIFT = FAMISTUDIO_EPSM_PITCH_SHIFT
    .else
        .if FAMISTUDIO_EXP_N163
            FAMISTUDIO_PITCH_SHIFT = FAMISTUDIO_N163_PITCH_SHIFT
        .else
            FAMISTUDIO_PITCH_SHIFT = 0
        .endif    
    .endif
.endif

.if FAMISTUDIO_EXP_N163
    FAMISTUDIO_N163_CHN_MASK = (FAMISTUDIO_EXP_N163_CHN_CNT - 1) << 4
.endif

.if FAMISTUDIO_CFG_SFX_SUPPORT
    FAMISTUDIO_SFX_STRUCT_SIZE = 15

    FAMISTUDIO_SFX_CH0 = FAMISTUDIO_SFX_STRUCT_SIZE * 0
    FAMISTUDIO_SFX_CH1 = FAMISTUDIO_SFX_STRUCT_SIZE * 1
    FAMISTUDIO_SFX_CH2 = FAMISTUDIO_SFX_STRUCT_SIZE * 2
    FAMISTUDIO_SFX_CH3 = FAMISTUDIO_SFX_STRUCT_SIZE * 3
.endif

FAMISTUDIO_FIRST_EXP_INST_CHANNEL = 5

.if FAMISTUDIO_EXP_EPSM
FAMISTUDIO_FIRST_POSITIVE_SLIDE_CHANNEL = 3 + FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT
.else
FAMISTUDIO_FIRST_POSITIVE_SLIDE_CHANNEL = 3
.endif

;======================================================================================================================
; RAM VARIABLES (You should not have to play with these)
;======================================================================================================================

.segment .string(FAMISTUDIO_CA65_RAM_SEGMENT)

famistudio_env_value:             .res FAMISTUDIO_NUM_ENVELOPES
famistudio_env_repeat:            .res FAMISTUDIO_NUM_ENVELOPES
famistudio_env_addr_lo:           .res FAMISTUDIO_NUM_ENVELOPES
famistudio_env_addr_hi:           .res FAMISTUDIO_NUM_ENVELOPES
famistudio_env_ptr:               .res FAMISTUDIO_NUM_ENVELOPES

famistudio_pitch_env_value_lo:    .res FAMISTUDIO_NUM_PITCH_ENVELOPES
famistudio_pitch_env_value_hi:    .res FAMISTUDIO_NUM_PITCH_ENVELOPES
famistudio_pitch_env_repeat:      .res FAMISTUDIO_NUM_PITCH_ENVELOPES
famistudio_pitch_env_addr_lo:     .res FAMISTUDIO_NUM_PITCH_ENVELOPES
famistudio_pitch_env_addr_hi:     .res FAMISTUDIO_NUM_PITCH_ENVELOPES
famistudio_pitch_env_ptr:         .res FAMISTUDIO_NUM_PITCH_ENVELOPES
.if FAMISTUDIO_USE_PITCH_TRACK
famistudio_pitch_env_fine_value:  .res FAMISTUDIO_NUM_PITCH_ENVELOPES
.endif

.if FAMISTUDIO_USE_SLIDE_NOTES
famistudio_slide_step:            .res FAMISTUDIO_NUM_SLIDES
famistudio_slide_pitch_lo:        .res FAMISTUDIO_NUM_SLIDES
famistudio_slide_pitch_hi:        .res FAMISTUDIO_NUM_SLIDES
.endif

famistudio_chn_ptr_lo:            .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_ptr_hi:            .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_note:              .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_repeat:            .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_return_lo:         .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_return_hi:         .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_ref_len:           .res FAMISTUDIO_NUM_CHANNELS
.if FAMISTUDIO_USE_VOLUME_TRACK
famistudio_chn_volume_track:      .res FAMISTUDIO_NUM_CHANNELS
.if FAMISTUDIO_USE_VOLUME_SLIDES
famistudio_chn_volume_slide_step:   .res FAMISTUDIO_NUM_VOLUME_SLIDES
famistudio_chn_volume_slide_target: .res FAMISTUDIO_NUM_VOLUME_SLIDES
.endif
.endif
.if FAMISTUDIO_USE_VIBRATO || FAMISTUDIO_USE_ARPEGGIO
famistudio_chn_env_override:      .res FAMISTUDIO_NUM_CHANNELS ; bit 7 = pitch, bit 0 = arpeggio.
.endif
.if FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS
famistudio_chn_note_delay:        .res FAMISTUDIO_NUM_CHANNELS
famistudio_chn_cut_delay:         .res FAMISTUDIO_NUM_CHANNELS
.endif
.if FAMISTUDIO_CFG_EQUALIZER
famistudio_chn_note_counter:      .res FAMISTUDIO_NUM_CHANNELS
.endif
.if FAMISTUDIO_USE_PHASE_RESET
famistudio_phase_reset:           .res 1 ; bit 0/1 = 2a03, bit 2/3/4 = vrc6, 5/6 = mmc5, bit 7 = fds
.if FAMISTUDIO_EXP_N163
famistudio_phase_reset_n163:      .res 1 ; bit 0...7 = n163
.endif
.endif
.if FAMISTUDIO_USE_DELTA_COUNTER
famistudio_dmc_delta_counter:     .res 1
.endif
.if FAMISTUDIO_EXP_VRC6
famistudio_vrc6_saw_volume:       .res 1 ; -1 = 1/4, 0 = 1/2, 1 = Full
.if FAMISTUDIO_USE_PHASE_RESET
famistudio_vrc6_pulse1_prev_hi:   .res 1
famistudio_vrc6_pulse2_prev_hi:   .res 1
famistudio_vrc6_saw_prev_hi:      .res 1
.else
famistudio_vrc6_pulse1_prev_hi = famistudio_vrc6_saw_volume
famistudio_vrc6_pulse2_prev_hi = famistudio_vrc6_saw_volume
famistudio_vrc6_saw_prev_hi    = famistudio_vrc6_saw_volume
.endif
.endif
.if FAMISTUDIO_EXP_VRC7
famistudio_chn_vrc7_prev_hi:      .res 6
famistudio_chn_vrc7_patch:        .res 6
famistudio_chn_vrc7_trigger:      .res 6 ; bit 0 = new note triggered, bit 7 = note released.
.endif
.if FAMISTUDIO_EXP_EPSM
.if FAMISTUDIO_EXP_EPSM_RHYTHM_CNT > 0
famistudio_chn_epsm_rhythm_volume: .res FAMISTUDIO_EXP_EPSM_RHYTHM_CNT
famistudio_chn_epsm_rhythm_stereo: .res FAMISTUDIO_EXP_EPSM_RHYTHM_CNT
.endif
.if FAMISTUDIO_EXP_EPSM_FM_CHN_CNT+FAMISTUDIO_EXP_EPSM_RHYTHM_CNT > 0
famistudio_chn_epsm_trigger:       .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT + FAMISTUDIO_EXP_EPSM_RHYTHM_CNT ; bit 0 = new note triggered, bit 7 = note released.
.endif
.if FAMISTUDIO_EXP_EPSM_FM_CHN_CNT > 0
famistudio_chn_epsm_fm_stereo:     .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_fm_instrument: .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_alg:           .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_vol_op1:       .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_vol_op2:       .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_vol_op3:       .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
famistudio_chn_epsm_vol_op4:       .res FAMISTUDIO_EXP_EPSM_FM_CHN_CNT
.endif
.if FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT > 0
famistudio_epsm_env_period_lo:     .res 1
famistudio_epsm_env_period_hi:     .res 1
famistudio_epsm_env_override:      .res 1
famistudio_epsm_chn_env_shape:     .res FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT ; bit 7 = note attack.
famistudio_epsm_chn_env_octave:    .res FAMISTUDIO_EXP_EPSM_SSG_CHN_CNT
.endif
.endif
.if FAMISTUDIO_EXP_FDS
famistudio_chn_fds_instrument:    .res 1
.endif
.if FAMISTUDIO_EXP_N163
famistudio_chn_n163_instrument:   .res FAMISTUDIO_EXP_N163_CHN_CNT
famistudio_chn_n163_wave_index:   .res FAMISTUDIO_EXP_N163_CHN_CNT
famistudio_chn_n163_wave_len:     .res FAMISTUDIO_EXP_N163_CHN_CNT
.endif
.if FAMISTUDIO_EXP_S5B
famistudio_s5b_env_period_lo:     .res 1
famistudio_s5b_env_period_hi:     .res 1
famistudio_s5b_env_override:      .res 1 ; if non zero, it means we had an env period effect this frame.
famistudio_s5b_chn_env_shape:     .res 3 ; bit 7 = note attack
famistudio_s5b_chn_env_octave:    .res 3
.endif
.if FAMISTUDIO_USE_DUTYCYCLE_EFFECT
famistudio_duty_cycle:            .res FAMISTUDIO_NUM_DUTY_CYCLES
.endif

.if FAMISTUDIO_USE_FAMITRACKER_TEMPO
famistudio_tempo_step_lo:         .res 1
famistudio_tempo_step_hi:         .res 1
famistudio_tempo_acc_lo:          .res 1
famistudio_tempo_acc_hi:          .res 1
.if FAMISTUDIO_USE_FAMITRACKER_DELAYED_NOTES_OR_CUTS
famistudio_tempo_advance_row:     .res 1
.endif
.else
famistudio_tempo_env_ptr_lo:      .res 1
famistudio_tempo_env_ptr_hi:      .res 1
famistudio_tempo_env_counter:     .res 1
famistudio_tempo_env_idx:         .res 1
famistudio_tempo_frame_num:       .res 1
famistudio_tempo_frame_cnt:       .res 1
.endif

famistudio_pal_adjust:            .res 1
famistudio_song_list_lo:          .res 1
famistudio_song_list_hi:          .res 1
famistudio_instrument_lo:         .res 1
famistudio_instrument_hi:         .res 1
famistudio_dpcm_list_lo:          .res 1 ; TODO: Not needed if DPCM support is disabled.
famistudio_dpcm_list_hi:          .res 1 ; TODO: Not needed if DPCM support is disabled.
famistudio_dpcm_effect:           .res 1 ; TODO: Not needed if DPCM support is disabled.
famistudio_pulse1_prev:           .res 1
famistudio_pulse2_prev:           .res 1
famistudio_song_speed:            .res 1

.if FAMISTUDIO_EXP_MMC5
famistudio_mmc5_pulse1_prev:      .res 1
famistudio_mmc5_pulse2_prev:      .res 1
.endif

.if FAMISTUDIO_EXP_FDS
famistudio_fds_mod_envelope:      .res 2
famistudio_fds_mod_speed:         .res 2
famistudio_fds_mod_depth:         .res 1
famistudio_fds_mod_delay:         .res 1
famistudio_fds_mod_delay_counter: .res 1
famistudio_fds_override_flags:    .res 1 ; Bit 7 = mod speed overriden, bit 6 mod depth overriden
famistudio_fds_wave_index:        .res 1
.if FAMISTUDIO_USE_FDS_AUTOMOD
famistudio_fds_automod_numer:     .res 1 ; 0 = auto-mod off.
famistudio_fds_automod_denom:     .res 1
.endif
.if FAMISTUDIO_USE_PHASE_RESET
famistudio_fds_prev_hi:           .res 1
.endif
.endif

.if FAMISTUDIO_EXP_VRC7
famistudio_vrc7_dummy:            .res 1 ; TODO: Find a dummy address i can simply write to without side effects.
.endif

; FDS, N163 and VRC7 have very different instrument layout and are 16-bytes, so we keep them seperate.
.if FAMISTUDIO_EXP_FDS || FAMISTUDIO_EXP_N163 || FAMISTUDIO_EXP_VRC7 || FAMISTUDIO_EXP_EPSM || FAMISTUDIO_EXP_S5B
famistudio_exp_instrument_lo:     .res 1
famistudio_exp_instrument_hi:     .res 1
.endif

.if FAMISTUDIO_CFG_SFX_SUPPORT

famistudio_output_buf:     .res 11
famistudio_sfx_addr_lo:    .res 1
famistudio_sfx_addr_hi:    .res 1
famistudio_sfx_base_addr:  .res (FAMISTUDIO_CFG_SFX_STREAMS * FAMISTUDIO_SFX_STRUCT_SIZE)

; TODO: Refactor SFX memory layout. These uses a AoS approach, not fan. 
famistudio_sfx_repeat = famistudio_sfx_base_addr + 0
famistudio_sfx_ptr_lo = famistudio_sfx_base_addr + 1
famistudio_sfx_ptr_hi = famistudio_sfx_base_addr + 2
famistudio_sfx_offset = famistudio_sfx_base_addr + 3
famistudio_sfx_buffer = famistudio_sfx_base_addr + 4

.endif 

;======================================================================================================================
; ZEROPAGE VARIABLES
;
; These are only used as temporary variable during the famistudio_xxx calls.
; Feel free to alias those with other ZP values in your programs to save a few bytes.
;======================================================================================================================

.segment .string(FAMISTUDIO_CA65_ZP_SEGMENT) : zeropage

famistudio_r0:   .res 1
famistudio_r1:   .res 1
famistudio_r2:   .res 1
famistudio_r3:   .res 1

famistudio_ptr0: .res 2
famistudio_ptr1: .res 2
.if FAMISTUDIO_EXP_EPSM || FAMISTUDIO_EXP_FDS || FAMISTUDIO_EXP_S5B
famistudio_ptr2: .res 2
.endif

famistudio_ptr0_lo = famistudio_ptr0+0
famistudio_ptr0_hi = famistudio_ptr0+1
famistudio_ptr1_lo = famistudio_ptr1+0
famistudio_ptr1_hi = famistudio_ptr1+1
