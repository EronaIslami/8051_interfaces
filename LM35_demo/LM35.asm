;---pinat e LCD----
RS EQU P2.0
EN EQU P2.1
;---/pinat e LCD----

;----pinat e MCP3208-----
CLK EQU P1.0
DIN EQU P1.1; digital input
DOUT EQU P1.2
CS EQU P1.3
;---/pinat e MCP3208------
FREQUENCY_DIVISOR EQU 30H

ORG 0000H
LJMP MAIN

ORG 000BH
PUSH 0E0H ;ACC
PUSH 0D0H ;PSW

SETB P3.0
MOV C,P3.0
MOV 60H,C
LCALL SHFAQJA_DISPLAY ;duhet me thirr ne interrupt rutinen per shfaqje

DJNZ FREQUENCY_DIVISOR, END_T0_ISR
MOV FREQUENCY_DIVISOR,#4D
LCALL CALCULATE_DATA ;cdo 1ms  

END_T0_ISR:

POP 0D0H 
POP 0E0H 
RETI


MAIN:
;--------main---------
MOV FREQUENCY_DIVISOR,#4D
MOV IE,#82H
MOV TMOD,#02H
MOV TH0,#6D
MOV TL0,#6D
SETB TR0
SETB 60H

LCALL LCD_INITIALIZATION

;shkruaj shkronjat me ascii code:
MOV A,#'T'
LCALL LCD_WRITE_DATA 
MOV A,#'E'
LCALL LCD_WRITE_DATA
MOV A,#'M'
LCALL LCD_WRITE_DATA
MOV A,#'P'
LCALL LCD_WRITE_DATA
MOV A,#'E'
LCALL LCD_WRITE_DATA
MOV A,#'R'
LCALL LCD_WRITE_DATA
MOV A,#'A'
LCALL LCD_WRITE_DATA
MOV A,#'T'
LCALL LCD_WRITE_DATA
MOV A,#'U'
LCALL LCD_WRITE_DATA
MOV A,#'R'
LCALL LCD_WRITE_DATA
MOV A,#'A'
LCALL LCD_WRITE_DATA
MOV A,#':'
LCALL LCD_WRITE_DATA

MOV A,#0C0H ;force cursor to beginning (2nd line)
LCALL LCD_WRITE_COMMAND 

;----main---
SJMP $

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


LCD_CLEAR:
MOV A,#01H
LCALL LCD_WRITE_COMMAND
LCALL DELAY3MS
RET

LCD_INITIALIZATION:
MOV A,#38H ;16x2 matrix
LCALL LCD_WRITE_COMMAND

MOV A,#0FH ;cursor blinking
LCALL LCD_WRITE_COMMAND

MOV A,#80H ;force cursor to 2nd line
LCALL LCD_WRITE_COMMAND
RET

LCD_WRITE_DATA: ;the subroutine to write a byte of data in LCD
SETB RS
LCALL LCD_FREQUENCY_DELAY
SETB EN
LCALL LCD_FREQUENCY_DELAY
MOV P0,A
CLR EN
LCALL LCD_FREQUENCY_DELAY
RET

LCD_WRITE_COMMAND: ;the subroutine to write a command in LCD
CLR RS
LCALL LCD_FREQUENCY_DELAY
SETB EN
LCALL LCD_FREQUENCY_DELAY
MOV P0,A
CLR EN
LCALL LCD_FREQUENCY_DELAY
RET

DELAY3MS: ;delay necessary for LCD's "clear display" command
MOV R0,#255D
LOOP12:
MOV R2,#6D
DJNZ R2,$
DJNZ R0,LOOP12
RET

LCD_FREQUENCY_DELAY: ;delay necessary for LCD's working frequency
MOV R0,#7D
DJNZ R0,$
RET


DIV_16BIT_BY_7BIT:
MOV R4,#00H
MOV R5,#00H

