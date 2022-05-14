;----------------------------------------------------------------------------
;undefined data (link this last)
;----------------------------------------------------------------------------
        .386p
code    segment public use32
        assume cs:code,ds:code

        include equates.h

        public codelist
        public input_buff
        public filename
        public startdir
        public tempdir
        public mapperdata
        public memmap
        public kb_table
        public ram
        public oam
        public spritecount
        public spritelist
        public vram
        public spritemask
        public vscreen
        public vscreen2
        public attrib
        public mixbuff
        public freqtbl
        public ch1buff
        public ch2buff
        public ch3buff
        public ch4buff
        public ch5buff
        public tmp
        public the_end

;----------------------------------------------------------------------------

codelist        db      MAXCODES*16 dup (?)     ;game genie code list
input_buff      db      BUFFSIZE dup (?)        ;debug command input buffer
filename        db      256 dup (?)             ;path/filename+'.'
startdir        db      128 dup (?)             ;starting directory
tempdir         db      128 dup (?)             ;for savedir
mapperdata      db      MAPDATASIZE dup (?)     ;used in state saving
memmap          dd      8 dup (?)               ;NES memory map ($2000 granularity)
kb_table        db      100h dup (?)            ;table of keys held
ram             db      10100h dup (?)          ;64k NES RAM
oam             db      100h dup (?)            ;OAM
spritecount     db      256 dup (?)             ;sprites per line
spritelist      dd      8*256 dup (?)           ;holds sprite data for each line.  Y byte is replaced by sprite line #.
vram            db      4000h dup (?)           ;VRAM
spritemask      db      264 dup (?)             ;priority buffer
vscreen         db      264*249 dup (?)         ;offscreen buffer
vscreen2        db      264*241 dup (?)         ;another offscreen buffer
attrib          dd      32*32*4 dup (?)         ;unpacked attrib table
freqtbl         dd      2048 dup (?)            ;NES freq tbl
ch1buff         db      CH1SIZE*8 dup (?)       ;sound channel command buffers
ch2buff         db      CH1SIZE*8 dup (?)       ;(cyclic queue)
ch3buff         db      CH1SIZE*8 dup (?)       ;
ch4buff         db      CH1SIZE*8 dup (?)       ;
ch5buff         db      CH5SIZE*8 dup (?)       ;
tmp             db      TMPSIZE dup (?)         ;scratch area

mixbuff         dd      MIXSIZE dup (?)         ;mixer buffer

                db      400h dup (?)            ;stack goes here
the_end         label byte                      ;end of code segment
;----------------------------------------------------------------------------
code    ends
        end
