"""
fill the EEPROM with nop instructions
"""

rom = bytearray([0xEA] * 32768)

# load A register with 0x37
rom[0] = 0xA9
rom[1] = 0x37

# store register A at rom[0x3000]
rom[2] = 0x8D
rom[3] = 0x00
rom[4] = 0x30

# set instruction memory to essentially start from 0.
# the first 15 bits (of 0x8000 i.e.) are used for addressing
# whilst the MSB is used to cheap-enable the EEPROM reads,
# NOTE: 6502 uses little endian
rom[0x7FFC] = 0x00
rom[0x7FFD] = 0x80


with open("rom.bin", "wb") as out_file:
    out_file.write(rom)

