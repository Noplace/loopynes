        .386p
code    segment public use32
        assume cs:code,ds:code

        include 6502.h
        include map00.h
        include empty.h
        include file.h
        include memory.h
        include ppu.h
        include data.h
        include equates.h
        include debug.h
        include kb.h

        public mapperinit01
;----------------------------------------------------------------------------
mapperinit01:;
;----------------------------------------------------------------------------
        mov [write_tbl+4*4],offset write0
        mov [write_tbl+5*4],offset write1
        mov [write_tbl+6*4],offset write2
        mov [write_tbl+7*4],offset write3

        mov [reg0],01110b
        mov [reg1],10000b
        mov [reg2],10000b
        mov [reg3],00000b

        call reset
        jmp pal_init            ;VS Dr Mario
reset:
        mov [latch],0
        mov [latchbit],0
        or [reg0],01110b

        call romswitch
        ret
;----------------------------------------------------------------------------
write0:;        ($8000-$9FFF)
;----------------------------------------------------------------------------
        or al,al
        js reset

        and al,1
        mov ah,cl
        mov cl,[latchbit]
        inc [latchbit]
        shl al,cl
        or [latch],al
        cmp [latchbit],5
        mov cl,ah
        jb w00
        mov [latchbit],0
        mov al,[latch]
        mov [latch],0
        mov [reg0],al
        trace tMMC0,al
    ;----
        test al,02h
        jnz w01
        test al,01h
        call mirror1
        jmp w02
w01:
        test al,01h
        call mirror2V
w02:
        call romswitch
    ;----        
w00:
        ret
;----------------------------------------------------------------------------
write1:;        ($A000-$BFFF)
;----------------------------------------------------------------------------
        or al,al
        js reset

        and al,1
        mov ah,cl
        mov cl,[latchbit]
        inc [latchbit]
        shl al,cl
        or [latch],al
        cmp [latchbit],5
        mov cl,ah
        jb w00
        mov [latchbit],0
        mov al,[latch]
        mov [latch],0
        mov [reg1],al
    ;----
        cmp [vromsize],0
        je romswitch

        test [reg0],10h
        jnz w11
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
        mov [chr_map+16],eax
        add eax,1000h
        mov [chr_map+20],eax
        add eax,1000h
        mov [chr_map+24],eax
        add eax,1000h
        mov [chr_map+28],eax
        call newchrmap
        jmp romswitch
w11:
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
        call newchrmap
        jmp romswitch
;----------------------------------------------------------------------------
write2:;        ($C000-$DFFF)
;----------------------------------------------------------------------------
        or al,al
        js reset

        and al,1
        mov ah,cl
        mov cl,[latchbit]
        inc [latchbit]
        shl al,cl
        or [latch],al
        cmp [latchbit],5
        mov cl,ah
        jb w00
        mov [latchbit],0
        mov al,[latch]
        mov [latch],0
        mov [reg2],al
    ;----
        test [reg0],10h
        jnz w20
        ret
w20:
        cmp [vromsize],0
        je romswitch

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

        jmp romswitch
;----------------------------------------------------------------------------
write3:;        ($E000-$FFFF)
;----------------------------------------------------------------------------
        or al,al
        js reset

        and al,1
        mov ah,cl
        mov cl,[latchbit]
        inc [latchbit]
        shl al,cl
        or [latch],al
        cmp [latchbit],5
        mov cl,ah
        jb w00
        mov [latchbit],0
        mov al,[latch]
        mov [latch],0
if DEBUG
        test al,10h
        jz w30
        or [int_flags],DEBUG2
        mov [debugmsg],offset msg04
w30:
endif
        and al,0fh                      ;remove unused bits
        mov [reg3],al
    ;----
        jmp romswitch
;----------------------------------------------------------------------------
romswitch:;
;----------------------------------------------------------------------------
        mov al,[reg1]
        and al,10h
        or al,[reg3]

        test [reg0],08h
        jz rs1
                                        ;switch 16k:
        mov ebp,eax
        test [reg0],04h
        jz rs0

        call map89AB                    ;map low bank
        mov eax,ebp
        or al,0fh
        call mapCDEF                    ;map hardwired high bank
        jmp flush
rs0:
        call mapCDEF                    ;map high bank
        mov eax,ebp
        and al,10h
        call map89AB                    ;map hardwired low bank
        jmp flush
rs1:                                    ;switch 32k:
        shr al,1
        call map89ABCDEF
        jmp flush
;----------------------------------------------------------------------------
        align 4

reg0            equ     mapperdata+0
reg1            equ     mapperdata+1
reg2            equ     mapperdata+2
reg3            equ     mapperdata+3
latch           equ     mapperdata+4
latchbit        equ     mapperdata+5

;----------------------------------------------------------------------------
code    ends
        end
