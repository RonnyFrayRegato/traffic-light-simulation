;
; traffic-light-simulation.asm
;
; Created: 11/23/2021 4:59:31 PM
; Author : Ronny Fray, Alexis Lopez, Henry Bryant
;

; PORTD, PD4: Red LED1, Red LED2
; PORTD, PD3: Yellow LED1, Yellow LED2
; PORTD, PD5: Green LED1, Green LED2
; PORTD, PB0: Crosswalk LED1, Crosswalk LED2
; PORTD, PD2: Crosswalk Switch1, Crosswalk Switch2


; Replace with your application code
.ORG 0x0  ; location for reset
     jmp  main

.ORG 0x02                 ; location for external interrupt 0
     jmp  EX0_ISR

.ORG 0x1A ; location for Timer1 overflow
     jmp  T1_OV_ISR

;    main program for initialization
.ORG 0x100
main:
     ldi  r16,high(RAMEND)
     out  SPH,r16
     ldi  r16,low(RAMEND)
     out  SPL,r16
     
     ldi  r20,(1<<TOIE1)
     sts  TIMSK1,r20     ; enable Timer0 overflow interrupt
     sei                 ; set I (enable interrupts globally)

     ; configure pins
     ; Green LEDs
     sbi  DDRD,DDD5           ; set D5 output
     sbi  PORTD,PD5           ; turn Green LED on

     ; Yellow LEDs
     sbi  DDRD,DDD3           ; set D3 output
     cbi  PORTD,PD3           ; clear D3

     ; Red LEDs
     sbi  DDRD,DDD4           ; set D4 output
     cbi  PORTD,PD4           ; clear D4

     ; Crosswalk LEDs
     sbi  DDRB,DDB0           ; set B0 output
     cbi  PORTB,PB0           ; clear B0

     ; Switches
     cbi  DDRD,DDD2           ; set D2 input
     sbi  PORTD,PD2           ; set D2 pull-up

     ; configure Timer1
     ldi  r20,high(0x48E5)      ; the high byte
     sts  TCNT1H,r20          ; load Timer1 high byte
     ldi  r20,low(0x48E5)       ; the low byte
     sts  TCNT1L,r20          ; load Timer1 low byte
     ldi  r20,0x00
     sts  TCCR1A,r20          ; normal mode
     ldi  r20,0x05
     sts  TCCR1B,r20          ; internal clk, 1024 prescalar

     ; configure Timer1 for interrupt
     ldi  r20,(1<<TOIE1)
     sts  TIMSK1,r20     ; enable Timer1 overflow interrupt
     ;sei                 ; set I (enable interrupts globally)

     ; configure external switch interrupt
     ldi  r25,1<<INT0         ; enable INT0 on D2
     out  EIMSK,r20
     ldi  r25,(1<<ISC01)      ; INT0 falling edge trigger
     sts  EICRA,r20 
     sei				     ; enable external interrupts


;----infinite wait loop (that will wait for interrupts)
End_Main:
     rjmp End_Main
;----end infinite wait loop


Delay_Half_Second:

     LDI  R22,32        ; 192x250K = 48M * 0.0625 = 3Mu
L3:
     LDI  R23,200        ; 200x1250 = 250Ku
L2:
     LDI  R24,250        ; 250x5 = 1,250u
L1:
     NOP                 ; 1u
     NOP                 ; 1u
     DEC  R24            ; 1u
     BRNE L1             ; 2u/1u
     
     DEC  R23
     BRNE L2
     
     DEC  R22
     BRNE L3 
     ret


;----ISR for Timer1
.ORG 0x300
T1_OV_ISR:
     ldi  r18,high(0x48)      ; the high byte
     sts  TCNT1H,r18          ; load Timer1 high byte
     ldi  r18,low(0xE5)       ; the low byte
     sts  TCNT1L,r18          ; load Timer1 low byte

Green_LED:
     in   r16,PIND            ; read current state of Port D
     andi r16,0b00100000      ; test for Green LEDs on
     cpi  r16,0b00100000      ; see if Green LEDs on
     brne Yellow_LED
     cbi  PORTD,PD5           ; turn Green LED off
     sbi  PORTD,PD3           ; turn Yellow LED on
     jmp  End_Test

Yellow_LED:
     in   r16,PIND            ; read current state of Port D
     andi r16,0b00001000      ; test for Yellow LEDs on
     cpi  r16,0b00001000      ; see if Yellow LEDs on
     brne Red_LED
     cbi  PORTD,PD3           ; turn Yellow LED off
     sbi  PORTD,PD4           ; turn Red LED on
     jmp  End_Test

Red_LED:
     in   r16,PIND            ; read current state of Port D
     andi r16,0b00010000      ; test for Red LEDs on
     cpi  r16,0b00010000      ; see if Red LEDs on
     brne Green_LED
     cbi  PORTD,PD4           ; turn Red LED off
     sbi  PORTD,PD5           ; turn Green LED on

End_Test:
     reti                     ; return from interrupt


;----ISR for external interrupt
.ORG 0x400
EX0_ISR:

     cbi  PORTD,PD5           ; turn Green LED off
     cbi  PORTD,PD3           ; turn Yellow LED off
     sbi  PORTD,PD4           ; turn Red LED on

     sbi  PORTB,PB0           ; turn on Crosswalk LED 1
     cbi  PORTB,PB2           ; turn off Crosswalk LED 2
     call Delay_Half_Second
     cbi  PORTB,PB0           ; turn off Crosswalk LED 1
     sbi  PORTB,PB2           ; turn on Crosswalk LED 2
     call Delay_Half_Second
     cbi  PORTB,PB0           ; turn off Crosswalk LED 1
     cbi  PORTB,PB2           ; turn on Crosswalk LED 2

     reti
