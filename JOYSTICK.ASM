        .386p
code    segment public use32
        assume cs:code,ds:code
        
        include equates.h
        include config.h

        public joy_load
        public joy0x
        public joy0y
        public joy1x
        public joy1y
        public joy0axis
        public joy1axis
        public joybuttons
        public joyread
        public joymask

;----------------------------------------------------------------------------
joy_load:;      load joystick data
;       out:
;               eax,ebp=?
;----------------------------------------------------------------------------
        push ebx
        push ecx
        push edx
        push esi

        mov edx,0201h

        in al,dx
        xor ebx,ebx                             ;do buttons
        shl al,1
        adc bh,0ffh
        shl al,1
        adc bl,0ffh
        shl ebx,16
        shl al,1
        adc bh,0ffh
        shl al,1
        adc bl,0ffh
        mov [joybuttons],ebx

        xor ebx,ebx                             ;X0 axis
        xor ecx,ecx                             ;Y0 axis
        xor esi,esi                             ;X1 axis
        xor ebp,ebp                             ;Y1 axis

        mov eax,0900h                           ;"cli"
        int 31h

        out dx,al                               ;reset axes

jl1:    in al,dx                                ;read from joystick port
        ror al,1
        adc ebx,0                               ;increment axis values
        ror al,1
        adc ecx,0
        ror al,1
        adc esi,0
        ror al,1
        adc ebp,0

        cmp ebx,JOY_TIMEOUT
        ja jl2
        cmp ecx,JOY_TIMEOUT
        ja jl2
        cmp esi,JOY_TIMEOUT
        ja jl2
        cmp ebp,JOY_TIMEOUT
        ja jl2
        test al,[joymask]                       ;quit when axis bits are settled
        jnz jl1
jl2:
        mov eax,0901h                           ;"sti"
        int 31h

        add ebx,[joy0x]
        add ecx,[joy0y]
        shr ebx,1                               ;average with last values
        add esi,[joy1x]
        shr ecx,1
        add ebp,[joy1y]
        shr esi,1
        mov [joy0x],ebx                         ;save axis values
        shr ebp,1
        mov [joy0y],ecx
        mov [joy1x],esi
        mov [joy1y],ebp

        xor edx,edx                             ;setup joy0 axis flags
        cmp ebx,[joy0xmid]
        jae jl3
        or edx,40h                              ;left
jl3:    cmp ebx,[joy0xmax]
        jb jl4
        or edx,80h                              ;right
jl4:    cmp ecx,[joy0ymid]
        ja jl5
        or edx,10h                              ;up
jl5:    cmp ecx,[joy0ymax]
        jb jl6
        or edx,20h                              ;down
jl6:    mov [joy0axis],edx

        xor edx,edx                             ;setup joy1 axis flags
        cmp esi,[joy1xmid]
        jae jl7
        or edx,40h                              ;left
jl7:    cmp esi,[joy1xmax]
        jb jl8
        or edx,80h                              ;right
jl8:    cmp ebp,[joy1ymid]
        ja jl9
        or edx,10h                              ;up
jl9:    cmp ebp,[joy1ymax]
        jb jl10
        or edx,20h                              ;down
jl10:   mov [joy1axis],edx

jl18:
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
;----------------------------------------------------------------------------
JOY_TIMEOUT     equ     5000                    ;# of reads before giving up

joy0x           dd      ?                       ;raw axis values
joy0y           dd      ?
joy1x           dd      ?
joy1y           dd      ?

joy0axis        dd      ?                       ;axis bits
joy1axis        dd      ?
joybuttons      dd      ?

joymask         db      0                       ;mask for axis read (see joy_load)
joyread         db      ?                       ;allow joystick read
;----------------------------------------------------------------------------
code    ends
        end
