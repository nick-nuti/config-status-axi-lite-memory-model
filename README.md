NOTE: 
- Generation script does not have any special parsing for the JSON at the current moment; so be aware of overlapping bit domains.
- All of this was synthesized and simulated using Vivado 2024.1
- Example model provided used 81 LUTs and 163 FFs (includes axi-lite slave)
- The registers you include do affect the size of the memory model (RC and W1C use more resources)

-------------------------------------------------

How to use the script:
ex: python .\mem_config.py -i .\mem_config.json -o outputdir

- mem_config.json:
--> you can add however many registers you want within the "registers" JSON list (please just copy the preexisting formats... again the script does not have complete parsing)

--> you can add however many signals you want within the "signal_list" JSON list
  ---> keep track of overlapping "low_bit"'s and "high_bit"'s and PLEASE keep the bit depths within the "data_width" attribute bit depth

--> generate your MASKS in this file, they will coincide with the signal bits inside of "signal_list"

-------------------------------------------------

Register field types (CPU point of view):

- RW (Read/Write) :
  -- CPU can read + write register field
  -- logic can read this register field (cannot write because it lacks arbitration)
  
- W1C (Write 1 Clear) :
  -- CPU can read and clear this field by writing a 1 to it (writing a zero does nothing
  -- logic can write this field and receives a "clear" indication from CPU
  
- WO (Write Only) :
  -- CPU can only write this field (reading this field will return nothing)
  -- logic can read this field
  
- RC (Read Clear) :
  -- CPU can only read this field (which clears whatever is in it after being read)
  -- logic can write this field and receives a "clear" indication from CPU
  
- RO (Read Only) :
  -- CPU can only read this field (writing this field does nothing)
  -- logic can write this field
  
- Pulse (Pulse) :
  -- CPU can write this field and field will pulse high for one clock cycle
  -- logic can only read this one-cycle pulse

-------------------------------------------------

Explanation :
1. CPU + master axi-lite <--- R/W ---> slave axi-lite

2. slave axi-lite <---> reg_generation
   - reg_generation reads reg_desc_pkg within a generate loop to create instances of reg_slice
   - reg_slice is the memory model core (involves utilizing the masks and is how axi-lite reads and write memory)
   - reg_generation uses "reg_if" to communicate with logic. Contains [DATA_W-1:0] number of bits going from (memory to logic) and from (logic to memory)

3. reg_generation (reg_slices) <---> reg_adapter
   - reg_adapter involves simple wiring between "reg_if" interfaces and logic

4. reg_adapter <---> custom logic
   - connect your custom logic to here!!!!

-------------------------------------------------

Required simulation sources:
- *_testbench.sv
- axilite_master.sv

Required design sources:
- *_defines.vh
- *_top.sv
- axilite_slave.sv
- *_reg_adapter.sv
- *_reg_desc_pkg.sv
- *_reg_generation.sv
- *_reg_interface.sv
- *_reg_slice.sv 
