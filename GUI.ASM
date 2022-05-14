        .386p
code    segment public use32
        assume cs:code,ds:code

        include sb.h
        include ppu.h
        include data.h
        include input.h
        include joystick.h
        include font.h
        include empty.h
        include kb.h
        include equates.h
        include main.h
        include 6502.h
        include memory.h
        include vga.h
        include mouse.h
        include config.h
        include io.h
        include file.h
        include ggenie.h

        public startgui
        public drawfps
        public text
;----------------------------------------------------------------------------
window:;        menu type box
;       in:
;               ecx=width
;               edx=height
;               edi=vscreen ptr
;       out:
;               eax,ebx,ecx,edx,edi,ebp=?
;----------------------------------------------------------------------------
        sub edi,264*5+5
        add ecx,10
        add edx,8
        mov eax,0f3f5f9fbh
        mov bl,0f8h
;----------------------------------------------------------------------------
box:;
;       in:
;               eax:bl=colors
;               ecx=width
;               edx=height
;               edi=vscreen ptr
;       out:
;               eax,ebx,ecx,edx,edi,ebp=?
;----------------------------------------------------------------------------
        push esi

        add edi,2                       ;adjust for 2 pixel border
        sub ecx,4
        mov ebp,264
        push edi                        ;save top of window
        sub ebp,ecx
        push ecx                        ;save width
        mov [xl],ecx
        shr ecx,2
        mov [xh],ecx
        and [xl],3
        lea esi,[edx-3]                 ;esi=Y count
        add edi,264

        mov edx,eax
        mov bh,bl
        mov ax,bx
        shl eax,16                      ;eax=middle color
        mov ax,bx
        shld ebx,edx,16                 ;bx,dx=border colors
box1:
        mov [edi-2],dx                  ;draw middle part
        mov ecx,[xh]
        rep stosd
        mov ecx,[xl]
        rep stosb
        mov [edi],bx
        add edi,ebp
        dec esi
        jnz box1

        mov al,dh                       ;top/bottom borders
        add al,bl
        rcr al,1
        pop ecx                         ;get width
        inc ecx
        pop esi                         ;get window top
        mov [esi-1],dl
        mov [esi-2],dl
        mov [edi-2],dl
        mov [edi-1],al
        mov [edi+263],bh
box2:   mov [esi],dl
        mov [esi+264],dh
        mov [edi],bl
        mov [edi+264],bh
        inc edi
        inc esi
        dec ecx
        jnz box2
        mov [esi+263],al
        mov [esi+264],bh
        mov [edi],bh
        mov [edi+264],bh

        pop esi
        ret

        xh dd ?
        xl dd ?
;----------------------------------------------------------------------------
htext:;         highlighted text (pushed button look)
;       in:
;               esi=text ptr
;               edi=vscreen ptr
;       out:
;               eax,ebx,edx,edi=?
;               esi=EOL
;----------------------------------------------------------------------------
        push ecx
        push ebp
        push esi
        push edi
        inc edi

        xor ecx,ecx                     ;ecx=line width
ht0:    movzx eax,byte ptr [esi]
        mov al,[lookup+eax]
        shl eax,6
        add ecx,[font+eax]              ;add up char widths
        inc esi
        cmp byte ptr [esi],0
        jne ht0

        mov [htextend],edi
        mov eax,0f9faf5f7h
        mov bl,0f7h
        add ecx,4
        add [htextend],ecx
        mov edx,LINEHEIGHT+2
        sub edi,264*2+3
        call box

        pop edi
        pop esi
        call text
        pop ebp
        pop ecx
        ret

htextend        dd      ?
;----------------------------------------------------------------------------
text:;
;       in:
;               esi=text ptr
;               edi=vscreen ptr
;       out:
;               esi=EOL
;               eax,ebx,edx,edi=?
;----------------------------------------------------------------------------
t1:
        movzx eax,byte ptr [esi]
        cmp al,32
        jb t2

        movzx edx,[lookup+eax]
        shl edx,6

        mov eax,[font+8 +edx]
        mov ebx,[font+12+edx]
        or [edi+000h],eax
        or [edi+004h],ebx
        mov eax,[font+16+edx]
        mov ebx,[font+20+edx]
        or [edi+108h],eax
        or [edi+10ch],ebx
        mov eax,[font+24+edx]
        mov ebx,[font+28+edx]
        or [edi+210h],eax
        or [edi+214h],ebx
        mov eax,[font+32+edx]
        mov ebx,[font+36+edx]
        or [edi+318h],eax
        or [edi+31ch],ebx
        mov eax,[font+40+edx]
        mov ebx,[font+44+edx]
        or [edi+420h],eax
        or [edi+424h],ebx
        mov eax,[font+48+edx]
        mov ebx,[font+52+edx]
        or [edi+528h],eax
        or [edi+52ch],ebx
        mov eax,[font+56+edx]
        mov ebx,[font+60+edx]
        or [edi+630h],eax
        or [edi+634h],ebx

        add edi,[font+edx]
        inc esi
        jmp t1
t2:
        ret
;----------------------------------------------------------------------------
drawmenu:;      draw one menu
;       in:
;               esi=menu ptr
;       out:
;               ecx=lines in menu
;               ?=?
;----------------------------------------------------------------------------
        xor ecx,ecx                     ;ecx=text width
        xor edx,edx                     ;edx=text height
        lea edi,[esi+12]                ;edi=text ptr
