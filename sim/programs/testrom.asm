; category: Arithmetic Operations


.text

main:

; test: addi
    addi r3, r0, #15
    sw addi_test1(r0), r3
    ; expect: addi_test1 15

    addi r4, r3, #15
    sw addi_test2(r0), r4
    ; expect: addi_test2 30

    ; This should sign extend the immediate
    addi r4, r0, #0xFFFF
    sw addi_test3(r0), r4
    ; expect: addi_test3 0xFFFFFFFF

; test: addui
 addui r3, r0, #15
    sw addui_test1(r0), r3
    ; expect: addui_test1 15

    addui r4, r3, #15
    sw addui_test2(r0), r4
    ; expect: addui_test2 30

    ; This should not sign extend the immediate
    addui r4, r0, #0xFFFF
    sw addui_test3(r0), r4
    ; expect: addui_test3 0x0000FFFF
    
; test: subi
	addi r3, r0, #30
  	subi r3, r3, #15
    sw subi_test1(r0), r3
    ; expect: subi_test1 15

    subi r4, r3, #15
    sw subi_test2(r0), r4
    ; expect: subi_test2 0

    ; This should sign extend the immediate

    subi r4, r0, #0xFFFF
    sw subi_test3(r0), r4
    ; expect: subi_test3 0x00000001


; test: subui
	addi r3, r0, #30
  	subui r3, r3, #15
    sw subui_test1(r0), r3
    ; expect: subui_test1 15

    subui r4, r3, #15
    sw subui_test2(r0), r4
    ; expect: subui_test2 0

    ; This should sign extend the immediate

    subui r4, r0, #0xFFFF
    sw subui_test3(r0), r4
    ; expect: subui_test3 0xFFFF0001
    
; category: Jumps and Branches

; test: beqz

itype_jumps:
    addi r3, r0, #0
    addi r4, r0, #1

    addi r10, r0, #10
    addi r11, r0, #20


    sw beqz_test1(r0), r10
    sw beqz_test2(r0), r10

    beqz r3, beqz_test_should_jump

    sw beqz_test1(r0), r11

beqz_test_should_jump:

    beqz r4, beqz_test_should_not_jump

    sw beqz_test2(r0), r11

beqz_test_should_not_jump:
    ; expect: beqz_test1 10
    ; expect: beqz_test2 20

; test: bnez

itype_jumps:
    addi r3, r0, #1
    addi r4, r0, #0

    addi r10, r0, #10
    addi r11, r0, #20


    sw bnez_test1(r0), r10
    sw bnez_test2(r0), r10

    bnez r3, bnez_test_should_jump

    sw beqz_test1(r0), r11

bnez_test_should_jump:

    bnez r4, beqz_test_should_not_jump

    sw bnez_test2(r0), r11

bnez_test_should_not_jump:
    ; expect: bnez_test1 10
    ; expect: bnez_test2 20


; test: jalr


addi r6, r0, test_routine
jalr r6
	addi r1,r0,#30
	sw jalr_test2(r0), r1
	j skip_routine


test_routine:
	addi r1,r0,#10
	sw jalr_test1(r0), r1
	jr r31


skip_routine:


 	; expect: jalr_test1 10
    ; expect: jalr_test2 30

; test: jr
addi r1,r0,first_jump
addi r2,r0,second_jump
addi r3,r0,third_jump
addi r10,r0,skip
jr r2

first_jump:
addi r4,r0,0x0FFF
sw jr_test2(r0), r4
jr r10

second_jump:
addi r4,r0,#10
sw jr_test1(r0), r4
jr r1


third_jump:
addi r4,r0,0xAAAA
sw jr_test1(r0), r4
skip:

; expect: jr_test1 10
    ; expect: jr_test2 0xFFF

; category: Loads and Stores (From Memory)

; test: lw
	addi r11, r0, #10
	sw lw_test1_temp(r0), r11
	
	addi r11, r0, #20
	sw lw_test2_temp(r0), r11

	addi r11, r0, #30
	sw lw_test3_temp(r0), r11

	lw r1, lw_test1_temp(r0)
	sw lw_test1(r0), r1
	
	lw r1, lw_test2_temp(r0)
	sw lw_test2(r0), r1
	
	lw r1, lw_test3_temp(r0)
	sw lw_test3(r0), r1
	
	; expect: lw_test1 10
	
	; expect: lw_test2 20
	
	; expect: lw_test3 30
