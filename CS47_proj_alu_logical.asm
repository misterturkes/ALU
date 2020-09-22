.include "./cs47_proj_macro.asm"
.text
.globl au_logical
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
# TBD: Complete it
	addi	$sp, $sp, -52
	sw	$a0, 0($sp)
	sw	$a1, 4($sp)
	sw	$a2, 8($sp)
	sw	$a3, 12($sp)
	sw	$fp, 16($sp)
	sw	$s0, 20($sp)	# Store result
	sw	$s1, 24($sp)	# Carry values
	sw	$ra, 28($sp)
	sw	$s2, 32($sp)	#for multiplication and sign checking
	sw	$s3, 36($sp)	#""
	sw	$s4, 40($sp)	#""
	sw	$s5, 44($sp)	#""
	addi	$fp, $sp, 52
	li 	$t0, 0		#bit marker and loop counter
	li	$s0, 0		#initialize at 0
	li	$s1, 0		#initialize at 0
	beq 	$a2, 0x2D, subtract_start 		# 0x2D == -
	beq	$a2, 0x2B, addition_start		# 0x2B == +
	beq	$a2, 0x2A, multiply_start		# 0x2A == *
	beq	$a2, 0x2F, divide_start		# 0x2F == /
	j	restore_frame_return
	
#same thing as adding a negative	
subtract_start:
	nor	$a1, $a1, $zero		# turns the value inside $a1 into the 2's bitwise compliment opposite sign
	li	$s1, 1			# starting with a 1 in our remainder fixes the issue of discrepency caused by inversion
	j	addition_l_loop

#set up to do addition normally
addition_start:
	li	$s1, 0		# starts at 0 only need to carry ones when we add
	j	addition_l_loop
# $s0 --> final number
# $s1 --> carry bit
# $t0 --> bit selected
# utilizes full adder design from book
addition_l_loop:
	slti	$t3, $t0, 32	#keep looping until we reach the end of the register
	beqz	$t3, end_addition_loop	
	retrieve_bit($a0, $t1, $t0)
	retrieve_bit($a1, $t2, $t0)
	xor	$t4, $t2, $t1	# check if only one of the operand has a one in the current position
	and	$t5, $t4, $s1	# check if we have a 1 in this position and a remainder from previous
	xor	$t4, $s1, $t4	# check if its only 1 total remainder to put a 1 in current position
	and	$t6, $t1, $t2	# check for remainder from current position
	or	$s1, $t5, $t6	# check if there will be another remainder next loop
	set_bit($t4, $s0 $t0)	# place bit 
	addi	$t0, $t0, 1	#increment position by 1
	j	addition_l_loop
	
# $s0 --> hi saved
# $s1 --> lo saved and multiplier
# $s2 --> multiplicand
# $s3 --> loop count
# $s4 and $s5 --> two's compliment sign holders
multiply_start:
	or	$s1, $a1, $zero		#store into proper saved regs
	or	$s2, $a0, $zero	
	li	$s0, 0			# reset reg
	li	$t0, 31			# selects sign bit
	retrieve_bit($a0, $s4, $t0)	# get multiplicand sign
	retrieve_bit($a1, $s5, $t0)	# get multiplier sign
	beqz	$s4, invert_fixed_a0	# is multiplicand Negative?
	j	invert_a0
	
multiplication_loop_initialize:
li	$s0, 0			# with inversions data could've been stored in $s0 so reset		
li	$s3, 32			# total number of loops we are going to do
j	multiplication_loop

# multiplication is achieved by selecting multiplier bits and adding the multiplicand to the hi after shifting
# based on multiplier bit location.
multiplication_loop:
	beqz	$s3, fix_signs		# finished loop fix the signs
	retrieve_bit($s1, $t1, $zero)	# current multiplier bit
	beqz	$t1, shift_for_next_bit# if current multiplier bit is 0 no addition is needed
	or	$a1, $s0, $zero		# hi register to be added too
	li	$a2, 0x2B		# call for addition
	jal	au_logical
	or	$s0, $v0, $zero		# store new value in hi
	j	shift_for_next_bit
	
# inverts register a0 and puts it into s2	
invert_a0:
	jal	inverter		# if yes make a0 positive
	or	$s2, $v0, $zero		# store into saved
	or	$a0, $s2, $zero		# restore fixed value to $a0
	j	invert_fixed_a0		# jump to next test
	
# checks if a1 is negative, if so it inverts it and stores it inside s1	
invert_fixed_a0:
	beqz	$s5, multi_or_divide	# is a1 negative?
	or	$a0, $a1, $zero		# yes assign to correct arguement register for inversion
	jal	inverter		# invert a1
	or	$s1, $v0, $zero		# assign to proper saved reg
	or	$a0, $s2, $zero		# restore a0 initial value to proper arguement register
	j 	multi_or_divide		# jump to final setup for multiplication loop

# in order to not copy code, both multiplication and division need to check for 
# negative signs and turn them positive, this allow for the checking code to be the same
# yet each initialize and start their loops separately
multi_or_divide:
	beq	$a2, 0x2A, multiplication_loop_initialize		# 0x2A == *
	beq	$a2, 0x2F, division_loop_initialize			# 0x2F == /
	
