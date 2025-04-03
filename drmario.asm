################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
#
# Student 1: Terence Yang
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
BOARD_COLOR: .word 0xdbc7be
CLEAR_PIXEL: .word 0x000000
CAPSULE_COLORS: .word 0xf45b69, 0x456990 , 0x80d39b


##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
VIRUS_MAP: .space 4096
# Counter for gravity timer
GRAVITY_COUNTER: .word 0
# Timer threshold for gravity (60 cycles ≈ 1 second at 60 FPS)
GRAVITY_THRESHOLD: .word 30
# Counter for cleared lines
CLEARED_LINES: .word 0
# Current level (increases as lines are cleared)
CURRENT_LEVEL: .word 1
# Storage for next 4 capsules (8 colors - left and right for each capsule)
NEXT_CAPSULES: .space 32  # 8 words (4 capsules x 2 colors per capsule)
# Music data
music_theme:
    .word 75, 25   # Asharp (?) idk i don't hae perf pitch)
     .word 76, 25
    .word 75, 25
    .word 76, 25
    .word 74, 25
    .word 72, 25
    .word 72, 25
    .word 74, 25

    .word 75, 25
    .word 76, 25
    .word 74, 25
    .word 72, 25
    .word 72, 100  # 
music_length: .word 13  
current_note_index: .word 0  
music_timer: .word 0  # tracks when to play next note

##############################################################################
# Code
##############################################################################
	.text
	.globl main
main:
    lw $t0, ADDR_DSPL
    lw $t1, ADDR_KBRD
    
    lw $t2, CLEAR_PIXEL  # clear the display 
    li $t3, 0            # clear initial position
    
    jal clear_gameboard  # make whole screen black
    jal clear_virus_map
    jal draw_bottle_border
    jal draw_mario       # Explicitly call to draw Dr. Mario

    jal generate_viruses      # spawn the viruses
  
    j game_loop

    
game_loop:
    # Reload the keyboard address each time to prevent it being lost between function calls
    lw $t1, ADDR_KBRD
    
    # Play a startup sound if this is the first frame
    lw $t8, current_note_index
    bnez $t8, continue_game_loop
    
    # Play a distinctive startup sound
    li $a0, 60              # middle c
    li $a1, 300             # Duration
    li $a2, 0               # Piano
    li $a3, 127             # volune
    li $v0, 31              # syscall t play
    syscall
    
continue_game_loop:
    jal play_background_music
    
    # gravity - check to automatically move down
    lw $t8, GRAVITY_COUNTER
    lw $t9, GRAVITY_THRESHOLD
    addi $t8, $t8, 1           # speed of gravity, higher = faster
    sw $t8, GRAVITY_COUNTER    # Store updated counter
    
    # If counter has reached threshold, apply gravity
    blt $t8, $t9, check_keyboard
    
    # Reset gravity counter
    sw $zero, GRAVITY_COUNTER
    
    # Apply gravity by calling move_down
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal move_down
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
##############################################################################
# Draw dr. Mario
##############################################################################
draw_mario:
    li $t1, 0x50a9a9
    addi $t2, $t0, 2024   
    sw $t1, 0( $t2 )
    
    addi $t2, $t0, 2152  
    sw $t1, 0( $t2 )

    li $t1, 0x7C553D
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    li $t1, 0xf2d0a6
    addi $t2, $t0, 2280    
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    
    li $t1, 0x7C553D
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    li $t1, 0xf2d0a6
    addi $t2, $t0, 2408   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )

    addi $t2, $t0, 2536   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    # mustach line
    addi $t2, $t0, 2664  
    sw $t1, 0( $t2 )
    li $t1, 0x7C553D
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    li $t1, 0xf2d0a6
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    addi $t2, $t0, 2792   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    # head done

    # body
    li $t1, 0x50a9a9
    addi $t2, $t0, 2920   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    li $t1, 0xf2ebdd
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    addi $t2, $t0, 3048   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    addi $t2, $t0, 3176  
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t0, 3304  
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t0, 3432   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    addi $t2, $t0, 3560   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    li $t1, 0x7C553D
    addi $t2, $t0, 3684   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )
    addi $t2, $t2, 4
    sw $t1, 0( $t2 )

    # star
    li $t1, 0xf45b69
    addi $t2, $t0, 3464   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 256
    sw $t1, 0( $t2 )
    addi $t2, $t0, 3588   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )
    li $t1, 0xf0e4d7
    addi $t2, $t0, 3592 
    sw $t1, 0( $t2 )

    # star2
    li $t1, 0x456990
    addi $t2, $t0, 2948  
    sw $t1, 0( $t2 )
    addi $t2, $t2, 256
    sw $t1, 0( $t2 )
    addi $t2, $t0, 3072  
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )

    # star3
    li $t1, 0x80d39b
    addi $t2, $t0, 2440   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 256
    sw $t1, 0( $t2 )
    addi $t2, $t0, 2564   
    sw $t1, 0( $t2 )
    addi $t2, $t2, 8
    sw $t1, 0( $t2 )
    
    jr $ra
######################################################################################################################################################
    
check_keyboard:
    lw $t1, ADDR_KBRD
    # 1a. Check if key has been pressed
    lw $t8, 0($t1)                              # Load first word from keyboard
    bne $t8, 1, game_loop_sleep                       # If first word not 1, no key is pressed
    
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
    # 2b. Update locations (capsules)
    # 3. Draw the screen
    lw $a0, 4($t1)                              # Load second word from keyboard inp
    jal key_pressed                             
    
game_loop_sleep:
    # Check for automatic capsule dropping due to gravity
    jal is_next_state
    
	# 4. Sleep
    li $v0, 32
    li $a0, 16   # Sleep for 16ms
    syscall

    # 5. Go back to Step 1
    j game_loop

clear_gameboard:
    add $t4, $t0, $t3
    sw $t2, 0($t4)
    addi $t3, $t3, 4                # next pixel position
    bne $t3, 4096, clear_gameboard

    jr $ra                          # return