; test: sw
	addi r11, r0, #10
	sw sw_test1(r0), r11
	
	addi r11, r0, #20
	sw sw_test2(r0), r11

	addi r11, r0, #30
	sw sw_test3(r0), r11
	
	; expect: sw_test1 10
	
	; expect: sw_test2 20
	
	; expect: sw_test3 30
	
; test: lhu
	lhi r1,0xDEAD
	addui r1,r1,0xBEEF
	sw lhu_test1_temp(r0), r1
	
	addi r1,r0,0x69696969
	sw lhu_test2_temp(r0), r1
	
	addi r1,r0,0x42042069
	sw lhu_test3_temp(r0), r1
	
	lhu r2,lhu_test1_temp+2(r0)
	sw lhu_test1(r0), r2
	lhu r3,lhu_test2_temp(r0)
	sw lhu_test2(r0), r3
	lhu r4,lhu_test3_temp(r0)
	sw lhu_test3(r0), r4
	
	; expect: lhu_test1 0x0000DEAD
	; expect: lhu_test2 0x00006969
	; expect: lhu_test3 0x00002069
	
; test: lb
	lhi r1,0xDEAD
	addui r1,r1,0x00FF
	sw lb_test1_temp(r0), r1
	
	addui r1,r0,0xFF01
	sw lb_test2_temp(r0), r1
	
	addui r1,r0,0xAABB
	sw lb_test3_temp(r0), r1
	
	
	lb r2,lb_test1_temp+2(r0)
	sw lb_test1(r0), r2
	
	lb r3,lb_test2_temp(r0)
	sw lb_test2(r0), r3
	
	lb r4,lb_test3_temp(r0)
	sw lb_test3(r0), r4
	
	; expect: lb_test1 0xFFFFFFAD
	; expect: lb_test2 0x00000001
	; expect: lb_test3 0xFFFFFFBB
	
; test: sb
	lhi r1,0xDEAD
	addui r1,r1,0x00FF
	sb sb_test1(r0), r1
	
	addui r1,r0,0xFF01
	sb sb_test2(r0), r1
	
	addui r1,r0,0xAABB
	sb sb_test3(r0), r1

	; expect: sb_test1 0x000000FF
	; expect: sb_test2 0x00000001
	; expect: sb_test3 0x000000BB
	

; test: lbu

	lhi r1,0xDEAD
	addui r1,r1,0x00FF
	sw lbu_test1_temp(r0), r1
	
	addui r1,r0,0xFF01
	sw lbu_test2_temp(r0), r1
	
	addui r1,r0,0xAABB
	sw lbu_test3_temp(r0), r1
	
	
	lbu r2,lbu_test1_temp+2(r0)
	sw lbu_test1(r0), r2
	
	lbu r3,lbu_test2_temp(r0)
	sw lbu_test2(r0), r3
	
	lbu r4,lbu_test3_temp(r0)
	sw lbu_test3(r0), r4
	
	; expect: lbu_test1 0x000000AD
	; expect: lbu_test2 0x00000001
	; expect: lbu_test3 0x000000BB
; category: Comparisons

; test: seqi
	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	seqi r4,r1,#10
	seqi r5,r2,#10
	seqi r6,r3,#30

	sw seqi_test1(r0), r4
	sw seqi_test2(r0), r5
	sw seqi_test3(r0), r6

	; expect: seqi_test1 1
	; expect: seqi_test2 0
	; expect: seqi_test3 1
; test: snei
	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	snei r4,r1,#10
	snei r5,r2,#10
	snei r6,r3,#30

	sw snei_test1(r0), r4
	sw snei_test2(r0), r5
	sw snei_test3(r0), r6

	; expect: snei_test1 0
	; expect: snei_test2 1
	; expect: snei_test3 0

; test: sgei
	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	sgei r4,r1,#10
	sgei r5,r2,#50
	sgei r6,r3,#-40

	sw sgei_test1(r0), r4
	sw sgei_test2(r0), r5
	sw sgei_test3(r0), r6

	; expect: sgei_test1 1
	; expect: sgei_test2 0
	; expect: sgei_test3 1

