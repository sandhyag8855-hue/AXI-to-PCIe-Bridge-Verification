class mem_agent extends uvm_agent;

  `uvm_component_utils(mem_agent)

  mem_sequencer mem_seqr;
  mem_driver    mem_drv;
  mem_monitor  mem_mon;

  function new(string name = "mem_agent",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction


  //========================================================
  // BUILD PHASE
  //========================================================
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);
    // Create monitor
    mem_mon = mem_monitor::type_id::create("mem_mon",this);
    mem_seqr = mem_sequencer::type_id::create("mem_seqr",this);
    mem_drv = mem_driver::type_id::create("mem_drv",this);
  endfunction


  //========================================================
  // CONNECT PHASE
  //========================================================
  virtual function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     mem_drv.seq_item_port.connect(mem_seqr.seq_item_export);
  endfunction
endclass