        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include equates.h
        include io.h
        include empty.h
        include debug.h
        include 6502.h
        include file.h
        include config.h
        include ppu.h

include debug.h
include kb.h
        public sb_init
        public sb_exit
        public sb_pause
        public sb_resume
        public wavrecord
        public wavhandle
        public soundreset
        public mixer
        public soundmask
        public changevol
;----------------------------------------------------------------------------
sb_init:;       initialize SB
;
;       if failed:
;               CF set
;----------------------------------------------------------------------------
        mov esi,[env_ptr]               ;find BLASTER environment
        mov eax,'SALB'
        mov ebx,'=RET'

si0:    cmp word ptr [esi],0000h
        je si99
        cmp [esi],eax
        jne si1
        cmp [esi+4],ebx
        je si2
si1:    inc esi
        jmp si0
si2:                                    ;found BLASTER=
        xor eax,eax
        mov al,[esi+10]                 ;get base port
        sub al,'0'
        shl al,4
        add eax,200h
        mov [sb_base],eax
        add al,12                       ;setup port vars..
        mov [sb_write],eax
        add al,2
        mov [sb_data],eax
        mov [sb_irqack],eax

        xor eax,eax
        mov al,[esi+14]                 ;get IRQ
        mov bl,[esi+15]
        sub al,'0'
        cmp bl,' '
        je si3
        sub bl,'0'-10
        mov al,bl
        inc esi
si3:    mov bl,[IMRmask+eax]            ;get IMR mask
        mov [sb_imr],bl
        add al,8                        ;change IRQ to interrupt
        cmp al,16
        jb si4
        add al,60h
        mov [sb_isr],0a0h
si4:    mov [sb_int],al

        mov al,[esi+17]                 ;get DMA channel (8bit)
        and al,3
        mov [sb_dma8],al
        mov [sb_dma16],al

        mov al,[esi+20]                 ;get DMA (16bit)
        cmp byte ptr [esi+19],'H'
        jne si5
        and al,3
        mov [sb_dma16],al
si5:
        call reset_sb                   ;reset SB
        jc si99

        call get_dsp                    ;get DSP version
        mov [sb_dsp],ah

        mov al,0d1h                     ;speaker on
        call write_dsp
                                        ;setup interrupt handler:
        mov edx,[sb_isr]                        ;disable interrupt
        inc dl
        in al,dx
        or al,[sb_imr]
        out dx,al

        mov eax,0205h                           ;set pmode vector
        mov bl,[sb_int]
        mov cx,cs
        mov edx,offset blasterint
        int 31h

        inc [sb_installed]

        mov edx,[sb_isr]                        ;enable interrupt
        mov bl,[sb_imr]
        inc dl
        not bl
        in al,dx
        and al,bl
        out dx,al

        mov [io_read_tbl+15h*4],offset snd15r   ;setup port access
        mov [io_write_tbl+00h*4],offset ch1w
        mov [io_write_tbl+01h*4],offset ch1w
        mov [io_write_tbl+02h*4],offset ch1w
        mov [io_write_tbl+03h*4],offset ch1w
        mov [io_write_tbl+04h*4],offset ch2w
        mov [io_write_tbl+05h*4],offset ch2w
        mov [io_write_tbl+06h*4],offset ch2w
        mov [io_write_tbl+07h*4],offset ch2w
        mov [io_write_tbl+08h*4],offset ch3w
        mov [io_write_tbl+09h*4],offset ch3w
        mov [io_write_tbl+0ah*4],offset ch3w
        mov [io_write_tbl+0bh*4],offset ch3w
        mov [io_write_tbl+0ch*4],offset ch4w
        mov [io_write_tbl+0dh*4],offset ch4w
        mov [io_write_tbl+0eh*4],offset ch4w
        mov [io_write_tbl+0fh*4],offset ch4w
        mov [io_write_tbl+10h*4],offset ch5w
        mov [io_write_tbl+11h*4],offset ch5w
        mov [io_write_tbl+12h*4],offset ch5w
        mov [io_write_tbl+13h*4],offset ch5w
        mov [io_write_tbl+15h*4],offset snd15w

        xor eax,eax
        mov [inuse],eax
        mov [mixerdmadst],eax
        mov [mixed],DMABUFFERS-1

        cmp [sb_dsp],3
        ja sb16setup
sbsetup:;--------------------------------
        mov [dmasize],MIXSIZE*DMABUFFERS
        mov [framesize],MIXSIZE
        call allocDMA
        jc si99

        mov [sb_freq],44100
        call precalc                            ;build tables
        mov al,TIMECONST                        ;set freq
        call write_dsp
        mov al,233         ;256-1000000/44100
        call write_dsp

        call dma8                               ;setup 8bit DMA
        mov al,48h
        call write_dsp
        mov al,(MIXSIZE-1) and 0ffh
        call write_dsp                          ;set length low
        mov al,(MIXSIZE-1)/256
        call write_dsp                          ;set length high
        mov al,1ch                              ;8bit autoinit
        call write_dsp

        call sb_pause                           ;this clears dma buffers
        call sb_resume                          ;and resets vars
        clc
        ret
sb16setup:;------------------------------        
        mov [dmasize],MIXSIZE*DMABUFFERS*2
        mov [framesize],MIXSIZE*2
        call allocDMA
        jc si99

        inc [sb_irqack]
        mov [sb_freq],44100
        call precalc                            ;build tables
        mov al,SAMPLERATE                       ;set freq
        call write_dsp
        mov al,byte ptr (44100 shr 8)
        call write_dsp
        mov al,byte ptr (44100 and 0ffh)
        call write_dsp

        call dma16                              ;setup 16bit DMA
        mov al,0b6h                             ;16bit autoinit
        call write_dsp
        mov al,10h
        call write_dsp                          ;mono+signed
        mov al,(MIXSIZE-1) and 0ffh
        call write_dsp                          ;set length low
        mov al,(MIXSIZE-1)/256
        call write_dsp                          ;set length high

        mov [wavbps],88200
        mov [wavalign],2
        mov [wavbits],16

        call sb_pause
        call sb_resume
        clc
        ret
dma8:;-----------------------------------
        mov ecx,[dmabuff]
        add ecx,[code_addr]                     ;ECX=address
        movzx ebx,[sb_dma8]                     ;EBX=channel
        xor edx,edx
        mov al,4
        add al,bl
        out 0ah,al                              ;mask dma channel
        out 0ch,al                              ;clear dma ptr
        mov al,58h
        add al,bl
        out 0bh,al                              ;set mode (auto-init read)
        mov dl,[dma8addr+ebx]
        mov al,cl
        out dx,al                               ;set address low
        mov al,ch
        out dx,al                               ;set address high
        inc dl
        mov al,(MIXSIZE*DMABUFFERS-1) and 0ffh
        out dx,al                               ;set length low
        mov al,(MIXSIZE*DMABUFFERS-1)/256
        out dx,al                               ;set length high
        shr ecx,16
        mov dl,[dma8page+ebx]
        mov al,cl
        out dx,al                               ;set page
        mov al,bl
        out 0ah,al                              ;unmask dma channel
        ret