#########################################################################################################################################
# DRAWING GAMEBOARED
########################################################################################################################################## return
draw_bottle_border:
    addi $sp, $sp, -4    # allocate stack space to save return address
    sw $ra, 0($sp)       # save return address

    li $t2, 0xdbc7be            # Load color into $t2 -- will be the color of the bottle (pink)
    
    ############################ bottle's neck ####################################################
    # Draw pixel (5, 10)
    addi $t4, $t0, 640         
    addi $t4, $t4, 40          
    sw $t2, 0($t4)             # Store color at (6, 10)

    # Draw pixel (4, 10)
    addi $t4, $t0, 512         
    addi $t4, $t4, 40           
    sw $t2, 0($t4)             # Store color at (5, 10)

    # bottle's nectk right side
    # Draw pixel (5, 15)
    addi $t4, $t0, 640         
    addi $t4, $t4, 60           
    sw $t2, 0($t4)             # Store color at (6, 10)

    # Draw pixel (4, 15)
    addi $t4, $t0, 512        
    addi $t4, $t4, 60        
    sw $t2, 0($t4)             # Store color at (5, 10)

    ############################ bottle's neck horiz leftside ####################################
    # bottle top leftside horizontal part
    # Starting addresses at (6, 4)
    addi $t4, $t0, 768         # Row offset for row 6 (6 * 128 bytes)
    addi $t4, $t4, 16           # Column offset for column 4 (4 * 4 bytes)

    # Initialize loop counter
    li $t9, 0                  # Set loop counter $t9 to 0
    li $t8, 7                  # Loop limit to 7 pixels so it will draw 7 pixels later

    draw_loop_top_left_horizontal:
        # Draw the color at the current calculated address in $t2
        sw $t2, 0($t4)             # Store color (at address $t2) at the current pixel
    
        # Go next pixel to the right (add 4 bytes to the address)
        addi $t4, $t4, 4        
    
        # Increment loop counter at $t9
        addi $t9, $t9, 1          
    
        # Check if we have drawn 7 pixels
        bne $t9, $t8, draw_loop_top_left_horizontal    # Continue if $t9 is not equal to $t8

        ############################ bottle's neck rightside ##########################################
        # starting address at (6, 15)
        addi $t4, $t0, 768         # Row offset for row 6 (6 * 128 bytes)
        addi $t4, $t4, 60           # Column offset for column 4 (15 * 4 bytes)
            
        # Initialize loop counter
        li $t9, 0                  # Set loop counter $t9 to 0
        li $t8, 7                  # Set the loop limit to 7 pixels
            
    draw_loop_top_right_horizontal:
        # Draw the color (at addrewss $t1) at the current calculated address in $t2
        sw $t2, 0($t4)             # Store color at the current pixel
    
        # Go next pixel by 4 offset next pixel to the right (add 4 bytes to the address)
        addi $t4, $t4, 4         
    
        # Increment loop counter at $t9
        addi $t9, $t9, 1          
    
        # Check if we have drawn 7 pixels
        bne $t9, $t8, draw_loop_top_right_horizontal    # Continue if $t9 is not equal to $t8

    ############################ bottle's bottom horiz ##############################################
    # starting address for the horizontal line at (29, 4)
    addi $t4, $t0, 3584         # Row offset for row 7 (29 * 128 bytes)
    addi $t4, $t4, 16           # Column offset for column 4 (4 * 4 bytes)
        
    # Initialize loop counter
    li $t9, 0                  # Set loop counter $t9 to 0
    li $t8, 18                  # Set the loop limit to 18 pixels
        
    draw_loop_bottom:
        # Draw the color (at addrewss $t1) at the current calculated address in $t2
        sw $t2, 0($t4)             
    
        # Move to the next pixel to the right (add 4 bytes to the address)
        addi $t4, $t4, 4           # Move to the next pixel in the same row (4 bytes per pixel)
    
        # Increment loop counter
        addi $t9, $t9, 1           # Increment loop counter $t9
    
        # Check if we have drawn 7 pixels
        bne $t9, $t8, draw_loop_bottom    # Continue if $t9 is not equal to $t8

    ############################ bottle's vertitcal #############################################
    # starting address at (7, 4) for left vertical line
    addi $t4, $t0, 896         # Row offset for row 7 with color at t0
    addi $t4, $t4, 16           # Column offset for column 4 

    # starting address (7, 21) for right vertical line
    addi $t5, $t0, 896         # Row offset for row 7 w coor from t0
    addi $t5, $t5, 84           # Column offset for column 21 (21 * 4 bytes)
    li $t8, 21 # limit 21 px coz wna draw 21 px
    li $t9, 0 # the counter variablev
    
    vertical: # draw the vertical lines tgt since they got the same # of pixes in same dir
        sw $t2, 0( $t4 )
        addi $t4, $t4, 128
        sw $t2, 0( $t5 )
        addi $t5, $t5, 128
        addi $t9, $t9, 1
        bne $t9, $t8, vertical
    jal spawn_next_capsule
    jal spawn_starter_capsule
    
    lw $ra, 0($sp)     # Restore return address
    addi $sp, $sp, 4   # Deallocate stack space
    
    jr $ra

#########################################################################################################################################
# DRAWING CAPSULES
#########################################################################################################################################
spawn_starter_capsule:
    # NOTE: CURRENT CAPSULE COLOR IS STORED TO s0 and s1
    addi $sp, $sp, -4   
    sw $ra, 0($sp)      

    # check if bottle is blocked
    lw $t6, CLEAR_PIXEL       # Load the value of CLEAR_PIXEL (black color) into $t6
    lw $t7, 816($t0)          # left entrance (column 4, row 5) -> t7
    bne $t7, $t6, end_game    # If the left entrance is not black, end the game
    lw $t7, 820($t0)          # right_entrance (column 5, row 5) -> t7
    bne $t7, $t6, end_game    # If the right entrance is not black, end the game

    # Set initial capsule positions
    li $s4, 816         # Left block position (row 5, column 4: 5*128 + 4*4 = 640 + 16 = 656)
    li $s5, 820         # Right block position (row 5, column 5: 5*128 + 5*4 = 640 + 20 = 660)

    # Get the first capsule from the queue
    la $t5, NEXT_CAPSULES
    lw $s0, 0($t5)      # Left color of first capsule
    lw $s1, 4($t5)      # Right color of first capsule
    
    # Draw the current capsule
    sw $s0, 816($t0)    # Draw left block of the capsule
    sw $s1, 820($t0)    # Draw right block of the capsule

    # Shift all capsules in the queue forward
    lw $t1, 8($t5)      # Get 2nd capsule left color
    lw $t2, 12($t5)     # Get 2nd capsule right color
    sw $t1, 0($t5)      # Move to 1st position
    sw $t2, 4($t5)      # Move to 1st position
    
    lw $t1, 16($t5)     # Get 3rd capsule left color
    lw $t2, 20($t5)     # Get 3rd capsule right color
    sw $t1, 8($t5)      # Move to 2nd position
    sw $t2, 12($t5)     # Move to 2nd position
    
    lw $t1, 24($t5)     # Get 4th capsule left color
    lw $t2, 28($t5)     # Get 4th capsule right color
    sw $t1, 16($t5)     # Move to 3rd position
    sw $t2, 20($t5)     # Move to 3rd position
    
    # Generate a new capsule for the 4th position
    addi $sp, $sp, -8
    sw $t3, 0($sp)
    sw $t4, 4($sp)
    
    # Save the existing s2, s3 values
    move $t3, $s2
    move $t4, $s3
    
    # Generate new colors for the 4th position
    jal random_color_generator
    
    # Store the new colors at the 4th position
    sw $s2, 24($t5)
    sw $s3, 28($t5)
    
    # Restore s2, s3 to their prior values
    move $s2, $t3
    move $s3, $t4
    
    lw $t4, 4($sp)
    lw $t3, 0($sp)
    addi $sp, $sp, 8
    
    # Update the preview display
    jal draw_capsule_preview

    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Deallocate stack space
    jr $ra               # Return

