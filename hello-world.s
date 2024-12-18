PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003
PCR   = $600C
IFR   = $600D
IER   = $600E
T1CL  = $6004
T1CH  = $6005
ACR   = $600B

E   = %10000000
RW  = %01000000
RS  = %00100000

ticks = $0000 ; 4 bytes
toggle_time = $0004 ; 1 bytes

  .org $8000
reset:
  ldx #$ff
  txs
  cli

  ; previous button interrupts
  ; lda #$82
  ; sta IER

  lda #0
  sta PCR
  sta toggle_time

  sei
  jsr init_lcd
  jsr init_timer
  cli

  ldx #(<message)
  ldy #(>message)
  jsr print_str

; "halt" the cpu
loop:
  sec
  lda ticks
  sbc toggle_time
  cmp #25 ; have 250ms elapsed?
  bcc loop
  ; do whatever
  lda ticks
  sta toggle_time
  jmp loop


message: .asciiz "Hello World!"


init_timer:
  lda #0
  sta ticks
  sta ticks+1
  sta ticks+2
  sta ticks+3
  ; set continuous interrupts to enable timer Free-Run mode
  lda #%01000000
  sta ACR
  ; trigger interrupts every 10ms 
  lda #$0E
  sta T1CL
  lda #$27
  sta T1CH
  ; generate interrupts for Timer1
  lda #%11000000
  sta IER
  rts


; initialize lcd display screen w.r.t custom settings
init_lcd:
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

  rts

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

nmi:
 rti

irq:
  bit T1CL
  inc ticks
  bne end_irq
  inc ticks+1
  bne end_irq
  inc ticks+2
  bne end_irq
  inc ticks+3
end_irq:
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq

