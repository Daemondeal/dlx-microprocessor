.text

main:
    addi r1, r0, #15
    addi r2, r0, #18
    imul r3, r2, r1
    imul r4, r2, r1
    ; test: check multiplies
    ; expect: multiply_result1 270
    ; expect: multiply_result2 270
    sw multiply_result1(r0), r3
    sw multiply_result2(r0), r3

    add r4, r1, r2

; Stop Simulator
end:
    lhi r1, 0xFFFF
    sw 0(r1), #0
.data

    .space 4096

data_start:

multiply_result1:
    .space 4

multiply_result2:
    .space 4
