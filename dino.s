PORTB = $6000
PORTA = $6001
DDRB  = $6002
DDRA  = $6003
PCR   = $600C
IFR   = $600D ; Interrupt Flag Reg (8 bits high -> low): IRQ, Timer1, Timer2, CB1, CB2, ShiftReg, CA1, CA2
IER   = $600E
T1CL  = $6004
T1CH  = $6005
ACR   = $600B

E   = %10000000
RW  = %01000000
RS  = %00100000

; the followings will be addressed according to little endian
; i.e. $0001 - low byte of "ground", $0002 - high byte of "ground"
player_col = $0000 ; 1 bytes
ground    = $0001 ; 2 bytes
ticks     = $0003 ; 4 bytes
jump_tick_count = $0007 ; 1 bytes
toggle_time = $0008 ; 1 bytes
blocks_tick_count = $0009 ; 1 bytes


  .org $8000
reset:
  sei
  ldx #$ff
  txs

  lda #$82
  sta IER
  lda #$00
  sta PCR

  jsr init_timer

  ; the column of the player relative to ground+1 (left 8 bits of screen)
  lda #$80
  sta player_col

  lda #0
  sta ground
  sta ground+1
  sta toggle_time
  sta jump_tick_count
  sta blocks_tick_count

  jsr init_lcd
  cli

 
game_loop:
  jsr delay
  jsr print_game

  ; check for collision
  lda ground+1
  and player_col
  cmp #$80
  beq end_game
  
  ; add random obstacles every now and then
  jsr add_block

  ; hold jump duration for some ticks
  lda player_col
  cmp #$80
  beq continue

  ; player is jumping -> hold 4 ticks in the air
  inc jump_tick_count
  lda jump_tick_count
  cmp #4
  bne continue
  ; set player back on ground
  lda #$80
  sta player_col
  lda #0
  sta jump_tick_count

continue:
  jsr move_ground
  jmp game_loop
end_game:

; "halt" the cpu
loop:
  jmp loop


; set delay to 10ms
init_timer:
  lda #0
  sta ticks
  sta ticks+1
  sta ticks+2
  sta ticks+3
  lda #%01000000
  sta ACR ; set Free-Run mode
  lda #$0E
  sta T1CL
  lda #$27
  sta T1CH
  lda #%11000000
  sta IER
  rts


delay:
  sec
  lda ticks
  sbc toggle_time
  cmp #20 ; have 200ms elapsed?
  bcc delay
  lda ticks
  sta toggle_time
  rts


move_ground:
  pha
  asl ground+1
  clc
  asl ground
  bcc end_move_ground
  lda ground+1
  ora #$01
  sta ground+1
end_move_ground:
  pla
  rts


add_block:
  pha
  inc blocks_tick_count

  lda blocks_tick_count
  cmp #10
  bne check_double_block
  lda ground
  ora #%00000100 ; single block
  sta ground
check_double_block:
  lda blocks_tick_count
  cmp #20
  bne end_add_block
  lda ground
  ora #%00001100 ; double block
  sta ground
  lda #0
  sta blocks_tick_count
end_add_block:
  pla
  rts


print_game:
  jsr clear_lcd

  ; print first line
  jsr goto_line1_lcd
  lda player_col
  cmp #0
  bne continue_print_game
  lda #"o"
  jsr print_char

continue_print_game:
  ; print second line
  jsr goto_line2_lcd

  lda player_col
  cmp #$80
  bne print_no_player
  lda #"o"
  jsr print_char
  jmp print_line_2

print_no_player:
  lda #" "
  jsr print_char
print_line_2:
  jsr goto_line2_lcd
  ldy ground+1
  jsr print_ground
  ldy ground
  jsr print_ground
end_print_game:
  rts


print_ground:
  ; param: reg Y - ground half bitfield
  pha
  txa
  pha

  ldx #$08
  print_loop1:
    tya
    and #$80
    cmp #$80
    bne no_print
    lda #"#"
    jsr print_char
    jmp loop1_cont
  no_print:
    ; shift cursor 1 to the right
    lda #%00010100
    jsr lcd_instruction
  loop1_cont:
    ; shift left by 1 the ground
    tya
    rol A
    tay

    dex
    bne print_loop1

  pla
  tax
  pla
  rts

; initialize lcd display screen w.r.t custom settings
init_lcd:
  lda #%11111111  ; set all pins on port B to output
  sta DDRB

  lda #%11100000  ; set top 3 pins on port A to output
  sta DDRA

  lda #%00111000  ; set 8-bit mode, 2-line display, 5x8 font
  jsr lcd_instruction

  lda #%00001100  ; display on, cursor on, blinking off
  jsr lcd_instruction

  lda #%00000110  ; increment and shift cursor, don't shift display
  jsr lcd_instruction

  lda #%00000001  ; clear screen
  jsr lcd_instruction
  rts


clear_lcd:
  lda #%00000001
  jsr lcd_instruction
  rts


goto_line1_lcd:
  lda #%0000000010
  jsr lcd_instruction
  rts


goto_line2_lcd:
  lda #%0011000000
  jsr lcd_instruction
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
  pha
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E)
  sta PORTA
  lda #RS
  sta PORTA
  pla
  rts


nmi:
 rti


irq:
  pha
  ; check if button clicked interrupt or timer interrupt
  ; (if IFR.CA1 is set, then its a timer interrupt)
  lda IFR
  and #%00000010
  cmp #0
  beq timer_interrupt

  ; button clicked interrupt
  lda #0
  sta player_col
  bit PORTA
  jmp end_irq
timer_interrupt:
  ; read timer interrupt
  bit T1CL
  inc ticks
  bne end_irq
  inc ticks+1
  bne end_irq
  inc ticks+2
  bne end_irq
  inc ticks+3
end_irq:
  pla
  rti


  .org $fffa
  .word nmi
  .word reset
  .word irq

