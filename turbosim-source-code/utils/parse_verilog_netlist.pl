#! /usr/bin/perl

use Data::Dumper;
# $Data::Dumper::Indent = 1;         # mild pretty print
# $Data::Dumper::Maxdepth = 1;

if (@ARGV == 0) {
    die "Usage :\n\t parse_verilog_primitive.pl  <verilog_netlist>\n\n";
}


$debug = 0;

$fname0 = $ARGV[0];

if (!(-s $fname0)) {
    print "ERROR - could not open $fname0\n";
    die "Usage :\n\t parse_verilog_primitive.pl  <verilog_netlist>\n\n";
}

open(g,"$fname0") || print "can not open $fname0 file ...\n";
while(<g>){

    # module add1 ( o, a, b );

    if (/^\s*module\s+(\w+)/){
	$module_name = $1;

    }
    # simple single port in a line, decending bus
    elsif (/^\s*(output|input)\s+(\[\d+:\d+\]\s+)?(\w+)\s*;/){
	$port_dir   = $1;
	$bus_string = $2;
	$port_name  = $3;
	$bus_string =~ s/(\[|\]|\s+)//g;
	($stop_i, $start_i) = split(/:/,$bus_string); 
	if ($bus_string ne "") {
	    $is_bus = 1;
	    for ($i=$stop_i; $i>=$start_i; $i--) {
		$MODULE->{ports}->{$port_name."[$i]"} = $port_dir;  
	    }	
	}
	else {
	    $MODULE->{ports}->{$port_name} = $port_dir; 
	}
    } 
    # simple one instance in a line, by order, verilog primitive, one output !!!
    elsif (/^\s*(not|buf|nor|nand|or|and)\s+#\((\d+)\.(\d+)\)\s+(\w+)\s+\(([^)]+)\)\s*;/){
	$prim_type  = $1;
	$prim_delay = sprintf("%s.%s", $2, $3);
	$prim_delay_ps = int($2 . $3);
	$prim_inst  = $4;
	$pin_string = $5;
	$pin_string =~ s/\s+//g;
	@pin_array  = split(/,/,$pin_string);
	$pin_name   = 'pin0';
	$MODULE->{cells}->{$prim_inst}->{prim_type} = $prim_type ;
	$MODULE->{cells}->{$prim_inst}->{prim_delay}= $prim_delay;
	$MODULE->{cells}->{$prim_inst}->{prim_delay_ps}= $prim_delay_ps;
	$MODULE->{cells}->{$prim_inst}->{prim_inst} = $prim_inst ;
	$MODULE->{cells}->{$prim_inst}->{pin_string}= $pin_string;

	foreach $net (@pin_array) {
	    $MODULE->{cells}->{$prim_inst}->{pins}->{$pin_name} = $net  ;
	    $MODULE->{nets}->{$net}->{"$prim_inst/$pin_name"}   = 1;
	    $MODULE->{pins}->{"$prim_inst/$pin_name"}           = 1;
	    $pin_name++;
	}
    }
    else {
	print "#$_";
    }

}


$Data::Dumper::Varname = 'MODULE';
# print Dumper $MODULE;

foreach $prim_inst (keys %{$MODULE->{cells}}){
    # print "===$prim_inst\n";
    $ALL->{cells}->{$prim_inst}->{prim_type}  = $MODULE->{cells}->{$prim_inst}->{prim_type};
    $ALL->{cells}->{$prim_inst}->{prim_delay} = $MODULE->{cells}->{$prim_inst}->{prim_delay};
    $ALL->{cells}->{$prim_inst}->{prim_delay_ps} = $MODULE->{cells}->{$prim_inst}->{prim_delay_ps};
    $ALL->{cells}->{$prim_inst}->{pin_string} = $MODULE->{cells}->{$prim_inst}->{pin_string};

    foreach $pin_name (keys %{$MODULE->{cells}->{$prim_inst}->{pins}}){
	$net = $MODULE->{cells}->{$prim_inst}->{pins}->{$pin_name};
	if ($pin_name eq 'pin0') {
	    # output pin, 
	    foreach $inst_pin (keys %{$MODULE->{nets}->{$net}}){
		# going over all pins on that net
		if (defined $MODULE->{ports}->{$net}) {
		    # output pin conneted to port, probably output
		    $ALL->{cells}->{$prim_inst}->{pins}->{$pin_name}->{$net} = 4;
		}
		elsif ($inst_pin =~ /\w+\/pin0/){		   
		    # skip the net driver, kind of null pointer
		    # $ALL->{cells}->{$prim_inst}->{pins}->{$pin_name}->{$net} = 2;
		}
		else {
		    $ALL->{cells}->{$prim_inst}->{pins}->{$pin_name}->{$inst_pin} = $net;
		}
	    }   
	}
	else {
	    # input pin
	    foreach $inst_pin (keys %{$MODULE->{nets}->{$net}}){
		if ($inst_pin =~ /\w+\/pin0/){
		    $ALL->{cells}->{$prim_inst}->{pins}->{$pin_name}->{$inst_pin} = $net;
		}
		else {
		    # skip the other net loads
		    if (defined $MODULE->{ports}->{$net}) {
			# input pin connected to port, prabably input
			$ALL->{cells}->{$prim_inst}->{pins}->{$pin_name}->{$net} = 3;
		    }
		}
	    }   
	}
    }
}



