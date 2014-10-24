/*
 * This is dummy module, which holds all common defines for all modules.
 * all modules should include this one
 *
 *
 * Author: Kimi
 */
`ifndef _common_defines
`define _common_defines

`define TRUE						1'b1
`define FALSE						1'b0

// EQ input signals decode
`define INSERT_CMD					1'b0 // op signal decode
`define EXTRACT_CMD					1'b1 // op signal decode

// turbosim status
`define TURBOSIM_STATUS_OK			2'b00
`define TURBOSIM_STATUS_EQ_FULL		2'b01
`define TURBOSIM_STATUS_CTU_FULL	2'b10

// cell ram indices
`define CELL_RAM_NET_INPUT3_VAL		3:0
`define CELL_RAM_NET_INPUT3_IDX		14:4
`define CELL_RAM_NET_INPUT3_V		15
`define CELL_RAM_NET_INPUT2_VAL		19:16
`define CELL_RAM_NET_INPUT2_IDX		30:20
`define CELL_RAM_NET_INPUT2_V		31
`define CELL_RAM_NET_INPUT1_VAL		35:32
`define CELL_RAM_NET_INPUT1_IDX		46:36
`define CELL_RAM_NET_INPUT1_V		47
`define CELL_RAM_NET_INPUT0_VAL		51:48
`define CELL_RAM_NET_INPUT0_IDX		62:52
`define CELL_RAM_NET_INPUT0_V		63
`define CELL_RAM_NET_OUTPUT_IDX		74:64
`define CELL_RAM_NET_OUTPUT_V		75
`define CELL_RAM_DELAY				91:76
`define CELL_RAM_TYPE				95:92

`define CELL_RAM_FROM_INPUT3_VAL	95:4
`define CELL_RAM_UNTIL_INPUT2_VAL	15:0
`define CELL_RAM_FROM_INPUT2_VAL	95:20
`define CELL_RAM_UNTIL_INPUT1_VAL	31:0
`define CELL_RAM_FROM_INPUT1_VAL	95:36
`define CELL_RAM_UNTIL_INPUT0_VAL	47:0
`define CELL_RAM_FROM_INPUT0_VAL	95:52

// cell types
`define CELL_TYPE_NOT				4'b000
`define CELL_TYPE_BUF				4'b001
`define CELL_TYPE_AND				4'b010
`define CELL_TYPE_OR				4'b011
`define CELL_TYPE_NOR				4'b100
`define CELL_TYPE_NAND				4'b101

// valid
`define CELL_INVALID				1'b0
`define CELL_VALID					1'b1

// value types
`define VALUE_0						2'b00
`define VALUE_1						2'b01
`define VALUE_X						2'b10
`define VALUE_Z						2'b11

// net ram indices
`define NET_RAM_NEXT_EV_VALUE		3:0
`define NET_RAM_NEXT_EV_TIME		19:4
`define NET_RAM_CONTROL				23:20
`define NET_RAM_CURRENT_VALUE		27:24
`define NET_RAM_LOAD_NUM			31:28
`define NET_RAM_NET_LOAD3_PIN		35:32
`define NET_RAM_NET_LOAD3_IDX		46:36
`define NET_RAM_NET_LOAD3_V			47
`define NET_RAM_NET_LOAD2_PIN		51:48
`define NET_RAM_NET_LOAD2_IDX		62:52
`define NET_RAM_NET_LOAD2_V			63
`define NET_RAM_NET_LOAD1_PIN		67:64
`define NET_RAM_NET_LOAD1_IDX		78:68
`define NET_RAM_NET_LOAD1_V			79
`define NET_RAM_NET_LOAD0_PIN		83:80
`define NET_RAM_NET_LOAD0_IDX		94:84
`define NET_RAM_NET_LOAD0_V			95
`define NET_RAM_NET_DRIVE			111:96

`define NET_RAM_CURRENT_VALUE_2BIT	25:24
`define NET_RAM_UNTIL_CURRENT_VALUE 23:0
`define NET_RAM_FROM_CURRENT_VALUE	111:28

`define NET_RAM_FROM_NEXT_EV_TIME	111:20

// event queue indices
`define EQ_TIME						15:0
`define EQ_NET_INDEX				26:16
`define EQ_RESERVED					29:27
`define EQ_NEXT_VALUE				31:30
`define EQ_IS_STIMULUS				32

// CTU indices
`define CTU_GATE0					0
`define CTU_GATE1					1
`define CTU_GATE2					2
`define CTU_GATE3					3
`define CTU_NET_IDX_0				5:4
`define CTU_NET_IDX_1				7:6
`define CTU_NET_IDX_2				9:8
`define CTU_NET_IDX_3				11:10
`define CTU_CELL_IDX				22:12
`define CTU_FLAG					23

`define CTU_SET_LENGTH_WD			10
`define CTU_SET_LENGTH				1024

// input event indices
`define IN_EVENT_TIME				15:0
`define IN_EVENT_NET_IDX			26:16
`define IN_EVENT_NET_VAL			31:30

`endif