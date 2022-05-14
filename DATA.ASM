;----------------------------------------------------------------------------
;misc program data
;----------------------------------------------------------------------------
        .386p
code    segment public use32
        assume cs:code,ds:code

        include equates.h
        include memory.h
        include ppu.h
        include io.h
        include macros.h
        include mappers.h

        public reg_struc                ;register data structure for real
        public _eax                     ;mode interrupt simulation
        public _ebx
        public _ecx
        public _edx
        public _esi
        public _edi
        public _ebp
        public _ds
        public _es
        public _fs
        public _gs
        public _flags
        public errtbl                   ;error code table
        public code_addr
        public psp_ptr
        public env_ptr
        public data_sel
        public dos_ptr
        public gfx_ptr
        public text_ptr
        public ram_sel
        public ram_ptr
        public rom_ptr
        public vrom_ptr
        public chr_ptr
        public dmabuff
        public flag_encode
        public flag_decode
        public striketbl
        public read_tbl
        public write_tbl
        public mapperinit
        public palmap

        public nes
        public castlevania
        public excitebike
        public mario
        public goonies
        public iceclimber
        public gradius
        public hogalley
;----------------------------------------------------------------------------

                align   4

EOL             equ     13,10,'$'
errtbl          dd      err00,err01,err02,err03,err04,err05,err06,err07
                dd      err08,err09,err0A,err0B,err0C,err0D,err0E,err0F
                dd      err10,err11,err12,err13,err14,err15,err16,err17
                dd      err18,err19,err1A,err1B,err1C,err1D,err1E,err1F
                dd      err20,err21,err22,err23,err24,err25,err26,err27

err00           db      'err00',EOL
err01           db      'err01',EOL
err02           db      'err02',EOL
err03           db      'err03',EOL
err04           db      'err04',EOL
err05           db      'err05',EOL
err06           db      'err06',EOL
err07           db      'Error opening file.',EOL
err08           db      'File access error.',EOL
err09           db      'Error loading file.',EOL
err0A           db      'No file specified.',EOL
err0B           db      'Mapper not supported.',EOL
err0C           db      'File creation error.',EOL
err0D           db      'File write error.',EOL
err0E           db      EOL
err0F           db      EOL
err10           db      EOL
err11           db      EOL
err12           db      EOL
err13           db      EOL
err14           db      EOL
err15           db      EOL
err16           db      EOL
err17           db      EOL
err18           db      EOL
err19           db      EOL
err1A           db      EOL
err1B           db      EOL
err1C           db      EOL
err1D           db      EOL
err1E           db      EOL
err1F           db      EOL
err20           db      EOL
err21           db      EOL
err22           db      EOL
err23           db      EOL
err24           db      EOL
err25           db      EOL
err26           db      EOL
err27           db      'Generic error message.',EOL

;----------------------------------------------------------------------------
                align   4
reg_struc:                              ;register data structure for real
_edi            dd      ?               ;mode interrupt simulation
_esi            dd      ?
_ebp            dd      ?
                dd      ?
_ebx            dd      ?
_edx            dd      ?
_ecx            dd      ?
_eax            dd      ?
_flags          dw      0
_es             dw      ?
_ds             dw      ?
_fs             dw      ?
_gs             dw      ?
                dd      ?
_sp             dw      0
_ss             dw      0
;----------------------------------------------------------------------------
                align   4
code_addr       dd      0               ;code/data linear address
data_sel        dd      0               ;data (DS) selector
dos_ptr         dd      ?               ;64k dos mem ptr
psp_ptr         dd      0               ;PSP start (DS offset)
env_ptr         dd      0               ;environment area
gfx_ptr         dd      0               ;offset to gfx VRAM (A0000h ptr)
text_ptr        dd      0               ;offset to text VRAM (B8000h ptr)
ram_sel         dd      0               ;NES ram selector
ram_ptr         dd      0               ;ptr to NES ram space ($0000-$7FFF)
rom_ptr         dd      0               ;ptr to rom (PRG)
vrom_ptr        dd      0               ;ptr to vrom (CHR), redirected to vram if vrom not present
chr_ptr         dd      0               ;ptr to unpacked chr (vrom or vram)

dmabuff         dd      ?               ;DMA buffer

;----------------------------------------------------------------------------
encode  macro value                     ;translate 80x86 to 6502 format
_base   =       value and 10110101b
_flag_Z =       (value and 01000000b) shr 6
_flag_V =       (value and 00001000b) shr 3
_flag_M =       (value and 00000010b) shr 1
_value	=	_base + (_flag_V Shl 6) + (_flag_M Shl 3) + (_flag_Z Shl 1)
        db      _value
