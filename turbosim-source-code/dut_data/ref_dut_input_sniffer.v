// DATA derived from module add1 !!!!!!!!!!!!!!!!
// code used to capture inputs change to ref_dut
// converting them to vcd format fed to turbosim in_fifo
reg null_bit;

always @(ref_dut.a[0])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[0]), 14'd0, dt});
end

always @(ref_dut.a[10])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[10]), 14'd1, dt});
end

always @(ref_dut.a[11])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[11]), 14'd2, dt});
end

always @(ref_dut.a[12])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[12]), 14'd3, dt});
end

always @(ref_dut.a[13])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[13]), 14'd4, dt});
end

always @(ref_dut.a[14])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[14]), 14'd5, dt});
end

always @(ref_dut.a[15])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[15]), 14'd6, dt});
end

always @(ref_dut.a[1])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[1]), 14'd7, dt});
end

always @(ref_dut.a[2])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[2]), 14'd8, dt});
end

always @(ref_dut.a[3])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[3]), 14'd9, dt});
end

always @(ref_dut.a[4])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[4]), 14'd10, dt});
end

always @(ref_dut.a[5])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[5]), 14'd11, dt});
end

always @(ref_dut.a[6])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[6]), 14'd12, dt});
end

always @(ref_dut.a[7])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[7]), 14'd13, dt});
end

always @(ref_dut.a[8])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[8]), 14'd14, dt});
end

always @(ref_dut.a[9])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.a[9]), 14'd15, dt});
end

always @(ref_dut.b[0])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[0]), 14'd16, dt});
end

always @(ref_dut.b[10])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[10]), 14'd17, dt});
end

always @(ref_dut.b[11])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[11]), 14'd18, dt});
end

always @(ref_dut.b[12])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[12]), 14'd19, dt});
end

always @(ref_dut.b[13])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[13]), 14'd20, dt});
end

always @(ref_dut.b[14])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[14]), 14'd21, dt});
end

always @(ref_dut.b[15])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[15]), 14'd22, dt});
end

always @(ref_dut.b[1])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[1]), 14'd23, dt});
end

always @(ref_dut.b[2])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[2]), 14'd24, dt});
end

always @(ref_dut.b[3])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[3]), 14'd25, dt});
end

always @(ref_dut.b[4])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[4]), 14'd26, dt});
end

always @(ref_dut.b[5])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[5]), 14'd27, dt});
end

always @(ref_dut.b[6])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[6]), 14'd28, dt});
end

always @(ref_dut.b[7])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[7]), 14'd29, dt});
end

always @(ref_dut.b[8])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[8]), 14'd30, dt});
end

always @(ref_dut.b[9])
begin
	dt = $time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.b[9]), 14'd31, dt});
end