MOV R3,#17D ;rotate bits 17 times
TRY_TO_DIVIDE:
LCALL ROTATE_16BITS 
MOV A,R5
CJNE A,02H, NOT_EQUAL
MOV R5,#00H
SETB C
SJMP END_DIVISION
NOT_EQUAL:
JB CY, LESS_THAN_DIVISOR  ;(A) < direct => CY = 1
CLR C
MOV A,R5
SUBB A,R2
MOV R5,A
SETB C
SJMP END_DIVISION
LESS_THAN_DIVISOR:
CLR C
END_DIVISION:
DJNZ R3,TRY_TO_DIVIDE
MOV R5,#00H
CLR C
RET


ROTATE_16BITS:
PUSH PSW ;store the CY
;must store the remainder before the last rotation of bits
;otherwise the remainder is lost
CJNE R3,#01D, DONT_STORE_REMAINDER ; while comparing delets the CY flag
MOV A,R5 ;store remainder
MOV R7,A
DONT_STORE_REMAINDER:

POP PSW ;pop the CY

MOV A,R1
RLC A
MOV R1,A

MOV A,R0
RLC A
MOV R0,A

MOV A,R5
RLC A
MOV R5,A

MOV A,R4
RLC A
MOV R4,A
RET

SUB_16BIT:

LCALL SECOND_COMPLEMENT
LCALL ADD_16BIT
;this subroutine, subtracts two 16bit numbers
RET
;----------------/SUB_16bit_subroutine--------------------

;----------------SECOND_COMPLEMENT_subroutine--------------------
SECOND_COMPLEMENT:

MOV R4,#17D
FIRST_COMPLEMENT_16BITS:
MOV A,R2
RLC A
MOV R2,A

CPL C  ;complements the 2nd number

MOV A,R3
RLC A
MOV R3,A
DJNZ R4,FIRST_COMPLEMENT_16BITS

;second complement
MOV A,R3
ADD A,#1D ;+1 = second complement
MOV R3,A

MOV A,R2
ADDC A,#00H ;propagate carry if generated
MOV R2,A
;this subroutine complements bits of R2 and R3,
;and stores the result in the same registers
RET
;----------------/SECOND_COMPLEMENT_subroutine--------------------

;----------------ADD_16bit_subroutine--------------------
ADD_16BIT:

MOV A,R1 ;R1+R3
ADD A,R3 ;ADD instruction generates CY='1', if A+R3>255, if A+R3<255 generates CY='0', even if CY='1'
MOV R7,A ;

MOV A,R0  ;R0+R2
ADDC A,R2 ;
MOV R6,A  ;

JNB CY, NO_CARRY   ;check if carry after R0+R2
MOV R5,#01H        ;if CY='1'
SJMP END_ADD_16BIT
NO_CARRY:
MOV R5,#00H        ;if CY='0'
END_ADD_16BIT:

RET
;---------------/ADD_16bit_subroutine--------------------

CMP_16BIT:
;compare MSBs
MOV A,R0 ;first_MSB
CJNE A, 02H, MSB_NOT_EQUAL ;compare with second_MSB
;if MSBs are equal then compare LSBs
MOV A,R1 ;first LBS
CJNE A, 03H, LSB_NOT_EQUAL ;compare with second_LSB
MOV A,#00H
SETB ACC.1
SJMP END_CMP_ROUTINE
LSB_NOT_EQUAL:
JB CY, FIRST_LESS_THAN_SECOND
SJMP FIRST_GREATER_THAN_SECOND
MSB_NOT_EQUAL:
JB CY, FIRST_LESS_THAN_SECOND ;(A)<direct C=1
FIRST_GREATER_THAN_SECOND:
MOV A,#00H
SETB ACC.0
SJMP END_CMP_ROUTINE
FIRST_LESS_THAN_SECOND:
MOV A,#00H
SETB ACC.2
END_CMP_ROUTINE:
RET

