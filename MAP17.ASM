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
        include map00.h
        include memory.h
include debug.h
include kb.h
        public mapperinit17
;----------------------------------------------------------------------------
mapperinit17:;
;----------------------------------------------------------------------------
        xor al,al                               ;1st bank to 8000-BFFF
        call map89AB
        mov al,-1                               ;last bank to C000-FFFF
        call mapCDEF
        call flush
xor al,al
inc al
call mirror1

        mov [write_tbl+2*4],offset w4XXX        ;trap 4xxx writes
        mov [scanlinehook],offset hook
        mov [irqen],0
        ret
;----------------------------------------------------------------------------
w4XXX:
;----------------------------------------------------------------------------
        cmp edi,4018h
        jb IO_W
if DEBUG
        cmp edi,42feh
        je w42FE
        cmp edi,42ffh
        je w42FF
        cmp edi,4501h
        jb empty_W
        cmp edi,451fh
        ja empty_W
endif
        and edi,1fh
        jmp [write45xx+edi*4]
;----------------------------------------------------------------------------
w42FE:
mov byte ptr [prof1],al
xor al,al
call mirror1
        ret
;----------------------------------------------------------------------------
w42FF:
mov byte ptr [prof0],al
;        cmp al,30h
;        je mirror2V
;        test al,1
;        jmp mirror2H
        ret
;----------------------------------------------------------------------------
w4504:
        call map89
        jmp flush
;----------------------------------------------------------------------------
w4505:
        call mapAB
        jmp flush
;----------------------------------------------------------------------------
w4506:
        call mapCD
        jmp flush
;----------------------------------------------------------------------------
w4507:
        call mapEF
        jmp flush
;----------------------------------------------------------------------------
w451x:
        shl eax,12
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi*4-40h],eax
        add eax,1000h
        mov [chr_map+edi*4-40h+4],eax
        jmp newchrmap
;----------------------------------------------------------------------------
w4501:
trace tMMC2,al
        mov [counter],0 ;[irqen],al
        ret
;----------------------------------------------------------------------------
w4502:
trace tMMC0,al
        mov byte ptr [counter],al
        ret
;----------------------------------------------------------------------------
w4503:
trace tMMC1,al
   ;     mov [irqen],1
        mov byte ptr [counter+1],al
        ret
;----------------------------------------------------------------------------
hook:
        cmp [counter],0
        je h0
        add [irqfrac],FRACTION
        adc [counter],CYCLESPERLINE
        cmp [counter],0ffffh
        jb h0
        mov [counter],0ffffh
;        cmp [irqen],0
;        je h0
;        mov [irqen],0
        or [int_flags],IRQ
h0:
        ret
;----------------------------------------------------------------------------
                align   4
write45xx       dd      empty_W
                dd      w4501
                dd      w4502
                dd      w4503
                dd      w4504
                dd      w4505
                dd      w4506
                dd      w4507
                dd      empty_W,empty_W,empty_W,empty_W
                dd      empty_W,empty_W,empty_W,empty_W
                dd      w451x
                dd      w451x
                dd      w451x
                dd      w451x
                dd      w451x
                dd      w451x
                dd      w451x
                dd      w451x
                dd      empty_W,empty_W,empty_W,empty_W
                dd      empty_W,empty_W,w42FE,w42FF

irqen           equ     mapperdata+0
counter         equ     dword ptr mapperdata+1

irqfrac         equ     dword ptr mapperdata+64
;----------------------------------------------------------------------------
code    ends
        end
