        .486p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include main.h
        include equates.h
        include ppu.h
        include 6502.h
        include empty.h
        include debug.h
        include kb.h
        include input.h
        include ppu.h
        include memory.h
        include io.h
        include mappers.h
        include sb.h
        include config.h
        include ggenie.h
        include macros.h

        public free
        public LFNtest
        public findfirst
        public findnext
        public findclose
        public f_create
        public f_open
        public f_read
        public f_write
        public f_seek
        public f_close
        public loadcart
        public closerom
        public fileend
        public cartflags
        public romsize
        public rommask
        public vromsize
        public chrmask
        public mapper
        public cd
        public savedir
        public restoredir
        public exedir
        public savepcx
        public saveSNSS
        public loadSNSS
;-----------------------------------------------------------------------------
malloc:;        allocate extended memory (frees old mem)
;
;       in:
;               ebx=block size
;       out:
;               ebx=block ptr
;               eax,ecx,esi,edi=?
;-----------------------------------------------------------------------------
        call free
        jc error2
        mov eax,0501h
        mov ecx,ebx
        shr ebx,16
        int 31h
        jc error2                       ;quit on error
        mov [memhandle],edi
        mov word ptr [memhandle+2],si   ;save handle
        shl ebx,16
        mov bx,cx                       ;ebx=linear addr
        sub ebx,[code_addr]             ;change to offset
        ret
;-----------------------------------------------------------------------------
free:;          free memory block
;       in:
;               nothing
;       out:
;               eax,esi,edi=?
;       on error:
;               CF=1
;-----------------------------------------------------------------------------
        cmp [memhandle],-1
        je free0                        ;skip if handle unused
        mov eax,0502h
        mov edi,[memhandle]
        mov si,word ptr [memhandle+2]
        int 31h                         ;free mem
        mov [memhandle],-1              ;reset handle
free0:  ret
;----------------------------------------------------------------------------
LFNtest:;       check if LFN is supported
;----------------------------------------------------------------------------
        mov [_eax],716ch                ;(try something screwy and see
        mov [_ebx],0                    ;what error we get)
        mov [_ecx],0
        mov [_edx],1
        mov edi,[dos_ptr]
        mov byte ptr [edi],0
        add edi,[code_addr]
        shr edi,4
        mov [_ds],di
        mov [_esi],0

        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode int

        jc error2                       ;exit on DPMI error
        cmp [_eax],7100h
        je lt9
        mov [lfn],1
lt9:
	ret
;-----------------------------------------------------------------------------
findfirst:;
;       in:
;               cl=allowable attrib mask
;               ch=required attrib mask
;               edx=filename
;       out:
;               eax=?
;               esi=filename
;               cf=1 on error (nothing found)
;-----------------------------------------------------------------------------
        cmp [lfn],0
        jne lff0

        mov [reqmask],ch        ;--- normal findfirst
        xor ch,ch
        mov ah,4eh
        int 21h
        jc ff0
        mov esi,[psp_ptr]
        mov al,[reqmask]                ;check req mask, normal find doesn't
        xor al,[esi+80h+15h]
        and al,[reqmask]
        jnz findnext                    ;no good, keep looking
        add esi,80h+1eh
        clc
ff0:
        ret
lff0:                           ;--- LFN findfirst
        mov [_eax],714eh
        mov [_ecx],ecx                  ;attribs
        mov [_esi],0                    ;date/time format

        push ebx
        push ecx
        push edi

        mov edi,[dos_ptr]               ;copy filename to dos area
        xor ecx,ecx
lff1:   mov al,[edx+ecx]
        mov [edi+ecx],al
        inc ecx
        or al,al
        jnz lff1
        
        add edi,[code_addr]
        shr edi,4
        mov [_ds],di                    ;[ds:dx]=filename ptr
        mov [_es],di
        mov [_edx],0
        mov [_edi],100h                 ;[es:di]=finddata record

        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode interrupt

        pop edi
        pop ecx
        pop ebx

        jc error2                       ;exit on DPMI error
        mov eax,[_eax]
        mov [findhandle],eax
        mov esi,[dos_ptr]
        add esi,12ch                    ;esi=filename ptr
        bt [_flags],0                   ;check carry
	ret

findhandle      dd      ?
reqmask         db      ?
;-----------------------------------------------------------------------------
findnext:;
;       in:
;               ?
;       out:
;               eax=?
;               esi=filename
;               cf=1 on error (nothing found)
;-----------------------------------------------------------------------------
        cmp [lfn],0
        jne lfn0
        mov esi,[psp_ptr]