; test: sgeui

addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	sgeui r4,r1,#10
	sgeui r5,r2,#50
	sgeui r6,r3,#17

	sw sgeui_test1(r0), r4
	sw sgeui_test2(r0), r5
	sw sgeui_test3(r0), r6

	; expect: sgeui_test1 1
	; expect: sgeui_test2 0
	; expect: sgeui_test3 1
	
; test: sgti

	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	sgti r4,r1,#10
	sgti r5,r2,#50
	sgti r6,r3,#-40

	sw sgti_test1(r0), r4
	sw sgti_test2(r0), r5
	sw sgti_test3(r0), r6

	; expect: sgti_test1 0
	; expect: sgti_test2 0
	; expect: sgti_test3 1
; test: sgtui

	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	sgtui r4,r1,#10
	sgtui r5,r2,#50
	sgtui r6,r3,#17

	sw sgtui_test1(r0), r4
	sw sgtui_test2(r0), r5
	sw sgtui_test3(r0), r6

	; expect: sgtui_test1 0
	; expect: sgtui_test2 0
	; expect: sgtui_test3 1
	
; test: slei
	addi r1,r0, #-10
	addi r2,r0, #-20
	addi r3,r0, #30

	slei r4,r1,#-5
	slei r5,r2,#-20
	slei r6,r3,#-17

	sw slei_test1(r0), r4
	sw slei_test2(r0), r5
	sw slei_test3(r0), r6

	; expect: slei_test1 1
	; expect: slei_test2 1
	; expect: slei_test3 0

; test: slti
	addi r1,r0, #-10
	addi r2,r0, #-20
	addi r3,r0, #30

	slti r4,r1,#-5
	slti r5,r2,#-20
	slti r6,r3,#-17

	sw slti_test1(r0), r4
	sw slti_test2(r0), r5
	sw slti_test3(r0), r6

	; expect: slti_test1 1
	; expect: slti_test2 0
	; expect: slti_test3 0

; test: sltui
	addi r1,r0, #10
	addi r2,r0, #20
	addi r3,r0, #30

	sltui r4,r1,#5
	sltui r5,r2,#20
	sltui r6,r3,#60

	sw sltui_test1(r0), r4
	sw sltui_test2(r0), r5
	sw sltui_test3(r0), r6

	; expect: sltui_test1 0
	; expect: sltui_test2 0
	; expect: sltui_test3 1
; category: Bitwise operations



itype_bitwise:

; test: andi
    addi r3, r0, #3
    andi r3, r3, #2
    sw andi_test1(r0), r3

    ; expect: andi_test1 0x2

; test: xori
	addui r1, r0, 0xAAAA
	xori r1,r1,0x0002
	sw xori_test1(r0), r1
	
	addui r1, r0, 0xAAAA
	xori r1,r1,0xFFFF
	sw xori_test2(r0), r1
	
	addui r1, r0, 0xAAAA
	xori r1,r1,0x0000
	sw xori_test3(r0), r1
	
	; expect: xori_test1 0xAAA8
	; expect: xori_test2 0x5555
	; expect: xori_test3 0xAAAA
; test: ori
addui r1, r0, 0xAAAA
	ori r1,r1,0x0002
	sw ori_test1(r0), r1
	
	addui r1, r0, 0xAAAA
	ori r1,r1,0xFFFF
	sw ori_test2(r0), r1
	
	addui r1, r0, 0xAAAA
	ori r1,r1,0x0000
	sw ori_test3(r0), r1
	
	; expect: ori_test1 0xAAAA
	; expect: ori_test2 0xFFFF
	; expect: ori_test3 0xAAAA

; category: Shifts
; test: slli
	addui r1,r0,#1
	slli r1,r1,#5
	sw slli_test1(r0), r1
	
	addui r1,r0,0xFFFF
	slli r1,r1,#16
	sw slli_test2(r0), r1
	
	addui r1,r0,0xAAAA
	slli r1,r1,#4
	sw slli_test3(r0), r1
	
	; expect: slli_test1 0x20
	; expect: slli_test2 0xFFFF0000
	; expect: slli_test3 0xAAAA0
	
