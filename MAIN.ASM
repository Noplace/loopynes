        .386p
code    segment public use32
        assume cs:code,ds:code

        include equates.h
        include file.h
        include data.h
        include kb.h
        include vga.h
        include 6502.h
        include empty.h
        include mouse.h
        include sb.h
        include timer.h
        include config.h
        include debug.h
        include io.h
        include gui.h
        
        public  error2
        public  _error
        public  _exit

;----------------------------------------------------------------------------
main:;          program entry point
;----------------------------------------------------------------------------
        mov eax,0901h                   ;enable virtual interrupts
        int 31h

        mov eax,-1
        mov edx,offset the_end
        int 21h                         ;resize segment
        jc error2
        mov esp,edx

        mov [data_sel],ds               ;save DS selector

        mov eax,0006h
        mov bx,ds
        int 31h
        mov [code_addr],edx
        mov word ptr [code_addr+2],cx   ;save base address

        mov eax,0006h
        mov bx,es
        int 31h
        shl ecx,16
        mov cx,dx
        sub ecx,[code_addr]
        mov [psp_ptr],ecx               ;save PSP ptr

        mov eax,0006h
        mov bx,es:[2ch]
        int 31h
        shl ecx,16
        mov cx,dx
        sub ecx,[code_addr]
        mov [env_ptr],ecx               ;save environment ptr

        mov es,[data_sel]               ;ES=DS

        mov ah,47h                      ;get initial path
        mov dl,0
        mov [startdir],'\'
        mov esi,offset startdir+1
        int 21h
        jnc main7
        mov [startdir],0
main7:
        mov eax,000a0000h               ;setup VGA pointers
        sub eax,[code_addr]
        mov [gfx_ptr],eax
        mov eax,000b8000h
        sub eax,[code_addr]
        mov [text_ptr],eax

        mov edx,offset ram
        add edx,0000000ffh
        and edx,0ffffff00h              ;256 byte align (for 6502 stack pointer)
        mov [ram_ptr],edx

        mov ax,0ah                      ;make nes ram descriptor
        mov bx,cs
        int 31h
        jc error2
        mov [ram_sel],eax
        mov ebx,eax
        mov eax,8
        xor ecx,ecx
        mov edx,0ffffh
        int 31h                         ;set limit to 64k
        jc error2
        mov ebx,[ram_sel]
        mov eax,7
        mov ecx,[ram_ptr]
        add ecx,[code_addr]
        mov edx,ecx
        shr ecx,16
        int 31h                         ;set base address
        jc error2
        mov fs,bx                       ;load FS with selector

        xor eax,eax                     ;clear screens
        mov ecx,264*240/4
        mov edi,offset vscreen
        rep stosd
        mov ecx,264*240/4
        mov edi,offset vscreen2
        rep stosd

        mov ax,0100h                    ;allocate 64k dos mem
        mov bx,1000h
        int 31h
        jc error2
        and eax,0ffffh
        shl eax,4
        sub eax,[code_addr]
        mov [dos_ptr],eax

        call LFNtest                    ;check LFN
        call kb_init                    ;init keyboard
        call mouseinit                  ;init mouse
        call sb_init                    ;init sound
        call timer_init                 ;init 60Hz timer

        mov al,'v'                      ;check -v# param
        call param
        jc main1
        cmp al,VIDMODES
        jae main1
        mov byte ptr [vidmode],al
main1:

ife DEBUG
        call gfxmode
endif
        mov edx,[psp_ptr]           ;get filename from commandline:
        add edx,80h
        cmp byte ptr [edx],0
        je main9
main4:  inc edx                         ;scan for front of filename
        cmp byte ptr [edx],' '
        je main4

        lea esi,[edx-1]                 ;scan for end of filename
main6:  inc esi
        mov al,[esi]
        cmp al,0dh                              ;stop at CR
        je main3
        cmp al,'-'                              ;or " -*"
        jne main6
        cmp byte ptr [esi-1],' '
        jne main6
        cmp byte ptr [esi+1],' '
        je main6
main3:
        cmp edx,esi
        je main9
        dec esi
        cmp byte ptr [esi],' '
        je main3
        mov byte ptr [esi+1],0          ;terminate filename
        inc esi                         ;edx=front, esi=back

        sub esi,edx
main8:  cmp byte ptr [esi+edx-1],'\'    ;look for dir in filename
        je main11
        dec esi
        jnz main8
        jmp main10
main11:                                 ;move to rom dir
        push dword ptr [esi+edx]
        mov byte ptr [esi+edx],0
        call cd
        pop dword ptr [esi+edx]
main10:
        lea edi,[esi+edx]

if DEBUG
main9:
        call loadcart                   ;load cart
        jc _error
        mov [int_flags],DEBUG2          ;debugger entry flag
        mov [vgamode],1                 ;reset screen
        mov [debugmsg],offset msg41
        jmp cpu_init
else
        call loadcart                   ;load cart
        jnc cpu_init
main9:
        call startgui
        jmp main9
endif
;----------------------------------------------------------------------------
param:;         look for cmdline param
;       in:
;               al=
;       out:
;               on success:
;                       cf=0
;                       al=#
;----------------------------------------------------------------------------
        mov esi,[psp_ptr]
        add esi,80h
p0:     inc esi                         ;scan for " -*"
        cmp byte ptr [esi],0dh
        je p9
        cmp word ptr [esi],"- "
        jne p0
        cmp byte ptr [esi+2],' '
        je p0

p1:     inc esi                         ;scan for AL
        cmp byte ptr [esi],0dh
        je p9
        cmp [esi],al
        jne p1

        mov al,[esi+1]                  ;only handles single digits for now
        sub al,'0'
        clc
        ret
p9:
        stc
        ret
;----------------------------------------------------------------------------
shutdown:;      shutdown everything
;----------------------------------------------------------------------------
        call vga_exit
        call free
        call mouseexit
        call sb_exit
        call timer_exit
        ret
;----------------------------------------------------------------------------
error2:;        generic error
;----------------------------------------------------------------------------
        mov al,27h
;----------------------------------------------------------------------------
_error:;        shutdown everything, display error string, and exit to DOS.
;
;       in:
;               AL=error code
;
;----------------------------------------------------------------------------
        push eax
        call shutdown
        pop ecx

        and ecx,03fh
        mov edx,[errtbl+ecx*4]          ;get ptr to error string
        mov ah,09h
        int 21h

        jmp _realexit
;----------------------------------------------------------------------------
_exit:;         shutdown everything and exit to DOS
;----------------------------------------------------------------------------
        call closerom                   ;unload ROM
        call saveconfig                 ;save config
        call shutdown

        mov ah,3bh                      ;restore original dir
        mov edx,offset startdir
        int 21h
_realexit:
        mov eax,4c00h
        int 21h                         ;exit to DOS
;----------------------------------------------------------------------------
code    ends
end     main
