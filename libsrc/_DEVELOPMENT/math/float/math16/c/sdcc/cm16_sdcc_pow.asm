
SECTION code_fp_math16
PUBLIC cm16_sdcc_pow

EXTERN powf16_callee

.cm16_sdcc_pow

    pop hl      ; return
    pop de      ; LHS
    ex (sp),hl  ; return to stack, RHS
    
    push de     ; LHS    
    push hl     ; RHS

    call powf16_callee
    pop bc
    push bc
    push bc
    push bc
    ret
