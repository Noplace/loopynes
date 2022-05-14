        .386p
code    segment public use32
        assume cs:code,ds:code

        include data.h
        include equates.h
        include file.h
        include main.h
        include memory.h
        include vga.h
        include macros.h
        include kb.h
        include 6502.h
        include ppu.h
        include io.h
        include empty.h
        include sb.h
        
        public  prof0
        public  prof1
        public  prof2
        public  prof3
        public  prof4
        public  prof5
        public  prof6
        public  prof7
if DEBUG
        public  debug
        public  _trace
        public  break_addr
        public  break_frame
        public  break_line
        public  jsrminaddr
        public  jsrmaxaddr
        public  debugmsg
        public  msg00
        public  msg02
        public  msg03
        public  msg04
        public msg05
        public msg06
        public msg15
        public  msg41
        public  msg42
        public  msg43
        public  msg44
        public  msg45
        public  msg46
        public  msg47
        public  msg48
        public  tFRAME
        public  tVRET
        public  tCTRL0w
        public  tCTRL1w
        public  tSTATr
        public  tSCROLLw
        public  tOAMADDRw
        public  tOAMDMAw
        public  tVMADDRw
        public  tVMDATAr
        public  tMMC0
        public  tMMC1
        public  tMMC2
        public  tMMC3
        public  tMMC4
        public  tMMC5
        public  tIRQ
        public  tSTRIKE
;----------------------------------------------------------------------------
debug:;         debugger entry point
;----------------------------------------------------------------------------
        save6502
        call sb_pause
        mov eax,[_PC]
        mov [unassemble_addr],eax       ;new unassemble address

        cmp [vgamode],0
        je debug0
        call textmode                   ;reset display if not in text mode
debug0:
        call kb_clear                   ;reset keyboard stuff
        mov esi,[debugmsg]
        call putstr                     ;show debugger entry msg
        call register                   ;show registers
        and [int_flags],not DEBUGALL    ;clear all debug ints
        ;fall thru to prompt:
        ;  |
        ;  |
        ;  
;----------------------------------------------------------------------------
prompt:;        read in next debug command
;----------------------------------------------------------------------------
        mov al,'-'
        call putch                      ;show prompt

        mov esi,offset input_buff
prompt1:
        call getch                      ;read in next char
        cmp al,''                      
        je prompt4                      ;take care of up arrow
        cmp al,8
        je prompt6                      ;take care of backspace
        cmp al,13
        je prompt3                      ;take care of CR
        cmp al,27
        je prompt5                      ;take care of ESC
        cmp al,9
        je prompt9                      ;take care of tab

prompt2:cmp esi,(offset input_buff)+BUFFSIZE-1   ;buffer full?
        jae prompt1                     ;  ^^^ (leave space for string terminator)
        mov [esi],al                    ;add char to buffer
        inc esi
        call putch                      ;display char
        jmp prompt1                     ;get next char

prompt6:cmp esi,offset input_buff
        je prompt1                      ;skip if empty string
        dec esi                         ;back up buffer ptr
        call putch
        jmp prompt1

prompt4:mov ecx,[strlen]
        add ecx,offset input_buff       ;cx points to 1st empty char.
p4:     cmp esi,ecx
        jae prompt1                     ;quit if end of buffer
        mov al,[esi]                    ;grab next char from buff
        call putch                      ;display char
        inc esi                         ;update buff ptr
        jmp p4

prompt5:call newline
        jmp prompt                      ;reset string

prompt9:mov esi,[strlen]
        add esi,offset input_buff       ;move esi to end of last command
        jmp prompt3                     ;and go to CR

prompt3:call newline
        cmp esi,offset input_buff
        je prompt                       ;skip if nothing was entered
        mov byte ptr [esi],0            ;null terminate string
        sub esi,offset input_buff
        mov [strlen],esi                ;save string length
 
        mov al,[input_buff]             ;get 1st char
        mov esi,offset cmdtable
prompt7:cmp byte ptr [esi],al           ;this a valid debug command?
        je prompt8
        add esi,8
        cmp esi,offset cmdtableEND
        jb prompt7                      ;keep looking until nothing left to check
prompt8:call [esi+4]                    ;call debug command routine
        jmp prompt                      ;read in next command
