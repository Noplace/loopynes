;----------------------------------------------------------------------------
;link this right before empty.asm
;----------------------------------------------------------------------------
        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include file.h
        include input.h
        include equates.h

        public saveconfig
        public joy0xmid
        public joy0xmax
        public joy0ymid
        public joy0ymax
        public joy1xmid
        public joy1xmax
        public joy1ymid
        public joy1ymax
        public mouseXmin
        public mouseXmax
        public mouseYmin
        public mouseYmax
        public control0read
        public control1read
        public serial0load
        public serial1load
        public serial2load
        public serial3load
        public control0config
        public control1config
        public control2config
        public control3config
        public vwait
        public showfps
        public vidmode
        public palette
        public soundvol
;----------------------------------------------------------------------------
saveconfig:;            write config data to EXE
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        mov edx,[env_ptr]
        xor eax,eax
sc0:    inc edx
        cmp [edx],ax
        jne sc0
        add edx,4                       ;edx=exe name

        mov cl,2
        call f_open                     ;open exe
        jc sc19
        mov al,02h
        mov edx,-CONFIGSIZE
        call f_seek
        jc sc18                         ;seek to config area

        mov ecx,CONFIGSIZE
        mov edx,offset config           ;write config
        call f_write
sc18:   call f_close
sc19:   ret
;----------------------------------------------------------------------------
                align 4

config:         ;stuff saved to .EXE

palette label dword                     ;current palette
include palette.txt                     ;(0RGB*64)

                                        ;joystick calibration:
joy0xmid        dd      ?                       ;lowest value for x center position
joy0xmax        dd      ?                       ;lowest value for x right position
joy0ymid        dd      ?                       ;lowest value for y center position
joy0ymax        dd      ?                       ;lowest value for y up position
joy1xmid        dd      ?                       ;..
joy1xmax        dd      ?
joy1ymid        dd      ?
joy1ymax        dd      ?

mouseXmin       dd      ?
mouseXmax       dd      ?
mouseYmin       dd      ?
mouseYmax       dd      ?

control0read    dd serialread           ;4016
control1read    dd serialread           ;4017

serial0load     dd keyboard              ;load serial data
serial1load     dd unplugged
serial2load     dd unplugged
serial3load     dd unplugged

control0config  db KB_LEFT,KB_UP,KB_RIGHT,KB_DOWN,KB_TAB,KB_ENTER,KB_LSHIFT,KB_Z
                db 24 dup (0)
control1config  db 32 dup (0)
control2config  db 32 dup (0)
control3config  db 32 dup (0)

vwait           dd 0                    ;VRET wait on pageflip
vidmode         dd 1                    ;graphics mode

showfps         db 0                    ;display FPS
soundvol        db 5                    ;SB volume (1-10, 5 is normal)

CONFIGSIZE      equ $-config

;----------------------------------------------------------------------------
code    ends
        end
