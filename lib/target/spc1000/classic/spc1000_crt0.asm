;	SPC-1000 


        MODULE  spc1000_crt0

        
;--------
; Include zcc_opt.def to find out some info
;--------

        defc    crt0 = 1
        INCLUDE "zcc_opt.def"

;--------
; Some scope definitions
;--------

        EXTERN    _main           ; main() is always external to crt0 code

        PUBLIC    cleanup         ; jp'd to by exit()
        PUBLIC    l_dcal          ; jp(hl)


;--------
; Set an origin for the application (-zorg=) default to 32768
;--------

	defc	CRT_ORG_CODE = 0x7cdd

	defc	CONSOLE_ROWS = 16
	defc	CONSOLE_COLUMNS = 32

	defc	CRT_KEY_DEL = 12

;        defc    TAR__fputc_cons_generic = 1
        defc    TAR__clib_exit_stack_size = 0
        defc    TAR__register_sp = -1
	defc	__CPU_CLOCK = 4000000 
        INCLUDE "crt/classic/crt_rules.inc"

        org     CRT_ORG_CODE
	jp	start

start:

        INCLUDE "crt/classic/crt_init_sp.asm"
        INCLUDE "crt/classic/crt_init_atexit.asm"

        ld      (start1+1),sp   ; Save entry stack
	call	crt0_init_bss
        ld      (exitsp),sp

; Optional definition for auto MALLOC init
; it assumes we have free space between the end of 
; the compiled program and the stack pointer
	IF DEFINED_USING_amalloc
		INCLUDE "crt/classic/crt_init_amalloc.asm"
	ENDIF


        call    _main           ; Call user program
cleanup:
;
;       Deallocate memory which has been allocated here!
;
        push    hl				; return code

IF CRT_ENABLE_STDIO = 1
        EXTERN     closeall
        call    closeall
ENDIF

IF CRT_ENABLE_VDP
	EXTERN	tms9918_spc1000_impl
	defc	__unused_vdp_import = tms9918_spc1000_impl
ELSE
	EXTERN	tms9918_spc1000_stub
	defc	__unused_vdp_import = tms9918_spc1000_stub
ENDIF


cleanup_exit:

        pop     bc				; return code (still not sure it is teh right one !)

start1: ld      sp,0            ;Restore stack to entry value
	ret


l_dcal: jp      (hl)            ;Used for function pointer calls



	defm    "Small C+ SPC-1000"   ;Unnecessary file signature
	defb    0
        INCLUDE "crt/classic/crt_runtime_selection.asm"

        INCLUDE "crt/classic/crt_section.asm"
