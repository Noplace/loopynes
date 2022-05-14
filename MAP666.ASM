        .386p
code    segment public use32
        assume cs:code,ds:code

        include 6502.h
        include map00.h
        include empty.h
        include file.h
        include memory.h
        include ppu.h
        include data.h
        include equates.h
        include debug.h
        include kb.h
        include io.h

        public mapperinit666
;----------------------------------------------------------------------------
mapperinit666:;
;----------------------------------------------------------------------------
        mov eax,[ram_ptr]               ;map $8000-$ffff to ram
        mov [memmap+4*4],eax
        mov [memmap+5*4],eax
        mov [memmap+6*4],eax
        mov [memmap+7*4],eax
        mov [read_tbl+4*4],offset sram_R
        mov [read_tbl+5*4],offset sram_R
        mov [read_tbl+6*4],offset sram_R
        mov [read_tbl+7*4],offset sram_R

        cmp dword ptr fs:[5070h],0      ;setup bankswitch data if missing
        jne mi0
        cmp dword ptr fs:[5074h],0
        jne mi0
        mov ecx,[romsize]                       ;ecx=banks
        shr ecx,12
        mov al,fs:[5009h]
        and eax,70h                             ;eax=starting bank
        shr eax,4
        add eax,5070h
        xor ebx,ebx
mi1:    mov fs:[eax+ebx],bl
        inc ebx
        dec ecx
        jnz mi1
mi0:
        mov [read_tbl+2*4],offset r4000
        mov [write_tbl+2*4],offset w4000

        mov dword ptr [banks],-1
        mov dword ptr [banks+4],-1

        mov esi,offset nsf_rom          ;load rom to 5080+
        mov edi,[ram_ptr]
        add edi,5080h
        mov ecx,nsf_romsize/4
        rep movsd

        mov fs:[0fffch],50805080h       ;setup interrupt vectors

        ret
;----------------------------------------------------------------------------
r4000:;
;----------------------------------------------------------------------------
        cmp edi,4020h
        jb IO_R
        jmp sram_R
;----------------------------------------------------------------------------
w4000:;
;----------------------------------------------------------------------------
        cmp edi,4018h                   ;I/O write
        jb IO_W
        cmp edi,5ff8h                   ;bad write
        jb empty_W

      push esi
      push ecx
        and edi,7
        shl edi,12
        add edi,8000h
        add edi,[ram_ptr]

        and eax,0ffh
        shl eax,12
        add eax,[rom_ptr]
        mov esi,eax

        mov ecx,1000h/4
        rep movsd

        mov fs:[0fffch],50805080h       ;setup interrupt vectors
      pop ecx
      pop esi

        ret
;----------------------------------------------------------------------------
        align 4

banks   db 8 dup (?)

        align 4

nsf_rom label dword
include nsfrom.txt
nsf_romsize equ $-nsf_rom
;----------------------------------------------------------------------------
code    ends
        end
