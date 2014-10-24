vlog -work work ../rtl_lib/comperator_2.v
vlog -work work ../rtl_lib/comperator_3.v
vlog -work work ../rtl_lib/dp_ram_duo.v

vlog +incdir+.+..+../rtl_lib -work work Queue.v
vlog +incdir+.+..+../rtl_lib -work work Queue_test_bench.v

vsim work.queue_test_bench

noview wave*
do wave.do
log -r /*

run 205ns