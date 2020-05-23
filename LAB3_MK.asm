;Lab 3 MK. 
;Create by Kozlov Igor 1741

;Task:5)В исходном состоянии – автоматич. прибавление 1 каждые 0.5 сек.
;При нажатии на кнопку (с кликом) складывается левый 
;и правый разряд и помежается в левый разряд. При отпускании кнопки счет продолжается.


#INCLUDE <P16F877A.INC>

__CONFIG(_CP_OFF&_PWRTE_ON&_WDT_OFF&_HS_OSC); set config for current programm

;----------------------------------------------------------------------------| Rename Reg |
;Rename registers, begin addres: 20h

ValIndic1	equ 20h; Correspond to the number on the left  indicator
ValIndic2	equ 21h; Correspond to the number on the right indicator
NumberInd1	equ 22h; {0 - 9} left indicatora
NumberInd2	equ 23h; {0 - 9} right indicator
nine		equ 24h
CountTimer1 equ 25h
tmp			equ 26h


;----------------------------------------------------------------------------

ORG 0 

GOTO Start


;----------------------------------------------------------------------------| Ineraction ORG 4 |
;Handler Interactions													     |I
ORG 4				;														 |N
BCF INTCON, GIE		;														 |E
MOVWF tmp;           														 |R
BTFSC INTCON, 0x2; if RTM0 is overflow                                       |A
CALL IntRTM0;																 |C
;																			 |T
BTFSC INTCON, RBIF; in PORTB 4-7 change signal								 |I
CALL IntSig	;		                                                         |O
MOVFW tmp;												  	                 |N
RETFIE				;														 |S
;----------------------------------------------------------------------------


;port C -out
;--------------------------------------------------------------------------- |ConstArray: SignalConstArray|
SignalConstArray: 	NOP ; default ROM array. Data is value for indicator
			
					addwf   PCL,F 

					retlw B'00010000' ;0
					retlw B'01011011' ;1 
					retlw B'00001100' ;2
					retlw B'00001001' ;3
					retlw B'01000011' ;4
					retlw B'00100001' ;5
					retlw B'00100000' ;6
					retlw B'00011011' ;7
					retlw B'00000000' ;8
					retlw B'00000001' ;9


;--------------------------------------------------------------------------- | Start |
Start:	
		MOVLW 0x09
		MOVWF nine

		BSF STATUS, RP0; page 1

		CLRF TRISC     ;Port c -out
		BCF TRISB, 7
		BCF TRISB, 6
		BCF TRISB, 5
		BCF TRISB, 4
		BCF OPTION_REG, T0CS; F/4 = 5 000( F = 20 MHz)
		BCF OPTION_REG, PSA
		BSF OPTION_REG, PS0
		BSF OPTION_REG, PS1
		BSF OPTION_REG, PS2; 1:256 for TMR0
		BCF OPTION_REG, 0x7
		; Initialization varible for Timer, should be 0,5 sec
		; F = 5 000 000 Hz
		; F 1 tik TMR0 = F /256/256 9 => 1 COUNTERS

		BCF STATUS, RP0; Page 0
		BSF PORTB, 0x4		
		BSF PORTB, 0x5		
		BSF PORTB, 0x6	
		BSF PORTB, 0x7		

		MOVLW 0x00
		MOVWF NumberInd1; initialization
		MOVWF NumberInd2; initialization
		MOVLW 0xDA
		MOVWF CountTimer1;
		
			;Mask of INT
		BSF INTCON, RBIE; enable inetaction PortB(4-7)
		BSF INTCON, 0x5; enable inetaction TMR0(0xFF -> 0x00)

			;Global Interactio Enable 
		BCF INTCON, RBIF
		
		BSF INTCON, GIE;
;counters


;------------------------------------------------------------------------------ | MAIN |
MAIN:

		;Check Overflow NumberInd1 and NumberInd2
 		CALL isOverflow
		
		;get val for Indicator1
		MOVFW NumberInd1
		CALL SignalConstArray
		
		MOVWF ValIndic1; in ValIndic1 {0-9} for indicator
		
		;get val for Indicator2
		MOVFW NumberInd2
		CALL SignalConstArray
		
		MOVWF ValIndic2; in ValIndic1 {0-9} for indicator
		BSF ValIndic2, 0x7 ; since it is rigth indicator RC7 = 1

		
		;out ValIndic to Indicator
		
		MOVFW ValIndic2
		MOVWF PORTC

		MOVFW ValIndic1
		MOVWF PORTC
		
GOTO MAIN


;----------------------------------------------------------------------------|isOverflow| in {0-9}
isOverflow:

			;if NumberInd > 9 then NumberInd = NumberInd - 10
			;NumberInd1
			BCF STATUS, C
			MOVFW NumberInd1
			SUBWF nine, W
	

			;MOVWF CountTimer1

			MOVLW 0x0A
			BTFSS STATUS, C
			SUBWF NumberInd1, F

			;if 9 - NumberInd1 then  NumberInd2 -= 10
			;NumberInd
			BCF STATUS, C
			MOVFW NumberInd2
			SUBWF nine, W
			
			MOVLW 0x0A
			BTFSS STATUS, C
			SUBWF NumberInd2, F

RETURN


;---------------------------------------------------------------------------------| Interaction RTM0 is overflow |
IntRTM0:
BCF INTCON, 0x2;RTIF
;Счётчик 0.5 сек
INCF CountTimer1, F;

BTFSC STATUS, Z;overflow count1
CALL TIK

RETURN



;--------------------------------------------------------------------------------------| TIK: T~0.5 sec
TIK:

INCF NumberInd1,F
INCF NumberInd2, F

;count 2 = N =DA Для подбора времени 0.5 сек
MOVLW 0xDA
MOVWF CountTimer1;
RETURN

;---------------------------------------------------------------------------------| Interaction PORTB 4-7 change signal - button is pressed |
IntSig:
BCF INTCON, RBIF;

;add left and rigth
MOVFW NumberInd2
ADDWF NumberInd1, F

	;Check Overflow NumberInd1 and NumberInd2
 		CALL isOverflow
		
		;get val for Indicator1
		MOVFW NumberInd1
		CALL SignalConstArray
		
		MOVWF ValIndic1; in ValIndic1 {0-9} for indicator

		MOVFW ValIndic1
		MOVWF PORTC

;Вывод результата на индикаторы
;sleep until button is unpressed
BSF INTCON, GIE;
SLEEP
BCF INTCON, GIE;
BCF INTCON, RBIF;
;

RETURN

END