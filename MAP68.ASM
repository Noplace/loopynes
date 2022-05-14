        .386p
code    segment public use32
        assume cs:code,ds:code

        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
include debug.h
include kb.h
include 6502.h
include memory.h
        public mapperinit68
;----------------------------------------------------------------------------
mapperinit68:;
;----------------------------------------------------------------------------
        xor al,al
        call map89AB
        mov al,-1
        call mapCDEF
        call flush

        mov [write_tbl+4*4],offset w8000        ;redirect rom writes
        mov [write_tbl+5*4],offset w8000
        mov [write_tbl+7*4],offset wE000

        test [cartflags],MIRROR         ;set mirror
        call mirror2H

        call pal_init                   ;check VS Platoon
        ret
;----------------------------------------------------------------------------
w8000:
;----------------------------------------------------------------------------
test edi,07ffh
jnz empty_W
test edi,0800h
jz empty_W
        and edi,3000h
        shr edi,9
        shl eax,12
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi],eax
        add eax,1000h
        mov [chr_map+edi+4],eax
        jmp newchrmap
;----------------------------------------------------------------------------
wE000:
;----------------------------------------------------------------------------
test edi,07ffh
jnz empty_W
test edi,0800h
jz empty_W
        cmp edi,0f000h
        jae wF000
mov byte ptr [prof0],al
        test al,2
        jnz asdf
        and al,1
        jmp mirror2H
asdf:
        and al,1
        jmp mirror1
wF000:
mov byte ptr [prof1],al
        call map89AB
        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
