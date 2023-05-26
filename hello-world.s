PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003

E   = %10000000
RW  = %01000000
RS  = %00100000

  .org $8000
reset:
  lda #%11111111  ; set all pins on port B to output
  sta DDRB

  lda #%11100000  ; set top 3 pins on port A to output
  sta DDRA

  lda #%00111000  ; set 8-bit mode, 2-line display, 5x8 font
  jsr lcd_instruction

  lda #%00001110  ; display on, cursor on, blinking off
  jsr lcd_instruction

  lda #%00000110  ; increment and shift cursor, don't shift display
  jsr lcd_instruction

  lda #%00000001  ; clear screen
  jsr lcd_instruction

  ldx #(<message)
  ldy #(>message)
  jsr print_str  

; "halt" the cpu
loop:
  jmp loop


message: .asciiz "Hello World!"


; prints a string terminated by \0
; params:
;   - reg X, lower byte of the effective address
;   - reg Y, higher byte of the effective address
print_str:
  stx $0000
  sty $0001
  ldy #0
print_str_loop:
  lda ($0000), Y
  beq end_print
  jsr print_char
  iny
  jmp print_str_loop
end_print:
  rts


; busy waits until the busy flag of the LCD is set
lcd_wait:
  pha
  ; set port B to input
  lda #%00000000 
  sta DDRB
lcdbusy:
  ; a reg <- read from lcd
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  
  ; check for busy flag
  and #%10000000
  bne lcdbusy

  ; set port B to output
  lda #RW
  sta PORTA
  lda #%11111111
  sta DDRB
  pla
  rts


; send an instruction to the LCD
lcd_instruction:
  jsr lcd_wait

  sta PORTB
  lda #0          ; clear RS/RW/E bits
  sta PORTA
  lda #E          ; set Enable bit to send instruction
  sta PORTA
  lda #0          ; clear RS/RW/E bits
  sta PORTA
  rts


; prints char to LCD
; params:
;   - reg A, character value
print_char:
  jsr lcd_wait

  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E)
  sta PORTA
  lda #RS
  sta PORTA
  rts

  .org $fffc
  .word reset
  .word $0000 ; pad zeroes to match EEPROM size


