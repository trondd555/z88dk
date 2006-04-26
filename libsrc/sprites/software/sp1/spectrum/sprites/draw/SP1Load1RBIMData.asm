
; DRAW LOAD SPRITE 1 BYTE DEFINITION ROTATED, RIGHT BORDER WITH IMPLIED MASK
; 04.2006 aralbrec, Sprite Pack v3.0
; sinclair spectrum version

XLIB SP1Load1RBIMData
LIB SP1Load1LBIMData
XREF SP1RETSPRDRAW, SP1V_ROTTBL, SP1V_PIXELBUFFER

; following data segment copied into struct sp1_cs

.SP1Load1RBIMData

   ld de,0
   nop
   ld hl,0
   call SP1Load1RBIM
   
; following draw code called by way of SP1UpdateNow
;
;  a = hor rot table
; bc = graphic disp
; de = graphic def ptr
; hl = left graphic def ptr
;
; 64 + 8*54 - 6 + 10 = 500 cycles

.SP1Load1RBIM

   cp SP1V_ROTTBL/256
   jp z, SP1RETSPRDRAW

   add hl,bc
   ex de,hl
   ld h,a
   ld l,$ff
   ld c,(hl)
   inc h
   
   ;  h = shift table
   ;  c = constant mask
   ; de = sprite def (graph only)

.SP1Load1RBIMRotate

   jp SP1Load1LBIMData+23              ; SP1Load1LBIMRotate
   