dma16:;-----------------------------------
        mov ecx,[dmabuff]
        add ecx,[code_addr]
        shr ecx,1                               ;ECX=address
        movzx ebx,[sb_dma16]                    ;EBX=channel
        xor edx,edx
        mov al,4
        add al,bl
        out 0d4h,al                             ;mask dma channel
        out 0d8h,al                             ;clear dma ptr
        mov al,58h
        add al,bl
        out 0d6h,al                             ;set mode (auto-init read)
        mov dl,[dma16addr+ebx]
        mov al,cl
        out dx,al                               ;set address low
        mov al,ch
        out dx,al                               ;set address high
        add dl,2
        mov al,(MIXSIZE*DMABUFFERS-1) and 0ffh
        out dx,al                               ;set length low
        mov al,(MIXSIZE*DMABUFFERS-1)/256
        out dx,al                               ;set length high
        shr ecx,15
        mov dl,[dma16page+ebx]
        mov al,cl
        out dx,al                               ;set page
        mov al,bl
        out 0d4h,al                             ;unmask dma channel
        ret
allocDMA:;-------------------------------
        mov ax,0100h                    ;allocate DMA buffer
        mov ebx,[dmasize]
        shr ebx,3                               ;(double the size)
        inc ebx                                 ;a little safety
        int 31h
        jc ad00
        mov ebx,10000h
        sub ebx,[dmasize]
        and eax,0ffffh
        shl eax,4
        cmp ax,bx                               ;fits in this segment?
        jbe ad01
        mov ax,-1                               ;if not, go on to the next
        inc eax
ad01:   sub eax,[code_addr]
        mov [dmabuff],eax
        clc                             ;carry=errorflag
ad00:   ret
si99:;-----------------------------------
        stc
        ret
;----------------------------------------------------------------------------
precalc:;       build tables
;----------------------------------------------------------------------------
        xor eax,eax
        mov ebx,44100 ;[sb_freq]               ;build freq tbl
        mov [freqtbl],eax
        mov [freqtbl+4],eax
        mov [freqtbl+8],eax
        mov [freqtbl+12],eax
        mov [freqtbl+16],eax
        mov [freqtbl+20],eax
        mov [freqtbl+24],eax
        mov [freqtbl+28],eax
        shl ebx,3
        mov ecx,8
pc3:
        add ebx,44100; [sb_freq]
        mov edx,00001b4f4h
        mov eax,0c8000000h
        div ebx
        mov [freqtbl+ecx*4],eax
        inc ecx
        cmp ecx,2048
        jb pc3

changevol:
        movzx eax,[soundvol]
        mov ebx,MASTERVOL
        mul ebx
        xor ecx,ecx
        xor edx,edx
        xor edi,edi

        mov [trianglevol],eax
        add [trianglevol],eax
cv0:    mov [noisevols+edi*4],ecx
        mov [squarevols+edi*4],edx
        add ecx,eax
        lea edx,[edx+eax*2]
        inc edi
        cmp edi,16
        jb cv0
        ret
;----------------------------------------------------------------------------
sb_exit:;
;----------------------------------------------------------------------------
        cmp [sb_installed],0
        je sx0                          ;no SB here?
        
        mov edx,[sb_isr]                ;disable interrupt
        mov bl,[sb_imr]
        inc dl
        in al,dx
        or al,bl
        out dx,al

        call reset_sb                   ;reset
        mov al,10h
        call write_dsp
        mov al,00h
        call write_dsp                  ;this seems to get rid of leftover buzzing

        cmp [wavhandle],0
        jne wavrecord                    ;stop recording
sx0:
        ret
;----------------------------------------------------------------------------
reset_sb:
;
;       out:
;               CF set if unsuccessful
;----------------------------------------------------------------------------
        mov edx,[sb_base]
        add dl,6
        mov al,01h              ;write 1 to reset port
        out dx,al
        in al,dx                ;delay
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        mov al,00h              ;write 0 to reset port
        out dx,al

        mov edx,[sb_data]
        xor ecx,ecx
rs1:
        in al,dx
        or al,al
        js rd0
        inc cl
        jnz rs1
rs2:    stc
        ret
rs0:
        sub dl,4
        in al,dx
        cmp al,0aah             ;reset ok?
        jne rs2
        ret
;----------------------------------------------------------------------------
get_dsp:;       get dsp version number
;
;       out:
;               AX=number
;----------------------------------------------------------------------------
        mov al,DSPVERSION
        call write_dsp
        call read_dsp
        mov ah,al               ;AH=major version number
        call read_dsp           ;AL=minor version number
        ret
;----------------------------------------------------------------------------
read_dsp:
;       out:
;               AL=value
;----------------------------------------------------------------------------
        mov edx,[sb_data]
rd0:    in al,dx                        ;wait til ready to read
        or al,al
        jns rd0
        sub dl,4
        in al,dx                        ;read data
        ret
;----------------------------------------------------------------------------
write_dsp:
;       in:
;               AL=value
;----------------------------------------------------------------------------
        push eax
        mov edx,[sb_write]
wd0:    in al,dx                        ;wait til ready to receive
        or al,al
        js wd0
        pop eax
        out dx,al                       ;send data
        ret
;----------------------------------------------------------------------------
sb_pause:;      pause SB output
;----------------------------------------------------------------------------
        cmp [sb_installed],0
        je sp9
        mov [pause],1

        xor eax,eax
        cmp [sb_dsp],3
        ja sp1
        mov eax,80808080h
sp1:
        mov edi,[dmabuff]
        mov ecx,[dmasize]
        shr ecx,2
        inc ecx
        rep stosd

        cmp [wavhandle],0
        jne wavrecord                   ;stop recording
sp9:    ret
;----------------------------------------------------------------------------
sb_resume:;     resume SB output
;----------------------------------------------------------------------------
;        cmp [sb_installed],0
;        je sr9
        mov [pause],0

        mov eax,[inuse]
        mov [mixerdmadst],eax
        mov [mixed],DMABUFFERS-1        ;reset vars..

sr9:    ret
;----------------------------------------------------------------------------
blasterint:;    SB interrupt handler
;----------------------------------------------------------------------------
        pushad
        push ds
        mov ax,word ptr cs:[data_sel]
        mov ds,ax                       ;load data selector

        mov edx,[sb_irqack]
        in al,dx                        ;acknowledge DSP IRQ
        cmp [sb_int],70h
        mov al,20h
        jb pm0
        out 0a0h,al                     ;send EOI to slave ISR
pm0:    out 20h,al                      ;send EOI to master ISR

        mov eax,[inuse]                 ;keep track of where SB is DMA'ing from
        add eax,[framesize]
        cmp eax,[dmasize]
        jb pm1
        xor eax,eax
pm1:    mov [inuse],eax

        dec [mixed]

        pop ds
        popad
        iretd
