class ep_base_seq extends uvm_sequence #(dll_packet);

  `uvm_object_utils(ep_base_seq)
  `NEW_OBJ

  task pre_body();
    uvm_phase phase = get_starting_phase();

    if (phase != null) begin
      phase.phase_done.set_drain_time(this,100);
      phase.raise_objection(this);
    end
  endtask

  task post_body();
    uvm_phase phase = get_starting_phase();

    if (phase != null) begin
      phase.drop_objection(this);
    end
  endtask

endclass


class ep_link_training_sequence extends uvm_sequence #(dll_packet);
 `uvm_object_utils(ep_link_training_sequence)

  dll_packet pkt;

  function new(string name="ep_link_training_sequence");
    super.new(name);
  endfunction

  virtual task body();

    pkt = dll_packet::type_id::create("pkt");

    // Link training complete
    start_item(pkt);
    pkt.pkt_type = LINK_TRAINING;
    pkt.linkup    = 1'b1;
    pkt.dll_vc_up = 8'b0000_0000;
    finish_item(pkt);

    // VC0 to VC7 initialization
    for(int i = 0; i < 8; i++)
    begin
      start_item(pkt);
      pkt.pkt_type = LINK_TRAINING;
      pkt.dll_vc_up = (8'b0000_0001 << i);
      finish_item(pkt);
      // Give DUT time to update vc_fc_status
      //repeat(2)
     // #10; 
    end
  endtask
endclass


class ep_cfg_read_sequence extends uvm_sequence #(dll_packet);

  `uvm_object_utils(ep_cfg_read_sequence)

  dll_packet pkt;

  function new(string name = "ep_cfg_read_sequence");
    super.new(name);
  endfunction

  virtual task body();

    pkt = dll_packet::type_id::create("pkt");

    start_item(pkt);
    pkt.pkt_type = CONFIG_READ;
    // Only Configuration Read handshake
    pkt.tx_ready = 1'b1;
    finish_item(pkt);

  endtask
endclass

class ep_mem_write_sequence extends uvm_sequence #(dll_packet);

  `uvm_object_utils(ep_mem_write_sequence)

  dll_packet pkt;

  function new(string name = "ep_mem_write_sequence");
    super.new(name);
  endfunction

  virtual task body();

    pkt = dll_packet::type_id::create("pkt");

    start_item(pkt);

    // Memory Read TLP
    pkt.pkt_type = MEMORY_WRITE;

    // DUT can transmit when tx_ready = 1
    pkt.tx_ready = 1'b1;

    finish_item(pkt);

  endtask

endclass


class ep_mem_read_sequence extends uvm_sequence #(dll_packet);

  `uvm_object_utils(ep_mem_read_sequence)

  dll_packet pkt;
 // axi_scoreboard::mem_rd_extract mem_rd_req;

  function new(string name = "ep_mem_read_sequence");
    super.new(name);
  endfunction

  virtual task body();

    pkt = dll_packet::type_id::create("pkt");
    // Read MRd information from Resource DB
    // --------------------------------
  //  if (!uvm_resource_db #(axi_scoreboard::mem_rd_extract)::read_by_name("GLOBAL","mem_rd_req",mem_rd_req, this))
  //  begin
    //  `uvm_fatal("SEQ", "mem_rd_req not found in Resource DB")
  //  end

    start_item(pkt);
      	
    	pkt.pkt_type = MEMORY_READ;

    finish_item(pkt);

  endtask

endclass
