# Add you macro definition here - do not touch cs47_common_macro.asm"
#<------------------ MACRO DEFINITIONS ---------------------->#
# allows for a single bit to be select within a given register
# Macro: retrieve_bit
# Usage: retrieve_bit($val, $targ, $shf)
.macro retrieve_bit($val, $targ, $shf)
	li	$t6, 31			# max possible shift amount
	sub	$t6, $t6, $shf 		# shift amount for current selected bit
	sllv	$t7, $val, $t6		# delete all values before selected bit
	srlv	$t7, $t7, $t6		# reset bit position
	srlv	$t7, $t7, $shf		# delete all values on right of selected bit
	move	$targ, $t7		# return selected bit moved to lsb position
.end_macro

# Macro set_bit
# Usage: retrieve_bit($val, $targ, $pos)
.macro set_bit($val, $targ, $pos)
	sllv	$t7, $val, $pos		# stores proper value at correct position in t7
	or	$targ, $targ, $t7	# assigns val to targ register at given pos
.end_macro
	