fn1:
        mov ah,4fh              ;--- normal findnext
        int 21h
        jc fn0
        mov al,[reqmask]                ;check req mask
        xor al,[esi+80h+15h]
        and al,[reqmask]
        jnz fn1                         ;no good, keep looking
        add esi,80h+1eh
        clc
fn0:
        ret
lfn0:                           ;--- LFN findnext
        mov [_eax],714fh
        mov [_esi],0
        mov eax,[findhandle]
        mov [_ebx],eax

        push ebx
        push ecx
        push edi

        mov edi,[dos_ptr]
        add edi,[code_addr]
        shr edi,4
        mov [_es],di
        mov [_edi],0                    ;[es:di]=finddata record

        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode interrupt

        pop edi
        pop ecx
        pop ebx

        jc error2                       ;exit on DPMI error
        mov esi,[dos_ptr]
        add esi,2ch                     ;esi=filename ptr
        bt [_flags],0                   ;check carry
	ret
;----------------------------------------------------------------------------
findclose:;     call after using findfirst/findnext
;
;       out:
;               nothing
;----------------------------------------------------------------------------
        cmp [lfn],0                     ;only needed with LFN
        je fcl9

        push eax
        push ebx
        push ecx
        push edi

        mov [_eax],71a1h
        mov eax,[findhandle]
        mov [_ebx],eax
        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode interrupt

        pop edi
        pop ecx
        pop ebx
        pop eax

        jc error2                       ;exit on DPMI error
        test [_flags],1
        jnz error2                      ;hum.. something's fuct
fcl9:   ret
;----------------------------------------------------------------------------
f_create:;      Create file
;
;       in:
;               edx=filename
;       out:
;               bx=handle
;               ?=?
;       if failed:
;               cf set
;               al=dos error code
;----------------------------------------------------------------------------
        cmp [lfn],1
        je fcr0

        mov ah,3ch
        xor ecx,ecx
        int 21h
        mov ebx,eax
        ret
fcr0:
        mov esi,edx
        mov bx,0001h
        mov dx,0012h
        jmp LFNopen
;----------------------------------------------------------------------------
f_open:;        Open file
;
;       in:
;               CL: access mode
;                   0=read only
;                   1=write only
;                   2=read/write
;               EDX=filename
;       out:
;               bx=handle
;               ?=?
;       if failed:
;               CF set
;               AL=dos error code
;
;----------------------------------------------------------------------------
        cmp [lfn],1
        je fo9
fo0:
        mov ah,3dh
        mov al,cl
        int 21h
        mov ebx,eax
	ret
fo9:
        mov esi,edx
        mov edx,1
        mov ebx,ecx
        and ebx,3

LFNopen:;-------------------------------ESI=name, BX=access mode, DX=action

        mov [_eax],716ch                ;LFN open/create
        mov [_ebx],ebx                  ;access mode
        mov [_ecx],0                    ;normal attribs
        mov [_edx],edx                  ;action

        mov edi,[dos_ptr]               ;copy filename to dos area
        xor ecx,ecx
lfo0:   mov al,[esi+ecx]
        mov [edi+ecx],al
        inc ecx
        or al,al
        jnz lfo0
        
        add edi,[code_addr]
        shr edi,4
        mov [_ds],di                    ;[ds:si]=filename ptr
        mov [_esi],0

        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode interrupt

        jc error2                       ;exit on DPMI error
        bt [_flags],0                   ;check carry
        mov ebx,[_eax]
	ret
;----------------------------------------------------------------------------
f_read:;        read from file
;
;       in:
;               bx=handle
;               ECX=bytes to read
;               EDX=dst
;       out:
;               eax=?
;       if failed:
;               CF set
;               AL=error code
;                       08h: file access error
;----------------------------------------------------------------------------
        mov ah,3fh
        int 21h
        mov al,08h
        ret
;----------------------------------------------------------------------------
f_write:;       write to file
;
;       in:
;               bx=handle
;               ecx=bytes to write
;               edx=src
;       out:
;               eax=?
;       if failed:
;               CF set
;               AL=error code
;                       0Dh: write error
;
;----------------------------------------------------------------------------
        mov ah,40h
        int 21h
        mov al,0dh
        ret
;----------------------------------------------------------------------------
f_seek:;        seek to position in file
;
;       in:
;               AL=offset code:
;                       00h=offset from start of file
;                       01h=signed offset from current filepos
;                       02h=signed offset from end of file
;               bx=handle
;               EDX=file offset
;       out:
;               EDX=file pointer
;               EAX,ECX=?
;       if failed:
;               CF set
;               AL=08h - file access error
;                 
;----------------------------------------------------------------------------
        mov ah,42h
        mov ecx,edx
        shr ecx,16                      ;CX:DX=pointer
        int 21h                         ;set pointer
        jc fs0

        shl edx,16
        mov dx,ax                       ;edx=new file pointer
        clc

