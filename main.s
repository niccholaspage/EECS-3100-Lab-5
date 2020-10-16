;*******************************************************************
; main.s
; Author: Nicholas Nassar
; Date Created: 10/13/2020
; Last Modified: 10/15/2020
; Section Number: 002
; Instructor: Devinder Kaur
; Lab number: 5
; Brief description of the program
;   If the switch is presses, the LED toggles at 8 Hz
; Hardware connections
;  PE1 is switch input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external LED on protoboard) 
; Overall functionality is similar to Lab 4, with six changes:
;   1) the pin to which we connect the switch is moved to PE1, 
;   2) you will have to remove the PUR initialization because
;      pull up is no longer needed. 
;   3) the pin to which we connect the LED is moved to PE0, 
;   4) the switch is changed from negative to positive logic, and 
;   5) you should increase the delay so it flashes about 8 Hz.
;   6) the LED should be on when the switch is not pressed
; Operation
;   1) Make PE0 an output and make PE1 an input. 
;   2) The system starts with the LED on (make PE0 =1). 
;   3) Wait about 62 ms
;   4) If the switch is pressed (PE1 is 1), then toggle the LED
;      once, else turn the LED on. 
;   5) Steps 3 and 4 are repeated over and over
;*******************************************************************

GPIO_PORTE_DATA_R       EQU   0x400243FC
GPIO_PORTE_DIR_R        EQU   0x40024400
GPIO_PORTE_AFSEL_R      EQU   0x40024420
GPIO_PORTE_DEN_R        EQU   0x4002451C
GPIO_PORTE_AMSEL_R      EQU   0x40024528
GPIO_PORTE_PCTL_R       EQU   0x4002452C
SYSCTL_RCGCGPIO_R       EQU   0x400FE608

	IMPORT  TExaS_Init

	AREA    |.text|, CODE, READONLY, ALIGN=2
	THUMB
	EXPORT  Start
Start
	; TExaS_Init sets bus clock at 80 MHz
	BL  TExaS_Init ; voltmeter, scope on PD3
	; you initialize PE1 PE0
InitPortE
	; SYSCTL_RCGCGPIO_R = 0x10
	MOV R0, #0x10
	LDR R1, =SYSCTL_RCGCGPIO_R
	STR R0, [R1]
	
	LDR R0, [R1] ; Delay before continuing

	; GPIO_PORTE_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_PCTL_R
	STR R0, [R1]

	; GPIO_PORTE_DIR_R = 0x01
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DIR_R
	STR R0, [R1]

	; GPIO_PORTE_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AFSEL_R
	STR R0, [R1]

	; GPIO_PORTE_DEN_R = 0x03
	MOV R0, #0x03
	LDR R1, =GPIO_PORTE_DEN_R
	STR R0, [R1]
	
	; Turns LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]

	CPSIE  I    ; TExaS voltmeter, scope runs on interrupts

loop  
	; you input output delay
	BL Delay62ms ; Delay 62 ms
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of Port E data into R1
	LDR R0, [R1] ; Load the value at the address in R1 into R0
	LSR R0, #1 ; Shift the register 1 bit to the right, since we only care about pin 1
	CBNZ R0, toggle_led ; Since the switch is on, we toggle the LED
	; The switch is off, so turn the LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B    loop

toggle_led ; Toggles the LED
	; Read Port E data so we can check if LED is on or not
	LDR R1, =GPIO_PORTE_DATA_R
	LDR R0, [R1] ; Load the value at the address in R1 into R0
	AND R0, #0x01 ; Clear all bits except for bit zero
	CBZ R0, turn_led_on ; If the LED is off, then we turn it on
	; Otherwise, turn the LED off
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B loop ; Loop again!

turn_led_on
	; Turns LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	B loop ; Loop again!

; A subroutine that delays for 62 ms then returns to the original line
Delay62ms
	MOV R12, #0xD000 ; set R12 to our big number to get us our 62 ms delay
	MOVT R12, #0x12 ; Needed so we can fill the upper halfword of the register too
WaitForDelay
	SUBS R12, R12, #0x01 ; Subtract one from the register
	BNE WaitForDelay ; If the value isn't zero, go back to waiting for the delay
	BX LR ; We did it, we finished waiting! So we go back to where we were before calling this.


      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file
       