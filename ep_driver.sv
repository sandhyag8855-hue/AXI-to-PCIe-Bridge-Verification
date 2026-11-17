class ep_dll_driver extends uvm_driver #(dll_packet);

  `uvm_component_utils(ep_dll_driver)

  virtual dll_if vif;

  dll_packet pkt;
  int unsigned actual_length;
 // axi_scoreboard::mem_rd_extract mem_rd_req;
  memory_model mem;
//  uvm_event link_up_done;
  uvm_event memory_rd_rcp_done;
  uvm_event memory_rd_resp_done;
  
  int hdr_cnt = 0, payload_count = 0;

  function new(string name="ep_dll_driver",uvm_component parent=null);
    super.new(name,parent);
  endfunction

  
   function void build_phase(uvm_phase phase);
    super.build_phase(phase);

     if(!uvm_config_db #(virtual dll_if)::get(this,"","dll_vif",vif))
    `uvm_fatal("DRV","Virtual interface not found")
       
     /* if (!uvm_resource_db #(mem_rd_extract)::read_by_name("GLOBAL","mem_rd_req",mem_rd_req,this))      
       `uvm_fatal("DRV", "mem_rd_req not found")    */
        mem = new();
      if (!mem.randomize())`uvm_fatal("MEM", "Memory randomization failed");   
      memory_rd_rcp_done = uvm_event_pool::get_global("memory_rd_rcp_done");
      memory_rd_resp_done = uvm_event_pool::get_global("memory_rd_resp_done");
endfunction
       
  

   //-------------------------
  // Drive Link Training
  //-------------------------
  task drive_link_training();

    @(posedge vif.tl_dll_clk);

    // Drive DUT inputs
    vif.linkup    <= pkt.linkup;
     @(posedge vif.tl_dll_clk);   
    vif.dll_vc_up <= pkt.dll_vc_up;
    repeat(2) @(posedge vif.tl_dll_clk); 
    
    `uvm_info("DRV",
      $sformatf("\n========== LINK TRAINING ==========\n\LINKUP    = %0d\n\DLL_VC_UP = %08b\n\vc_fc_status=%08b====================================",pkt.linkup,pkt.dll_vc_up, vif.vc_fc_status),UVM_MEDIUM)

    repeat(2) @(posedge vif.tl_dll_clk);
     if (vif.vc_fc_status == 8'hFF) begin
     `uvm_info("DRV","LINK TRAINING COMPLETE - ALL VCs UP",UVM_MEDIUM)
    //  link_up_done.trigger();
     end    
  endtask

 //-------------------------
// Drive Configuration Read TLP Ready
//-------------------------
     
task drive_cfg_rd_tlp();

    // Make sure READY is low before starting
    vif.drv_cb.tx_ready <= 1'b1;
   // @(vif.drv_cb);
    @(posedge vif.tl_dll_clk);
    // Assert READY for CFG transfer
  //  vif.tx_ready <= 1'b1;
  $display("DRIVER: time=%0t tx_ready=%0b",$time,vif.tx_ready);

endtask
     
task drive_mem_write();
  
  vif.tx_ready <= pkt.tx_ready;
  @(posedge vif.tl_dll_clk);
  
endtask
     
 task drive_mem_read();

  $display("========================================");
  $display("DRIVER :: MEMORY READ TLP");
  $display("========================================");

  
  // --------------------------------
  // Create completion headers
  // --------------------------------
  if (hdr_cnt == 0) begin

    // --------------------------------
    // Completion Header 0
    // --------------------------------
    pkt.header0 = 32'h0;
    pkt.header0[31:29] = 3'b010;       // Fmt = 3DW Header + Data
    pkt.header0[28:24] = 5'b01010;     // Type = Completion with Data
    pkt.header0[9:0]   = axi_scoreboard::mem_rd_length;

    // --------------------------------
    // Completion Header 1
    // --------------------------------
    pkt.header1 = 32'h0;
    pkt.header1[31:16] = 16'h0000;     
    pkt.header1[15:13] = 3'b000;       
    pkt.header1[12]    = 1'b0;         
    pkt.header1[11:0]  = axi_scoreboard::mem_rd_length << 2;

    // --------------------------------
    // Completion Header 2
    // --------------------------------
    pkt.header2 = 32'h0;
    pkt.header2[31:16] = axi_scoreboard::mem_rd_requester_id;
    pkt.header2[15:8]  = axi_scoreboard::mem_rd_tag;
    pkt.header2[6:0]   = axi_scoreboard::mem_rd_address[6:0];

  end


  if (axi_scoreboard::mem_rd_length == 0)
  actual_length = 1024;
   else
  actual_length = axi_scoreboard::mem_rd_length;
  // ============================================
  // Send Header + Payload
  // ============================================
  while (payload_count < actual_length) begin

    // ------------------------------------------
    // Drive data on NEGEDGE
    // DUT samples on POSEDGE
    // ------------------------------------------
    @(negedge vif.tl_dll_clk);

    case (hdr_cnt)

      // Header 0
      0: begin
        vif.rx_data = pkt.header0;
        `uvm_info("EP_DRV",$sformatf("CPLD HEADER[%0d] = %08h",hdr_cnt, vif.rx_data),UVM_MEDIUM)
        hdr_cnt++;
      end

      // Header 1
      1: begin
        vif.rx_data = pkt.header1;
        `uvm_info("EP_DRV",$sformatf("CPLD HEADER[%0d] = %08h",hdr_cnt, vif.rx_data),UVM_MEDIUM)
        hdr_cnt++;
      end

      // Header 2
      2: begin
        vif.rx_data = pkt.header2;
        `uvm_info("EP_DRV",$sformatf("CPLD HEADER[%0d] = %08h",hdr_cnt, vif.rx_data),UVM_MEDIUM)
        hdr_cnt++;
      end

      // Payload
      default: begin
        vif.rx_data = memory_model::mem1[payload_count];
        //`uvm_info("EP_DRV",$sformatf("CPLD PALOAD[%0d] = %08h",payload_count, vif.rx_data),UVM_MEDIUM)
        payload_count++;
      end
    endcase

    // ------------------------------------------
    // Assert VALID
    // ------------------------------------------
    vif.rx_valid = 1'b1;

   /* if (hdr_cnt < 3 && payload_count == 0) begin
    `uvm_info("EP_DRV",$sformatf("CPLD HEADER[%0d] = %08h", hdr_cnt, vif.rx_data),UVM_MEDIUM)    
    end
    else begin
    `uvm_info("EP_DRV",$sformatf("CPLD PAYLOAD[%0d] = %08h", payload_count, vif.rx_data),UVM_MEDIUM)
    end*/

    // ------------------------------------------
    // DUT samples here
    // ------------------------------------------
    @(posedge vif.tl_dll_clk);

    // ------------------------------------------
    // Wait for DUT ready
    // ------------------------------------------
    wait (vif.rx_ready == 1'b1);

  end


  // ============================================
  // End of TLP
  // ============================================
  @(negedge vif.tl_dll_clk);

  vif.rx_valid = 1'b0;
  vif.rx_data  = 32'h0;
 // memory_rd_resp_done.trigger();

  `uvm_info("EP_DRV","CPLD TRANSMISSION COMPLETE",UVM_MEDIUM)
 

  // --------------------------------
  // Reset counters
  // --------------------------------
  hdr_cnt       = 0;
  payload_count = 0;

endtask

   
  //-------------------------
  // Run Phase
  //-------------------------
  virtual task run_phase(uvm_phase phase);

    forever begin

      seq_item_port.get_next_item(pkt);
       case (pkt.pkt_type)

      LINK_TRAINING: begin
        drive_link_training();
      end

      CONFIG_READ: begin
        drive_cfg_rd_tlp();
      end
      MEMORY_WRITE: begin
        drive_mem_write(); 
      end
      MEMORY_READ: begin
         memory_rd_rcp_done.wait_ptrigger();
        drive_mem_read();       
      end
      default: begin
        `uvm_error("DRV", "Unknown packet type")
      end

    endcase
      seq_item_port.item_done();

    end

  endtask
     endclass
     