; test: srli
addi r1,r0,0x0FFF
	srli r1,r1,#4
	sw srli_test1(r0), r1
	
	addi r1,r0,0xABCD
	srli r1,r1,#0
	sw srli_test2(r0), r1
	
	addi r1,r0,0xABCD
	srli r1,r1,0xFFFF
	sw srli_test3(r0), r1
	
	addi r1,r0,0xFFFF
	srli r1,r1,0xFF11
	sw srli_test4(r0), r1
	
	; expect: srli_test1 0x000000FF
	; expect: srli_test2 0xFFFFABCD
	; expect: srli_test3 0x1
	; expect: srli_test4 0x7FFF

; test: srai
addi r1,r0,0x0FFF
	srai r1,r1,#4
	sw srai_test1(r0), r1
	
	addi r1,r0,0xABCD
	srai r1,r1,#0
	sw srai_test2(r0), r1
	
	addi r1,r0,0xABCD
	srai r1,r1,0xFFFF
	sw srai_test3(r0), r1
	
	addi r1,r0,0xFFFF
	srai r1,r1,0xFF11
	sw srai_test4(r0), r1
	
	; expect: srai_test1 0x000000FF
	; expect: srai_test2 0xFFFFABCD
	; expect: srai_test3 0xFFFFFFFF
	; expect: srai_test4 0xFFFFFFFF

; category: J-Type Jumps

jumps:
; test: j
    addi r3, r0, #50
    j j_should_jump

    addi r3, r0, #100
j_should_jump:
    sw j_test1(r0), r3
    ; expect: j_test1 50

; test: jal

    addi r3, r0, #50

    jal jal_should_jump

    addi r3, r0, #100

    j jal_skip

; This is an example of a subroutine
jal_should_jump:
    sw jal_test1(r0), r3
    ; expect: jal_test1 50

    jr r31 ; Return from subroutine

jal_skip:
    sw jal_test2(r0), r3
    ; expect: jal_test2 100


; category: R-Type Arithmetic

arithmetic:
; test: add
    addi r3, r0, #10
    addi r4, r0, #10
    add r3, r3, r4
    sw add_test1(r0), r3
    ; expect: add_test1 20

    addi r3, r0, #-150
    addi r4, r0, #149
    add r3, r3, r4
    sw add_test2(r0), r3
    ; expect: add_test2 0xFFFFFFFF

    lhi  r3, #0xFFFF
    addi r3, r0, #0xFFFF
    addi r4, r0, #1
    add r3, r3, r4
    sw add_test3(r0), r3
    ; expect: add_test3 0

; test: addu
    addi r3, r0, #10
    addi r4, r0, #10
    addu r3, r3, r4
    sw addu_test1(r0), r3
    ; expect: addu_test1 20

    addi r3, r0, #-150
    addi r4, r0, #149
    addu r3, r3, r4
    sw addu_test2(r0), r3
    ; expect: addu_test2 0xFFFFFFFF

    lhi  r3, #0xFFFF
    addi r3, r0, #0xFFFF
    addi r4, r0, #1
    addu r3, r3, r4
    sw addu_test3(r0), r3
    ; expect: addu_test3 0

; test: sub
    addi r3, r0, #150
    addi r4, r0, #-150
    sub r3, r3, r4
    sw sub_test1(r0), r3
    ; expect: sub_test1 300

    addi r3, r0, #840
    sub r4, r0, r3
    sub r5, r3, r0
    sw sub_test2(r0), r4
    sw sub_test3(r0), r5
    ; expect: sub_test2 -840
    ; expect: sub_test3 840

; test: subu
    addi r3, r0, #150
    addi r4, r0, #-150
    subu r3, r3, r4
    sw subu_test1(r0), r3
    ; expect: subu_test1 300

    addi r3, r0, #840
    subu r4, r0, r3
    subu r5, r3, r0
    sw subu_test2(r0), r4
    sw subu_test3(r0), r5
    ; expect: subu_test2 -840
    ; expect: subu_test3 840

; category: R-Type Comparisons

; test: seq
    addi r3, r0, #100
    addi r4, r0, #100
    seq r3, r3, r4
    sw seq_test1(r0), r3
    ; expect: seq_test1 1

    addi r3, r0, #-50
    seq r3, r3, r4
    sw seq_test2(r0), r3
    ; expect: seq_test2 0