dm2:                                    ;calc text width/height:
        xor ebx,ebx                     ;ebx=current line width
dm0:    movzx eax,byte ptr [edi]
        mov al,[lookup+eax]
        shl eax,6
        add ebx,[font+eax]              ;add chars in this line
        inc edi
        cmp byte ptr [edi],0
        jne dm0
        inc edi
        cmp ebx,ecx                     ;compare this line with widest line
        jbe dm1
        mov ecx,ebx
dm1:    add edx,LINEHEIGHT              ;add height for 1 line
        cmp byte ptr [edi],0
        jne dm2

        mov edi,[esi]
        call window

        mov ebp,[esi+4]                 ;ebp=selected line
        mov edi,[esi]                   ;edi=screen ptr
        add esi,12                      ;esi=text ptr
        xor ecx,ecx                     ;ecx=line#
tw1:
        push edi
        cmp ecx,ebp
        jne tw0
        call htext
        jmp tw2
tw0:    call text
tw2:    pop edi
        inc esi
        add edi,LINEHEIGHT*264
        inc ecx
        cmp byte ptr [esi],0
        jne tw1
        ret
;----------------------------------------------------------------------------
drawmenus:;     redraw screen and all menus in menulist
;
;       in:
;               ?
;       out:
;               ecx=lines in last menu
;----------------------------------------------------------------------------
        mov esi,offset vscreen2                 ;draw NES screen
        mov edi,offset vscreen
        mov ecx,264*240/4
        rep movsd

        mov edi,offset vscreen+8+264*214+10     ;print version
        mov esi,offset version
        call text

        xor eax,eax                             ;eax=menu#
dw2:
        mov esi,[menulist+eax*4]
        push eax
        call drawmenu
        pop eax
        inc eax
        cmp eax,[menus]
        jb dw2
dw1:
        ret
;----------------------------------------------------------------------------
drawfilemenu:;
;       in:
;               esi=file ptr list
;       out:
;               ?
;----------------------------------------------------------------------------        
        mov edi,[esi]                   ;edi=screen ptr
        mov ecx,[esi+16]                ;ecx=width
        mov edx,[esi+20]                ;edx=height
        call window

        mov edi,[esi]                   ;edi=screen ptr
        mov eax,[esi+4]                 ;get line offset
        mov ebp,[esi+8]                 ;ebp=selected line
        sub ebp,eax
        xor ecx,ecx                     ;ecx=line count
        mov [sel],ebp
        lea ebp,[esi+24+eax*4]          ;ebp=starting line
dwfm4:
        push edi
        mov esi,[ebp]
        add ebp,4
        inc esi
        cmp ecx,[sel]
        jne dwfm3
        call htext
        jmp dwfm5
dwfm3:  call text
dwfm5:  pop edi
        add edi,LINEHEIGHT*264
        inc ecx
        cmp dword ptr [ebp],0
        je dwfm2
        cmp ecx,MAXLINESINFILEMENU
        jb dwfm4
dwfm2:
        ret

sel     dd      ?                       ;selected line
;----------------------------------------------------------------------------
domenu:;        do new menu
;
;       in:
;               esi=menu ptr
;               edi=screen ptr
;       out:
;               ?
;----------------------------------------------------------------------------
        mov [esi],edi
        mov eax,[menus]                 ;add to menulist
        mov [menulist+eax*4],esi
        inc [menus]

        xor ebp,ebp                     ;ebp=selected line
gi5:
        mov [esi+4],ebp                 ;store selected line
        push esi
        push ebp
        call drawmenus                  ;draw all menus
        push ecx
        call [pageflip]
        pop ecx                         ;ecx=lines in active menu
        pop ebp                         ;ebp=selected line
        pop esi                         ;esi=menu ptr
gi0:
        xor al,al
gi4:    or al,[kb_last]                 ;wait for keypress
        jz gi4
        mov [kb_last],0

        cmp al,KB_UP                    ;up:
        jne gi1
        dec ebp                                 ;update line
        jns gi5
        lea ebp,[ecx-1]
        jmp gi5                                 ;and redraw
gi1:
        cmp al,KB_DOWN                  ;down:
        jne gi2
        inc ebp
        cmp ebp,ecx
        jb gi5
        xor ebp,ebp                             ;update line
        jmp gi5                                 ;and redraw
gi2:
        cmp al,KB_ENTER                 ;enter:
        jne gi3
        mov edi,[esi+8]                         ;get function list
        push esi
        push ebp
        call [edi+ebp*4]                        ;call line func, ebp=line
        pop ebp
        pop esi
        jc gi6                                  ;exit if menu function returned with CF
        jmp gi5
gi3:
        cmp al,KB_ESC                   ;esc:
        jne gi0
gi6:
        dec [menus]                     ;remove this menu from list
        ret                             ;and exit this menu
;----------------------------------------------------------------------------
startgui:;
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        call sb_pause

        mov esi,offset vscreen                  ;save nes screen in vscreen2
        mov edi,offset vscreen2
        mov ecx,264*240/4
        rep movsd

        mov [menus],0

        mov esi,offset main                     ;do main menu
        mov edi,offset vscreen+8+34*264+12
        call domenu

        call sb_resume
        ret
