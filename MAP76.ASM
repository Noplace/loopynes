        .386p
code    segment public use32
        assume cs:code,ds:code

        include empty.h
        include kb.h
        include file.h
        include 6502.h
        include ppu.h
        include data.h
        include equates.h
        include debug.h
        include memory.h
        include map00.h
include 6502.h
        public mapperinit76
;----------------------------------------------------------------------------
mapperinit76:;
;----------------------------------------------------------------------------
        mov [write_tbl+4*4],offset write0
;        mov [write_tbl+5*4],offset write1
;        mov [write_tbl+6*4],offset write2
;        mov [write_tbl+7*4],offset write3

        mov al,-1
        call map89ABCDEF
        call flush

        test [cartflags],MIRROR
        call mirror2H

;        mov [scanlinehook],offset hook

        ret
;----------------------------------------------------------------------------
write0:;        $8000-8001
;----------------------------------------------------------------------------
   cmp edi,8001h
   je w8001
   cmp edi,8000h
   jne empty_W
        and edi,1
        jnz w8001
        mov [reg0],al
        ret
w8001:
        movzx ebp,[reg0]
   cmp ebp,7
   ja empty_W
        and ebp,7
        jmp [commandlist+ebp*4]
cmd0:
        jmp empty_W
cmd1:
        jmp empty_W
cmd2:
        shl eax,13                      ;map chr (1000-17ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+00h],eax
        add eax,1000h
        mov [chr_map+04h],eax
        jmp newchrmap
cmd3:
        shl eax,13                      ;map chr (1000-17ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+08h],eax
        add eax,1000h
        mov [chr_map+0ch],eax
        jmp newchrmap
cmd4:
        shl eax,13                      ;map chr (1000-17ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+10h],eax
        add eax,1000h
        mov [chr_map+14h],eax
        jmp newchrmap
cmd5:
        shl eax,13                      ;map chr (1800-1fff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+18h],eax
        add eax,1000h
        mov [chr_map+1ch],eax
        jmp newchrmap
cmd6:
        call map89
        jmp flush
cmd7:
        call mapAB
        jmp flush
;----------------------------------------------------------------------------
hook:;
;----------------------------------------------------------------------------
        ret
;----------------------------------------------------------------------------
                align   4

commandlist     dd      cmd0,cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7

reg0            equ     mapperdata+0    ;$8000 command
;----------------------------------------------------------------------------
code    ends
        end
