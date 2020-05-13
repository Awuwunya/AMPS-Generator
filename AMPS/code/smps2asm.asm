;GEN-ASM
; ===========================================================================
; ---------------------------------------------------------------------------
; AMPS - SMPS2ASM macro & equate file
; ---------------------------------------------------------------------------
%ifasm% AS
; Note Equates
; ---------------------------------------------------------------------------

	enum nC0=$81,nCs0,nD0,nEb0,nE0,nF0,nFs0,nG0,nAb0,nA0,nBb0,nB0
	enum nC1=$8D,nCs1,nD1,nEb1,nE1,nF1,nFs1,nG1,nAb1,nA1,nBb1,nB1
	enum nC2=$99,nCs2,nD2,nEb2,nE2,nF2,nFs2,nG2,nAb2,nA2,nBb2,nB2
	enum nC3=$A5,nCs3,nD3,nEb3,nE3,nF3,nFs3,nG3,nAb3,nA3,nBb3,nB3
	enum nC4=$B1,nCs4,nD4,nEb4,nE4,nF4,nFs4,nG4,nAb4,nA4,nBb4,nB4
	enum nC5=$BD,nCs5,nD5,nEb5,nE5,nF5,nFs5,nG5,nAb5,nA5,nBb5,nB5
	enum nC6=$C9,nCs6,nD6,nEb6,nE6,nF6,nFs6,nG6,nAb6,nA6,nBb6,nB6
	enum nC7=$D5,nCs7,nD7,nEb7,nE7,nF7,nFs7,nG7,nAb7,nA7,nBb7
	enum nRst=$80, nHiHat=nBb6
%endif%
%ifasm% ASM68K

; this macro is created to emulate enum in AS
enum		macro lable
	rept narg
\lable =	_num
_num =		_num+1
	shift
	endr
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Note equates
; ---------------------------------------------------------------------------

_num =		$80
	enum nRst
	enum nC0,nCs0,nD0,nEb0,nE0,nF0,nFs0,nG0,nAb0,nA0,nBb0,nB0
	enum nC1,nCs1,nD1,nEb1,nE1,nF1,nFs1,nG1,nAb1,nA1,nBb1,nB1
	enum nC2,nCs2,nD2,nEb2,nE2,nF2,nFs2,nG2,nAb2,nA2,nBb2,nB2
	enum nC3,nCs3,nD3,nEb3,nE3,nF3,nFs3,nG3,nAb3,nA3,nBb3,nB3
	enum nC4,nCs4,nD4,nEb4,nE4,nF4,nFs4,nG4,nAb4,nA4,nBb4,nB4
	enum nC5,nCs5,nD5,nEb5,nE5,nF5,nFs5,nG5,nAb5,nA5,nBb5,nB5
	enum nC6,nCs6,nD6,nEb6,nE6,nF6,nFs6,nG6,nAb6,nA6,nBb6,nB6
	enum nC7,nCs7,nD7,nEb7,nE7,nF7,nFs7,nG7,nAb7,nA7,nBb7
nHiHat =	nBb6
%endif%
; ===========================================================================
; ---------------------------------------------------------------------------
; Header macros
; ---------------------------------------------------------------------------

; Header - Initialize a music file
sHeaderInit	macro
sPatNum %set%	0
    endm

; Header - Initialize a sound effect file
sHeaderInitSFX	macro

    endm

; Header - Set up channel usage
sHeaderCh	macro fm,psg
%narg% >1 psg <>
		dc.b %macpfx%psg-1, %macpfx%fm-1
		if %macpfx%fm>(5+((FEATURE_FM6<>0)&1))
			%warning%"You sure there are %macpfx%fm FM channels?"
		endif

		if %macpfx%psg>3
			%warning%"You sure there are %macpfx%psg PSG channels?"
		endif
	else
		dc.b %macpfx%fm-1
	endif
    endm

; Header - Set up tempo and tick multiplier
sHeaderTempo	macro tmul,tempo
	dc.b %macpfx%tempo,%macpfx%tmul-1
    endm

; Header - Set priority level
sHeaderPrio	macro prio
	dc.b %macpfx%prio
    endm

; Header - Set up a DAC channel
sHeaderDAC	macro loc,vol,samp
	dc.w %macpfx%loc-*

%narg% >1 vol <>
		dc.b (%macpfx%vol)&$FF
	%narg% >2 samp <>
			dc.b %macpfx%samp
		else
			dc.b $00
		endif
	else
		dc.w $00
	endif
    endm

