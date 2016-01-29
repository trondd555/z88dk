
// automatically generated by m4 from headers in proto subdir


#ifndef _INTRINSIC_H
#define _INTRINSIC_H

extern void intrinsic_di(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_ei(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_ei_reti(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_halt(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_retn(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_im_0(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_im_1(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_im_2(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_af(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_bc(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_de(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_hl(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_ix(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_push_iy(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_pop_af(void) __preserves_regs(b,c,d,e,h,l);

extern void intrinsic_pop_bc(void) __preserves_regs(a,d,e,h,l);

extern void intrinsic_pop_de(void) __preserves_regs(a,b,c,h,l);

extern void intrinsic_pop_hl(void) __preserves_regs(a,b,c,d,e);

extern void intrinsic_pop_ix(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_pop_iy(void) __preserves_regs(a,b,c,d,e,h,l);

extern void intrinsic_exx(void) __preserves_regs(a);


#endif