;----------------------------------------------------------------------------
reset:;
;----------------------------------------------------------------------------
        or [int_flags],RES
        stc
        ret
;----------------------------------------------------------------------------
lcmp:;          cmp [[edi]],[[ebp]]
;       out:
;               eax,ebx,ecx,edx=?
;----------------------------------------------------------------------------
        mov ebx,[edi]
        mov edx,[ebp]

        mov al,[ebx]                    ;check head first
        mov ah,[edx]
        cmp al,2
        jb lc0
        mov al,2
lc0:    cmp ah,2
        jb lc1
        mov ah,2
lc1:    cmp al,ah
        jne lc3

        xor ecx,ecx                     ;now do the rest
lc2:    inc ecx
        mov al,[ebx+ecx]
        mov ah,[edx+ecx]

        cmp al,97                       ;(case insensitive)
        jb lc4
        cmp al,122
        ja lc4
        add al,'A'-'a'
lc4:
        cmp ah,97
        jb lc5
        cmp ah,122
        ja lc5
        add ah,'A'-'a'
lc5:
        cmp al,ah
        jnz lc3
        or al,al
        jnz lc2
lc3:
        ret
;----------------------------------------------------------------------------
dofilemenu:;
;       in:
;               esi=file list
;               edi=screen ptr
;               ebp=end of file list
;       out:
;               eax=filename ptr
;               cf=1 on ESC
;----------------------------------------------------------------------------        
        ;[ptrlist+0]=screen ptr
        ;[ptrlist+4]=line offset
        ;[ptrlist+8]=selected line
        ;[ptrlist+12]=total lines
        ;[ptrlist+16]=window width
        ;[ptrlist+20]=window height

        mov [ebp],edi                   ;keep screen ptr
        mov dword ptr [ebp+4],0         ;reset selected
        mov [list],esi
        mov [ptrlist],ebp
;-------                            ;sort list-
        add ebp,24                      ;build ptr list
dfm30:  cmp byte ptr [esi],0
        je dfm32
        mov [ebp],esi
        add ebp,4
dfm31:  inc esi
        cmp byte ptr [esi],0
        jne dfm31
        inc esi
        jmp dfm30
dfm32:  mov dword ptr [ebp],0

dfm33:  sub ebp,4                       ;do some sorting
        mov edi,[ptrlist]
        add edi,24
        cmp edi,ebp
        jae dfm36
dfm34:  call lcmp
        jbe dfm35
        mov eax,[edi]
        xchg eax,[ebp]
        mov [edi],eax
dfm35:  add edi,4
        cmp edi,ebp
        je dfm33
        jmp dfm34
dfm36:
;-------                            ;calc window size
        xor ecx,ecx                     ;max width
        xor edx,edx                     ;line count
        mov ebp,[ptrlist]               ;list ptr
        add ebp,24
dfm20:
        mov edi,[ebp]                   ;edi=text ptr
        add ebp,4
        inc edi
        xor ebx,ebx                     ;current width
dfm21:  movzx eax,byte ptr [edi]        ;calc text width/height:
        mov al,[lookup+eax]
        shl eax,6
        add ebx,[font+eax]              ;add chars in this line
        inc edi
        cmp byte ptr [edi],0
        jne dfm21
        cmp ebx,ecx                     ;compare this line with widest line
        jbe dfm22
        mov ecx,ebx
dfm22:  inc edx                         ;count line
        cmp dword ptr [ebp],0
        jne dfm20

        mov ebp,[ptrlist]
        mov [ebp+12],edx
        mov [ebp+16],ecx     ;range check this
        mov eax,LINEHEIGHT
        cmp edx,MAXLINESINFILEMENU      ;range check window size
        jbe dfm23
        mov edx,MAXLINESINFILEMENU
dfm23:  mul edx
        mov [ebp+20],eax
;---
dfm10:
        xor ebp,ebp                     ;select line 0
dfm8:
        mov esi,[ptrlist]               ;some sanity checking ..
        cmp ebp,[esi+4]
        jae dfm14
        mov [esi+4],ebp
dfm14:
        cmp ebp,[esi+12]
        jb dfm7
        mov ebp,[esi+12]
        dec ebp
dfm7:
        mov [esi+8],ebp                         ;store selected line
        sub ebp,MAXLINESINFILEMENU-1
        js dfm15
        cmp [esi+4],ebp
        jae dfm15
        mov [esi+4],ebp                 ;..
dfm15:
        call drawmenus                  ;draw other menus
        mov esi,[ptrlist]
        call drawfilemenu               ;draw this menu
        call [pageflip]
        mov esi,[ptrlist]
        mov ebp,[esi+8]                 ;ebp=selected line
dfm0:
        xor al,al
dfm4:   or al,[kb_last]                 ;wait for keypress
        jz dfm4
        mov [kb_last],0

        cmp al,KB_UP                    ;up:
        jne dfm1
        dec ebp
        js dfm10
        jmp dfm8
dfm1:
        cmp al,KB_DOWN                  ;down:
        jne dfm2
        inc ebp
        jmp dfm8                                ;and redraw
dfm2:
        cmp al,KB_HOME                  ;home:
        je dfm10                               ;reset selected
dfm9:
        cmp al,KB_END                   ;end:
        jne dfm11
        mov ebp,-1
        jmp dfm8
