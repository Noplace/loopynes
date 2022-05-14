;----------------------------------------------------------------------------
;input devices go here
;----------------------------------------------------------------------------
        .386p
code    segment public use32
        assume cs:code,ds:code

        include kb.h
        include empty.h
        include mouse.h
        include equates.h
        include config.h
        include joystick.h
        include 6502.h
        include data.h

        public getinput
        public joy0_W
        public joy1_W
        public joy0_R
        public joy1_R
        public unplugged
        public keyboard
        public joystick0
        public joystick1
        public zapper
        public zapperVS
        public paddle
        public serialread
        public serial0mask
        public serial1mask
;----------------------------------------------------------------------------
getinput:;      deal with input devices (read mouse,joystick,etc)
;----------------------------------------------------------------------------
        mov [joyread],1                         ;allow joystick read
        xor edi,edi
        cmp byte ptr [mouseX+1],0               ;mouse offscreen X?
        jne gi1
        mov eax,[mouseY]
        cmp eax,223                             ;Y?
        ja gi1
        mov edi,eax
        shl edi,8
        lea edi,[vscreen+8+8*264+edi+eax*8]
        add edi,[mouseX]                        ;edi=screen ptr
gi1:
        mov [zapperptr],edi

        mov ah,[mousebuttons]                   ;zapper trigger:
        mov al,[mouselast]
        and ah,1
        xor al,ah
        and al,ah
        mov [mouselast],ah
        jz gi0
        mov eax,[framecount]
        inc eax
        mov [triggertimeout],eax
gi0:
        ret
;----------------------------------------------------------------------------
joy0_W:;        4016
;----------------------------------------------------------------------------
        mov [strobe],3
        ret
;----------------------------------------------------------------------------
joy1_W:;        $4017
;----------------------------------------------------------------------------
        ret
;----------------------------------------------------------------------------
joy0_R:;        read joypad 0
;----------------------------------------------------------------------------
        jmp [control0read]
;----------------------------------------------------------------------------
joy1_R:;        read joypad 1
;----------------------------------------------------------------------------
        jmp [control1read]
;----------------------------------------------------------------------------
serialread:
;----------------------------------------------------------------------------
        and edi,1
        jnz serial1read
        test [strobe],1
        jz sr00
        and [strobe],not 1

        mov [serial0data],80000h                ;4 player adapter

        mov edi,offset control0config           ;get joypad flags
        call [serial0load]                     ;(edi=config area)
        mov byte ptr [serial0data],al
        mov edi,offset control2config           ;get joypad flags
        call [serial2load]                     ;(edi=config area)
        mov byte ptr [serial0data+1],al
sr00:
        mov al,[kb_table+KB_TILDE]      ;coin
        and al,40h
        shr [serial0data],1
        adc al,[serial0mask]

        ret
serial1read:;- - - - - - - - - - - - - -
        test [strobe],2
        jz sr10
        and [strobe],not 2

        mov [serial1data],40000h                ;4 player adapter

        mov edi,offset control1config           ;get joypad flags
        call [serial1load]                      ;(edi=config area)
        mov byte ptr [serial1data],al
        mov edi,offset control3config           ;get joypad flags
        call [serial3load]                      ;(edi=config area)
        mov byte ptr [serial1data+1],al
sr10:
        xor al,al
        shr [serial1data],1
        adc al,[serial1mask]
        ret
;----------------------------------------------------------------------------
unplugged:;     (serial) controller not plugged in
;----------------------------------------------------------------------------
        xor al,al
        ret
;----------------------------------------------------------------------------
keyboard:;      (serial) keyboard input
;       in:
;               edi=config ptr
;       out:
;               eax=
;               edi=
;               ebp=
;
;----------------------------------------------------------------------------
        push ebx
        xor ebp,ebp
        xor eax,eax

        mov al,[a_btn+edi]
        mov al,[kb_table+eax]
        and al,01h
        or ebp,eax
        mov al,[b_btn+edi]
        mov al,[kb_table+eax]
        and al,02h
        or ebp,eax
        mov al,[sel+edi]
        mov al,[kb_table+eax]
        and al,04h
        or ebp,eax
        mov al,[start+edi]
        mov al,[kb_table+eax]
        and al,08h
        or ebp,eax

        mov al,[up+edi]
        mov al,[kb_table+eax]
        mov bl,al
        and al,10h
        or ebp,eax
        mov al,[down+edi]
        mov al,[kb_table+eax]
        and bl,al
        and al,20h
        or ebp,eax
        and ebx,30h
        xor ebp,ebx

        mov al,[left+edi]
        mov al,[kb_table+eax]
        mov bl,al
        and al,40h
        or ebp,eax
        mov al,[right+edi]
        mov al,[kb_table+eax]
        and bl,al
        and al,80h
        or ebp,eax
        and ebx,0c0h
        xor ebp,ebx

        mov eax,ebp
        pop ebx
        ret
;----------------------------------------------------------------------------
joystick0:;      (serial) joystick input
;----------------------------------------------------------------------------
        cmp [joyread],0
        je j08
        or [joymask],00110000b
        call joy_load
        mov [joyread],0
j08:
        xor eax,eax
        xor ebp,ebp

        mov al,[joy_a+edi]                      ;keyboard stuff
        cmp al,4
        jb j00
        mov al,[kb_table+eax]
        and al,01h
        or ebp,eax
        mov al,[joy_b+edi]
        cmp al,4
        jb j01