fs0:    mov al,08h
        ret
;----------------------------------------------------------------------------
f_close:;       close file
;       in:
;               bx=handle
;       out:
;               eax=?
;----------------------------------------------------------------------------
        mov ah,3eh
        int 21h
        ret
;----------------------------------------------------------------------------
exedir:;        change to exe dir
;       out:
;               eax,ebx,ecx,edx,edi=?
;----------------------------------------------------------------------------
        mov edx,[env_ptr]
        xor eax,eax
ed0:    inc edx
        cmp [edx],ax
        jne ed0
        add edx,4                       ;edx=exe name

        xor ecx,ecx
ed1:    inc ecx
        cmp [edx+ecx],al
        jne ed1
ed2:    dec ecx
        cmp byte ptr [edx+ecx],'\'
        jne ed2

        mov [edx+ecx],al
        push ecx
        call cd
        pop ecx
        mov byte ptr [edx+ecx],'\'
        ret
;----------------------------------------------------------------------------
savedir:;       put current dir in tempdir
;       out:
;               eax,edx,esi=?
;----------------------------------------------------------------------------
        mov ah,47h                      ;get initial path
        mov dl,0
        mov [tempdir],'\'
        mov esi,offset tempdir+1
        int 21h
        jnc svd0
        mov [tempdir],0
svd0:   ret
;----------------------------------------------------------------------------
restoredir:;
;----------------------------------------------------------------------------
        mov edx,offset tempdir
;----------------------------------------------------------------------------
cd:;            change dir
;       in:
;               edx=path
;       out:
;               eax,ebx,ecx,edi=?
;               cf=status
;----------------------------------------------------------------------------
        cmp [lfn],0
        jne lcd0

        mov ah,3bh
        int 21h
        ret
lcd0:                           ;LFN chdir ---
        mov edi,[dos_ptr]               ;copy path to dos mem
        xor ecx,ecx
lcd1:   mov al,[edx+ecx]
        mov [edi+ecx],al
        inc ecx
        or al,al
        jnz lcd1
        
        add edi,[code_addr]
        shr edi,4
        mov [_ds],di                    ;[ds:dx]=filename ptr
        mov [_edx],0
        mov [_eax],713bh
        mov ax,0300h
        mov bx,0021h
        xor ecx,ecx
        mov edi,offset reg_struc
        int 31h                         ;simulate real mode interrupt
        jc error2                       ;exit on DPMI error
        bt [_flags],0                   ;check carry
	ret
;----------------------------------------------------------------------------
loadcart:;
;
;       in:
;               edi=filename
;       on error:
;               CF set
;               AL=error code
;                       09h: generic load error
;                       0ah: empty filename
;----------------------------------------------------------------------------
        push edi
        xor eax,eax                     ;clear screens
        mov ecx,264*240/4
        mov edi,offset vscreen
        rep stosd
        mov ecx,264*240/4
        mov edi,offset vscreen2
        rep stosd
        pop edi

        mov al,0ah
        cmp byte ptr [edi],0
        je lc99

        mov esi,offset filename         ;copy name to [filename]
lc0:    mov al,[edi]
        mov [esi],al
        inc esi
        inc edi
        or al,al
        jnz lc0

        cmp byte ptr [esi-2],'.'        ;*.
        je lc3
        cmp byte ptr [esi-3],'.'        ;*.?
        je lc2
        cmp byte ptr [esi-4],'.'        ;*.??        
        je lc1
        cmp byte ptr [esi-5],'.'        ;*.???
        je lc4

        mov byte ptr [esi-1],'.'        ;*
        mov byte ptr [esi],0
        add esi,4
lc4:    dec esi
lc1:    dec esi
lc2:    dec esi
lc3:    dec esi
        mov [fileend],esi
;-----------------
        mov [GGcodes],0                 ;first things first.. reset ggenie

        mov edx,offset filename
        xor cl,cl
        call f_open                     ;open file
        jnc lc20

        mov edi,[fileend]               ;error-
        mov dword ptr [edi],'SEN'       ;try adding .NES extension
        mov edx,offset filename
        xor cl,cl
        call f_open
        jnc lc20

        mov edi,[fileend]               ;error-
        mov dword ptr [edi],'FSN'       ;try adding .NSF extension
        mov edx,offset filename
        xor cl,cl
        call f_open
        jc lc98
