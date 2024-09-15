.text

start:
    addi r1, r0, #15
    addi r2, r0, #18
    addi r3, r0, #0
    addi r4, r0, #0
    j end
    imul r3, r1, r2

end:
    imul r4, r1, r2
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    sw result(r0), r3
    ; test: should not have multiplied
    ; expect: result 0

    sw result2(r0), r4
    ; test: should have multiplied
    ; expect: result2 270

    lhi r1, #0xFFFF
    sw 0(r1), r0



.data

code_space:
    .space 1024

data_start:

result:
    .space 4

result2:
    .space 4

