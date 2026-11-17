class main_virtual_sequence extends uvm_sequence;

  `uvm_object_utils(main_virtual_sequence)

  `uvm_declare_p_sequencer(virtual_sequencer)
  
  //========================================================
  // AXI SEQUENCE HANDLES
  //========================================================

  axi_rst_dut                axi_rst_seq;
  axi_multiple_wr_seq        axi_mt_wd;
  axi_multiple_rd_seq        axi_mt_rd;
  ep_link_training_sequence  ep_lup;
  axi_dma_config_read_write  axi_dma_cfg_wrd;
  ep_cfg_read_sequence       ep_cfg_wrd;
  axi_dma_mem_wr_seq         axi_dma_mwr;
  mem_write                  mem_wr;
  axi_dma_mem_rd_seq         axi_dma_mrd;
  ep_mem_read_sequence       ep_mem_rd;
  axi_rx_desc_wr_seq         axi_rx_desrc_rd;
  axi_memory_read            mem_axi_m_rd;
  //========================================================
  // EVENT
  //========================================================
  uvm_event tlp_reception_done;
  uvm_event mem_write_cmp_done;
  uvm_event memory_rd_resp_done;
  
  function new(string name = "main_virtual_sequence");
    super.new(name);
  endfunction


  task body();
    // Create sequences
    
    //Event
    tlp_reception_done = uvm_event_pool::get_global("tlp_reception_done");
    mem_write_cmp_done = uvm_event_pool::get_global("mem_write_cmp_done");
    memory_rd_resp_done = uvm_event_pool::get_global("memory_rd_resp_done");
    
    //Sequences
    axi_rst_seq = axi_rst_dut::type_id::create("axi_rst_seq");
    axi_mt_wd   = axi_multiple_wr_seq::type_id::create("axi_mt_wd");
    axi_mt_rd   = axi_multiple_rd_seq::type_id::create("axi_mt_rd");
    ep_lup = ep_link_training_sequence::type_id::create("ep_lup");
    axi_dma_cfg_wrd = axi_dma_config_read_write::type_id::create("axi_dma_cfg_wrd");
    ep_cfg_wrd = ep_cfg_read_sequence::type_id::create("ep_cfg_wrd");
    axi_dma_mwr = axi_dma_mem_wr_seq::type_id::create("axi_dma_mwr");
    mem_wr = mem_write::type_id::create("mem_wr");
    axi_dma_mrd = axi_dma_mem_rd_seq::type_id::create("axi_dma_mrd");
    ep_mem_rd = ep_mem_read_sequence::type_id::create("ep_mem_rd");
    axi_rx_desrc_rd = axi_rx_desc_wr_seq::type_id::create("axi_rx_desrc_rd");
    mem_axi_m_rd = axi_memory_read::type_id::create("mem_axi_m_rd");
    
    // Sequence execution will come here
    // Execute sequentially
    axi_rst_seq.start(p_sequencer.axi_seqr);
    axi_mt_wd.start(p_sequencer.axi_seqr);
    axi_mt_rd.start(p_sequencer.axi_seqr);
    
    
    //Link up
     axi_dma_cfg_wrd.start(p_sequencer.axi_seqr);
     ep_lup.start(p_sequencer.ep_seqr);
     
    //Config read and write packets  
    ep_cfg_wrd.start(p_sequencer.ep_seqr);
    tlp_reception_done.wait_trigger();
    `uvm_info("VSEQ","17 TLPs received. Previous operation complete.",UVM_MEDIUM)
    
    //Mmeory write operation
    axi_dma_mwr.start(p_sequencer.axi_seqr);    
    mem_wr.dma_length = axi_dma_mwr.dma_length;   
    mem_wr.start(p_sequencer.mem_seqr);
    mem_write_cmp_done.wait_trigger();
   `uvm_info("VSEQ","MEM_WR complete.",UVM_MEDIUM)
    
    //Mmeory read operation
    axi_rx_desrc_rd.start(p_sequencer.axi_seqr);    
    axi_dma_mrd.start(p_sequencer.axi_seqr);
    
    mem_axi_m_rd.rx_length = axi_rx_desrc_rd.rx_length;
    
    ep_mem_rd.start(p_sequencer.ep_seqr);
    mem_axi_m_rd.start(p_sequencer.mem_seqr);
   
          
    #600000;
    
  endtask
endclass