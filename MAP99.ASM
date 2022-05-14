        .386p
code    segment public use32
        assume cs:code,ds:code

        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include 6502.h
        include io.h
        include input.h
        include debug.h
        include map00.h

        public mapperinit99
;----------------------------------------------------------------------------
mapperinit99:;
;----------------------------------------------------------------------------
        xor al,al                       ;1st bank to 8000-BFFF
        call map89AB
        mov al,-1                       ;last bank to C000-FFFF
        call mapCDEF
        call flush

        mov [write_tbl+2*4],offset io   ;process 4016 writes..
        call mirror4                    ;4 screen..
        call pal_init                   ;palette..

        ret
;----------------------------------------------------------------------------
io:
;----------------------------------------------------------------------------
        cmp edi,4016h
        jne IO_W
;test al,0f8h
;jz ok
;or [int_flags],DEBUG2
;ok:
        push eax

        test al,04h
        jnz bank1
bank0:
        mov eax,[chr_ptr]
        mov [chr_map],eax               ;map chr ($0000-1fff)
        add eax,1000h
        mov [chr_map+4],eax
        add eax,1000h
        mov [chr_map+8],eax
        add eax,1000h
        mov [chr_map+12],eax
        add eax,1000h
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax
        call newchrmap
        pop eax
        jmp joy0_W
bank1:
        mov eax,[chr_ptr]
        add eax,8000h
        mov [chr_map],eax
        add eax,1000h
        mov [chr_map+4],eax
        add eax,1000h
        mov [chr_map+8],eax
        add eax,1000h
        mov [chr_map+12],eax
        add eax,1000h
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax
        call newchrmap
        pop eax
        jmp joy0_W
;----------------------------------------------------------------------------
code    ends
        end