;----------------------------------------------------------------------------
txt2hex:;       translate ascii to hex
;
;       in:
;               ESI=ptr to start of string
;       out:
;               EAX,ESI=?
;               EDX: #
;----------------------------------------------------------------------------
        xor eax,eax
        xor edx,edx
        
txt0:   mov al,[esi]                    ;grab next char
        cmp al,':'
        jb txt1
        cmp al,'A'
        jb txt3                         ;ignore bad values
        sub al,7

txt1:   sub al,'0'
        cmp al,15                       ;convert to hex
        ja txt3                         ;ignore out of range values
        shl edx,4
        add edx,eax                     ;add on value to current sum

txt3:   mov al,[esi]                    ;grab char again
        inc esi                         ;increment ptr
        cmp al,0
        je txt4                         ;quit at end of line
        cmp al,' '
        jne txt0                        ;or end of word

txt4:   ret
;----------------------------------------------------------------------------
sysinfo:;
;----------------------------------------------------------------------------        
        mov eax,[framecount]
        call puthex16
        mov al,':'
        call putch
        mov eax,[scanline]
        call puthex16
        call newline

        mov eax,[prof0]
        call puthex32
        call space
        mov eax,[prof1]
        call puthex32
        call space
        mov eax,[prof2]
        call puthex32
        call space
        mov eax,[prof3]
        call puthex32
        call space
        mov eax,[prof4]
        call puthex32
        call space
        mov eax,[prof5]
        call puthex32
        call space
        mov eax,[prof6]
        call puthex32
        call space
        mov eax,[prof7]
        call puthex32
        call newline

        mov esi,offset msg48
        call putstr
        mov al,[ctrl0]
        call puthex8

        mov esi,offset msg49
        call putstr
        mov al,[ctrl1]
        call puthex8

        mov esi,offset msg50
        call putstr
        mov ax,word ptr [vmaddr]
        call puthex16

        mov esi,offset msg51
        call putstr
        mov ax,word ptr [vmaddr2]
        call puthex16

        mov esi,offset msg52
        call putstr
        mov al,byte ptr [bgskip]
        call puthex8

        call newline

        mov eax,[linecycles]
        sub eax,[cycles]
        call puthex32
        call newline

        mov esi,offset msg06
        call putstr
        xor ebp,ebp                             ;show rom mapping
        mov edx,8000h
        sub edx,[rom_ptr]
si00:   mov eax,[memmap+4*4+ebp*4]
        add eax,edx
        shr eax,13 ;$2000
        call puthex8
        call space
        add edx,2000h
        inc ebp
        cmp ebp,4
        jb si00
        call newline

        ret
;----------------------------------------------------------------------------
dump:;                          ;($0800-$5FFF gives invalid data)
;----------------------------------------------------------------------------
        mov edx,[dump_addr]             ;get address to dump
        cmp [strlen],3
        jb dump1                        ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get new address to dump
dump1:  mov esi,edx

        mov edi,16                      ;dump 16 lines:
dump2:  mov eax,esi
        call puthex16
        mov al,':'
        call putch                              ;show address
        call space

        mov ebp,16
dump3:  call rdmem                              ;16 bytes per line
        call puthex8                            ;show hex val
        call space
        dec ebp
        jnz dump3

        sub esi,16
        mov ebp,16
dump4:  call rdmem
        call putch2
        dec ebp
        jnz dump4

        call newline
        dec edi
        jnz dump2
        
        mov word ptr [dump_addr],si             ;save new dump address
        
        ret

rdmem:;- - - - - - - - -
;  mov ecx,esi
;  mov al,byte ptr [spritelist+ecx]
;  inc esi
;  ret
        movzx ebx,si
        mov ecx,ebx
        shr ebx,13
        add ecx,[memmap+ebx*4]
        mov al,[ecx]
        inc esi
        ret
;----------------------------------------------------------------------------
vdump:;
;----------------------------------------------------------------------------
        mov edx,[vdump_addr]            ;get address to dump
        cmp [strlen],3
        jb vdump1                       ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get new address to dump
vdump1: mov esi,edx
        and esi,03fffh

        mov edi,16                      ;dump 16 lines:
vdump2: mov eax,esi
        call puthex16
        mov al,':'
        call putch                      ;show address
        call space

        mov ebp,16
