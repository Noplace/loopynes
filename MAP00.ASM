        .386p
code    segment public use32
        assume cs:code,ds:code

        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include macros.h
        include 6502.h
        include ggenie.h
;include memory.h
        public mapperinit00
        public mirror1
        public mirror2H
        public mirror2V
        public mirror4
        public map89
        public mapAB
        public mapCD
        public mapEF
        public map89AB
        public mapCDEF
        public map89ABCDEF
        public flush
        public pal_init
;----------------------------------------------------------------------------
mapperinit00:;
;----------------------------------------------------------------------------
        xor al,al                       ;1st bank to 8000-BFFF
        call map89AB
        mov al,-1                       ;last bank to C000-FFFF
        call mapCDEF
        call flush

        test [cartflags],MIRROR
        call mirror2H

        ret
;----------------------------------------------------------------------------
mirror1:;       1 screen mirror
;       in:
;               Z=source
;                       1=2000
;                       0=2400
;----------------------------------------------------------------------------
        jnz mi10

        mov [name0_map],offset vram+2000h
        mov [name1_map],offset vram+2000h
        mov [name2_map],offset vram+2000h
        mov [name3_map],offset vram+2000h
        ret
mi10:
        mov [name0_map],offset vram+2400h
        mov [name1_map],offset vram+2400h
        mov [name2_map],offset vram+2400h
        mov [name3_map],offset vram+2400h
        ret
;----------------------------------------------------------------------------
mirror2V:;      2 screen mirror
;
;       in:
;               Z=mirror type (1=vertical)
;----------------------------------------------------------------------------
        jz mi20
mi21:
        test [cartflags],SCREEN4
        jnz mirror4
        mov [name0_map],offset vram+2000h
        mov [name1_map],offset vram+2000h
        mov [name2_map],offset vram+2400h
        mov [name3_map],offset vram+2400h
        ret
mirror2H:;------------------;1=horizontal
        jz mi21
mi20:
        test [cartflags],SCREEN4
        jnz mirror4
        mov [name0_map],offset vram+2000h
        mov [name1_map],offset vram+2400h
        mov [name2_map],offset vram+2000h
        mov [name3_map],offset vram+2400h
        ret
;----------------------------------------------------------------------------
mirror4:;       4 screen
;----------------------------------------------------------------------------
        mov [name0_map],offset vram+2000h
        mov [name1_map],offset vram+2400h
        mov [name2_map],offset vram+2800h
        mov [name3_map],offset vram+2c00h
        ret
;----------------------------------------------------------------------------
map89:;        map 8k bank to $8000-$9FFF
;       in:
;               al=bank
;       out:
;               eax,edi=?
;               esi=new pc
;----------------------------------------------------------------------------
        shl eax,13
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,8000h
        mov [memmap+4*4],eax
        ret
;----------------------------------------------------------------------------
mapAB:;        map 8k bank to $A000-$BFFF
;----------------------------------------------------------------------------
        shl eax,13
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,0a000h
        mov [memmap+5*4],eax
        ret
;----------------------------------------------------------------------------
mapCD:;        map 8k bank to $C000-$DFFF
;----------------------------------------------------------------------------
        shl eax,13
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,0c000h
        mov [memmap+6*4],eax
        ret
;----------------------------------------------------------------------------
mapEF:;        map 8k bank to $E000-$FFFF
;----------------------------------------------------------------------------
        shl eax,13
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,0e000h
        mov [memmap+7*4],eax
        ret
;----------------------------------------------------------------------------
map89AB:;      map 16k bank to $8000-$BFFF
;----------------------------------------------------------------------------
        shl eax,14
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,8000h
        mov [memmap+4*4],eax
        mov [memmap+5*4],eax
        ret
;----------------------------------------------------------------------------
mapCDEF:;      map 16k bank to $C000-$FFFF
;----------------------------------------------------------------------------
        shl eax,14
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,0c000h
        mov [memmap+6*4],eax
        mov [memmap+7*4],eax
        ret
;----------------------------------------------------------------------------
map89ABCDEF:;   map 32k bank to $8000-$FFFF
;----------------------------------------------------------------------------
        shl eax,15
        and eax,[rommask]
        add eax,[rom_ptr]
        sub eax,8000h
        mov [memmap+4*4],eax
        mov [memmap+5*4],eax
        mov [memmap+6*4],eax
        mov [memmap+7*4],eax
        ret
;----------------------------------------------------------------------------
flush:;         setup ggenie and PC
;----------------------------------------------------------------------------
        sub esi,[lastbank]
        encodePC
        cmp [GGcodes],0
        jne flush2
        ret
;----------------------------------------------------------------------------
pal_init:;      set VS palette map
;----------------------------------------------------------------------------
        test [cartflags],VS             ;only VS!
        jz pi9

        mov edi,[memmap+7*4]
        mov ecx,COUNT
        mov eax,[edi+NMI_VECTOR]
pi0:
        dec ecx
        js pi9
        cmp [biglist+ecx*8],eax
        jne pi0

        mov eax,[biglist+ecx*8+4]
        mov [palmap],eax
pi9:
        ret

biglist dd 080008281h,gradius           ;pinball           RP2C04-0001
        dd 08000809ch,hogalley          ;hogans alley
                                        ;baseball
                                        ;sky kid
                                        ;super xevious
        dd 0f422f492h,gradius           ;gradius
        dd 0fff3fd92h,hogalley          ;platoon

        dd 0800080ceh,castlevania       ;golf / ladygolf   RP2C04-0002
        dd 080008053h,castlevania       ;mach rider
        dd 0c008c062h,castlevania       ;castlevania

        dd 085af863fh,excitebike        ;excitebike        RP2C04-0003
        dd 0800080bah,goonies           ;soccer
        dd 0f007f0a5h,goonies           ;goonies
        dd 0ff008005h,goonies           ;dr mario

        dd 08000810ah,mario             ;super mario bros  RP2C04-0004
        dd 0b578b5deh,iceclimber        ;ice climber
                                        ;RBI baseball

                                        ;tennis            RC2C03B
        dd 080008080h,nes               ;duckhunt          RC2C03B

                                        ;gumshoe           RC2C05-03

                                        ;top gun           RC2C05-04
COUNT equ ($-biglist)/8
;----------------------------------------------------------------------------
code    ends
        end
