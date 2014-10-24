onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider TurboSIM
add wave -noupdate -color Yellow -format Logic /sim_project/clk
add wave -noupdate -format Logic /sim_project/rst
add wave -noupdate -color {Steel Blue} -format Logic /sim_project/go
add wave -noupdate -color Cyan -format Logic /sim_project/done
add wave -noupdate -color {Light Steel Blue} -format Literal -radix decimal /sim_project/turbosim/status
add wave -noupdate -format Logic /sim_project/wr
add wave -noupdate -format Logic /sim_project/rd
add wave -noupdate -format Logic /sim_project/full
add wave -noupdate -format Logic /sim_project/empty
add wave -noupdate -format Literal -radix hexadecimal /sim_project/in_record
add wave -noupdate -format Literal -radix hexadecimal /sim_project/out_record
add wave -noupdate -color Orange -format Literal -label state -radix ascii /sim_project/turbosim/state_str
add wave -noupdate -format Literal -radix unsigned /sim_project/turbosim/sim_time
add wave -noupdate -group {Input FIFO}
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/cs
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/wr
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/full
add wave -noupdate -group {Input FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/in_fifo/wr_data
add wave -noupdate -group {Input FIFO} -format Literal -radix unsigned /sim_project/turbosim/in_fifo/wr_ptr
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/rd
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/int_rd
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/empty
add wave -noupdate -group {Input FIFO} -format Literal -radix unsigned /sim_project/turbosim/in_fifo/next_rd_ptr
add wave -noupdate -group {Input FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/in_fifo/rd_data
add wave -noupdate -group {Input FIFO} -format Literal -radix unsigned /sim_project/turbosim/in_fifo/len
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo/full
add wave -noupdate -group {Input FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/in_fifo/dp_ram/ram
add wave -noupdate -group {Input FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/in_fifo_rd_data
add wave -noupdate -group {Input FIFO} -format Logic /sim_project/turbosim/in_fifo_empty
add wave -noupdate -group {Output FIFO}
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/cs
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/wr
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/full
add wave -noupdate -group {Output FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/out_fifo/wr_data
add wave -noupdate -group {Output FIFO} -format Literal -radix unsigned /sim_project/turbosim/out_fifo/wr_ptr
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/rd
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/int_rd
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo/empty
add wave -noupdate -group {Output FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/out_fifo/rd_data
add wave -noupdate -group {Output FIFO} -format Literal -radix decimal /sim_project/turbosim/out_fifo/rd_ptr
add wave -noupdate -group {Output FIFO} -format Literal -radix unsigned /sim_project/turbosim/out_fifo/len
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo_wr_sel
add wave -noupdate -group {Output FIFO} -format Literal -radix unsigned /sim_project/turbosim/out_fifo/next_rd_ptr
add wave -noupdate -group {Output FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/out_fifo/dp_ram/ram
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo_wr
add wave -noupdate -group {Output FIFO} -format Literal -radix hexadecimal /sim_project/turbosim/out_fifo_wr_data
add wave -noupdate -group {Output FIFO} -format Logic /sim_project/turbosim/out_fifo_full
add wave -noupdate -height 50 -expand -group {Event Queue}
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/cs
add wave -noupdate -group {Event Queue} -format Literal -radix unsigned /sim_project/turbosim/eq/op
add wave -noupdate -group {Event Queue} -format Literal -radix hexadecimal /sim_project/turbosim/eq/EV_in
add wave -noupdate -group {Event Queue} -format Literal -radix hexadecimal /sim_project/turbosim/eq/EV_out
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/dv
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/full
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/empty
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/busy_for_rd
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/busy_for_wr
add wave -noupdate -group {Event Queue} -color red -format Analog-Step -height 50 -max 70.0 -radix unsigned /sim_project/turbosim/eq/length
add wave -noupdate -group {Event Queue} -format Logic /sim_project/turbosim/eq/is_zero_delay
add wave -noupdate -group {Event Queue} -divider {inner cmds}
add wave -noupdate -height 50 -expand -group CTU
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/cs
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/empty
add wave -noupdate -group CTU -format Literal -radix hexadecimal /sim_project/turbosim/ctu1/EV_in
add wave -noupdate -group CTU -format Literal -radix hexadecimal /sim_project/turbosim/ctu1/EV_out
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/full
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/rd
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/wr
add wave -noupdate -group CTU -color red -format Analog-Step -height 50 -max 80.0 -radix unsigned /sim_project/turbosim/ctu1/length
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/ctu_continues_write
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/ctu_enter_new_entry
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/ctu_first_write
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/ctu_read_ena
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/ctu_write_ena
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/does_cell_exist_in_ram
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/enrty_is_missing_in_ram
add wave -noupdate -group CTU -format Logic /sim_project/turbosim/ctu1/remove_entry_from_ram
add wave -noupdate -group {Cell RAM}
add wave -noupdate -group {Cell RAM} -format Literal -label ram -radix hexadecimal /sim_project/turbosim/cell_ram/ram
add wave -noupdate -group {Cell RAM} -format Logic /sim_project/turbosim/cell_ram/cs
add wave -noupdate -group {Cell RAM} -format Logic /sim_project/turbosim/cell_ram/rd
add wave -noupdate -group {Cell RAM} -format Logic /sim_project/turbosim/cell_ram/wr
add wave -noupdate -group {Cell RAM} -format Literal -radix hexadecimal /sim_project/turbosim/cell_ram/rd_add
add wave -noupdate -group {Cell RAM} -format Literal -radix hexadecimal /sim_project/turbosim/cell_ram/wr_add
add wave -noupdate -group {Cell RAM} -format Literal -radix hexadecimal /sim_project/turbosim/cell_ram/wr_data
add wave -noupdate -group {Cell RAM} -format Literal -radix hexadecimal /sim_project/turbosim/cell_ram/rd_data
add wave -noupdate -group {Net RAM}
add wave -noupdate -group {Net RAM} -format Literal -radix hexadecimal /sim_project/turbosim/net_ram/ram
add wave -noupdate -group {Net RAM} -format Logic /sim_project/turbosim/net_ram/cs
add wave -noupdate -group {Net RAM} -format Logic /sim_project/turbosim/net_ram/rd
add wave -noupdate -group {Net RAM} -format Logic /sim_project/turbosim/net_ram/wr
add wave -noupdate -group {Net RAM} -format Literal -radix hexadecimal /sim_project/turbosim/net_ram/rd_add
add wave -noupdate -group {Net RAM} -format Literal -radix hexadecimal /sim_project/turbosim/net_ram/wr_add
add wave -noupdate -group {Net RAM} -format Literal -radix hexadecimal /sim_project/turbosim/net_ram/wr_data
add wave -noupdate -group {Net RAM} -format Literal -radix hexadecimal /sim_project/turbosim/net_ram/rd_data
add wave -noupdate -divider {CPU Stages}
add wave -noupdate -group {Stage: GET_INPUTS}
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_end_pipeline
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_in_pipeline
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_push_to_eq_update_net_ram
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_read_net_ram
add wave -noupdate -group {Stage: GET_INPUTS} -format Literal -radix hexadecimal /sim_project/turbosim/get_inputs_saved_in_record
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_start_pipeline
add wave -noupdate -group {Stage: GET_INPUTS} -format Logic /sim_project/turbosim/get_inputs_suspend_pipeline
add wave -noupdate -group {Stage: SOLVE}
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_cell_ram_rd
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_cell_ram_rd_add
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_cell_ram_wr
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_cell_ram_wr_add
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_cell_ram_wr_data
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_ctu_data
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_curr_pin_idx
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_prev_pin_idx
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_current_load
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_dequeue_event
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_event
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_net
add wave -noupdate -group {Stage: SOLVE} -format Literal -radix hexadecimal /sim_project/turbosim/solve_net_new_value
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_read_net_event
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_write_event_to_net_ram
add wave -noupdate -group {Stage: SOLVE} -format Logic /sim_project/turbosim/solve_write_to_ctu
add wave -noupdate -group {Stage: GENERATE_EVENTS}
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_all_one
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_all_zero
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_at_least_one_one
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_at_least_one_zero
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Literal -radix hexadecimal /sim_project/turbosim/generate_events_cell_delay
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_create_new_event
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Literal -radix unsigned /sim_project/turbosim/generate_events_evaluated_value
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Literal -radix hexadecimal /sim_project/turbosim/generate_events_net_idx
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Literal /sim_project/turbosim/generate_events_pipeline_status
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_1
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_1_active
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_2
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_2_active
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_3
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_stage_3_active
add wave -noupdate -group {Stage: GENERATE_EVENTS} -format Logic /sim_project/turbosim/generate_events_suspend_pipeline
add wave -noupdate -divider input_vcd_fifo
add wave -noupdate -format Literal -radix hexadecimal /sim_project/input_vcd_fifo
add wave -noupdate -format Literal -radix unsigned /sim_project/input_vcd_wr_ptr
add wave -noupdate -format Literal -radix unsigned /sim_project/input_vcd_rd_ptr
add wave -noupdate -format Literal -radix decimal /sim_project/input_vcd_len
add wave -noupdate -format Logic /sim_project/input_vcd_full
add wave -noupdate -format Logic /sim_project/input_vcd_empty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {10437992 ps} 0}
configure wave -namecolwidth 179
configure wave -valuecolwidth 57
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {105 us}
