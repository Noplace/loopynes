DEBUG           = 0 ;2 for onscreen prof* vars
SAFE            = 1
;------------------------------------------------------processor status flags
;                                                      (80x86 encoded format)
C               equ     00000001b       ;carry
Z               equ     01000000b       ;zero
I               equ     00000100b       ;IRQ disable
D               equ     00000010b       ;decimal
B               equ     00010000b       ;break flag
R               equ     00100000b       ;reserved (locked at 1)
V               equ     00001000b       ;overflow
N               equ     10000000b       ;negative
;-----------------------------------------------------------[int_flags] flags
RES             equ     0000000000000001b       ;RES interrupt
NMI             equ     0000000000000010b       ;NMI interrupt
IRQ             equ     0000000000000100b       ;IRQ interrupt
DEBUG1          equ     1000000000000000b       ;debugger- step over other debug interrupts
DEBUG2          equ     0100000000000000b       ;debugger- enter debugger
DEBUG3          equ     0010000000000000b       ;debugger- check breakpoint
DEBUG4          equ     0001000000000000b       ;frame breakpoint
DEBUG5          equ     0000100000000000b       ;line breakpoint

DEBUGALL        equ     DEBUG1+DEBUG2+DEBUG3+DEBUG4+DEBUG5
;----------------------------------------------------------------------------
IRQ_VECTOR      equ     0fffeh                  ; IRQ interrupt vector address
BRK_VECTOR      equ     0fffeh                  ; BRK interrupt vector address
RES_VECTOR      equ     0fffch                  ; RESET interrupt vector address
NMI_VECTOR      equ     0fffah                  ; NMI interrupt vector address
;-----------------------------------------------------------[cartflags] flags
MIRROR          equ     00000000000000000000000000000001b       ;horizontal mirroring
SRAM            equ     00000000000000000000000000000010b       ;SRAM present
TRAINER         equ     00000000000000000000000000000100b       ;trainer present
SCREEN4         equ     00000000000000000000000000001000b       ;4 screen layout
VS              equ     00000000000000000000000000010000b       ;VS arcade
;----------------------------------------------------------------------------
CYCLESPERLINE   equ     113
FRONT           equ     (CYCLESPERLINE-HBLANK)/4          ;cycle counts
MIDDLE          equ     CYCLESPERLINE-FRONT-HBLANK
HBLANK          equ     28
FRACTION        equ     0aaaaaaabh      ;.66666666..
;--------------------------------------------------------------keyboard stuff
KB_ESC          equ     1
KB_1            equ     2
KB_2            equ     3
KB_3            equ     4
KB_4            equ     5
KB_5            equ     6
KB_6            equ     7
KB_7            equ     8
KB_8            equ     9
KB_9            equ     10
KB_0            equ     11
KB_EQ           equ     13
KB_A            equ     30
KB_B            equ     48
KB_C            equ     46
KB_D            equ     32
KB_E            equ     18
KB_F            equ     33
KB_G            equ     34
KB_H            equ     35
KB_I            equ     23
KB_J            equ     36
KB_K            equ     37
KB_L            equ     38
KB_M            equ     50
KB_N            equ     49
KB_O            equ     24
KB_P            equ     25
KB_Q            equ     16
KB_R            equ     19
KB_S            equ     31
KB_T            equ     20
KB_U            equ     22
KB_V            equ     47
KB_W            equ     17
KB_X            equ     45
KB_Y            equ     21
KB_Z            equ     44
KB_F1           equ     59
KB_F2           equ     60
KB_F3           equ     61
KB_F4           equ     62
KB_F5           equ     63
KB_F6           equ     64
KB_F7           equ     65
KB_F8           equ     66
KB_F9           equ     67
KB_F10          equ     68
KB_F11          equ     87
KB_F12          equ     88
KB_PGUP         equ     201
KB_PGDN         equ     209
KB_INSERT       equ     210
KB_DELETE       equ     211
KB_HOME         equ     199
KB_END          equ     207
KB_LWIN         equ     219
KB_LSHIFT       equ     42
KB_RSHIFT       equ     54
KB_LALT         equ     56
KB_RALT         equ     184
KB_LCTRL        equ     29
KB_RCTRL        equ     157
KB_UP           equ     200
KB_DOWN         equ     208
KB_LEFT         equ     203
KB_RIGHT        equ     205
KB_UPPAD        equ     72
KB_DOWNPAD      equ     80
KB_LEFTPAD      equ     75
KB_RIGHTPAD     equ     77
KB_5PAD         equ     76
KB_BREAK        equ     197
KB_CTRLBREAK    equ     198
KB_DEL          equ     211
KB_TAB          equ     15
KB_ENTER        equ     28
KB_PRINTSCR     equ     183
KB_SPACE        equ     57
KB_TILDE        equ     41

EXTEND          equ     00000001b               ;extended key being read
EXTEND2         equ     00000010b               ;double extended (break)
;-------------------------------------------------------------------PPU flags
CR0_SPRITESRC   equ     00001000b               ;sprite tile src
CR0_BGSRC       equ     00010000b               ;BG tile src
CR0_8X16        equ     00100000b               ;8x16 sprites
CR0_NMI         equ     10000000b               ;NMI enable

CR1_MONO        equ     00000001b
CR1_BGCLIP      equ     00000010b
CR1_OBJCLIP     equ     00000100b
CR1_BG          equ     00001000b               ;background enable
CR1_OBJ         equ     00010000b               ;sprite enable

STAT_STRIKE     equ     01000000b               ;sprite0 collision
STAT_VBL        equ     10000000b

OBJ_BG          equ     00100000b               ;sprite attributes
OBJ_HFLIP       equ     01000000b
OBJ_VFLIP       equ     10000000b
;----------------------------------------------------------------------------
BUFFSIZE        equ     256                     ;debug input buffer size
MAPDATASIZE     equ     128
VIDMODES        equ     3
TMPSIZE         equ     8000h                   ;size of temp area
MAXCODES        equ     64                      ;max # of GG codes

MIXSIZE         equ     44100/60                ;#samples that mixer() deals with at one time
DMABUFFERS      equ     5 

CH1SIZE         equ     40h                     ;channel buffer size
CH5SIZE         equ     400h                    ;(#records,not bytes)
;----------------------------------------------------------------------------