spawn_next_capsule:
    # INITIALIZES THE CAPSULE QUEUE
    addi $sp, $sp, -4    # Allocate stack space
    sw $ra, 0($sp)       # Save return address

    # Initialize the capsule queue with 4 random capsules
    la $t9, NEXT_CAPSULES
    li $t8, 4            # 4 capsules to generate
    
init_capsule_loop:
    # Generate random colors for the capsule
    addi $sp, $sp, -8
    sw $t8, 0($sp)       # Save loop counter
    sw $t9, 4($sp)       # Save queue position
    
    jal random_color_generator
    
    lw $t9, 4($sp)       # Restore queue position
    lw $t8, 0($sp)       # Restore loop counter
    addi $sp, $sp, 8
    
    # Store the colors in the queue
    sw $s2, 0($t9)       # Store left color
    sw $s3, 4($t9)       # Store right color
    
    # Move to next capsule position in queue
    addi $t9, $t9, 8
    
    # Decrement counter and loop if not done
    addi $t8, $t8, -1
    bgtz $t8, init_capsule_loop
    
    # Draw the capsule preview
    jal draw_capsule_preview

    lw $ra, 0($sp)       # Restore return address
    addi $sp, $sp, 4     # Deallocate stack space
    jr $ra               # Return

# Draws the preview of the next 4 capsules
draw_capsule_preview:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Clear the preview area first
    lw $t7, CLEAR_PIXEL
    
    # Clear preview area (right side of the play field)
    li $t6, 0            # Row counter
    li $t8, 15           # Number of rows to clear
    
clear_preview_loop:
    # Calculate starting position for this row
    mul $t5, $t6, 128    # t5 = row * 128 (bytes per row)
    addi $t5, $t5, 96    # Start at column 24 (96 = 24 * 4)
    add $t5, $t5, $t0    # Add display base address
    
    # Clear 8 pixels in this row
    sw $t7, 0($t5)
    sw $t7, 4($t5)
    sw $t7, 8($t5)
    sw $t7, 12($t5)
    sw $t7, 16($t5)
    sw $t7, 20($t5)
    sw $t7, 24($t5)
    sw $t7, 28($t5)
    
    # Move to next row
    addi $t6, $t6, 1
    blt $t6, $t8, clear_preview_loop
    
    # Now draw each capsule in the preview
    la $t9, NEXT_CAPSULES
    
    # Draw 1st capsule preview (row 2)
    lw $t1, 0($t9)       # Left color
    lw $t2, 4($t9)       # Right color
    addi $t3, $t0, 256   # Row 2
    addi $t3, $t3, 96    # Start at column 24
    sw $t1, 0($t3)       # Draw left
    sw $t2, 4($t3)       # Draw right
    
    # Draw 2nd capsule preview (row 5)
    lw $t1, 8($t9)       # Left color
    lw $t2, 12($t9)      # Right color
    addi $t3, $t0, 640   # Row 5
    addi $t3, $t3, 96    # Start at column 24
    sw $t1, 0($t3)       # Draw left
    sw $t2, 4($t3)       # Draw right
    
    # Draw 3rd capsule preview (row 8)
    lw $t1, 16($t9)      # Left color
    lw $t2, 20($t9)      # Right color
    addi $t3, $t0, 1024  # Row 8
    addi $t3, $t3, 96    # Start at column 24
    sw $t1, 0($t3)       # Draw left
    sw $t2, 4($t3)       # Draw right
    
    # Draw 4th capsule preview (row 11)
    lw $t1, 24($t9)      # Left color
    lw $t2, 28($t9)      # Right color
    addi $t3, $t0, 1408  # Row 11
    addi $t3, $t3, 96    # Start at column 24
    sw $t1, 0($t3)       # Draw left
    sw $t2, 4($t3)       # Draw right
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

random_color_generator:
    addi $sp, $sp, -8        # Allocate stack space for saving registers
    sw $ra, 0($sp)           # Save return address
    sw $t8, 4($sp)           # Save temporary register $t8

    li $t7, 2                # Loop counter (2 iterations: left and right blocks)
    la $t9, CAPSULE_COLORS   # Load color array address
    
    RCG_loop:
        li $v0, 42               # Syscall for random number
        li $a0, 0                # Random generator ID (always 0)
        li $a1, 3                # Upper bound, 3 colors: 0, 1, 2
        syscall                  # Generate random number in $a0
    
        sll $t8, $a0, 2          # t8 = a0 << 2 = a0 * 4 (word size = 4)
        add $t8, $t9, $t8        # Move index to chosen color
        lw $t8, 0($t8)           # Load the selected color
    
        # Assign the color to $s2 (left block) or $s3 (right block)
        beq $t7, 2, set_left_color
        move $s3, $t8            # Set right block color
        j next_color
    
    set_left_color:
        move $s2, $t8            # Set left block color
    
    next_color:
        subi $t7, $t7, 1         # Decrement loop counter
        bnez $t7, RCG_loop # Repeat for the right block
    
        lw $t8, 4($sp)           # Restore temporary register $t8
        lw $ra, 0($sp)           # Restore return address
        addi $sp, $sp, 8         # Deallocate stack space
        jr $ra                   # Return

make_sound_move:
    li $a0, 75    # freq
    li $a1, 100    # duration
    li $a2, 100    # volume
    li $a3, 127    # waveform
    li $v0, 31     # system call no for sound playing
    syscall
    jr $ra
    