lc20:
        mov [handle],ebx                ;keep handle

        mov ecx,16                      ;read ines header
        mov edx,offset tmp
        call f_read
        jc lc97

        mov esi,offset tmp              ;get cart info:
        cmp dword ptr [esi],'MSEN'              ;'NESM'?
        je loadnsf
        cmp dword ptr [esi],1a53454eh           ;'NES^Z'?
        jne lc97
        xor eax,eax
        mov al,[esi+4]                          ;get ROM size
        shl eax,14
        jz lc97                                 ;no rom?? exit
        mov [romsize],eax
        dec eax
        bsr ecx,eax
        mov eax,0fffffffeh
        shl eax,cl
        not eax
        mov [rommask],eax                       ;set rom size mask
        xor eax,eax
        mov al,[esi+5]                          ;get VROM size
        shl eax,13
        mov [vromsize],eax
        mov eax,[esi+6]                         ;get flags
        mov ecx,eax                             ;get mapper
        shl al,4
        shr eax,4
        mov [cartflags],eax
        test dword ptr [esi+8],-1               ;check for garbage in header
     jz lc15
     mov dword ptr [esi+8],0
     mov dword ptr [esi+12],0
       ; jnz lc6
       ; test dword ptr [esi+12],-1
       ; jz lc15
lc6:    and ecx,0f0h
lc15:   and ecx,0f0f0h
        shr ch,4
        shr ecx,4
        mov [mapper],ecx

        mov [palmap],offset nes                 ;reset palette map

        mov ebx,[vromsize]              ;mem alloc:
        or ebx,ebx
        jnz lc5
        mov ebx,8192                            ;need at least 1 chr page
lc5:    shl ebx,2
         dec ebx
         bsr ecx,ebx
         mov eax,0fffffffeh
         shl eax,cl
         not eax
         mov [chrmask],eax                      ;set chr mask
         inc ebx
        add ebx,[vromsize]
        add ebx,[romsize]
        call malloc                             ;allocate romsize+vromsize+vromsize*4
        mov [rom_ptr],ebx
        add ebx,[romsize]
        mov [vrom_ptr],offset vram              ;point vrom to vram if no vrom exists
        cmp [vromsize],0
        je lc7
        mov [vrom_ptr],ebx
lc7:    add ebx,[vromsize]
        mov [chr_ptr],ebx

        mov ebx,[handle]                ;duh

        xor eax,eax                     ;clear nes ram
        mov ecx,10000h/4
        mov edi,[ram_ptr]
        rep stosd

        test [cartflags],TRAINER        ;trainer here?
        jz lc8
        mov ecx,512
        mov edx,[ram_ptr]
        add edx,7000h
        call f_read                             ;read trainer into ram
        jc lc97
lc8:
        mov ecx,[romsize]
        mov edx,[rom_ptr]
        call f_read                     ;read ROM
        jc lc97

        mov eax,offset VRAM_pat         ;(CHR writing ok)
        cmp [vromsize],0
        je lc9                          ;skip if no VROM

        mov ecx,[vromsize]                      ;read VROM
        mov edx,[vrom_ptr]
        call f_read
        jc lc97

        mov esi,[vrom_ptr]                      ;unpack tileset
        mov edi,[chr_ptr]
        mov edx,[vromsize]
        shr edx,4
        call unpack

        mov eax,offset VRAM_empty       ;(no CHR writing)
lc9: ;(!!! loadnsf jumps here)
        mov edi,offset VRAM_write_tbl   ;set CHR write access
        mov ecx,8
        rep stosd

        mov ebx,[handle]
        call f_close

        call loadsram

        call kb_clear                           ;reset keyboard

        mov [scanlinehook],offset void          ;clear hooks
        mov [mapperreset],offset void
        mov eax,0db87h
        mov word ptr [bg1hook],ax
        mov word ptr [bg8hook],ax
        mov word ptr [sprite8hook],ax
        mov word ptr [sprite16hook],ax

        mov [serial0mask],0                            ;reset VS switches
        mov [serial1mask],0

        mov [read_tbl+00h],offset ram_R         ;reset to standard mem access
        mov [read_tbl+04h],offset PPU_R
        mov [read_tbl+08h],offset IO_R
        mov [read_tbl+0ch],offset sram_R
        mov [read_tbl+10h],offset rom_R
        mov [read_tbl+14h],offset rom_R
        mov [read_tbl+18h],offset rom_R
        mov [read_tbl+1ch],offset rom_R
        mov [write_tbl+00h],offset ram_W
        mov [write_tbl+04h],offset PPU_W
        mov [write_tbl+08h],offset IO_W
        mov [write_tbl+0ch],offset sram_W
        mov [write_tbl+10h],offset empty_W
        mov [write_tbl+14h],offset empty_W
        mov [write_tbl+18h],offset empty_W
        mov [write_tbl+1ch],offset empty_W

        mov eax,[ram_ptr]               ;map $0000-$7fff to ram
        mov [memmap+0*4],eax
        mov [memmap+1*4],eax
        mov [memmap+2*4],eax
        mov [memmap+3*4],eax

        xor eax,eax                      ;clear VRAM
        mov ecx,4000h/4
        mov edi,offset vram
        rep stosd
