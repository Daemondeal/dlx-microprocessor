.text

    ; test: sample test
    addi r1, r0, #15
    sw var1(r0), r1
    ; expect: var1 15
    nop
    lhi r1, #0xFFFF
    sw 0(r1), r0
    nop
    nop
    nop


.data

code_space:
    .space 1024

data_start:

var1: 
    .space 4

