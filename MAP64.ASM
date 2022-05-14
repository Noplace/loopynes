        .386p
code    segment public use32
        assume cs:code,ds:code

        include 6502.h
        include empty.h
        include file.h
        include ppu.h
        include data.h
        include equates.h
        include memory.h
        include debug.h
        include kb.h
        include map00.h

        public mapperinit64
;----------------------------------------------------------------------------
mapperinit64:;
;----------------------------------------------------------------------------
        mov al,-1
        call map89
        mov al,-1
        call mapAB
        mov al,-1
        call mapCD
        mov al,-1
        call mapEF
        call flush

        mov [write_tbl+4*4],offset write0
        mov [write_tbl+5*4],offset write1
        mov [write_tbl+6*4],offset write2
        mov [write_tbl+7*4],offset write3
mov [countdown],0
        mov [irqen],0
        mov [scanlinehook],offset hook

        ret
;----------------------------------------------------------------------------
write0:
;----------------------------------------------------------------------------
        cmp edi,8000h
        jne w8001
        mov [reg0],al
      trace tMMC4,al
        ret
w8001:
        cmp edi,8001h
        jne empty_W
      trace tMMC5,al

        movzx edi,[reg0]
        mov ebp,edi
        and edi,80h
        and ebp,0fh
        shr edi,3                       ;edi=chr base
        jmp [command+ebp*4]
cmd0:
        shl eax,12                      ;map chr (0000-07ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+edi+0],eax
        add eax,1000h
        mov [chr_map+edi+4],eax
        jmp newchrmap
cmd1:
        shl eax,12                      ;map chr (0800-0fff)
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
        mov [chr_map+edi+0],eax
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
cmd6:
        test [reg0],40h
        jz blah89
        jmp blahAB
cmd7:
        test [reg0],40h
        jz blahAB
        jmp blahCD
cmd8:
        shl eax,12                      ;map chr (0400-07ff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+4],eax
        jmp newchrmap
cmd9:
        shl eax,12                      ;map chr (0c00-0fff)
        and eax,[chrmask]
        add eax,[chr_ptr]
        mov [chr_map+12],eax
        jmp newchrmap
cmd10:
cmd11:
cmd12:
cmd13:
cmd14:
if DEBUG
    or [int_flags],DEBUG2
    mov [debugmsg],offset msg04
endif
        ret

cmd15:
        test [reg0],40h
        jz blahCD
      ;  jmp blah89
      ;  .
      ;  .
blah89:
        call map89
        jmp flush
blahAB:
        call mapAB
        jmp flush
blahCD:
        call mapCD
        jmp flush
blahEF:
        call mapEF
        jmp flush
;----------------------------------------------------------------------------
write1:;        $A000
;----------------------------------------------------------------------------
        cmp edi,0a000h
        jne empty_W

        test al,1                       ;set mirror
        jmp mirror2V
;----------------------------------------------------------------------------
write2:;        C000-C001
;----------------------------------------------------------------------------
        cmp edi,0c000h
        jne wC001
        trace tMMC0,al
        and eax,0ffh
        mov [countdown],eax
     mov [irqen],0           ;stop counting
        ret
wC001:
        cmp edi,0c001h
        jne empty_W
        trace tMMC1,al
        ret
;----------------------------------------------------------------------------
write3:;        E000-E001
;----------------------------------------------------------------------------
        cmp edi,0e000h
        jne wE001
        trace tMMC2,al
        mov [irqen],0           ;stop counting
        and [int_flags],not IRQ ;stop pending irqs
        ret
wE001:
        cmp edi,0e001h
        jne empty_W
        trace tMMC3,1
        mov [irqen],1           ;begin counting
        ret
;----------------------------------------------------------------------------
hook:;
;----------------------------------------------------------------------------
        test [ctrl1],CR1_BG+CR1_OBJ     ;screen on?
        jz h0
        cmp [scanline],239
        ja h0
h1:
        cmp [irqen],0
        je h0                   ;not counting
      ;  cmp [countdown],0
      ;  je h0                   ;done counting
      test [countdown],80000000h
      js h0
        dec [countdown]
        jns h0                  ;no timeout
        or [int_flags],IRQ      ;trigger IRQ
h0:
        ret
;----------------------------------------------------------------------------
                align 4

command         dd      cmd0,cmd1,cmd2,cmd3,cmd4,cmd5,cmd6,cmd7
                dd      cmd8,cmd9,cmd10,cmd11,cmd12,cmd13,cmd14,cmd15

countdown       equ     dword ptr mapperdata+64
reg0            equ     mapperdata+68
irqen           equ     mapperdata+69

;----------------------------------------------------------------------------
code    ends
        end