;----------------------------------------------------------------------------
mixer:;         call this after frame is drawn, so [render] adjustmends work out right
;----------------------------------------------------------------------------
        cmp [sb_installed],0
        je fakemixer

        mov edi,offset mixbuff
        mov ecx,MIXSIZE
        xor eax,eax
        rep stosd

        test [soundmask],1
        jz mix2
        call channel1
mix2:   test [soundmask],2
        jz mix3
        call channel2
mix3:   test [soundmask],4
        jz mix4
        call channel3
mix4:   test [soundmask],8
        jz mix5
        call channel4
mix5:   test [soundmask],16
        jz mix6
        call channel5
mix6:
        mov eax,[cycles]
        mov [ch1time],0
        mov [ch2time],0
        mov [ch3time],0
        mov [ch4time],0
        mov [ch5time],0
        mov [totalcycles],eax

        mov edi,[mixerdmadst]           ;to
        mov esi,offset mixbuff          ;from
        mov ecx,MIXSIZE                 ;count

        mov bl,1
        inc [mixed]
mix1:   cmp [mixed],DMABUFFERS-2        ;don't get too far ahead
        jg mix1
        cmp [mixed],DMABUFFERS-3
        jge mix7                        ;(or behind)
        mov bl,0
mix7:   mov [render],bl                 ;(make sure mixer() and ppu calls are done in a sane order so this works out right)

        cmp [sb_dsp],3
        ja mix12

        mov eax,edi                     ;update dma buffer dest.
        add eax,MIXSIZE
        cmp eax,MIXSIZE*DMABUFFERS
        jb mix8
        xor eax,eax
mix8:   mov [mixerdmadst],eax

        add edi,[dmabuff]
mix0:
        mov al,[esi+3]                  ;fill dma buffer
        add esi,4
        xor al,80h
        mov [edi],al
        inc edi
        dec ecx
        jnz mix0
        jmp mix11
mix12:
                mov eax,edi                     ;16 bit version:
                add eax,MIXSIZE*2   
                cmp eax,MIXSIZE*DMABUFFERS*2
                jb mix18
                xor eax,eax
mix18:          mov [mixerdmadst],eax

                add edi,[dmabuff]
mix10:
                mov al,[esi+2]
                mov ah,[esi+3]
                add esi,4
                mov [edi],al
                mov [edi+1],ah
                add edi,2
                dec ecx
                jnz mix10
mix11:
        cmp [wavhandle],0               ;.wav logging?
        je mix9
        cmp [mixerdmadst],0                      ;do whole DMA buffer at once
        jne mix9
        
        mov ebx,[wavhandle]
        mov ecx,[dmasize]
        mov edx,[dmabuff]
        add [wavsize],ecx
        call f_write
        jc wavrecord                            ;stop recording on error
mix9:
        ret
;----------------------------------------------------------------------------
fakemixer:
;----------------------------------------------------------------------------
        mov eax,[cycles]
        mov [totalcycles],eax

        mov [render],1
        mov eax,[framecount]
df9:    cmp eax,[ticks]           ;wait if we're early
        ja df9

        cmp eax,[ticks]
        je df0
        mov [render],0
df0:
        ret
;----------------------------------------------------------------------------
channel1:;      add ch1 (square) to mixer buffer
;----------------------------------------------------------------------------
        mov eax,[ch1buffptr]
        xor edi,edi             ;edi=mixbuff ptr
        xor esi,esi             ;esi=ch*buffptr
        mov [ch1buff+eax*8+time],9999999        ;top off ch*buff
        mov eax,[ch1buff+esi*8+time]            ;get starting time
        mov [ch1next],eax
        mov [ch1buffptr],edi

        mov edx,[ch1vol]        ;edx=
        mov eax,[ch1freq]
        mov ebp,[freqtbl+eax*4] ;ebp=freq
                                ;eax,ebx,ecx=free
ch10:                                           ;port write:
        add [ch1frac],MINOR
        sbb [ch1next],MAJOR
        jns ch12

        mov ebx,dword ptr [ch1buff+esi*8+port]          ;ebx=port
        mov al,[ch1buff+esi*8+data]                     ;eax=data
        and ebx,7
        call [ch1write+ebx*4]                           ;do write
        mov eax,[ch1buff+esi*8+time+8]                  ;get the next time
        inc esi
        add [ch1next],eax
ch12:
        test [on],00001b                ;channel active?
        jz ch16

        mov eax,[ch1timerspeed]                 ;timer
        add [ch1timermod],eax
        jnc ch15
        and [on],not 00001b
ch15:
        add [ch1pos],ebp                        ;+ pulse
        jnc ch11

        mov bl,[sregs+00h]
        test bl,00010000b
        jnz ch151
        mov ebx,[ch1decayvol]
  ch151:
        and ebx,15
        add edx,[squarevols+ebx*4]
ch11:                                           ;- pulse
        add [ch1neg],ebp
        jnc ch13

        mov bl,[sregs+00h]
        test bl,00010000b
        jnz ch111
        mov ebx,[ch1decayvol]
  ch111:
        and ebx,15
        sub edx,[squarevols+ebx*4]
ch13:                          
        mov ebx,[ch1decayspeed]                 ;vol decay
        add [ch1decaymod],ebx
        sbb [ch1decayvol],0
        jnc ch133
        inc [ch1decayvol]
        test [sregs+00h],00100000b
        jz ch133
        mov [ch1decayvol],15
ch133:
        mov eax,[ch1sweepspeed]                 ;freq sweep
        add [ch1sweepmod],eax
        jnc ch16

        mov eax,[ch1freq]
        mov cl,[ch1sweepshift]
        shr eax,cl
        test [sregs+01h],00001000b
        jz ch131
        not eax
    ch131:
        add eax,[ch1freq]

        cmp eax,800h
        jb ch132
        xor eax,eax
    ch132:
        mov [ch1freq],eax
        mov ebp,[freqtbl+eax*4]
ch16:
        mov eax,edx
        sar eax,5
        add [mixbuff+edi*4],edx
        sub edx,eax
        inc edi
        cmp edi,MIXSIZE
        jb ch10

        mov [ch1vol],edx
        ret
;- - - - - - - - - - - - - - - - - - - - - - -
w00:
        mov [sregs+00h],al

        and eax,0c0h            ;**xxxxxx
        shr eax,4
        mov ebx,[ch1pos]
        sub ebx,[ratio+eax]
        mov [ch1neg],ebx

        mov al,[sregs+00h]      ;xxxx****
        and eax,0fh
        mov ebx,[decayspeeds+eax*4]
        mov [ch1decayspeed],ebx
  w000:
        mov al,[sregs+03h]      ;xx*xxxxx (w03 jumps here)
        and eax,11111000b
        shr eax,1
        mov ebx,[timerspeeds+eax]
        test [sregs+00h],00100000b
        jz w001
        xor ebx,ebx
  w001: mov [ch1timerspeed],ebx

        ret
