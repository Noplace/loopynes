        .386p
code    segment public use32
        assume cs:code,ds:code

        include font.h
        include data.h
        include empty.h
        include debug.h
        include equates.h
        include config.h
        include ppu.h
        include main.h

        public  vga_exit
        public  textmode
        public  gfxmode
        public  tweak
        public  vgamode
        public  setcursor
        public  putch
        public  putch2
        public  putstr
        public  newline
        public  puthex32
        public  puthex24
        public  puthex16
        public  puthex8
        public  debugnum
        public  cursor
        public  space
        public  pageflip

;----------------------------------------------------------------------------
vga_exit:;      restore display
;----------------------------------------------------------------------------
        xor eax,eax
        cmp [vgamode],eax               ;already in textmode?
        jne ve0                         ;jump if not

        cmp [cursor],7fffffffh          ;skip if cursor hasnt been modified
        ja ve2                          ;(still at dos screen.. must have been
                                        ;an error)
        mov eax,[cursor]
        mov bl,80                       ;exiting from a debug screen-
        div bl                          ;set BIOS cursorpos
        mov edx,eax                     
        xchg dh,dl                      
        mov ah,02h
        xor bh,bh
        int 10h
ve2:
        ret
ve0:
        mov [_eax],0003h                ;mode 03h
        mov ax,0300h
        mov bx,0010h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode int (some older BIOSes need this)
        ret
;----------------------------------------------------------------------------
gfxmode:;       switch to grafx mode
;----------------------------------------------------------------------------
        mov [vgamode],1
        mov edi,[vidmode]
        jmp [modelist+edi*4]
;----------------------------------------------------------------------------
m256x224:;
;----------------------------------------------------------------------------
        mov esi,offset t256x224
        mov [pageflip],offset d256x240
        jmp m00
;----------------------------------------------------------------------------
m256x240:;
;----------------------------------------------------------------------------
        mov [pageflip],offset d256x240
        mov esi,offset t256x240
m00:
        mov [_eax],0013h                ;mode 13h
        mov ax,0300h
        mov bx,0010h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode int (some older BIOSes need this)
        jc error2                       ;exit on DPMI error

        push esi
        call setpal
        pop esi

        mov eax,0f0f0f0f0h               ;clear borders
        mov edi,[gfx_ptr]
        mov ecx,256*8/4-1
m0:     mov [edi+ecx*4],eax
        dec ecx
        jns m0
        add edi,232*256
        mov ecx,256*8/4-1
m1:     mov [edi+ecx*4],eax
        dec ecx
        jns m1
tweak:; - - - - - - - - - - - - - - - - -
        mov edx,3c2h
        mov al,[esi]
        out dx,al                       ;send first value to port 3C2h

        mov edx,3d4h
        mov ecx,15
set1:   add esi,4
        mov eax,[esi]
        out dx,ax                       ;send the rest to port 3D4h
        dec ecx
        jnz set1
        ret

t256x240  dd 00e3h,0c11h,5f00h,3f01h,4002h,8203h,4e04h,9605h
          dd 0d06h,3e07h,4109h,0ea10h,0df12h,2013h,0e715h,0616h

; fullscreen 68hz
t256x224        dd      0063h,0e11h,5100h,3f01h,4002h,9403h,4504h,0c05h
                dd      1206h,03e07h,4109h,0ec10h,0df12h,2013h,0e615h,0c16h
;----------------------------------------------------------------------------
m320x200:;
;----------------------------------------------------------------------------
        mov [pageflip],offset d320x200

        mov eax,0013h                   ;mode 13h
        int 10h                         

        mov eax,0f0f0f0f0h              ;clear borders
        mov edi,[gfx_ptr]
        mov edx,200
m3201:  mov ecx,8
m3200:  mov [edi],eax
        mov [edi+32+256],eax
        add edi,4
        dec ecx
        jnz m3200
        add edi,320-32
        dec edx
        jnz m3201

        jmp setpal
;----------------------------------------------------------------------------
setpal:;        setup palette stuff for 256 color modes
;
;       out:
;               ?
;----------------------------------------------------------------------------
        mov edx,3c8h                    ;00-3f=entire nes palette
        xor al,al
        xor ebx,ebx
        out dx,al
        inc edx
        mov ecx,-64
        mov edi,[palmap]
        mov esi,offset palette
