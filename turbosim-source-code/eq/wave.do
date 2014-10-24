onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider DUT
add wave -noupdate -radix hexadecimal /queue_test_bench/EV_in
add wave -noupdate -radix hexadecimal /queue_test_bench/EV_out
add wave -noupdate -radix hexadecimal /queue_test_bench/dut_len
add wave -noupdate /queue_test_bench/rst
add wave -noupdate /queue_test_bench/clk
add wave -noupdate -color Red -radix ascii /queue_test_bench/op_str
add wave -noupdate -color Gray55 /queue_test_bench/cs
add wave -noupdate -color Gray55 /queue_test_bench/op
add wave -noupdate -color Turquoise /queue_test_bench/busy
add wave -noupdate -color Turquoise /queue_test_bench/dv
add wave -noupdate /queue_test_bench/empty
add wave -noupdate /queue_test_bench/full
add wave -noupdate -divider TB
add wave -noupdate -radix hexadecimal /queue_test_bench/data_in
add wave -noupdate -radix hexadecimal /queue_test_bench/dut_data_out
add wave -noupdate -radix hexadecimal /queue_test_bench/gm_data_out
add wave -noupdate -radix hexadecimal /queue_test_bench/s
add wave -noupdate /queue_test_bench/round
add wave -noupdate -divider GM
add wave -noupdate -radix hexadecimal /queue_test_bench/gm_len
add wave -noupdate -radix hexadecimal /queue_test_bench/ram
add wave -noupdate -divider Q
add wave -noupdate -radix hexadecimal -expand -subitemconfig {{/queue_test_bench/dut/ram/ram[0]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[1]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[2]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[3]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[4]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[5]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[6]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[7]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[8]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[9]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[10]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[11]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[12]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[13]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[14]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[15]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[16]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[17]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[18]} {-radix hexadecimal} {/queue_test_bench/dut/ram/ram[19]} {-radix hexadecimal}} /queue_test_bench/dut/ram/ram
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/clk
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/EV_in
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/op
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/cs
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/rst
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/EV_out
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/dv
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/full
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/empty
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/busy
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/length
add wave -noupdate -divider {Q inner signals}
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/n
add wave -noupdate -color Gold -radix hexadecimal /queue_test_bench/dut/update_last
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/update_first_wait_op_state
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/update_first_extract_state
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/q_len
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/last
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/last_fast
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/key
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/sml_key
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/sml_idx
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/sml_dv
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/state
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/prev_state
add wave -noupdate -divider read
add wave -noupdate -color Cyan -radix hexadecimal /queue_test_bench/dut/rd_ram0
add wave -noupdate -color Cyan -radix hexadecimal /queue_test_bench/dut/biased_rd_add0
add wave -noupdate -color Cyan -radix hexadecimal /queue_test_bench/dut/rd_dat0
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/rd_ram1
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/biased_rd_add1
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/rd_dat1
add wave -noupdate -divider write
add wave -noupdate -color cyan -radix hexadecimal /queue_test_bench/dut/wr_ram0
add wave -noupdate -color cyan -radix hexadecimal /queue_test_bench/dut/biased_wr_add0
add wave -noupdate -color cyan -radix hexadecimal /queue_test_bench/dut/wr_dat0
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/wr_ram1
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/biased_wr_add1
add wave -noupdate -color {Green Yellow} -radix hexadecimal /queue_test_bench/dut/wr_dat1
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/cs_ram
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/d0_idx
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/d1_idx
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/d2_idx
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/c_idx
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_insert_condition
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_not_empty_parent_exitst
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_extract_condition
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_extract_write_last_to_head
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_extract_left_child_exist
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/wait_op_extract_right_child_exist
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/seek_for_keys_place
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/inserting_continue_inserting
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/inserting_key_to_its_place
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/extract_continue_extracting
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/extract_cont_extracting_left_child_exist
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/extract_cont_extracting_right_child_exist
add wave -noupdate -radix hexadecimal /queue_test_bench/dut/extract_cont_extracting_out_of_Q_bounds
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {205000 ps} 1} {{Cursor 2} {185000 ps} 0}
configure wave -namecolwidth 265
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 5000
configure wave -gridperiod 20000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {55625 ps} {318125 ps}