;        mov [vram+3f70h],70h            ;map 70h to black
;        mov [vram+3ff0h],70h            ;(for palette change with blanked BG)

        mov ecx,-32*32*4*4              ;clear attrib
        mov eax,40404040h
lc13:   mov [attrib+32*32*4*4+ecx],eax
        add ecx,4
        jnz lc13

        mov eax,-1                      ;clear OAM
        mov ecx,64
        mov edi,offset oam
        rep stosd

        cmp [vromsize],0                ;clear chr if no vrom
        jne lc14
        mov esi,offset vram
        mov edi,[chr_ptr]
        mov edx,512
        call unpack
lc14:
        mov eax,[chr_ptr]               ;map chr (0000-1fff) to first bank
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

        xor esi,esi                     ;do something with PC so encodePC in mapperinit won't screw up
        mov [lastbank],esi

        xor eax,eax                     ;clear mapper data
        mov ecx,MAPDATASIZE/4
        mov edi,offset mapperdata
        rep stosd

        mov al,0bh
        mov ebx,[mapper]
        mov esi,offset mapperinit-8
lc10:   add esi,8
        cmp dword ptr [esi],-1
        je lc99
        cmp [esi+4],ebx
        jne lc10
        call [esi]                      ;call mapperinitXX

        clc
        ret
;----------------------------
lc97:   call f_close                    ;close file first
lc98:   mov al,09h                      ;exit with error code 09h
lc99:   stc                             ;exit with error
        ret
;----------------------------------------------------------------------------
loadnsf:;
;----------------------------------------------------------------------------
        xor eax,eax                     ;clear nes ram
        mov ecx,10000h/4
        mov edi,[ram_ptr]
        rep stosd

        xor eax,eax
        xor edx,edx
        call f_seek
        mov ecx,80h                     ;read NSF header into nes $5000
        mov edx,[ram_ptr]
        add edx,5000h
        call f_read
        jc lc97

        mov al,2                                ;get filesize
        mov edx,0
        call f_seek
        sub edx,80h
        mov eax,fs:[5008h]                      ;set romsize
        and eax,0fffh
        add eax,edx
        add eax,0fffh
        and eax,not 0fffh
        mov [romsize],eax
        mov al,0
        mov edx,80h
        call f_seek

        mov [vromsize],0                ;set cart info:
        mov [chrmask],7fffh
        mov [rommask],-1
        mov [cartflags],0
        mov [mapper],666

        mov [palmap],offset nes         ;set palette

        mov ebx,8192*4                  ;mem alloc:
        add ebx,[romsize]
        call malloc
        mov [rom_ptr],ebx
        add ebx,[romsize]
        mov [vrom_ptr],offset vram
        mov [chr_ptr],ebx

        mov ebx,[handle]
        mov ecx,[romsize]
        mov edx,fs:[5008h]
        and edx,0fffh
        add edx,[rom_ptr]
        call f_read                     ;read ROM
        jc lc97

        mov eax,offset VRAM_pat
        jmp lc9
;----------------------------------------------------------------------------
closerom:;              unload rom and save stuff
;----------------------------------------------------------------------------
        test [cartflags],SRAM
        jz clr20

        mov esi,[ram_ptr]                       ;scan sram..
        add esi,6000h
        mov ecx,1ffch
        xor eax,eax
clr2:   or eax,[esi+ecx]
        sub ecx,4
        jns clr2

        or eax,eax
        jz clr20                                ;skip if sram not used

        mov edi,[fileend]                       ;create file
        mov dword ptr [edi],'VAS'
        mov edx,offset filename
        call f_create
        jc clr20

        mov ecx,2000h
        mov edx,[ram_ptr]
        add edx,6000h
        call f_write
        call f_close
clr20:
        ret
;----------------------------------------------------------------------------
loadsram:;
;----------------------------------------------------------------------------
        mov edi,[fileend]               ;open SRAM
        mov dword ptr [edi],'VAS'
        mov edx,offset filename
        xor cl,cl
        call f_open
        jc lsr0

        mov ecx,2000h                   ;load SRAM
        mov edx,[ram_ptr]
        add edx,6000h
        call f_read
        or [cartflags],SRAM
        call f_close
lsr0:
        ret
