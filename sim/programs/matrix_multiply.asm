.text
start:
    addi r1, r0, mat_a
    addi r2, r0, mat_b
    addi r3, r0, 2 ; N (Assuming square matrices for simplicity)
    jal matrix_multiply

    lhi r1, #0xFFFF
    sw 0(r1), r0
    ; expect: res_first 19
    ; expect: res_second 22
    ; expect: res_third 43
    ; expect: res_fourth 50

matrix_multiply:

    addi r4, r0, 0 ; i
i_loop:
    sge r10, r4, r3
    bnez r10, i_loop_end

    addi r5, r0, 0 ; j
j_loop:
    sge r10, r5, r3
    bnez r10, j_loop_end

    ; result[i][j] = 0
    addi r8, r0, 0

    addi r6, r0, 0 ; k
k_loop:
    sge r10, r6, r3
    bnez r10, k_loop_end

    ; r9 = m1[i][k] = m1[i * N + k]
    addi r9, r4, 0
    imul r9, r9, r3
    add r9, r9, r6

    ; the index needs to be multiplied by four because it's addressing words
    slli r9, r9, 2
    lw r9, mat_a(r9)

    ; r10 = m2[k][j] = m2[k * N + j]
    addi r10, r6, 0
    imul r10, r10, r3
    add r10, r10, r5

    ; the index needs to be multiplied by four because it's addressing words
    slli r10, r10, 2
    lw r10, mat_b(r10)

    ; result[i][j] = m1[i][k] * m2[k][j]
    imul r9, r9, r10
    add r8, r8, r9

    addi r6, r6, 1
    j k_loop
k_loop_end:

    ; save result[i][j] = result[i * N + j]
    addi r9, r4, 0
    imul r9, r9, r3
    add r9, r9, r5

    ; the index needs to be multiplied by four because it's addressing words
    slli r9, r9, 2
    sw result(r9), r8

    addi r5, r5, 1
    j j_loop
j_loop_end:

    addi r4, r4, 1
    j i_loop
i_loop_end:

    jr r31


.data

code_space:
    .space 1024

data_start:

mat_a:
    .word 1, 2, 3, 4

mat_b:
    .word 5, 6, 7, 8

result:

res_first:
    .space 4
res_second:
    .space 4
res_third:
    .space 4
res_fourth:
    .space 4