; Header - Set up an FM channel
sHeaderFM	macro loc,pitch,vol
	dc.w %macpfx%loc-*
	dc.b (%macpfx%pitch)&$FF,(%macpfx%vol)&$FF
    endm

; Header - Set up a PSG channel
sHeaderPSG	macro loc,pitch,vol,detune,volenv
	dc.w %macpfx%loc-*
	dc.b (%macpfx%pitch)&$FF,(%macpfx%vol)&$FF,(%macpfx%detune)&$FF,%macpfx%volenv
    endm

; Header - Set up an SFX channel
sHeaderSFX	macro flags,type,loc,pitch,vol
	dc.b %macpfx%flags,%macpfx%type
	dc.w %macpfx%loc-*
	dc.b (%macpfx%pitch)&$FF,(%macpfx%vol)&$FF
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Macros for FM instruments
; ---------------------------------------------------------------------------

; Patches - Algorithm and patch name
spAlgorithm	macro val, name
	if (sPatNum<>0)&(safe=0)
		; align the patch
		dc.b ((*)%xor%(sPatNum*spTL4))&$FF
		dc.b (((*)>>8)+(spDe3*spDR3))&$FF
		dc.b (((*)>>16)-(spTL1*spRR3))&$FF
	endif

%narg% >1 name <>
p%dlbs%name%dlbe% %set%		sPatNum
	endif

sPatNum %set%	sPatNum+1
spAl %set%		%macpfx%val
    endm

; Patches - Feedback
spFeedback	macro val
spFe %set%		%macpfx%val
    endm

; Patches - Detune
spDetune	macro op1,op2,op3,op4
spDe1 %set%		%macpfx%op1
spDe2 %set%		%macpfx%op2
spDe3 %set%		%macpfx%op3
spDe4 %set%		%macpfx%op4
    endm

; Patches - Multiple
spMultiple	macro op1,op2,op3,op4
spMu1 %set%		%macpfx%op1
spMu2 %set%		%macpfx%op2
spMu3 %set%		%macpfx%op3
spMu4 %set%		%macpfx%op4
    endm

; Patches - Rate Scale
spRateScale	macro op1,op2,op3,op4
spRS1 %set%		%macpfx%op1
spRS2 %set%		%macpfx%op2
spRS3 %set%		%macpfx%op3
spRS4 %set%		%macpfx%op4
    endm

; Patches - Attack Rate
spAttackRt	macro op1,op2,op3,op4
spAR1 %set%		%macpfx%op1
spAR2 %set%		%macpfx%op2
spAR3 %set%		%macpfx%op3
spAR4 %set%		%macpfx%op4
    endm

; Patches - Amplitude Modulation
spAmpMod	macro op1,op2,op3,op4
spAM1 %set%		%macpfx%op1
spAM2 %set%		%macpfx%op2
spAM3 %set%		%macpfx%op3
spAM4 %set%		%macpfx%op4
    endm

; Patches - Sustain Rate
spSustainRt	macro op1,op2,op3,op4
spSR1 %set%		%macpfx%op1		; Also known as decay 1 rate
spSR2 %set%		%macpfx%op2
spSR3 %set%		%macpfx%op3
spSR4 %set%		%macpfx%op4
    endm

; Patches - Sustain Level
spSustainLv	macro op1,op2,op3,op4
spSL1 %set%		%macpfx%op1		; also known as decay 1 level
spSL2 %set%		%macpfx%op2
spSL3 %set%		%macpfx%op3
spSL4 %set%		%macpfx%op4
    endm

; Patches - Decay Rate
spDecayRt	macro op1,op2,op3,op4
spDR1 %set%		%macpfx%op1		; Also known as decay 2 rate
spDR2 %set%		%macpfx%op2
spDR3 %set%		%macpfx%op3
spDR4 %set%		%macpfx%op4
    endm

; Patches - Release Rate
spReleaseRt	macro op1,op2,op3,op4
spRR1 %set%		%macpfx%op1
spRR2 %set%		%macpfx%op2
spRR3 %set%		%macpfx%op3
spRR4 %set%		%macpfx%op4
    endm

; Patches - SSG-EG
spSSGEG		macro op1,op2,op3,op4
spSS1 %set%		%macpfx%op1
spSS2 %set%		%macpfx%op2
spSS3 %set%		%macpfx%op3
spSS4 %set%		%macpfx%op4
    endm

; Patches - Total Level
spTotalLv	macro op1,op2,op3,op4
spTL1 %set%		%macpfx%op1
spTL2 %set%		%macpfx%op2
spTL3 %set%		%macpfx%op3
spTL4 %set%		%macpfx%op4