dfm11:
        cmp al,KB_PGUP                  ;pageup:
        jne dfm12
        sub ebp,MAXLINESINFILEMENU
        js dfm10
        jmp dfm8
dfm12:
        cmp al,KB_PGDN                  ;pagedown:
        jne dfm13
        add ebp,MAXLINESINFILEMENU
        jmp dfm8
dfm13:
        cmp al,KB_ENTER                 ;enter:
        jne dfm3
        mov eax,[esi+ebp*4+24]                  ;eax=name ptr
        clc
        ret
dfm3:
        cmp al,KB_ESC                   ;esc:
        jne dfm0
dfm6:
        stc
        ret                             ;and exit this menu

list    dd ?
ptrlist dd ?
;----------------------------------------------------------------------------
listfiles:;     find files and add to list
;       in:
;               bl=type head
;               bh=terminator
;               cx=attrib
;               edx=name
;               edi=list start
;       out:
;               edi=list end
;               ...=...?
;----------------------------------------------------------------------------
        call findfirst
        jc lf9
lf0:
        mov byte ptr [edi],bl           ;type (file,dir,drive,etc)
        inc edi
      cmp cl,10h
      jne lf1
      mov byte ptr [edi],'\'
      inc edi
lf1:
        mov al,[esi]
        inc esi
        mov [edi],al
        inc edi
        cmp al,bh
        jne lf1
        mov byte ptr [edi-1],0          ;end of name

        call findnext
        jnc lf0
        call findclose
        clc
lf9:
        mov byte ptr [edi],0            ;end of list
        ret
;----------------------------------------------------------------------------
loadmenu:;
;----------------------------------------------------------------------------
        mov bl,1
        mov bh,0
        mov ecx,1010h                   ;dir
        mov edx,offset wilddir
        mov edi,offset tmp
        call listfiles
        jc lm0

        mov bl,2
        mov bh,'.'
        xor ecx,ecx
        mov edx,offset wildnes
        call listfiles

        mov esi,offset tmp
        lea ebp,[edi+4]
        mov edi,[htextend]
        and ebp,-4                      ;(dword align)
        push edi
        call dofilemenu
        pop edi
        jc lm0                          ;(escaped out)

        cmp byte ptr [eax],1            ;dir?
        jne lm1
        mov [htextend],edi
        lea edx,[eax+2]
        call cd                                 ;chdir
        jc lm0
        jmp loadmenu
lm1:                                    ;.nes file
        push eax
        call closerom                           ;unload current ROM
        pop eax
        lea edi,[eax+1]
lm2:    inc eax
        cmp byte ptr [eax],0
        jne lm2
        mov [eax],'SEN.'
        mov byte ptr [eax+4],0
        call loadcart                           ;try to load
        jnc cpu_init                            ;execute if ok
lm0:
        clc
        ret

wilddir db '*.*',0
wildnes db '*.NES',0
;----------------------------------------------------------------------------
palmenu:;
;----------------------------------------------------------------------------
        call savedir
        call exedir

        mov bl,1
        mov bh,'.'
        xor ecx,ecx
        mov edx,offset wildpal
        mov edi,offset tmp
        call listfiles
        jc pm0

        mov esi,offset tmp
        lea ebp,[edi+4]
        mov edi,[htextend]
        and ebp,-4                      ;(dword align)
        call dofilemenu
        jc pm0                          ;(escaped out)

        lea edx,[eax+1]                 ;open..
pm4:    inc eax
        cmp byte ptr [eax],0
        jne pm4
        mov [eax],'LAP.'
        mov byte ptr [eax+4],0
        xor cl,cl
        call f_open
        jc pm0
        mov ecx,64*3                    ;read..
        mov edx,offset tmp
        call f_read
        call f_close
        mov ecx,64                      ;copy..
        mov esi,offset tmp
        mov edi,offset palette
pm3:    mov eax,[esi]
        shr eax,2
        and eax,3f3f3fh
        add esi,3
        mov [edi],eax
        add edi,4
        dec ecx
        jnz pm3
        call setnespal                  ;set..
pm0:
        call restoredir
        clc
        ret

wildpal         db '*.PAL',0
;----------------------------------------------------------------------------
configmenu:;
;----------------------------------------------------------------------------
        xor [vwait],1                           ;sneaky :)
        call toggleV
        xor [showfps],1
        call toggleF

        mov esi,offset config
        mov edi,[htextend]
        call domenu
        clc
        ret
;----------------------------------------------------------------------------
toggleV:;
;----------------------------------------------------------------------------
        xor [vwait],1
        mov al,'Ä'
        jz vOFF
        mov al,'û'
vOFF:
;        mov [vtxt],al
        clc
        ret
;----------------------------------------------------------------------------
toggleF:;
;----------------------------------------------------------------------------
        xor [showfps],1
        mov al,'Ä'
        jz fOFF
        mov al,'û'
fOFF:
        mov [ftxt],al
        clc
        ret
;----------------------------------------------------------------------------
vidmenu:;
;----------------------------------------------------------------------------
        mov esi,offset vidmodes
        mov edi,[htextend]
        call domenu
        clc
        ret
;----------------------------------------------------------------------------
vpick:;
;----------------------------------------------------------------------------
        mov [vidmode],ebp
        call gfxmode
        call setnespal

        stc
        ret