;----------------------------------------------------------------------------
savepcx:;
;----------------------------------------------------------------------------
        mov edx,[fileend]
        mov [edx],'XCP'
        mov edx,offset filename
        call f_create
        jc error2

        mov ecx,128
        mov edx,offset pcxhead
        call f_write
        jc _error

        push ebx                        ;keep handle

        mov esi,offset vscreen+264*8+8
        mov edi,offset tmp
        mov ebp,offset vram+3f00h-40h
        xor eax,eax                     ;eax=color
        mov edx,224                     ;edx=line count
sp1:    mov ecx,256                     ;ecx=pixel count
        xor bl,bl                       ;bl=run count
sp2:    mov al,[esi]
        inc esi
        cmp al,64                       ;al=color# or index#?
        jb sp9
        test al,3                       ;transparent color?
        jnz sp3
        mov al,40h
sp3:    mov al,[eax+ebp]                ;translate palette index to color#
sp9:    call putpix
        dec ecx
        jnz sp2
        call pp0                        ;finish off line
        add esi,8
        dec edx
        jnz sp1

        mov byte ptr [edi],0ch
        inc edi

        xor ecx,ecx                     ;copy palette (0-63)
        xor eax,eax
        mov ebx,[palmap]
        mov esi,offset palette
sp7:    mov al,[ebx+ecx]
        mov edx,[esi+eax*4]
        shl edx,2
        mov [edi],edx
        add edi,3
        inc ecx
        cmp ecx,64
        jb sp7

        xor eax,eax                     ;clear palette (64-255)
        mov ecx,((256-64)*3)/4
sp8:    mov [edi],eax
        add edi,4
        dec ecx
        jnz sp8
        mov dword ptr [edi-4],0ffffff00h        ;last color is white

        pop ebx                         ;get handle

        sub edi,offset tmp
        mov ecx,edi
        mov edx,offset tmp
        call f_write
        call f_close
        ret
putpix:
        cmp bl,3fh
        je pp0
        cmp bl,0
        je pp3
        cmp al,bh
        je pp3
pp0:    cmp bh,0c0h
        jae pp1
        cmp bl,2
        jb pp2
pp1:    or bl,0c0h
        mov [edi],bl
        inc edi
pp2:    mov [edi],bh
        inc edi
        xor bl,bl
pp3:    inc bl
        mov bh,al
        ret

pcxhead db 10,5,1,8                ;256x224 pcx header
        dw 0,0,255,223
        dw 300,300
        db 48 dup (0)
        db 0,1
        dw 256,1,0,0
        db 54 dup (0)
;----------------------------------------------------------------------------
saveSNSS:;
;       in:
;               al=state# (0-3)
;----------------------------------------------------------------------------
        mov edi,[fileend]
        add al,'0'
        mov byte ptr [edi],'S'                  ;*.SS#
        mov byte ptr [edi+1],'S'
        mov byte ptr [edi+2],al
        mov byte ptr [edi+3],0

        mov edx,offset filename                 ;new file..
        call f_create
        jc sss99
        mov [handle],ebx
;- - - - - - - -
        mov ecx,8                               ;blank header for now
        mov edx,offset tmp
        call f_write
        mov [blocks],0                                  ;& reset counter
;- - - - - - - -
        mov eax,'BASR'
        mov ebx,1
        call blockstart

        mov eax,[_P_A]                          ;6502
        mov ebx,[_X_Y]
        mov ecx,[_S]
        mov edx,[_PC]
        mov [edi],al                            ;A
        mov [edi+1],bh                          ;X
        mov [edi+2],bl                          ;Y
        mov [edi+3],ah                          ;P
        mov [edi+4],cl                          ;S
        mov [edi+5],dh                          ;PC
        mov [edi+6],dl
        add edi,7

        mov al,[ctrl0]                          ;CR0
        mov ah,byte ptr [vmaddr2+1]
        and eax,0cfch
        shr ah,2
        or al,ah
        stosb

        mov al,[ctrl1]                          ;CR1
        stosb

        mov ecx,800h/4                          ;ram
        mov esi,[ram_ptr]
        rep movsd

        mov ecx,100h/4                          ;OAM
        mov esi,offset oam
        rep movsd

        mov ecx,1000h/4                         ;NT
        mov esi,offset vram+2000h
        rep movsd

        mov ecx,32/4                            ;palette
        mov esi,offset vram+3f00h
        rep movsd

        mov ecx,3                               ;mirror
sss0:   mov eax,[name0_map+ecx*4]
        sub eax,offset vram+2000h
        shr eax,10
        mov [edi+ecx],al
        dec ecx
        jns sss0
        add edi,4

        mov eax,[vmaddr]                        ;vmaddr
        and eax,3fffh
        xchg al,ah
        stosw
        mov al,byte ptr [oamaddr]               ;oamaddr
        stosb

        mov al,byte ptr [vmaddr2]               ;bg x scroll
        shl al,3
        or al,byte ptr [xoffset]
        stosb

        mov eax,[vmaddr2]                       ;bg y scroll
        and eax,73e0h
        shr eax,2
        shr ah,2
        or al,ah
        stosb

        ;[toggle]
        ;[readreg]
        ;[vmaddr2]

        call blockend
