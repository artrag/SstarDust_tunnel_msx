	output stardust64.rom
	
	defpage 0,0x0000,0x4000
	defpage 1,0x4000,0x4000
	defpage 2,0x8000,0x4000
	defpage 3,0x8000,0x4000

; ------------------------------

	incdir	mus
	incdir	miz

; ------------------------------
	code page 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include macros.asm	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	code
checkkbd:
	in	a,(0aah)
	and 011110000B			; upper 4 bits contain info to preserve
	or	e
	out (0aah),a
	in	a,(0a9h)
	ld	l,a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	code	
write_256:
	ld	bc,0x0098
[8]	otir
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	code		
enascr:
	ld	   a,(_vdpReg + 1)
	or	   #40
	jr	   1f
disscr:
	ld	   a,(_vdpReg + 1)
	and	   #bf
1:	out	   (#99),a
	ld	   (_vdpReg + 1),a
	ld	   a,1 + 128
	out	   (#99),a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	code	
setwrtvram:
	di
	ld	a,e
	out (0x99),a
	ld	a,d
	or 0x40
	out (0x99),a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write 2K while ints are active from miz_buffer
; in: de vram address, hl ram address
	code	
write_2k:
	ex	de,hl
	set	6,h
	ld	c,0x99
	push	de
	ld	de,16
	exx
	pop		hl		; ld	hl,miz_buffer
	ld 	e,127
	ld	c,0x98
2:	di
	exx
	out (c),l
	out (c),h	;c' = 0x99, HL' with write setup bit set
	add hl,de	;de' = 16
	exx
	ld b,16
1:	outi		;c = 0x98
	jp nz,1b
	ei
	dec e
	jp nz,2b
	ret
	code @ 0x0038
isr:
	push   hl         
	push   de         
	push   bc         
	push   af         
	push   iy         
	push   ix         
	in	a,(0x99)
	pop    ix         
	pop    iy         
	pop    af         
	pop    bc         
	pop    de         
	pop    hl         
	ei
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include mizer.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 110 BLOAD "data0.bin",S,&H0800:BLOAD "data1.bin",S,&H1000
; 120 BLOAD "data2.bin",S,&H1800:BLOAD "data3.bin",S,&H2000
; 130 BLOAD "data4.bin",S,&H2800:BLOAD "data5.bin",S,&H3000
	incdir	basic

d0:		incbin data0.bin
d1:		incbin data1.bin	
d2:		incbin data2.bin
d3:		incbin data3.bin
d4:		incbin data4.bin
d5:		incbin data5.bin
vraminit:
	ld	hl,d0+7
	ld	de,0x0800
	call	write_2k
	ld	hl,d1+7
	ld	de,0x1000
	call	write_2k
	ld	hl,d2+7
	ld	de,0x1800
	call	write_2k
	ld	hl,d3+7
	ld	de,0x2000
	call	write_2k
	ld	hl,d4+7
	ld	de,0x2800
	call	write_2k
	ld	hl,d5+7
	ld	de,0x3000
	call	write_2k
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
joy_read:
	di
	push	ix
	ld	a,(joystick)
	ld	(old_joystick),a
	call	.rd_joy
	ld	a,(joystick)
	ld	b,a
	ld	a,(old_joystick)
	xor	b
	and	b
	ld	(chang_joystick),a
	pop		ix
	ei
	ret
; PSG I/O port A (r#14) – read-only
; Bit	Description	Comment
; 0	Input joystick pin 1	(up)
; 1	Input joystick pin 2	(down)
; 2	Input joystick pin 3	(left)
; 3	Input joystick pin 4	(right)
; 4	Input joystick pin 6	(trigger A)
; 5	Input joystick pin 7	(trigger B)
; 6	Japanese keyboard layout bit	(1=JIS, 0=ANSI)
; 7	Cassette input signal	

.rd_joy:
	ld	a,#0f
	out	(#a0),a
	ld	a,0x8F
	out	(#a1),a		; select port A
	ld	a,#0e
	out	(#a0),a
	in	a,(#a2)
.rd_key:	
	ld	ix,joystick
	ld	(ix),a
	
	ld  e,8
    call    checkkbd
	bit	0,a				; space
	jr	nz,1f
	res	4,(ix)			; (trigger A)
1:
	bit	7,a				; RIGHT
	jr	nz,1f
	res	3,(ix)			; (right joy)
1:
	bit	6,a				; DOWN
	jr	nz,1f
	res	1,(ix)			; (down joy)
1:
	bit	5,a				; UP
	jr	nz,1f
	res	0,(ix)			; (up joy)
1:
	bit	4,a				; LEFT
	jr	nz,1f
	res	2,(ix)			; (left joy)
1:
	ld  e,5
    call    checkkbd
	bit	5,a				; X
	jr	nz,1f
	res	5,(ix)			; (trigger B)
1:
	bit	7,a				; Z
	jr	nz,1f
	res	4,(ix)			; (trigger A)
1:
	ret

	
	
;    5   |    Z     Y     X     W     V     U     T     S
;    6   |   F3    F2    F1   CODE   CAP  GRAPH CTRL  SHIFT
;    7   |   RET   SEL   BS   STOP   TAB   ESC   F5    F4
;    8   |  RIGHT DOWN   UP   LEFT   DEL   INS  HOME  SPACE
.z_or_space:
	ld	a,(joystick)
	and	16
	ret
.x_and_up:
	ld	a,(joystick)
	and	32
	ret	nz
.up:
	ld	a,(joystick)
	and	1
	ret
.x_and_dwn:
	ld	a,(joystick)
	and	32
	ret	nz
.dwn:
	ld	a,(joystick)
	and	2
	ret
.left:
	ld	a,(joystick)
	and	4
	ret
.right:
	ld	a,(joystick)
	and	8
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
xstep equ 2
	
	code @	4000h,page 1
rom_header:
	db "AB"		; rom header
    dw initmain
    ds    12
    dz 'TRI005'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include rominit64.asm	
	include PT3-ROM.ASM
	include AYFX-ROM.ASM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	INCLUDE SCCaudio.asm
	INCLUDE SCCWAVES.ASM
	INCLUDE SCCDETEC.ASM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mus_mute:
    ds 16,0
	incbin UR_mute.BIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sfxBank_miz:
    incbin	sfx.miz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
initmain:
	ld	a,(_vdpReg+1)
	or 2
	ld	(_vdpReg+1),a
	
	ld	a,3
	call 0x005f
	ld sp,0F380h		; place manually the stack

	di
	call	search_slotram	; look for the ram slot 
	call	search_slot		; look for the slot of our rom

	ld	a,(slotram)
	ld	i,a					; save for later use
	
	;---------------------
	call	setrampage2		; set ram in page 2
	ld sp,0C000h			; place manually the stack
	call	setrompage3		; set rom in page 3 <- old ram data cannot be accessed
	;---------------------

	ld	hl,0xC000			; now page 3 is in 0x8000-0xBFFF
	ld	de,0x8000
	ld	bc,0x4000
	ldir
	
	;---------------------
	ld		a,i				; recover ram in page 3
	call	setslotpage3	; NB two bytes at the end of the page get corrupted by this call!
	ld sp,0F380h			; place manually the stack
	call	setrompage2		; set rom in page 2
	;---------------------
	
enpage2 equ	setrompage2
enpage3 equ	setrampage2

	call	setrompage0		; 48K of rom are active - bios is excluded
							; from here interrupts are disabled
	call	vraminit
	
	setVdp 7,0x00;	VDP(7)=0:
	
	setVdp 2,0x00;	VDP(2)=0:
	setVdp 5,0x06;	VDP(5)=&H06:'SAT = &H0300
	setVdp 6,0x07;	VDP(6)=7:	'SPT = &h3800
	
	;VPOKE &H0300,&HD0
	setvdpwvram 0x0300
	ld	a,0xD0
	out	(0x98),a
	
	setvdpwvram 0x03800
	ld	b,32
	ld	a,-1
1:	out	(0x98),a
	djnz 1b
	
	xor	a
	ld	(xmap),a
	inc	a
	ld	(dxmap),a
	ld	hl,0
	ld	(xship),hl
	
	;FORI=1TO6:GOSUB240:VDP(4)=I:NEXT
		
main_loop:	
[2]	halt
	setVdp 4,(dxmap)	
	call vramupdate
	
	
	setvdpwvram 0x0300
	ld	a,96-8
	out	(0x98),a
	ld	a,(xship)
	out	(0x98),a
	ld	a,0
	out	(0x98),a
	ld	a,15
	out	(0x98),a
	ld	a,0xD0
	out	(0x98),a

	
	ld	a,(dxmap)
	inc	a
	cp	6
	jr	nz,2f
	ld	a,1
2:	ld	(dxmap),a

	call	joy_read.rd_joy
	ld	a,(joystick)
	bit	3,a			; right 
	call nz,dec_xoff
	ld	a,(joystick)
	bit	2,a			; left 
	call nz,inc_xoff

	jp main_loop
inc_xoff:
	ld	a,(xship)
	add	a,xstep
	cp 240
	ret	nc
	ld	(xship),a
	and	15
	ret	nz
	ld	a,(xmap)
	inc	a
	cp	10
	ret	z
	ld	(xmap),a
	ret
dec_xoff:
	ld	a,(xship)
	sub a,xstep
	ret	c
	ld	(xship),a
	and	15
	ret	nz
	ld	a,(xmap)
	dec	a
	cp	-1
	ret	z
	ld	(xmap),a
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FORK=0TO5:FORI=0TO3:FORJ=0TO31:VPOKEN,M+J:N=N+1:NEXT:NEXT:M=M+42:NEXT

;150 VDP(2)=0:VDP(5)=&H2C:VDP(6)=0:N=0:M=0
;160 FORK=0TO5:
;		FORI=0TO3:
;			FORJ=0TO31:
;				VPOKEN,M+J:N=N+1
;			NEXT:
;		NEXT:
;		M=M+42:
;	NEXT
;170 VPOKE &H1600,&HD0:' remove sprites


vramupdate:
	setvdpwvram  0x0000
	ld	d,6
	ld	a,(xmap)
1:	ld	c,a
[4]	call .setline
	ld	a,42
	add	a,c
	dec d
	jr nz,1b
	ret
	

.setline
	ld	a,c
	ld	b,32
1:	out	(0x98),a
	inc	a
	djnz 1b
	ret
	

d0m:		incbin data0.miz
d1m:		incbin data1.miz	
d2m:		incbin data2.miz
d3m:		incbin data3.miz
d4m:		incbin data4.miz
d5m:		incbin data5.miz

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
MSX_O_Mizer_buf:	equ	0xFe00	; ds	328+26 aligned at 0x100
ram_sat:			equ	0xfd09	; ds	128
ram_tileset:		equ	0xf87f	; ds	128*8 
slotvar:			equ	0xFFC5
slotram:			equ 0xFFC6
SCC:				equ	0xFFC7
curslot:			equ	0xFFC8
music_flag:			equ	0xFFC9

	map 0xC000
meta_pnt_table_u:	#	1024
meta_pnt_table_d:	#	1024
miz_buffer:			#	3*1024

level_buffer:		#	1

toshiba_switch		#	1		; Toshiba
game_speed:			#	1		; game speed 1,2,3,4
victory:			#	1		
visible_sprts:		#	1
ingame:				#	1
aniframe:			#	1
old_aniframe:		#	1

ms_state:			#	1
anispeed:			#	1

enable_cheat		#	1

PT3_SETUP:			#	1	;set bit0 to 1, if you want to play without looping
					        ;bit7 is set each time, when loop point is passed
PT3_MODADDR:		#	2
PT3_CrPsPtr:		#	2  ; Patter# = CrPsPtr-song_buffer-101;
PT3_SAMPTRS:		#	2
PT3_OrnPtrs:		#	2
PT3_PDSP:			#	2
PT3_CSP:			#	2
PT3_PSP:			#	2
PT3_PrNote:			#	1
PT3_PrSlide:		#	2
PT3_AdInPtA:		#	2
PT3_AdInPtB:		#	2
PT3_AdInPtC:		#	2
PT3_LPosPtr:		#	2
PT3_PatsPtr:		#	2
PT3_Delay:			#	1
PT3_AddToEn:		#	1
PT3_Env_Del:		#	1
PT3_ESldAdd:		#	2

VARS: 				#	0
ChanA:				#	30			;CHNPRM_Size
ChanB:				#	30			;CHNPRM_Size
ChanC:				#	30			;CHNPRM_Size

;GlobalVars
DelyCnt:			#	1
CurESld:			#	2
CurEDel:			#	1

Ns_Base_AddToNs:	
Ns_Base:			#	1
AddToNs:			#	1

AYREGS:     		#	0
VT_:				#	14
EnvBase:			#	2
VAR0END:			#	240

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Helper variables from PT3 mobule
; scc patch

_psg_vol_fix:		#	1
_sfx_vol_fix:		#	1
_scc_vol_fix:		#	1

fade_psg_vol_fix:	#	1
fade_scc_vol_fix:	#	1

_psg_vol_balance:	#	2
_scc_vol_balance:	#	2

AYREGS_CPY:			#	13
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wchA:				#	1	; wave on channel A
wchB:				#	1	; wave on channel B
wchC:				#	1	; wave on channel C
; pt3 samples previously detected (times 2)
OSmplA          	#	1
OSmplB          	#	1
OSmplC          	#	1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_waves				#	16

reverse_sat:		#	1


		; --- THIS FILE MUST BE COMPILED IN RAM ---

		; --- PT3 WORKAREA [self-modifying code patched] ---

    ; global _ayFX_PRIORITY
ayFX_PRIORITY:		#	1			; Current ayFX stream priority

		; --- THIS FILE MUST BE COMPILED IN RAM ---

ayFX_PLAYING:	#	1			; There's an ayFX stream to be played?
ayFX_CURRENT:	#	1			; Current ayFX stream playing
ayFX_POINTER:	#	2			; Pointer to the current ayFX stream
ayFX_TONE:	    #	2			; Current tone of the ayFX stream
ayFX_NOISE: 	#	1			; Current noise of the ayFX stream
ayFX_VOLUME:	#	1			; Current volume of the ayFX stream
ayFX_CHANNEL:	#	1			; PSG channel to play the ayFX stream
ayFX_VT:		#	2			; ayFX relative volume table pointer



				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vsf:         		#	1          ; 0 if 50Hz, !0 if 60Hz
cnt:         		#	1          ; counter to compensate NTSC machines
ayend:				#	0
randSeed:			#	2

assault_wave_timer:	# 	2
wave_count:			#	1
landing_permission:	#	1
bullet_rate:		#	1
dxmap:				#	1
xmap:				#	2
yship:				#	1
xship:				#	2
cur_level:			#	1
next_level:			#	1
sprite_3c:			#	1
clr_table			#	2
joystick:			#	1
old_joystick:		#	1
chang_joystick:		#	1
menu_item:			#	1
already_dead:		#	1	; set after you die, reset at level start 

god_mode			#	1
halt_game:			#	1
menu_level:			#	0
halt_gamef1:		#	1
lives:				#	3
dummy_:				#	4
score:				#	7
score_bin:			#	4
lives_bin:			#	1	; BCD !!!

toggle_scc			#	1
save_SCC			#	1
	
	struct enemy_data
y				db	0
x				dw	0
xoff			db	0
yoff			db	0
xsize			db	0
ysize			db	0
status			db	0	; B7 == DWN/UP | B6 == RIGHT/LEFT | B0 == Inactive/Active
cntr			db	0
kind			db	0
frame			db	0
color			db	0
speed			dw	0
	ends
	
max_enem 			equ	1
max_bullets			equ 1
max_enem_bullets 	equ 1

; [max_enem]			enemy_data
; [max_bullets]		enemy_data
; [max_enem_bullets]	enemy_data

enemies:		#	enemy_data*max_enem
ms_bullets:		#	enemy_data*max_bullets
enem_bullets:	#	enemy_data*max_enem_bullets

	
	endmap
	