w01:
        mov [ch1sweepmod],40000000h             ;??? zelda2
        mov [sregs+01h],al
        and eax,0f0h            ;****xxxx
        shr eax,4
        mov ebx,[sweepspeeds+eax*4]
        mov [ch1sweepspeed],ebx

        mov al,[sregs+01h]      ;xxxxx***
        and al,7
        jz w011
        mov [ch1sweepshift],al
        ret
   w011:
        mov [ch1sweepspeed],0
        ret
w02:
        mov [sregs+02h],al
        mov byte ptr [ch1freq],al

        mov eax,[ch1freq]
        mov ebp,[freqtbl+eax*4]
        ret
w03:
        mov [sregs+03h],al

        and al,7                        ;xxxxx***
        mov byte ptr [ch1freq+1],al
        mov eax,[ch1freq]
        mov ebp,[freqtbl+eax*4]

        mov al,[sregs+15h]
        and al,00001b
        or [on],al

        mov [ch1decayvol],15
        mov [ch1decaymod],0

        mov [ch1timermod],0             ;*****xxx
        jmp w000
w04:
        and [sregs+15h],11110b
        and al,00001b
        or [sregs+15h],al

        or al,not 00001b
        and [on],al
        ret
;- - - - - - -
                align 4

ch1write        dd w00,w01,w02,w03,w04

ch1vol          dd 0
ch1frac         dd ?
ch1next         dd ?                            ;time til next write
ch1freq         dd ?
ch1pos          dd 87654321h
ch1neg          dd ?
ch1decayspeed   dd ?
ch1decaymod     dd ?
ch1decayvol     dd ?
ch1timerspeed   dd ?
ch1timermod     dd ?
ch1sweepspeed   dd ?
ch1sweepmod     dd ?
ch1sweepshift   db ?

                align 4

ratio           dd 20000000h    ;12.5%
                dd 40000000h    ;25%
                dd 80000000h    ;50%
                dd 0c0000000h   ;75%

squarevols      dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?

DECAYSPEED equ 23378314  ;111860.78/44100/466
decayspeeds     dd     DECAYSPEED/1
                dd     DECAYSPEED/2
                dd     DECAYSPEED/3
                dd     DECAYSPEED/4
                dd     DECAYSPEED/5
                dd     DECAYSPEED/6
                dd     DECAYSPEED/7
                dd     DECAYSPEED/8
                dd     DECAYSPEED/9
                dd     DECAYSPEED/10
                dd     DECAYSPEED/11
                dd     DECAYSPEED/12
                dd     DECAYSPEED/13
                dd     DECAYSPEED/14
                dd     DECAYSPEED/15
                dd     DECAYSPEED/16

SWEEPSPEED equ 11689157 ;111860.78/44100/932
sweepspeeds     dd     0
                dd     0
                dd     0
                dd     0
                dd     0
                dd     0
                dd     0
                dd     0
                dd     SWEEPSPEED/1
                dd     SWEEPSPEED/2
                dd     SWEEPSPEED/3
                dd     SWEEPSPEED/4
                dd     SWEEPSPEED/5
                dd     SWEEPSPEED/6
                dd     SWEEPSPEED/7
                dd     SWEEPSPEED/8

TIMERSPEED equ 5843492   ;%1/44100*60
timerspeeds     dd     TIMERSPEED/5
                dd     TIMERSPEED/127
                dd     TIMERSPEED/10
                dd     TIMERSPEED/1
                dd     TIMERSPEED/20
                dd     TIMERSPEED/2
                dd     TIMERSPEED/40
                dd     TIMERSPEED/3
                dd     TIMERSPEED/80
                dd     TIMERSPEED/4
                dd     TIMERSPEED/30
                dd     TIMERSPEED/5
                dd     TIMERSPEED/7
                dd     TIMERSPEED/6
                dd     TIMERSPEED/13
                dd     TIMERSPEED/7
                dd     TIMERSPEED/6
                dd     TIMERSPEED/8
                dd     TIMERSPEED/12
                dd     TIMERSPEED/9
                dd     TIMERSPEED/24
                dd     TIMERSPEED/10
                dd     TIMERSPEED/48
                dd     TIMERSPEED/11
                dd     TIMERSPEED/96
                dd     TIMERSPEED/12
                dd     TIMERSPEED/36
                dd     TIMERSPEED/13
                dd     TIMERSPEED/8
                dd     TIMERSPEED/14
                dd     TIMERSPEED/16
                dd     TIMERSPEED/15
;----------------------------------------------------------------------------
channel2:;      add ch2 (square) to mixer buffer
;----------------------------------------------------------------------------
        mov eax,[ch2buffptr]
        xor edi,edi             ;edi=mixbuff ptr
        xor esi,esi             ;esi=ch*buffptr
        mov [ch2buff+eax*8+time],9999999        ;top off ch*buff
        mov eax,[ch2buff+esi*8+time]            ;get starting time
        mov [ch2next],eax
        mov [ch2buffptr],edi

        mov edx,[ch2vol]        ;edx=
        mov eax,[ch2freq]
        mov ebp,[freqtbl+eax*4] ;ebp=freq
                                ;eax,ebx,ecx=free
ch20:                                           ;port write:
        add [ch2frac],MINOR
        sbb [ch2next],MAJOR
        jns ch22

        mov ebx,dword ptr [ch2buff+esi*8+port]          ;ebx=port
        mov al,[ch2buff+esi*8+data]                     ;eax=data
        and ebx,7
        call [ch2write+ebx*4]                           ;do write
        mov eax,[ch2buff+esi*8+time+8]                  ;get the next time
        inc esi
        add [ch2next],eax
ch22:
        test [on],00010b                ;channel active?
        jz ch26

        mov eax,[ch2timerspeed]                 ;timer
        add [ch2timermod],eax
        jnc ch25
        and [on],not 00010b
ch25:
        add [ch2pos],ebp                        ;+ pulse
        jnc ch21

        mov bl,[sregs+04h]
        test bl,00010000b
        jnz ch251
        mov ebx,[ch2decayvol]
  ch251:
        and ebx,15
        add edx,[squarevols+ebx*4]
ch21:                                           ;- pulse
        add [ch2neg],ebp
        jnc ch23

        mov bl,[sregs+04h]
        test bl,00010000b
        jnz ch211
        mov ebx,[ch2decayvol]
  ch211:
        and ebx,15
        sub edx,[squarevols+ebx*4]
ch23:                          
        mov ebx,[ch2decayspeed]                 ;vol decay
        add [ch2decaymod],ebx
        sbb [ch2decayvol],0
        jnc ch233
        inc [ch2decayvol]
        test [sregs+04h],00100000b
        jz ch233
        mov [ch2decayvol],15
