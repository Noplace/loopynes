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

        public mapperinit151

;----------------------------------------------------------------------------
mapperinit151:;
;----------------------------------------------------------------------------
        mov al,-1                       ;everything to last bank
        call map89ABCDEF
        call flush

        test [cartflags],MIRROR
        call mirror2H
;     call mirror4     ;?

        mov [write_tbl+4*4],offset write89
        mov [write_tbl+5*4],offset writeAB
        mov [write_tbl+6*4],offset writeCD
        mov [write_tbl+7*4],offset writeEF

        call pal_init
        ret
;----------------------------------------------------------------------------
write89:;
;----------------------------------------------------------------------------
        cmp edi,8000h
        jne w9000

test al,0f0h
jz ok1
or [int_flags],DEBUG2
ok1:
        call map89
        jmp flush
w9000:
        cmp edi,09000h
        jne huh
cmp al,0
jne huh
;        trace tMMC0,al
        ret
;----------------------------------------------------------------------------
writeAB:;
;----------------------------------------------------------------------------
        cmp edi,0a000h
        jne wb000

test al,0f0h
jz ok2
or [int_flags],DEBUG2
ok2:
        call mapAB
        jmp flush
wb000:
        or [int_flags],DEBUG2
        ret
;----------------------------------------------------------------------------
writeCD:;
;----------------------------------------------------------------------------
        cmp edi,0c000h
        jne wd000

test al,0f0h
jz ok3
or [int_flags],DEBUG2
ok3:
        call mapCD
        jmp flush
wd000:
        or [int_flags],DEBUG2
        ret
;----------------------------------------------------------------------------
writeEF:;
;----------------------------------------------------------------------------
test al,0f0h
jz ok
or [int_flags],DEBUG2
ok:
        cmp edi,0e000h
        jne wf000              ;>efff?

        shl eax,14
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map],eax
        add eax,1000h
        mov [chr_map+4],eax
        add eax,1000h
        mov [chr_map+8],eax
        add eax,1000h
        mov [chr_map+12],eax
        add eax,1000h
        call newchrmap
        ret
wf000:
        cmp edi,0f000h
        jne huh

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
        ret
huh:
        or [int_flags],DEBUG2
        ret
;----------------------------------------------------------------------------
code    ends
        end