vdump3: call vreadmem                   ;16 bytes per line
        call puthex8                    ;show hex val
        call space
        dec ebp
        jnz vdump3

        sub esi,16
        and esi,03fffh
        mov ebp,16
vdump4: call vreadmem
        call putch2
        dec ebp
        jnz vdump4

        call newline
        dec edi
        jnz vdump2
        
        mov [vdump_addr],esi            ;save new vdump address
        
        ret

vreadmem:;- - - - - - - - -
        mov al,[vram+esi]
        inc esi
        and esi,03fffh
        ret
;----------------------------------------------------------------------------
odump:;
;----------------------------------------------------------------------------
        xor esi,esi                     ;esi=data ptr

        mov edi,16                      ;dump 16 lines:
odump2: mov eax,esi
        call puthex16
        mov al,':'
        call putch                      ;show address
        call space

        mov ebp,16
odump3: call oreadmem                   ;16 bytes per line
        call puthex8                    ;show hex val
        call space
        dec ebp
        jnz odump3

        sub esi,16
        mov ebp,16
odump4: call oreadmem
        call putch2
        dec ebp
        jnz odump4

        call newline
        dec edi
        jnz odump2
        
        ret

oreadmem:;- - - - - - - - -
        mov al,[oam+esi]
        inc esi
        ret
;----------------------------------------------------------------------------
register:;
;----------------------------------------------------------------------------
        mov al,'A'
        mov cl,byte ptr [_P_A]
        call reg8

        mov al,'X'
        mov cl,byte ptr [_X_Y+1]
        call reg8

        mov al,'Y'
        mov cl,byte ptr [_X_Y]
        call reg8

        mov al,'S'
        mov cl,byte ptr [_S]
        call reg8

        mov al,'P'
        call putch
        mov al,'C'
        call putch
        mov al,'='
        call putch
        mov eax,[_PC]
        call puthex16
        call space
        call space

        mov esi,[cursor]
        shl esi,1
        add esi,[text_ptr]
        xor ebx,ebx
              
        mov al,'N'
        mov bl,N
        call flag
        mov al,'V'
        mov bl,V
        call flag
        mov al,'D'
        mov bl,D
        call flag
        mov al,'I'
        mov bl,I
        call flag
        mov al,'Z'
        mov bl,Z
        call flag
        mov al,'C'
        mov bl,C
        call flag
        call newline

        mov esi,[_PC]
        call disasm                     ;show next instruction

        ret
;- - - - - - - - - - - - - - -
reg8:   call putch
        mov al,'='
        call putch
        mov al,cl
        call puthex8
        call space
        call space
        ret

flag:   test byte ptr [_P_A+1],bl
        setz ah
        add ah,0111b
        mov [esi],ax
        inc esi
        inc esi
        ret
;----------------------------------------------------------------------------
disasm:;        disassemble instruction at ESI and increment ESI to next
;               instruction
;----------------------------------------------------------------------------
        push [cursor]                           ;(save this for later..)
        push esi

        mov eax,esi
        call puthex16
        mov al,':'
        call putch                              ;show address
        call space

        mov eax,esi
        mov edi,esi               
        shr eax,13
        add edi,[memmap+eax*4]                ;edi=instruction ptr

        movzx ebx,byte ptr [edi]                ;grab instruction
        mov bl,[opcode+ebx*4+3]
        call [optype+ebx*4]                     ;handle opcode type

        pop ebx
        pop eax
        cmp ebx,[_PC]                           ;check if this address=PC
        jne di0

        shl eax,1                               ;highlight address
        add eax,[text_ptr]
        or dword ptr [eax],0f000f00h
        or dword ptr [eax+4],0f000f00h
di0:
        call newline
        ret

;- - - - - - - - - - - - - - - - -

imp:                                            ;implied
imm:                                            ;immediate      #$xx
abs:                                            ;absolute       $xxxx
zp:                                             ;zero page      $xx (also BRK)
absX:                                           ;abs idx X      $xxxx,X
absY:                                           ;abs idx Y      $xxxx,Y
zpX:                                            ;zero idx X     $xx,X
ind:                                            ;ind            ($xxxx)
indX:                                           ;idx ind        ($xx,X)
indY:                                           ;ind idx        ($xx),Y
zpY:                                            ;zero idx Y     $xx,Y
        push esi
        mov ch,[opsize+ebx]
        lea eax,[optail+ebx*4]
        push eax
        push dword ptr [opsize+ebx]
        lea eax,[ophead+ebx*4]
        push eax
        call dmp
        pop esi
        call putstr
        mov eax,[edi+1]
        pop ebx
        and ebx,0fh
        call [puthex+ebx*4]
        pop esi
        call putstr
        pop esi
        add si,bx
        ret