ch233:
        mov eax,[ch2sweepspeed]                 ;freq sweep
        add [ch2sweepmod],eax
        jnc ch26

        mov eax,[ch2freq]
        mov cl,[ch2sweepshift]
        shr eax,cl
        test [sregs+05h],00001000b
        jz ch231
        not eax
    ch231:
        add eax,[ch2freq]

        cmp eax,800h
        jb ch232
        xor eax,eax
    ch232:
        mov [ch2freq],eax
        mov ebp,[freqtbl+eax*4]
ch26:
        mov eax,edx
        sar eax,5
        add [mixbuff+edi*4],edx
        sub edx,eax
        inc edi
        cmp edi,MIXSIZE
        jb ch20

        mov [ch2vol],edx
        ret
;- - - - - - - - - - - - - - - - - - - - - - -
w20:
        mov [sregs+04h],al

        and eax,0c0h            ;**xxxxxx
        shr eax,4
        mov ebx,[ch2pos]
        sub ebx,[ratio+eax]
        mov [ch2neg],ebx

        mov al,[sregs+04h]      ;xxxx****
        and eax,0fh
        mov ebx,[decayspeeds+eax*4]
        mov [ch2decayspeed],ebx
  w200:
        mov al,[sregs+07h]      ;xx*xxxxx (w23 jumps here)
        and eax,11111000b
        shr eax,1
        mov ebx,[timerspeeds+eax]
        test [sregs+04h],00100000b
        jz w201
        xor ebx,ebx
  w201: mov [ch2timerspeed],ebx

        ret
w21:
        mov [ch2sweepmod],40000000h             ;??? zelda2
        mov [sregs+05h],al
        and eax,0f0h            ;****xxxx
        shr eax,4
        mov ebx,[sweepspeeds+eax*4]
        mov [ch2sweepspeed],ebx

        mov al,[sregs+05h]      ;xxxxx***
        and al,7
        jz w211
        mov [ch2sweepshift],al
        ret
   w211:
        mov [ch2sweepspeed],0
        ret
w22:
        mov [sregs+06h],al
        mov byte ptr [ch2freq],al

        mov eax,[ch2freq]
        mov ebp,[freqtbl+eax*4]
        ret
w23:
        mov [sregs+07h],al

        and al,7                        ;xxxxx***
        mov byte ptr [ch2freq+1],al
        mov eax,[ch2freq]
        mov ebp,[freqtbl+eax*4]

        mov al,[sregs+15h]
        and al,00010b
        or [on],al

        mov [ch2decayvol],15
        mov [ch2decaymod],0

        mov [ch2timermod],0             ;*****xxx
        jmp w200
w24:
        and [sregs+15h],11101b
        and al,00010b
        or [sregs+15h],al

        or al,not 00010b
        and [on],al
        ret
;- - - - - - -
                align 4

ch2write        dd w20,w21,w22,w23,w24

ch2vol          dd 7fh
ch2frac         dd ?
ch2next         dd ?                            ;time til next write
ch2freq         dd ?
ch2pos          dd ?
ch2neg          dd ?
ch2decayspeed   dd ?
ch2decaymod     dd ?
ch2decayvol     dd ?
ch2timerspeed   dd ?
ch2timermod     dd ?
ch2sweepspeed   dd ?
ch2sweepmod     dd ?
ch2sweepshift   db ?
;----------------------------------------------------------------------------
channel3:;      add ch3 (triangle) to mixer buffer
;----------------------------------------------------------------------------
        mov eax,[ch3buffptr]
        xor edi,edi             ;edi=mixbuff ptr
        xor esi,esi             ;esi=ch*buffptr
        mov [ch3buff+eax*8+time],9999999        ;top off ch*buff
        mov eax,[ch3buff+esi*8+time]            ;get starting time
        mov [ch3next],eax
        mov [ch3buffptr],edi

        mov ebx,[ch3timer2inc]
        mov edx,[ch3level]
        mov eax,[ch3freq]
        mov ebp,[freqtbl+eax*4] ;ebp=freq
                                ;eax,ecx=free
ch30:                                           ;port write:
        add [ch3frac],MINOR
        sbb [ch3next],MAJOR
        jns ch32

        mov ecx,dword ptr [ch3buff+esi*8+port]          ;ecx=port
        mov al,[ch3buff+esi*8+data]                     ;eax=data
        and ecx,7
        call [ch3write+ecx*4]                           ;do write
        mov eax,[ch3buff+esi*8+time+8]                  ;get the next time
        inc esi
        add [ch3next],eax
ch32:
        test [on],00100b                ;channel active?
        jz ch39

        mov eax,[ch3timerspeed]                 ;timer1
        add [ch3timermod],eax
        jnc ch35
        and [on],not 00100b
ch35:                                           ;timer2
        add [ch3timer2mod],ebx
        sbb [ch3timer2],0
        jle ch39
ch36:
        add [ch3freqmod],ebp                    ;+- pulse
        jnc ch31

        add [ch3step],08h
        jo ch31
        jc ch31
        mov eax,[trianglevol]
        jns ch351
        neg eax
  ch351:
        add edx,eax
ch31:
        mov eax,edx
        sar eax,9
        sub edx,eax

        add [ch3blah],10h
        jnc ch36

        add [mixbuff+edi*4],edx

        inc edi
        cmp edi,MIXSIZE
        jb ch30

        mov [ch3level],edx
        mov [ch3timer2inc],ebx
        ret
ch39:                                   ;<-- channel off
        mov eax,edx
         mov ecx,edx
        sar eax,6
         add [mixbuff+edi*4],edx
        sar ecx,7
         sub edx,eax
        inc edi
         sub edx,ecx
        cmp edi,MIXSIZE
        jb ch30

        mov [ch3level],edx
        mov [ch3timer2inc],ebx
        ret

;- - - - - - - - - - - - - - - - - - - - - - -
w30:
        mov cl,[sregs+08h]
        mov [sregs+08h],al
        and ecx,7fh
        and eax,7fh             ;eax=new, ecx=old
  w300:                         ;(w33 jumps here with eax,ecx setup)
        cmp ecx,[ch3timer2]
        jne w302                ;(if timer2 countdown has started)
        mov [ch3timer2],eax
        xor ebx,ebx
        test [sregs+08h],80h
        jnz w303
        mov ebx,TIMER2SPEED
  w303:
        mov [ch3timer2inc],ebx
  w302:
        mov al,[sregs+0bh]
        and eax,11111000b
        shr eax,1
        mov ecx,[timerspeeds+eax]
        test [sregs+08h],10000000b
        jz w301
        xor ecx,ecx
  w301: mov [ch3timerspeed],ecx
        ret
w31:
        ret
w32:
        mov [sregs+0ah],al
        mov byte ptr [ch3freq],al

        mov eax,[ch3freq]
        mov ebp,[freqtbl+eax*4]
        ret
w33:
        mov [sregs+0bh],al

        and al,7                        ;xxxxx***
        mov byte ptr [ch3freq+1],al
        mov eax,[ch3freq]
        mov ebp,[freqtbl+eax*4]

        mov al,[sregs+15h]
        and al,00100b
        or [on],al

        mov [ch3timermod],0             ;reset both timers..
        mov [ch3timer2mod],0
        mov cl,[sregs+08h]
        and ecx,7fh
        mov eax,ecx
        mov [ch3timer2],ecx
        jmp w300
