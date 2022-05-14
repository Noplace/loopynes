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

        public mapperinit16
;----------------------------------------------------------------------------
mapperinit16:;
;----------------------------------------------------------------------------
        mov [write_tbl+3*4],offset wXXXX
        mov [write_tbl+4*4],offset wXXXX

        xor al,al
        call map89AB
        mov al,-1
        call mapCDEF
        call flush

        mov [irqenable],0
;        mov dword ptr [irqcount],0ffffh
        mov [scanlinehook],offset hook

        ret
;----------------------------------------------------------------------------
wXXXX:;
;----------------------------------------------------------------------------
        and edi,0fh
        jmp [table+edi*4]
w0:;1234567--------------------
trace tMMC0,al
        shl eax,12
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi*4],eax
        jmp newchrmap
w8:;---------------------------
trace tMMC1,al
        call map89AB
        jmp flush
w9:;---------------------------
trace tMMC2,al
        and al,3
        jz mirror2V     ;0=vertical mirror
        cmp al,1
        je mirror2H     ;1=horz mirror
        cmp al,2        ;2=2000 mirror (1-screen)
        jmp mirror1     ;3=2400 mirror (1-screen)
wA:;---------------------------
trace tMMC3,al
        mov [irqenable],al
        and dword ptr [irqcount],0ffffh
        ret
wB:;---------------------------
trace tMMC4,al
        mov [irqcount],al
        ret
wC:;---------------------------
trace tMMC5,al
        mov [irqcount+1],al
        ret
wD:;---------------------------
wE:;---------------------------
wF:;---------------------------
if DEBUG
        or [int_flags],DEBUG2
endif
        ret
;----------------------------------------------------------------------------
hook:;
;----------------------------------------------------------------------------
        cmp [irqenable],0
        je h0

        sub dword ptr [irqfrac],FRACTION
        sbb dword ptr [irqcount],CYCLESPERLINE
        jnc h0
        or [int_flags],IRQ      ;trigger IRQ
h0:
        ret
;----------------------------------------------------------------------------
                align   4

table   dd      w0,w0,w0,w0,w0,w0,w0,w0,w8,w9,wA,wB,wC,wD,wE,wF

irqfrac         equ     mapperdata+64
irqcount        equ     mapperdata+68
irqenable       equ     mapperdata+72
;----------------------------------------------------------------------------
code    ends
        end