; test: sne
    addi r3, r0, #100
    addi r4, r0, #100
    sne r3, r3, r4
    sw sne_test1(r0), r3
    ; expect: sne_test1 0

    addi r3, r0, #-50
    sne r3, r3, r4
    sw sne_test2(r0), r3
    ; expect: sne_test2 1

; test: sge
    addi r3, r0, #-15
    addi r4, r0, #16
    sge r3, r3, r4
    sw sge_test1(r0), r3
    ; expect: sge_test1 0

    addi r3, r0, #181
    addi r4, r0, #180
    sge r3, r3, r4
    sw sge_test2(r0), r3
    ; expect: sge_test2 1

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sge r3, r3, r4
    sw sge_test3(r0), r3
    ; expect: sge_test3 1

    addi r3, r0, #50
    addi r4, r0, #50
    sge r3, r3, r4
    sw sge_test4(r0), r3
    ; expect: sge_test4 1

; test: sgeu
    addi r3, r0, #-15
    addi r4, r0, #16
    sgeu r3, r3, r4
    sw sgeu_test1(r0), r3
    ; expect: sgeu_test1 1

    addi r3, r0, #181
    addi r4, r0, #180
    sgeu r3, r3, r4
    sw sgeu_test2(r0), r3
    ; expect: sgeu_test2 1

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sgeu r3, r3, r4
    sw sgeu_test3(r0), r3
    ; expect: sgeu_test3 0

    addi r3, r0, #50
    addi r4, r0, #50
    sgeu r3, r3, r4
    sw sgeu_test4(r0), r3
    ; expect: sgeu_test4 1

; test: sgt
    addi r3, r0, #-15
    addi r4, r0, #16
    sgt r3, r3, r4
    sw sgt_test1(r0), r3
    ; expect: sgt_test1 0

    addi r3, r0, #181
    addi r4, r0, #180
    sgt r3, r3, r4
    sw sgt_test2(r0), r3
    ; expect: sgt_test2 1

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sgt r3, r3, r4
    sw sgt_test3(r0), r3
    ; expect: sgt_test3 1

    addi r3, r0, #50
    addi r4, r0, #50
    sgt r3, r3, r4
    sw sgt_test4(r0), r3
    ; expect: sgt_test4 0

; test: sgtu
    addi r3, r0, #-15
    addi r4, r0, #16
    sgtu r3, r3, r4
    sw sgtu_test1(r0), r3
    ; expect: sgtu_test1 1

    addi r3, r0, #181
    addi r4, r0, #180
    sgeu r3, r3, r4
    sw sgtu_test2(r0), r3
    ; expect: sgtu_test2 1

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sgtu r3, r3, r4
    sw sgtu_test3(r0), r3
    ; expect: sgtu_test3 0

    addi r3, r0, #50
    addi r4, r0, #50
    sgtu r3, r3, r4
    sw sgtu_test4(r0), r3
    ; expect: sgtu_test4 0


; test: sle
    addi r3, r0, #-15
    addi r4, r0, #16
    sle r3, r3, r4
    sw sle_test1(r0), r3
    ; expect: sle_test1 1

    addi r3, r0, #181
    addi r4, r0, #180
    sle r3, r3, r4
    sw sle_test2(r0), r3
    ; expect: sle_test2 0

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sle r3, r3, r4
    sw sle_test3(r0), r3
    ; expect: sle_test3 0

    addi r3, r0, #50
    addi r4, r0, #50
    sle r3, r3, r4
    sw sle_test4(r0), r3
    ; expect: sle_test4 1

; test: sleu
    addi r3, r0, #-15
    addi r4, r0, #16
    sleu r3, r3, r4
    sw sleu_test1(r0), r3
    ; expect: sleu_test2 0

    addi r3, r0, #181
    addi r4, r0, #180
    sleu r3, r3, r4
    sw sleu_test2(r0), r3
    ; expect: sleu_test2 0

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sleu r3, r3, r4
    sw sleu_test3(r0), r3
    ; expect: sleu_test3 1

    addi r3, r0, #50
    addi r4, r0, #50
    sleu r3, r3, r4
    sw sleu_test4(r0), r3
    ; expect: sleu_test4 1

