# Aws Hammad - 1221697
# Ibraheem Sleet - 1220200

################# Data segment #####################
.data
# strings
menu:         .asciiz "\nEnter the input file name or path: (Enter Q or q to exit)\n"
choose:       .asciiz "\nChoose the heuristic (FF or BF):\n"
error:        .asciiz "\nError! The file does not exist or the input file content is invalid\n"
output_file:  .asciiz "output_file.txt"
invalid:      .asciiz "\nError! Please enter FF or BF.\n"
newline:      .asciiz "\n"
items_label:  .asciiz " Items: "
space:        .asciiz " "
bin_label:    .asciiz "Bin "
colon_space:  .asciiz ": "
# buffers
read_buffer:  .space 256          # to store the file in it
line_buffer:  .space 100          # to store every line 
.align 3                          # for the double 
items:        .space 1600         # up to 200 doubles (200*8 bytes)
fileName:     .space 100          # to store the file name
heuristic:    .space 100          # to store the heuristic
item_bins:    .space 800          # to store the number of which bin the item is in
item_count:   .word 0             # total number of items
# constants
zeropoint:    .double 0.0         # to use it in comparison
point1:       .double 0.1         # to use in conversion from string to double
bins:         .space 1600         # to store the total in each bin
bin_count:    .word 0             # to store the # of bins are used
one:          .double 1.0         # to put items in bins until it reach 1
onepointone:  .double 1.1         # to be the first gap in BF (larger than 1)
ten:          .double 10.0        # to use for conversion from 0.xxxx to a number x 10
hundred:      .double 100.0       # to print in two decimals after the point like (0.xx)

################# Code segment #####################
.text
main:
start:
# ask the user to input file name
    li   $v0, 4               # print the menu
    la   $a0, menu            # store the menu in a0
    syscall 

# read filename from the user
    li   $v0, 8               # read a string from user
    la   $a0, fileName        # store input in fileName buffer
    li   $a1, 100             # the max is 100 characters
    syscall

# remove '\n' from fileName
    la   $s2, fileName        # load the fileName into s2
remove_loop:
    lb   $t1, 0($s2)          # load current char
    beqz $t1, done_remove     # if null terminator, done
    li   $t2, 10              # ascii code for '\n'
    beq  $t1, $t2, replace_null # if '\n', replace it
    addi $s2, $s2, 1          # move to next character
    j    remove_loop          # continue loop
replace_null:
    li   $t3, 0               # null terminator
    sb   $t3, 0($s2)          # replace '\n' with null
done_remove:

# check if user entered "q" or "Q" to exit
    la   $t0, fileName        # load address of fileName
    lb   $t1, 0($t0)          # load first char
    li   $t2, 'q'             # ascii of 'q'
    beq  $t1, $t2, check_q    # if q then check next char
    li   $t2, 'Q'             # ascii of 'Q'
    beq  $t1, $t2, check_q    # if Q then check next char
    b    open                 # otherwise continue to open

check_q:
    lb   $t7, 1($t0)          # check second char
    bne  $t7, $zero, open     # if not null then continue
    b    exit_program         # if null exit

open:
# open input file for reading
    li   $v0, 13              # open the file
    la   $a0, fileName        # file name
    li   $a1, 0               # read only mode
    syscall
    move $s0, $v0             # save file descriptor in s0
    bltz $s0, file_error      # if error go to error message

# read entire file into our buffer
    li   $v0, 14              # read file
    move $a0, $s0             # get file descriptor from s0
    la   $a1, read_buffer     # our buffer to store data
    li   $a2, 256             # max bytes to read is 256
    syscall
    move $t1, $v0             # t1 = number of bytes that is read
    beqz $t1, close_file      # if empty, close file

# null terminate the buffer
    la   $t7, read_buffer     # start of buffer
    add  $t7, $t7, $t1        # move to end of read data
    li   $t8, 0               # null byte
    sb   $t8, 0($t7)          # terminate with null

# convert each line to a double
    la   $s3, read_buffer     # s3 points to buffer start
    li   $t0, 0               # item counter
process_lines:
    lb   $t1, 0($s3)          # load current char
    beqz $t1, finish_processing # if null then finish

# skip newline characters
skip_newline:
    lb   $t1, 0($s3)          # load current char
    beqz $t1, finish_processing # if null then finish
    li   $t2, 10              # ascii of '\n'
    beq  $t1, $t2, skip_inc   # if newline skip it
    j    copy_line            # otherwise start copy

