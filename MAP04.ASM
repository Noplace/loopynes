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

        public mapperinit04
;----------------------------------------------------------------------------
mapperinit04:;
;----------------------------------------------------------------------------
        mov [write_tbl+4*4],offset write0
        mov [write_tbl+5*4],offset write1
        mov [write_tbl+6*4],offset write2
        mov [write_tbl+7*4],offset write3

        xor al,al
        call map89AB
        mov al,-1
        call mapCDEF
        call flush

        mov [bank0],0
        mov [bank1],0
        mov [irqen],0
        mov [scanlinehook],offset hook

        ret
;----------------------------------------------------------------------------
write0:;        $8000-8001
;----------------------------------------------------------------------------
        and edi,1
        jnz w8001

        mov ah,[reg0]
        mov [reg0],al
        xor al,ah
        js abc
        ret

abc:    mov edi,offset chr_map          ;swap chr on base change
        mov eax,[edi+00h]
        mov ebp,[edi+10h]
        mov [edi+10h],eax
        mov [edi+00h],ebp
        mov eax,[edi+04h]
        mov ebp,[edi+14h]
        mov [edi+14h],eax
        mov [edi+04h],ebp
        mov eax,[edi+08h]
        mov ebp,[edi+18h]
        mov [edi+18h],eax
        mov [edi+08h],ebp
        mov eax,[edi+0ch]
        mov ebp,[edi+1ch]
        mov [edi+1ch],eax
        mov [edi+0ch],ebp
        jmp newchrmap
w8001:
        movzx ebp,[reg0]
        and ebp,7
        movzx edi,[reg0]
        and edi,80h
        shr edi,3                       ;edi=chr base
        jmp [commandlist+ebp*4]
cmd0:
        shr eax,1
        shl eax,13                      ;map chr (0000-07ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi],eax
        add eax,1000h
        mov [chr_map+edi+4],eax
        jmp newchrmap
cmd1:
        shr eax,1
        shl eax,13                      ;map chr (0800-0fff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi+8],eax
        add eax,1000h
        mov [chr_map+edi+12],eax
        jmp newchrmap
cmd2:
        shl eax,12                      ;map chr (1000-13ff)
        xor edi,10h
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi],eax
        jmp newchrmap
cmd3:
        shl eax,12                      ;map chr (1400-17ff)
        xor edi,10h
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi+4],eax
        jmp newchrmap
cmd4:
        shl eax,12                      ;map chr (1800-1bff)
        xor edi,10h
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi+8],eax
        jmp newchrmap
cmd5:
        shl eax,12                      ;map chr (1c00-1fff)
        xor edi,10h
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi+12],eax
        jmp newchrmap
cmd6:                                   ;$8000/$A000 select
        mov [bank0],al
        jmp romswitch
cmd7:                                   ;$A000/$C000 select
        mov [bank1],al
        jmp romswitch
;----------------------------------------------------------------------------
romswitch:
;----------------------------------------------------------------------------
        mov al,-2
        test [reg0],40h
        jnz rs0
                                        ;$8000/$A000 swapping
        call mapCD                      ;do hardwired bank
        mov al,[bank0]                  ;do first switchable bank
        call map89
        mov al,[bank1]                  ;do second switchable bank
        call mapAB
        jmp flush
rs0:;- - - - - - - - -                  ;$A000/$C000 swapping
        call map89
        mov al,[bank0]
        call mapCD
        mov al,[bank1]
        call mapAB
        jmp flush
;----------------------------------------------------------------------------
write1:;        $A000-A001
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2

        trace tMMC4,al
        and edi,1
        jnz wA001
test al,0feh
jnz empty_W

        test al,1
        jmp mirror2V
wA001:
        trace tMMC5,al

        ;?

        ret
;----------------------------------------------------------------------------
write2:;        C000-C001
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
        and edi,1
        jnz wC001
        trace tMMC0,al
        mov [latch],al

        cmp [resetmode],1
        jne done
        mov al,[latch]
        mov [countdown],al
done:
        ret
wC001:
        trace tMMC1,al
        mov [resetmode],1

        mov al,[latch]
        mov [countdown],al

        ret
;----------------------------------------------------------------------------
write3:;        E000-E001
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
        and edi,1
        jnz wE001
        trace tMMC2,al
        mov [irqen],0           ;stop counting

        cmp [resetmode],1
        jne done
        mov al,[latch]
        mov [countdown],al

        ret
wE001:
        trace tMMC3,al
        mov [irqen],1           ;begin counting

        cmp [resetmode],1
        jne done
        mov al,[latch]
        mov [countdown],al

        ret
;----------------------------------------------------------------------------
hook:;
;----------------------------------------------------------------------------
        test [ctrl1],CR1_BG+CR1_OBJ     ;screen on?
        jz h0
        cmp [scanline],260
        ja h1
        cmp [scanline],239
        ja h0
h1:
        mov [resetmode],0
        sub [countdown],1
        jnc h0;z h0                       ;no timeout
        mov [resetmode],1
        cmp [irqen],0
        je h0                   ;not counting

        or [int_flags],IRQ      ;trigger IRQ
h0:
        ret
;----------------------------------------------------------------------------
                align   4

commandlist     dd      cmd0,cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7

countdown       equ     mapperdata+0    ;$C000
latch           equ     mapperdata+1    ;$C001
irqen           equ     mapperdata+2    ;counter enable
reg0            equ     mapperdata+3    ;$8000
bank0           equ     mapperdata+64   ;cmd6 value
bank1           equ     mapperdata+65   ;cmd7 value
resetmode       equ     mapperdata+66
;----------------------------------------------------------------------------
code    ends
        end