; test: slt
    addi r3, r0, #-15
    addi r4, r0, #16
    slt r3, r3, r4
    sw slt_test1(r0), r3
    ; expect: slt_test1 1

    addi r3, r0, #181
    addi r4, r0, #180
    slt r3, r3, r4
    sw slt_test2(r0), r3
    ; expect: slt_test2 0

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    slt r3, r3, r4
    sw slt_test3(r0), r3
    ; expect: slt_test3 0

    addi r3, r0, #50
    addi r4, r0, #50
    slt r3, r3, r4
    sw slt_test3(r0), r3
    ; expect: slt_test4 0

; test: sltu
    addi r3, r0, #-15
    addi r4, r0, #16
    sltu r3, r3, r4
    sw sltu_test1(r0), r3
    ; expect: sltu_test1 0

    addi r3, r0, #181
    addi r4, r0, #180
    sltu r3, r3, r4
    sw sltu_test2(r0), r3
    ; expect: sltu_test2 0

    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    addi r4, r3, #1
    sltu r3, r3, r4
    sw sltu_test3(r0), r3
    ; expect: sltu_test3 1

    addi r3, r0, #50
    addi r4, r0, #50
    sltu r3, r3, r4
    sw sltu_test4(r0), r3
    ; expect: sltu_test4 0


; category: R-Type Logic

; test: and

rtype_logic:
    addi r3, r0, #3
    addi r4, r0, #2
    and r3, r3, r4
    sw and_test1(r0), r3

    ; expect: and_test1 2

    addi r3, r0, #-185
    addi r4, r0, #0xFFFF
    and r3, r3, r4
    sw and_test2(r0), r3

    ; expect: and_test2 -185

; test: xor
    addi r3, r0, #3
    addi r4, r0, #2
    xor r3, r3, r4
    sw xor_test1(r0), r3

    ; expect: xor_test1 1

    addui r3, r0, #0xFFFF
    addi r4, r0, #0xFFFF
    xor r3, r3, r4
    sw xor_test2(r0), r3

    ; expect: xor_test2 0xFFFF0000

    ; xorswap
    addi r3, r0, #15
    addi r4, r0, #-87

    xor r3, r3, r4
    xor r4, r3, r4
    xor r3, r3, r4

    sw xor_xorswap1(r0), r3
    sw xor_xorswap2(r0), r4

    ; expect: xor_xorswap1 -87
    ; expect: xor_xorswap2 15

; test: or
    addi r3, r0, #5
    addi r4, r0, #2
    xor r3, r3, r4
    sw or_test1(r0), r3

    ; expect: or_test1 7

; category: R-Type Shifts

; test: sll
    addi r3, r0, #150
    addi r4, r0, #3
    sll r3, r3, r4
    sw sll_test1(r0), r3

    ; expect: sll_test1 1200

    ; Shifts in this cpu only consider the 5 lowest significant bits
    addi r3, r0, #15
    addi r4, r0, #0xFF02
    sll r3, r3, r4
    sw sll_test2(r0), r3

    ; expect: sll_test2 60

; test: srl
    addi r3, r0, #150
    addi r4, r0, #2
    srl r3, r3, r4
    sw srl_test1(r0), r3
    ; expect: srl_test1 37

    addi r3, r0, #-840
    addi r4, r0, #8
    srl r3, r3, r4
    sw srl_test2(r0), r3
    ; expect: srl_test2 0x00FFFFFC


; test: sra
    addi r3, r0, #150
    addi r4, r0, #2
    sra r3, r3, r4
    sw sra_test1(r0), r3
    ; expect: sra_test1 37

    addi r3, r0, #-840
    addi r4, r0, #8
    sra r3, r3, r4
    sw sra_test2(r0), r3
    ; expect: sra_test2 -4

; category: Other

; test: lhi
    lhi r3, #0xABCD
    sw lhi_test1(r0), r3
    ; expect: lhi_test1 0xABCD0000

