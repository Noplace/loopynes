        .386p
code    segment public use32
        assume cs:code,ds:code

        include equates.h
        include empty.h
        include macros.h
        include 6502.h
include debug.h
        public GGon
        public GGoff
        public GGadd
        public GGdecode
        public GGchars
        public GGcodes
        public flush2
;----------------------------------------------------------------------------
flush2:;        (from map00)
;----------------------------------------------------------------------------
        call GGoff
        ;.
;----------------------------------------------------------------------------
GGon:;          patch rom with code list
;               don't call again without calling GGoff first, .original will be lost)
;       out:
;               eax,ebp,edi=?
;----------------------------------------------------------------------------
        mov ebp,[GGcodes]                         ;ebp=code count+ptr
        shl ebp,4
        jnz on4
        ret
on4:
        push esi
on1:
        mov esi,[codelist+ebp-16+address]
        mov edi,[codelist+ebp-16+address]
        shr edi,13
        add esi,[memmap+edi*4]                  ;esi=rom addr
        cmp [codelist+ebp-16+ctype],0
        mov al,[esi]                            ;keep old val
        je on2
        cmp al,[codelist+ebp-16+compare]
        jne on3
on2:    mov ah,[codelist+ebp-16+replace]
        mov [esi],ah
on3:    mov [codelist+ebp-16+original],al
        mov [codelist+ebp-16+romptr],esi
        sub ebp,16
        jnz on1
        pop esi
        ret
;----------------------------------------------------------------------------
GGoff:;         restore rom (call only after using GGon)
;       out:
;               eax,ebp,edi=?
;----------------------------------------------------------------------------
        mov ah,byte ptr [GGcodes]
        mov ebp,offset codelist
        or ah,ah
        jnz off1
        ret
off1:
        mov edi,[ebp+romptr]
        mov al,[ebp+original]
        mov [edi],al
        add ebp,16
        dec ah
        jnz off1
        ret
;----------------------------------------------------------------------------
GGadd:;
;       in:
;               esi=code string ptr
;----------------------------------------------------------------------------
        cmp [GGcodes],MAXCODES
        je add2
        call GGdecode
        jnc add1
add2:   ret
add1:
        push eax
        call GGoff
        mov esi,[GGcodes]
        inc [GGcodes]
        pop eax
        shl esi,4
        add esi,offset codelist

        mov edi,eax
        and edi,7fffh
        or edi,8000h
        mov [esi+address],edi
        shr eax,16
        mov [esi+replace],al
        mov [esi+compare],ah
        setc [esi+ctype]
        jmp GGon
;----------------------------------------------------------------------------
GGdecode:;
;       in:
;               esi=code string ptr
;       out:
;               ...=?
;               eax=code
;                       bit 0-14=addr
;                       bit 15=type (0=6 letter)
;                       bit 16-23=data
;                       bit 24-31=compare val
;               CF set on bad code
;----------------------------------------------------------------------------
        xor edx,edx                     ;edx=gg code
        xor ebx,ebx                     ;ebx=code index
gg0:    xor ecx,ecx                     ;ecx=GGchars index
gg1:    mov al,[esi+ebx]
        cmp [GGchars+ecx],al
        jne gg2
        shl edx,4                       ;translate GG code to hex
        or dl,cl
        inc ebx
        jmp gg0
gg2:    or al,al
        jz gg3                          ;EOL
        inc cl
        cmp cl,16
        jb gg1
        stc
        ret                             ;invalid code
gg3:
        cmp bl,8                        ;8 letter code?
        je gg4
        shl edx,8                       ;add space for 6 letter code
        bt edx,11
        jnc gg4
        bts edx,3                       ;copy compare bit 3 to data bit 3
gg4:
        xor esi,esi
gg5:    mov cl,[shift+esi]
        ror edx,cl
        mov cl,[shift+esi+1]
        shrd eax,edx,cl
        add esi,2
        cmp esi,13*2
        jb gg5

        and ax,not 8000h                ;set bit 15 for 8 letter code
        cmp bl,6
        je gg6
        or ax,8000h
gg6:
        clc
        ret

GGchars db 'APZLGITYEOXUKSVN'           ;GG->hex translate tbl

shift   db 12,3, 7,4, 8,1, 13,3, 7,5    ;addr
        db 13,3, 7,1, 21,3, 7,1         ;data
        db 5,3, 7,1, 21,3, 7,1          ;compare
;----------------------------------------------------------------------------
        align 4

GGcodes dd 0

ggcode struc
        address dd ?                    ;cpu addr
        original db ?                   ;original value
        compare db ?                    ;compare value
        replace db ?                    ;GG replacement value
        ctype db ?                      ;0=always  1=compare
        romptr dd ?                     ;rom address
        dd ?
ends

;----------------------------------------------------------------------------
code    ends
        end