; Construct the patch finally.
	dc.b (spFe<<3)+spAl

;   0     1     2     3     4     5     6     7
;%1000,%1000,%1000,%1000,%1010,%1110,%1110,%1111

spTLMask4 %set%	$80
spTLMask2 %set%	((spAl>=5)<<7)
spTLMask3 %set%	((spAl>=4)<<7)
spTLMask1 %set%	((spAl=7)<<7)

	dc.b (spDe1<<4)+spMu1, (spDe3<<4)+spMu3, (spDe2<<4)+spMu2, (spDe4<<4)+spMu4
	dc.b (spRS1<<6)+spAR1, (spRS3<<6)+spAR3, (spRS2<<6)+spAR2, (spRS4<<6)+spAR4
	dc.b (spAM1<<7)+spSR1, (spAM3<<7)+spsR3, (spAM2<<7)+spSR2, (spAM4<<7)+spSR4
	dc.b spDR1,            spDR3,            spDR2,            spDR4
	dc.b (spSL1<<4)+spRR1, (spSL3<<4)+spRR3, (spSL2<<4)+spRR2, (spSL4<<4)+spRR4
	dc.b spSS1,            spSS3,            spSS2,            spSS4
	dc.b spTL1|spTLMask1,  spTL3|spTLMask3,  spTL2|spTLMask2,  spTL4|spTLMask4

	if safe=1
		dc.b "NAT"	; align the patch
	endif
    endm

; Patches - Total Level (for broken total level masks)
spTotalLv2	macro op1,op2,op3,op4
spTL1 %set%		%macpfx%op1
spTL2 %set%		%macpfx%op2
spTL3 %set%		%macpfx%op3
spTL4 %set%		%macpfx%op4

	dc.b (spFe<<3)+spAl
	dc.b (spDe1<<4)+spMu1, (spDe3<<4)+spMu3, (spDe2<<4)+spMu2, (spDe4<<4)+spMu4
	dc.b (spRS1<<6)+spAR1, (spRS3<<6)+spAR3, (spRS2<<6)+spAR2, (spRS4<<6)+spAR4
	dc.b (spAM1<<7)+spSR1, (spAM3<<7)+spsR3, (spAM2<<7)+spSR2, (spAM4<<7)+spSR4
	dc.b spDR1,            spDR3,            spDR2,            spDR4
	dc.b (spSL1<<4)+spRR1, (spSL3<<4)+spRR3, (spSL2<<4)+spRR2, (spSL4<<4)+spRR4
	dc.b spSS1,            spSS3,            spSS2,            spSS4
	dc.b spTL1,	       spTL3,		 spTL2,		   spTL4

	if safe=1
		dc.b "NAT"	; align the patch
	endif
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Equates for sPan
; ---------------------------------------------------------------------------

spNone %equ%	$00
spRight %equ%	$40
spLeft %equ%	$80
spCentre %equ%	$C0
spCenter %equ%	$C0
; ===========================================================================
; ---------------------------------------------------------------------------
; Tracker commands
; ---------------------------------------------------------------------------

; E0xx - Panning, AMS, FMS (PANAFMS - PAFMS_PAN)
sPan		macro pan, ams, fms
%narg% =1 ams ==
		dc.b $E0, %macpfx%pan

%narg% =2 fms == else
		dc.b $E0, %macpfx%pan|%macpfx%ams

	else
		dc.b $E0, %macpfx%pan|(%macpfx%ams<<4)|%macpfx%fms
	endif
    endm

; E1xx - Set channel frequency displacement to xx (DETUNE_SET)
ssDetune	macro detune
	dc.b $E1, %macpfx%detune
    endm

; E2xx - Add xx to channel frequency displacement (DETUNE)
saDetune	macro detune
	dc.b $E2, %macpfx%detune
    endm

; E3xx - Set channel pitch to xx (TRANSPOSE - TRNSP_SET)
ssTranspose	macro transp
	dc.b $E3, %macpfx%transp
    endm

; E4xx - Add xx to channel pitch (TRANSPOSE - TRNSP_ADD)
saTranspose	macro transp
	dc.b $E4, %macpfx%transp
    endm

; E5xx - Set channel tick multiplier to xx (TICK_MULT - TMULT_CUR)
ssTickMulCh	macro tick
	dc.b $E5, %macpfx%tick-1
    endm

