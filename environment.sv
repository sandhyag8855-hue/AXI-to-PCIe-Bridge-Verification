class axi_env extends uvm_env;

  `uvm_component_utils(axi_env)

  axi_slave_agent agent;
  axi_scoreboard  sb;
  ep_agent e_agt;
  mem_agent mem_agnt;
  virtual_sequencer vseqr;
  ep_coverage cov;

  function new(string name="axi_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent = axi_slave_agent::type_id::create("agent", this);
    e_agt = ep_agent::type_id::create("e_agt", this);
    mem_agnt = mem_agent::type_id::create("mem_agnt", this);
    sb    = axi_scoreboard ::type_id::create("sb", this);
    vseqr = virtual_sequencer::type_id::create("vseqr", this);
    cov = ep_coverage::type_id::create("cov", this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);   
     agent.mon.ap.connect(sb.analysis_export);
     e_agt.mon.ep.connect(sb.ep_export);
     mem_agnt.mem_mon.mem_ap.connect(e_agt.mon.mem_imp);
     mem_agnt.mem_mon.axi_mem_ap.connect(sb.axi_mem_imp);
     mem_agnt.mem_mon.addr_ap.connect(sb.addr_imp);
     e_agt.mon.ep.connect(cov.analysis_export);
    //========================================================
    // Connect REAL sequencers to VIRTUAL sequencer
    //========================================================

    vseqr.axi_seqr = agent.seqr;            // NEW
    vseqr.ep_seqr  = e_agt.seqr;            // NEW
    vseqr.mem_seqr = mem_agnt.mem_seqr;     // NEW
     
  endfunction

endclass