key_pressed: 
    # j make_sound
    beq $a0, 0x77, spin_capsule    #W
    beq $a0, 0x61, move_left       #A
    beq $a0, 0x73, move_down       #S
    beq $a0, 0x64, move_right      #D                 
    beq $a0, 0x71, end_game    # q
    
    j game_loop   # if its none of the 

    # s0, s1 stores colors (leftcapsule, right capsule)
    # $s4, $s5 stores capsule position (lef, r)
    
   spin_capsule:
      addi $sp, $sp, -4    # allocate stack space
      sw $ra, 0($sp)       # save return address

      # Reset gravity counter after player action
      sw $zero, GRAVITY_COUNTER
      
      jal rotate

      lw $ra, 0($sp)     # Restore return address
      addi $sp, $sp, 4   # Deallocate stack space
    
      jr $ra     # return

        rotate:
            lw $t7, CLEAR_PIXEL
            
            move $t6, $s4             # move $destination, $source
            addi $t6, $t6, 128        
            beq $t6, $s5, rotate_left # have to rotate left  

            move $t6, $s4             
            addi $t6, $t6, -4
            beq $t6, $s5, rotate_up  # have to rotate up
            
            move $t6, $s4             
            addi $t6, $t6, -128
            beq $t6, $s5, rotate_right # have to rotate right

            move $t6, $s4           
            addi $t6, $t6, 4
            beq $t6, $s5, rotate_down # hae to rotate down
            
            rotate_left:
                addi $t3, $0, 4
                j update_rotation
  
            rotate_up: 
                # collision check
                addi $t3, $0, 128
                j update_rotation

            rotate_right: 
                addi $t3, $0, -4
                j update_rotation
  
            rotate_down: 
                addi $t3, $0, -128
                j update_rotation

        update_rotation:
            # collision check
            add $t5, $s5, $t3    
            add $t5, $t0, $t5   
            lw $t5, 0($t5)          
            bne $t5, $t7, early_return  # collision detected
            
            # erase s4
            add $t5, $t0, $s4
            sw $s7, 0($t5)

            # set new s4
            add $s4, $s5, $t3

            # draw new s4
            add $t5, $t0, $s4
            sw $s0, 0($t5)
            
            # Play sound 
            j make_sound_move        

            jr $ra
      
    move_left:
        # PLAY SOUND FOR MOvvE LEFT - why is my v key broken tf
        li $a0, 50    # Frequency
        li $a1, 300   # Duration
        li $a2, 100   # Volume
        li $a3, 127   # Waveform
        li $v0, 31    # System call for sound playing
        syscall

      lw $t7, CLEAR_PIXEL
      addi $t3, $0, -4

      # Reset gravity counter after player action
      sw $zero, GRAVITY_COUNTER

      move $t6, $s4             # load s4 capsule position (s4 up)
      addi $t6, $t6, 128       
      beq $t6, $s5, vert_collision1  
       
      move $t6, $s4             # s4 right
      addi $t6, $t6, -4
      beq $t6, $s5, horiz_collision1
      
      move $t6, $s4             # s4 down
      addi $t6, $t6, -128
      beq $t6, $s5, vert_collision1  

      move $t6, $s4             # s4 left
      addi $t6, $t6, 4
      beq $t6, $s5, horiz_collision1

  move_down:
        
      lw $t7, CLEAR_PIXEL
      addi $t3, $0, 128
      
      # Reset gravity counter after player action
      sw $zero, GRAVITY_COUNTER
      
      # collision check
      move $t6, $s4             # load s4 capsule position (s4 up)
      addi $t6, $t6, 128       
      beq $t6, $s5, vert_collision2

      move $t6, $s4             # s4 right
      addi $t6, $t6, -4
      beq $t6, $s5, vert_collision1
      
      move $t6, $s4             # s4 down
      addi $t6, $t6, -128
      beq $t6, $s5, is_collideV3

      move $t6, $s4             # s4 left
      addi $t6, $t6, 4
      beq $t6, $s5, vert_collision1
            
        vert_collision2:
            add $t5, $t0, $s5
            j is_collideV4
        
        is_collideV3:
            add $t5, $t0, $s4
            j is_collideV4

        is_collideV4:
            add $t5, $t5, $t3
            lw $t5, 0($t5)
            bne $t5, $t7, early_return  
            
            j update_position   
  
    move_right:

        # # PLAY SOUND FO RMOVE RIGHT - NOTE: THERES A BUG U CAN ONLY MOVE RIGH VERTICALLY WITHT HE SOUND
        # li $a0, 57    # Frequency
        # li $a1, 300   # Duration
        # li $a2, 100   # Volume
        # li $a3, 127   # Waveform
        # li $v0, 31    # System call for sound playing
        # syscall
      
      lw $t7, CLEAR_PIXEL
      addi $t3, $0, 4

      # Reset gravity counter after player actions
      sw $zero, GRAVITY_COUNTER

      move $t6, $s4             # load s4 capsule position (s4 up)
      addi $t6, $t6, 128       
      beq $t6, $s5, vert_collision1  

      move $t6, $s4             # s4 right
      addi $t6, $t6, -4
      beq $t6, $s5, horiz_collision1
      
      move $t6, $s4             # s4 down
      addi $t6, $t6, -128
      beq $t6, $s5, vert_collision1  

      move $t6, $s4             # s4 left
      addi $t6, $t6, 4
      beq $t6, $s5, horiz_collision1
              
  pressed_p: ############################################################################################################
      
      jr $ra     # return

vert_collision1:
    # Check collision for $s4
    add $t5, $s4, $t3        # Calculate new position for $s4
    add $t5, $t0, $t5        # Add base address of the display
    lw $t5, 0($t5)           # Load the value at the new position
    bne $t5, $t7, early_return  # If not empty, return early

    # Check collision for $s5
    add $t5, $s5, $t3        # Calculate new position for $s5
    add $t5, $t0, $t5        # Add base address of the display
    lw $t5, 0($t5)           # Load the value at the new position
    bne $t5, $t7, early_return  # If not empty, return early

    j update_position         # If no collision, update position
    
