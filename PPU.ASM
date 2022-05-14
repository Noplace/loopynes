;----------------------------------------------------------------------------
; NES PPU stuff
;----------------------------------------------------------------------------
        .486p
code    segment public use32
        assume cs:code,ds:code

        include io.h
        include memory.h
        include equates.h
        include input.h
        include file.h
        include vga.h
        include empty.h
        include kb.h
        include data.h
        include 6502.h
        include debug.h
        include memory.h
        include gui.h
        include config.h
        include mouse.h
        include sb.h
        include mappers.h

        public PPU_R
        public PPU_W
        public drawframe
        public drawline
        public ctrl0
        public ctrl1
        public stat
        public unpack
        public palchange
        public spritechange
        public vmdata_W
        public newchrmap
        public chr_map
        public name0_map
        public name1_map
        public name2_map
        public name3_map
        public oamaddr
        public vmaddr
        public vmaddr2
        public xoffset
        public toggle
        public vmainc
        public ppureset
        public setnespal
        public vram_map
        public render
        public striketime
        public VRAM_write_tbl
        public VRAM_pat
        public VRAM_empty
        public bgskip
        public writeattrib
        public ctrl0_W2
        public checkKB
        public xscroll_w
        public yscroll_w
        public xsame
        public sortsprites
        public sprite8hook
        public sprite16hook
        public bg1hook
        public bg8hook
;----------------------------------------------------------------------------
PPU_R:;         PPU read
;----------------------------------------------------------------------------
        and edi,7
        jmp [PPU_read_tbl+edi*4]
;----------------------------------------------------------------------------
PPU_W:;         PPU write
;----------------------------------------------------------------------------
        and edi,7
        jmp [PPU_write_tbl+edi*4]
;----------------------------------------------------------------------------
ppureset:;      called with CPU reset
;----------------------------------------------------------------------------
        mov [ctrl0],0                           ;NMI off
        mov [ctrl1],0                           ;screen off
        mov [stat],0                            ;flags off
        mov [striketime],-1                     ;strike off
        mov [vmainc],1                          ;..
        mov [toggle],0
        ret
;----------------------------------------------------------------------------
ctrl0_W:;       (2000)
;----------------------------------------------------------------------------
        trace tCTRL0w,al
ctrl0_W2:                                         ;(for loadSNSS)
        mov ah,[ctrl0]
        mov [ctrl0],al
        xor al,ah

        test al,CR0_8X16
        jz c02
        mov [spritechange],1            ;flag change in sprite size
c02:
        and al,[ctrl0]
        and al,[stat]
        jns c03
        or [int_flags],NMI              ;NMI when NMIen&VBLflag=0->1
c03:
        mov [vmainc],1                            ;update vmainc
        test [ctrl0],04h
        jz c00
        mov [vmainc],32
c00:
        mov [drawsprites],offset drawsprites8     ;update drawsprites
        test [ctrl0],20h
        jz c01
        mov [drawsprites],offset drawsprites16
c01:
        call newchrmap

        mov al,[ctrl0]
        and eax,3
        shl eax,10
        and [vmaddr2],111001111111111b
        or [vmaddr2],eax
        mov [xsame],0                          ;BG changed

        ret
;----------------------------------------------------------------------------
ctrl1_W:;       (2001)
;----------------------------------------------------------------------------
        trace tCTRL1w,al
        mov [ctrl1],al
        mov [bgskip],0                          ;stuff

        ret
;----------------------------------------------------------------------------
stat_R:;        (2002)
;----------------------------------------------------------------------------
        mov edi,[linecycles]
        xor eax,eax
        sub edi,[cycles]
        mov [toggle],eax
        sub edi,[striketime]
        adc al,7fh
        and al,40h                              ;al=40h if striketime>cycles

        or al,[stat]
        and [stat], not STAT_VBL                ;clear VBL flag
;        trace tSTATr,al
        ret
;----------------------------------------------------------------------------
oamaddr_W:;     (2003)
;----------------------------------------------------------------------------
        trace tOAMADDRw, al
        mov byte ptr [oamaddr], al
        ret
;----------------------------------------------------------------------------
oamdata_R:;     (2004)
;----------------------------------------------------------------------------
if DEBUG
        or [int_flags],DEBUG2
        mov [debugmsg],offset msg46
endif
        mov [spritechange],1
        mov edi,[oamaddr]
        mov al,[oam+edi]
        ret
;----------------------------------------------------------------------------
oamdata_W:;     (2004)
;----------------------------------------------------------------------------
        mov [spritechange],1
        mov edi,[oamaddr]
        mov [oam+edi],al
        inc byte ptr [oamaddr]
        ret
;----------------------------------------------------------------------------
bgscroll_W:;    (2005)
;----------------------------------------------------------------------------
        trace tSCROLLw,al
        xor [toggle],1
        jz yscroll_w
xscroll_w:                      ;! loadSNSS also calls these
        mov edi,eax
        shr al,3
        and edi,7
        mov [xoffset],edi
        and [vmaddr2],111111111100000b
        or byte ptr [vmaddr2],al
        mov [xsame],0                          ;BG changed
        ret
yscroll_w:
        mov edi,eax
        and eax,07h
        and edi,0f8h
        shl eax,12
        and [vmaddr2],000110000011111b
        lea edi,[edi*4+eax]
        or [vmaddr2],edi
        ret
;----------------------------------------------------------------------------
vmaddr_W:;      (2006)
;----------------------------------------------------------------------------
        trace tVMADDRw,al
        xor [toggle],1
        jz low
high:
        and al,3fh
        mov byte ptr [vmaddr2+1],al
        mov [xsame],0                          ;BG changed
        ret
low:
        mov byte ptr [vmaddr2],al
        mov eax,[vmaddr2]
        mov [vmaddr],eax
        mov [bgskip],0                          ;BG changed
        ret