skip_inc:
    addi $s3, $s3, 1          # move to next char
    j    process_lines        # repeat the process

copy_line:
    la   $t4, line_buffer     # load line buffer
copy_line_loop:
    lb   $t1, 0($s3)          # load char
    beqz $t1, finish_copy     # stop if null
    li   $t2, 10              # ascii of newline is 10
    beq  $t1, $t2, finish_copy # stop if newline
    sb   $t1, 0($t4)          # store char in buffer
    addi $s3, $s3, 1          # next input char
    addi $t4, $t4, 1          # next buffer position
    j    copy_line_loop       # continue the copying

finish_copy:
# if line_buffer doesn’t begin with '0.'
    la    $t9, line_buffer     # address of your copy buffer
    lb    $t1, 0($t9)          # first char
    li    $t2, '0'
    bne   $t1, $t2, file_error
    lb    $t1, 1($t9)          # second char
    li    $t2, '.'
    bne   $t1, $t2, file_error
# null-terminate the line in the buffer
    li    $t1, 0
    sb    $t1, 0($t4)
# convert line_buffer → double in $f0
    la    $a0, line_buffer
    jal   str_to_double
    mov.d $f2, $f0             # f2 = parsed value
# if f2 < 0.0, skip it
    ldc1  $f4, zeropoint       # f4 = 0.0
    c.lt.d $f2, $f4
    bc1t  file_error
# if f2 ≥ 1.0, skip it
    ldc1  $f4, one             # f4 = 1.0
    c.le.d $f4, $f2
    bc1t  file_error
# otherwise store f2 into items[t0]
    la    $t4, items
    mul   $t5, $t0, 8          # offset = index * 8 bytes
    add   $t4, $t4, $t5
    s.d   $f2, 0($t4)
    addi  $t0, $t0, 1          # increment valid-item count
    j     process_lines        # back to reading next line


finish_processing:
    sw   $t0, item_count      # store total item count
    j    close_file           # go close the file

file_error:
    li   $v0, 4               # print string
    la   $a0, error           # load error message
    syscall
    j    start                # restart program

close_file:
    li   $v0, 16              # close file
    move $a0, $s0             # file descriptor
    syscall
    j    choose_heuristic     # go to choose heuristic

choose_heuristic:
    li   $v0, 4               # print the heuristic selection message
    la   $a0, choose          # load entered string
    syscall

    li   $v0, 8               # syscall to read string input
    la   $a0, heuristic       # store input in 'heuristic' buffer
    li   $a1, 100             # max input length = 100
    syscall

    la   $s2, heuristic       # s2 points to start of heuristic string
remove_loop2:
    lb   $t1, 0($s2)          # load current char
    beqz $t1, done_remove2    # if null then finish
    li   $t2, 10              # ascii of '\n'
    beq  $t1, $t2, replace_null2 # if newline replace it
    addi $s2, $s2, 1          # move to the next char
    j    remove_loop2         # repeat the loop
replace_null2:
    li   $t3, 0               # null terminator
    sb   $t3, 0($s2)          # replace newline with null
done_remove2:

    la   $t4, heuristic       # t4 points to the heuristic string
    lb   $a0, 0($t4)          # load first char
    jal  tolower              # convert to lowercase
    move $t5, $v0             # store result in t5 (tolower)

    lb   $a0, 1($t4)          # load second char
    jal  tolower              # convert to lowercase
    move $t6, $v0             # store result in t6 (tolower)

    lb   $t7, 2($t4)          # load third character
    bne  $t7, $zero, invalid_choice # if there's more than 2 chars then invalid

    li   $t8, 'f'             # ascii of 'f'
    beq  $t5, $t8, check_ff   # if first char is 'f' check FF
    li   $t8, 'b'             # ascii of 'b'
    beq  $t5, $t8, check_bf   # if first char is 'b' check BF
    j    invalid_choice       # otherwise invalid input

check_ff:
    li   $t8, 'f'             # ascii of 'f'
    beq  $t6, $t8, FF         # if second char is 'f' go to FF
    j    invalid_choice       # otherwise invalid

check_bf:
    li   $t8, 'f'             # ascii for 'f'
    beq  $t6, $t8, BF         # if second char is 'f' go to BF
    j    invalid_choice       # otherwise invalid

invalid_choice:
    li   $v0, 4               # print string
    la   $a0, invalid         # load invalid choice message
    syscall
    j    choose_heuristic     # repeat heuristic input