;----------------------------------------------------------------------------
soundmenu:;
;----------------------------------------------------------------------------
        xor [soundmask],11111b
        call ch1switch
        call ch2switch
        call ch3switch
        call ch4switch
        call ch5switch

        mov esi,offset sndlist
        mov edi,[htextend]
        call domenu
        clc
        ret
;----------------------------------------------------------------------------
ch1switch:;
;----------------------------------------------------------------------------
        mov al,1
        mov edi,offset ch1txt
        jmp chXswitch
ch2switch:;
        mov al,2
        mov edi,offset ch2txt
        jmp chXswitch
ch3switch:;
        mov al,4
        mov edi,offset ch3txt
        jmp chXswitch
ch4switch:;
        mov al,8
        mov edi,offset ch4txt
        jmp chXswitch
ch5switch:;
        mov al,16
        mov edi,offset ch5txt
chXswitch:
        xor [soundmask],al
        and al,[soundmask]
        mov al,'Ä'
        jz chOFF
        mov al,'û'
chOFF:
        mov [edi],al
        clc
        ret
;----------------------------------------------------------------------------
volmenu:;
;----------------------------------------------------------------------------
        mov esi,offset vollist
        mov edi,[htextend]
        call domenu
        clc
        ret
;----------------------------------------------------------------------------
volset:;
;----------------------------------------------------------------------------
        mov eax,ebp
        inc al
        mov [soundvol],al
        call changevol
        stc
        ret
;----------------------------------------------------------------------------
ctrlmenu:;
;----------------------------------------------------------------------------
        sub ebp,CTRLMENUNUM                     ;ebp=controller#
        mov esi,[clist+ebp*4]
        mov edi,[htextend]
        mov [controlnum],ebp                    ;save controller#
        call domenu

        mov [joymask],0
        clc
        ret

        align 4
clist           dd ctl3,ctl1,ctl2,ctl2
controlnum      dd ?
;----------------------------------------------------------------------------
noconfig:
;----------------------------------------------------------------------------
        mov eax,offset unplugged
nc0:
        mov edi,[controlnum]
        mov [serial0load+edi*4],eax
        test edi,2
        jnz nc1
        mov [control0read+edi*4],offset serialread
nc1:    stc
        ret
;----------------------------------------------------------------------------
kbconfig:
;----------------------------------------------------------------------------
        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset kbtxt0
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+9
        call text
        mov esi,offset kbtxt1
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+25
        call text

        mov edi,[controlnum]
        shl edi,5
        xor ecx,ecx
        mov bl,1
kc3:
        pushad
        call flashbuttons
        popad
        call readkb
        jc kc2
        jz kc3
kc2:    mov [control0config+edi+ecx],al

        inc cl
        shl bl,1
        jnz kc3

        mov eax,offset keyboard
        jmp nc0
;----------------------------------------------------------------------------
readkb:;        check keyboard for input
;       out:
;               AL=scancode
;               (CF=1)  esc pressed
;               (ZF=1)  nothing pressed
;----------------------------------------------------------------------------
        mov al,[kb_last]
        or al,al
        jz rk2
        cmp al,KB_ESC
        je rk1
;        cmp al,KB_BREAK                 ;..ignore invalid keys
;        je rk0
;        cmp al,KB_F1
;        je rk0
;        cmp al,KB_F2
;        je rk0
;        cmp al,KB_F3
;        je rk0
;        cmp al,KB_F4
;        je rk0
;        cmp al,KB_F5
;        je rk0
;        cmp al,KB_F6
;        je rk0
;        cmp al,KB_F7
;        je rk0
;        cmp al,KB_F8
;        je rk0
;        cmp al,KB_1
;        je rk0
;        cmp al,KB_2
;        je rk0
;        cmp al,KB_3
;        je rk0
;        cmp al,KB_4
rk0:    mov [kb_last],0
rk2:    clc
        ret
rk1:    stc
        mov [kb_last],0
        ret
;----------------------------------------------------------------------------
flashbuttons:
;       in:
;               bl=button mask
;       out:
;               everything=?
;----------------------------------------------------------------------------
        call db0
        xor bl,bl
db0:
        xor esi,esi
        mov edi,[htextend]
        mov edx,8
db2:
        mov ebp,offset blackbuttons
        shr bl,1
        jnc db3
        mov ebp,offset greenbuttons
db3:    add edi,[blackbuttons+esi]
        add esi,4
        mov ecx,7
db1:
        mov eax,[esi+ebp]
        mov [edi],eax
        mov eax,[esi+ebp+4]
        mov [edi+4],eax
        add edi,264
        add esi,8
        dec ecx
        jnz db1
        dec edx
        jnz db2
        
        push [vwait]
        mov [vwait],1                   ;force vret
        call [pageflip]
        pop [vwait]
        ret
;----------------------------------------------------------------------------
readbuttons:;   read joystick buttons
;       out:
;               eax=button# (0-3)
;               edx=?
;               (zf=1: nothing pressed)
;----------------------------------------------------------------------------
        mov edx,[joybuttons]
        xor [last],edx
        jz rb1
        bsf eax,edx
        shr eax,3
        or edx,edx
rb1:
        mov [last],edx
        ret

        align 4