; E6xx - Set global tick multiplier to xx (TICK_MULT - TMULT_ALL)
ssTickMul	macro tick
	dc.b $E6, %macpfx%tick-1
    endm

; E7 - Do not attack of next note (HOLD)
sHold %equ%		$E7

; E8xx - Set patch/voice/sample to xx (INSTRUMENT - INS_C_FM / INS_C_PSG / INS_C_DAC)
sVoice		macro voice
	dc.b $E8, %macpfx%voice
    endm

; F2xx - Set volume envelope to xx (INSTRUMENT - INS_C_PSG) (FM_VOLENV / DAC_VOLENV)
sVolEnv		macro env
	dc.b $F2, %macpfx%env
    endm

; F3xx - Set modulation envelope to xx (MOD_ENV - MENV_GEN)
sModEnv		macro env
	dc.b $F3, %macpfx%env
    endm

; E9xx - Set music speed shoes tempo to xx (TEMPO - TEMPO_SET_SPEED)
ssTempoShoes	macro tempo
	dc.b $E9, %macpfx%tempo
    endm

; EAxx - Set music tempo to xx (TEMPO - TEMPO_SET)
ssTempo		macro tempo
	dc.b $EA, %macpfx%tempo
    endm

; FF18xx - Add xx to music speed tempo (TEMPO - TEMPO_ADD_SPEED)
saTempoSpeed	macro tempo
	dc.b $FF,$18, %macpfx%tempo
    endm

; FF1Cxx - Add xx to music tempo (TEMPO - TEMPO_ADD)
saTempo		macro tempo
	dc.b $FF,$1C, %macpfx%tempo
    endm

; EB - Use sample DAC mode, where each note is a different sample (DAC_MODE - DACM_SAMP)
sModeSampDAC	macro
	dc.b $EB
    endm

; EC - Use pitch DAC mode, where each note is a different pitch (DAC_MODE - DACM_NOTE)
sModePitchDAC	macro
	dc.b $EC
    endm

; EDxx - Add xx to channel volume (VOLUME - VOL_CN_FM / VOL_CN_PSG / VOL_CN_DAC)
saVol		macro volume
	dc.b $ED, %macpfx%volume
    endm

; EExx - Set channel volume to xx (VOLUME - VOL_CN_ABS)
ssVol		macro volume
	dc.b $EE, %macpfx%volume
    endm

; EFxxyy - Enable/Disable LFO (SET_LFO - LFO_AMSEN)
ssLFO		macro reg, ams, fms, pan
%narg% =2 fms ==
		dc.b $EF, %macpfx%reg,%macpfx%ams

%narg% =3 pan == else
		dc.b $EF, %macpfx%reg,(%macpfx%ams<<4)|%macpfx%fms

	else
		dc.b $EF, %macpfx%reg,(%macpfx%ams<<4)|%macpfx%fms|%macpfx%pan
	endif
    endm

; F0xxzzwwyy - Modulation (AMPS algorithm)
;  ww: wait time
;  xx: modulation speed
;  yy: change per step
;  zz: number of steps
; (MOD_SETUP)
sModAMPS	macro wait, speed, step, count
	dc.b $F0
	sModData %macpfx%wait, %macpfx%speed, %macpfx%step, %macpfx%count
    endm

sModData	macro wait, speed, step, count
	dc.b %macpfx%speed, %macpfx%count, %macpfx%step, %macpfx%wait
    endm

; FF00 - Turn on Modulation (MOD_SET - MODS_ON)
sModOn		macro
	dc.b $FF,$00
    endm

; FF04 - Turn off Modulation (MOD_SET - MODS_OFF)
sModOff		macro
	dc.b $FF,$04
    endm

; FF28xxxx - Set modulation frequency to xxxx (MOD_SET - MODS_FREQ)
ssModFreq	macro freq
	dc.b $FF,$28
	dc.w %macpfx%freq
    endm

; FF2C - Reset modulation data (MOD_SET - MODS_RESET)
sModReset	macro
	dc.b $FF,$2C
    endm

; F1xx - Set portamento speed to xx frames. 0 means portamento is disabled (PORTAMENTO)
ssPortamento	macro frames
	dc.b $F1, %macpfx%frames
    endm

; F4xxxx - Keep looping back to xxxx each time the SFX is being played (CONT_SFX)
sCont		macro loc
	dc.b $F4
	dc.w %macpfx%loc-*-2
    endm

; F5 - End of channel (TRK_END - TEND_STD)
sStop		macro
	dc.b $F5
    endm