# ---------- First-Fit (FF) heuristic ----------
FF:
    li   $t9, 0               # initialize bin_count = 0
    sw   $t9, bin_count       # store initial bin count
    li   $t1, 0               # t1 = item index

ff_loop:
    beq  $t1, $t0, ff_done    # if all items processed then finish
    la   $t2, items           # t2 points to items array
    mul  $t3, $t1, 8          # t3 = item index * 8 (offset in bytes)
    add  $t2, $t2, $t3        # move to current item
    l.d  $f2, 0($t2)          # load current item value into f2

    li   $t4, 0               # t4 = bin index

ff_bin_loop:
    bge  $t4, $t9, ff_new_bin # if reached end of used bins go create new one
    la   $t5, bins            # t5 points to bins array
    mul  $t6, $t4, 8          # t6 = bin index * 8 (offset)
    add  $t5, $t5, $t6        # move to current bin
    l.d  $f4, 0($t5)          # load current bin total into f4
    add.d $f6, $f4, $f2       # f6 = bin total + item
    l.d  $f8, one             # load bin capacity = 1.0
    c.le.d $f6, $f8           # check if new total <= 1.0
    bc1t fit_found            # if it fits go to store it

ff_next_bin:
    addi $t4, $t4, 1          # go to next bin
    j    ff_bin_loop          # repeat check

fit_found:
    s.d  $f6, 0($t5)          # store new total in bin
    la   $t8, item_bins       # t8 points to item_bins array
    mul  $t7, $t1, 4          # t7 = item index * 4
    add  $t8, $t8, $t7        # move to the needed item_bin slot
    sw   $t4, 0($t8)          # store bin index for current item
    addi $t1, $t1, 1          # move to the next item
    j    ff_loop              # repeat the item loop

ff_new_bin:
    la   $t5, bins            # t5 points to bins array
    mul  $t6, $t9, 8          # t6 = new bin index * 8
    add  $t5, $t5, $t6        # move to new bin slot
    s.d  $f2, 0($t5)          # store item value directly in new bin

    la   $t8, item_bins       # t8 points to item_bins array
    mul  $t7, $t1, 4          # t7 = item index * 4
    add  $t8, $t8, $t7        # move to needed item_bin slot
    sw   $t9, 0($t8)          # assign this item to the new bin

    addi $t9, $t9, 1          # increment total bin count
    addi $t1, $t1, 1          # move to next item
    j    ff_loop              # repeat item loop

ff_done:
    sw   $t9, bin_count       # store final bin count
    j    write_output         # go to output


# ---------- Best-Fit (BF) heuristic ----------
BF:
    li   $t1, 0               # t1 = item index
    li   $t9, 0               # t9 = bin count
    sw   $t9, bin_count       # store the initial bin count

bf_loop:
    beq  $t1, $t0, bf_done    # if all items processed finish
    la   $t2, items           # t2 points to items array
    mul  $t3, $t1, 8          # t3 = item index * 8 (byte offset)
    add  $t2, $t2, $t3        # move to current item
    l.d  $f2, 0($t2)          # load item value into f2

    li   $t4, 0               # t4 = bin index
    li   $t5, -1              # t5 = best bin index (initially -1)
    l.d  $f20, onepointone    # f20 = initial min waste (1.1) bigger then 1

bf_bin_loop:
    bge  $t4, $t9, bf_check_best # if all bins checked then go decide
    la   $t6, bins            # t6 points to bins array
    mul  $t7, $t4, 8          # t7 = bin index * 8
    add  $t6, $t6, $t7        # move to current bin
    l.d  $f4, 0($t6)          # load bin total into f4
    add.d $f6, $f4, $f2       # f6 = bin total + item
    l.d  $f8, one             # f8 = 1.0
    c.le.d $f6, $f8           # check if fits in bin (f6 ≤ 1.0 ?)
    bc1f bf_next_bin          # if not go to next bin

    sub.d $f10, $f8, $f6      # f10 = waste (1 - total)
    c.lt.d $f10, $f20         # is current waste < min waste?
    bc1f bf_next_bin          # if not skip
    mov.d $f20, $f10          # update min waste to f10
    move  $t5, $t4            # update best bin index to t5

bf_next_bin:
    addi $t4, $t4, 1          # next bin index
    j    bf_bin_loop          # repeat check