;- - - - - - - -
        cmp [vromsize],0                        ;chr ram?
        jne sss20

        mov eax,'VRAM'
        mov ebx,1
        call blockstart

        mov ecx,2000h
        mov esi,offset vram
        rep movsb

        call blockend
sss20:
;- - - - - - - -
        mov eax,'SRAM'
        mov ebx,1
        call blockstart

        mov byte ptr [edi],1                    ;sram enabled flag
        inc edi

        mov esi,[ram_ptr]                       ;copy sram & compare
        add esi,6000h
        xor ecx,ecx
        xor ebx,ebx
sss31:  mov eax,[esi+ecx*4]
        stosd
        or ebx,eax
        inc ecx
        cmp ecx,2000h/4
        jb sss31

        or ebx,ebx                              ;sram unused?
        jz sss30
        call blockend
sss30:
;- - - - - - - -
        cmp [mapper],0                          ;dont need to save mapper 0
        je sss19

        mov eax,'MPRD'
        mov ebx,1
        call blockstart

        xor ecx,ecx                             ;store rom mapping
        mov edx,8000h
        sub edx,[rom_ptr]
sss10:  mov eax,[memmap+4*4+ecx*4]
        add eax,edx
        shr eax,13 ;$2000
        xchg al,ah
        stosw
        add edx,2000h
        inc ecx
        cmp ecx,4
        jb sss10

        xor ecx,ecx                             ;store chr mapping
sss11:  mov eax,[chr_map+ecx*4]
        sub eax,[chr_ptr]
        shr eax,12 ;$400*4
        xchg al,ah
        stosw
        inc ecx
        cmp ecx,8
        jb sss11

        mov ecx,MAPDATASIZE                     ;mapper data
        mov esi,offset mapperdata
        rep movsb

        call blockend
sss19:
;- - - - - - - -
sss97:
        xor al,al
        xor edx,edx
        mov ebx,[handle]
        call f_seek
        jc sss98
        mov ecx,8
        mov edx,offset SNSSheader
        call f_write                            ;write header
sss98:
        call f_close
sss99:
        ret
;---------------
blockstart:                                     ;(eax=sig, ebx=version)
        mov edi,offset tmp
        bswap eax
        bswap ebx
        mov [edi],eax
        mov [edi+4],ebx
        add edi,12
        ret
blockend:                                       ;(edi=end of data)
        mov edx,offset tmp
        sub edi,edx
        mov ecx,edi                             ;ecx=blocksize+header
        sub edi,12                              ;edi=blocksize
        bswap edi
        mov dword ptr [tmp+8],edi               ;set size in block header
        mov ebx,[handle]
        inc [blocks]
        jmp f_write
;----------------------------------------------------------------------------
loadSNSS:;
;       in:
;               al=state# (0-3)
;----------------------------------------------------------------------------
        mov edi,[fileend]
        add al,'0'
        mov byte ptr [edi],'S'          ;*.SS#
        mov byte ptr [edi+1],'S'
        mov byte ptr [edi+2],al
        mov byte ptr [edi+3],0

        mov edx,offset filename         ;open file,
        xor cl,cl
        call f_open
        jc lss0                         ;quit on error
        mov [handle],ebx

        mov ecx,8                       ;read header
        mov edx,offset tmp
        call f_read
        cmp dword ptr [tmp],'SSNS'
        jne lss1                        ;abort on bad header
        mov al,[tmp+7]
        mov [blocks],al                 ;got our block count

        call GGoff                      ;game genie reset
lss3:                            ;read loop:
        cmp [blocks],0
        je lss2

        dec [blocks]
        mov ebx,[handle]
        mov ecx,12                      ;read block head
        mov edx,offset tmp
        call f_read
        jc lss2

        mov edi,dword ptr [tmp]                   ;block sig
        mov ecx,dword ptr [tmp+8]                 ;block size
        bswap ecx
      ;(check for valid size)
        mov edx,offset tmp
        call f_read                     ;read block
        jc lss2

        mov edx,offset loadlist
lss4:   cmp [edx],edi                   ;scan for known block type
        je lss5
        add edx,8
        cmp edx,offset loadend
        jne lss4
lss5:   mov esi,offset tmp              ;call loader with data in [tmp],
        call [edx+4]                            ;esi=tmp
        jmp lss3                                ;ecx=size