# after every loop of multiplication (whether the multiplier had a 1 or 0 in the current
# multiplier bit) the register needs to shift to setup for the next multiplier bit (works like a queue)
shift_for_next_bit:
	srl	$s1, $s1, 1		# shift lo/multiplier register right one to allow for insertion of next msb and
					# setup for next multiplier bit to be selected
	retrieve_bit($s0, $t1, $zero)	# get lowest bit in hi register
	li	$t3, 31			# new empty bit location for shift
	set_bit($t1, $s1, $t3)		# inserts lowest bit in hi into msb position of lo
	srl	$s0, $s0, 1		# removes bit in lsb location of hi
	addi	$s3, $s3, -1		# reduce counter by 1
	j	multiplication_loop
	
# based on saved signs ($s4, $s5) it will flip the sign of the total
# number stored in lo and hi($s1, $s0)
fix_signs:
	xor	$t0, $s4, $s5		# if only one has a negative sign (1) then the final value will be negative
	beqz	$t0, multi_return	# if both multiplicand and multiplier were negative or positive there will no need to change the signs
	or	$a0, $s1, $zero		# move low into register to invert (need to add the 1 discrepancy)
	jal	inverter
	or	$s1, $v0, $zero		# move inverted number back into lo register
	nor	$s0, $s0, $zero		# inverts hi register no need to add the 1 discrepancy as taken care of in lo
	j	multi_return
	
# loads the lo and hi with the correct values and calls the frame restore
multi_return:
	or	$v0, $s1, $zero
	or	$v1, $s0, $zero
	j	restore_frame_return

# $a0-->$s2 --> starting dividend
# $a1-->$s1 --> divisor
# $s3--> counter/quotient
divide_start:
	or	$s1, $a1, $zero		# store operands
	or	$s2, $a0, $zero
	li	$t1, 31			# negative checker location
	retrieve_bit($a0, $s4, $t1)	# sign stored
	retrieve_bit($a1, $s5, $t1)
	beqz	$s4, invert_fixed_a0	# is a0 Negative?
	j	invert_a0
	
division_loop_initialize: 
	or	$a1, $s1, $zero		# insure that $a1 is set to positive value for subtractions
	li	$a2, 0x2D		# call subtraction to do division
	li	$s3, 0 			# set counter
	j	division_loop

# subtracts the divisor from our running dividend until the maximum value is reached or
# it can no longer whole subtract the divisor from the dividend
division_loop:
	slt	$t0, $s2, $s1		# if we can no longer subtract from dividend branch
	bnez	$t0, division_set_values
	or	$a0, $s2, $zero		# put current dividend into $a0 for subtraction
	jal	au_logical
	or	$s2, $v0, $zero		# put new dividend value back into $s2	
	addi	$s3, $s3, 1		# increment counter/quotient
	j	division_loop
	
# check to see if remainder or quotient need to be inverted
division_set_values:
	xor	$t3, $s4, $s5			# saved sign values if both are negative or positive stay positive, else negative quotient
	beqz	$t3, fixed_inversion_quotient	# if no need to invert jump to remainded
	or	$a0, $s3, $zero			# invert
	jal	inverter
	or	$s3, $v0, $zero
	j	fixed_inversion_quotient
	
# checks to see if remainder needs to be inverted based on initial sign of dividend	
fixed_inversion_quotient:
	beqz	$s4, fixed_inversion_remainder		#saved sign of dividend
	or	$a0, $s2, $zero
	jal	inverter
	or	$s2, $v0, $zero
	j	fixed_inversion_remainder

# assign to proper registers for output v1 --> remainder v2 --> quotient
fixed_inversion_remainder:
	or	$v1, $s2, $zero
	or	$v0, $s3, $zero
	j	restore_frame_return
	
# takes the number inside $a0, does the bitwise nor of it to change the sign
# since there is a discrepancy between negative and positive numbers a one must
# be added thus a au_logical call is made to add the 1 to the new inverted
# number and then the frame is restored
inverter:
	addi	$sp, $sp, -24
	sw	$a0, 0($sp)		# store the frame
	sw	$a1, 4($sp)
	sw	$a2, 8($sp)
	sw	$fp, 12($sp)
	sw	$ra, 16($sp)
	addi	$fp, $sp, 24
	li	$a1, 1			# one to be added to fix neg and pos discrepancy
	nor	$a0, $zero, $a0		# bitwise nor of $a0 inverting value
	li	$a2, 0x2B		# operand call of '+'
	jal	au_logical		# execute addition
	lw	$a0, 0($sp)		# restore frame
	lw	$a1, 4($sp)
	lw	$a2, 8($sp)
	lw	$fp, 12($sp)
	lw	$ra, 16($sp)
	addi	$sp, $sp, 24
	jr	$ra			# return to previous operation

# for addition storing in proper output register
end_addition_loop:
	or	$v0, $s0, $zero
	j	restore_frame_return
	
# does what it says
restore_frame_return:
	lw	$a0, 0($sp)
	lw	$a1, 4($sp)
	lw	$a2, 8($sp)
	lw	$a3, 12($sp)
	lw	$fp, 16($sp)
	lw	$s0, 20($sp)
	lw	$s1, 24($sp)
	lw	$ra, 28($sp)
	lw	$s2, 32($sp)
	lw	$s3, 36($sp)
	lw	$s4, 40($sp)
	lw	$s5, 44($sp)
	addi	$sp, $sp, 52
	jr 	$ra
