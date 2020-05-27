;GEN-ASM
; ===========================================================================
; ---------------------------------------------------------------------------
; Register usage throughout the AMPS codebase in most situations
; ---------------------------------------------------------------------------
;   a0 - Dual PCM cue
;   a1 - Current channel
;   a2 - Tracker
;   a3 - Special address (channels), target channel (playsnd), scratch
;   a4 - Music channel (dcStop), other various uses, scratch
;   a5-a6 - Scratch, use lower number when possible
;   d0 - Channel dbf counter, other dbf counters
;   d1 - Various things read from the tracker, scratch
;   d2 - Volume or pitch when calculating it
;   d3-d6 - Scatch, use lower number when possible
;   d7 - Never used for anything.
; ===========================================================================
; ---------------------------------------------------------------------------
; Various assembly flags
; ---------------------------------------------------------------------------
%ifasm% ASM68K
	opt ae+
%endif%

%features%
; ---------------------------------------------------------------------------

; Select the tempo algorithm
; 0 = Overflow method
; 1 = Counter method

TEMPO_ALGORITHM =	0

; if safe mode is enabled (1), then the driver will attempt to find any issues
; if Vladik's error debugger is installed, then the error will be displayed
; else, the CPU is trapped

safe =	1
; ===========================================================================
; ---------------------------------------------------------------------------
; Channel configuration
; ---------------------------------------------------------------------------

	%rsset% 0
cFlags		%rb% 1		; various channel flags, see below
cType		%rb% 1		; hardware type for the channel
cData		%rl% 1		; tracker address for the channel
	if FEATURE_DACFMVOLENV=0
cEnvPos =	%re%		; volume envelope position. PSG only
	endif
cPanning	%rb% 1		; channel panning and LFO. FM and DAC only
cDetune		%rb% 1		; frequency detune (offset)
cPitch		%rb% 1		; pitch (transposition) offset
cVolume		%rb% 1		; channel volume
cTick		%rb% 1		; channel tick multiplier
	if FEATURE_DACFMVOLENV=0
cVolEnv =	%re%		; volume envelope ID. PSG only
	endif
cSample =	%re%		; channel sample ID, DAC only
cVoice		%rb% 1		; YM2612 voice ID. FM only
cDuration	%rb% 1		; current note duration
cLastDur	%rb% 1		; last note duration
cFreq		%rw% 1		; channel note frequency

	if FEATURE_MODULATION
cModDelay =	%re%		; delay before modulation starts
cMod		%rl% 1		; modulation data address
cModFreq	%rw% 1		; modulation frequency offset
cModSpeed	%rb% 1		; number of frames til next modulation step
cModStep	%rb% 1		; modulation frequency offset per step
cModCount	%rb% 1		; number of modulation steps until reversal
	endif

	if FEATURE_PORTAMENTO
cPortaSpeed	%rb% 1		; number of frames for portamento to complete. 0 means it is disabled
		%reven%
cPortaFreq	%rw% 1		; frequency offset for portamento
cPortaDisp	%rw% 1		; frequency displacement per frame for portamento
	endif

	if FEATURE_DACFMVOLENV
cVolEnv		%rb% 1		; volume envelope ID
cEnvPos		%rb% 1		; volume envelope position
	endif

	if FEATURE_MODENV
cModEnv		%rb% 1		; modulation envelope ID
cModEnvPos	%rb% 1		; modulation envelope position
cModEnvSens	%rb% 1		; sensitivity of modulation envelope
	endif

	if FEATURE_SOUNDTEST
		%reven%
cChipFreq	%rw% 1		; frequency sent to the chip
cChipVol	%rb% 1		; volume sent to the chip
	endif

cLoop		%rb% 3		; loop counter values
		%reven%
cSizeSFX =	%re%		; size of each SFX track (this also sneakily makes sure the memory is aligned to word always. Additional loop counter may be added if last byte is odd byte)
cPrio =		%re%-1		; sound effect channel priority. SFX only

	if FEATURE_DACFMVOLENV
cStatPSG4 =	cPanning	; PSG4 type value. PSG3 only
	else
cStatPSG4 =	%re%-2		; PSG4 type value. PSG3 only
	endif
; ---------------------------------------------------------------------------

cGateCur	%rb% 1		; number of frames until note-off. Music only
cGateMain	%rb% 1		; amount of frames for gate effect. Music only
cStack		%rb% 1		; channel stack pointer. Music only
		%rb% 1		; unused. Music only
		%rl% 3		; channel stack data. Music only
		%reven%
