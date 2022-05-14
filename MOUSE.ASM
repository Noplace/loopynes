        .386p
code    segment public use32
        assume cs:code,ds:code

        include io.h
        include empty.h
        include data.h
        include config.h

        public mouseinit
        public mouseexit
        public mouseX
        public mouseY
        public mouseXmove
        public mouseYmove
        public mousebuttons

;----------------------------------------------------------------------------
mouseinit:;     init mouse driver
;
;       out:
;               EAX,EBX=?
;----------------------------------------------------------------------------
        xor eax,eax                     ;reset vars
        mov [mouseX],eax
        mov [mouseY],eax
        mov [mouseXmove],eax
        mov [mouseYmove],eax
        mov [mouseXmod],eax
        mov [mouseYmod],eax
        mov [mousebuttons],al

        int 33h                         ;reset mouse driver

        push es
        mov ax,cs
        mov es,ax
        mov edx,offset mousehandler
        mov ax,000ch                    ;install handler
        mov cx,1fh
        int 33h
        pop es

        ret
;----------------------------------------------------------------------------
mouseexit:;     shutdown mouse driver
;----------------------------------------------------------------------------
        mov ax,000ch                    ;uninstall handler
        xor ecx,ecx
        int 33h
        ret
;----------------------------------------------------------------------------
mousehandler:;
;----------------------------------------------------------------------------
        pushad
        push ds
        mov ds,cs:[data_sel]

        mov [mousebuttons],bl

        mov eax,000bh
        int 33h
        add ecx,[mouseXmod]
        add edx,[mouseYmod]
        mov ebx,MOUSESPEED

        mov ax,dx
        cwd 
        idiv bx
        mov [mouseYmod],edx
        cwde
        mov [mouseYmove],eax
        add [mouseY],eax

        mov ax,cx
        cwd 
        idiv bx
        mov [mouseXmod],edx
        cwde
        mov [mouseXmove],eax
        add [mouseX],eax

        mov eax,[mouseX]                ;X range check
        cmp eax,[mouseXmin]
        jg mh1
        mov eax,[mouseXmin]
mh1:    cmp eax,[mouseXmax]
        jl mh2
        mov eax,[mouseXmax]
mh2:    mov [mouseX],eax

        mov eax,[mouseY]                ;Y range check
        cmp eax,[mouseYmin]
        jg mh3
        mov eax,[mouseYmin]
mh3:    cmp eax,[mouseYmax]
        jl mh4
        mov eax,[mouseYmax]
mh4:    mov [mouseY],eax

        pop ds
        popad
        retf
;----------------------------------------------------------------------------
        align 4

MOUSESPEED      equ     4

mouseX          dd      ?               ;cursor position
mouseY          dd      ?
mouseXmove      dd      ?               ;change in mouseX/Y
mouseYmove      dd      ?
mouseXmod       dd      ?               ;
mouseYmod       dd      ?

mousebuttons    db      ?

;----------------------------------------------------------------------------
code    ends
        end
