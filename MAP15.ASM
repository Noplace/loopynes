        .386p
code    segment public use32
        assume cs:code,ds:code

        include 6502.h
        include map00.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include debug.h

        public mapperinit15
;----------------------------------------------------------------------------
mapperinit15:;
;----------------------------------------------------------------------------
        xor al,al
        call map89ABCDEF
        call flush

        mov [write_tbl+4*4],offset write0

        ret
;----------------------------------------------------------------------------
write0:
;----------------------------------------------------------------------------
        cmp edi,8000h
        jne w1
        test al,40h
        call mirror2V

        mov ebp,eax
        call map89AB
        mov eax,ebp
        inc al
        call mapCDEF
        jmp flush
w1:
        cmp edi,8001h
        jne w2
        call mapCDEF
        jmp flush
w2:
        cmp edi,8002h
        jne w3
        rol al,1
        mov ebp,eax
        call map89
        mov eax,ebp
        call mapAB
        mov eax,ebp
        call mapCD
        mov eax,ebp
        call mapEF
        jmp flush
w3:
        cmp edi,8003h
        jne w9
        test al,40h
        call mirror2V
        call mapCDEF
        jmp flush
w9:
if DEBUG
        or [int_flags],DEBUG2
        mov [debugmsg],offset msg44
endif
        ret
;----------------------------------------------------------------------------
code    ends
        end