cSize =		%re%		; size of each music track
; ===========================================================================
; ---------------------------------------------------------------------------
; Bits for cFlags
; ---------------------------------------------------------------------------

	%rsset% 0
cfbMode =	%re%		; set if in pitch mode, clear if in sample mode. DAC only
cfbRest		%rb% 1		; set if channel is resting. FM and PSG only
cfbInt		%rb% 1		; set if interrupted by SFX. Music only
cfbHold		%rb% 1		; set if note is being held
cfbMod		%rb% 1		; set if modulation is enabled
cfbCond		%rb% 1		; set if condition is false
cfbVol		%rb% 1		; set if channel should update volume
cfbRun =	$07		; set if channel is running a tracker
; ===========================================================================
; ---------------------------------------------------------------------------
; Misc variables for channel modes
; ---------------------------------------------------------------------------

ctbPt2 =	$02		; bit part 2 - FM 4-6
ctFM1 =		$00		; FM 1
ctFM2 =		$01		; FM 2
ctFM3 =		$02		; FM 3	- Valid for SFX
ctFM4 =		$04		; FM 4	- Valid for SFX
ctFM5 =		$05		; FM 5	- Valid for SFX
	if FEATURE_FM6
ctFM6 =		$06		; FM 6
	endif

ctbDAC =	$04		; DAC bit
ctDAC1 =	(1<<ctbDAC)|$03	; DAC 1	- Valid for SFX
ctDAC2 =	(1<<ctbDAC)|$06	; DAC 2

ctPSG1 =	$80		; PSG 1	- Valid for SFX
ctPSG2 =	$A0		; PSG 2	- Valid for SFX
ctPSG3 =	$C0		; PSG 3	- Valid for SFX
ctPSG4 =	$E0		; PSG 4
; ===========================================================================
; ---------------------------------------------------------------------------
; Misc flags
; ---------------------------------------------------------------------------

Mus_DAC =	2		; number of DAC channels
Mus_FM =	5+((FEATURE_FM6<>0)&1); number of FM channels (5 or 6)
Mus_PSG =	3		; number of PSG channels
Mus_Ch =	Mus_DAC+Mus_FM+Mus_PSG; total number of music channels
SFX_DAC =	1		; number of DAC SFX channels
SFX_FM =	3		; number of FM SFX channels
SFX_PSG =	3		; number of PSG SFX channels
SFX_Ch =	SFX_DAC+SFX_FM+SFX_PSG; total number of SFX channels

VoiceRegs =	29		; total number of registers inside of a voice
VoiceTL =	VoiceRegs-4	; location of voice TL levels

MaxPitch =	$1000		; this is the maximum pitch Dual PCM is capable of processing
Z80E_Read =	$0018		; this is used by Dual PCM internally but we need this for macros

; ---------------------------------------------------------------------------
; NOTE: There is no magic trick to making Dual PCM play samples at higher rates.
; These values are only here to allow you to give lower pitch samples higher
; quality, and playing samples at higher rates than Dual PCM can process them
; may decrease the perceived quality by the end user. Use these equates only
; if you know what you are doing.
; ---------------------------------------------------------------------------

sr17 =		$0140		; 5 Quarter sample rate	17500 Hz
sr15 =		$0120		; 9 Eights sample rate	15750 Hz
sr14 =		$0100		; Default sample rate	14000 Hz
sr12 =		$00E0		; 7 Eights sample rate	12250 Hz
sr10 =		$00C0		; 3 Quarter sample rate	10500 Hz
sr8 =		$00A0		; 5 Eights sample rate	8750 Hz
sr7 =		$0080		; Half sample rate	7000 HZ
sr5 =		$0060		; 3 Eights sample rate	5250 Hz
sr3 =		$0040		; 1 Quarter sample rate	3500 Hz
; ===========================================================================
; ---------------------------------------------------------------------------
; Sound driver RAM configuration
; ---------------------------------------------------------------------------

dZ80 =		$A00000		; quick reference to Z80 RAM
dPSG =		$C00011		; quick reference to PSG port

	%rsset% Drvmem		; insert your sound driver RAM address here!