horiz_collision1:
    # Determine which block to check based on relative positions
    move $t6, $s4
    addi $t6, $t6, -4         # Check if $s4 is to the left of $s5
    beq $t6, $s5, check_collision_c2_L

    move $t6, $s4
    addi $t6, $t6, 4          # Check if $s4 is to the right of $s5
    beq $t6, $s5, check_collision_c1_L
    
    check_collision_c1_L:
        beq $a0, 0x64, check_collision_c2_R  # If moving right, check $s5
        move $t5, $s4             # Otherwise, check $s4
        j horiz_collision2
    
    check_collision_c1_R:
        move $t5, $s4             # Check $s4
        j horiz_collision2
    
    check_collision_c2_L:
        beq $a0, 0x64, check_collision_c1_R  # If moving right, check $s4
        move $t5, $s5             # Otherwise, check $s5
        j horiz_collision2
    
    check_collision_c2_R:
        move $t5, $s5             # Check $s5
        j horiz_collision2
    
    horiz_collision2:
        # Perform collision check for the selected block
        add $t5, $t5, $t3        
        add $t5, $t0, $t5        
        lw $t5, 0($t5)           
        bne $t5, $t7, early_return  
    
        j update_position          # If no collision, update position
    
    update_position:
        # Save return address and allocate stack space
        addi $sp, $sp, -4
        sw $ra, 0($sp)
    
        # Erase the current capsule
        jal erase_capsule
    
        # Update positions of $s4 and $s5
        add $s4, $s4, $t3
        add $s5, $s5, $t3
    
        # Draw the updated capsule
        jal draw_updated_capsule
    
        # Restore return address and deallocate stack space
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
    erase_capsule:
        # Clear the current positions of $s4 and $s5
        add $t5, $t0, $s4
        sw $t7, 0($t5)            # Clear $s4
        add $t5, $t0, $s5
        sw $t7, 0($t5)            # Clear $s5
        jr $ra
    
    draw_updated_capsule:
        # Draw the updated positions of $s4 and $s5
        add $t5, $t0, $s4
        sw $s0, 0($t5)            # Draw $s4
        add $t5, $t0, $s5
        sw $s1, 0($t5)            # Draw $s5
        jr $ra

early_return: 
    jr $ra

clear_line:
    # $s0, $s1 = current capsule colors
    # $s4, $s5 = current capsule positions

    # 放下药丸声音
    li $a0, 79    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # dleya
    li $v0, 32    # Sleep syscall
    li $a0, 100   # Sleep for 100ms
    syscall

    li $a0, 79    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # dleya
    li $v0, 32    # Sleep syscall
    li $a0, 100   # Sleep for 100ms
    syscall
    
    addi $sp, $sp, -20       # allocate stack space and save ret addresss
    sw $ra, 0($sp)           
    sw $s6, 4($sp)           # save $s6 (used for temp)
    sw $s7, 8($sp)           # save $s7 (used for CLEAR_PIXEL)
    sw $t9, 12($sp)          # save $t9 (used for flag)
    sw $s2, 16($sp)          # save $s2 (used for cleared columns array)
    
    # track which columns had cleared matches
    li $s2, 0                # which columns
    lw $s7, CLEAR_PIXEL     
    
    # Initialize line clearing status
    li $t9, 0                # $t9 = whether any lines were cleared this iteration

    
    
scan_board:
    # Start scanning from 3712 (bottom row) and go up
    # Each row is 128 bytes (32 pixels), 17 pixels wide playable area
    li $s6, 3712             # Start at bottom row
    
scan_row_loop:
    # Check if we've reached the top of the board
    li $t8, 928              # End at top of playable area
    blt $s6, $t8, scan_complete  # If we've reached the top, we're done scanning
    
    # Initialize column counter
    li $t7, 16               # Start at column 4 (offset 16)
    
scan_col_loop:
    # Check if we've reached the end of the row
    li $t6, 88           # 17 playable columns (4*17 + 16 = 84, but check just past that)
    beq $t7, $t6, next_row   # If we've finished the row, move to the next row
    
    # Check horizontal match (need 4 consecutive same-colored blocks)
    add $t5, $s6, $t7        
    add $t4, $t0, $t5        # address of curr puxel
    lw $t3, 0($t4)           # Load color of current pixel
    
    # Skip checking if it's a clear pixel or board pixel
    lw $t2, CLEAR_PIXEL
    beq $t3, $t2, next_col   # Skip if clear pixel
    lw $t2, BOARD_COLOR
    beq $t3, $t2, next_col   # Skip if board pixel
    
    # Check horizontal match
    jal check_horizontal
    
    # Check vertical match
    jal check_vertical
    
next_col:
    addi $t7, $t7, 4         # Move to next column
    j scan_col_loop
    
next_row:
    addi $s6, $s6, -128      # Move up to next row
    j scan_row_loop
    
scan_complete:
    # If we cleared any lines, drop capsules in affected columns
    beq $t9, $zero, finish_clearing
    
    # Handle dropping capsules only in affected columns
    jal drop_affected_columns
    
    # Reset cleared status and scan again for any new matches
    li $t9, 0
    j scan_board
    
finish_clearing:
    
    # Restore saved registers
    lw $ra, 0($sp)
    lw $s6, 4($sp)
    lw $s7, 8($sp)
    lw $t9, 12($sp)
    lw $s2, 16($sp)
    addi $sp, $sp, 20
    
    jr $ra

# Check for horizontal match of 4 same-colored blocks
check_horizontal:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $t6, 4($sp)    # Save t6 for column tracking
    
    # Make sure we don't check beyond board boundary
    # For 17 columns starting at column 4 (offset 16), last valid starting point is offset 72
    # (this allows checking positions 72, 76, 80, 84 - the last 4 columns)
    li $t2, 72               # Maximum valid starting position (88 - 4*4)
    bgt $t7, $t2, check_h_done  # Skip if too close to right edge
    
    # Check if next 3 blocks match current color
    lw $t2, 4($t4)           # Check next pixel
    bne $t2, $t3, check_h_done  # If not same color, no match
    
    lw $t2, 8($t4)           # Check pixel+2
    bne $t2, $t3, check_h_done  # If not same color, no match
    
    lw $t2, 12($t4)          # Check pixel+3
    bne $t2, $t3, check_h_done  # If not same color, no match
    
    # We found a match! Clear these 4 blocks and their virus markers
    sw $s7, 0($t4)           # Clear first block
    
    # Clear virus marker if present
    sub $t2, $t4, $t0        # Get offset from display base
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, 4($t4)           # Clear second block
    
    # Clear virus marker if present
    addi $t2, $t2, 4         # Move to next position
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, 8($t4)           # Clear third block
    
    # Clear virus marker if present
    addi $t2, $t2, 4         # Move to next position
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, 12($t4)          # Clear fourth block
    
    # Clear virus marker if present
    addi $t2, $t2, 4         # Move to next position
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    # Mark ALL columns as affected when a match is found
    li $s2, 0xFFFF           # Set all 16 columns as affected
    
    # Set flag that we cleared a line
    li $t9, 1
    
    # Increment the cleared lines counter
    lw $t2, CLEARED_LINES
    addi $t2, $t2, 1
    sw $t2, CLEARED_LINES

    # Check if we should increase difficulty
    jal check_increase_speed
    
check_h_done:
    lw $ra, 0($sp)
    lw $t6, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Check for vertical match of 4 same-colored blocks
check_vertical:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $t6, 4($sp)           # Save $t6
    
    # Make sure we're not too close to top of board
    li $t2, 1024             # Minimum row for vertical check (to avoid going past top)
    blt $s6, $t2, check_v_done  # Skip if too close to top
    
    # Check if next 3 blocks up match current color
    lw $t2, -128($t4)        # Check pixel above
    bne $t2, $t3, check_v_done  # If not same color, no match
    
    lw $t2, -256($t4)        # Check 2 pixels above
    bne $t2, $t3, check_v_done  # If not same color, no match
    
    lw $t2, -384($t4)        # Check 3 pixels above
    bne $t2, $t3, check_v_done  # If not same color, no match
    
    # We found a match! Clear these 4 blocks and their virus markers
    sw $s7, 0($t4)           # Clear current block
    
    # Clear virus marker if present
    sub $t2, $t4, $t0        # Get offset from display base
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, -128($t4)        # Clear block above
    
    # Clear virus marker if present
    addi $t2, $t2, -128      # Move to position above
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, -256($t4)        # Clear 2 blocks above
    
    # Clear virus marker if present
    addi $t2, $t2, -128      # Move to position above
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    sw $s7, -384($t4)        # Clear 3 blocks above
    
    # Clear virus marker if present
    addi $t2, $t2, -128      # Move to position above
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t2        # Calculate virus map position
    sw $zero, 0($t6)         # Clear virus marker
    
    # Mark ALL columns as affected when a match is found
    li $s2, 0xFFFF           # Set all 16 columns as affected
    
    # Set flag that we cleared a line
    li $t9, 1
    
    # Increment the cleared lines counter
    lw $t2, CLEARED_LINES
    addi $t2, $t2, 1
    sw $t2, CLEARED_LINES

    # Check if we should increase difficulty
    jal check_increase_speed
    
check_v_done:
    lw $ra, 0($sp)
    lw $t6, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Process only columns that were affected by clearing
drop_affected_columns:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s6, 4($sp)
    sw $t9, 8($sp)
    
    # We'll do multiple passes to handle cascading falls
    li $t9, 1        # Set to 1 to start the loop
    
drop_iteration:
    beqz $t9, affected_drop_complete  # early_return when no more movements
    li $t9, 0        # Reset movement flag for this iteration
    
    # Iterate through each column
    li $t1, 0        # Column index
    li $t2, 1        # Bit mask for checking affected columns
    
check_columns:
    li $t6, 21       # Max columns (16)
    beq $t1, $t6, drop_iteration_end
    
    # Check if this column was affected
    and $t3, $s2, $t2
    beqz $t3, next_column
    
    # This column was affected, process it
    jal drop_single_column
    
next_column:
    addi $t1, $t1, 1     # Next column
    sll $t2, $t2, 1      # Shift mask left by 1
    j check_columns
    
drop_iteration_end:
    # If any blocks fell, do another pass
    bnez $t9, drop_iteration
    
affected_drop_complete:
    lw $ra, 0($sp)
    lw $s6, 4($sp)
    lw $t9, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# Drop blocks in a single affected column
drop_single_column:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s6, 4($sp)
    
    # Start from second-to-bottom row (3584) and work upward
    li $s6, 3584
    
    # Calculate starting byte offset for this column
    sll $t8, $t1, 2      # t8 = column * 4 (bytes per pixel)
    addi $t8, $t8, 16    # col 4
    
drop_column_loop:
    # Check if we've reached the top of the board
    li $t3, 928
    blt $s6, $t3, drop_column_done
    
    # Calculate pixel position
    add $t7, $s6, $t8        # t7 = row + column_offset
    add $t4, $t0, $t7        
    lw $t3, 0($t4)           # Color of current pixel
    
    # Skip if it's not a colored block
    lw $t5, CLEAR_PIXEL
    beq $t3, $t5, column_next_row
    lw $t5, BOARD_COLOR
    beq $t3, $t5, column_next_row
    
    # Check if this block is a virus - if so, skip it (viruses don't fall)
    sub $t5, $t4, $t0      # Get offset from display base
    la $t6, VIRUS_MAP      # add of virus mapping
    add $t6, $t6, $t5      # map pos
    lw $t5, 0($t6)         # t5 = (1 = virus, 0 = not virus)
    bnez $t5, column_next_row
    
    # Check if space below is empty
    lw $t5, 128($t4)         # Color below
    lw $t6, CLEAR_PIXEL
    bne $t5, $t6, column_next_row  
    
    # Check if this block is part of a horizontal capsule
    jal check_block_horizontal
    
    # If horizontal capsule, handle it differently
    bnez $v0, handle_horizontal_capsule
    
    # Single block - move down
    sw $t3, 128($t4)         # Move down
    sw $s7, 0($t4)           # Clear original position
    li $t9, 1                # Set movement flag
    j column_next_row
    
handle_horizontal_capsule:
    # v0 contains partner address
    # We need to check if space below both blocks is empty
    
    # make sure partner isn't in the wall SIGMA SIGMA ON THE WALL LOL
    sub $t5, $v0, $t0        # partner offset
    li $t6, 128              # size of row 
    div $t5, $t6            
    mfhi $t6                 # Get remainder (column position)
    
    # If partner column is out of bounds, treat as single block
    li $t8, 88               # Playable width (17 columns * 4 bytes + start offset 20 = 88)
    bge $t6, $t8, single_block_move
    bltz $t6, single_block_move
    
    # Check if this block or partner is a virus - if so, don't move
    sub $t5, $t4, $t0        # locaiton of block
    la $t6, VIRUS_MAP       
    add $t6, $t6, $t5        # Calculate virus map position for current block
    lw $t5, 0($t6)           # Load virus flag for current block
    bnez $t5, column_next_row  # skil if virus
    
    sub $t5, $v0, $t0        # Get offset of partner from display base
    la $t6, VIRUS_MAP        # Load address of virus map
    add $t6, $t6, $t5        # Calculate virus map position for partner
    lw $t5, 0($t6)           # Load virus flag for partner
    bnez $t5, single_block_move  # If partner is a virus, only move current block
    
    # Check if space below partner is empty
    lw $t5, 128($v0)         # Check space below partner
    lw $t6, CLEAR_PIXEL
    bne $t5, $t6, column_next_row  # If not clear, don't move
    
    # Check if space below current block is empty (already checked above)
    
    # Both spaces below are empty, move both blocks down
    lw $t5, 0($v0)           # Partner color
    sw $t3, 128($t4)         # Move current block down
    sw $t5, 128($v0)         # Move partner block down
    sw $s7, 0($t4)           # Clear current position
    sw $s7, 0($v0)           # Clear partner position
    li $t9, 1                # Set movement flag
    j column_next_row
    
single_block_move:
    # Move just this block (partner is invalid or can't move)
    sw $t3, 128($t4)         # Move down
    sw $s7, 0($t4)           # Clear original position
    li $t9, 1                # Set movement flag
    
column_next_row:
    addi $s6, $s6, -128      # Move up to next row
    j drop_column_loop
    
drop_column_done:
    lw $ra, 0($sp)
    lw $s6, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Check if a block is part of a horizontal capsule
# Input: $t4 = block address, $t3 = block color
# Output: $v0 = partner address if found, 0 if not
check_block_horizontal:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Initialize return value
    li $v0, 0
    
    # Check left neighbor
    addi $t5, $t4, -4        # Address of left neighbor
    sub $t6, $t5, $t0        # Offset of left neighbor from display base
    
    # Make sure we're still in the same row by checking if moving left wraps to previous row
    sub $t8, $t4, $t0        # Current offset from display base
    li $t7, 128              # Bytes per row
    div $t8, $t7             # Divide current offset by row size
    mfhi $t8                 # t8 = Current column offset within row
    
    # If current position is at left edge (column offset = 16 = 4*4), skip left check
    li $t7, 16               # First column position (4*4)
    beq $t8, $t7, try_right_neighbor  # Skip left check if at left edge
    
    # Check if left neighbor is a colored block (not empty or wall)
    lw $t6, 0($t5)           # Color of left neighbor
    lw $t7, CLEAR_PIXEL
    beq $t6, $t7, try_right_neighbor  # Skip if empty
    lw $t7, BOARD_COLOR
    beq $t6, $t7, try_right_neighbor  # Skip if wall
    
    # Found a left partner
    move $v0, $t5
    j check_horizontal_done
    
try_right_neighbor:
    # Check right neighbor
    addi $t5, $t4, 4         # Address of right neighbor
    sub $t6, $t5, $t0        # Offset of right neighbor from display base
    
    # Make sure we're still in the same row by checking if moving right wraps to next row
    sub $t8, $t4, $t0        # Current offset from display base
    li $t7, 128              # Bytes per row
    div $t8, $t7             # Divide current offset by row size
    mfhi $t8                 # t8 = Current column offset within row
    
    # If current position is at right edge (column offset = 84 = (20*4)), skip right check
    li $t7, 84               # Last column position (20*4 + 4)
    beq $t8, $t7, check_horizontal_done  # Skip right check if at right edge
    
    # Check if right neighbor is a colored block (not empty or wall)
    lw $t6, 0($t5)           # Color of right neighbor
    lw $t7, CLEAR_PIXEL
    beq $t6, $t7, check_horizontal_done  
    lw $t7, BOARD_COLOR
    beq $t6, $t7, check_horizontal_done 
    
    # Found a right partner
    move $v0, $t5
    
check_horizontal_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

next_state:
    addi $sp, $sp, -4    # allocate stack space
    sw $ra, 0($sp)       # save return address
    
    addi $t3, $0, 128
      
    jal clear_line       # Check for matching blocks and clear them
    
    # After clearing lines, spawn a new capsule
    jal spawn_starter_capsule

    lw $ra, 0($sp)     # Restore return address
    addi $sp, $sp, 4   # Deallocate stack space

    jr $ra

is_next_state:
    # collision check
    lw $t7, CLEAR_PIXEL      # Load clear pixel value
    
    move $t6, $s4      
    addi $t6, $t6, 128       
    beq $t6, $s5, is_next_stateV2

    move $t6, $s4             
    addi $t6, $t6, -4
    beq $t6, $s5, is_next_stateH
    
    move $t6, $s4            
    addi $t6, $t6, -128
    beq $t6, $s5, is_next_stateV1

    move $t6, $s4           
    addi $t6, $t6, 4
    beq $t6, $s5, is_next_stateH

      is_next_stateV1:
          addi $t5, $s4, 128    
          add $t5, $t0, $t5
          lw $t5, 0($t5)
          bne $t5, $t7, next_state   

          jr $ra

      is_next_stateV2:
          add $t5, $s5, 128    # s5
          add $t5, $t0, $t5
          lw $t5, 0($t5)
          bne $t5, $t7, next_state 

          jr $ra

      is_next_stateH:
          addi $t5, $s4, 128    # s4
          add $t5, $t0, $t5
          lw $t5, 0($t5)
          bne $t5, $t7, next_state 

          add $t5, $s5, 128    # s5
          add $t5, $t0, $t5
          lw $t5, 0($t5)
          bne $t5, $t7, next_state 

          jr $ra
    
    jr $ra
    
end_game:
    ######### ENDIG 音乐 ########################
    # Play the first note (frequency 70)
    li $a0, 70    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the first note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

    # Play the second note (frequency 77)
    li $a0, 70    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the second note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

    # Play the third note (frequency 79)
    li $a0, 77    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the third note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

    # Play the fourth note (frequency 77)
    li $a0, 77    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the fourth note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

        # Play the third note (frequency 79)
    li $a0, 79    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the third note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

    # Play the fourth note (frequency 77)
    li $a0, 79    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the fourth note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

     # Play the fourth note (frequency 77)
    li $a0, 77    # Frequency
    li $a1, 100   # Duration
    li $a2, 100   # Volume
    li $a3, 127   # Waveform
    li $v0, 31    # System call for sound playing
    syscall

    # Delay after the fourth note
    li $v0, 32    # Sleep syscall
    li $a0, 200   # Sleep for 100ms
    syscall

    # Exit the program
    li $v0, 10    # Exit syscall
    syscall

# Generate random viruses in the lower half of the playing field
generate_viruses:
    addi $sp, $sp, -16    # allocate stack space
    sw $ra, 0($sp)        # save return address
    sw $s0, 4($sp)        # save $s0 (used for virus count)
    sw $s1, 8($sp)        # save $s1 (used for temp)
    sw $s2, 12($sp)       # save $s2 (used for temp)
    
    # Number of viruses to generate (can be adjusted)
    li $s0, 4
    
    # Counter for placement attempts to avoid infinite loops
    li $t7, 100           # Maximum number of attempts
    
