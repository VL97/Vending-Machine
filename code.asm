#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#
		
			jmp ioinit
			db     	5 dup(0)
			dw	interrupt
			dw	0000
			db	1012 dup(0)
			
ioinit:		
		;Memory variable maps;
		
		porta		equ 	00h
		portb		equ		02h
		portc		equ		04h
		ctrio		equ		06h
		
		;stores wieght needed for a chocolate (updated after button press)
		weight_need	equ		12h
		
		;stores the button input
		button		equ		14h
		
		;stores number of chocolates
		choc_no_1	equ		15h
		choc_no_2	equ		16h
		choc_no_3	equ		17h
		
		;stores motor orientations
		motor1		equ		21h
		motor1		equ		22h
		motor1		equ		23h
		
	;MEMORY ADDRESS MAP
	;ROM1 4KB: even bank :	00000, 00002 ... 01FFC, 01FFE h
	;ROM2 4KB: ODD bank :	00001, 00003 ... 01FFD, 01FFF h 
	;RAM1 2KB: even bank :	02000, 02002 ... 02FFC, 02FFE h   
	;RAM2 2KB: ODD bank :	02001, 02003 ... 02FFD, 02FFF h
	
	;Total Memory interfaced:12KB (2FFF+1)
	;Note upon RESET normal function wont resume as instruction is executed from last FFFF0H but memory is 
	;not interfaced there. In 8086, reset values of CS & lP are FFFFH & 0000h.
	
	; intialize ds, es,ss to start of RAM
	mov ax,0200h
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov sp,0FFFEh          ;stack will work with ss
		
		;intialise port A & lower port C as input ,port B & higher port C as output
		mov al,10010001b
		out	ctrio,al
		
		;set no of chocolates to 2 each
		mov al,2
		mov di,15h
		mov [di],al
		inc di
		mov [di],al
		inc di
		mov [di],al
		
		;initialize motor orientation: 
		;ME: 3 Motor Enable bits to sleect 1 out of 3 motors (ONE HOT)
		;MO: 4 bit motor output to drive 1 motor.
		;Format: X ME3 ME2 ME1 MO4 MO3 MO2 MO1
		mov di,21h
		mov [di],00010011b;
		mov di,22h
		mov [di],00100011b;
		mov di,23h
		mov [di],01000011b;
		
		
		;loop till interrupt is received
x1:		jmp x1

interrupt:	
		
		in al,portc			;check input portc
		and al,07h			;use only last 3 bits ie input bits
		cmp al,07h			;if all 3 are high means no input received :exit
		jz exitp		
		mov di, 14h			;store the button input
		mov [di],al 
		
		;note debouncing not implemented due to simulation delay problems.		               	
				
button1:mov di,14h
		mov dl,[di]                     ;check if button1 was pressed
		cmp dl,00000110b
		jnz button2
		mov bx,15h			;if yes:
		mov di,12h			;store the required weight for this choco1
		mov [di],5h			;BX will contain the choco1 quantity identifier 15h
		mov si,21h			;SI will contain the first motors orientation
		jmp check_weight
		
button2:mov di,14h
		mov dl,[di]
		cmp dl,00000101b
		jnz button3
		mov bx,16h
		mov di,12h
		mov [di],0ah		
		mov si,22h		
		jmp check_weight
		
button3:mov di,14h
		mov dl,[di]
		cmp dl,00000011b
		jnz exitp
		mov bx,17h
		mov di,12h
		mov [di],14h		
		mov si,23h		
		jmp check_weight
		
check_weight: 		
			
		in al,porta 			;get inputs from porta (0808 is always ON! and converting)
	    
		mov di,12h			;get the required weights
		mov dl,[di]
		cmp al,dl			;compare the input weight from 0808: exit if below
		jb exitp

		mov di,bx			;compare if chocolate quantity is 0: yes then 
		mov dl,[di]			;jmp pass through choc[1,2,3] to glow LEDs
		cmp dl,0
		jz	choc1			
		sub dl,1			;else subtract choco if available 
		mov [di],dl
		
		mov dl,[si]			;get current orientation of motor in DL
		mov dh,dl			;DH is proxy for DL
		and dh,00001111b		;strip the ME(Motor Enable) bits from DH(DL retains them)
		
state1:	cmp dh,00000011b			;find current motor orienation from DH and update with 
		jnz state2			;next one through DL which still has ME bits
		and dl,11111101b
		jmp state_done
		
		
state2:	cmp dh,00000001b
		jnz state3
		or dl,00001000b
		jmp state_done
		
state3:	cmp dh,00001001b
		jnz state4
		and dl,11111110b
		jmp state_done
		
state4:	cmp dh,00001000b
		jnz state5
		or dl,00000100b
		jmp state_done
		
state5:	cmp dh,00001100b
		jnz state6
		and dl,11110111b
		jmp state_done
		
state6:	cmp dh,00000100b
		jnz state7
		or dl,00000010b
		jmp state_done

state7:	cmp dh,00000110b
		jnz state8
		and dl,11111011b
		jmp state_done	

state8:	cmp dh,0000010b
		jnz choc1
		or dl,00000001b
		jmp state_done		

			
state_done:
		mov al,dl			;Output Motor orientation to portb to move the motor
		out portb,al
		mov [si],dl
		jmp choc1

;choc1, choc2, choc3 check all 3 chocolate quantities again and if zero: glow the corresponding LEDs.		
choc1: 	mov di,15h			
		mov dl,[di]
		cmp dl,0
		ja choc2		
		in al,portc
		or al,10000000b
		out portc,al
		
		
choc2:	mov di,16h
		mov dl,[di]
		cmp dl,0
		ja choc3		
		in al,portc
		or al,01000000b
		out portc,al

choc3:	mov di,17h
		mov dl,[di]
		cmp dl,0
		ja exitp		
		in al,portc
		or al,00100000b
		out portc,al
			
exitp:	iret

;motor sequence;
;0011
;0001
;1001
;1000
;1100
;0100
;0110
;0010
;0011