mFlags		%rb% 1		; various driver flags, see below
mCtrPal		%rb% 1		; frame counter fo 50hz fix
mComm		%rb% 8		; communications bytes
mMasterVolFM =	%re%		; master volume for FM channels
mFadeAddr	%rl% 1		; fading program address
mSpeed		%rb% 1		; music speed shoes tempo
mSpeedAcc	%rb% 1		; music speed shoes tempo accumulator
mTempo		%rb% 1		; music normal tempo
mTempoAcc	%rb% 1		; music normal tempo accumulator
mQueue		%rb% 3		; sound queue
mMasterVolPSG	%rb% 1		; master volume for PSG channels
mVctMus		%rl% 1		; address of voice table for music
mMasterVolDAC	%rb% 1		; master volume for DAC channels
mSpindash	%rb% 1		; spindash rev counter
mContCtr	%rb% 1		; continous sfx loop counter
mContLast	%rb% 1		; last continous sfx played
mLastCue	%rb% 1		; last YM Cue the sound driver was accessing
%ralign%
; ---------------------------------------------------------------------------

mBackUpArea =	%re%		; this is where the area to be backed up starts
mDAC1		%rb% cSize	; DAC 1 data
mDAC2		%rb% cSize	; DAC 2 data
mFM1		%rb% cSize	; FM 1 data
mFM2		%rb% cSize	; FM 2 data
mFM3		%rb% cSize	; FM 3 data
mFM4		%rb% cSize	; FM 4 data
mFM5		%rb% cSize	; FM 5 data
	if FEATURE_FM6
mFM6		%rb% cSize	; FM 6 data
	endif
mPSG1		%rb% cSize	; PSG 1 data
mPSG2		%rb% cSize	; PSG 2 data
mPSG3		%rb% cSize	; PSG 3 data
mSFXDAC1	%rb% cSizeSFX	; SFX DAC 1 data
mSFXFM3		%rb% cSizeSFX	; SFX FM 3 data
mSFXFM4		%rb% cSizeSFX	; SFX FM 4 data
mSFXFM5		%rb% cSizeSFX	; SFX FM 5 data
mSFXPSG1	%rb% cSizeSFX	; SFX PSG 1 data
mSFXPSG2	%rb% cSizeSFX	; SFX PSG 2 data
mSFXPSG3	%rb% cSizeSFX	; SFX PSG 3 data
mChannelEnd =	%re%		; used to determine where channel RAM ends
; ---------------------------------------------------------------------------

	if FEATURE_BACKUP
mBackUpLoc =	%re%		; this is where the area for loading a backed up song starts
mBackDAC1	%rb% cSize	; back-up DAC 1 data
mBackDAC2	%rb% cSize	; back-up DAC 2 data
mBackFM1	%rb% cSize	; back-up FM 1 data
mBackFM2	%rb% cSize	; back-up FM 2 data
mBackFM3	%rb% cSize	; back-up FM 3 data
mBackFM4	%rb% cSize	; back-up FM 4 data
mBackFM5	%rb% cSize	; back-up FM 5 data
	if FEATURE_FM6
mBackFM6	%rb% cSize	; back-up FM 6 data
	endif
mBackPSG1	%rb% cSize	; back-up PSG 1 data
mBackPSG2	%rb% cSize	; back-up PSG 2 data
mBackPSG3	%rb% cSize	; back-up PSG 3 data

mBackSpeed	%rb% 1		; back-up music speed shoes tempo
mBackSpeedAcc	%rb% 1		; back-up music speed shoes tempo accumulator
mBackTempo	%rb% 1		; back-up music normal tempo
mBackTempoAcc	%rb% 1		; back-up music normal tempo accumulator
mBackVctMus	%rl% 1		; back-up address of voice table for music
	endif
; ---------------------------------------------------------------------------

	if safe=1
msChktracker	%rb% 1		; safe mode only: If set, bring up debugger
	endif
%ralign%
mSize =		%re%		; end of the driver RAM
; ===========================================================================
; ---------------------------------------------------------------------------
; Bits for mFlags
; ---------------------------------------------------------------------------

	%rsset% 0
mfbSwap		%rb% 1		; if set, the next swap-sfx will be swapped
mfbSpeed	%rb% 1		; if set, speed shoes are active
mfbWater	%rb% 1		; if set, underwater mode is active
mfbNoPAL	%rb% 1		; if set, play songs slowly in PAL region
mfbBacked	%rb% 1		; if set, a song has been backed up
mfbExec		%rb% 1		; if set, AMPS is currently running
mfbRunTwice	%rb% 1		; if set, AMPS should be updated twice at some point
mfbPaused =	$07		; if set, sound driver is paused
; ===========================================================================
; ---------------------------------------------------------------------------
; Sound ID equates
; ---------------------------------------------------------------------------

	%rsset% 1