;----------------------------------------------------------------------------
vmdata_R:;      (2007)
;----------------------------------------------------------------------------
        trace tVMDATAr,0
        mov edi,[vmaddr]
        mov ebp,[vmainc]
        and edi,3fffh
        add [vmaddr],ebp
        cmp edi,3f00h
        jae palread

        mov eax,edi
        and edi,03ffh
        shr eax,10
        add edi,[vram_map+eax*4]
        mov al,[edi]
        xchg al,[readreg]
        ret
palread:
        and edi,1fh
        mov al,[vram+3f00h+edi]
        ret
;----------------------------------------------------------------------------
vmdata_W:;      (2007)
;----------------------------------------------------------------------------
        mov [bgskip],0                          ;BG change
        mov ebp,[vmaddr]
        mov edi,[vmainc]
        and ebp,3fffh
        add [vmaddr],edi
        mov edi,ebp
        shr ebp,10
        jmp [VRAM_write_tbl+ebp*4]
;----------------------------------------------------------------------------
newchrmap:;     set new oamchr_map,bgchr_map,vram_map
;               (call on chr_map/CTRL0 change)
;       out:
;               eax,edi=?
;----------------------------------------------------------------------------
        push ecx

        mov edi, offset chr_map
        test [ctrl0], 08h
        jz  nc1
        add edi, 16
nc1:    mov eax,[edi]                           ;new oamchr_map
        mov ecx,[edi+4]
        mov [oamchr_map],eax
        mov [oamchr_map+4],ecx
        mov eax,[edi+8]
        mov ecx,[edi+12]
        mov [oamchr_map+8],eax
        mov [oamchr_map+12],ecx

        mov edi,offset chr_map
        test [ctrl0],10h
        jz nc0
        add edi,16
nc0:    mov eax,[edi]                           ;new bgchr_map
        mov ecx,[edi+4]
        mov [bgchr_map],eax
        mov [bgchr_map+4],ecx
        mov eax,[edi+8]
        mov ecx,[edi+12]
        mov [bgchr_map+8],eax
        mov [bgchr_map+12],ecx

        mov edi,8                               ;new vram_map (0000-1fff)
nc3:    mov eax,[chr_map+edi*4-4]
        mov ecx,[chr_map+edi*4-8]
        sub eax,[chr_ptr]
        sub ecx,[chr_ptr]
        shr eax,2
        shr ecx,2
        add eax,[vrom_ptr]
        add ecx,[vrom_ptr]
        mov [vram_map+edi*4-4],eax
        mov [vram_map+edi*4-8],ecx
        sub edi, 2
        jnz nc3

        pop ecx
        mov [bgskip],0                          ;stuff

        ret
;----------------------------------------------------------------------------
drawdips:;
;----------------------------------------------------------------------------
        mov edi,offset vscreen+264*32+212

        test [serial0mask],08h
        call dipON
        test [serial0mask],10h
        call dipON
        test [serial1mask],04h
        call dipON
        add edi,2
        test [serial1mask],10h
        call dipON
        test [serial1mask],20h
        call dipON
        add edi,2
        test [serial1mask],08h
        call dipON
        test [serial1mask],40h
        call dipON
        test [serial1mask],80h
dipON:
        mov [edi+264*0],0f8f8f8f8h
        mov [edi+264*5],0f8f8f8f8h
        jz dipOFF
        mov [edi+264*1],0f8fffff8h
        mov [edi+264*2],0f8fffff8h
        mov [edi+264*3],0f8f0f0f8h
        mov [edi+264*4],0f8f0f0f8h
        add edi,5
        ret
dipOFF:
        mov [edi+264*1],0f8f0f0f8h
        mov [edi+264*2],0f8f0f0f8h
        mov [edi+264*3],0f8fffff8h
        mov [edi+264*4],0f8fffff8h
        add edi,5
        ret
;----------------------------------------------------------------------------
checkKB:;       called at the start of every frame
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        getc
        jnz df00
        ret
df00:
        cmp al, KB_ESC                          ;ESC- do GUI
        jne df08
        call startgui
        mov eax,[framecount]                    ;reset timer
        mov [ticks], eax
        ret
df08:
        cmp al,KB_F1                            ;F1-F4- save state
        jb df03
        cmp al,KB_F4
        ja df03
        sub al,KB_F1
        call saveSNSS
        ret
df03:
        cmp al,KB_F5                            ;F5-F8- load state
        jb df04
        cmp al,KB_F8
        ja df04
        sub al,KB_F5
        call loadSNSS
        ret
df04:
        cmp al,KB_F9                            ;F9- snapshot
        jne df05
        call savepcx
        ret
df05:
        cmp al,KB_F10                           ;F10- .WAV record
        jne df06
        call wavrecord
        mov ebx,[ticks]
        mov [recordblink],ebx
        ret
df06:
        cmp al,KB_CTRLBREAK                     ;^BRK- debug
        jne df01
if DEBUG
        or [int_flags],DEBUG2
        mov [debugmsg],offset msg41
        ret
else
        ;hard reset
        ret
endif
df01:
        cmp al,KB_BREAK                         ;break- reset
        jne df02
        or [int_flags],RES
        ret
df02:
        test [cartflags],VS
        jz df18

        cmp al,KB_1
        jb df18
        cmp al,KB_8
        ja df18
        mov ebx,[ticks]
        add ebx,120                     ;2 second timeout
        mov [diptimeout],ebx
        mov cl,[serial0mask]
        mov ch,[serial1mask]

        cmp al,KB_1
        jne df11
        xor cl,08h
  df11:
        cmp al,KB_2
        jne df12
        xor cl,10h
  df12:
        cmp al,KB_3
        jne df13
        xor ch,04h
  df13:
        cmp al,KB_4
        jne df14
        xor ch,10h
  df14:
        cmp al,KB_5
        jne df15
        xor ch,20h
  df15:
        cmp al,KB_6
        jne df16
        xor ch,08h
  df16:
        cmp al,KB_7
        jne df17
        xor ch,40h
  df17:
        cmp al,KB_8
        jne df07
        xor ch,80h
  df07:
        mov [serial0mask],cl
        mov [serial1mask],ch