; test: imul
imul_tests:
    addi r3, r0, #15
    addi r4, r0, #-15
    imul r3, r3, r4
    sw imul_test1(r0), r3
    ; expect: imul_test1 -225

    addi r3, r0, #-158 
    addi r4, r0, #0
    imul r3, r3, r4
    sw imul_test2(r0), r3
    ; expect: imul_test2 0


    lhi r3, #0x7FFF
    addui r3, r3, #0xFFFF
    add r4, r3, r0
    # INT_MAX * INT_MAX = 1 

    imul r3, r3, r4
    sw imul_test3(r0), r3
    ; expect: imul_test3 1

    addi r3, r0, #150
    addi r4, r0, #827
    imul r3, r3, r4

    sw imul_test4(r0), r3
    ; expect: imul_test4 124050

    ; test: idiv
idiv_tests:
    addi r3, r0, #15
    addi r4, r0, #7

    idiv r4, r3, r4
    sw idiv_test1(r0), r4
    ; expect: idiv_test1 2

    addi r3, r0, #-15
    addi r4, r0, #5

    idiv r4, r3, r4
    sw idiv_test2(r0), r4
    ; expect: idiv_test2 -3

    addi r3, r0, #15
    addi r4, r0, #-5

    idiv r4, r3, r4
    sw idiv_test3(r0), r4
    ; expect: idiv_test3 -3

    addi r3, r0, #-15
    addi r4, r0, #-5

    idiv r4, r3, r4
    sw idiv_test4(r0), r4
    ; expect: idiv_test4 3

    ; test: imod
imod_tests:
    addi r3, r0, #15
    addi r4, r0, #7

    imod r4, r3, r4
    sw imod_test1(r0), r4
    ; expect: imod_test1 1

    addi r3, r0, #-15
    addi r4, r0, #9

    imod r4, r3, r4
    sw imod_test2(r0), r4
    ; expect: imod_test2 3

    addi r3, r0, #15
    addi r4, r0, #-4

    imod r4, r3, r4
    sw imod_test3(r0), r4
    ; expect: imod_test3 1

    addi r3, r0, #-10
    addi r4, r0, #-7

    imod r4, r3, r4
    sw imod_test4(r0), r4
    ; expect: imod_test4 3

; Stop Simulator
end:
    lhi r1, 0xFFFF
    sw 0(r1), #0
.data

    .space 4096

data_start:

sltui_test1:
	.space 4
sltui_test2:
	.space 4
sltui_test3:
	.space 4

slti_test1:
	.space 4
slti_test2:
	.space 4
slti_test3:
	.space 4


slei_test1:
	.space 4
slei_test2:
	.space 4
slei_test3:
	.space 4

sgtui_test1:
	.space 4
sgtui_test2:
	.space 4
sgtui_test3:
	.space 4

sgti_test1:
	.space 4
sgti_test2:
	.space 4
sgti_test3:
	.space 4

sgeui_test1:
	.space 4
sgeui_test2:
	.space 4
sgeui_test3:
	.space 4

sgei_test1:
	.space 4
sgei_test2:
	.space 4
sgei_test3:
	.space 4

snei_test1:
	.space 4
snei_test2:
	.space 4
snei_test3:
	.space 4

seqi_test1:
	.space 4
seqi_test2:
	.space 4
seqi_test3:
	.space 4



jr_test1:
	.space 4
jr_test2:
	.space 4


jalr_test1:
	.space 4
jalr_test2:
	.space 4

bnez_test1:
	.space 4
bnez_test2:
	.space 4


srai_test1: 
    .space 4
srai_test2: 
    .space 4
srai_test3:
    .space 4
srai_test4:
    .space 4

srli_test1: 
    .space 4
srli_test2: 
    .space 4
srli_test3:
    .space 4
srli_test4:
    .space 4

slli_test1: 
    .space 4
slli_test2: 
    .space 4
slli_test3:
    .space 4

ori_test1: 
    .space 4
ori_test2: 
    .space 4
ori_test3:
    .space 4

xori_test1: 
    .space 4
xori_test2: 
    .space 4
xori_test3:
    .space 4

sb_test1: 
    .space 4
sb_test2: 
    .space 4
sb_test3:
    .space 4

lbu_test1_temp: 
    .space 4
lbu_test2_temp: 
    .space 4
lbu_test3_temp: 
    .space 4


lbu_test1: 
    .space 4