last    dd      0
;----------------------------------------------------------------------------
joy0config:;
;----------------------------------------------------------------------------
        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt0
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+3
        call text                       ;'center'
        mov esi,offset joytxt1
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+7
        call text
        xor bl,bl
        call flashbuttons

        or [joymask],00110000b          ;(for axis reading)

j0c0:   call joy_load
        call readkb                     ;abort on esc
        jc j0c99
j0c9:   call readbuttons                ;wait for button
        jz j0c0

        mov eax,[joy0x]                 ;init calibration stuff
        mov ebx,[joy0y]
        mov [xmin],eax
        mov [xmid],eax
        mov [xmax],eax
        mov [ymin],ebx
        mov [ymid],ebx
        mov [ymax],ebx

        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt2
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+5
        call text                       ;'circle'
        mov esi,offset joytxt3
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+7
        call text

j0c2:
        xor bl,bl
        mov al,byte ptr [joy0axis]
        bt eax,5
        rcl bl,1
        bt eax,7
        rcl bl,1
        bt eax,4
        rcl bl,1
        bt eax,6
        rcl bl,1
        call flashbuttons

        call joy_load

        mov eax,[joy0x]
        mov ebx,[joy0y]

        cmp eax,[xmin]
        ja j0c3
        mov [xmin],eax
j0c3:   cmp eax,[xmax]
        jb j0c4
        mov [xmax],eax
j0c4:   cmp ebx,[ymin]
        ja j0c5
        mov [ymin],ebx
j0c5:   cmp ebx,[ymax]
        jb j0c6
        mov [ymax],ebx
j0c6:
        mov eax,[xmin]
        mov ebx,[ymin]
        mov ecx,[xmid]
        mov edx,[ymid]
        add eax,ecx
        add ebx,edx
        shr eax,1
        shr ebx,1
        mov [joy0xmid],eax
        mov [joy0ymid],ebx
        add ecx,[xmax]
        add edx,[ymax]
        shr ecx,1
        shr edx,1
        mov [joy0xmax],ecx
        mov [joy0ymax],edx

        call readbuttons
        jz j0c2                          ;wait for button press

        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt4          ;'press button'
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+2
        call text
        mov esi,offset joytxt5
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+10
        call text

        mov edi,[controlnum]
        shl edi,5
        xor ecx,ecx
        mov bl,10h
j0c7:
        pushad
        call joy_load
        call flashbuttons
        popad
        call readbuttons
        jnz j0c8
        call readkb
        jc j0c8
        jz j0c7
j0c8:   mov [control0config+edi+ecx],al

        inc cl
        shl bl,1
        jnz j0c7

        mov eax,offset joystick0
        jmp nc0
j0c99:
        stc
        ret

xmin    dd      ?                       ;temp vars for calibration
xmid    dd      ?
xmax    dd      ?
ymin    dd      ?
ymid    dd      ?
ymax    dd      ?
;----------------------------------------------------------------------------
joy1config:;    lazy cut-n-paste :P
;----------------------------------------------------------------------------
        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt0
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+3
        call text                       ;'center'
        mov esi,offset joytxt1
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+7
        call text
        xor bl,bl
        call flashbuttons

        or [joymask],11000000b          ;(for axis reading)

j1c0:   call joy_load
        call readkb                     ;abort on esc
        jc j1c99
j1c9:   call readbuttons                ;wait for button
        jz j1c0

        mov eax,[joy1x]                 ;init calibration stuff
        mov ebx,[joy1y]
        mov [xmin],eax
        mov [xmid],eax
        mov [xmax],eax
        mov [ymin],ebx
        mov [ymid],ebx
        mov [ymax],ebx

        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt2
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+5
        call text                       ;'circle'
        mov esi,offset joytxt3
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+7
        call text

j1c2:
        xor bl,bl
        mov al,byte ptr [joy1axis]
        bt eax,5
        rcl bl,1
        bt eax,7
        rcl bl,1
        bt eax,4
        rcl bl,1
        bt eax,6
        rcl bl,1
        call flashbuttons

        call joy_load

        mov eax,[joy1x]
        mov ebx,[joy1y]

        cmp eax,[xmin]
        ja j1c3
        mov [xmin],eax
j1c3:   cmp eax,[xmax]
        jb j1c4
        mov [xmax],eax
j1c4:   cmp ebx,[ymin]
        ja j1c5
        mov [ymin],ebx
j1c5:   cmp ebx,[ymax]
        jb j1c6
        mov [ymax],ebx
j1c6:
        mov eax,[xmin]
        mov ebx,[ymin]
        mov ecx,[xmid]
        mov edx,[ymid]
        add eax,ecx
        add ebx,edx
        shr eax,1
        shr ebx,1
        mov [joy1xmid],eax
        mov [joy1ymid],ebx
        add ecx,[xmax]
        add edx,[ymax]
        shr ecx,1
        shr edx,1
        mov [joy1xmax],ecx
        mov [joy1ymax],edx

        call readbuttons
        jz j1c2                          ;wait for button press

        mov edi,[htextend]
        mov ecx,CONFIG_W
        mov edx,CONFIG_H
        call window
        mov esi,offset joytxt4          ;'press button'
        mov edi,[htextend]
        add edi,CONFIG_TEXT0_Y+2
        call text
        mov esi,offset joytxt5
        mov edi,[htextend]
        add edi,CONFIG_TEXT1_Y+10
        call text

        mov edi,[controlnum]
        shl edi,5
        xor ecx,ecx
        mov bl,10h