w34:
        and [sregs+15h],11011b
        and al,00100b
        or [sregs+15h],al

        or al,not 00100b
        and [on],al
        ret
;- - - - - - -
                align 4

ch3write        dd w30,w31,w32,w33,w34

trianglevol     dd ?
ch3level        dd ?
ch3frac         dd ?
ch3next         dd ?                            ;time til next write
ch3freq         dd ?
ch3freqmod      dd ?
ch3timerspeed   dd ?
ch3timermod     dd ?
ch3timer2       dd ?
ch3timer2mod    dd ?
ch3timer2inc    dd ?

ch3step         db ?
ch3blah         db ?

TIMER2SPEED     equ 23373972  ;%1/44100*60*4
;----------------------------------------------------------------------------
channel4:;      add ch4 (noise) to mixer buffer
;----------------------------------------------------------------------------
        mov eax,[ch4buffptr]
        xor edi,edi             ;edi=mixbuff ptr
        xor esi,esi             ;esi=ch*buffptr
        mov [ch4buff+eax*8+time],9999999        ;top off ch*buff
        mov eax,[ch4buff+esi*8+time]            ;get starting time
        mov [ch4next],eax
        mov [ch4buffptr],edi

        mov ebx,[ch4loopcount]
        mov edx,[ch4vol]        ;edx=
        mov al,[sregs+0eh]
        and eax,15
        mov ebp,[noisefreqs+eax*4] ;ebp=freq
                                   ;eax,ecx=free
ch40:                                           ;port write:
        add [ch4frac],MINOR
        sbb [ch4next],MAJOR
        jns ch42

        mov ecx,dword ptr [ch4buff+esi*8+port]          ;ecx=port
        mov al,[ch4buff+esi*8+data]                     ;eax=data
        and ecx,7
        call [ch4write+ecx*4]                           ;do write
        mov eax,[ch4buff+esi*8+time+8]                  ;get the next time
        inc esi
        add [ch4next],eax
ch42:
        test [on],01000b                ;channel active?
        jz ch49

        mov eax,[ch4timerspeed]                 ;timer
        add [ch4timermod],eax
        jnc ch45
        and [on],not 01000b
ch45:
        add [ch4freqmod],ebp                    ;+- pulse
        jnc ch41

        mov eax,[rand1]
        mov ecx,[rand2]
        dec ebx
        jns ch450
        mov eax,[seed1]
        mov ecx,[seed2]
        mov ebx,[ch4loop]
        mov [rand1],eax
  ch450:
        add [rand1],ecx
        mov [rand2],eax
        shl eax,1
        jc ch41

        mov cl,[sregs+0ch]
        test cl,00010000b
        jnz ch451
        mov ecx,[ch4decayvol]
  ch451:
        and ecx,15
        neg [ch4sign]
        mov eax,[noisevols+ecx*4]
        js ch452
        neg eax
  ch452:
        add edx,eax
ch41:
        mov ecx,[ch4decayspeed]                 ;vol decay
        add [ch4decaymod],ecx
        sbb [ch4decayvol],0
        jnc ch49
        inc [ch4decayvol]
        test [sregs+0ch],00100000b
        jz ch49
        mov [ch4decayvol],15
ch49:
        mov eax,edx
        sar eax,5
        add [mixbuff+edi*4],edx
        sub edx,eax
        inc edi
        cmp edi,MIXSIZE
        jb ch40

        mov [ch4vol],edx
        mov [ch4loopcount],ebx
        ret
;- - - - - - - - - - - - - - - - - - - - - - -
w40:
        mov [sregs+0ch],al

        mov al,[sregs+0ch]      ;xxxx****
        and eax,0fh
        mov ecx,[decayspeeds+eax*4]
        mov [ch4decayspeed],ecx
  w400:
        mov al,[sregs+0fh]      ;xx*xxxxx (w43 jumps here)
        and eax,11111000b
        shr eax,1
        mov ecx,[timerspeeds+eax]
        test [sregs+0ch],00100000b
        jz w401
        xor ecx,ecx
  w401: mov [ch4timerspeed],ecx

        ret
w41:
        ret
w42:
        mov ah,[sregs+0eh]
        mov [sregs+0eh],al

        mov ebp,8000h
        test al,80h
        jz w420
        mov ebp,92
        test ah,80h
        jnz w421
        mov ebx,ebp
        mov eax,[rand1]
        mov ecx,[rand2]
        mov [seed1],eax
        mov [seed2],ecx
  w420: mov [ch4loop],ebp
  w421:
        mov al,[sregs+0eh]
        and eax,15
        mov ebp,[noisefreqs+eax*4]

        ret
w43:
        mov [sregs+0fh],al

        mov al,[sregs+15h]
        and al,01000b
        or [on],al

        mov [ch4decayvol],15
        mov [ch4decaymod],0

        mov [ch4timermod],0             ;*****xxx
        jmp w400
w44:
        and [sregs+15h],10111b
        and al,01000b
        or [sregs+15h],al

        or al,not 01000b
        and [on],al
        ret
;- - - - - - -
                align 4

ch4write        dd w40,w41,w42,w43,w44

ch4vol          dd 7fh
ch4frac         dd ?
ch4next         dd ?                            ;time til next write
ch4freqmod      dd ?
ch4sign         dd 1
ch4decayspeed   dd ?
ch4decaymod     dd ?
ch4decayvol     dd ?
ch4timerspeed   dd ?
ch4timermod     dd ?
ch4loop         dd ?
ch4loopcount    dd ?

rand1           dd 01234567h
rand2           dd 89abcdefh
seed1           dd 01234567h
seed2           dd 89abcdefh

                align 4
;NOISEFREQ=%21477270/44100/12/4
noisefreqs      dd -1           ;NOISEFREQ/1
                dd -1           ;NOISEFREQ/2
                dd -1           ;NOISEFREQ/4
                dd -1           ;NOISEFREQ/8
                dd 2723573680   ;NOISEFREQ/16
                dd 1815715787   ;NOISEFREQ/24
                dd 1361786840   ;NOISEFREQ/32
                dd 1089429472   ;NOISEFREQ/40
                dd 871543577    ;NOISEFREQ/50?
                dd 680893420    ;NOISEFREQ/64
                dd 453928947    ;NOISEFREQ/96
                dd 340446710    ;NOISEFREQ/128
                dd 239435049    ;NOISEFREQ/182?
                dd 170223355    ;NOISEFREQ/256
                dd 85111677     ;NOISEFREQ/512
                dd 42555839     ;NOISEFREQ/1024

noisevols       dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?
                dd ?

