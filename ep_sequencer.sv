class ep_sequencer extends uvm_sequencer #(dll_packet);

  `uvm_component_utils(ep_sequencer)

  function new(string name = "ep_sequencer",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass