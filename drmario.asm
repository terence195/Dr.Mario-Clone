################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Terence Yang, 1010204501
# Student 2: Jessie Wang, 1009102141 (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    64
# - Display height in pixels:   64
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

# Add these variables for tracking capsule position and state
current_x: .word 10    # Starting X position (middle of screen)
current_y: .word 3     # Starting Y position (near top)
capsule_color1: .word 0  # First pill color
capsule_color2: .word 0  # Second pill color
orientation: .word 0     # 0=horizontal, 1=vertical
prev_x: .word 10     # Add these variables to store previous position
prev_y: .word 6
prev_orientation: .word 0

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
    
    # Initialize border
    li $t4, 0xffffff
    sw $t4, 540($t0)
    sw $t4, 412($t0)
    sw $t4, 440($t0)
    sw $t4, 568($t0)
    # Now use the random number generator

    jal randomize_color
    
    li $t5, 5               # Y-coordinate
    li $t6, 2               # Start X
    
    jal top_loop
    jal bottom_loop
    jal left_loop
    
    # Initialize capsule colors
    jal randomize_color
    sw $t1, capsule_color1    # Store first color
    jal randomize_color
    sw $t1, capsule_color2    # Store second color
    
    j game_loop

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
    lw $t3, ADDR_KBRD
    lw $t8, 0($t3)
    beqz $t8, check_fall    # If no key pressed, check if we should fall
    lw $t9, 4($t3)          # Get the key that was pressed

    beq $t9, 0x61, move_left      # pressed a
    beq $t9, 0x64, move_right     # pressed d
    beq $t9, 0x73, move_down      # pressed s
    beq $t9, 0x77, rotate_capsule # pressed w
    beq $t9, 0x71, exit_game      # pressed q

check_fall:
    # Add automatic falling logic here
    j draw_capsule

move_left:
    # Store current position as previous
    lw $t0, current_x
    sw $t0, prev_x
    lw $t0, current_y
    sw $t0, prev_y
    lw $t0, orientation
    sw $t0, prev_orientation
    
    # Then do the move
    lw $t0, current_x
    beq $t0, 3, game_loop    # Don't move if at left border
    addi $t0, $t0, -1        # Decrease X position
    sw $t0, current_x
    j draw_capsule

move_right:
    # Store current position as previous
    lw $t0, current_x
    sw $t0, prev_x
    lw $t0, current_y
    sw $t0, prev_y
    lw $t0, orientation
    sw $t0, prev_orientation
    
    # Then do the move
    lw $t0, current_x
    lw $t1, orientation
    beqz $t1, check_horizontal_right
    beq $t0, 18, game_loop   # Don't move if at right border (vertical)
    j do_move_right
check_horizontal_right:
    beq $t0, 17, game_loop   # Don't move if at right border (horizontal)
do_move_right:
    addi $t0, $t0, 1        # Increase X position
    sw $t0, current_x
    j draw_capsule

move_down:
    # Store current position as previous
    lw $t0, current_x
    sw $t0, prev_x
    lw $t0, current_y
    sw $t0, prev_y
    lw $t0, orientation
    sw $t0, prev_orientation
    
    # Then do the move
    lw $t0, current_y
    beq $t0, 27, game_loop   # Don't move if at bottom
    addi $t0, $t0, 1        # Increase Y position
    sw $t0, current_y
    j draw_capsule

rotate_capsule:
    # Store current position as previous
    lw $t0, current_x
    sw $t0, prev_x
    lw $t0, current_y
    sw $t0, prev_y
    lw $t0, orientation
    sw $t0, prev_orientation
    
    # Then do the rotation
    lw $t0, orientation
    xori $t0, $t0, 1        # Toggle between 0 and 1
    sw $t0, orientation
    j draw_capsule

draw_capsule:
    # First clear the previous position
    lw $t0, ADDR_DSPL
    lw $t1, prev_x
    lw $t2, prev_y
    lw $t3, prev_orientation

    # Calculate previous position
    sll $t6, $t2, 5        # Multiply Y by 32
    add $t6, $t6, $t1      # Add X
    sll $t6, $t6, 2        # Multiply by 4 for byte address
    add $t6, $t6, $t0      # Add base display address

    # Clear first pill
    sw $zero, 0($t6)

    # Clear second pill based on previous orientation
    beqz $t3, clear_horizontal
    # Vertical orientation
    addi $t6, $t6, 128     # Move down one row
    j clear_second
clear_horizontal:
    addi $t6, $t6, 4       # Move right one column
clear_second:
    sw $zero, 0($t6)

    # Now draw new position
    lw $t0, ADDR_DSPL
    lw $t1, current_x
    lw $t2, current_y
    lw $t3, orientation
    lw $t4, capsule_color1
    lw $t5, capsule_color2

    # Calculate new position
    sll $t6, $t2, 5        # Multiply Y by 32
    add $t6, $t6, $t1      # Add X
    sll $t6, $t6, 2        # Multiply by 4 for byte address
    add $t6, $t6, $t0      # Add base display address

    # Draw first pill
    sw $t4, 0($t6)

    # Draw second pill based on orientation
    beqz $t3, draw_horizontal
    # Vertical orientation
    addi $t6, $t6, 128     # Move down one row
    j draw_second
draw_horizontal:
    addi $t6, $t6, 4       # Move right one column
draw_second:
    sw $t5, 0($t6)

    # Add sleep delay
    li $v0, 32           # syscall for sleep
    li $a0, 50          # sleep for 50 milliseconds
    syscall

    j game_loop

exit_game:
    li $v0, 10
    syscall