endm

                i=0
flag_encode     equ     this byte       ;encode from 80x86 to 6502 flag format
rept 256
                encode <i>
                i=i+1
endm
;----------------------------------------------------------------------------
decode  macro value                     ;translate 6502 to 80x86 format
_base   =       value and 10110101b
_flag_V =       (value and 01000000b) shr 6
_flag_M =       (value and 00001000b) shr 3
_flag_Z =       (value and 00000010b) shr 1
_value  =       _base + (_flag_Z shl 6) + (_flag_V shl 3) + (_flag_M shl 1)
        db      _value
endm

                i=0
flag_decode     equ     this byte       ;decode from 6502 to 80x86 flag format
rept 256
                decode <i>
                i=i+1
endm
;----------------------------------------------------------------------------
                i=0
striketbl               label dword     ;pixel->cycle lookup
rept 255
                dd      i*(CYCLESPERLINE-HBLANK)/256
                i=i+1
endm
                dd 9 dup (-1)           ;no strike offscreen (pixel 255 will miss)
;----------------------------------------------------------------------------
                align   4
read_tbl        equ     this dword      ;read memory page table
                dd      ram_R           ;page 00h - RAM area
                dd      PPU_R           ;page 20h - PPU read
                dd      IO_R            ;page 40h - I/O read (sound,joystick,etc)
                dd      sram_R          ;page 60h - RAM/SRAM area
                dd      rom_R           ;page 80h - ROM area
                dd      rom_R           ;page A0h - ROM area
                dd      rom_R           ;page C0h - ROM area
                dd      rom_R           ;page E0h - ROM area
;----------------------------------------------------------------------------
                align   4
write_tbl       equ     this dword      ;write memory page table
                dd      ram_W           ;$0000 - RAM
                dd      PPU_W           ;$2000 - PPU
                dd      IO_W            ;$4000 - I/O
                dd      sram_W          ;$6000 - RAM/SRAM
                dd      empty_W         ;$8000 - ROM
                dd      empty_W         ;$A000 - ROM
                dd      empty_W         ;$C000 - ROM
                dd      empty_W         ;$E000 - ROM
;----------------------------------------------------------------------------
mapperinit      dd      mapperinit00,0
                dd      mapperinit01,1
                dd      mapperinit02,2
                dd      mapperinit03,3
                dd      mapperinit04,4
                dd      mapperinit07,7
                dd      mapperinit09,9
                dd      mapperinit11,11
                dd      mapperinit15,15
                dd      mapperinit16,16
                dd      mapperinit17,17
                dd      mapperinit34,34
                dd      mapperinit64,64
                dd      mapperinit68,68
                dd      mapperinit71,71
                dd      mapperinit76,76
                dd      mapperinit99,99
                dd      mapperinit151,151
                dd      mapperinit232,232
                dd      mapperinit666,666
                dd      -1,-1
;----------------------------------------------------------------------------

palmap  dd      nes     ;palette map ptr

nes:
        db 00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0ah,0bh,0ch,0dh,0eh,0fh
        db 10h,11h,12h,13h,14h,15h,16h,17h,18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3ah,3bh,3ch,3dh,3eh,3fh
;           0               4               8               c
castlevania:
        db 0fh,27h,18h,3fh,3fh,25h,3fh,34h,16h,13h,3fh,3fh,20h,23h,3fh,0bh
        db 3fh,3fh,06h,3fh,1bh,3fh,3fh,22h,3fh,24h,3fh,3fh,32h,3fh,3fh,03h
        db 3fh,37h,26h,33h,11h,3fh,10h,3fh,14h,3fh,00h,09h,12h,0fh,3fh,30h
        db 3fh,3fh,2ah,17h,0ch,01h,15h,19h,3fh,3fh,07h,37h,3fh,05h,3fh,3fh
;           0               4               8               c


mario:
        db 18h,3fh,1ch,3fh,3fh,3fh,0bh,17h,10h,3fh,14h,3fh,36h,37h,1ah,3fh
        db 25h,3fh,12h,3fh,0fh,3fh,3fh,3fh,3fh,3fh,22h,19h,3fh,3fh,3ah,21h
        db 3fh,3fh,07h,3fh,3fh,3fh,00h,15h,0ch,3fh,3fh,3fh,3fh,3fh,3fh,3fh
        db 3fh,3fh,07h,16h,3fh,3fh,30h,3ch,3fh,27h,3fh,3fh,29h,3fh,1bh,09h