df18:
        ret
;----------------------------------------------------------------------------
drawframe:;     screen redraw
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        cmp [render],0
        jne df0
        ret
df0:
        call getinput                           ;deal with input devices

        cmp [control1read],offset zapper        ;draw zapper crosshairs
        je df5
        cmp [serial0load],offset zapperVS
        jne df1
df5:    mov eax,[mouseY]
        mov edi,eax
        shl edi,8
        lea edi,[vscreen+8+8*264+edi+eax*8]
        add edi,[mouseX]

        cmp [mouseX],255
        jg df2
        mov dword ptr [edi+3],0ffffffffh
        cmp [mouseX],0
        jl df3
df2:
        mov dword ptr [edi-6],0ffffffffh
df3:
        cmp [mouseY],0
        jl df4
        mov byte ptr [edi-264*3],0ffh
        mov byte ptr [edi-264*4],0ffh
        mov byte ptr [edi-264*5],0ffh
        mov byte ptr [edi-264*6],0ffh
        cmp [mouseY],223
        jg df1
df4:
        mov byte ptr [edi+264*3],0ffh
        mov byte ptr [edi+264*4],0ffh
        mov byte ptr [edi+264*5],0ffh
        mov byte ptr [edi+264*6],0ffh
df1:
        call drawfps                            ;draw fps
if DEBUG eq 2
        mov eax,[prof0]
        mov edi,offset vscreen+8+264*6*6
        call debugnum
        mov eax,[prof1]
        mov edi,offset vscreen+8+264*6*7
        call debugnum
        mov eax,[prof2]
        mov edi,offset vscreen+8+264*6*8
        call debugnum
        mov eax,[prof3]
        mov edi,offset vscreen+8+264*6*9
        call debugnum
        mov eax,[prof4]
        mov edi,offset vscreen+8+264*6*10
        call debugnum
        mov eax,[prof5]
        mov edi,offset vscreen+8+264*6*11
        call debugnum
        mov eax,[prof6]
        mov edi,offset vscreen+8+264*6*12
        call debugnum
        mov eax,[prof7]
        mov edi,offset vscreen+8+264*6*13
        call debugnum
endif

        mov eax,[ticks]                         ;draw dip switches
        cmp eax,[diptimeout]
        ja df19
        call drawdips
df19:
        cmp [wavhandle],0                       ;draw record pic
        je df20
        mov edi,offset vscreen+232+264*40
        test [blink],1
        jz df21
        mov eax,0ededededh                               ;red dot
        mov [edi+264*0+1],ax
        mov [edi+264*0+3],al
        mov [edi+264*1],eax
        mov [edi+264*1+4],al
        mov [edi+264*2],eax
        mov [edi+264*2+4],al
        mov [edi+264*3],eax
        mov [edi+264*3+4],al
        mov [edi+264*4+1],ax
        mov [edi+264*4+3],al
df21:   mov esi,offset rectxt
        sub edi,264-7
        call text
        mov eax,[ticks]
        cmp eax,[recordblink]
        jb df20
        add [recordblink],15                            ;1/4 second
        xor [blink],1
df20:
        call [pageflip]                         ;dump to screen

        inc [drawn]                             ;update pages drawn counter
        ret

rectxt  db 'REC',0
;----------------------------------------------------------------------------
drawline:;
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        cmp [render],0                          ;drawing this frame?
        jne dl5

 ;still need to deal with sprite0 hits

        mov eax,[scanline]
        cmp [spritecount+eax],0         ;no sprites?
        je dl2
        shl eax,5
        test [spritelist+eax+2],10h     ;is sprite0 here?
        jz dl2
        cmp [striketime],0              ;already set?
        je dl2

        mov [linebase],offset vscreen+8 ;(not visible)
        call drawBG
        call [drawsprites]
dl2:
        ret
dl5:
        mov edi,[scanline]
        mov eax,[scanline]
        shl edi,8
        lea edi,[edi+eax*8+offset vscreen+8]
        mov [linebase],edi                      ;set vscreen ptr

        test [ctrl1],CR1_BG+CR1_OBJ     ;nothing to draw.. blank line
        jz dl3

        call drawBG
        test [ctrl1],CR1_BGCLIP
        jnz dl4
        mov edi,[linebase]
        mov dword ptr [edi],40404040h           ;clip BG
        mov dword ptr [edi+4],40404040h
dl4:
        call [drawsprites]

        cmp [palchange],0                       ;check for palette change
        je dl1
        cmp [scanline],8
        jb dl1
        cmp [scanline],231
        ja dl1
        mov edi,[linebase]
        mov ebp,-256
        xor eax,eax
        xor ebx,ebx
        xor ecx,ecx
        xor edx,edx
dl0:    mov al,[edi+ebp+256]                    ;remap to full nes palette
        mov bl,[edi+ebp+257]
        mov cl,[edi+ebp+258]
        mov dl,[edi+ebp+259]
        mov al,[vram+3f00h+eax-40h]
        mov bl,[vram+3f00h+ebx-40h]
        mov cl,[vram+3f00h+ecx-40h]
        mov dl,[vram+3f00h+edx-40h]
        mov [edi+ebp+256],al
        mov [edi+ebp+257],bl
        mov [edi+ebp+258],cl
        mov [edi+ebp+259],dl
        add ebp,4
        jnz dl0