j1c7:
        pushad
        call joy_load
        call flashbuttons
        popad
        call readbuttons
        jnz j1c8
        call readkb
        jc j1c8
        jz j1c7
j1c8:   mov [control0config+edi+ecx],al

        inc cl
        shl bl,1
        jnz j1c7

        mov eax,offset joystick1
        jmp nc0
j1c99:
        stc
        ret
;----------------------------------------------------------------------------
zapconfig:
;----------------------------------------------------------------------------
        mov [mouseXmin],-7
        mov [mouseXmax],263
        mov [mouseYmin],-7
        mov [mouseYmax],231
        mov [control1read],offset zapper
        stc
        ret
;----------------------------------------------------------------------------
vszapconfig:
;----------------------------------------------------------------------------
        mov [mouseXmin],-7
        mov [mouseXmax],263
        mov [mouseYmin],-7
        mov [mouseYmax],231
        mov [serial0load],offset zapperVS
        stc
        ret
;----------------------------------------------------------------------------
paddleconfig:
;----------------------------------------------------------------------------
        mov [control1read],offset paddle
        mov [mouseXmin],98
        mov [mouseXmax],242
        stc
        ret
;----------------------------------------------------------------------------
cheatmenu:
;----------------------------------------------------------------------------
        mov edi,[htextend]
        mov ecx,50
        mov edx,11
        call window
c1:
        mov eax,0f9faf5f7h
        mov bl,0f0h
        mov edi,[htextend]
        sub edi,2+264*2
        mov ecx,54
        mov edx,13
        call box

        mov edi,[htextend]
        add edi,1*264+1
        mov esi,offset txt
        call text

        call [pageflip]
c2:
        call getch              ;read kb
        mov esi,[curs]
        cmp al,13               ;enter?
        je c3
        cmp al,27               ;esc?
        je c0
        cmp al,8                ;backspace?
        je c5
;                               ;normal key:
        cmp esi,8                       ;max 8 chars
        je c2
        mov ecx,15
        call gcmp                       ;valid letter code?
        jnz c2
        xor ah,ah
        mov word ptr [txt+esi],ax
        inc [curs]
        jmp c1
c3:                             ;enter
        mov esi,offset txt
        call GGadd
        mov [curs],0
        mov byte ptr [txt],0
        jmp c0
c5:                             ;backspace
        or esi,esi
        jz c2
        dec [curs]
        mov byte ptr [txt+esi-1],0
        jmp c1
c0:
        clc
        ret
gcmp:
        cmp al,[GGchars+ecx]
        je c4
        dec ecx
        jns gcmp
c4:     ret

txt db 30 dup (0)
curs dd 0
;----------------------------------------------------------------------------
drawfps:;
;----------------------------------------------------------------------------
        cmp [showfps],0
        jne fps0
        ret
fps0:
        mov eax,[fps]
        call fps3
        mov byte ptr [esi],0
        mov esi,offset strbuff
        mov edi,offset vscreen+8+264*21+10
        jmp text
fps3:;- - - - - - - - - - - - - - - - - - - - - - - write decimal# to strbuff
        mov ecx,10
        mov esi,offset strbuff
fps1:
        xor edx,edx
        div ecx
        or eax,eax
        jz fps2
        push edx
        call fps1
        pop edx
fps2:
        mov al,dl
        add al,'0'
        mov [esi],al
        inc esi
        ret

strbuff db 8 dup (0)
;----------------------------------------------------------------------------

LINEHEIGHT              equ 9           ;height of one menu line
MAXLINESINFILEMENU      equ 19
CONFIG_W                equ 80          ;controller config window
CONFIG_H                equ 49
CONFIG_TEXT0_Y          equ 264*30
CONFIG_TEXT1_Y          equ 264*39

        align 4

menulist        dd 8 dup (?)                    ;menu list
menus           dd ?                            ;items in menulist

version         db ??date,0 ;'.5X',0

kbtxt0          db 'hit key for lit',0
kbtxt1          db 'control',0
joytxt0         db 'center stick and',0
joytxt1         db 'press a button',0
joytxt2         db 'circle stick and',0
joytxt3         db 'press a button',0
joytxt4         db 'hit key or button',0
joytxt5         db 'for lit control',0

main            dd ?                            ;screen pos
                dd ?                            ;current selection
                dd mfunc                        ;line function list
                db 'LOAD',0
                db 'CONFIG',0
                db 'CHEAT',0
                db 'RESET',0
                db 'EXIT',0
                db 0
mfunc           dd loadmenu
                dd configmenu
                dd cheatmenu
                dd reset
                dd _exit

config          dd ?
                dd ?
                dd cfunc
;           atxt db 'ûAUTO RATE',0
;           vtxt db 'ûVSYNC',0
           ftxt db 'ûSHOW FPS',0
                db 'VIDEO MODE',0
                db 'SOUND',0
                db 'PALETTE',0
                db 'CONTROLLER 1',0
                db 'CONTROLLER 2',0
                db 'CONTROLLER 3',0
                db 'CONTROLLER 4',0
                db 0
