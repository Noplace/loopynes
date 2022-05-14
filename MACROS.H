setlastbank macro
        mov edi,esi
        shr edi,13
        mov eax,[memmap+edi*4]
        mov [lastbank],eax
endm

encodePC macro                                  ;translate esi from 6502 PC to DS offset
        setlastbank
        add esi,eax
endm

save6502 macro                                  ;save 6502 regs
        mov [_P_A],edx
        mov [_X_Y],ecx
        mov [_S],ebx
        sub esi,[lastbank]
        mov [_PC],esi
endm

restore6502 macro                               ;restore 6502 regs
        mov esi,[_PC]
        mov ebx,[_S]
        mov edx,[_P_A]
        mov ecx,[_X_Y]
        add esi,[lastbank]
endm

;----------------------------------------------------------------------------

fetch   macro count
        sub [cycles],count
        jmp op_fetch
        align 8
endm

fetch1  macro
        js timeout
        test [int_flags],-1
        jnz interrupt
        fetch2
endm

fetch2  macro                                   ;execute next instruction
        mov edi,[esi]
        and edi,0ffh
        inc esi
        jmp [op_table+edi*4]
endm

;----------------------------------------------------------------------------
readmem macro
        mov ebp,edi
        shr ebp,13
        call [read_tbl+ebp*4]
        ;EAX=value, EDI,EBP=?
endm

writemem macro
        mov ebp,edi
        shr ebp,13
        call [write_tbl+ebp*4]
        ;EAX,EDI,EBP=?
endm

;----------------------------------------------------------------------------

_IMM    equ     1                       ;immediate
_ZP     equ     2                       ;zero page
_ABS    equ     3                       ;absolute

;----------------------------------------------------------------------------

flagNZ  macro
        lahf                                    ;load flags into AH
        and ah,N+Z                              ;mask off all but sign/zero flags
        and dh,not (N+Z)                        ;clear N/Z flags
        or dh,ah                                ;update the 6502 flags
endm

flagNZC macro
        lahf                                    ;load flags into AH
        and ah,N+Z+C                            ;mask off all but sign/carry/zero flags
        and dh,not (N+Z+C)
        or dh,ah                                ;update the 6502 status flags
endm

flagNVZC macro
        pushfd
        pop eax
        and eax,0000100011000001b
        or ah,al
        and dh,not (N+V+Z+C)
        or dh,ah
endm

;----------------------------------------------------------------------------

push16  macro
        mov [ebx],ah
        dec bl
        mov [ebx],al
        dec bl
endm

push8   macro x
        mov [ebx],x
        dec bl
endm

pop16   macro  
        inc bl
        mov al,[ebx]
        inc bl
        mov ah,[ebx]
endm

pop8    macro x
        inc bl
        mov x,[ebx]
endm

;----------------------------------------------------------------------------

doABS   macro                           ;absolute               $xxxx
_type   =       _ABS 
        movzx edi,word ptr [esi]
        add esi,2
endm

doAIX   macro                           ;absolute indexed X     $xxxx,X
_type   =       _ABS 
        movzx edi,ch
        add di,[esi]
        add esi,2
endm


doAIX2  macro                           ;absolute indexed X     $xxxx,X
_type   =       _ABS                    ;(add one cycle for page crossing)
        movzx eax,ch
        add ax,[esi]
        add esi,2
        mov edi,eax
        sub al,ch
        sbb [cycles],0
endm

doAIY   macro                           ;absolute indexed Y     $xxxx,Y
_type   =       _ABS
        movzx edi,cl
        add di,[esi]
        add esi,2
endm

doAIY2  macro                           ;absolute indexed Y     $xxxx,Y
_type   =       _ABS                    ;(add one cycle for page crossing)
        movzx eax,cl
        add ax,[esi]
        add esi,2
        mov edi,eax
        sub al,cl
        sbb [cycles],0
endm

doIMM   macro                           ;immediate              #$xx
_type   =       _IMM
endm

doIIX   macro                           ;indexed indirect X     ($xx,X)
_type   =       _ABS 
        xor eax,eax
        xor edi,edi
        mov al,[esi]
        add al,ch
        mov di,fs:[eax]
        inc esi
endm

doIIY   macro                           ;indirect indexed Y     ($xx),Y
_type   =       _ABS
        xor eax,eax
        xor edi,edi
        mov al,[esi]
        mov di,fs:[eax]
        mov al,cl
        add di,ax
        inc esi
endm

doIIY2   macro                          ;indirect indexed Y     ($xx),Y
_type   =       _ABS                    ;(add one cycle for page crossing)
        movzx edi,byte ptr [esi]
        xor eax,eax
        mov al,cl
        add ax,fs:[edi]
        inc esi
        mov edi,eax
        sub al,cl
        sbb [cycles],0
endm

doZ     macro                           ;zero page              $xx
_type   =       _ZP
        movzx edi,byte ptr [esi]
        inc esi
endm

doZIX   macro                           ;zero page indexed X    $xx,X
_type   =       _ZP
        xor eax,eax
        mov al,[esi]
        add al,ch
        mov edi,eax
        inc esi
endm

doZIY   macro                           ;zero page indexed Y    $xx,Y
_type   =       _ZP
        mov edi,[esi]
        add edi,ecx
        and edi,0ffh
        inc esi
endm

;----------------------------------------------------------------------------

opADC   macro
        if _type eq _ABS
                readmem
                mov ah,dh
                shr ah,1
                adc dl,al
                flagNVZC
        elseif _type eq _ZP
                mov ah,dh
                shr ah,1
                adc dl,fs:[edi]
                flagNVZC
        else
                mov ah,dh
                shr ah,1
                adc dl,[esi]
                flagNVZC
                inc esi
        endif