rel:                                            ;relative       $xx
        mov ch,2
        call dmp
        mov al,'$'
        call putch
        lea eax,[esi+2]
        movsx ebx,byte ptr [edi+1]
        add eax,ebx
        call puthex16
        add si,2
        ret

;- - - - - - - - - - - - - - - - -

dmp:    push edi                ;do hex dump+write mnemonic
        mov ebp,8               ;CH=instruction size
dmp0:   mov al,[edi]
        call puthex8
        inc edi
        dec ebp
        dec ebp
        dec ch
        jnz dmp0
dmp1:   call space
        dec ebp
        jnz dmp1
        pop edi

        xor ebx,ebx             ;write mnemonic
        mov bl,[edi]
        mov al,[opcode+ebx*4]
        call putch
        mov al,[opcode+ebx*4+1]
        call putch
        mov al,[opcode+ebx*4+2]
        call putch
        call space
        call space
        ret

;(sorted by optype)

opsize  db      1,2,3,2,3,3,2,3,2,2,2,2
ophead  dd      0,'$#','$','$','$','$','$','$(','$(','$(',0,'$'
optail  dd      0,0,0,0,'X,','Y,','X,',')',')X,','Y,)',0,'Y,'
puthex  dd      void,void,puthex8,puthex16
;----------------------------------------------------------------------------
unassemble:;
;----------------------------------------------------------------------------
        mov edx,[unassemble_addr]       ;get starting address
        cmp [strlen],3
        jb un1                          ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get new address
un1:    mov esi,edx                     ;ESI=address

        mov ecx,32                      ;unassemble 32 instructions
un2:    push ecx
        call disasm
        pop ecx
        dec ecx
        jnz un2

        mov [unassemble_addr],esi       ;save new address
        ret
;----------------------------------------------------------------------------
go:;
;----------------------------------------------------------------------------
        call sb_resume
        mov [debugmsg],offset msg00                     ;clear debug msg

        call gfxmode                    ;restore screen
        mov [palchange],-1              ;restore palette

        cmp [strlen],3
        jb go1                          ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get breakpoint
        mov [break_addr],edx            ;save address
        or [int_flags],DEBUG1+DEBUG3    ;set step+breakpoint interrupt
go1:
        restore6502

        mov eax,[framecount]            ;set timer
        mov [ticks],eax
        pop eax                         ;kill return address
        fetch 0                         ;resume execution
;----------------------------------------------------------------------------
jsrtrap:;
;----------------------------------------------------------------------------
        call sb_resume
        mov [debugmsg],offset msg00                     ;clear debug msg

;        call kb_clear                   ;reset keyboard
        call gfxmode                    ;restore screen
        mov [palchange],-1              ;restore palette

        mov esi,offset input_buff+2
        call txt2hex
        mov [jsrminaddr],edx

        mov esi,offset input_buff+7
        call txt2hex                    ;get breakpoint
        mov [jsrmaxaddr],edx            ;save address

        restore6502
        mov eax,[framecount]            ;set timer
        mov [ticks],eax
        pop eax                         ;kill return address
        fetch 0                         ;resume execution
;----------------------------------------------------------------------------
gframe:
;----------------------------------------------------------------------------        
        call sb_resume
        mov [debugmsg],offset msg00                     ;clear debug msg

;        call kb_clear                   ;reset keyboard
        call gfxmode                    ;restore screen
        mov [palchange],-1              ;restore palette

        cmp [strlen],3
        jb gf0                          ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get breakpoint
        mov [break_frame],edx           ;save frame
        or [int_flags],DEBUG4           ;set frame interrupt
gf0:
        restore6502
        mov eax,[framecount]            ;set timer
        mov [ticks],eax
        pop eax                         ;kill return address
        fetch 0                         ;resume execution
