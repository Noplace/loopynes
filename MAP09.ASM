        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include file.h
        include ppu.h
        include empty.h
        include equates.h
        include debug.h
        include kb.h
        include map00.h

        public mapperinit09
        public bglatch
        public sprite8latch
        public sprite16latch
;----------------------------------------------------------------------------
mapperinit09:;
;----------------------------------------------------------------------------
        mov al,-1                       ;map everything to last bank
        call map89ABCDEF
        xor al,al                       ;map $8000-$9FFF to 1st bank
        call map89
        call flush

        mov [write_tbl+5*4],offset write0
        mov [write_tbl+6*4],offset write1 
        mov [write_tbl+7*4],offset write2 

        mov word ptr [bg1hook],0d3ffh ;call ebx
        mov word ptr [bg8hook],0d3ffh ;call ebx
        mov word ptr [sprite8hook],0d7ffh ;call edi
        mov word ptr [sprite16hook],0d7ffh ;call edi

        and [cartflags],not SCREEN4     ;no 4-screen (many roms have bad headers)

        ret
;----------------------------------------------------------------------------
write0:;        ($a000-$bfff)
;----------------------------------------------------------------------------
        cmp edi,0b000h
        jae wB000
wA000:
        call map89
        jmp flush
wB000:
        trace tMMC1,al
        mov [reg0],al
        cmp [latch0],0fdh
        je chrswap
        ret
;----------------------------------------------------------------------------
write1:;        ($c000-$dfff)
;----------------------------------------------------------------------------
        cmp edi,0d000h
        jae wD000
        trace tMMC2,al
        mov [reg1],al
        cmp [latch0],0feh
        je chrswap
        ret
wD000:
        trace tMMC3,al
        mov [reg2],al
        cmp [latch1],0fdh
        je chrswap
        ret
;----------------------------------------------------------------------------
write2:;        ($e000-$ffff)
;----------------------------------------------------------------------------
        cmp edi,0f000h
        jae wF000
wE000:
        trace tMMC4,al
        mov [reg3],al
        cmp [latch1],0feh
        je chrswap
        ret
wF000:
        test al,1
        jmp mirror2V
;----------------------------------------------------------------------------
sprite8latch:;  trigger latch from sprite
;       in:
;               eax=fdh-ffh
;       out:
;               nothing
;----------------------------------------------------------------------------
        cmp al,0fdh
        je s8l0
        cmp al,0feh
        je s8l0
        ret
s8l0:
        test [ctrl0],CR0_SPRITESRC
        jnz s8l1
        mov [latch0],al
        jmp chrswap
s8l1:
        mov [latch1],al
        jmp chrswap
;----------------------------------------------------------------------------
sprite16latch:;   trigger latch from sprite16
;       in:
;               eax=fdh-ffh
;       out:
;               nothing
;----------------------------------------------------------------------------
        cmp al,07eh
        jne sl0
        mov [latch0],0fdh
        jmp chrswap
sl0:
        cmp al,07fh
        jne sl1
        mov [latch0],0feh
        jmp chrswap
sl1:
        cmp al,0feh
        jne sl2
        mov [latch1],0fdh
        jmp chrswap
sl2:
        cmp al,0ffh
        jne sl3
        mov [latch1],0feh
        jmp chrswap
sl3:
        ret
;----------------------------------------------------------------------------
bglatch:;       trigger latch from BG
;       in:
;               eax=tile#
;       out:
;               nothing
;----------------------------------------------------------------------------
        cmp al,0fdh
        je bgl0
        cmp al,0feh
        je bgl0
        ret
bgl0:
        test [ctrl0],CR0_BGSRC
        jnz bgl1
        mov [latch0],al
        jmp chrswap
bgl1:
        mov [latch1],al
        ;..
;----------------------------------------------------------------------------
chrswap:;       all regs preserved
;----------------------------------------------------------------------------
        push eax
        push edi

        mov al,[reg0]
        cmp [latch0],0fdh
        je cs0
        mov al,[reg1]
cs0:                                    ;map $0000-0fff
        shl eax,14
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+00],eax
        add eax,1000h
        mov [chr_map+04],eax
        add eax,1000h
        mov [chr_map+08],eax
        add eax,1000h
        mov [chr_map+12],eax

        mov al,[reg2]
        cmp [latch1],0fdh
        je cs1
        mov al,[reg3]
cs1:                                    ;map $1000-1fff
        shl eax,14
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax

        call newchrmap

        pop edi
        pop eax
cs2:
        ret
;----------------------------------------------------------------------------
        align 4

latch0  equ     mapperdata+0            ;(0000-0fff)
latch1  equ     mapperdata+1            ;(1000-1fff)
reg0    equ     mapperdata+2            ;B000
reg1    equ     mapperdata+3            ;C000
reg2    equ     mapperdata+4            ;D000
reg3    equ     mapperdata+5            ;E000

;----------------------------------------------------------------------------
code    ends
        end
