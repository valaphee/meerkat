// Copyright 2024 Kevin Ludwig
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

    .section .multiboot.init, "a"

    .global __start
__start:
    .code32
    // save multiboot arguments
    mov edi, eax
    mov esi, ebx

    // enable long-mode
    mov   ecx, 0xC0000080 // EFER
    rdmsr
    or    eax, 0x00000100 // EFER.LME
    wrmsr

    // enable PAE (required by long-mode)
    mov eax, cr4
    or  eax, 0x00000020 // CR4.PAE
    mov cr4, eax

    // setup rudimentary page table
    // 0000000000000000 - 00000000001FFFFF: id
    // FFFFFFFF80000000 - FFFFFFFF801FFFFF: id
    // FFFFFF0000000000 - FFFFFF7FBFDFEFFF: self ref
    mov eax, offset ptl1 - 0xFFFFFFFF80000000
    mov ecx, 0x3                              // P R/W
1:
    mov [eax], ecx
    add eax  , 8
    add ecx  , 0x00001000
    cmp ecx  , 0x00200003
    jnz 1b

    mov eax                   , offset ptl2 - 0xFFFFFFFF80000000
    mov long ptr [eax + 0x000], offset ptl1 - 0xFFFFFFFF80000000 + 0x3 // P R/W 000: 1

    mov eax                   , offset ptl3i - 0xFFFFFFFF80000000
    mov long ptr [eax + 0x000], offset ptl2 - 0xFFFFFFFF80000000 + 0x3 // P R/W 000: 2

    mov eax                   , offset ptl3 - 0xFFFFFFFF80000000
    mov long ptr [eax + 0xFF0], offset ptl2 - 0xFFFFFFFF80000000 + 0x3 // P R/W 776: 2

    mov eax                   , offset ptl4  - 0xFFFFFFFF80000000
    mov long ptr [eax + 0xFF0], offset ptl4  - 0xFFFFFFFF80000000 + 0x3 // P R/W 776: 4
    mov long ptr [eax + 0x000], offset ptl3i - 0xFFFFFFFF80000000 + 0x3 // P R/W 000: 3i
    mov long ptr [eax + 0xFF8], offset ptl3  - 0xFFFFFFFF80000000 + 0x3 // P R/W 777: 3
    mov cr3, eax

    // enable paging
    mov eax, cr0
    or  eax, 0x80000000 // CR0.PG
    mov cr0, eax

    // setup flat segmentation
    lgdt gdtr_32
    mov  ax, (2 << 3) // KDATA
    mov  ds, ax
    mov  es, ax
    mov  fs, ax
    mov  gs, ax
    mov  ss, ax
    //jmp  (1 << 3), 2f
    .byte 0xEA
    .long 2f
    .short (1 << 3) // KCODE
2:  .code64
    lgdt gdtr_64

    // setup stack and call main with multiboot arguments
    mov rax, offset stack_top
    mov rsp, rax
    mov rbp, rax
    call main

gdtr_32:
    .short (8 * 7) - 1
    .quad DESCRIPTOR_TABLE - 0xFFFFFFFF80000000

gdtr_64:
    .short (8 * 7) - 1
    .quad DESCRIPTOR_TABLE



    .section .bss

    .align 4096
stack_bottom:
    .zero 4096
stack_top:
ptl4:
    .zero 4096
ptl3i:
    .zero 4096
ptl3:
    .zero 4096
ptl2:
    .zero 4096
ptl1:
    .zero 4096