;----------------------------------------------------------------------------
gline:
;----------------------------------------------------------------------------        
        mov [debugmsg],offset msg00                     ;clear debug msg

;        call kb_clear                   ;reset keyboard
        call gfxmode                    ;restore screen
        mov [palchange],-1              ;restore palette

        cmp [strlen],3
        jb gl0                          ;skip if no extra params
        mov esi,offset input_buff+2
        call txt2hex                    ;get breakpoint
        mov [break_line],edx
        or [int_flags],DEBUG5
gl0:
        restore6502
        mov eax,[framecount]            ;set timer
        mov [ticks],eax
        pop eax                         ;kill return address
        fetch 0                         ;resume execution
;----------------------------------------------------------------------------
proceed:
;----------------------------------------------------------------------------
        mov [debugmsg],offset msg00                     ;clear debug msg

;        cmp [strlen],3
;        jb pr1                          ;skip if no extra params
;        mov esi,offset input_buff+2
;        call txt2hex                    ;get address
;        mov esi,edx
;        and esi,0ffffh
;        setlastbank
;        mov [_PC],esi
;        jmp pr2

        restore6502
        or [int_flags],DEBUG1+DEBUG2    ;set step+debug interrupt
        mov eax,[framecount]            ;set timer
        mov [ticks],eax
        pop eax                         ;kill return address
        fetch 0                         ;execute 1 instruction
;----------------------------------------------------------------------------
flip:;          show screen
;----------------------------------------------------------------------------
        call gfxmode
        call setnespal

        mov edi,[scanline]
        mov eax,[scanline]
        shl edi,8
        lea edi,[edi+eax*8+offset vscreen+8+264]
        mov eax,0f0f0f0f0h
fl0:    mov [edi],eax
        add edi,4
        cmp edi,offset vscreen+8+264*232
        jb fl0

        call [pageflip]
        call getch
        call textmode
        ret
;----------------------------------------------------------------------------
irq:;
;----------------------------------------------------------------------------
        or [int_flags],IRQ
        ret
;----------------------------------------------------------------------------
help:;
;----------------------------------------------------------------------------
        mov esi,offset cmdlist
        call putstr
        ret
;----------------------------------------------------------------------------
invalid:;
;----------------------------------------------------------------------------
        mov esi,offset msg01
        call putstr
        ret
;----------------------------------------------------------------------------
quit:
;----------------------------------------------------------------------------
        jmp _exit
;----------------------------------------------------------------------------
_trace:;        output program trace to file (dont call directly, see DEBUG.H)
;
;               in:
;                       ESI=trace code
;                       BL=value
;----------------------------------------------------------------------------
        mov edi,offset tmp                      ;initialize trace ptr
trace0:
        mov al,[esi]                            ;write trace code
        inc esi
        mov [edi],al
        inc edi
        or  al,al
        jnz trace0
        dec edi

        mov ecx,ebx
        and ebx,0ffh                            ;write BL
        shr bl,4        
        mov al,[hextable+ebx]
        mov [edi],al
        and ecx,0fh
        mov al,[hextable+ecx]
        mov [edi+1],al
        mov byte ptr [edi+2],' '
        add edi,3

        mov ecx,[scanline]                      ;write scanline
        mov ebx,ecx
        shr ebx,8
        mov al,[hextable+ebx]
        mov [edi],al
        mov ebx,ecx
        and ebx,0f0h
        shr ebx,4
        mov al,[hextable+ebx]
        mov [edi+1],al
        and ecx,0fh
        mov al,[hextable+ecx]
        mov [edi+2],al
        mov byte ptr [edi+3],'.'
        mov ebx,[linecycles]
        sub ebx,[cycles]
        and ebx,0f0h                            ;write cycle
        shr bl,4        
        mov al,[hextable+ebx]
        mov [edi+4],al
        mov ebx,[linecycles]
        sub ebx,[cycles]
        and ebx,0fh
        mov al,[hextable+ebx]
        mov [edi+5],al
        mov byte ptr [edi+6],0dh
        mov byte ptr [edi+7],0ah
        add edi,8

        sub edi,offset tmp
        push edi

        cmp [tracehandle],0                     ;need to create file?
        jne trace2
        mov edx,offset tracename
        call f_create
        jc error2
        mov [tracehandle],ebx
