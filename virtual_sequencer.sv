class virtual_sequencer extends uvm_sequencer;

  `uvm_component_utils(virtual_sequencer)

  axi_slave_sequencer axi_seqr;
  ep_sequencer  ep_seqr;
  mem_sequencer mem_seqr;

  function new(string name = "virtual_sequencer",uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
endclass