;           0               4               8               c
iceclimber:
        db 18h,3fh,1ch,3fh,3fh,3fh,01h,17h,10h,3fh,2ah,3fh,36h,37h,1ah,39h
        db 25h,3fh,12h,3fh,0fh,3fh,3fh,26h,3fh,3fh,22h,19h,3fh,0fh,3ah,21h
        db 3fh,0ah,07h,06h,13h,3fh,00h,15h,0ch,3fh,11h,3fh,3fh,38h,3fh,3fh
        db 3fh,3fh,07h,16h,3fh,3fh,30h,3ch,0fh,27h,3fh,31h,29h,3fh,11h,09h
;           0               4               8               c



gradius:
        db 35h,3fh,16h,3fh,1ch,3fh,3fh,15h,3fh,3fh,27h,05h,04h,3fh,3fh,30h
        db 21h,3fh,3fh,3fh,3fh,3fh,36h,12h,3fh,2bh,3fh,3fh,3fh,3fh,3fh,3fh
        db 3fh,31h,3fh,2ah,2ch,0ch,3fh,3fh,3fh,07h,34h,06h,3fh,25h,26h,0fh
        db 3fh,19h,10h,3fh,3fh,3fh,3fh,17h,3fh,11h,3fh,3fh,3fh,3fh,18h,3fh
;           0               4               8               c
hogalley:
        db 35h,3fh,16h,22h,1ch,3fh,3fh,15h,3fh,00h,27h,05h,04h,3fh,3fh,30h
        db 21h,3fh,3fh,29h,3ch,3fh,36h,12h,3fh,2bh,3fh,3fh,3fh,3fh,3fh,01h
        db 3fh,31h,3fh,2ah,2ch,0ch,3fh,3fh,3fh,07h,34h,06h,3fh,25h,26h,0fh
        db 3fh,19h,10h,3fh,3fh,3fh,3fh,17h,3fh,11h,3fh,3fh,3fh,25h,18h,3fh
;           0               4               8               c



goonies:
        db 0fh,3fh,3fh,10h,3fh,30h,31h,3fh,01h,0fh,36h,3fh,3fh,3fh,3fh,3ch
        db 3fh,3fh,3fh,12h,19h,3fh,17h,3fh,00h,3fh,3fh,02h,16h,3fh,3fh,3fh
        db 3fh,3fh,3fh,37h,3fh,27h,26h,20h,3fh,04h,22h,3fh,11h,3fh,3fh,3fh
        db 2ch,3fh,3fh,3fh,07h,2ah,3fh,3fh,3fh,3fh,3fh,38h,13h,3fh,3fh,0ch
;           0               4               8               c
excitebike:
        db 3fh,3fh,3fh,3fh,1ah,30h,3ch,09h,0fh,0fh,3fh,0fh,3fh,3fh,3fh,30h
        db 32h,1ch,3fh,12h,3fh,18h,17h,3fh,0ch,3fh,3fh,02h,16h,3fh,3fh,3fh
        db 3fh,3fh,0fh,37h,3fh,28h,27h,3fh,29h,3fh,21h,3fh,11h,3fh,0fh,3fh
        db 31h,3fh,3fh,3fh,0fh,2ah,28h,3fh,3fh,3fh,3fh,3fh,13h,3fh,3fh,3fh
;           0               4               8               c

;xxxx xxxx xxxx xxxx
;2=challenge banner bg color
;5=track color
;6=stump base
;7=stump top
;9,13=temp outline
;04     track3 track
;05     bike white
;06     b/g biker
;07     track3 stump base
;08     title bg
;09     bike black
;0b     track4 banner bg
;0f     pre-race checker
;10     track1 temp
;11     track1 banner
;13     pre-race checker
;15     bonus ramp 
;16     track1 track
;18     track4 bg
;1b     win banner
;1c     pre-race
;(1d)   flash
;(1f)   flash
;22     track2 stump base
;23     trophy stand
;25     pre-race
;26     track1 stump top
;28     bonus track color
;2a     trophy sky, title
;2c     track2 track color
;2e     pre-race BG
;30     letters in name reg
;34     track1 stump base
;35     track3 stump top
;36     track2 bg
;3c     b/w biker

;goonies:
;16=17/27
;1c=05/16
;2a=22/21


;----------------------------------------------------------------------------
code    ends
        end