sp1:
        mov bl,[ecx+edi+64]
        mov eax,[esi+ebx*4]
        out dx,al
        shr eax,8
        out dx,al
        shr eax,8

        out dx,al
        cmp bl,0fh
        jne sp2
        lea ebp,[ecx+64]
sp2:    inc cl
        js sp1
                 
        xor al,al                       ;(40-5f=16 color nes palette)
        out dx,al
        out dx,al
        out dx,al

        dec edx
        mov al,0edh
        out dx,al
        inc edx
        mov al,3fh
        out dx,al                       ;ed=red
        xchg ah,al                      ;ee=green
        out dx,al                       ;ef=blue
        out dx,al
        out dx,al
        xchg ah,al
        out dx,al
        xchg ah,al
        out dx,al
        out dx,al
        out dx,al
        xchg ah,al
        out dx,al

        xor eax,eax                     ;f0-ff=black->white
sp0:    out dx,al
        out dx,al
        out dx,al
        add al,4
        test al,40h
        jz sp0

        mov edx,3dah                    ;set overscan color to (nes 0fh)
        in al,dx
        mov edx,3c0h
        mov al,31h
        out dx,al
        mov eax,ebp
        out dx,al

        ret
;----------------------------------------------------------------------------
textmode:;      switch to 80x50 text mode
;----------------------------------------------------------------------------
        mov [cursor],0                  ;reset stuff
        mov [vgamode],0
 
        mov eax,0003h                   ;VGA mode 03h
        int 10h

        mov eax,1112h                   ;80x50
        xor ebx,ebx
        int 10h