trace2:
        pop ecx
        mov edx,offset tmp
        mov ebx,[tracehandle]
        call f_write                            ;write to file
        ret

        align 4
tracehandle dd 0
;----------------------------------------------------------------------------
                align   4

hextable        db      '0123456789ABCDEF'

dump_addr       dd      ?                       ;address for next dump command
vdump_addr      dd      ?                       ;address for next vram dump
unassemble_addr dd      ?                       ;address for next unassemble
break_addr      dd      ?                       ;breakpoint address
break_frame     dd      ?                       ;breakpoint frame
break_line      dd      ?                       ;breakpoint scanline
jsrminaddr      dd      -1                      ;JSR trap min addr
jsrmaxaddr      dd      ?                       ;JSR trap max addr
debugmsg        dd      msg00                   ;shown on debugger entry

strlen          dd      ?                       ;length of last command

opcode          db      'BRK',03,'ORA',8,'???',0,'???',0,'???',0,'ORA',3,'ASL',03,'???',0 ;0
                db      'PHP',00,'ORA',1,'ASL',0,'???',0,'???',0,'ORA',2,'ASL',02,'???',0
                db      'BPL',10,'ORA',9,'???',0,'???',0,'???',0,'ORA',6,'ASL',06,'???',0 ;1
                db      'CLC',00,'ORA',5,'???',0,'???',0,'???',0,'ORA',4,'ASL',04,'???',0
                db      'JSR',02,'AND',8,'???',0,'???',0,'BIT',3,'AND',3,'ROL',03,'???',0 ;2
                db      'PLP',00,'AND',1,'ROL',0,'???',0,'BIT',2,'AND',2,'ROL',02,'???',0
                db      'BMI',10,'AND',9,'???',0,'???',0,'???',0,'AND',6,'ROL',06,'???',0 ;3
                db      'SEC',00,'AND',5,'???',0,'???',0,'???',0,'AND',4,'ROL',04,'???',0
                db      'RTI',00,'EOR',8,'???',0,'???',0,'???',0,'EOR',3,'LSR',03,'???',0 ;4
                db      'PHA',00,'EOR',1,'LSR',0,'???',0,'JMP',2,'EOR',2,'LSR',02,'???',0
                db      'BVC',10,'EOR',9,'???',0,'???',0,'???',0,'EOR',6,'LSR',06,'???',0 ;5
                db      'CLI',00,'EOR',5,'???',0,'???',0,'???',0,'EOR',4,'LSR',04,'???',0
                db      'RTS',00,'ADC',8,'???',0,'???',0,'???',0,'ADC',3,'ROR',03,'???',0 ;6
                db      'PLA',00,'ADC',1,'ROR',0,'???',0,'JMP',7,'ADC',2,'ROR',02,'???',0
                db      'BVS',10,'ADC',9,'???',0,'???',0,'???',0,'ADC',6,'ROR',06,'???',0 ;7
                db      'SEI',00,'ADC',5,'???',0,'???',0,'???',0,'ADC',4,'ROR',04,'???',0
                db      '???',00,'STA',8,'???',0,'???',0,'STY',3,'STA',3,'STX',03,'???',0 ;8
                db      'DEY',00,'???',0,'TXA',0,'???',0,'STY',2,'STA',2,'STX',02,'???',0
                db      'BCC',10,'STA',9,'???',0,'???',0,'STY',6,'STA',6,'STX',11,'???',0 ;9
                db      'TYA',00,'STA',5,'TXS',0,'???',0,'???',0,'STA',4,'???',00,'???',0
                db      'LDY',01,'LDA',8,'LDX',1,'???',0,'LDY',3,'LDA',3,'LDX',03,'???',0 ;A
                db      'TAY',00,'LDA',1,'TAX',0,'???',0,'LDY',2,'LDA',2,'LDX',02,'???',0
                db      'BCS',10,'LDA',9,'???',0,'???',0,'LDY',6,'LDA',6,'LDX',11,'???',0 ;B
                db      'CLV',00,'LDA',5,'TSX',0,'???',0,'LDY',4,'LDA',4,'LDX',05,'???',0
                db      'CPY',01,'CMP',8,'???',0,'???',0,'CPY',3,'CMP',3,'DEC',03,'???',0 ;C
                db      'INY',00,'CMP',1,'DEX',0,'???',0,'CPY',2,'CMP',2,'DEC',02,'???',0
                db      'BNE',10,'CMP',9,'???',0,'???',0,'???',0,'CMP',6,'DEC',06,'???',0 ;D
                db      'CLD',00,'CMP',5,'???',0,'???',0,'???',0,'CMP',4,'DEC',04,'???',0
                db      'CPX',01,'SBC',8,'???',0,'???',0,'CPX',3,'SBC',3,'INC',03,'???',0 ;E
                db      'INX',00,'SBC',1,'NOP',0,'???',0,'CPX',2,'SBC',2,'INC',02,'???',0
                db      'BEQ',10,'SBC',9,'???',0,'???',0,'???',0,'SBC',6,'INC',06,'???',0 ;F
                db      'SED',00,'SBC',5,'???',0,'???',0,'???',0,'SBC',4,'INC',04,'???',0
