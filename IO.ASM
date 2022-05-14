;----------------------------------------------------------------------------
; miscellaneous NES I/O ($40xx)
;----------------------------------------------------------------------------
        .386p
code    segment public use32
        assume cs:code,ds:code

        include memory.h
        include data.h
        include equates.h
        include 6502.h
        include debug.h
        include ppu.h
        include empty.h
        include input.h
        include sb.h
        include kb.h

        public IO_R
        public IO_W
        public io_read_tbl
        public io_write_tbl
        public ioreset
;----------------------------------------------------------------------------
IO_R:;          I/O read
;----------------------------------------------------------------------------
cmp edi,4020h ;VS
je void
        test edi,00001fe0h                      ;check for out of range read
        jnz empty_R
        jmp [io_read_tbl+edi*4-4000h*4]
;----------------------------------------------------------------------------
IO_W:;          I/O write
;----------------------------------------------------------------------------
cmp edi,4020h ;VS
je void
        test edi,00001fe0h                      ;check for out of range write
        jnz empty_W
        jmp [io_write_tbl+edi*4-4000h*4]
;----------------------------------------------------------------------------
ioreset:;       called on CPU reset
;----------------------------------------------------------------------------
        ret
;----------------------------------------------------------------------------
dma_W:;    (4014)       sprite DMA transfer
;----------------------------------------------------------------------------        
        trace tOAMDMAw,al

        mov [spritechange],1
        sub [cycles],514
if DEBUG
        cmp al,80h                              ;check for dma from rom
        jb dw0
        test [oamaddr],07h
        jz dw0
        or [int_flags],DEBUG2
        mov [debugmsg],offset msg47
    dw0:
endif
        push ecx
        and eax,0ffh
        mov edi,[ram_ptr]
        shl eax,8
        mov ebp,offset oam
        add edi,eax
        xor ecx,ecx
sd0:    mov eax,[edi+ecx]
        mov [ebp+ecx],eax
        add cl,4
        jnz sd0
        pop ecx
        ret
;----------------------------------------------------------------------------

                align   4

io_read_tbl     dd      empty_R                 ;$4000:
                dd      empty_R                 ;$4001:
                dd      empty_R                 ;$4002:
                dd      empty_R                 ;$4003: 
                dd      empty_R                 ;$4004:
                dd      empty_R                 ;$4005:
                dd      empty_R                 ;$4006:
                dd      empty_R                 ;$4007:
                dd      empty_R                 ;$4008:
                dd      empty_R                 ;$4009:
                dd      empty_R                 ;$400A:
                dd      empty_R                 ;$400B:
                dd      empty_R                 ;$400C:
                dd      empty_R                 ;$400D:
                dd      empty_R                 ;$400E:
                dd      empty_R                 ;$400F:
                dd      empty_R                 ;$4010:
                dd      empty_R                 ;$4011:
                dd      empty_R                 ;$4012:
                dd      empty_R                 ;$4013: 
                dd      empty_R                 ;$4014:
                dd      void                    ;$4015:
                dd      joy0_R                  ;$4016: controller 1
                dd      joy1_R                  ;$4017: controller 2
                dd      empty_R                 ;$4018:
                dd      empty_R                 ;$4019:
                dd      empty_R                 ;$401A:
                dd      empty_R                 ;$401B:
                dd      empty_R                 ;$401C:
                dd      empty_R                 ;$401D:
                dd      empty_R                 ;$401E:
                dd      empty_R                 ;$401F:

io_write_tbl    dd      void                    ;$4000: Sound
                dd      void                    ;$4001: Sound
                dd      void                    ;$4002: Sound
                dd      void                    ;$4003: Sound
                dd      void                    ;$4004: Sound
                dd      void                    ;$4005: Sound
                dd      void                    ;$4006: Sound
                dd      void                    ;$4007: Sound
                dd      void                    ;$4008: Sound
                dd      void                    ;$4009: Sound
                dd      void                    ;$400A: Sound
                dd      void                    ;$400B: Sound
                dd      void                    ;$400C: Sound
                dd      void                    ;$400D: Sound
                dd      void                    ;$400E: Sound
                dd      void                    ;$400F: Sound
                dd      void                    ;$4010: Sound
                dd      void                    ;$4011: Sound
                dd      void                    ;$4012: Sound
                dd      void                    ;$4013: Sound
                dd      dma_W                   ;$4014: Sprite DMA transfer
                dd      void                    ;$4015: Sound
                dd      joy0_W                  ;$4016: Joypad 0 write
                dd      joy1_W                  ;$4017: Joypad 1 write??
                dd      empty_W                 ;$4018:
                dd      empty_W                 ;$4019:
                dd      empty_W                 ;$401A:
                dd      empty_W                 ;$401B:
                dd      empty_W                 ;$401C:
                dd      empty_W                 ;$401D:
                dd      empty_W                 ;$401E:
                dd      empty_W                 ;$401F:
;----------------------------------------------------------------------------
code    ends
        end