;        mov [_eax],1112h                ;switch to 80x50
;        xor eax,eax
;        mov [_ebx],eax
;        mov eax,0300h
;        mov ebx,0010h
;        xor ecx,ecx
;        mov edi,offset reg_struc        ;simulate real mode interrupt
;        add edi,[code_addr]             ;(need to do it this way or 8x8 font
;        int 31h                         ;won't load right)

        ret
;----------------------------------------------------------------------------
setcursor:;     move hardware cursor to [cursor]
;
;       out:
;               none
;----------------------------------------------------------------------------
        push eax
        push edx

        mov edx,3d4h
        mov al,0eh
        mov ah,byte ptr [cursor+1]
        out dx,ax
        inc al
        mov ah,byte ptr [cursor]
        out dx,ax

        pop edx
        pop eax
sc9:    ret
;----------------------------------------------------------------------------
space:;         putch ' '
;       out:
;               al=' '
;----------------------------------------------------------------------------
        mov al,' '
        ;..
;----------------------------------------------------------------------------
putch:;         filtered character output (BS and CR handling)
;
;       in:
;               AL=char
;       out:
;               none
;----------------------------------------------------------------------------
        or al,al
        jz sc9
        cmp al,13
        je newline
        cmp al,8
        jne putch2

        push edi                                ;backspace
        dec [cursor]
        mov edi,[cursor]
        shl edi,1
        add edi,[text_ptr]
        mov word ptr [edi],0720h        
        pop edi
        ret
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
putch2:;        character output (nonfiltered)
        push edi
        mov edi,[cursor]
        shl edi,1
        add edi,[text_ptr]

        mov [edi],al
        mov byte ptr [edi+1],7
        pop edi

        inc [cursor]
        cmp [cursor],80*50
        jae newline2
        ret
;----------------------------------------------------------------------------
putstr:;        filtered string output (BS and CR handling)
;
;       in:
;               ESI=string ptr
;       out:
;               ESI=?
;----------------------------------------------------------------------------
        push eax
ps1:    mov al,[esi]
        call putch
        inc esi
        or al,al
        jnz ps1
ps0:    pop eax
        ret
;----------------------------------------------------------------------------
newline:;       move cursor to next line, shifting display up if necessary
;
;       out:
;               none
;----------------------------------------------------------------------------
        push eax
        push ebx

        mov eax,[cursor]
        mov ebx,80
        div bl
        sub bl,ah
        add [cursor],ebx                ;cursor+=80-(cursor%80)

        cmp [cursor],80*50
        pop ebx
        pop eax
        jb n1                           ;skip if dont need to scroll up

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
newline2:;      shift up display
        push eax
        push edx
        push edi

        mov edi,[text_ptr]
        mov edx,80*49*2/4
n0:     mov eax,[edi+80*2]
        mov [edi],eax
        add edi,4
        dec edx
        jnz n0
        mov eax,07000700h
        mov edx,80*2/4
n2:     mov [edi],eax
        add edi,4
        dec edx
        jnz n2
        mov [cursor],80*49

        pop edi
        pop edx
        pop eax
n1:     ret
;----------------------------------------------------------------------------
;puthex:;       print hex value
;
;       in:
;               eax=#
;       out:
;               eax,cl=?
;----------------------------------------------------------------------------
puthex8:
        mov cl,2
        jmp ph0
puthex16:
        mov cl,4
        jmp ph0
puthex24:
        mov cl,6
        jmp ph0
puthex32:
        mov cl,8
ph0:
        dec cl
        jz ph1
        push eax
        shr eax,4
        call ph0
        pop eax
ph1:
        and eax,0fh
        mov al,[eax+hextable]
        jmp putch
;----------------------------------------------------------------------------
debugnum:;      draw debug# to vscreen
;
;       in:
;               eax=val
;               edi=screen ptr
;       out:
;               eax,ebx,esi,edi,ebp=?
;----------------------------------------------------------------------------
        mov ebp,8                       ;char counter
dn2:
        rol eax,4
        mov bl,al
        and ebx,0fh
        cmp bl,10
        jb dn3
        add bl,'A'-':'
dn3:
        add bl,[lookup+'0']
        shl ebx,6
        lea esi,[font+ebx+8]
W=108h
        mov ebx,[esi+00h]
        mov [edi       ],ebx
        mov ebx,[esi+04h]
        mov [edi     +4],ebx
        mov ebx,[esi+08h]
        mov [edi+W*1  ],ebx
        mov ebx,[esi+0ch]
        mov [edi+W*1+4],ebx
        mov ebx,[esi+10h]
        mov [edi+W*2  ],ebx
        mov ebx,[esi+14h]
        mov [edi+W*2+4],ebx
        mov ebx,[esi+18h]
        mov [edi+W*3  ],ebx
        mov ebx,[esi+1ch]
        mov [edi+W*3+4],ebx
        mov ebx,[esi+20h]
        mov [edi+W*4  ],ebx
        mov ebx,[esi+24h]
        mov [edi+W*4+4],ebx
        mov ebx,[esi+28h]
        mov [edi+W*5  ],ebx
        mov ebx,[esi+2ch]
        mov [edi+W*5+4],ebx
        mov ebx,[esi+30h]
        mov [edi+W*6  ],ebx
        mov ebx,[esi+34h]
        mov [edi+W*6+4],ebx

        add edi,9
        dec ebp
        jnz dn2
        ret
;----------------------------------------------------------------------------
vret:;          wait for retrace
;----------------------------------------------------------------------------
        test [vwait],1
        jnz vr2
        ret
vr2:
        mov edx,3dah
vr0:    in al,dx
        test al,8
        jnz vr0
vr1:    in al,dx
        test al,8
        jz vr1
        ret
;----------------------------------------------------------------------------
d256x240:;      dump vscreen to vga
;----------------------------------------------------------------------------
        call vret

        mov esi,offset vscreen+8+8*264
        mov edi,[gfx_ptr]
        mov edx,224
        add edi,8*256
pf1:    mov eax,[esi]
        mov ecx,[esi+4]
        mov [edi],eax
        mov [edi+4],ecx
        mov eax,[esi+8]
        mov ecx,[esi+12]
        mov [edi+8],eax
        mov [edi+12],ecx
        mov eax,[esi+16]
        mov ecx,[esi+20]
        mov [edi+16],eax
        mov [edi+20],ecx
        mov eax,[esi+24]
        mov ecx,[esi+28]
        mov [edi+24],eax
        mov [edi+28],ecx

        mov eax,[esi+32]
        mov ecx,[esi+36]
        mov [edi+32],eax
        mov [edi+36],ecx
        mov eax,[esi+40]
        mov ecx,[esi+44]
        mov [edi+40],eax
        mov [edi+44],ecx
        mov eax,[esi+48]
        mov ecx,[esi+52]
        mov [edi+48],eax
        mov [edi+52],ecx
        mov eax,[esi+56]
        mov ecx,[esi+60]
        mov [edi+56],eax
        mov [edi+60],ecx

        mov eax,[esi+64]
        mov ecx,[esi+68]
        mov [edi+64],eax
        mov [edi+68],ecx
        mov eax,[esi+72]
        mov ecx,[esi+76]
        mov [edi+72],eax
        mov [edi+76],ecx
        mov eax,[esi+80]
        mov ecx,[esi+84]
        mov [edi+80],eax
        mov [edi+84],ecx
        mov eax,[esi+88]
        mov ecx,[esi+92]
        mov [edi+88],eax
        mov [edi+92],ecx

        mov eax,[esi+96]
        mov ecx,[esi+100]
        mov [edi+96],eax
        mov [edi+100],ecx
        mov eax,[esi+104]
        mov ecx,[esi+108]
        mov [edi+104],eax
        mov [edi+108],ecx
        mov eax,[esi+112]
        mov ecx,[esi+116]
        mov [edi+112],eax
        mov [edi+116],ecx
        mov eax,[esi+120]
        mov ecx,[esi+124]
        mov [edi+120],eax
        mov [edi+124],ecx

        mov eax,[esi+128]
        mov ecx,[esi+132]
        mov [edi+128],eax
        mov [edi+132],ecx
        mov eax,[esi+136]
        mov ecx,[esi+140]
        mov [edi+136],eax
        mov [edi+140],ecx
        mov eax,[esi+144]
        mov ecx,[esi+148]
        mov [edi+144],eax
        mov [edi+148],ecx
        mov eax,[esi+152]
        mov ecx,[esi+156]
        mov [edi+152],eax
        mov [edi+156],ecx

        mov eax,[esi+160]
        mov ecx,[esi+164]
        mov [edi+160],eax
        mov [edi+164],ecx
        mov eax,[esi+168]
        mov ecx,[esi+172]
        mov [edi+168],eax
        mov [edi+172],ecx
        mov eax,[esi+176]
        mov ecx,[esi+180]
        mov [edi+176],eax
        mov [edi+180],ecx
        mov eax,[esi+184]
        mov ecx,[esi+188]
        mov [edi+184],eax
        mov [edi+188],ecx

        mov eax,[esi+192]
        mov ecx,[esi+196]
        mov [edi+192],eax
        mov [edi+196],ecx
        mov eax,[esi+200]
        mov ecx,[esi+204]
        mov [edi+200],eax
        mov [edi+204],ecx
        mov eax,[esi+208]
        mov ecx,[esi+212]
        mov [edi+208],eax
        mov [edi+212],ecx
        mov eax,[esi+216]
        mov ecx,[esi+220]
        mov [edi+216],eax
        mov [edi+220],ecx

        mov eax,[esi+224]
        mov ecx,[esi+228]
        mov [edi+224],eax
        mov [edi+228],ecx
        mov eax,[esi+232]
        mov ecx,[esi+236]
        mov [edi+232],eax
        mov [edi+236],ecx
        mov eax,[esi+240]
        mov ecx,[esi+244]
        mov [edi+240],eax
        mov [edi+244],ecx
        mov eax,[esi+248]
        mov ecx,[esi+252]
        mov [edi+248],eax
        mov [edi+252],ecx

        add edi, 256
        add esi, 264
        dec edx
        jnz pf1

        ret
;----------------------------------------------------------------------------
d320x200:;      dump vscreen to vga
;----------------------------------------------------------------------------
        call vret

        mov esi,offset vscreen+8+(8+12)*264
        mov edi,[gfx_ptr]
        add edi,32
        mov edx,200
d3200:  mov ecx,256/4
d3201:  mov eax,[esi]
        add esi,4
        mov [edi],eax
        add edi,4
        dec ecx
        jnz d3201
        add esi,8
        add edi,64
        dec edx
        jnz d3200
        ret
;----------------------------------------------------------------------------

        align   4

hextable        db      '0123456789ABCDEF'

pageflip        dd      ?               ;draw screen

cursor          dd      -1              ;text cursor pos.

vgamode         dd      0               ;current VGA mode- 0=text,>0=gfx

modelist        dd      m320x200        ;init routines for gfx modes
                dd      m256x240
                dd      m256x224

;----------------------------------------------------------------------------
code    ends
        end