cfunc: ;         dd toggleA
       ;         dd toggleV
                dd toggleF
        ;        dd togglesprite8
                dd vidmenu
                dd soundmenu
                dd palmenu
           blah dd ctrlmenu
                dd ctrlmenu
                dd ctrlmenu
                dd ctrlmenu
CTRLMENUNUM=(blah-cfunc)/4

vidmodes        dd ?
                dd ?
                dd vfunc
                db '320*200',0
                db '320*240',0
                db '256*224',0
                db 0
vfunc           dd vpick
                dd vpick
                dd vpick

sndlist         dd ?
                dd ?
                dd sndfunc
         ch1txt db 'ûSQUARE 1',0
         ch2txt db 'ûSQUARE 2',0
         ch3txt db 'ûTRIANGLE',0
         ch4txt db 'ûNOISE',0
         ch5txt db 'ûPCM',0
                db 'VOLUME..',0
                db 0
sndfunc         dd ch1switch
                dd ch2switch
                dd ch3switch
                dd ch4switch
                dd ch5switch
                dd volmenu

vollist         dd ?
                dd ?
                dd volfunc
                db '1',0
                db '2',0
                db '3',0
                db '4',0
                db '5',0
                db '6',0
                db '7',0
                db '8',0
                db '9',0
                db '10',0
                db 0
volfunc         dd volset
                dd volset
                dd volset
                dd volset
                dd volset
                dd volset
                dd volset
                dd volset
                dd volset
                dd volset

ctl1            dd ?
                dd ?
                dd ctlfunc
                db 'NONE',0
                db 'KEYBOARD',0
                db 'JOYSTICK 1',0
                db 'JOYSTICK 2',0
                db 'ZAPPER',0
                db 'PADDLE',0
                db 0
ctlfunc         dd noconfig
                dd kbconfig
                dd joy0config
                dd joy1config
                dd zapconfig
                dd paddleconfig

ctl2            dd ?
                dd ?
                dd ctlfunc
                db 'NONE',0
                db 'KEYBOARD',0
                db 'JOYSTICK 1',0
                db 'JOYSTICK 2',0
                db 0

ctl3            dd ?
                dd ?
                dd ctl3func
                db 'NONE',0
                db 'KEYBOARD',0
                db 'JOYSTICK 1',0
                db 'JOYSTICK 2',0
                db 'ZAPPER (VS)',0
                db 0
ctl3func        dd noconfig
                dd kbconfig
                dd joy0config
                dd joy1config
                dd vszapconfig

blackbuttons    dd 264*11+10
                db 0f8h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;left
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f6h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f8h,0fah,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd -264*13+6
                db 0f8h,0f6h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h      ;up
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd -264*1+6
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h      ;right
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0fah,0f8h,0f8h
                dd -264*1-6
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;down
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0f6h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0fah,0fah,0fah,0fah,0fah,0f8h,0f8h
                dd -264*13+17
                db 0f8h,0f8h,0f8h,0f8h,0f6h,0f6h,0f8h,0f8h      ;select
                db 0f8h,0f8h,0f8h,0f6h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0fah,0f8h,0f8h,0f8h,0f8h
                db 0f8h,0fah,0fah,0f8h,0f8h,0f8h,0f8h,0f8h
                dd -264*7+8
                db 0f8h,0f8h,0f8h,0f8h,0f6h,0f6h,0f8h,0f8h      ;start
                db 0f8h,0f8h,0f8h,0f6h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0fah,0f8h,0f8h,0f8h,0f8h
                db 0f8h,0fah,0fah,0f8h,0f8h,0f8h,0f8h,0f8h
                dd -264*7+11
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;B
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0f6h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd -264*7+9
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;A
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0f6h,0f8h,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f6h,0f0h,0f0h,0f0h,0f0h,0f0h,0fah,0f8h
                db 0f8h,0f6h,0f0h,0f0h,0f0h,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h

greenbuttons    dd ?
                db 0f8h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;left
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0f6h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f8h,0fah,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd ?
                db 0f8h,0f6h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h      ;up
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f6h,0f8h,0f8h      ;right
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0fah,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;down
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0f6h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0fah,0fah,0fah,0fah,0fah,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f8h,0f8h,0f6h,0f6h,0f8h,0f8h      ;select
                db 0f8h,0f8h,0f8h,0f6h,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0fah,0f8h,0f8h,0f8h,0f8h
                db 0f8h,0fah,0fah,0f8h,0f8h,0f8h,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f8h,0f8h,0f6h,0f6h,0f8h,0f8h      ;start
                db 0f8h,0f8h,0f8h,0f6h,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0fah,0f8h,0f8h,0f8h,0f8h
                db 0f8h,0fah,0fah,0f8h,0f8h,0f8h,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;B
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0f6h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h
                dd ?
                db 0f8h,0f8h,0f6h,0f6h,0f6h,0f8h,0f8h,0f8h      ;A
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0f6h,0f8h,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f6h,0eeh,0eeh,0eeh,0eeh,0eeh,0fah,0f8h
                db 0f8h,0f6h,0eeh,0eeh,0eeh,0fah,0f8h,0f8h
                db 0f8h,0f8h,0fah,0fah,0fah,0f8h,0f8h,0f8h

;----------------------------------------------------------------------------
code    ends
        end