endm

opAND   macro
        if _type eq _ABS
                readmem
                and dl,al
                flagNZ
        elseif _type eq _ZP
                and dl,fs:[edi]
                flagNZ
        else
                and dl,[esi]
                flagNZ
                inc esi
        endif
endm

opASL   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                shl al,1
                flagNZC
                writemem
        else
                shl byte ptr fs:[edi],1
                flagNZC
        endif
endm

opBIT   macro
        if _type eq _ABS
                and dh,not (N+V+Z)
                readmem
                test al,dl
                lahf
                and ah,Z
                or dh,ah
                and eax,0C0h
                or dh,[flag_decode+eax]
        else
                and dh,not (N+V+Z)
                mov al,fs:[edi]
                test al,dl
                lahf
                and ah,Z
                or dh,ah
                and eax,0C0h
                or dh,[flag_decode+eax]
        endif
endm

opCMP   macro
        if _type eq _ABS
                readmem
                cmp dl,al
                cmc
                flagNZC
        elseif _type eq _ZP
                cmp dl,fs:[edi]
                cmc
                flagNZC
        else
                cmp dl,[esi]
                cmc
                flagNZC
                inc esi
        endif
endm

opCPX   macro
        if _type eq _ABS
                readmem
                cmp ch,al
                cmc
                flagNZC
        elseif _type eq _ZP
                cmp ch,fs:[edi]
                cmc
                flagNZC
        else
                cmp ch,[esi]
                cmc
                flagNZC
                inc esi
        endif
endm

opCPY   macro
        if _type eq _ABS
                readmem
                cmp cl,al
                cmc
                flagNZC
        elseif _type eq _ZP
                cmp cl,fs:[edi]
                cmc
                flagNZC
        else
                cmp cl,[esi]
                cmc
                flagNZC
                inc esi
        endif
endm

opDEC   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                dec al
                flagNZ
                writemem
        else
                dec byte ptr fs:[edi]
                flagNZ
        endif
endm

opEOR   macro
        if _type eq _ABS
                readmem
                xor dl,al
                flagNZ
        elseif _type eq _ZP
                xor dl,fs:[edi]
                flagNZ
        else
                xor dl,[esi]
                flagNZ
                inc esi
        endif
endm

opINC   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                inc al
                flagNZ
                writemem
        else
                inc byte ptr fs:[edi]
                flagNZ
        endif
endm

opLDA   macro
        if _type eq _ABS
                readmem
                mov dl,al
                or al,al
                flagNZ
        elseif _type eq _ZP
                mov dl,fs:[edi]
                or dl,dl
                flagNZ
        else
                mov dl,[esi]
                or dl,dl
                flagNZ
                inc esi
        endif
endm

opLDX   macro
        if _type eq _ABS
                readmem
                mov ch,al
                or al,al
                flagNZ
        elseif _type eq _ZP
                mov ch,fs:[edi]
                or ch,ch
                flagNZ
        else
                mov ch,[esi]
                or ch,ch
                flagNZ
                inc esi
        endif
endm

opLDY   macro
        if _type eq _ABS
                readmem
                mov cl,al
                or al,al
                flagNZ
        elseif _type eq _ZP
                mov cl,fs:[edi]
                or cl,cl
                flagNZ
        else
                mov cl,[esi]
                or cl,cl
                flagNZ
                inc esi
        endif
endm

opLSR   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                shr al,1
                flagNZC
                writemem
        else
                shr byte ptr fs:[edi],1
                flagNZC
        endif
endm

opORA   macro
        if _type eq _ABS
                readmem
                or dl,al
                flagNZ
        elseif _type eq _ZP
                or dl,fs:[edi]
                flagNZ
        else
                or dl,[esi]
                flagNZ
                inc esi
        endif
endm

opROL   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                shr dh,1
                rcl al,1
                rcl dh,1
                or al,al
                flagNZ
                writemem
        else
                mov al,fs:[edi]
                shr dh,1
                rcl al,1
                rcl dh,1
                or al,al
                flagNZ
                mov fs:[edi],al
        endif
endm

opROR   macro
        if (_type eq _ABS) and (SAFE eq 1)
                push edi
                readmem
                pop edi
                shr dh,1
                rcr al,1
                rcl dh,1
                or al,al
                flagNZ
                writemem
        else
                mov al,fs:[edi]
                shr dh,1
                rcr al,1
                rcl dh,1
                or al,al
                flagNZ
                mov fs:[edi],al
        endif
endm

opSBC   macro
        if _type eq _ABS
                readmem
                mov ah,dh
                shr ah,1
                cmc
                sbb dl,al
                cmc
                flagNVZC
        elseif _type eq _ZP
                mov ah,dh
                shr ah,1
                cmc
                sbb dl,fs:[edi]
                cmc
                flagNVZC
        else
                mov ah,dh
                shr ah,1
                cmc
                sbb dl,[esi]
                cmc
                flagNVZC
                inc esi
        endif
endm

opSTA   macro
        if _type eq _ABS
                mov al,dl
                writemem
        else
                mov fs:[edi],dl
        endif
endm

opSTX   macro
        if _type eq _ABS
                mov al,ch
                writemem
        else
                mov fs:[edi],ch
        endif
endm

opSTY   macro
        if _type eq _ABS
                mov al,cl
                writemem
        else
                mov fs:[edi],cl
        endif
endm