lss2:                            ;all done
        call GGon                       ;game genie restore
lss1:
        call f_close
lss0:
        ret
;-------------------
loadBASR:
        mov al,[esi]                            ;A
        mov bh,[esi+1]                          ;X
        mov bl,[esi+2]                          ;Y
        mov ah,[esi+3]                          ;P
        mov ecx,[ram_ptr]
        add ecx,100h
        mov cl,[esi+4]                          ;S
        movzx edx,word ptr [esi+5]              ;PC
        xchg dl,dh
        mov [_P_A],eax
        mov [_X_Y],ebx
        mov [_S],ecx
        mov [_PC],edx
        add esi,7

        push esi                                ;this makes restore6502 work
        mov esi,[_PC]
        setlastbank
        pop esi

        lodsb                                   ;CR0
        call ctrl0_W2                           ;(skip trace,etc)
        lodsb                                   ;CR1
        mov [ctrl1],al

        mov ecx,800h/4                          ;ram
        mov edi,[ram_ptr]
        rep movsd

        mov ecx,100h/4                          ;oam
        mov edi,offset oam
        rep movsd
        mov [spritechange],-1                   ;flag new sprites

        mov ecx,1000h/4                         ;NT
        mov edi,offset vram+2000h
        rep movsd
                
        mov cl,0                                ;unpack attrib
        mov ebx,offset vram+2000h
lss11:  mov edx,3c0h
lss12:  mov ebp,ebx
        mov edi,edx
        mov al,[ebx+edx]
        call writeattrib
        inc edx
        cmp edx,400h
        jb lss12
        add ebx,400h
        inc cl
        cmp cl,4
        jb lss11

        mov ecx,32/4                            ;palette
        mov edi,offset vram+3f00h
        rep movsd
        mov [palchange],-1                      ;flag new palette

        mov ecx,3                               ;mirror
lss10:  movzx eax,byte ptr [esi+ecx]
        shl eax,10 ;$400
        add eax,offset vram+2000h
        mov [name0_map+ecx*4],eax
        dec ecx
        jns lss10
        add esi,4

        lodsw
        xchg al,ah
        mov word ptr [vmaddr],ax                ;vmaddr
        lodsb
        mov byte ptr [oamaddr],al               ;oamaddr

        lodsb                                   ;x,y scroll
        call xscroll_w
        lodsb
        call yscroll_w

;        mov [toggle],0                          ;toggle reset

        ret
;-------------------
loadVRAM:
        mov ecx,2000h                           ;copy chr
        mov edi,offset vram
        rep movsb

        mov esi,offset vram                     ;unpack chr
        mov edi,[chr_ptr]
        mov edx,512
        call unpack

        ret
;-------------------
loadSRAM:
        inc esi         ;useless flag
        mov ecx,2000h
        mov edi,[ram_ptr]
        add edi,6000h
        rep movsb
        ret
;-------------------
loadMPRD:                                       ;set rom mapping
        xor ebx,ebx      ;(dont mess up block size in ecx)
        mov edx,[rom_ptr]
        sub edx,8000h
lss20:  xor eax,eax
        lodsw
        xchg al,ah
        shl eax,13 ;$2000
        add eax,edx
        mov [memmap+4*4+ebx*4],eax
        sub edx,2000h
        inc ebx
        cmp ebx,4
        jb lss20

        xor ebx,ebx                             ;set chr mapping
lss21:  xor eax,eax
        lodsw
        xchg al,ah
        shl eax,12 ;$400*4
        add eax,[chr_ptr]
        mov [chr_map+ebx*4],eax
        inc ebx
        cmp ebx,8
        jb lss21
        call newchrmap

        add ecx,offset tmp
        sub ecx,esi
        mov edi,offset mapperdata
        rep movsb

        ret
;----------------------------------------------------------------------------
        align   4

loadlist        dd 'RSAB',loadBASR
                dd 'MARV',loadVRAM
                dd 'MARS',loadSRAM
                dd 'DRPM',loadMPRD
loadend         dd -1,void

SNSSheader      db      'SNSS',0,0,0
blocks          db      ?

memhandle       dd      -1                      ;memory block handle
fileend         dd      ?                       ;points to end of filename (after the '.')

romsize         dd      0                       ;ROM size, in bytes (not including trainer)
rommask         dd      0                       ;romsize-1
vromsize        dd      0                       ;VROM size, in bytes
chrmask         dd      0                       ;[chr_ptr] size-1
mapper          dd      0                       ;mapper type
cartflags       dd      0                       ;misc flags

lfn             db      0                       ;long filenames supported

handle          dd      ?                       ;temp file handle

;----------------------------------------------------------------------------
code    ends
	end
