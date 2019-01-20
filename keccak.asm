; Keccak 256 cryptographic hash for Zilog Z80 processors
; Written by Daniel A. Nagy <nagydani@epointsystem.org> in 2019

; Init
; Pollutes: AF,BC,DE,HL
KECCAKI:LD	HL,KECCAKS
	LD	E,L
	LD	D,H
	INC	DE
	LD	(HL),0
	LD	BC,199
	LDIR
	JR	KECCAKQ

; Update
; In: A next byte to hash
; Pollutes: AF, AF', BC, BC', DE, DE', HL, HL', IX
KECCAKU:LD	HL,(KECCAKP)
	LD	H,KECCAKS / 0x100
	XOR	(HL)
	LD	(HL),A
	LD	A,L
	INC	A
	CP	KECCAKS - 0x100 * (KECCAKS / 0x100) + 0x88
	LD	(KECCAKP),A
	RET	C
	CALL	KECCAKF
KECCAKQ:LD	A,KECCAKS - 0x100 * (KECCAKS / 0x100)
	LD	(KECCAKP),A
	RET

; Finalize
; Out: hash value beginning at KECCAKS
; Pollutes: AF, AF', BC, BC', DE, DE', HL, HL', IX
KECCAK:	LD	HL,(KECCAKP)
	LD	H,KECCAKS / 0x100
	LD	A,1
	XOR	(HL)
	LD	(HL),A
	LD	A,(KECCAKS + 0x87)
	XOR	0x80
	LD	(KECCAKS + 0x87),A
; Shuffle
KECCAKF:LD	B,24
KECCAKL:PUSH	BC
; Theta
THETA:	LD	HL,KECCAKB
	LD	IX,KECCAKS+100
	LD	B,40
THETAL1:LD	A,(IX-100)
	XOR	(IX-60)
	XOR	(IX-20)
	XOR	(IX+20)
	XOR	(IX+60)
	LD	(HL),A
	INC	L
	DEFB	0xDD
	INC	L	; INC IXL
	DJNZ	THETAL1
	LD	D,H
	LD	B,5
	XOR	A
THETAL2:ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	L,A
	LD	E,40
	LD	C,E	; Prevent LDI from decrementing B
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LD	L,KECCAKB - 0x100 * (KECCAKB / 0x100) + 47
	LD	A,(HL)
	ADD	A,A
	LD	L,KECCAKB - 0x100 * (KECCAKB / 0x100) + 40
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
THETAR:	LD	A,B
	SUB	2
	JP	P,THETAP
	LD	A,4
THETAP:	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	E,A
	LD	L,KECCAKB - 0x100 * (KECCAKB / 0x100) + 40
	LD	C,B
	LD	B,8
THETALX:LD	A,(DE)
	XOR	(HL)
	LD	(HL),A
	INC	L
	INC	E
	DJNZ	THETALX
	LD	B,8
THETAL3:DEFB	0xDD
	DEC	L	; DEC IXL
	DEC	L
	LD	E,(HL)
	LD	A,(IX-100)
	XOR	E
	LD	(IX-100),A
	LD	A,(IX-60)
	XOR	E
	LD	(IX-60),A
	LD	A,(IX-20)
	XOR	E
	LD	(IX-20),A
	LD	A,(IX+20)
	XOR	E
	LD	(IX+20),A
	LD	A,(IX+60)
	XOR	E
	LD	(IX+60),A
	DJNZ	THETAL3
	LD	B,C
	DEC	B
	LD	A,B
	JR	NZ,THETAL2
; Rho & Pi
RHOPI:	LD	L,KECCAKS - 0x100 * (KECCAKS/0x100) + 8
	LD	E,B
	LD	C,8
	LDIR
	EXX
	LD	HL,RHOPIT - RHOPITE
	LD	BC,RHOPITE - RHOPIT
	ADD	HL,SP
	LD	SP,HL
	EX	DE,HL
	LD	HL,RHOPIT
	LDIR		; Stack RHOPIT
RHOPIL:	EXX
	POP	HL	; Pi table lookup
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	EXX
	RET		; Rho table lookup
RHOPIR:	DEFB	0x3E	; LD A,x
	XOR	A
	EXX
	EX	DE,HL
	LD	L,7
	DEC	E
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LD	DE,KECCAKB
	LD	HL,KECCAKB+8
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	EXX
	OR	A
	JR	NZ,RHOPIL
; Chi
CHI:	LD	L,KECCAKS - 0x100 * (KECCAKS/0x100) - 40
	LD	B,5
CHIL0:	PUSH	BC
	LD	E,KECCAKB - 0x100 * (KECCAKB/0x100)
	LD	BC,40
	ADD	HL,BC
	LDIR
	LD	IX,KECCAKB + 40	; Same as DE, but it is faster this way
	LD	B,8
