# 6502 Computer
Source files for my 6502 CPU breadboard-computer from [Ben Eater](https://eater.net/6502).

## Preparations
### Compiling the vasm assembler (Ubuntu 20.04)
After downloading the ``vasm``` assembler from [here](http://sun.hasenbraten.de/vasm/index.php?view=relsrc), run:
```
 $ make CPU=6502 SYNTAX=oldstyle
```
For personal preferences, I renamed the newly created executable to ``vasm`` and moved it to ``/usr/bin`` so I could run ``vasm`` from any working directory. 

### Downloading minipro
Using this software, we can write our binary files to the EEPROM using the **MiniPRO TL866 II Plus** chip programmer.
Follow the installation process discussed [here](https://gitlab.com/DavidGriffith/minipro).

**NOTE**: On VirtualBox, remember to mount the USB connection to the VM at ``Settings > USB > USB Device Filters``.

## Compilation
```
 $ vasm -Fbin -dotdir PROGRAM.s
 $ minipro -p AT28C256 -w a.out
```