dl1:
        ret
dl3:
        mov [bgskip],0          ;black line
        mov eax,0f0f0f0f0h
        mov ecx,256/32
dl6:    mov [edi],eax
        mov [edi+4],eax
        mov [edi+8],eax
        mov [edi+12],eax
        mov [edi+16],eax
        mov [edi+20],eax
        mov [edi+24],eax
        mov [edi+28],eax
        add edi,32
        dec ecx
        jnz dl6
        ret

        align 4

linebase        dd      ?
;----------------------------------------------------------------------------
drawBG:
;       in:
;               nothing
;       out:
;               ?
;----------------------------------------------------------------------------
        mov edi,[linebase]
        test [ctrl1],CR1_BG                     ;BG blanked?
        jz db2

        dec [bgskip]
        jns db98

        sub edi,[xoffset]                       ;edi=vscreen ptr
        mov esi,[vmaddr]
        mov ecx,[vmaddr]
        mov eax,esi
         mov ebx,ecx
        and esi,3ffh                            ;esi=name tbl offset
        and ecx,1fh
        and eax,0c00h
        xor ecx,1fh                             ;ecx=tile count
        shr eax,7
        push ecx                                ;save for later..
         and ebx,7000h
        push [maplist+eax+4]                    ;here's our name tables
        mov ebp,[maplist+eax]
         jz db10
        shr ebx,9
        mov [tilerow],ebx                       ;set tile row offset

        call db4
        pop ebp
        pop ecx
        xor ecx,31
        sub esi,32
db4:   ;- - - - - - - - - - - - -       ;single line
        mov ebp,[ebp]                           ;ebp=nametable base
        mov edx,ebp
        sub edx,offset vram+2000h
        shl edx,2
db0:
        mov ebx,offset bglatch
        movzx eax,byte ptr [ebp+esi]            ;eax=tile#
bg1hook:
        db 2 dup (?);call ebx                   ;(mapper 9)
        mov ebx,eax
        and eax,3fh
        shr ebx,6
        shl eax,6
        add eax,[bgchr_map+ebx*4]               ;eax=tile src
        add eax,[tilerow]

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax]
        mov [edi],ebx
        mov ebx,[attrib+edx+esi*4]
        add edi,8
        or ebx,[eax+4]
        inc esi
        mov [edi-4],ebx
        dec ecx
        jns db0
        ret
db10:  ;- - - - - - - - - - - - -       ;8 lines
        mov [bgskip],7
        call db11
        pop ebp
        pop ecx
        xor ecx,31
        sub esi,32
db11:
        mov ebp,[ebp]                           ;ebp=nametable base
        mov edx,ebp
        sub edx,offset vram+2000h
        shl edx,2
db12:
        mov ebx,offset bglatch
        movzx eax,byte ptr [ebp+esi]            ;eax=tile#
bg8hook:
        db 2 dup (?);call ebx                   ;(mapper 9)
        mov ebx,eax
        and eax,3fh
        shr ebx,6
        shl eax,6
        add eax,[bgchr_map+ebx*4]              ;eax=tile src

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*0]
        mov [edi+264*0],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*0]
        mov [edi+4+264*0],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*1]
        mov [edi+264*1],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*1]
        mov [edi+4+264*1],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*2]
        mov [edi+264*2],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*2]
        mov [edi+4+264*2],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*3]
        mov [edi+264*3],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*3]
        mov [edi+4+264*3],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*4]
        mov [edi+264*4],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*4]
        mov [edi+4+264*4],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*5]
        mov [edi+264*5],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*5]
        mov [edi+4+264*5],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*6]
        mov [edi+264*6],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*6]
        mov [edi+4+264*6],ebx

        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+8*7]
        mov [edi+264*7],ebx
        mov ebx,[attrib+edx+esi*4]
        or ebx,[eax+4+8*7]
        mov [edi+4+264*7],ebx

        inc esi
        add edi,8
        dec ecx
        jns db12
        ret
db2:   ;- - - - - - - - - - - - -               ;blank line
        dec [bgskip]
        mov eax,40404040h
        mov ecx,256/32
db3:    mov [edi],eax
        mov [edi+4],eax
        mov [edi+8],eax
        mov [edi+12],eax
        mov [edi+16],eax
        mov [edi+20],eax
        mov [edi+24],eax
        mov [edi+28],eax
        add edi,32
        dec ecx
        jnz db3
db98:
        ret

        align   4
tilerow dd      ?

maplist         dd      name0_map,name1_map
                dd      name1_map,name0_map
                dd      name2_map,name3_map
                dd      name3_map,name2_map
;----------------------------------------------------------------------------
checkstrike:;
;       in:
;               edx=sprite 0 tile ptr
;               edi=linebase
;       out:
;               ?
;----------------------------------------------------------------------------
        cmp [striketime],-1
        je ck5                                  ;continue if strike not set
        ret
ck5:
        movzx ebx,[oam+3]                       ;ebx=x
        xor eax,eax                             ;eax=sprite offset
        mov ecx,7                               ;ecx=countdown

        test [oam+2],OBJ_HFLIP
        jnz flip

ck4:    test byte ptr [edi+ebx],03h             ;scan 1 pixel at a time
        jz ck3
        test byte ptr [edx+eax],03h
        jnz ck1
ck3:    inc ebx
        inc eax
        dec cl
        jns ck4
        ret
ck1:
        trace tSTRIKE,bl
        mov eax,[striketbl+ebx*4]               ;lookup strike time
        mov [striketime],eax
        ret
flip:
        test byte ptr [edi+ebx],03h             ;scan 1 pixel at a time
        jz ck0
        test byte ptr [edx+ecx],03h             ;read sprite backwards
        jnz ck1
