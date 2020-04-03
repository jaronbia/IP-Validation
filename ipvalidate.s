.arch   armv7
.cpu    cortex-a53
.fpu    neon-fp-armv8
.global main
.text

@------------ Error Message ----------------

invalidNumberFormat:
	mov	R0, #1
	ldr	R1, =invalidnumformat
	mov	R2, #invnumformatsz
	bl	write
	b	end

invalidCharFormat:
	mov	R0, #1
	ldr	R1, =invalidchar
	mov	R2, #invcharsz
	bl	write
	b	end

invalidFormat:
        mov     R0, #1
        ldr     R1, =invalidformat
        mov     R2, #invformatsz
        bl      write
        b       end


@------------ Validate Ip Address ----------

getbinaryIP:
	push	{lr}
	push	{R4-R12}
	push	{R0-R3}

	mov	R4, #4		@ start at 4 and decrement down to 0
	mov	R7, #2		@ divide by 2
	ldr	R12, =binarychar	@ 32 bit representation of ip address

binouterloop:
	cmp     R4, #0
        beq     donebinary

	mov	R5, #8		@ set at 8 to append bits from back to front

	pop	{R6}		@ number to divide

	mul	R11, R5, R4	@ index at which to add the 0 or 1
	sub	R11, R11, #1	@ where to begin storing new bits

bininnerloop:
	cmp     R5, #0          @ if number is 1 reset bin
        beq     resetbin

	udiv	R8, R6, R7	@ divide num by 2
	mul	R9, R8, R7	@ multiple by 2 to see if there is a remainder
	sub	R10, R6, R9	@ get remainder

	mov	R6, R8		@ set to new number to keep division going

	cmp	R6, #1		@ if number is 1 automatically set bit to 1
	moveq	R9, #1

	add	R10, R10, #48	@ make bits readable by converting to chars
	strb	R10, [R12, R5]

	cmp	R5, #0		@ if number is 1 reset bin
	beq	resetbin

	sub	R5, R5, #1	@ index where to store from back to front
	b	bininnerloop

resetbin:
	sub	R4, R4, #1
	bl	addbits
	b	binouterloop

donebinary:
	pop	{R4-R12}
	pop	{pc}

@--------------- Zero Out bits -------------------

zerobits:
	push	{R4-R12}

	ldr	R4, =binarychar
	mov	R5, #8
	mov	R6, #0

zeroloop:
	cmp	R5, #0
	b	donezero

	strb	R6, [R4, R5]

	sub	R5, R5, #1

donezero:
	pop	{R4-R12}
	mov	pc, lr

@---------------- Add Bits to memory -------------

addbits:
	push	{R4-R12}

	mov	R5, #8
	ldr	R6, =ipbits

addbitsloop:
	ldrb	R4, [R12, R5]
	strb	R4, [R6, R11]

	sub	R5, R5, #1
	sub	R11, R11, #1

	cmp	R5, #0
	beq	doneaddbits
	b	addbitsloop

doneaddbits:
	pop	{R4-R12}
	mov	pc, lr

@---------- Checking character validity ------

isvalidchar:
	push	{R4-R12}
	cmp	R5, #0
	beq	donechar
	cmp	R5, #46
	beq	donechar
	cmp	R5, #48
	blt	invalidCharFormat
	cmp	R5, #57
	bgt	invalidCharFormat

donechar:
	pop	{R4-R12}
	mov	pc, lr

@---------- Retrieve Ip Address --------------

retrieveIP:
	push	{lr}
	push	{R4-R12}
	mov	R4, #0		@ ip index value, indexes ip address
	ldr	R6, [R1, #4]	@ load ip address entered
	mov	R9, #0		@ result
	mov	R10, #10	@ multiple of 10 to multiply R8 by
	bl	getnumlength	@ get value for R8
	mov	R12, #0		@ '.' counter

retrievalloop:
	ldrb	R5, [R6, R4]	@ extract individual bits of ip address

	bl	isvalidchar

	add	R4, R4, #1	@ increment ip index to find next char

	cmp     R5, #0          @ null terminated
        beq     retrievaldone

	cmp	R5, #46		@ if '.' reset values
	beq	reset

retrieveNum:
	sub	R5, R5, #48	@ convert char of number to integer of number
	mul	R5, R5, R8	@ multiply number by place value
	add	R9, R9, R5	@ add it to result

	cmp	R9, #255	@ not valid ip address format, too many numbers in a section
	bgt	invalidNumberFormat

	udiv	R8, R8, R10	@ increment by mul 10
	b	retrievalloop

reset:
	push	{R9}
	bl	getnumlength
	mov	R9, #0		@ reset result
	add	R12, R12, #1	@ adds '.' counter
	cmp	R12, #4
	beq	invalidFormat
	b	retrievalloop

retrievaldone:
	push	{R9}
	pop	{R0-R3}		@ numbers that compose ip address
	pop	{R4-R12}
	pop	{pc}

getnumlength:
	mov	R11, R4
	mov	R8, #1

lengthloop:
	ldrb	R5, [R6, R11]

	cmp	R5, #46
	beq	lengthdone

	cmp	R5, #0
	beq	lengthdone

	mul	R8, R8, R10
	add	R11, R11, #1
	b	lengthloop

lengthdone:
	udiv	R8, R8, R10
	mov	pc, lr

@----------------- Main ------------------

main:
	bl	retrieveIP	@ extract numbers from ip address
	bl	getbinaryIP	@ get 32 bit binary representation
bits:
	mov	R0, #1
	ldr	R1, =binaryis
	mov	R2, #bsz
	bl	write

	mov	R0, #1
	ldr	R1, =ipbits
	mov	R2, #ipbitssz
	bl	write
end:
	mov     R0, #1
        ldr     R1, =out
        mov     R2, #outsz
        bl      write

	mov	R7, #1
	swi	0

.data
invalidnumformat:.ascii	"\nError invalid number format"
		.equ	invnumformatsz, (.-invalidnumformat)
invalidchar:	.ascii  "\nError invalid character"
                .equ    invcharsz, (.-invalidchar)
invalidformat:  .ascii  "\nInvalid IP format"
		.equ	invformatsz, (.-invalidformat)
binaryis:	.ascii	"\nBinary: "
		.equ	bsz, (.-binaryis)
out:		.ascii  "\n"
		.equ	outsz, (.-out)
binarychar:	.space 8, 0
		.equ	bincharsz, (.-binarychar)
ipbits:		.space 32, 0
		.equ	ipbitssz, (.-ipbits)