virus_loop:
    beqz $s0, virus_done  # if no more viruses to generate, we're done
    beqz $t7, virus_done  # if we've made too many attempts, early_return
    
    # Generate random position in the lower half
    # Range for y: between 2320 (middle) and 3640 (near bottom)
    li $v0, 42            # syscall for random number
    li $a0, 0             # random generator ID
    li $a1, 11            # upper bound for row (0-10)
    syscall
    
    # Convert to actual row position (2320 + random*128)
    mul $s1, $a0, 128     # multiply by row size
    addi $s1, $s1, 2320   # add base offset for middle of board
    
    # Random x position (adjusted for 17 columns starting at column 4)
    li $v0, 42
    li $a0, 0
    li $a1, 17            # 17 columns (0-16) for playable area
    syscall
    addi $a0, $a0, 4      # Offset by 4 to start from column 4
    
    # Convert to actual column position
    sll $s2, $a0, 2       # multiply by 4 (bytes per pixel)
    
    # Combine to get final position
    add $s1, $s1, $s2     # final position offset
    
    # Make sure we're not placing in a board border
    # Check if position is at the edge of the board
    li $t9, 128           # Row size
    div $s1, $t9
    mfhi $t9              # Remainder (column position)
    li $t8, 16
    blt $t9, $t8, skip_virus  # Skip if before first playable column
    li $t8, 84
    bge $t9, $t8, skip_virus  # Skip if past last playable column
    
    # Add to base display address
    add $s1, $s1, $t0
    
    # Check if position is already occupied
    lw $t9, 0($s1)        # load current color at position
    lw $t8, CLEAR_PIXEL
    bne $t9, $t8, skip_virus  # if not empty, skip this virus
    lw $t8, BOARD_COLOR
    beq $t9, $t8, skip_virus  # if it's a board pixel, skip
    
    # Pick random color from the 3 available colors
    li $v0, 42
    li $a0, 0
    li $a1, 3             # 3 colors (0-2)
	syscall

    # Get the color from the color array
    la $t9, CAPSULE_COLORS  # load color array address
    sll $t8, $a0, 2        # t8 = a0 * 4 (word size)
    add $t9, $t9, $t8      # address of selected color
    lw $t8, 0($t9)         # load the selected color
    
    # Place the virus
    sw $t8, 0($s1)         # store virus at the chosen position
    
    # Mark this position as a virus in the VIRUS_MAP
    sub $t9, $s1, $t0      # Get offset from display base
    la $t8, VIRUS_MAP      # Load address of virus map
    add $t8, $t8, $t9      # Calculate virus map position
    li $t9, 1              # Value to store (1 = virus)
    sw $t9, 0($t8)         # Mark as virus
    
    addi $s0, $s0, -1      # decrement virus counter
    j virus_loop           # continue with next virus
    
skip_virus:
    addi $t7, $t7, -1      # decrement attempt counter
    j virus_loop           # try another position
    
virus_done:
    lw $ra, 0($sp)         # restore return address
    lw $s0, 4($sp)         # restore $s0
    lw $s1, 8($sp)         # restore $s1
    lw $s2, 12($sp)        # restore $s2
    addi $sp, $sp, 16      # deallocate stack space
    
    jr $ra                 # return
  
# Clear the virus map
clear_virus_map:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    
    la $s0, VIRUS_MAP    # Load address of virus map
    li $t3, 0            # Initialize counter
    
clear_virus_loop:
    sw $zero, 0($s0)     # Clear current position
    addi $s0, $s0, 4     # Move to next position
    addi $t3, $t3, 4     # Increment counter
    bne $t3, 4096, clear_virus_loop  # Continue until all positions cleared
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Check if we need to increase game speed based on cleared lines
check_increase_speed:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    
    # Get current cleared lines count
    lw $t0, CLEARED_LINES
    
    # Get current level
    lw $t1, CURRENT_LEVEL
    
    # Calculate required lines for next level (level * 3)
    mul $t2, $t1, 3
    
    # Check if we have enough lines to level up
    blt $t0, $t2, speed_check_done
    
    # Increase level
    addi $t1, $t1, 1
    sw $t1, CURRENT_LEVEL
    
    # Calculate new gravity threshold based on level
    # Use formula: 30 - (level * 2), with minimum of 5
    li $t2, 30
    li $t3, 2
    mul $t3, $t1, $t3       # t3 = level * 2
    sub $t2, $t2, $t3       # t2 = 30 - (level * 2)
    
    # Make sure threshold doesn't go below minimum
    li $t3, 5
    bgt $t2, $t3, set_threshold
    move $t2, $t3           # Use minimum threshold
    
set_threshold:
    # Set new gravity threshold
    sw $t2, GRAVITY_THRESHOLD
    
speed_check_done:
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

play_background_music:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    
    # Increment music timer
    lw $t0, music_timer
    addi $t0, $t0, 2        # Increment by 2 for faster timer progression
    sw $t0, music_timer
    
    # Check if it's time to play the next note
    lw $t1, current_note_index
    # Calculate address of current note duration
    la $t2, music_theme
    sll $t3, $t1, 3         # t3 = index * 8 (2 words per note)
    add $t2, $t2, $t3       # t2 = address of current note pitch
    addi $t2, $t2, 4        # t2 = address of current note duration
    lw $t2, 0($t2)          # t2 = duration of current note
    
    # If timer hasn't reached current note's duration, return
    blt $t0, $t2, music_done
    
    sw $zero, music_timer
    addi $t1, $t1, 1
    
    lw $t2, music_length
    blt $t1, $t2, play_next_note
    
    li $t1, 0
    
play_next_note:
    # Save updated note index
    sw $t1, current_note_index
    
    # Get next pitch
    la $t2, music_theme
    sll $t3, $t1, 3         # t3 = index * 8 (2 words per note)
    add $t2, $t2, $t3       # t2 = address of current note pitch
    lw $a0, 0($t2)          # a0 = pitch of current note
    
    # Play the note with louder volume and proper instrument
    li $a1, 100             # Duration 
    li $a2, 0               # Instrument 0 puano
    li $a3, 127             # Maximum volume
    li $v0, 31              # syscall for MIDI out
    syscall
    
music_done: ###### NOTE: IDK WHY BUT YOU CAN"T HEAR THE AUDIO ON A MAC #############
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    addi $sp, $sp, 12
    jr $ra
