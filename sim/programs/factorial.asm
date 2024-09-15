.text

start:
    addi r1, r0, 8
    jal fact
    sw result(r0), r1
    ; expect: result 40320

    lhi r1, #0xFFFF
    sw 0(r1), r0

fact:
    ; r1 is the input
    ; r2 is the index
    ; for (r2 = r1-1; r2 <= 1; r2--) {
    ;   r1 *= r2;
    ; }
    subi r2, r1, 1
    j fact_loop_end

fact_loop:
    imul r1, r1, r2
    subi r2, r2, 1

fact_loop_end:
    ; if (r2 <= 1) return
    slei r3, r2, 1
    beqz r3, fact_loop

end:
    jr r31


.data

.space 512

result:
	.space 4
