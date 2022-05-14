extrn   debug:near
extrn   _trace:near
extrn   break_addr:dword
extrn   break_frame:dword
extrn   break_line:dword
extrn   jsrminaddr:dword
extrn   jsrmaxaddr:dword
extrn   debugmsg:dword
extrn   msg00:byte
extrn   msg02:byte
extrn   msg03:byte
extrn   msg04:byte
extrn msg05:byte
extrn msg06:byte
extrn msg15:byte
extrn   msg41:byte
extrn   msg42:byte
extrn   msg43:byte
extrn   msg44:byte
extrn   msg45:byte
extrn   msg46:byte
extrn   msg47:byte
extrn   msg48:byte
extrn   prof0:dword
extrn   prof1:dword
extrn   prof2:dword
extrn   prof3:dword
extrn   prof4:dword
extrn   prof5:dword
extrn   prof6:dword
extrn   prof7:dword

extrn   tFRAME:byte
extrn   tVRET:byte
extrn   tCTRL0w:byte
extrn   tCTRL1w:byte
extrn   tSTATr:byte
extrn   tSCROLLw:byte
extrn   tOAMADDRw:byte
extrn   tOAMDMAw:byte
extrn   tVMADDRw:byte
extrn   tVMDATAr:byte
extrn   tMMC0:byte
extrn   tMMC1:byte
extrn   tMMC2:byte
extrn   tMMC3:byte
extrn   tMMC4:byte
extrn   tMMC5:byte
extrn   tIRQ:byte
extrn   tSTRIKE:byte

trace macro a,b
    local _addr
    if DEBUG
        kbtest(KB_F11)
        jz _addr
        pushad
        mov bl,b
        mov esi,offset a
        call _trace
        popad
_addr:
    endif
endm