CALCULATE_DATA:
MOV DPTR,#ASCII_DIGITS
LCALL  MOSTRO ; vleren e ruan ne 2BH, kete vlere e perpunon me pjestime dhe mbetjet i shfaq ne display
;KRAHASIMI:
;first number:
MOV R0,2AH ;msb
MOV R1,2BH ;lsb
;second number:
MOV R2,#02H ;msb
MOV R3,#26H ;lsb
;E krahasojme nese nr pas mostrimit eshte me i madh,i barabart,apo me i vogel se 550 

LCALL CMP_16BIT
JB ACC.0,ZBRITJA
JB ACC.1,ZBRITJA
JB ACC.2,First_lower_than_Second

First_lower_than_Second:
;first number
MOV R0,#02H ;msb
MOV R1,#26H ;lsb ;Tensionit qe vjen ne CH0 ia zbresum nr 550D=226H
;second number
MOV R2,2AH ;msb
MOV R3,2BH ;lsb
LCALL SUB_16BIT
MOV 54H,#10D
SJMP PJESTIMI
ZBRITJA:
;first number
MOV R0,2AH ;msb
MOV R1,2BH ;lsb ;Tensionit qe vjen ne CH0 ia zbresum nr 550D=226H
;second number
MOV R2,#02H ;msb
MOV R3,#26H ;lsb
LCALL SUB_16BIT
MOV 54H,#11D

PJESTIMI:
MOV A,R6 ;R6 msb ne rezultat tek zbritja
MOV R0,A ;R0 msb tek pjestimi
MOV A,R7 ;R7 lsb ne rezultat tek zbritja
MOV R1,A ;R1 Lsb tek pjestimi

MOV R2,#0AH ;Pjestojme me 10

LCALL DIV_16BIT_BY_7BIT
MOV 50H,R7

LCALL DIV_16BIT_BY_7BIT
MOV 51H,R7

LCALL DIV_16BIT_BY_7BIT
MOV 52H,R7

LCALL DIV_16BIT_BY_7BIT
MOV 53H,R7

RET ; perfundon rutina e perpunimit te të dhenave

SHFAQJA_DISPLAY:
JB 60H, MOS_SHFAQ
READ_BUTTON:
SETB P3.0
MOV C,P3.0
MOV 60H,C
JNB 60H,READ_BUTTON
SETB 60H

MOV A,#0C0H
LCALL LCD_WRITE_COMMAND ;Per me kthy kursorin ne fillim te rreshtit te dyt, kur preket buttoni heren tjeter
;shkrun permi qato vlera e nuk vazhdon djathtas me shkru 
MOV A,54H
MOVC A,@A+DPTR
LCALL LCD_WRITE_DATA ;shifra e pare ne rreshtin e dyte ne LCD
MOV A,53H
MOVC A,@A+DPTR
LCALL LCD_WRITE_DATA ;shifra e dyte ne rreshtin e dyte ne LCD
MOV A,52H
MOVC A,@A+DPTR
LCALL LCD_WRITE_DATA ;shifra e trete ne rreshtin e dyte ne LCD
MOV A,51H
MOVC A,@A+DPTR
LCALL LCD_WRITE_DATA ;shifra e katert ne rreshtin e dyte ne LCD
MOV A,#'.'
LCALL LCD_WRITE_DATA ;shifra e peste ne rreshtin e dyte ne LCD
MOV A,#'0'
LCALL LCD_WRITE_DATA ;shifra e gjashte ne rreshtin e dyte ne LCD

MOV A,#' '
LCALL LCD_WRITE_DATA ;hapsira ne rreshtin e dyte ne LCD
MOV A,#'*'
LCALL LCD_WRITE_DATA ;shifra e tete ne rreshtin e dyte ne LCD
MOV A,#'C'
LCALL LCD_WRITE_DATA ;shifra e nente ne rreshtin e dyte ne LCD

MOS_SHFAQ:
RET

DELAY1S:
MOV R2,#2D
WAIT:
MOV R1,#255D
WAIT0:
MOV R0,#255D
DJNZ R0,$
DJNZ R1,WAIT0
DJNZ R2,WAIT
RET

ASCII_DIGITS: DB '0','1','2','3','4','5','6','7','8','9','+','-'

END 