################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Terence Yang, 1010204501
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       16
# - Unit height in pixels:      16
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    lw $t0, ADDR_DSPL
    # Seed the random number generator FIRST
    li $v0, 40          # System call for seeding random
    li $a0, 12345       # Some initial seed value
    li $a1, 0           # Use the default generator (id 0)
    syscall
    
    li $t4, 0xffffff
    sw $t4, 540($t0)
    sw $t4, 412($t0)
    sw $t4, 440($t0)
    sw $t4, 568($t0)
    # Now use the random number generator
    jal randomize_color
    sw $t1, 424($t0)
    
    jal randomize_color
    sw $t1, 428($t0)

    jal randomize_color
    
    li $t5, 5               # Y-coordinate
    li $t6, 2               # Start X
top_loop:
    bgt $t6, 7, top_done   # Exit when X > 19
    sll $a0, $t5, 5         # Calculate address offset
    add $a0, $a0, $t6
    sll $a0, $a0, 2
    add $a0, $a0, $t0
    sw $t4, 0($a0)          # Draw red pixel
    addi $t6, $t6, 1        # Increment X
    j top_loop
top_done:

    li $t5, 5               # Y-coordinate
    li $t6, 14               # Start X
top_loop2:
    bgt $t6, 19, top_done2   # Exit when X > 19
    sll $a0, $t5, 5         # Calculate address offset
    add $a0, $a0, $t6
    sll $a0, $a0, 2
    add $a0, $a0, $t0
    sw $t4, 0($a0)          # Draw red pixel
    addi $t6, $t6, 1        # Increment X
    j top_loop2
top_done2:
  
li $t5, 5               # Start Y
right_loop:
    bgt $t5, 28, right_done # Exit when Y > 28
    sll $a0, $t5, 5
    add $a0, $a0, 19
    sll $a0, $a0, 2
    add $a0, $a0, $t0
    sw $t4, 0($a0)
    addi $t5, $t5, 1
    j right_loop
right_done:

li $t5, 28              # Y-coordinate
    li $t6, 19              # Start X
bottom_loop:
    blt $t6, 2, bottom_done # Exit when X < 2
    sll $a0, $t5, 5
    add $a0, $a0, $t6
    sll $a0, $a0, 2
    add $a0, $a0, $t0
    sw $t4, 0($a0)
    addi $t6, $t6, -1       # Decrement X
    j bottom_loop
bottom_done:

   li $t5, 28              # Start Y
left_loop:
    blt $t5, 5, left_done   # Exit when Y < 5
    sll $a0, $t5, 5
    add $a0, $a0, 2
    sll $a0, $a0, 2
    add $a0, $a0, $t0
    sw $t4, 0($a0)
    addi $t5, $t5, -1       # Decrement Y
    j left_loop
left_done:

randomize_color:
    li $v0, 42       # Random int syscall
    li $a0, 0        # Random generator ID
    li $a1, 3        # Upper bound (0-2 for 3 colors)
    syscall      
    
    move $t2, $a0
    beq $t2, 0, choose_red
    beq $t2, 1, choose_green
    beq $t2, 2, choose_blue

choose_red:
    li $t1, 0xff0000    # Red color
    j done_randomizing

choose_green:
    li $t1, 0x00ff00    # Green color
    j done_randomizing

choose_blue:
    li $t1, 0x0000ff  
    j done_randomizing# Blue color

done_randomizing:
    jr $ra      


game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
