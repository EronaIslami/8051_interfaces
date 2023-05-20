;----pinat e MCP3208-----
CLK EQU P1.0
DIN EQU P1.1; digital input
DOUT EQU P1.2
CS EQU P1.3
;---/pinat e MCP3208------
;msb ruhet ne 2AH
;lsb ruhet ne 2BH
ORG 0000H

MOSTRO:
CLR CLK ;clock idles low
NOP
CLR CS ;selektohet pajisja

SETB DIN ;Start biti
SETB CLK ;Tehu renes
NOP
CLR CLK

SETB CLK ;Dergohet SGL biti ne tehun renes
NOP
CLR CLK

CLR DIN 
SETB CLK ;Dergohet D2 ne tehun renes
NOP
CLR CLK
NOP
SETB CLK ;Dergohet D1 ne tehun renes
NOP
CLR CLK
NOP
SETB CLK ;Dergohet D0 ne tehun renes
NOP
CLR CLK
NOP
SETB CLK 
NOP
CLR CLK ;Tehu renes,del NULL bit

MOV A,#00H
MOV R0,#05D; 4 + NULL BIT

LOOP:      ;D11,D10,D9,D8
SETB DOUT
MOV C,DOUT
RLC A
SETB CLK
NOP
CLR CLK
DJNZ R0,LOOP
MOV 2AH,A


MOV A,#00H
MOV R0,#08D

LOOP0:      ;D7 - D0
SETB DOUT
MOV C,DOUT
RLC A
SETB CLK
NOP
CLR CLK
DJNZ R0,LOOP0
MOV 2BH,A

SETB CS
RET

END