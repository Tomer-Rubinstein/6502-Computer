"""
Load EEPROM with a simple program.
In this case, 8 LEDs blinking bitwise NOT: 0101 0101(0x55) -> 1010 1010(0xAA))
"""

code = bytearray([
  # set all pins of port B to output, so DDRB(reg2)='1111 1111'
  0xA9, 0xFF,         # lda #$ff
  0x8D, 0x02, 0x60,   # sta $6002 (01.....0010, write to register 2 of the W65C22)
  
  # (MAIN) write to reg0 (output port B) 0x55
  0xA9, 0x55,         # lda #$55
  0x8D, 0x00, 0x60,   # sta $6000

  # write to reg0 (output port B) 0xAA
  0xA9, 0xAA,         # lda #$AA
  0x8D, 0x00, 0x60,   # sta $6000

  # jump to (MAIN)
  0x4C, 0x05, 0x80
])

rom = code + bytearray([0xEA] * (32768 - len(code)))

# set instruction memory to essentially start from 0.
# the first 15 bits (of 0x8000 i.e.) are used for addressing
# whilst the MSB is used to chip-enable the EEPROM reads,
# NOTE: 6502 uses little endian
rom[0x7FFC] = 0x00
rom[0x7FFD] = 0x80


with open("rom.bin", "wb") as out_file:
    out_file.write(rom)