bf_check_best:
    bltz $t5, bf_open_new_bin # if no suitable bin found open new one

    la   $t6, bins            # t6 points to bins
    mul  $t7, $t5, 8          # t7 = best bin index * 8
    add  $t6, $t6, $t7        # move to best bin
    l.d  $f4, 0($t6)          # load current bin total
    add.d $f6, $f4, $f2       # add item to bin
    s.d  $f6, 0($t6)          # store new bin total

    la   $t8, item_bins       # t8 points to item_bins
    mul  $t7, $t1, 4          # t7 = item index * 4
    add  $t8, $t8, $t7        # move to correct item_bin slot
    sw   $t5, 0($t8)          # store assigned bin index
    addi $t1, $t1, 1          # move to next item
    j    bf_loop              # repeat item loop

bf_open_new_bin:
    la   $t6, bins            # t6 points to bins
    mul  $t7, $t9, 8          # t7 = new bin index * 8
    add  $t6, $t6, $t7        # move to new bin slot
    s.d  $f2, 0($t6)          # store item in new bin

    la   $t8, item_bins       # t8 points to item_bins
    mul  $t7, $t1, 4          # t7 = item index * 4
    add  $t8, $t8, $t7        # move to correct item_bin slot
    sw   $t9, 0($t8)          # assign item to new bin

    addi $t9, $t9, 1          # increment bin count
    addi $t1, $t1, 1          # move to next item
    j    bf_loop              # repeat item loop

bf_done:
    sw   $t9, bin_count       # store the final bin count
    j    write_output         # go write results

# ---------- tolower routine ----------
tolower: 
    blt  $a0, 'A', else_lower  # if char < 'A', not uppercase
    bgt  $a0, 'Z', else_lower  # if char > 'Z', not uppercase
    addi $v0, $a0, 32          # convert to lowercase
    jr   $ra                   # return
else_lower:
    move $v0, $a0              # return original char
    jr   $ra

# ---------- Write output to the output file ----------
write_output:
    lw   $s0, item_count       # total number of items
    lw   $s1, bin_count        # total number of bins used

# open output file for writing
    li   $v0, 13               # open file
    la   $a0, output_file      # filename
    li   $a1, 1                # write mode
    li   $a2, 0                # default
    syscall
    move $s7, $v0              # save file descriptor

    li   $s2, 0                # bin index = 0
outer_loop_file:
    bge  $s2, $s1, file_done   # if all bins done then finish

# write "Bin "
    li   $v0, 15               # write to file
    move $a0, $s7              # file descriptor
    la   $a1, bin_label        # "Bin "
    li   $a2, 4                # length = 4
    syscall

# write bin number 
    addi $a0, $s2, 48           # convert bin index to ascii digit
    sb   $a0, line_buffer       # store digit in line_buffer
    li   $v0, 15                # write to file
    move $a0, $s7               # file descriptor
    la   $a1, line_buffer       # address of ascii digit
    li   $a2, 1                 # length = 1
    syscall

# write ": "
    li   $v0, 15                # write to file
    move $a0, $s7
    la   $a1, colon_space       # ": "
    li   $a2, 2                 # length = 2
    syscall

# write bin total as decimal string
    la   $t2, bins              # base address of bins
    mul  $t3, $s2, 8            # offset = bin index * 8
    add  $t2, $t2, $t3
    l.d  $f0, 0($t2)            # load bin total into f0
    la   $a0, line_buffer
    jal  double_to_string       # convert double to string in line_buffer
    la   $a0, line_buffer
    jal  str_length             # calculate string length
    move $t4, $v0               # load string length into t4
    move $a0, $s7               # file descriptor
    la   $a1, line_buffer       # string address
    move $a2, $t4               # string length
    li   $v0, 15                # write to file
    syscall

# write " Items: "
    li   $v0, 15                # write to file
    move $a0, $s7
    la   $a1, items_label       # " Items: "
    li   $a2, 8                 # length = 8
    syscall

# inner loop: print all items in this bin
    li   $t5, 0                 # item index = 0
inner_loop_file:
    bge  $t5, $s0, newline_file # if all items checked go write newline
    la   $t6, item_bins         # t6 points to item_bins
    mul  $t7, $t5, 4            # t7 = item index * 4
    add  $t6, $t6, $t7          # move to correct item_bin slot
    lw   $t8, 0($t6)            # load assigned bin index of item
    bne  $t8, $s2, skip_item_file # skip if not current bin

    la   $t6, items             # load base address of items array
    mul  $t7, $t5, 8            # offset = item index * 8
    add  $t6, $t6, $t7          # move $t6 to the address of the current item
    l.d  $f0, 0($t6)            # load item value into f0
    la   $a0, line_buffer       # load the address of line_buffer
    jal  double_to_string       # convert to string in line_buffer
    la   $a0, line_buffer       # load the address of line_buffer
    jal  str_length             # calculate string length
    move $t9, $v0
    move $a0, $s7               # file descriptor
    la   $a1, line_buffer       # item string
    move $a2, $t9               # length of string
    li   $v0, 15
    syscall