; F6xxxx - Jump to xxxx (GOTO)
sJump		macro loc
	dc.b $F6
	dc.w %macpfx%loc-*-2
    endm

; F7xxyyzzzz - Loop back to zzzz yy times, xx being the loop index for loop recursion fixing (LOOP)
sLoop		macro index,loops,loc
	dc.b $F7, %macpfx%index
	dc.w %macpfx%loc-*-2
	dc.b %macpfx%loops-1

	if %macpfx%loops<2
		%fatal%"Invalid number of loops! Must be 2 or more!"
	endif
    endm

; F8xxxx - Call pattern at xxxx, saving return point (GOSUB)
sCall		macro loc
	dc.b $F8
	dc.w %macpfx%loc-*-2
    endm

; F9 - Return (RETURN)
sRet		macro
	dc.b $F9
    endm

; FAyyxx - Set communications byte yy to xx (SET_COMM - SPECIAL)
sComm		macro index, val
	dc.b $FA, %macpfx%index,%macpfx%val
    endm

; FBxyzz - Get communications byte y, and compare zz with it using condition x (COMM_CONDITION)
sCond		macro index, cond, val
	dc.b $FB, %macpfx%index|(%macpfx%cond<<4),%macpfx%val
    endm

; FC - Reset condition (COMM_RESET)
sCondOff	macro
	dc.b $FC
    endm

; FDxx - Stop note after xx frames (NOTE_STOP - NSTOP_NORMAL)
sGate		macro frames
	dc.b $FD, %macpfx%frames
    endm

; FExxyy - YM command yy on register xx (YMCMD)
sCmdYM		macro reg, val
	dc.b $FE, %macpfx%reg,%macpfx%val
    endm

; FF08xxxx - Set channel frequency to xxxx (CHFREQ_SET)
ssFreq		macro freq
	dc.b $FF,$08
	dc.w %macpfx%freq
    endm

; FF0Cxx - Set channel frequency to note xx (CHFREQ_SET - CHFREQ_NOTE)
ssFreqNote	macro note
	dc.b $FF,$0C, %macpfx%note%xor%$80
    endm

; FF10 - Increment spindash rev counter (SPINDASH_REV - SDREV_INC)
sSpinRev	macro
	dc.b $FF,$10
    endm

; FF14 - Reset spindash rev counter (SPINDASH_REV - SDREV_RESET)
sSpinReset	macro
	dc.b $FF,$14
    endm

; FF20xyzz - Get RAM address pointer offset by y, compare zz with it using condition x (COMM_CONDITION - COMM_SPEC)
sCondReg	macro index, cond, val
	dc.b $FF,$20, %macpfx%index|(%macpfx%cond<<4),%macpfx%val
    endm

; FF24xx - Play another music/sfx (SND_CMD)
sPlayMus	macro id
	dc.b $FF,$24, %macpfx%id
    endm

; FF30 - Enable FM3 special mode (SPC_FM3)
sSpecFM3	macro
	dc.b $FF,$30
	%fatal%"Flag is currently not implemented! Please remove."
    endm

; FF34xx - Set DAC filter bank address (DAC_FILTER)
ssFilter	macro bank
	dc.b $FF,$34, %macpfx%bank
    endm

; FF38 - Load the last song from back-up (FADE_IN_SONG)
sBackup		macro
	dc.b $FF,$38
    endm

; FF3Cxx - PSG4 noise mode xx (PSG_NOISE - PNOIS_AMPS)
sNoisePSG	macro mode
	dc.b $FF,$3C, %macpfx%mode
    endm

; FF40 - Freeze 68k. Debug flag (DEBUG_STOP_CPU)
sFreeze		macro
	if safe=1
		dc.b $FF,$40
	endif
    endm

; FF44 - Bring up tracker debugger at end of frame. Debug flag (DEBUG_PRINT_TRACKER)
sCheck		macro
	if safe=1
		dc.b $FF,$44
	endif
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Equates for sNoisePSG
; ---------------------------------------------------------------------------

%ifasm% AS
	enum snOff=$00			; disables PSG3 noise mode.
	enum snPeri10=$E0,snPeri20,snPeri40,snPeriPSG3
	enum snWhite10=$E4,snWhite20,snWhite40,snWhitePSG3
%endif%
%ifasm% ASM68K
snOff =		$00			; disables PSG3 noise mode.
_num =		$E0
	enum snPeri10, snPeri20, snPeri40, snPeriPSG3
	enum snWhite10,snWhite20,snWhite40,snWhitePSG3
%endif%
; ---------------------------------------------------------------------------