Mus_Reset	%rb% 1		; reset underwater and speed shoes flags, update volume for all channels
Mus_FadeOut	%rb% 1		; initialize a music fade out
Mus_Stop	%rb% 1		; stop all music
Mus_ShoesOn	%rb% 1		; enable speed shoes mode
Mus_ShoesOff	%rb% 1		; disable speed shoes mode
Mus_ToWater	%rb% 1		; enable underwater mode
Mus_OutWater	%rb% 1		; disable underwater mode
Mus_Pause	%rb% 1		; pause the music
Mus_Unpause	%rb% 1		; unpause the music
Mus_StopSFX	%rb% 1		; stop all sfx
MusOff =	%re%		; first music ID
; ===========================================================================
; ---------------------------------------------------------------------------
; Condition modes
; ---------------------------------------------------------------------------

	%rsset% 0
dcoT		%rb% 1		; condition T	; True
dcoF		%rb% 1		; condition F	; False
dcoHI		%rb% 1		; condition HI	; HIgher (unsigned)
dcoLS		%rb% 1		; condition LS	; Less or Same (unsigned)
dcoHS =		%re%		; condition HS	; Higher or Sane (unsigned)
dcoCC		%rb% 1		; condition CC	; Carry Clear (unsigned)
dcoLO =		%re%		; condition LO	; LOwer (unsigned)
dcoCS		%rb% 1		; condition CS	; Carry Set (unsigned)
dcoNE		%rb% 1		; condition NE	; Not Equal
dcoEQ		%rb% 1		; condition EQ	; EQual
dcoVC		%rb% 1		; condition VC	; oVerflow Clear (signed)
dcoVS		%rb% 1		; condition VS	; oVerflow Set (signed)
dcoPL		%rb% 1		; condition PL	; Positive (PLus)
dcoMI		%rb% 1		; condition MI	; Negamite (MInus)
dcoGE		%rb% 1		; condition GE	; Greater or Equal (signed)
dcoLT		%rb% 1		; condition LT	; Less Than (signed)
dcoGT		%rb% 1		; condition GT	; GreaTer (signed)
dcoLE		%rb% 1		; condition LE	; Less or Equal (signed)
; ===========================================================================
; ---------------------------------------------------------------------------
; Envelope commands equates
; ---------------------------------------------------------------------------

	%rsset% $80
eReset		%rw% 1		; 80 - Restart from position 0
eHold		%rw% 1		; 82 - Hold volume at current level
eLoop		%rw% 1		; 84 - Jump back/forwards according to next byte
eStop		%rw% 1		; 86 - Stop current note and envelope

; these next ones are only valid for modulation envelopes. These are ignored for volume envelopes.
esSens		%rw% 1		; 88 - Set the sensitivity of the modulation envelope
eaSens		%rw% 1		; 8A - Add to the sensitivity of the modulation envelope
eLast =		%re%		; safe mode equate
; ===========================================================================
; ---------------------------------------------------------------------------
; Fade out end commands
; ---------------------------------------------------------------------------

	%rsset% $80
fEnd		%rl% 1		; 80 - Do nothing
fStop		%rl% 1		; 84 - Stop all music
fResVol		%rl% 1		; 88 - Reset volume and update
fReset		%rl% 1		; 8C - Stop music playing and reset volume
fLast =		%re%		; safe mode equate
; ===========================================================================
; ---------------------------------------------------------------------------
; Quickly clear some memory in certain block sizes
;
; input:
;   a4 - Destination address
;   len - Length of clear
;   block - Size of clear block
;
; thrashes:
;   d6 - Set to $xxxxFFFF
;   a4 - Destination address
; ---------------------------------------------------------------------------

dCLEAR_MEM	macro len, block
		move.w	#((%macpfx%len)/(%macpfx%block))-1,d6; load repeat count to d6

.loop%tlbl%
	rept (%macpfx%block)/4
		clr.l	(a4)+		; clear driver and music channel memory
	%endr%
		dbf	d6, .loop%tlbl%	; loop for each longword to clear it

	rept ((%macpfx%len)%mod%(%macpfx%block))/4
		clr.l	(a4)+		; clear extra longs of memory
	%endr%

	if (%macpfx%len)&2
		clr.w	(a4)+		; if there is an extra word, clear it too
	endif
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Quickly read a word from odd address. 28 cycles
; ---------------------------------------------------------------------------