# write space after the item
    li   $v0, 15                # write to file
    move $a0, $s7
    la   $a1, space             # " "
    li   $a2, 1                 # length = 1
    syscall

skip_item_file:
    addi $t5, $t5, 1            # next item
    j    inner_loop_file        # go to the inner loop

newline_file:
    li   $v0, 15                # write to file
    move $a0, $s7
    la   $a1, newline           # "\n"
    li   $a2, 1                 # length = 1
    syscall

    addi $s2, $s2, 1            # next bin
    j    outer_loop_file        # go to the outer loop

file_done:
    li   $v0, 16                # close file
    move $a0, $s7               # file descriptor
    syscall
    j    start                  # restart program from beginning

exit_program:
    li   $v0, 10                # exit program
    syscall

# ---------- convert "0.xxxx" to double in $f0 ----------
str_to_double:
    ldc1 $f0, zeropoint       # initialize result (f0 = 0.0)
    ldc1 $f2, point1          # f2 = 0.1 (scaling factor)
    addi $t5, $a0, 2          # skip "0." prefix in string

conv_loop:
    lb   $t1, 0($t5)          # load next char
    beqz $t1, conv_done       # if null then done
    li   $t2, 10              # ascii for newline
    beq  $t1, $t2, conv_done  # if newline then done
    li   $t3, 48              # ascii for '0'
    sub  $t1, $t1, $t3        # convert ascii to int
    mtc1 $t1, $f4             # move to float register
    cvt.d.w $f4, $f4          # convert to double
    mul.d $f6, $f4, $f2       # multiply digit by factor
    add.d $f0, $f0, $f6       # add to result
    ldc1 $f8, point1          # load 0.1 again
    mul.d $f2, $f2, $f8       # reduce factor by 0.1 (move to next decimal place)
    addi $t5, $t5, 1          # increment string pointer
    j    conv_loop

conv_done:
    jr   $ra                  # return the result in $f0

# ---------- convert a double to a string ----------
double_to_string:
    mov.d $f12, $f0           # store original double in f12

# convert integer part to ascii
    cvt.w.d $f2, $f0          # convert to integer (truncate)
    mfc1  $t0, $f2            # move integer to t0
    addi  $t0, $t0, 48        # convert to ascii
    sb    $t0, 0($a0)         # store digit
    addi  $a0, $a0, 1         # increment pointer

# write decimal point
    li    $t0, 46             # '.' = 46
    sb    $t0, 0($a0)         # store '.' 
    addi  $a0, $a0, 1         # move pointer forward in buffer

# extract fractional part
    cvt.d.w $f2, $f2          # convert int part back to double
    sub.d $f4, $f12, $f2      # f4 = fractional part
    ldc1  $f6, hundred        # 100.0 for scaling
    mul.d $f4, $f4, $f6       # scale to 2-digit integer
    cvt.w.d $f4, $f4          # convert to int
    mfc1  $t1, $f4            # move to t1

# split into tens and ones
    li    $t0, 10
    div   $t1, $t0
    mflo  $t3                 # t3 = tens digit
    mfhi  $t4                 # t4 = ones digit
    addi  $t3, $t3, 48        # convert to ascii
    sb    $t3, 0($a0)         # store tens
    addi  $a0, $a0, 1
    addi  $t4, $t4, 48        # convert ones to ascii
    sb    $t4, 0($a0)         # store ones
    addi  $a0, $a0, 1

    li    $t0, 0              # null terminator
    sb    $t0, 0($a0)         # terminate string
    jr    $ra                 # return

# ---------- str_length: Returns length of a null-terminated string ----------
str_length:
    move $t0, $a0             # copy string pointer to t0
    li   $t1, 0               # t1 = counter

str_length_loop:
    lb   $t2, 0($t0)          # load current char
    beq  $t2, $zero, str_length_done  # if null, done
    addi $t1, $t1, 1          # increment length
    addi $t0, $t0, 1          # move to next char
    j    str_length_loop

str_length_done:
    move $v0, $t1             # return length in v0
    jr   $ra
    
    