optype          dd      imp,imm,abs,zp,absX,absY,zpX,ind,indX,indY,rel,zpY         ;disasm routines for instruction types

cmdlist         db      'dump           D [addr]',13
                db      'VRAM dump      V [addr]',13
                db      'OAM dump       O',13
                db      'unassemble     U [addr]',13
                db      'go             G [breakpoint]',13
                db      'JSR trap       J minaddr maxaddr',13
                db      'proceed        P',13
                db      'goto frame     A frame',13
                db      'goto line      L line',13
                db      'trigger IRQ    I',13
                db      'register       R',13
                db      'flip screen    F',13
                db      'system info    S',13
                db      'help           H,?',13
                db      'quit           Q',13
                db      0

cmdtable        dd      'D',dump
                dd      'V',vdump
                dd      'O',odump
                dd      'U',unassemble
                dd      'G',go
                dd      'J',jsrtrap
                dd      'P',proceed
                dd      'A',gframe
                dd      'L',gline
                dd      'I',irq
                dd      'R',register
                dd      'F',flip
                dd      'S',sysinfo
                dd      '?',help
                dd      'H',help
                dd      'Q',quit
cmdtableEND     dd      0,invalid               ;end of table- invalid command

msg00           db      0
msg01           db      "Invalid command.  Type '?' for help.",13,0
msg02           db      'VRAM read outside VBL',13,0
msg03           db      'VRAM write outside VBL',13,0
msg04           db      'Mapper error.',13,0
msg05           db      'Sound write',13,0
msg06           db      'rom: ',0
msg15           db      'JSR trap',13,0
msg41           db      "Type '?' for help.",13,13,0
msg42           db      'Illegal opcode.',13,0
msg43           db      'Bad memory read.',13,0
msg44           db      'Bad memory write.',13,0
msg45           db      'Bad VRAM write.',13,0
msg46           db      'Generic error message.',13,0
msg47           db      'Unsupported feature.',13,0
msg48           db      'cr0 ',0
msg49           db      ' cr1 ',0
msg50           db      ' vaddr ',0
msg51           db      ' vaddr2 ',0
msg52           db      ' skip ',0

tFRAME          db      '--TOP--- ',0
tVRET           db      '--VRET-- ',0
tCTRL0w         db      'CTRL0w   ',0
tCTRL1w         db      'CTRL1w   ',0
tSTATr          db      'STATr    ',0
tSCROLLw        db      'SCROLLw  ',0
tOAMADDRw       db      'OAMADDRw ',0
tOAMDMAw        db      'OAMDMAw  ',0
tVMADDRw        db      'VMADDRw  ',0
tVMDATAr        db      'VMDATAr  ',0
tMMC0           db      'MMC0     ',0
tMMC1           db      'MMC1     ',0
tMMC2           db      'MMC2     ',0
tMMC3           db      'MMC3     ',0
tMMC4           db      'MMC4     ',0
tMMC5           db      'MMC5     ',0
tIRQ            db      'IRQ      ',0
tSTRIKE         db      '-STRIKE--',0
tracename       db      'TRACE',0

endif
                align   4

prof0           dd      ?
prof1           dd      ?
prof2           dd      ?
prof3           dd      ?
prof4           dd      ?
prof5           dd      ?
prof6           dd      ?
prof7           dd      ?

;----------------------------------------------------------------------------
code    ends
        end
