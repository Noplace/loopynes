        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include equates.h
        include empty.h
        include vga.h

        public  kb_init
        public  kb_clear
        public  getch
        public  kb_last
        public  kb_flags

;----------------------------------------------------------------------------
kb_init:;       install keyboard handler
;
;       on error:
;               CF=1
;----------------------------------------------------------------------------
        call kb_clear
        mov eax,0205h
        mov bl,9
        mov cx,cs
        mov edx,offset int9
        int 31h                         ;set pmode vector
        ret
;----------------------------------------------------------------------------
int9:;          protected mode keyboard handler
;
;               extended keys are sent with the hi bit of the scancode set.
;               printscr is extended 55
;               alt-printscr is 84
;               break is extended 69
;               ctrl-break is extended 70
;
;----------------------------------------------------------------------------
        push eax
        push ebx
        push ds
        mov ax,word ptr cs:[data_sel]
        mov ds,ax                       ;load data selector
        in al,60h                       ;read keyboard
        mov bl,al
        cmp al,0e0h                     ;extended code?(0e0h or 0e1h)
        jae extend
        test [kb_flags],EXTEND+EXTEND2  ;extended key?
        jnz extend2
        and al,07fh
        test bl,80h
        jnz release
        ;---------
press:  movzx ebx,al
        mov [kb_last],al
        mov [kb_table+ebx],0ffh
        jmp done
        ;---------
extend: sub al,0dfh                     ;convert to [kb_flags] mask
        or [kb_flags],al
        jmp done
        ;---------
extend2:test [kb_flags],EXTEND2         ;double extended code?
        jnz ex_2
        and [kb_flags],not (EXTEND+EXTEND2)
        cmp al,2ah
        je done                         ;ignore 1st printscr code (42)
        or al,80h
        test bl,80h
        jnz release
        jmp press
ex_2:   xor [kb_flags],EXTEND+EXTEND2   ;set EXTEND flag+clear EXTEND2
        jmp done
        ;---------
release:movzx ebx,al
        mov [kb_table+ebx],0
        ;---------
done:   mov al,20h
        out 20h,al                      ;send EOI
        pop ds
        pop ebx
        pop eax
        iretd
;----------------------------------------------------------------------------
kb_clear:;      Clear all kb stuff
; 
;       out:
;               EAX,ECX,EDI=?
;----------------------------------------------------------------------------        
        xor eax,eax
        mov edi,offset kb_table
        mov ecx,100h/4
        rep stosd

        mov [kb_last],al

        ret
;----------------------------------------------------------------------------
getch:;         wait for keyboard input
;
;       out:
;               AL=char
;----------------------------------------------------------------------------
        call setcursor
g0:
        cmp [kb_last],0
        je g0
        mov al,[kb_table+KB_LSHIFT]
        or al,[kb_table+KB_RSHIFT]
        and eax,80h
        or al,[kb_last]
        mov al,[kb_asctable+eax]
        mov [kb_last],0
        or al,al
        jz g0
        ret
;----------------------------------------------------------------------------

                align   4

EXTEND          equ     00000001b                       ;extended key being read
EXTEND2         equ     00000010b                       ;double extended (break)

kb_asctable     db 000,'','1','2','3','4','5','6'      ;scancode->ascii
                db '7','8','9','0','-','=',008,009      ;translate table
                db 'Q','W','E','R','T','Y','U','I'
                db 'O','P','[',']',013,000,'A','S'
                db 'D','F','G','H','J','K','L',';'
                db "'",'`',000,'\','Z','X','C','V'
                db 'B','N','M',',','.','/',000,000
                db 000,' ',000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db '',000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000

kb_shifttable   db 000,'','!','@','#','$','%','^'      ;shifted scancode->ascii
                db '&','*','(',')','_','+',008,009      ;translate table
                db 'Q','W','E','R','T','Y','U','I'
                db 'O','P','{','}',013,000,'A','S'
                db 'D','F','G','H','J','K','L',':'
                db '"','~',000,'|','Z','X','C','V'
                db 'B','N','M','<','>','?',000,000
                db 000,' ',000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db '',000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                db 000,000,000,000,000,000,000,000
                
kb_last         db      0                       ;last key pressed (scancode)

kb_flags        db      0

;----------------------------------------------------------------------------
code    ends
        end