;----------------------------------------------------------------------------
channel5:;      add ch5 (PCM) to mixer buffer
;----------------------------------------------------------------------------
        mov eax,[ch5buffptr]
        xor edi,edi             ;edi=dst
        xor esi,esi             ;esi=ch5buffptr
        mov [ch5buff+eax*8+time],9999999        ;top off ch5buff
        mov eax,[ch5buff+esi*8+time]            ;get starting time
        mov [ch5next],eax
        mov [ch5buffptr],edi

        mov al,[sregs+10h]
        mov edx,[ch5level]              ;edx=vol
        and eax,0fh
        xor ebx,ebx
        mov ebp,[pcmfreqs+eax*4]        ;ebp=freq
        mov bl,[sregs+11h]              ;ebx=4011 counter
ch50:
        add [ch5frac],MINOR
        sbb [ch5next],MAJOR
        jns ch52

        mov ecx,dword ptr [ch5buff+esi*8+port]          ;ecx=port
        mov al,[ch5buff+esi*8+data]                     ;eax=data
        and ecx,7
        call [ch5write+ecx*4]                           ;do write
        mov eax,[ch5buff+esi*8+time+8]                  ;get the next time
        inc esi
        add [ch5next],eax
ch52:
        test [on],10000b
        jz ch59                         ;no DMA

        add [ch5freqmod],ebp            ;freq step
        jnc ch59
        dec [ch5bitnum]
        jns ch53
        dec [ch5dmasize]                ;dma complete?
        js ch58
  ch55:
        mov eax,[ch5dmaaddr]            ;get next byte
        mov ecx,eax
        shr eax,13
        mov [ch5bitnum],7
        mov eax,[memmap+6*4+eax*4]
        mov al,[ecx+eax+0c000h]
        inc ecx
        and ecx,3fffh
        mov [ch5dmabyte],al
        mov [ch5dmaaddr],ecx
  ch53:
        shr [ch5dmabyte],1              ;bit advance
        mov al,2
        mov ecx,2 shl PCMVOLSHIFT
        jc ch54
        neg al
        neg ecx
  ch54: add edx,ecx
        add bl,al
        jns ch59
        sub edx,ecx
        sub bl,al
ch59:                   ;(ch58 returns here)
        mov eax,edx
        sar eax,5
        add [mixbuff+edi*4],edx
        sub edx,eax
        inc edi
        cmp edi,MIXSIZE
        jb ch50

        mov [ch5level],edx
        mov [sregs+11h],bl
        ret

ch58:                           ;dma complete
        and [on],not 10000b
        test [sregs+10h],01000000b      ;looping?
        jnz ch581

        test [sregs+10h],10000000b      ;irq?
        jz ch59
        or [on],80h                             ;set irq flag
        or [int_flags],IRQ                      ;trigger irq
        jmp ch59
    ch581:
        mov al,10000b
        push offset ch59
        jmp p540

;- - - - - - - - - - - - - - - - - - - - - - -
p50:
        mov [sregs+10h],al
        and eax,0fh
        mov ebp,[pcmfreqs+eax*4]

        mov al,[sregs+10h]      ;clear irq flag?
        or al,7fh
        and [on],al
        ret
p51:
        and eax,7fh
        mov ecx,ebx
        mov ebx,eax
        sub eax,ecx
        shl eax,PCMVOLSHIFT
        add edx,eax
        ret
p52:
        mov [sregs+12h],al
        ret
p53:
        mov [sregs+13h],al
        ret
p54:
        and [on],7fh            ;clear irq flag
        test [on],10000b
        jz p540
        or al,not 10000b        ;1->0 or 1->1
        and [on],al
        ret
  p540:                         ;0->0 or 0->1    (ch58 jumps here)
        and eax,10000b
        jz p541
        or [on],al

        mov al,[sregs+13h]
        shl eax,4
        inc al
        mov [ch5dmasize],eax

        movzx eax,[sregs+12h]
        shl eax,6
        mov [ch5dmaaddr],eax

        mov [ch5bitnum],-1
        mov [ch5freqmod],0
  p541:
        ret


        align 4

pcmfreqs        dd 407263354  ;1789772.5/44100*8/3424
                dd 458707146  ;3040
                dd 512672693  ;2720
                dd 544714736  ;2560
                dd 609471033  ;2288
                dd 686254786  ;2032
                dd 771277502  ;1808
                dd 814526708  ;1712
                dd 917414292  ;1520
                dd 1089429472 ;1280
                dd 1227526166 ;1136
                dd 1361786840 ;1024
                dd 1644421845 ;848
                dd 2050690771 ;680
                dd 2420954382 ;576
                dd 3227939176 ;432

ch5write        dd p50,p51,p52,p53,p54

ch5level        dd 0
ch5frac         dd ?
ch5next         dd ?
ch5lastvol      dd ?    ;(for raw pcm)
ch5dmasize      dd ?
ch5dmaaddr      dd ?
ch5freqmod      dd ?

ch5bitnum       db ?
ch5dmabyte      db ?
;----------------------------------------------------------------------------
ch1w:;          channel 1 (4000-03)
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        and edi,3
ch1w_:  mov ebp,[ch1buffptr]
        mov dword ptr [ch1buff+ebp*8+port],edi  ;write port
        mov [ch1buff+ebp*8+data],al             ;write data

        mov eax,[cycles]
        mov edi,[totalcycles]
        sub edi,eax
        mov eax,[ch1time]
        mov [ch1time],edi
        sub edi,eax
        mov [ch1buff+ebp*8+time],edi            ;write timestamp

        inc ebp
        cmp ebp,CH1SIZE
        jae cw10
        mov [ch1buffptr],ebp                    ;ignore if full
cw10:
        ret
;----------------------------------------------------------------------------
ch2w:;          channel 2 (4004-07)
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        and edi,3
ch2w_:  mov ebp,[ch2buffptr]
        mov dword ptr [ch2buff+ebp*8+port],edi  ;write port
        mov [ch2buff+ebp*8+data],al             ;write data

        mov eax,[cycles]
        mov edi,[totalcycles]
        sub edi,eax
        mov eax,[ch2time]
        mov [ch2time],edi
        sub edi,eax
        mov [ch2buff+ebp*8+time],edi            ;write timestamp

        inc ebp
        cmp ebp,CH1SIZE
        jae cw20
        mov [ch2buffptr],ebp                    ;ignore if full
cw20:
        ret
;----------------------------------------------------------------------------
ch3w:;          channel 3 (4008-0b)
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        and edi,3
ch3w_:  mov ebp,[ch3buffptr]
        mov dword ptr [ch3buff+ebp*8+port],edi  ;write port
        mov [ch3buff+ebp*8+data],al             ;write data

        mov eax,[cycles]
        mov edi,[totalcycles]
        sub edi,eax
        mov eax,[ch3time]
        mov [ch3time],edi
        sub edi,eax
        mov [ch3buff+ebp*8+time],edi            ;write timestamp

        inc ebp
        cmp ebp,CH1SIZE
        jae cw30
        mov [ch3buffptr],ebp                    ;ignore if full
cw30:
        ret
