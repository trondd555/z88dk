;
;       Z88 Graphics Functions - Small C+ stubs
;
;       Written around the Interlogic Standard Library
;
;       Stubs Written by D Morris - 30/9/98
;
;
;	$Id: draw.asm,v 1.3 2001-04-18 13:21:37 stefano Exp $
;


                XLIB    draw
                LIB     swapgfxbk
                XREF	swapgfxbk1

                LIB     line
                LIB     plotpixel



.draw
		ld	ix,0
		add	ix,sp
		ld	e,(ix+2)	;y1
		ld	d,(ix+4)	;x1
		ld	l,(ix+6)	;y0
		ld	h,(ix+8)	;x0
                ld      ix,plotpixel
                call    swapgfxbk
                call    line
                jp      swapgfxbk1