$ALL->{ports} = $MODULE->{ports}; 
$ALL->{nets}  = $MODULE->{nets}; 
$ALL->{pins}  = $MODULE->{pins}; 

######################################################
######################################################
######################################################

# net based data structure

open(NETS, ">net_index_to_name_mem.v");
print NETS "// DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";
print NETS "// table used by testbench to translate out_records\n"; 
print NETS "// from turbosim to screen prints with time, value and net name\n"; 

open(IN_SNIFFER,">ref_dut_input_sniffer.v");
print IN_SNIFFER "// DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";
print IN_SNIFFER "// code used to capture inputs change to ref_dut\n";
print IN_SNIFFER "// converting them to vcd format fed to turbosim in_fifo\n";;
print IN_SNIFFER "reg null_bit;\n";

open(SNIFFER, ">ref_dut_sniffer.v");
print SNIFFER "// DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";
print SNIFFER "// code used to capture all changes in ref_dut and\n";
print SNIFFER "// generates screen prints with time, value and net name\n";;

$i=0;
foreach $net (sort keys %{$ALL->{nets}}){


    $hex_display = unpack('H40',sprintf("%-20s",$net)); 
    printf( NETS"%s //  net index:  %4d, net name:     %-20s %s\n",$hex_display, $i,$net, $ALL->{ports}->{$net});

    $net_name_to_index{$net} = $i;
    $net_index_to_name{$i}   = $net;

    print SNIFFER "always @( ref_dut.$net )\n";
    print SNIFFER "begin\n\tdelta_time=(\$time-start_time);\n\tref_dut_change_count = ref_dut_change_count + 1;\n\t\$display(\"===  ref_vcd      time %d ps, value %b, net name $net\",delta_time,ref_dut.$net);\nend\n";


    if (defined $ALL->{ports}->{$net} &&  $ALL->{ports}->{$net} eq 'input') {
	# if net is a port as well ...

	print IN_SNIFFER "
always @(ref_dut.$net)
begin
	dt = \$time - start_time;
	null_bit = push_input({encode_bit_value(ref_dut.$net), 14'd$i, dt});
end
";

    }
    
    
    $i++;
}
close NETS;
close IN_SNIFFER;
close SNIFFER;

######################################################
######################################################
######################################################

# cell based data structure

open(CELLS, ">cell_index_to_data_mem.v");
print CELLS "// DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";
print CELLS "// table may be used turbo sim to hold the cell functionality delay and connectivity\n"; 
print CELLS "// table width is 88 bits\n";
print CELLS "// where first 4 bits holds the primitive type\n";
print CELLS "// next is 16 bits that holds the primitive delay in ps\n";
print CELLS "// next is 12 bits the holds the net index of the output pin - pin0 bit 11 is set if exist\n";
print CELLS "// next is 16 bits for 4 input nets:\n";
print CELLS "// \t12 bits the holds the net index of the input pin  - pinX bit 11 is set if exist\n";
print CELLS "// \t4 bits that holds the input pin current value, set to x, R/W field\n";

$VERILOG_PRIM_ENCODING->{'not'} = 0;
$VERILOG_PRIM_ENCODING->{'buf'} = 1;
$VERILOG_PRIM_ENCODING->{'and'} = 2;
$VERILOG_PRIM_ENCODING->{'or'}  = 3;
$VERILOG_PRIM_ENCODING->{'nor'} = 4;
$VERILOG_PRIM_ENCODING->{'nand'}= 5;


$i=0;
foreach $cell (sort keys %{$ALL->{cells}}){
    # print "----------\n";
    # print Dumper $ALL->{cells}->{$cell};

    $prim_delay_ps = $ALL->{cells}->{$cell}->{prim_delay_ps};

    $prim_type  = $ALL->{cells}->{$cell}->{prim_type};
    $prin_type_code =$VERILOG_PRIM_ENCODING->{$prim_type};

    #                type dly  onet net1 net2 net3 net4 val  ctl
    # printf( CELLS "%01x_%04x_%03x_%03x_%03x_%03x_%03x_%01x_%01x"); 
    $out_hex_line = sprintf("%01x_%04x_",$prin_type_code,$prim_delay_ps);  
    $out_comment  = sprintf("// %4d %-7s |  %-5s %4d ps   ",$i, $cell, $prim_type,$prim_delay_ps);
  
    undef %pin_2_net_name; undef %pin_2_net_index; 
    %pin_2_net_name = (pin0 => undef, pin1 => undef, pin2 => undef, pin3 => undef, pin4 => undef);
    %pin_2_net_index = %pin_2_net_name;

    # print CELLS  Dumper \%pin_2_net;


    foreach $pin (sort keys %{$ALL->{cells}->{$cell}->{pins}}) {
	($inst_pin, $net_name) = each %{$ALL->{cells}->{$cell}->{pins}->{$pin}};
	if ($net_name == 3 || $net_name == 4 ) { # pin connected to input or output
	    $pin_2_net_name{$pin}  = $inst_pin;
	    $pin_2_net_index{$pin} = $net_name_to_index{$inst_pin};

	}
	else {
	    $pin_2_net_name{$pin}  = $net_name;
	    $pin_2_net_index{$pin} = $net_name_to_index{$net_name};
	}
	# print "$pin,$inst_pin, $net_name,$pin_2_net{$pin}\n";  
    }

    # print   Dumper \%pin_2_net_index;
    foreach $pin (sort keys %pin_2_net_index){
		# print "$pin\n";
		if (defined $pin_2_net_index{$pin}) {
			$pin_2_net_index_code =  $pin_2_net_index{$pin}+2**11; # valid bit
			$net_name =  $pin_2_net_name{$pin};
		} 
		else {
			$pin_2_net_index_code =  0; # not net connection
			$net_name =  "UC";
		}

		if ($pin eq "pin0") {
			$out_hex_line .= sprintf("%03x_", $pin_2_net_index_code);
			$out_comment  .= sprintf("%-7s", $net_name);
		} elsif ($net_name eq "UC") {
			$out_hex_line .= sprintf("%03x_%01x_", $pin_2_net_index_code, 3);
			$out_comment  .= sprintf("%-7s z ", $net_name);
		} else {
			$out_hex_line .= sprintf("%03x_%01x_", $pin_2_net_index_code, 2);
				$out_comment  .= sprintf("%-7s x ", $net_name);
		}
		# printf( CELLS "%03x_", $pin_2_net{$pin});
    }

	$out_hex_line = substr($out_hex_line, 0, length($out_hex_line) - 1);

	# TODO: remove last _ in $out_hex_line
	# TODO: add proper comments
	# TODO: set HiZ in UC?

	$out_comment .= "\n";
    
    print CELLS "$out_hex_line    $out_comment";

    $cell_name_to_index{$cell} = $i;
    $cell_index_to_name{$i}    = $cell;


    $i++;
    
}

close CELLS;
######################################################
######################################################
######################################################

# net based data structure

open(NETS, ">net_index_to_data_mem.v");
print NETS "// DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";
print NETS "// table may be used turbosim to hold the net connectivity\n"; 
print NETS "// table width is 92 bits, 5x16+4+4+4\n"; 
print NETS "// where 5 = 1 driver + 4 loads\n";
print NETS "// where 16 = 12 + 4, 12 = cell index + bit 11 set if exist\n";
print NETS "// where 4  = pin index of driving/load cell\n";
print NETS "// next is 4 bits reflects the number of loads on net\n";
print NETS "// next is 4 bits for the current output value, set to x, R/W field\n";
print NETS "// next is 4 bits control that can be used for whatever, also R/W field\n";
print NETS "// next is 16 bits for the next net event time, set to 0, also R/W field\n";
print NETS "// next is 4 bits for the next net event value, set to x, also R/W field\n";
print NETS "// ATTENTION : initial value of input nets/ports currently set to X !!!\n";



foreach $net_index (sort {$a <=> $b} keys %net_index_to_name) {
    $net_name = $net_index_to_name{$net_index};
    # print "$net_index -> $net_index_to_name{$net_index}\n";

    # we are supporting fanout of up to 4 loads on a net
    # we dont want to run into variable recored length


    %net_2_inst_pin = (driver => undef, load1 => undef, load2 => undef, load3 => undef, load4 => undef); 
    $load= 'load1';
    $n_loads=0;
    foreach $inst_pin (keys %{$ALL->{nets}->{$net_name}}) {
	($inst, $pin) = split (/\//, $inst_pin);
	if ($pin eq 'pin0') {
	    %{$net_2_inst_pin{driver}} = ($inst, $pin);
	}
	else {
	    %{$net_2_inst_pin{$load}} = ($inst, $pin);
	    $load++;
	    $n_loads++;
	}
    }
    # print Dumper \%net_2_inst_pin;

    $out_hex_line = '';
    $out_comment  = sprintf("// %4d %-7s |  ",$net_index, $net_name);
 

    foreach $connected_pin (sort keys %net_2_inst_pin) {
	if (defined $net_2_inst_pin{$connected_pin} ) {
	    ($inst , $pin ) =  each %{$net_2_inst_pin{$connected_pin}};
	    $inst_code = $cell_name_to_index{$inst};
	    $pin =~ m/pin(\d+)/;
	    $pin_code = $1;
	    $out_hex_line .= sprintf("%03x_%01x_",($inst_code+2**11),$pin_code);
	    $out_comment  .= sprintf("%-5s %4s ,",$inst,$pin);
	    # print "pins $connected_pin is connected  $inst, $pin\n";
	}
	else {

	    $out_hex_line .= sprintf("%03x_%01x_",0,0);
	    if ($connected_pin eq 'driver') {
		$out_comment  .= sprintf("%-11s,",'no dpin');
	    }
	    else {
		$out_comment  .= sprintf("%-11s,",'no load');
	    }
	    # print "no connection for $connected_pin\n";
	}	    

    }

	# number of loads
    $out_hex_line .= sprintf("%01x_",$n_loads);
    $out_comment  .= sprintf("n loads %1d, ",$n_loads);

	# initial value and control
    $out_comment  .= sprintf( "val x, ctl, ");
    $out_hex_line .= sprintf( "%01x_%01x_", 2,0);

	# next event time and next event value
	$out_comment  .= sprintf( "next time 0, next value x");
    $out_hex_line .= sprintf( "%04x_%01x", 0,2);

    print NETS "$out_hex_line $out_comment\n";
    

} 




close NETS;

sub pin_inst {

    my ($inst_a, $pin_a) = split (/\//, $a);
    my ($inst_b, $pin_b) = split (/\//, $b);
    $pin_a <=> $pin_b;

}

######################################################
######################################################
######################################################
open (MODULE_STRUCT , ">$module_name.pl");
print MODULE_STRUCT "# DATA derived from module $module_name !!!!!!!!!!!!!!!!\n";

print_header("Module $module_name statistics",MODULE_STRUCT );
$n = (keys %net_name_to_index);
printf( MODULE_STRUCT "# %-30s   : %5d\n","Number of nets (inc ports)", $n); 
$n = (keys %{$ALL->{ports}});
printf( MODULE_STRUCT "# %-30s   : %5d\n","Number of ports", $n); 
$n = (keys %{$ALL->{cells}});
printf( MODULE_STRUCT "# %-30s   : %5d\n","Number of cells", $n); 
$n = (keys %{$ALL->{pins}});
printf( MODULE_STRUCT "# %-30s   : %5d\n","Number of cells pins", $n); 




$Data::Dumper::Varname = 'CELLS_ENCODING';
print_header("CELLS encoding struct, net name to net index",MODULE_STRUCT);
print  MODULE_STRUCT Dumper \%cell_name_to_index;

$Data::Dumper::Varname = 'CELLS_ENCODING_REVERSE';
print_header("CELLS encoding struct reversed, net index to net name",MODULE_STRUCT);
print  MODULE_STRUCT Dumper \%cell_index_to_name;



$Data::Dumper::Varname = 'NETS_ENCODING';
print_header("NETS encoding struct, net name to net index",MODULE_STRUCT);
print  MODULE_STRUCT Dumper \%net_name_to_index;

$Data::Dumper::Varname = 'NETS_ENCODING_REVERSE';
print_header("NETS encoding struct reversed, net index to net name",MODULE_STRUCT);
print  MODULE_STRUCT Dumper \%net_index_to_name;

$Data::Dumper::Varname = 'PORTS';
print_header("PORTS struct",MODULE_STRUCT);
print  MODULE_STRUCT Dumper $ALL->{ports};

$Data::Dumper::Varname = 'CELLS';
print_header("CELLS struct",MODULE_STRUCT);
print  MODULE_STRUCT Dumper $ALL->{cells};

$Data::Dumper::Varname = 'NETS';
print_header("NETS struct",MODULE_STRUCT);
print  MODULE_STRUCT Dumper $ALL->{nets};

$Data::Dumper::Varname = 'PINS';
print_header("PINS struct",MODULE_STRUCT);
print  MODULE_STRUCT Dumper $ALL->{pins};

print  MODULE_STRUCT "1;\n\n";


exit;

&gofor('a');
&gofor('a',0,0);
&gofor('f',0,0);
&gofor('U63/pin1',0,0);
&gofor('U96/pin0',0,0);
&gofor('a[7]',0,0);

sub gofor {
    my($net_or_pin) = shift;

    if (@_ == 2) {
	$i     = shift;
	$depth = shift;
    }
    else {
	$i     = 0;
	$depth = 0;
    }

    my($prim_inst, $pin_name);
    my($net);
    my($out_net,$inst_pin );
    my($prim_type,$prim_delay);
    my($out_line);

    if ($i==0){
	if (!defined $MODULE->{nets}->{$net_or_pin} && !defined $MODULE->{pins}->{$net_or_pin}){
	    print "Error!!!, can not find $net_or_pin ...\n";
	    return
	}

	print "=================================\n";
	print "Start Path : $net_or_pin\n";
	print "=================================\n";
    }
    $i++;
    if ($i>250){
	exit;
    }
    $depth++;
    $d=@out_stuck;
    # print "+$i,$d,$depth, $net_or_pin,---\n"; 
    $out_line = sprintf("%3d %3d %-15s  ", $i,$depth, $net_or_pin); 
    if (defined $MODULE->{nets}->{$net_or_pin}) {
	# a call with a net, have to go over all loads, cell/inpins 
	$out_net = $net_or_pin;
	$out_line .= sprintf("%64s\n",R1);
	push (@out_stuck,$out_line); 

	foreach $inst_pin (keys %{$MODULE->{nets}->{$out_net}}) {
	    if ($inst_pin !~ /\w+\/pin0/) {
		&gofor($inst_pin, $i, $depth);
	    }
	}		
    }
    else {
	# expecting inst/pin format	
	my($prim_inst, $pin_name) = split(/\//,$net_or_pin);
	if ($pin_name eq 'pin0') {
	    # pin is output
	    $out_net = $MODULE->{cells}->{$prim_inst}->{pins}->{pin0};
	    $out_line .= sprintf("%-15s %22s %-5s %-15s  ",$prim_inst,'', $pin_name,$out_net);
	    if (defined $MODULE->{ports}->{$out_net}) {
		$out_line .= "END point\n";
		push (@out_stuck,$out_line); 
		print "\nkkk\n@out_stuck"; 
	    }
	    else {
		$out_line .= "R2\n";
		push (@out_stuck,$out_line); 
		&gofor($out_net, $i, $depth);
	    }
	}
	else {
	    # pin is input
	    # advancing one cell
	    $prim_type = $MODULE->{cells}->{$prim_inst}->{prim_type};
	    $prim_delay= $MODULE->{cells}->{$prim_inst}->{prim_delay};
	    $out_net   = $MODULE->{cells}->{$prim_inst}->{pins}->{pin0};
	    $out_line .= sprintf("%-15s %-5s %-10s %5.3f %-5s %-15s  " ,$prim_inst,$pin_name,$prim_type,$prim_delay,pin0,$out_net);
	    if (defined $MODULE->{ports}->{$out_net}) {
		$out_line .= "END point\n";
		push (@out_stuck,$out_line); 
		print "\njjj\n @out_stuck";
	    }
	    else {
		$out_line .= "R3\n";
		push (@out_stuck,$out_line); 
		&gofor($out_net, $i, $depth);
	    }
	}

    }
    $depth--;
    pop @out_stuck;
    $d=@out_stuck;
    # print "-$i,$d,$depth, $net_or_pin,---\n"; 

}

sub print_header {
    my($str) = shift;
    my ($n, $FH);
    if (($n = @_) > 0) {
	$FH = shift;
    }
    else {
	$FH = 0;
    }

    print $FH "#=================================\n";
    print $FH "# $str \n";
    print $FH "#=================================\n";
}
