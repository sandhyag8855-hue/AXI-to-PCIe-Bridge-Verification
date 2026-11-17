class ep_agent extends uvm_agent;

  `uvm_component_utils(ep_agent)

  ep_dll_driver     drv;
  ep_dll_monitor    mon;
  ep_sequencer      seqr;


  function new(string name="ep_agent",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    drv  = ep_dll_driver::type_id::create("drv",this);
    mon  = ep_dll_monitor::type_id::create("mon",this);
    seqr = ep_sequencer::type_id::create("seqr",this);

  endfunction


  function void connect_phase(uvm_phase phase);

    drv.seq_item_port.connect(seqr.seq_item_export);

  endfunction

endclass