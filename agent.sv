class axi_slave_agent extends uvm_agent;

  `uvm_component_utils(axi_slave_agent)

  // Component Handles
  axi_slave_driver     drv;
  axi_slave_monitor    mon;
  axi_slave_sequencer  seqr;

  function new(string name = "axi_slave_agent",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    drv  = axi_slave_driver    ::type_id::create("drv", this);
    mon  = axi_slave_monitor   ::type_id::create("mon", this);
    seqr = axi_slave_sequencer ::type_id::create("seqr", this);

  endfunction

  // Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    drv.seq_item_port.connect(seqr.seq_item_export);

  endfunction

endclass