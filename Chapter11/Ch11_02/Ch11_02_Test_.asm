;-------------------------------------------------
;               Ch11_02_Test_.asm
;-------------------------------------------------

        include <MacrosX86-64-AVX.asmh>
        extern c_NumPtsMin:dword
        extern c_NumPtsMax:dword

; extern bool Convolve2Ks5Test_(float* y, const float* x, int num_pts, const float* kernel, int kernel_size)

        .code
Convolve2Ks5Test_ proc frame
        _CreateFrame CKS5T_,0,48
        _SaveXmmRegs xmm6,xmm7,xmm8
        _EndProlog

; Validate argument values
        xor eax,eax                         ;set error code (rax is also loop index var)

        cmp dword ptr [rbp+CKS5T_OffsetStackArgs],5
        jne Done                            ;jump if kernel_size is not 5

        cmp r8d,[c_NumPtsMin]
        jl Done                             ;jump if num_pts too small
        cmp r8d,[c_NumPtsMax]
        jg Done                             ;jump if num_pts too big
        test r8d,7
        jnz Done                            ;num_pts not even multiple of 8

        test rcx,1fh
        jnz Done                            ;y is not properly aligned

; Perform required initializations
        vbroadcastss ymm4,real4 ptr [r9]        ;kernel[0]
        vbroadcastss ymm5,real4 ptr [r9+4]      ;kernel[1]
        vbroadcastss ymm6,real4 ptr [r9+8]      ;kernel[2]
        vbroadcastss ymm7,real4 ptr [r9+12]     ;kernel[3]
        vbroadcastss ymm8,real4 ptr [r9+16]     ;kernel[4]
        mov r8d,r8d                             ;r8 = num_pts
        add rdx,8                               ;x += 2

; Perform convolution
@@:     vxorps ymm2,ymm2,ymm2                   ;initialize sum vars
        vxorps ymm3,ymm3,ymm3
        mov r11,rax
        add r11,2                               ;j = i + ks2

        vmovups ymm0,ymmword ptr [rdx+r11*4]    ;ymm0 = x[j]:x[j + 7]
        vmulps ymm0,ymm0,ymm4
        vaddps ymm2,ymm2,ymm0                   ;ymm2 += x[j]:x[j + 7] * kernel[0]

        vmovups ymm1,ymmword ptr [rdx+r11*4-4]  ;ymm1 = x[j - 1]:x[j + 6]
        vmulps ymm1,ymm1,ymm5
        vaddps ymm3,ymm3,ymm1                   ;ymm3 += x[j - 1]:x[j + 6] * kernel[1]

        vmovups ymm0,ymmword ptr [rdx+r11*4-8]  ;ymm0 = x[j - 2]:x[j + 5]
        vmulps ymm0,ymm0,ymm6
        vaddps ymm2,ymm2,ymm0                   ;ymm2 += x[j - 2]:x[j + 5] * kernel[2]

        vmovups ymm1,ymmword ptr [rdx+r11*4-12] ;ymm1 = x[j - 3]:x[j + 4]
        vmulps ymm1,ymm1,ymm7
        vaddps ymm3,ymm3,ymm1                   ;ymm3 += x[j - 3]:x[j + 4] * kernel[3]

        vmovups ymm0,ymmword ptr [rdx+r11*4-16] ;ymm0 = x[j - 4]:x[j + 3]
        vmulps ymm0,ymm0,ymm8
        vaddps ymm2,ymm2,ymm0                   ;ymm2 += x[j - 4]:x[j + 3] * kernel[4]

        vaddps ymm0,ymm2,ymm3                   ;final values
        vmovaps ymmword ptr [rcx+rax*4],ymm0    ;save y[i]:y[i + 7]

        add rax,8                               ;i += 8
        cmp rax,r8
        jl @B                                   ;jump if i < num_pts
        mov eax,1                               ;set success return code

Done:   vzeroupper
        _RestoreXmmRegs xmm6,xmm7,xmm8
        _DeleteFrame
        ret
Convolve2Ks5Test_ endp
        end