ck0:    inc ebx
        dec cl
        jns flip
        ret
;----------------------------------------------------------------------------
sortsprites:;
;       in:
;               nothing
;       out:
;               everything=?
;----------------------------------------------------------------------------
        mov esi,00100007h
        cmp [drawsprites],offset drawsprites8
        je ss4
        add esi,8
ss4:
        xor eax,eax
        mov edi,offset spritecount
        mov ecx,256/4
        rep stosd               ;clear [spritecount]

        xor edx,edx             ;edx=sprite#
        xor ecx,ecx             ;ecx=line index
ss2:    mov eax,dword ptr [oam+edx]     ;eax=sprite data
        cmp al,0eeh             ;Y out of range?
        ja ss3

        lea ebx,[eax+1]         ;line=Y+1
        and eax,0ffe3ff00h      ;remove Y and useless bits
        and ebx,0ffh            ;ebx=count offset
        or eax,esi              ;add Y offset and sprite0 flag
        and esi,0ffh            ;no more sprite0
        add ebx,esi
        mov ebp,ebx             ;ebp=list offset
        shl ebp,5
ss1:
        cmp [spritecount+ebx],7       ;line full?
        ja ss0
        mov cl,[spritecount+ebx]      ;index into list
        inc [spritecount+ebx]         ;inc sprite count
        mov [spritelist+ebp+ecx*4],eax     ;add sprite to this line
ss0:
        sub ebp,32
        dec bl
        dec al                  ;next line
        jns ss1
ss3:    add dl,4                ;next sprite
        jnz ss2

        mov [spritechange],0
        ret
;----------------------------------------------------------------------------
drawsprites8:;
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        test [ctrl1],CR1_OBJ            ;sprites blanked?
        jz ds99

        mov edi,[scanline]
        mov cl,[spritecount+edi]
        or cl,cl
        jz ds99                         ;nothing to draw, abort
        mov [tempcount],cl

        mov ecx,edi
        shl ecx,5
        add ecx,offset spritelist       ;ecx=sprite data ptr

        xor eax,eax                     ;clear priority mask
        xor ebx,ebx
        xor edx,edx
        mov esi,-1
        mov al,[ecx+3]
        mov bl,[ecx+7]
        mov dl,[ecx+11]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi
        mov dword ptr [spritemask+edx],esi
        mov dword ptr [spritemask+4+edx],esi
        mov al,[ecx+15]
        mov bl,[ecx+19]
        mov dl,[ecx+23]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi
        mov dword ptr [spritemask+edx],esi
        mov dword ptr [spritemask+4+edx],esi
        mov al,[ecx+27]
        mov bl,[ecx+31]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi

        test [ctrl1],CR1_OBJCLIP                ;clip left 8 pixels?
        jnz ds3
        mov dword ptr [spritemask],0fcfcfcfch
        mov dword ptr [spritemask+4],0fcfcfcfch
ds3:
        movzx ebp,byte ptr [ecx+2]      ;ebp=attrib

        movzx ebx,byte ptr [ecx]        ;ebx=tile offset
        test ebp,OBJ_VFLIP
        jz ds1
        xor ebx,7
ds1:    shl ebx,3

        mov edi,offset sprite8latch
        movzx eax,byte ptr [ecx+1]         ;tile#
sprite8hook:
        db 2 dup (?) ;call edi          ;(mapper 9)
        mov edx,eax
        shr eax,6
        and edx,3fh
        shl edx,6
        mov edi,[linebase]              ;edi=screen ptr
        add edx,[oamchr_map+eax*4]      ;edx=tile ptr

     test ebp,10h                      ;sprite 0?
     jz ds7
     pushad
     add edx,ebx
     xor ebx,ebx
     call checkstrike          ;check STRIKE
     popad
ds7:
        mov esi,ebp
        and ebp,3

        mov eax,[edx+ebx]
        and esi,60h
        mov ebx,[edx+ebx+4]
        or eax,[attrib_tbl+ebp*4+16]
        shr esi,3
        or ebx,[attrib_tbl+ebp*4+16]

        movzx edx,byte ptr [ecx+3]      ;edx=sprite x pos

        call [spriteXX+esi]

        add ecx,4
        dec [tempcount]
        jnz ds3
ds99:
        ret

                align   4
spriteXX        dd      sprite__,spriteB_,sprite_H,spriteBH
tempcount       db      ?
;----------------------------------------------------------------------------
drawsprites16:;
;       in:
;               ?
;       out:
;               ?
;----------------------------------------------------------------------------
        test [ctrl1],CR1_OBJ            ;sprites blanked?
        jz ds199

        mov edi,[scanline]
        mov cl,[spritecount+edi]
        or cl,cl
        jz ds199                        ;nothing to draw, abort
        mov [tempcount],cl

        mov ecx,edi
        shl ecx,5
        add ecx,offset spritelist       ;ecx=sprite data ptr

        xor eax,eax                     ;clear priority mask
        xor ebx,ebx
        xor edx,edx
        mov esi,-1
        mov al,[ecx+3]
        mov bl,[ecx+7]
        mov dl,[ecx+11]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi
        mov dword ptr [spritemask+edx],esi
        mov dword ptr [spritemask+4+edx],esi
        mov al,[ecx+15]
        mov bl,[ecx+19]
        mov dl,[ecx+23]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi
        mov dword ptr [spritemask+edx],esi
        mov dword ptr [spritemask+4+edx],esi
        mov al,[ecx+27]
        mov bl,[ecx+31]
        mov dword ptr [spritemask+eax],esi
        mov dword ptr [spritemask+4+eax],esi
        mov dword ptr [spritemask+ebx],esi
        mov dword ptr [spritemask+4+ebx],esi

        test [ctrl1],CR1_OBJCLIP                ;clip left 8 pixels?
        jnz ds13
        mov dword ptr [spritemask],0fcfcfcfch
        mov dword ptr [spritemask+4],0fcfcfcfch