CHIL3:	DEC	L
	DEFB	0xDD
	DEC	L	; DEC IXL
	LD	A,(IX - 0x20)
	CPL
	AND	(IX - 0x18)
	XOR	(HL)
	LD	(HL),A
	DJNZ	CHIL3
	LD	B,8
CHIL2:	DEC	L
	DEFB	0xDD
	DEC	L	; DEC IXL
	LD	A,(IX + 0x08)
	CPL
	AND	(IX - 0x18)
	XOR	(HL)
	LD	(HL),A
	DJNZ	CHIL2
	LD	B,24
CHIL1:	DEC	L
	DEFB	0xDD
	DEC	L	; DEC IXL
	LD	A,(IX + 0x08)
	CPL
	AND	(IX + 0x10)
	XOR	(HL)
	LD	(HL),A
	DJNZ	CHIL1
	POP	BC
	DJNZ	CHIL0
; Iota
IOTA:	LD	D,KECCAKS / 0x100
	POP	BC
	LD	A,B
	ADD	A,A
	ADD	A,A
	LD	L,A	; E = B * 4
	LD	H,IOTAT / 0x100
	LD	E,KECCAKS - 0x100 * (KECCAKS / 0x100) + 7
	LD	A,(DE)
	XOR	(HL)
	LD	(DE),A
	INC	L
	LD	E,KECCAKS - 0x100 * (KECCAKS / 0x100) + 3
	LD	A,(DE)
	XOR	(HL)
	LD	(DE),A
	INC	L
	LD	E,KECCAKS - 0x100 * (KECCAKS / 0x100) + 1
	LD	A,(DE)
	XOR	(HL)
	LD	(DE),A
	INC	L
	LD	E,KECCAKS - 0x100 * (KECCAKS / 0x100) + 0
	LD	A,(DE)
	XOR	(HL)
	LD	(DE),A
	DEC	B
	JP	NZ,KECCAKL
	RET

; Cyclic 64 bit rotation helper functions
; Pollutes: AF, AF', BC, DE, HL

ROTL18:	CALL	ROTL16		; 16 + 1 + 1
	JR	ROTL2

ROTL6:	CALL	ROTL4		; 4 + 1 + 1
ROTL2:	CALL	ROTL1		; 1 + 1
ROTL1:	LD	HL,KECCAKB
	SLA	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	INC	L
	RL	(HL)
	LD	L,0
	RET	NC
	SET	0,(HL)
	RET

ROTL14:	CALL	ROTL16		; 16 - 1 - 1
ROTL62:	CALL	ROTR1		; 64 - 1 - 1
ROTR1:	LD	A,(KECCAKB)
	RRA
	LD	HL,KECCAKB+7
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	DEC	L
	RR	(HL)
	RET

ROTL27:	CALL	ROTL24		; 24 + 4 - 1
ROTL3:	CALL	ROTR1		; 4 - 1
ROTL4:	LD	HL,KECCAKB
	XOR	A
	RLD
	INC	L
	RLD
	INC	L
	RLD
	INC	L
	RLD
	INC	L
	RLD
	INC	L
	RLD
	INC	L
	RLD
	INC	L
	RLD
	LD	L,0
	OR	(HL)
	LD	(HL),A
	RET

ROTL61:	CALL	ROTL1		; 64 - 4 + 1
ROTR4:	LD	A,(KECCAKB)
	LD	HL,KECCAKB+7
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	DEC	L
	RRD
	RET

ROTL10:	CALL	ROTL2		; 8 + 1 + 1
ROTL8:	LD	HL,KECCAKB+7
	LD	E,L
	LD	D,H
	LD	A,(HL)
	DEC	L
	LDD	; Faster than LDDR
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LD	(DE),A
	RET

ROTL55:	CALL	ROTR1		; 64 - 8 - 1
ROTL56:	EQU	$		; 64 - 8
ROTR8:	LD	HL,KECCAKB
	LD	A,(HL)
	LD	E,L
	LD	D,H
	INC	L
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LD	(DE),A
	RET

ROTL15:	CALL	ROTR1		; 16 - 1
	JR	ROTL16

ROTL21:	CALL	ROTL1		; 16 + 4 + 1
ROTL20:	CALL	ROTL4		; 16 + 4
ROTL16:	LD	HL,KECCAKB+7
	LD	C,0xFF
	LD	E,L
	LD	D,H
	LD	A,(HL)
	DEC	L
	LD	B,(HL)
	DEC	L
	LDD
	LDD
	LDD
	LDD
	LDD
	LDD
	LD	L,E
	LD	H,D
	LD	(HL),A
	DEC	L
	LD	(HL),B
	RET

ROTL43:	CALL	ROTR1		; 64 - 16 - 4 - 1
	JR	ROTL44

