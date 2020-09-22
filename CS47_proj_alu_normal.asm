.include "./cs47_proj_macro.asm"
.text
.globl au_normal
# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:
# TBD: Complete it
	beq 	$a2, 0x2D, subtraction	# 2D = -
	beq	$a2, 0x2B, addition	# 2B = +
	beq	$a2, 0x2F, division 	# 2F = /
	beq	$a2, 0x2A, multiply	# 2A = *	
addition:
	add	$v0, $a0, $a1
	j	return
	
subtraction:
	sub	$v0, $a0, $a1
	j 	return
division:
	div	$v0, $a0, $a1
	mflo	$v0
	mfhi	$v1
	j	return
multiply:
	mult	$a0, $a1
	mflo	$v0
	mfhi	$v1
	j	return

return:
	jr	$ra
	