j04:    mov al,[kb_table+eax]
        and al,02h
        or ebp,eax
        mov al,[joy_sel+edi]
        cmp al,4
        jb j02
j05:    mov al,[kb_table+eax]
        and al,04h
        or ebp,eax
        mov al,[joy_start+edi]
        cmp al,4
        jb j03
j06:    mov al,[kb_table+eax]
        and al,08h
        or ebp,eax
        jmp j07

j00:    mov al,byte ptr [joybuttons+eax]                 ;joystick stuff
        and al,01h
        or ebp,eax
        mov al,[joy_b+edi]
        cmp al,3
        ja j04
j01:    mov al,byte ptr [joybuttons+eax]
        and al,02h
        or ebp,eax
        mov al,[joy_sel+edi]
        cmp al,3
        ja j05
j02:    mov al,byte ptr [joybuttons+eax]
        and al,04h
        or ebp,eax
        mov al,[joy_start+edi]
        cmp al,3
        ja j06
j03:    mov al,byte ptr [joybuttons+eax]
        and al,08h
        or ebp,eax
j07:
        mov eax,[joy0axis]
        or eax,ebp
        ret
;----------------------------------------------------------------------------
joystick1:;      (serial) joystick input
;----------------------------------------------------------------------------
        cmp [joyread],0
        je j18
        or [joymask],11000000b
        call joy_load
        mov [joyread],0
j18:
        xor eax,eax
        xor ebp,ebp

        mov al,[joy_a+edi]                      ;keyboard stuff
        cmp al,4
        jb j10
        mov al,[kb_table+eax]
        and al,01h
        or ebp,eax
        mov al,[joy_b+edi]
        cmp al,4
        jb j11
j14:    mov al,[kb_table+eax]
        and al,02h
        or ebp,eax
        mov al,[joy_sel+edi]
        cmp al,4
        jb j12
j15:    mov al,[kb_table+eax]
        and al,04h
        or ebp,eax
        mov al,[joy_start+edi]
        cmp al,4
        jb j13
j16:    mov al,[kb_table+eax]
        and al,08h
        or ebp,eax
        jmp j17

j10:    mov al,byte ptr [joybuttons+eax]                 ;joystick stuff
        and al,01h
        or ebp,eax
        mov al,[joy_b+edi]
        cmp al,3
        ja j14
j11:    mov al,byte ptr [joybuttons+eax]
        and al,02h
        or ebp,eax
        mov al,[joy_sel+edi]
        cmp al,3
        ja j15
j12:    mov al,byte ptr [joybuttons+eax]
        and al,04h
        or ebp,eax
        mov al,[joy_start+edi]
        cmp al,3
        ja j16
j13:    mov al,byte ptr [joybuttons+eax]
        and al,08h
        or ebp,eax
j17:
        mov eax,[joy1axis]
        or eax,ebp
        ret
;----------------------------------------------------------------------------
paddle:;        arkanoid paddle input
;----------------------------------------------------------------------------
        test [strobe],2
        jz pd0
        and [strobe],not 2

        mov [serial1data],0

        mov al,0ffh
        xor al,byte ptr [mouseX]
        shl eax,24
        mov [serial1data],eax

        and [serial0mask],not 2
        mov al,[mousebuttons]
        and al,1
        shl al,1
        or [serial0mask],al
pd0:
        xor eax,eax
        shl [serial1data],1
        adc al,0
        add al,al
        ret
;----------------------------------------------------------------------------
zapper:;        zapper input
;----------------------------------------------------------------------------
        mov edi,[zapperptr]
        mov ebp,[palmap]
        cmp edi,0                               ;out of range?
        je z0
        mov al,byte ptr [edi]                   ;read pixel
        and eax,7fh
        cmp al,40h
        jb z64
        mov al,[vram+3f00h+eax-40h]             ;(al=palette#)
z64:    cmp byte ptr [ebp+eax],0fh              ;(al=color#)
        je z0                                   ;black?
        xor al,al
        jmp z1
z0:
        mov al,08h
z1:
        mov edi,[triggertimeout]
        cmp edi,[framecount]
        jb z2
        or al,10h
z2:
        ret
;----------------------------------------------------------------------------
zapperVS:;      (serial)
;----------------------------------------------------------------------------
        mov edi,[zapperptr]
        mov ebp,[palmap]
        cmp edi,0                               ;out of range?
        je vs10
        mov al,byte ptr [edi]                   ;read pixel
        and eax,7fh
        cmp al,40h
        jb vs12
        mov al,[vram+3f00h+eax-40h]             ;(al=palette#)
vs12:   cmp byte ptr [ebp+eax],0fh              ;(al=color#)
        je vs10                                 ;black?
        mov al,7fh       ;hit
        jmp vs11
vs10:
        mov al,3fh       ;no hit
vs11:
        test [mousebuttons],1
        jz vs13
        or al,80h
vs13:
        ret
;----------------------------------------------------------------------------
                align 4

serial0data     dd ?
serial1data     dd ?

zapperptr       dd      ?                       ;vscreen pointer for zapper
triggertimeout  dd      ?

serial0mask     db ?
serial1mask     db ?
mouselast       db      ?                       ;(for zapper)
strobe          db ?

kbconfig struc
        left db ?
        up db ?
        right db ?
        down db ?
        sel db ?
        start db ?
        b_btn db ?
        a_btn db ?
ends

joyconfig struc
        joy_sel         db ?
        joy_start       db ?
        joy_b           db ?
        joy_a           db ?
ends

;----------------------------------------------------------------------------
code    ends
        end