lbu_test2: 
    .space 4
lbu_test3:
    .space 4

lb_test1_temp: 
    .space 4
lb_test2_temp: 
    .space 4
lb_test3_temp: 
    .space 4


lb_test1: 
    .space 4
lb_test2: 
    .space 4
lb_test3:
    .space 4

lhu_test1_temp: 
    .space 4
lhu_test2_temp: 
    .space 4
lhu_test3_temp: 
    .space 4


lhu_test1: 
    .space 4
lhu_test2: 
    .space 4
lhu_test3:
    .space 4

sw_test1: 
    .space 4
sw_test2: 
    .space 4
sw_test3: 
    .space 4

lw_test1_temp: 
    .space 4
lw_test2_temp: 
    .space 4
lw_test3_temp: 
    .space 4


lw_test1: 
    .space 4
lw_test2: 
    .space 4
lw_test3:
    .space 4


addi_test1: 
    .space 4
addi_test2: 
    .space 4
addi_test3: 
    .space 4

beqz_test1: 
    .space 4
beqz_test2: 
    .space 4

andi_test1: 
    .space 4

j_test1: 
    .space 4

jal_test1: 
    .space 4
jal_test2: 
    .space 4

add_test1: 
    .space 4
add_test2: 
    .space 4
add_test3: 
    .space 4

addu_test1: 
    .space 4
addu_test2: 
    .space 4
addu_test3: 
    .space 4
    
addui_test1: 
    .space 4
addui_test2: 
    .space 4
addui_test3: 
    .space 4

sub_test1: 
    .space 4
sub_test2: 
    .space 4
sub_test3: 
    .space 4

subi_test1: 
    .space 4
subi_test2: 
    .space 4
subi_test3: 
    .space 4
    
subu_test1: 
    .space 4
subu_test2: 
    .space 4
subu_test3: 
    .space 4

subui_test1: 
    .space 4
subui_test2: 
    .space 4
subui_test3: 
    .space 4
    
seq_test1: 
    .space 4
seq_test2: 
    .space 4

sne_test1: 
    .space 4
sne_test2: 
    .space 4

sge_test1: 
    .space 4
sge_test2: 
    .space 4
sge_test3: 
    .space 4
sge_test4: 
    .space 4

sgeu_test1: 
    .space 4
sgeu_test2: 
    .space 4
sgeu_test3: 
    .space 4
sgeu_test4: 
    .space 4

sgt_test1: 
    .space 4
sgt_test2: 
    .space 4
sgt_test3: 
    .space 4
sgt_test4: 
    .space 4

sgtu_test1: 
    .space 4
sgtu_test2: 
    .space 4
sgtu_test3: 
    .space 4
sgtu_test4: 
    .space 4

sle_test1: 
    .space 4
sle_test2: 
    .space 4
sle_test3: 
    .space 4
sle_test4: 
    .space 4

sleu_test1: 
    .space 4
sleu_test2: 
    .space 4
sleu_test3: 
    .space 4
sleu_test4: 
    .space 4

slt_test1: 
    .space 4
slt_test2: 
    .space 4
slt_test3: 
    .space 4
slt_test4: 
    .space 4

sltu_test1: 
    .space 4
sltu_test2: 
    .space 4
sltu_test3: 
    .space 4
sltu_test4: 
    .space 4

and_test1: 
    .space 4
and_test2: 
    .space 4

xor_test1: 
    .space 4
xor_test2: 
    .space 4

xor_xorswap1:
    .space 4
xor_xorswap2:
    .space 4

or_test1:
    .space 4

sll_test1:
    .space 4
sll_test2:
    .space 4

srl_test1:
    .space 4
srl_test2:
    .space 4

sra_test1:
    .space 4
sra_test2:
    .space 4

lhi_test1:
    .space 4

imul_test1:
    .space 4
imul_test2:
    .space 4
imul_test3:
    .space 4
imul_test4:
    .space 4

idiv_test1:
    .space 4
idiv_test2:
    .space 4
idiv_test3:
    .space 4
idiv_test4:
    .space 4

imod_test1:
    .space 4
imod_test2:
    .space 4
imod_test3:
    .space 4
imod_test4:
    .space 4

example:
    .space 4