;----------------------------------------------------------------------------
ch4w:;          channel 4 (400c-0f)
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        and edi,3
ch4w_:  mov ebp,[ch4buffptr]
        mov dword ptr [ch4buff+ebp*8+port],edi  ;write port
        mov [ch4buff+ebp*8+data],al             ;write data

        mov eax,[cycles]
        mov edi,[totalcycles]
        sub edi,eax
        mov eax,[ch4time]
        mov [ch4time],edi
        sub edi,eax
        mov [ch4buff+ebp*8+time],edi            ;write timestamp

        inc ebp
        cmp ebp,CH1SIZE
        jae cw40
        mov [ch4buffptr],ebp                    ;ignore if full
cw40:
        ret
;----------------------------------------------------------------------------
ch5w:;          channel 5 (4010-13)
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        and edi,3
ch5w_:  mov ebp,[ch5buffptr]
        mov dword ptr [ch5buff+ebp*8+port],edi  ;write port
        mov [ch5buff+ebp*8+data],al             ;write data

        mov eax,[cycles]
        mov edi,[totalcycles]
        sub edi,eax
        mov eax,[ch5time]
        mov [ch5time],edi
        sub edi,eax
        mov [ch5buff+ebp*8+time],edi            ;write timestamp

        inc ebp
        cmp ebp,CH5SIZE
        jae cw50
        mov [ch5buffptr],ebp                    ;ignore if full
cw50:
        ret
;----------------------------------------------------------------------------
snd15w:;
;----------------------------------------------------------------------------
;or [int_flags],DEBUG2
;mov [debugmsg],offset msg05
        mov [tmp15],al
        mov edi,4
        call ch1w_
        mov al,[tmp15]
        mov edi,4
        call ch2w_
        mov al,[tmp15]
        mov edi,4
        call ch3w_
        mov al,[tmp15]
        mov edi,4
        call ch4w_
        mov al,[tmp15]
        mov edi,4
        jmp ch5w_

tmp15   db ?
;----------------------------------------------------------------------------
snd15r:;
;----------------------------------------------------------------------------
        mov al,[on]
        ret
;----------------------------------------------------------------------------
soundreset:;    called on cpu reset
;----------------------------------------------------------------------------
        xor eax,eax
        mov [totalcycles],eax
        mov [ch1time],eax
        mov [ch2time],eax
        mov [ch3time],eax
        mov [ch4time],eax
        mov [ch5time],eax
        mov [ch1buffptr],eax
        mov [ch2buffptr],eax
        mov [ch3buffptr],eax
        mov [ch4buffptr],eax
        mov [ch5buffptr],eax

        mov dword ptr [sregs+0],eax
        mov dword ptr [sregs+4],eax
        mov dword ptr [sregs+8],eax
        mov dword ptr [sregs+12],eax
        mov dword ptr [sregs+16],eax
        mov [on],0
        ret
;----------------------------------------------------------------------------
wavrecord:;     call once to start, again to stop
;----------------------------------------------------------------------------
        cmp [sb_installed],0            ;abort if no sound
        je rec9

        cmp [wavhandle],0               ;stop if already recording
        jne rec5

        mov edx,[fileend]
        mov [edx],'VAW'
        mov edx,offset filename
        call f_create
        jc rec9                         ;create wav

        and ebx,0ffffh
        mov [wavhandle],ebx             ;keep handle
        mov ecx,WAVHEADERSIZE
        mov edx,offset wavheader
        call f_write                    ;make room for header
rec9:
        ret
rec5:
        mov ebx,[wavhandle]
        mov [wavhandle],0               ;stop recording
        xor al,al
        xor edx,edx
        call f_seek                     ;seek to header
        jc rec8
        mov eax,[wavsize]
        add eax,WAVHEADERSIZE
        mov [wavfilesize],eax
        mov ecx,WAVHEADERSIZE
        mov edx,offset wavheader
        call f_write                    ;write header
rec8:
        call f_close
        ret
;----------------------------------------------------------------------------

sb_installed    db      0

                align   4

;- - - - - -DSP commands

TIMECONST       equ     040h
SAMPLERATE      equ     041h
DSPVERSION      equ     0e1h

;- - - - - - - - - - - -

sb_base         dd      0               ;2x0
sb_write        dd      0               ;2xC
sb_data         dd      0               ;2xE
sb_irqack       dd      0               ;2xE/F
sb_isr          dd      20h             ;ISR port
sb_int          db      0               ;interrupt# (not irq)
sb_dma8         db      0               ;8bit DMA channel (0-3)
sb_dma16        db      0               ;16bit DMA channel (0-3 not 4-7)
sb_imr          db      0               ;IMR mask
sb_dsp          db      0               ;DSP version (2=2.0; 3=Pro; 4=16/AWE)
sb_freq         dd      ?

IMRmask         db      01h,02h,04h,08h,10h,20h,40h,80h
                db      01h,02h,04h,08h,10h,20h,40h,80h

dma8page        db      87h,83h,81h,82h ;DMA ports
dma8addr        db      00h,02h,04h,06h
dma16page       db      8fh,8bh,89h,8ah
dma16addr       db      0c0h,0c4h,0c8h,0cch

dmasize         dd      ?               ;whole dma buffer size
framesize       dd      ?               ;size for a single frame (dmasize/DMABUFFERS)
inuse           dd      ?               ;where SB is currently reading from (chunk#)
mixerdmadst     dd      ?               ;where newly mixed data will go
mixed           dd      ?               ;# of extra sound frames SB has waiting for it

ch1time         dd      ?               ;time of last write
ch2time         dd      ?
ch3time         dd      ?
ch4time         dd      ?
ch5time         dd      ?
ch1buffptr      dd      ?               ;buff index
ch2buffptr      dd      ?
ch3buffptr      dd      ?
ch4buffptr      dd      ?
ch5buffptr      dd      ?

sregs           db 16h dup (0)
on              db      0
pause           db      0
soundmask       db 11111b               ;sound channel mask

                align 4
wavhandle       dd 0                    ;wav file handle
wavptr          dd ?                    ;wavbuff offset

wavheader       db 'RIFF'
wavfilesize     dd ?
                db 'WAVE'
                db 'fmt '
                dd 18
                dw 1 ;format
                dw 1 ;channel
wavfreq         dd 44100 ;Hz
wavbps          dd 44100 ;bps
wavalign        dw 1 ;blockalign
wavbits         dw 8 ;bitspersample
                dw 0
                db 'data'
wavsize         dd ?
WAVHEADERSIZE   = $-wavheader

channelbuff struc
        time dd ?
        port db ?       
        data db ?
ends

       MAJOR=00000028h         ;113.666*262*60/sbfreq
       MINOR=8496003bh

       PCMVOLSHIFT=24
       MASTERVOL=5500000
     ;   SQUAREVOL=MASTERVOL*10
     ;   TRIANGLEVOL=MASTERVOL*10
     ;   NOISEVOL=MASTERVOL*5
;----------------------------------------------------------------------------
code    ends
        end