ds13:
        movzx ebp,byte ptr [ecx+2]      ;ebp=attrib

        movzx ebx,byte ptr [ecx]        ;ebx=tile offset
        test ebp,OBJ_VFLIP
        jz ds11
        xor ebx,15
ds11:   shl ebx,3

        mov edi,offset sprite16latch
        movzx eax,byte ptr [ecx+1]         ;tile#
        ror al,1
sprite16hook:
        db 2 dup (?);call edi           ;for mapper 9
        mov edx,eax
        shr eax,5
        and edx,1fh
        shl edx,7
        mov edi,[linebase]              ;edi=screen ptr
        add edx,[chr_map+eax*4]         ;edx=tile ptr

     test ebp,10h                      ;sprite 0?
     jz ds17
     pushad
     add edx,ebx
     xor ebx,ebx
     call checkstrike          ;check STRIKE
     popad
ds17:
        mov esi,ebp
        and ebp,3

        mov eax,[edx+ebx]
        and esi,60h
        mov ebx,[edx+ebx+4]
        or eax,[attrib_tbl+ebp*4+16]
        shr esi,3
        or ebx,[attrib_tbl+ebp*4+16]

        movzx edx,byte ptr [ecx+3]      ;edx=sprite x

        call [spriteXX+esi]

        add ecx,4
        dec [tempcount]
        jnz ds13
ds199:
        ret
;----------------------------------------------------------------------------
sprite_H:;      draw sprite (H flip)
;----------------------------------------------------------------------------        
        bswap eax
        bswap ebx
        xchg eax,ebx
;----------------------------------------------------------------------------
sprite__:;      draw sprite (normal)
;----------------------------------------------------------------------------        
        and eax,dword ptr [spritemask+edx]
        and ebx,dword ptr [spritemask+edx+4]
        push ebx
        push eax

        test al,3
        jz __0
        mov [edi+edx+0],al
__0:    test ah,3
        jz __1
        mov [edi+edx+1],ah
__1:    shr eax,16
        test al,3
        jz __2
        mov [edi+edx+2],al
__2:    test ah,3
        jz __3
        mov [edi+edx+3],ah
__3:    test bl,3
        jz __4
        mov [edi+edx+4],bl
__4:    test bh,3
        jz __5
        mov [edi+edx+5],bh
__5:    shr ebx,16
        test bl,3
        jz __6
        mov [edi+edx+6],bl
__6:    test bh,3
        jz __7
        mov [edi+edx+7],bh
__7:
        pop eax
        pop ebx
        mov edi,eax
        mov ebp,ebx
        shr edi,1
        shr ebp,1
        or edi,eax
        or ebp,ebx
        and edi,01010101h
        and ebp,01010101h
        lea edi,[edi+edi*2]
        lea ebp,[ebp+ebp*2]
        xor dword ptr [spritemask+edx],edi
        xor dword ptr [spritemask+edx+4],ebp
        ret
;----------------------------------------------------------------------------
spriteBH:;      draw sprite (background+H flip)
;----------------------------------------------------------------------------        
        bswap eax
        bswap ebx
        xchg eax,ebx
;----------------------------------------------------------------------------
spriteB_:;      draw sprite (background)
;----------------------------------------------------------------------------        
        push ebx
        push eax
        test byte ptr [edi+edx+0],3
        jnz B_0
        mov [edi+edx+0],al
B_0:    test byte ptr [edi+edx+1],3
        jnz B_1
        mov [edi+edx+1],ah
B_1:    shr eax,16
        test byte ptr [edi+edx+2],3
        jnz B_2
        mov [edi+edx+2],al
B_2:    test byte ptr [edi+edx+3],3
        jnz B_3
        mov [edi+edx+3],ah
B_3:    test byte ptr [edi+edx+4],3
        jnz B_4
        mov [edi+edx+4],bl
B_4:    test byte ptr [edi+edx+5],3
        jnz B_6
        mov [edi+edx+5],bh
B_6:    shr ebx,16
        test byte ptr [edi+edx+6],3
        jnz B_7
        mov [edi+edx+6],bl
B_7:    test byte ptr [edi+edx+7],3
        jnz B_8
        mov [edi+edx+7],bh
B_8:
        pop eax
        pop ebx
        mov edi,eax
        mov ebp,ebx
        shr edi,1
        shr ebp,1
        or edi,eax
        or ebp,ebx
        and edi,01010101h
        and ebp,01010101h
        lea edi,[edi+edi*2]
        lea ebp,[ebp+ebp*2]
        xor dword ptr [spritemask+edx],edi
        xor dword ptr [spritemask+edx+4],ebp
        ret
;----------------------------------------------------------------------------
VRAM_pat:;     write to pattern table (0000-1FFF)
;----------------------------------------------------------------------------
        mov [vram+edi],al
        push ebx
        push ecx
        push esi

        mov ebx,edi
        mov esi,edi
        and edi,not 15
        and esi,not 8                           ;esi=src
        shl edi,2
        and ebx,7
        add edi,[chr_ptr]                       ;edi=dst
        shl ebx,3
        add edi,ebx

        xor eax,eax
        xor ebx,ebx
        mov al,[vram+esi]                       ;plane 1
        mov bl,[vram+esi]
        shr al,4
        and bl,0fh
        mov ecx,[bitexpand+eax*4]
        mov ebp,[bitexpand+ebx*4]
        mov al,[vram+8+esi]                     ;plane 2
        mov bl,[vram+8+esi]
        shr al,4
        and bl,0fh
        shr ecx,1
        shr ebp,1
        or ecx,[bitexpand+eax*4]
        or ebp,[bitexpand+ebx*4]
        mov [edi],ecx
        mov [edi+4],ebp

        pop esi
        pop ecx
        pop ebx
        ret

        align   4
