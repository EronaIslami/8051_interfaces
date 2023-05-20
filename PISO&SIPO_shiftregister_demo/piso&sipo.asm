;-----------------------
SHCP EQU P2.0
DATAS EQU P2.1     ;74HC595
STCP EQU P2.2
;-----------------------
CLK EQU P3.0
SHLD EQU P3.1      ;74HC165
SO  EQU P3.2
;------------------------
ORG 0000H
LJMP MAIN
ORG 000BH
LCALL LEXIMI_BUTTONAVE
RETI

MAIN:

;------Inicializimi-------
MOV IE,#82H ;Konfigurimi i interruptit te Timer 0
MOV TMOD,#02H ;Konfigurimi i Timer 0 ne modin 8bit auto-reload
MOV TL0,#6D ;256-06=250us pra cdo 250us hyn ne interrupt
MOV TH0,#6D
SETB TR0


MOV DPTR,#DIGITS
CLR SHCP ;Fshijme clockun ashtu qe kur te ngarkojme nje te dhene te kete tranzicion prej 0-> 1
CLR STCP ;Fshijme ST_CP ashtu qe kur dojm ta shfaqim nje te dhene ne display te kete tranzicion prej 0-> 1
MOV 30H,#00H ;display i pare
MOV 31H,#00H ;display i dyte

MOV 2AH,#0FFH ;nje register bit-addressable ;FFH+1=00H
SETB 78H ; kjo mundeson shfaqjen e pare: 0 0 ;78H eshte nje flag
;--------/Inicializimi--------

PERSERITE:
LCALL ANALIZIMI_BUTTONAVE

JNB 78H, MOS_SHFAQ ;Nese buttoni eshte i mbyllur MOS_SHFAQ nr ne display dhe perserite(Analizoj buttonat vazhdimisht)
;nese flag 78H= '1'(buttoni eshte i hapur), atehere shfaq numrat:
CLR 78H ;e fshin qet flag qe heren tjeter mos me u ekzekutu
MOV A,31H 
LCALL SHFAQJA_DISPLAY
MOV A,30H 
LCALL SHFAQJA_DISPLAY
MOS_SHFAQ:
SJMP PERSERITE

LEXIMI_BUTTONAVE:
CLR SHLD ;Fshijme SH_LD_ ashtu qe aktivizohet LD(Load) per ngarkimin e te dhenave 
CLR CLK ;Fshijme Clk ashtu qe kur te ngarkohet nje e dhene te kete tranzicion prej 0-> 1
SETB SHLD ;Qe te dhenat te shiftohen duhet qe SH_LD_ te behet 1
MOV R1,#8D
NGARKIMI:
SETB SO ;Kushti per lexim
MOV C,SO ;Leximi
RLC A
SETB CLK ;Per mu ngarku nje e dhene duhet qe te behet 1 clk
CLR CLK ;Fshihet clk ashtu qe kur te ngarkohet e dhena tjeter te kete tranzicion prej 0-> 1
DJNZ R1,NGARKIMI
MOV 2AH,A
RET

ANALIZIMI_BUTTONAVE:
JNB 50H,ZBRITE ;buttoni ne D0 (per zbritje -1)
JNB 51H,RRITE ;buttoni ne D1(per rritje +1)
SJMP PERFUNDO
ZBRITE:
SETB 78H ; flagu e lejon shfaqjen ne display
JNB 50H,$ ;Sillet ne loop derisa buttoni eshte i mbyllur,dmth nuk ben asgje
DEC 31H ;kur te lshohet buttoni:-1 displayn e dyte
MOV A,31H
CJNE A,#0FFH,PERFUNDO ;E krahasojme vleren qe eshte ne displayn e dyte me FF(sepse 00H-1=FFH),nese po:
MOV 31H,#09D  ;e vendosim 9 ne displayn e dyte
DEC 30H ;dhe e zvgolgojme displayin e pare per -1
SJMP PERFUNDO
RRITE:
SETB 78H ; flagu e lejon shfaqjen ne display
JNB 51H,$ ;Sillet ne loop derisa buttoni eshte i mbyllur,dmth nuk ben asgje
INC 31H ;kur te lshohet buttoni:+1 displayn e dyte
MOV A,31H
CJNE A,#10D,PERFUNDO
MOV 31H,#00H ;Kur display i dyte e arrin vleren 9,pasi te shtypet buttoni per rritje edhe nje here e bejme 0 displayn e dyte
INC 30H ;dhe e rrisim vleren ne displayn e pare +1
SJMP PERFUNDO

PERFUNDO:
RET

SHFAQJA_DISPLAY:
MOVC A,@A+DPTR
LCALL DERGO_NE_SHIFTREGISTER
RET

DERGO_NE_SHIFTREGISTER:
MOV R0,#8D
SHIFTIMI: ;Shiftohen te dhenat nje nga nje
RLC A
MOV DATAS,C ;Te dhenen e dergojme ne pinin DS 
SETB SHCP ;Kur e dhena eshte ne pinin SO pas ndryshimit te clockut nga 0->1 e dhena ngarkohet
CLR SHCP ;Fshijme clockun ashtu qe kur te ngarkohet e dhena tjeter te kete tranzicion prej 0-> 1
DJNZ R0,SHIFTIMI

SETB STCP ;Te dhenat dergohen ne display
CLR STCP ;Fshihet biti qe heren e ardhshme te kete tranzicion prej 0-> 1
RET

DIGITS: DB 3FH,06H,5BH,4FH,66H,6DH,7DH,07H,7FH,6FH
END 