        .386p
code    segment public use32
        assume cs:code,ds:code

        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
include memory.h
include 6502.h
include debug.h
include kb.h
        public mapperinit232
;----------------------------------------------------------------------------
mapperinit232:;
;----------------------------------------------------------------------------
        mov al,-1
        call map89ABCDEF
        call flush

        mov [write_tbl+3*4],offset empty_W      ;redirect rom writes
        mov [write_tbl+4*4],offset w0         ;redirect rom writes
        mov [write_tbl+5*4],offset w0         ;redirect rom writes
        mov [write_tbl+6*4],offset w0         ;redirect rom writes
        mov [write_tbl+7*4],offset w0         ;redirect rom writes

        test [cartflags],MIRROR
        call mirror2H

        ret
;----------------------------------------------------------------------------
w0:
;----------------------------------------------------------------------------
        test edi,1
        jnz w1
or [int_flags],DEBUG2
        shr al,1
        and eax,0ch
        mov [bank],eax
        ret

bank dd ?
;----------------------------------------------------------------------------
w1:
;----------------------------------------------------------------------------
or [int_flags],DEBUG2

        and eax,03h
        or eax,[bank]
        call map89AB

        jmp flush
;----------------------------------------------------------------------------
code    ends
        end
