        .386p
code    segment public use32
        assume cs:code,ds:code

        public font
        public lookup

_font macro val
        _1=((((val and 16) shr 4) *255) shl 24)
        _2=((((val and 32) shr 5) *255) shl 16)
        _3=((((val and 64) shr 6) *255) shl 8)
        _4= (((val and 128) shr 7) *255)
        _5=((((val and 1) shr 0) *255) shl 24)
        _6=((((val and 2) shr 1) *255) shl 16)
        _7=((((val and 4) shr 2) *255) shl 8)
        _8= (((val and 8) shr 3) *255)
        dd _1+_2+_3+_4,_5+_6+_7+_8
endm

lookup  db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      1 ,2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10,11,12,13,14,15,16
        db      17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32
        db      33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48
        db      49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64
        db      65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80
        db      81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,97,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? 
        db      ? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,? ,96,? ,? ,? ,? 

font    dd 4,0
        _font 00000000b ;??
        _font 11100000b
        _font 10100000b
        _font 10100000b
        _font 10100000b
        _font 11100000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;sp
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 4,0
        _font 01000000b ;!
        _font 11100000b
        _font 11100000b
        _font 01000000b
        _font 00000000b
        _font 01000000b
        _font 00000000b

        dd 4,0
        _font 10100000b ;"
        _font 10100000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;#
        _font 01010000b
        _font 11111000b
        _font 01010000b
        _font 11111000b
        _font 01010000b
        _font 00000000b

        dd 6,0
        _font 00100000b ;$
        _font 01110000b
        _font 10100000b
        _font 01110000b
        _font 00101000b
        _font 01110000b
        _font 00100000b

        dd 5,0
        _font 00000000b ;%
        _font 00000000b
        _font 10010000b
        _font 00100000b
        _font 01000000b
        _font 10010000b
        _font 00000000b

        dd 6,0
        _font 00100000b ;&
        _font 01010000b
        _font 01100000b
        _font 10101000b
        _font 10010000b
        _font 01101000b
        _font 00000000b

        dd 3,0
        _font 01000000b ;'
        _font 10000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 4,0
        _font 00100000b ;(
        _font 01000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 01000000b
        _font 00100000b

        dd 4,0
        _font 10000000b ;)
        _font 01000000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 01000000b
        _font 10000000b

        dd 4,0
        _font 00000000b ;*
        _font 00000000b
        _font 00000000b
        _font 10100000b
        _font 01000000b
        _font 10100000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;+
        _font 00000000b
        _font 01000000b
        _font 11100000b
        _font 01000000b
        _font 00000000b
        _font 00000000b

        dd 3,0
        _font 00000000b ;,
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 01000000b
        _font 10000000b

        dd 4,0
        _font 00000000b ;-
        _font 00000000b
        _font 00000000b
        _font 11100000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;.
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 01000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;/
        _font 00010000b
        _font 00110000b
        _font 01100000b
        _font 11000000b
        _font 10000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;0
        _font 01100000b
        _font 10110000b
        _font 10010000b
        _font 11010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;1
        _font 00100000b
        _font 01100000b
        _font 00100000b
        _font 00100000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;2
        _font 01100000b
        _font 10010000b
        _font 00100000b
        _font 01000000b
        _font 11110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;3
        _font 11100000b
        _font 00010000b
        _font 00100000b
        _font 00010000b
        _font 11100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;4
        _font 00110000b
        _font 01010000b
        _font 10010000b
        _font 11110000b
        _font 00010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;5
        _font 11110000b
        _font 10000000b
        _font 11100000b
        _font 00010000b
        _font 11100000b
        _font 00000000b
    
        dd 5,0
        _font 00000000b ;6
        _font 01100000b
        _font 10000000b
        _font 11100000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;7
        _font 11110000b
        _font 00010000b
        _font 00100000b
        _font 01000000b
        _font 01000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;8
        _font 01100000b
        _font 10010000b
        _font 01100000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;9
        _font 01100000b
        _font 10010000b
        _font 01110000b
        _font 00010000b
        _font 01100000b
        _font 00000000b

        dd 2,0
        _font 00000000b ;:
        _font 00000000b
        _font 10000000b
        _font 00000000b
        _font 00000000b
        _font 10000000b
        _font 00000000b

        dd 3,0
        _font 00000000b ;;
        _font 00000000b
        _font 01000000b
        _font 00000000b
        _font 00000000b
        _font 01000000b
        _font 10000000b

        dd 4,0
        _font 00000000b ;<
        _font 00100000b
        _font 01000000b
        _font 10000000b
        _font 01000000b
        _font 00100000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;=
        _font 00000000b
        _font 11100000b
        _font 00000000b
        _font 11100000b
        _font 00000000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;>
        _font 10000000b
        _font 01000000b
        _font 00100000b
        _font 01000000b
        _font 10000000b
        _font 00000000b

        dd 6,0
        _font 01110000b ;?
        _font 10001000b
        _font 00010000b
        _font 00100000b
        _font 00000000b
        _font 00100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;@
        _font 01110000b
        _font 10010000b
        _font 10110000b
        _font 10000000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;A
        _font 01100000b
        _font 10010000b
        _font 11110000b
        _font 10010000b
        _font 10010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;B
        _font 11100000b
        _font 10010000b
        _font 11100000b
        _font 10010000b
        _font 11100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;C
        _font 01110000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;D
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 11100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;E
        _font 11110000b
        _font 10000000b
        _font 11100000b
        _font 10000000b
        _font 11110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;F
        _font 11110000b
        _font 10000000b
        _font 11100000b
        _font 10000000b
        _font 10000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;G
        _font 01110000b
        _font 10000000b
        _font 10110000b
        _font 10010000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;H
        _font 10010000b
        _font 10010000b
        _font 11110000b
        _font 10010000b
        _font 10010000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;I
        _font 11100000b
        _font 01000000b
        _font 01000000b
        _font 01000000b
        _font 11100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;J
        _font 00111000b
        _font 00010000b
        _font 00010000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;K
        _font 10010000b
        _font 10100000b
        _font 11000000b
        _font 10100000b
        _font 10010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;L
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 11110000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;M
        _font 10001000b
        _font 11011000b
        _font 10101000b
        _font 10001000b
        _font 10001000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;N
        _font 10001000b
        _font 11001000b
        _font 10101000b
        _font 10011000b
        _font 10001000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;O
        _font 01100000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;P
        _font 11100000b
        _font 10010000b
        _font 11100000b
        _font 10000000b
        _font 10000000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;Q
        _font 01110000b
        _font 10001000b
        _font 10001000b
        _font 10011000b
        _font 01111000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;R
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 11100000b
        _font 10010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;S
        _font 01110000b
        _font 10000000b
        _font 01100000b
        _font 00010000b
        _font 11100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;T
        _font 11111000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;U
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;V
        _font 10001000b
        _font 10001000b
        _font 01010000b
        _font 01010000b
        _font 00100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;W
        _font 10001000b
        _font 10001000b
        _font 10001000b
        _font 10101000b
        _font 01010000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;X
        _font 10001000b
        _font 01010000b
        _font 00100000b
        _font 01010000b
        _font 10001000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;Y
        _font 10001000b
        _font 01010000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;Z
        _font 11111000b
        _font 00010000b
        _font 00100000b
        _font 01000000b
        _font 11111000b
        _font 00000000b

        dd 4,0
        _font 11100000b ;[
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 11100000b

        dd 5,0
        _font 00000000b ;\
        _font 10000000b
        _font 11000000b
        _font 01100000b
        _font 00110000b
        _font 00010000b
        _font 00000000b

        dd 4,0
        _font 11100000b ;]
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 11100000b

        dd 4,0
        _font 01000000b ;^
        _font 10100000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;_
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 11110000b
        _font 00000000b

        dd 3,0
        _font 10000000b ;`
        _font 01000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;a
        _font 00000000b
        _font 01100000b
        _font 10010000b
        _font 10010000b
        _font 01101000b
        _font 00000000b

        dd 5,0
        _font 10000000b ;b
        _font 10000000b
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 11100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;c
        _font 00000000b
        _font 01110000b
        _font 10000000b
        _font 10000000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00010000b ;d
        _font 00010000b
        _font 01110000b
        _font 10010000b
        _font 10010000b
        _font 01110000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;e
        _font 00000000b
        _font 01100000b
        _font 10100000b
        _font 11000000b
        _font 01110000b
        _font 00000000b

        dd 4,0
        _font 00100000b ;f
        _font 01000000b
        _font 11100000b
        _font 01000000b
        _font 01000000b
        _font 01000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;g
        _font 00000000b
        _font 01110000b
        _font 10010000b
        _font 01110000b
        _font 00010000b
        _font 11100000b

        dd 5,0
        _font 10000000b ;h
        _font 10000000b
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 00000000b

        dd 2,0
        _font 10000000b ;i
        _font 00000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 00000000b

        dd 4,0
        _font 00100000b ;j
        _font 00000000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 00100000b
        _font 11000000b

        dd 5,0
        _font 10000000b ;k
        _font 10000000b
        _font 10010000b
        _font 10100000b
        _font 11100000b
        _font 10010000b
        _font 00000000b

        dd 2,0
        _font 10000000b ;l
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;m
        _font 00000000b
        _font 11010000b
        _font 10101000b
        _font 10101000b
        _font 10101000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;n
        _font 00000000b
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;o
        _font 00000000b
        _font 01100000b
        _font 10010000b
        _font 10010000b
        _font 01100000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;p
        _font 00000000b
        _font 11100000b
        _font 10010000b
        _font 10010000b
        _font 11100000b
        _font 10000000b

        dd 5,0
        _font 00000000b ;q
        _font 00000000b
        _font 01110000b
        _font 10010000b
        _font 10010000b
        _font 01110000b
        _font 00010000b

        dd 5,0
        _font 00000000b ;r
        _font 00000000b
        _font 10110000b
        _font 11000000b
        _font 10000000b
        _font 10000000b
        _font 00000000b

        dd 4,0
        _font 00000000b ;s
        _font 00000000b
        _font 11100000b
        _font 11000000b
        _font 00100000b
        _font 11100000b
        _font 00000000b

        dd 4,0
        _font 01000000b ;t
        _font 01000000b
        _font 11100000b
        _font 01000000b
        _font 01000000b
        _font 01000000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;u
        _font 00000000b
        _font 10010000b
        _font 10010000b
        _font 10010000b
        _font 01110000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;v
        _font 00000000b
        _font 10001000b
        _font 10001000b
        _font 01010000b
        _font 00100000b
        _font 00000000b

        dd 6,0
        _font 00000000b ;w
        _font 00000000b
        _font 10001000b
        _font 10001000b
        _font 10101000b
        _font 01010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;x
        _font 00000000b
        _font 10010000b
        _font 01100000b
        _font 01100000b
        _font 10010000b
        _font 00000000b

        dd 5,0
        _font 00000000b ;y
        _font 00000000b
        _font 10010000b
        _font 10010000b
        _font 01110000b
        _font 00010000b
        _font 01100000b

        dd 5,0
        _font 00000000b ;z
        _font 00000000b
        _font 11110000b
        _font 00100000b
        _font 01000000b
        _font 11110000b
        _font 00000000b

        dd 4,0
        _font 00100000b ;{
        _font 01000000b
        _font 01000000b
        _font 11000000b
        _font 01000000b
        _font 01000000b
        _font 00100000b

        dd 2,0
        _font 10000000b ;|
        _font 10000000b
        _font 10000000b
        _font 00000000b
        _font 10000000b
        _font 10000000b
        _font 10000000b

        dd 4,0
        _font 10000000b ;}
        _font 01000000b
        _font 01000000b
        _font 01100000b
        _font 01000000b
        _font 01000000b
        _font 10000000b

        dd 5,0
        _font 01010000b ;~
        _font 10100000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b
        _font 00000000b

        dd 9,0
        _font 00000000b ;û
        _font 00000110b
        _font 00001110b
        _font 11011100b
        _font 01110000b
        _font 00100000b
        _font 00000000b

        dd 9,0
        _font 00000000b ;Ä
        _font 00000000b
        _font 11100000b
        _font 00111000b
        _font 00001100b
        _font 00000000b
        _font 00000000b

code    ends
        end

