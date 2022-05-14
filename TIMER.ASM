        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include 6502.h

        public  timer_init
        public  timer_exit

;----------------------------------------------------------------------------
timer_init:;    install interrupt handlers
;----------------------------------------------------------------------------
        mov eax,0200h                   ;
        mov bl,8
        int 31h
        mov [cs_],cx
        mov [ip_],dx

        mov eax,0205h
        mov bl,8
        mov cx,cs
        mov edx,offset int8
        int 31h                         ;set pmode vector

        mov al,34h                      ;set rate to 60Hz
        out 43h,al
        mov al,0aeh                     ;(1234ddh/60) and 0ffh
        out 40h,al
        mov al,4dh                      ;(1234ddh/60)/256
        out 40h,al

        ret
;----------------------------------------------------------------------------
timer_exit:;    restore old real mode int vector
;----------------------------------------------------------------------------
        mov al,34h                      ;restore old timer
        out 43h,al
        xor al,al 
        out 40h,al
        out 40h,al
        ret
;----------------------------------------------------------------------------
int8:;          timer interrupt handler
;----------------------------------------------------------------------------
        pushad
        push ds
        mov ax,word ptr cs:[data_sel]
        mov ds,ax                       ;load data selector

        inc [ticks]                     ;update tick counter
        add [timeout],4dae0000h         ;100000000h*(18.2/60)
        jc pm0

        mov al,20h
        out 20h,al                      ;send EOI to ISR
        pop ds
        popad
        iretd
pm0:
        push es                         ;call BIOS handler
        mov es,ax
        mov edi,offset regstruc
        mov eax,0302h
        xor bh,bh
        xor ecx,ecx
        int 31h
        pop es
        pop ds
        popad
        iretd
;----------------------------------------------------------------------------
                align   4

timeout         dd      0               ;when to call BIOS handler

regstruc:                               ;real mode register data structure
edi_            dd      ?
esi_            dd      ?
ebp_            dd      ?
                dd      ?
ebx_            dd      ?
edx_            dd      ?
ecx_            dd      ?
eax_            dd      ?
flags_          dw      ?
es_             dw      ?
ds_             dw      ?
fs_             dw      ?
gs_             dw      ?
ip_             dw      ?
cs_             dw      ?
sp_             dw      0
ss_             dw      0

;----------------------------------------------------------------------------
code    ends
        end