dREAD_WORD	macro areg, dreg
	move.b	(%macpfx%areg)+,(sp)		; read the next byte into stack
	move.w	(sp),%macpfx%dreg		; get word back from stack (shift byte by 8 bits)
	move.b	(%macpfx%areg)+,%macpfx%dreg		; get the next byte into register
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Used to calculate the address of the FM voice bank
;
; input:
;   a1 - Channel address
; output:
;   a4 - Voice table address
; ---------------------------------------------------------------------------

dCALC_BANK	macro off
	lea	VoiceBank+%macpfx%off(pc),a4	; load sound effects voice table into a6
	cmp.w	#mSFXDAC1,a1		; check if this is a SFX channel
	bhs.s	.bank			; if so, branch
	move.l	mVctMus.w,a4		; load music voice table into a1

	if %macpfx%off<>0
		add.w	#%macpfx%off,a4%at%	; add offset into a1
	endif
.bank
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Used to calculate the address of the FM voice
;
; input:
;   d4 - Voice ID
;   a4 - Voice table address
; output:
;   a4 - Voice address
; ---------------------------------------------------------------------------

dCALC_VOICE	macro off
	lsl.w	#5,d4			; multiply voice ID by $20
%narg% >0 off <>
		add.w	#%macpfx%off,d4%at%	; if have had extra argument, add it to offset
	endif

	add.w	d4,a4			; add offset to voice table address
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Tells the Z80 to stop, and waits for it to finish stopping
; ---------------------------------------------------------------------------

stopZ80 	macro
	move.w	#$100,$A11100		; stop the Z80

.loop%tlbl%
	btst	#0,$A11100
	bne.s	.loop%tlbl%			; loop until it says it's stopped
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Tells the Z80 to start again
; ---------------------------------------------------------------------------

startZ80 	macro
	move.w	#0,$A11100		; start the Z80
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Initializes YM writes
;
; output:
;   d6 - YM part
;   d5 - channel type
; ---------------------------------------------------------------------------

InitChYM	macro
	move.b	cType(a1),d6		; get channel type to d6
	move.b	d6,d5			; copy to d5
	and.b	#3,d5			; get only the important part
	lsr.b	#1,d6			; halve part value
	and.b	#2,d6			; clear extra bits away
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Write data to channel-specific YM part
;
; input:
;   d6 - YM part
;   d5 - channel type
;   reg - YM register to write
;   value - value to write
;
; thrashes:
;   d4 - used for register calculation
; ---------------------------------------------------------------------------

WriteChYM	macro reg, value
	move.b	d6,(a0)+		; write part
	move.b	%macpfx%value,(a0)+		; write register value to cue
	move.b	d5,d4			; get the channel offset into d4
	or.b	%macpfx%reg,d4			; or the actual register value
	move.b	d4,(a0)+		; write register to cue
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Write data to YM part 1
; ---------------------------------------------------------------------------

WriteYM1	macro reg, value
	clr.b	(a0)+			; write to part 1
	move.b	%macpfx%value,(a0)+		; write value to cue
	move.b	%macpfx%reg,(a0)+		; write register to cue
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Write data to YM part 2
; ---------------------------------------------------------------------------

WriteYM2	macro reg, value
	move.b	#2,(a0)+		; write to part 2
	move.b	%macpfx%value,(a0)+		; write value to cue
	move.b	%macpfx%reg,(a0)+		; write register to cue
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Macro to check cue address
; ---------------------------------------------------------------------------

CheckCue	macro
	if safe=1
		AMPS_Debug_CuePtr Gen	; check if cue pointer is valid
	endif
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Macro for pausing music
; ---------------------------------------------------------------------------

AMPS_MUSPAUSE	macro			; enable request pause and paused flags
	move.b	#Mus_Pause,mQueue+2.w
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Macro for unpausing music
; ---------------------------------------------------------------------------

AMPS_MUSUNPAUSE	macro			; enable request unpause flag
	move.b	#Mus_Unpause,mQueue+2.w
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Create volume envelope table, and SMPS2ASM equates
; ---------------------------------------------------------------------------

volenv		macro name
%ifasm% AS
	if "name"<>""
v{"name"} =	__venv			; create SMPS2ASM equate
		dc.l vd{"name"}		; create pointer
__venv :=	__venv+1		; increase ID
	shift				; shift next argument into view
	volenv ALLARGS			; process next item
	endif
%endif%
%ifasm% ASM68K
	rept narg			; repeat for all arguments
v\name =	__venv			; create SMPS2ASM equate
		dc.l vd\name		; create pointer