bitexpand       dd      00000000h,02000000h,00020000h,02020000h
                dd      00000200h,02000200h,00020200h,02020200h
                dd      00000002h,02000002h,00020002h,02020002h
                dd      00000202h,02000202h,00020202h,02020202h
;----------------------------------------------------------------------------
unpack:;        unpack tiles
;       in:
;               ESI=src
;               EDI=dest
;               EDX=tile count
;       out:
;               EAX,EBX,ECX,EDX,ESI,EDI=?
;----------------------------------------------------------------------------
up1:
        mov ecx,8                               ;8 rows
up0:
        mov al,[esi]
        mov bl,[esi+8]

        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+0],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+1],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+2],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+3],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+4],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+5],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+6],bh
        xor bh,bh
        shl ebx,1
        shl al,1
        rcl bh,1
        mov [edi+7],bh

        add edi,8
        inc esi
        dec ecx
        jnz up0

        add esi,8
        dec edx
        jnz up1

        ret
;----------------------------------------------------------------------------
VRAM_name0:;    (2000-23ff)
;----------------------------------------------------------------------------
        and edi,3ffh
        mov ebp,[name0_map]
        mov [edi+ebp],al
        cmp edi,3c0h
        jae writeattrib
        ret
writeattrib:                                    ;(ppuload calls this too)
                                                ;in:
                                                ;       al=val
                                                ;       ebp=nameX_map
                                                ;       edi=(3c0-3ff)
                                                ;out:
                                                ;       eax,edi,ebp=?
        sub ebp,offset vram
        sub edi,3c0h
        and ebp,0c00h
        shr ebp,4
        add ebp,edi
        and edi,007h
        and ebp,0f8h
        shl edi,4
        shl ebp,6
        add edi,ebp

        mov ebp,eax
        and eax,3
        mov eax,[attrib_tbl+eax*4]
        mov [attrib+edi+00h],eax
        mov [attrib+edi+04h],eax
        mov [attrib+edi+80h],eax
        mov [attrib+edi+84h],eax
        mov eax,ebp
        shr eax,2
        and eax,3
        mov eax,[attrib_tbl+eax*4]
        mov [attrib+edi+08h],eax
        mov [attrib+edi+0ch],eax
        mov [attrib+edi+88h],eax
        mov [attrib+edi+8ch],eax
        mov eax,ebp
        shr eax,4
        and eax,3
        mov eax,[attrib_tbl+eax*4]
        mov [attrib+edi+100h],eax
        mov [attrib+edi+104h],eax
        mov [attrib+edi+180h],eax
        mov [attrib+edi+184h],eax
        shr ebp,6
        and ebp,3
        mov eax,[attrib_tbl+ebp*4]
        mov [attrib+edi+108h],eax
        mov [attrib+edi+10ch],eax
        mov [attrib+edi+188h],eax
        mov [attrib+edi+18ch],eax
        ret
;----------------------------------------------------------------------------
VRAM_name1:;    (2400-27ff)
;----------------------------------------------------------------------------
        and edi,3ffh
        mov ebp,[name1_map]
        cmp edi,3c0h
        mov [edi+ebp],al
        jae writeattrib
        ret
;----------------------------------------------------------------------------
VRAM_name2:;    (2800-2bff)
;----------------------------------------------------------------------------
        and edi,3ffh
        mov ebp,[name2_map]
        cmp edi,3c0h
        mov [edi+ebp],al
        jae writeattrib
        ret
;----------------------------------------------------------------------------
VRAM_name3:;    (2c00-2fff)
;----------------------------------------------------------------------------
        and edi,3ffh
        mov ebp,[name3_map]
        cmp edi,3c0h
        mov [edi+ebp],al
        jae writeattrib
        ret
;----------------------------------------------------------------------------
VRAM_pal:;      write to VRAM palette area ($3F00-$3F1F)
;----------------------------------------------------------------------------
        cmp edi,3f00h                           ;check out of range write
        jb VRAM_name3                           ;($3C00-$3EFF)

        and edi,1fh
        and al,3fh                              ;only colors 0-63 are valid

        test edi,03h                            ;deal with transparent
        mov ah,al
        jz vp0

        xor ah,[vram+3f00h+edi]                 ;check for new value
        mov [vram+3f00h+edi],al                 ;store value
        or [palchange],ah
        ret
vp0:
        xor ah,[vram+3f00h+edi]                 ;check for new value
        and edi,0fh
        or [palchange],ah
        mov [vram+3f00h+edi],al
        mov [vram+3f10h+edi],al
        ret
;----------------------------------------------------------------------------
VRAM_empty:;    write to void VRAM address
;----------------------------------------------------------------------------
;if DEBUG
;        or [int_flags],DEBUG2
;        mov [debugmsg],offset msg45
;endif
        ret
;----------------------------------------------------------------------------
setnespal:;        set entire NES palette
;       in:
;               nothing
;       out:
;               ?
;----------------------------------------------------------------------------
        mov edx,3c8h
        mov al,40h
        out dx,al
        inc edx

        mov ebp,[palmap]
        mov esi,offset palette
        mov edi,offset pal

        test [ctrl1],CR1_MONO
        jz snp0
        movzx edi,[ctrl1]
        shr edi,5
        mov cl,3
        mov edi,[mono+edi*4]