ROTL45:	CALL	ROTL1		; 64 - 16 - 4 + 1
ROTL44:	CALL	ROTR4		; 64 - 16 - 4
ROTR16:	LD	HL,KECCAKB
	LD	C,0xFF
	LD	A,(HL)
	LD	E,L
	LD	D,H
	INC	L
	LD	B,(HL)
	INC	L
	LDI
	LDI
	LDI
	LDI
	LDI
	LDI
	LD	L,E
	LD	(HL),A
	INC	L
	LD	(HL),B
	RET

ROTL25:	CALL	ROTL1		; 24 + 1
	JR	ROTL24

ROTL28:	CALL	ROTL4		; 24 + 4
ROTL24:	LD	HL,KECCAKB+7
	LD	C,0xFF
	LD	E,L
	LD	D,H
	LD	A,(HL)
	DEC	L
	EX	AF,AF'
	LD	A,(HL)
	DEC	L
	LD	B,(HL)
	DEC	L
	LDD
	LDD
	LDD
	LDD
	LDD
	LD	L,E
	LD	H,D
	EX	AF,AF'
	LD	(HL),A
	DEC	L
	EX	AF,AF'
	LD	(HL),A
	DEC	L
	LD	(HL),B
	RET

ROTL39:	CALL	ROTR1		; 64 - 24 - 1
	JR	ROTR24

ROTL41:	CALL	ROTL1		; 64 - 24 + 1
ROTR24:	LD	HL,KECCAKB
	LD	C,0xFF
	LD	A,(HL)
	LD	E,L
	LD	D,H
	INC	L
	EX	AF,AF'
	LD	A,(HL)
	INC	L
	LD	B,(HL)
	INC	L
	LDI
	LDI
	LDI
	LDI
	LDI
	LD	L,E
	EX	AF,AF'
	LD	(HL),A
	INC	L
	EX	AF,AF'
	LD	(HL),A
	INC	L
	LD	(HL),B
	RET

ROTL36:	CALL	ROTL4		; 32 + 4
ROT32:	LD	HL,KECCAKB
	LD	DE,KECCAKB+4
	LD	A,(DE)
	LDI
	DEC	L
	LD	(HL),A
	INC	L
	LD	A,(DE)
	LDI
	DEC	L
	LD	(HL),A
	INC	L
	LD	A,(DE)
	LDI
	DEC	L
	LD	(HL),A
	INC	L
	LD	A,(DE)
	LDI
	DEC	L
	LD	(HL),A
	RET

RHOPIT:	DEFW	KECCAKS + 10 * 8
	DEFW	ROTL1,RHOPIR
	DEFW	KECCAKS + 7 * 8
	DEFW	ROTL3,RHOPIR
	DEFW	KECCAKS + 11 * 8
	DEFW	ROTL6,RHOPIR
	DEFW	KECCAKS + 17 * 8
	DEFW	ROTL10,RHOPIR
	DEFW	KECCAKS + 18 * 8
	DEFW	ROTL15,RHOPIR
	DEFW	KECCAKS + 3 * 8
	DEFW	ROTL21,RHOPIR
	DEFW	KECCAKS + 5 * 8
	DEFW	ROTL28,RHOPIR
	DEFW	KECCAKS + 16 * 8
	DEFW	ROTL36,RHOPIR
	DEFW	KECCAKS + 8 * 8
	DEFW	ROTL45,RHOPIR
	DEFW	KECCAKS + 21 * 8
	DEFW	ROTL55,RHOPIR
	DEFW	KECCAKS + 24 * 8
	DEFW	ROTL2,RHOPIR
	DEFW	KECCAKS + 4 * 8
	DEFW	ROTL14,RHOPIR
	DEFW	KECCAKS + 15 * 8
	DEFW	ROTL27,RHOPIR
	DEFW	KECCAKS + 23 * 8
	DEFW	ROTL41,RHOPIR
	DEFW	KECCAKS + 19 * 8
	DEFW	ROTL56,RHOPIR
	DEFW	KECCAKS + 13 * 8
	DEFW	ROTL8,RHOPIR
	DEFW	KECCAKS + 12 * 8
	DEFW	ROTL25,RHOPIR
	DEFW	KECCAKS + 2 * 8
	DEFW	ROTL43,RHOPIR
	DEFW	KECCAKS + 20 * 8
	DEFW	ROTL62,RHOPIR
	DEFW	KECCAKS + 14 * 8
	DEFW	ROTL18,RHOPIR
	DEFW	KECCAKS + 22 * 8
	DEFW	ROTL39,RHOPIR
	DEFW	KECCAKS + 9 * 8
	DEFW	ROTL61,RHOPIR
	DEFW	KECCAKS + 6 * 8
	DEFW	ROTL20,RHOPIR
	DEFW	KECCAKS + 1 * 8
	DEFW	ROTL44,RHOPIR+1
RHOPITE:EQU	$