__venv =	__venv+1		; increase ID
	shift				; shift next argument into view
	endr
%endif%
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Create modulation envelope table, and SMPS2ASM equates
; ---------------------------------------------------------------------------

modenv		macro name
%ifasm% AS
	if "name"<>""			; repeate for all arguments
m{"name"} =	__menv			; create SMPS2ASM equate

		if FEATURE_MODENV
			dc.l md{"name"}	; create pointer
		endif

__menv :=	__menv+1		; increase ID
	shift				; shift next argument into view
	modenv ALLARGS			; process next item
	endif
%endif%
%ifasm% ASM68K
	rept narg			; repeate for all arguments
m\name =	__menv			; create SMPS2ASM equate

	if FEATURE_MODENV
		dc.l md\name		; create pointer
	endif

__menv =	__menv+1		; increase ID
	shift				; shift next argument into view
	endr
%endif%
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Include PCM data file
; ---------------------------------------------------------------------------

incSWF		macro file
%ifasm% AS
%narg% >0 file <>			; repeat for all arguments
SWF_file	equ *
		binclude "AMPS/DAC/incswf/file.swf"; include PCM data
SWFR_file	equ *
	 	asdata Z80E_Read*(MaxPitch/$100), $00; add end markers (for Dual PCM)

	shift				; shift next argument into view
	incSWF ALLARGS			; process next item
	endif
%endif%
%ifasm% ASM68K
	rept narg			; repeat for all arguments
SWF_\file	incbin	"AMPS/DAC/incswf/\file\.swf"; include PCM data
SWFR_\file 	dcb.b Z80E_Read*(MaxPitch/$100),$00; add end markers (for Dual PCM)
	shift				; shift next argument into view
	endr
%endif%
    endm
; ===========================================================================
; ---------------------------------------------------------------------------
; Create pointers for a sample
; ---------------------------------------------------------------------------

sample		macro freq, start, loop, name
%narg% >3 name <>			; if we have 4 arguments, we'd like a custom name
d%dlbs%name%dlbe% %equ%	__samp			; use the extra argument to create SMPS2ASM equate
	else
d%dlbs%start%dlbe% %equ%	__samp			; else, use the first one!
	endif

__samp %set%	__samp+1		; increase sample ID

; create offsets for the sample normal, reverse, loop normal, loop reverse.
%ifasm% AS
	if ("start"="Stop")|("start"="STOP")|("start"="stop")
		dc.b [6] 0
%endif%
%ifasm% ASM68K
	if strcmp("\start","Stop")|strcmp("\start","STOP")|strcmp("\start","stop")
		dcb.b 6, 0
%endif%
	else
		dc.b SWF_%macpfx%start&$FF,((SWF_%macpfx%start>>$08)&$7F)|$80,(SWF_%macpfx%start>>$0F)&$FF
		dc.b (SWFR_%macpfx%start-1)&$FF,(((SWFR_%macpfx%start-1)>>$08)&$7F)|$80,((SWFR_%macpfx%start-1)>>$0F)&$FF
	endif

%ifasm% AS
	if ("loop"="Stop")|("loop"="STOP")|("loop"="stop")
		dc.b [6] 0
%endif%
%ifasm% ASM68K
	if strcmp("\loop","Stop")|strcmp("\loop","STOP")|strcmp("\loop","stop")
		dcb.b 6, 0
%endif%
	else
		dc.b SWF_%macpfx%loop&$FF,((SWF_%macpfx%loop>>$08)&$7F)|$80, (SWF_%macpfx%loop>>$0F)&$FF
		dc.b (SWFR_%macpfx%loop-1)&$FF,(((SWFR_%macpfx%loop-1)>>$08)&$7F)|$80,((SWFR_%macpfx%loop-1)>>$0F)&$FF
	endif

	dc.w %macpfx%freq-$100			; sample frequency (actually offset, so we remove $100)
	dc.w 0				; unused!
    endm
%ifasm% AS
; ===========================================================================
; ---------------------------------------------------------------------------
; Workaround the ASS bug where you ca only put 1024 bytes per line of code
; ---------------------------------------------------------------------------

asdata		macro count, byte
.c :=		(count)
	while .c > $400
		dc.b [$400] byte
.c :=		.c - $400
	endm

	if .c > 0
		dc.b [.c] byte
	endif
    endm
; ---------------------------------------------------------------------------

	!org 0
	%rsset% 0
%endif%
%ifasm% ASM68K
; ---------------------------------------------------------------------------

	opt ae-
%endif%