snp0:
        xor ebx,ebx
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+01h]
        call edi
        mov bl,[vram+3f00h+02h]
        call edi
        mov bl,[vram+3f00h+03h]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+05h]
        call edi
        mov bl,[vram+3f00h+06h]
        call edi
        mov bl,[vram+3f00h+07h]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+09h]
        call edi
        mov bl,[vram+3f00h+0Ah]
        call edi
        mov bl,[vram+3f00h+0Bh]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+0Dh]
        call edi
        mov bl,[vram+3f00h+0Eh]
        call edi
        mov bl,[vram+3f00h+0Fh]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+11h]
        call edi
        mov bl,[vram+3f00h+12h]
        call edi
        mov bl,[vram+3f00h+13h]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+15h]
        call edi
        mov bl,[vram+3f00h+16h]
        call edi
        mov bl,[vram+3f00h+17h]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+19h]
        call edi
        mov bl,[vram+3f00h+1Ah]
        call edi
        mov bl,[vram+3f00h+1Bh]
        call edi
        mov bl,[vram+3f00h+00h]
        call edi
        mov bl,[vram+3f00h+1Dh]
        call edi
        mov bl,[vram+3f00h+1Eh]
        call edi
        mov bl,[vram+3f00h+1Fh]
        jmp edi
pal:
        mov bl,[ebx+ebp]
        mov eax,[esi+ebx*4]
        out dx,al
        shr eax,8
        out dx,al
        shr eax,8
        out dx,al
        ret

        out dx,al
        out dx,al
        out dx,al
        ret
___:
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        out dx,al
        out dx,al
        ret
__R:
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        xor al,al
        out dx,al
        out dx,al
        ret
_G_:
        xor al,al
        out dx,al
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        xor al,al
        out dx,al
        ret
_GR:
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        out dx,al
        xor al,al
        out dx,al
        ret
B__:
        xor al,al
        out dx,al
        out dx,al
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        ret
B_R:
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        xor ah,ah
        out dx,al
        xchg al,ah
        out dx,al
        xchg al,ah
        out dx,al
        ret
BG_:
        xor al,al
        out dx,al
        mov bl,[ebx+ebp]
        mov al,[esi+ebx*4]
        add al,[esi+ebx*4+1]
        xor ah,ah
        add al,[esi+ebx*4+2]
        div cl
        out dx,al
        out dx,al
        ret
BGR:
        mov al,3fh
        out dx,al
        out dx,al
        out dx,al
        ret

mono    dd      ___,__R,_G_,_GR,B__,B_R,BG_,BGR
;----------------------------------------------------------------------------
        align   4

attrib_tbl      dd      40404040h,44444444h,48484848h,4c4c4c4ch
                dd      50505050h,54545454h,58585858h,5c5c5c5ch

PPU_read_tbl    dd      empty_R                 ;$2000
                dd      empty_R                 ;$2001
                dd      stat_R                  ;$2002
                dd      empty_R                 ;$2003 
                dd      oamdata_R               ;$2004
                dd      empty_R                 ;$2005
                dd      empty_R                 ;$2006
                dd      vmdata_R                ;$2007

PPU_write_tbl   dd      ctrl0_W                 ;$2000
                dd      ctrl1_W                 ;$2001
                dd      void                    ;$2002
                dd      oamaddr_W               ;$2003
                dd      oamdata_W               ;$2004
                dd      bgscroll_W              ;$2005
                dd      vmaddr_W                ;$2006
                dd      vmdata_W                ;$2007

VRAM_write_tbl  dd      ? ;VRAM_pat             ;$0000 
                dd      ? ;VRAM_pat             ;$0400
                dd      ? ;VRAM_pat             ;$0800
                dd      ? ;VRAM_pat             ;$0c00
                dd      ? ;VRAM_pat             ;$1000
                dd      ? ;VRAM_pat             ;$1400
                dd      ? ;VRAM_pat             ;$1800
                dd      ? ;VRAM_pat             ;$1c00
                dd      VRAM_name0              ;$2000
                dd      VRAM_name1              ;$2400
                dd      VRAM_name2              ;$2800
                dd      VRAM_name3              ;$2c00
                dd      VRAM_name0              ;$3000
                dd      VRAM_name1              ;$3400
                dd      VRAM_name2              ;$3800
                dd      VRAM_pal                ;$3c00

vram_map        dd      vram+0000h              ;$0000
                dd      vram+0400h              ;$0400
                dd      vram+0800h              ;$0800
                dd      vram+0c00h              ;$0c00
                dd      vram+1000h              ;$1000
                dd      vram+1400h              ;$1400
                dd      vram+1800h              ;$1800
                dd      vram+1c00h              ;$1c00
name0_map       dd      vram+2000h              ;$2000
name1_map       dd      vram+2000h              ;$2400
name2_map       dd      vram+2400h              ;$2800
name3_map       dd      vram+2400h              ;$2c00
                dd      vram+3000h              ;$3000
                dd      vram+3400h              ;$3400
                dd      vram+3800h              ;$3800
                dd      vram+3c00h              ;$3c00

drawsprites     dd      drawsprites8

chr_map         dd      8 dup (?)
bgchr_map       dd      4 dup (?)
oamchr_map      dd      4 dup (?)

ctrl0           db      0
ctrl1           db      0
stat            db      0

                align   4

oamaddr         dd      0
vmainc          dd      1
toggle          dd      0                       ;0/1: select L/H (2005,2006)

vmaddr          dd      0
vmaddr2         dd      0
xoffset         dd      0

readreg         db      ?                       ;temporary reg for vram read

                align 4

bgskip          dd      0                       ;lines we can skip BG drawing
xsame           dd      0                       ;no change in x scroll

striketime      dd      ?                       ;when to set STRIKE flag
diptimeout      dd      ?                       ;when to hide dipswitches
recordblink     dd      ?                       ;when to blink record light
blink           db      ?                       ;on/off
palchange       db      0                       ;set on palette change
spritechange    db      0                       ;set on sprite data change

render          db      0                       ;screen render enable
;----------------------------------------------------------------------------        
code    ends
        end
