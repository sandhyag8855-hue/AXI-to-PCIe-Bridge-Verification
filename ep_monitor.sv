class ep_dll_monitor extends uvm_monitor;

  `uvm_component_utils(ep_dll_monitor)

  virtual dll_if vif;
  
/*uvm_analysis_port #(dll_packet) ep;
  uvm_analysis_port #(dll_packet) cfg_ep;
  uvm_analysis_port #(dll_packet) mem_rd_ep;
  uvm_analysis_imp  #(transaction, ep_dll_monitor) mem_imp;
  uvm_analysis_port #(dll_packet) mem_wr_ep; 
 */
  
  uvm_analysis_port #(dll_packet) ep;
  uvm_analysis_imp  #(transaction, ep_dll_monitor) mem_imp;
      
  uvm_event tlp_reception_done;  //Event
  uvm_event mem_write_cmp_done;  //Event
  uvm_event memory_rd_rcp_done;  //Event
  
 
  //============================================================
  // TLP TYPE
  //============================================================
  typedef enum {
    TLP_NONE,
    TLP_CFG_RD,
    TLP_CFG_WR,
    TLP_MEM_RD,
    TLP_MEM_WR
  } tlp_type_e;

  tlp_type_e current_tlp_type;


//============================================================
// COUNTERS
//============================================================
/*int hdr_cnt = 0;
int payload_count = 0;
int expected_payload_count = 0;

   
  dll_packet pkt;
  bit link_training_done = 0;
  bit [31:0] hdr0,hdr1,hdr2; */
  
   dll_packet pkt;
  
  int expected_payload_count;
  int payload_count = 0;
  
  int mem_rd_hdr_cnt = 0;
  bit [31:0] mem_rd_hdr0, mem_rd_hdr1, mem_rd_hdr2;
  
   int mem_wr_hdr_cnt = 0;
  

  bit [31:0] hdr0,hdr1,hdr2; 
  bit link_training_done = 0;
    
// Header counter (0=Header0, 1=Header1, 2=Header2)
int hdr_cnt = 0;

// Configuration Read TLP counter (TLP 0 to TLP 15)
int tlp_cnt = 0;
  
//Mem write operation counter
int tx_cnt = 0;
  
  function new(string name="ep_dll_monitor",uvm_component parent=null);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ep = new("ep",this);
    mem_imp = new("mem_imp", this);
    
   if(!uvm_config_db #(virtual dll_if)::get(this,"","dll_vif",vif))`uvm_fatal("MON","Virtual interface not found")
     tlp_reception_done = uvm_event_pool::get_global("tlp_reception_done"); //Event
     mem_write_cmp_done = uvm_event_pool::get_global("mem_write_cmp_done");
     memory_rd_rcp_done = uvm_event_pool::get_global("memory_rd_rcp_done");
     endfunction
  
  
 function void write(transaction tr);

   expected_payload_count = ((tr.arlen + 1  ) * (1 << tr.arsize)) / 4;

  /*`uvm_info("EP_MON",$sformatf("Received ARLEN=%0d ARSIZE=%0d Expected Payload DW=%0d",
              tr.arlen,
              tr.arsize,
                               expected_payload_count),UVM_LOW)*/
 endfunction
     
  
task monitor_link_training();

  if (vif.linkup)
  begin

    link_training_done = 0;

    while (!link_training_done)
    begin
      //@(posedge vif.tl_dll_clk);
      @(vif.dll_vc_up or vif.vc_fc_status);
      pkt = dll_packet::type_id::create("pkt");

      pkt.linkup       = vif.linkup;
      pkt.dll_vc_up    = vif.dll_vc_up;
      pkt.vc_fc_status = vif.vc_fc_status;

      `uvm_info("MON",$sformatf("DLL_VC_UP=%08b VC_FC_STATUS=%08b",pkt.dll_vc_up,pkt.vc_fc_status),UVM_MEDIUM)
      
       pkt.header0 = 32'hFFFFFFFF;
       ep.write(pkt);//Dummy value so that it will not overlap with memory read operation

      if (vif.vc_fc_status == 8'hFF)
      begin
        link_training_done = 1;          
        `uvm_info("MON",$sformatf("LINK TRAINING DONE: VC_FC_STATUS=%08b",vif.vc_fc_status),UVM_MEDIUM)
      end
    end
  end

endtask
  
  
/*task monitor_config_read_completion();

    if (!vif.mon_cb.target_device_type  && !vif.mon_cb.tlp_type_mon)   
    begin

    case (hdr_cnt)

      //========================================
      // HEADER 0
      //========================================
      0: begin
        hdr0 = vif.mon_cb.tx_data;
        hdr_cnt = 1;
      end


      //========================================
      // HEADER 1
      //========================================
      1: begin
        hdr1 = vif.mon_cb.tx_data;
        hdr_cnt = 2;
      end


      //========================================
      // HEADER 2
      //========================================
      2: begin
        hdr2 = vif.mon_cb.tx_data;
        if (tlp_cnt < 16) begin

        // ---------------------------------------
        // CFG READ TLPs: TLP 0 to TLP 14
        // ---------------------------------------
        pkt = dll_packet::type_id::create("cfg_pkt");
        pkt.header0 = hdr0;
        pkt.header1 = hdr1;
        pkt.header2 = hdr2;

        $display("MON: time=%0t TLP=%0d HEADER0=%08h HEADER1=%08h HEADER2=%08h",$time,
          tlp_cnt,
          pkt.header0,
          pkt.header1,
          pkt.header2
        );

        ep.write(pkt);

        tlp_cnt++;
        hdr_cnt = 0;

    end
          else begin

        // 16 CFG TLPs completed
        // Next DW belongs to WRITE TLP
        hdr_cnt = 3;

    end
      end
        3: begin

    pkt = dll_packet::type_id::create("write_tlp");

    pkt.header0 = hdr0;
    pkt.header1 = hdr1;
    pkt.header2 = hdr2;
    pkt.payload[0] = vif.mon_cb.tx_data;

    $display(
      "MON: time=%0t WRITE TLP HEADER0=%08h HEADER1=%08h HEADER2=%08h PAYLOAD=%08h",
      $time,
      pkt.header0,
      pkt.header1,
      pkt.header2,
      pkt.payload[0]
    );

    ep.write(pkt);
          

    // Reset for next TLP
    hdr_cnt = 0;
          $display("MEM CFG :: ENTER capture: hdr_cnt=%0d",hdr_cnt);
    tlp_cnt = 0;
          
          vif.enumeration_done_tb = 1'b1;
          tlp_reception_done.trigger();
                  
end
    endcase
  end 
  
  //=========================================Memory write capture========================================//
  
  
  if (vif.mon_cb.tlp_type_mon == 1) begin

    //========================================
    // Create object for NEW Memory Write TLP
    //========================================
    if (mem_wr_hdr_cnt == 0) begin

        pkt = dll_packet::type_id::create("mem_wr_pkt");

        payload_count = 0;

    end


    //========================================
    // Capture 3-DW Header
    //========================================
    if (mem_wr_hdr_cnt < 3) begin

        case (mem_wr_hdr_cnt)

            0: begin
                pkt.header0 = vif.mon_cb.tx_data;

                //========================================
                // Decode PCIe Length field
                // Length is in DW
                // HEADER[0][9:0]
                //========================================
                expected_payload_count = vif.mon_cb.tx_data[9:0];
              if (expected_payload_count == 0) expected_payload_count = 1024;

                $display("EP_MON :: HEADER[0] = %08h",vif.mon_cb.tx_data);
                $display("EP_MON :: PCIe PAYLOAD LENGTH = %0d DW = %0d BYTES",expected_payload_count,expected_payload_count * 4);
            end


            1: begin
                pkt.header1 = vif.mon_cb.tx_data;

                $display("EP_MON :: HEADER[1] = %08h",vif.mon_cb.tx_data);
            end


            2: begin
                pkt.header2 = vif.mon_cb.tx_data;

                $display("EP_MON :: HEADER[2] = %08h",
                         vif.mon_cb.tx_data);
            end

        endcase

        mem_wr_hdr_cnt++;

    end


    //========================================
    // Capture Payload
    //========================================
    else begin

        pkt.payload[payload_count] = vif.mon_cb.tx_data;
        memory_model::mem2[payload_count] = vif.mon_cb.tx_data;

       // $display("EP_MON :: PAYLOAD[%0d] = %08h",payload_count,vif.mon_cb.tx_data);
        payload_count++;


        //========================================
        // Complete TLP
        //========================================
        if (payload_count == expected_payload_count) begin

            $display("EP_MON :: TLP COMPLETE");
            $display("EP_MON :: HEADER = 3 DW");
            $display("EP_MON :: PAYLOAD = %0d DW",expected_payload_count);           
            ep.write(pkt);


            //====================================
            // Prepare for NEXT TLP
            //====================================
            mem_wr_hdr_cnt = 0;
            payload_count  = 0;
            expected_payload_count = 0;
            pkt = null;
            mem_write_cmp_done.trigger();
            

        end
    end 
  end
  
   //=========================================Memory read capture========================================//
  
  
  if (vif.mon_cb.tlp_type_mon == 2) begin

    if (mem_rd_hdr_cnt < 3) begin

        case (mem_rd_hdr_cnt)

            //========================================
            // HEADER 0
            //========================================
            0: begin

                // New TLP -> create new packet
                pkt = dll_packet::type_id::create("mem_rd_pkt");
                pkt.header0 = vif.mon_cb.tx_data;
                mem_rd_hdr_cnt = 1;

            end


            //========================================
            // HEADER 1
            //========================================
            1: begin

                pkt.header1 = vif.mon_cb.tx_data;               
                mem_rd_hdr_cnt = 2;

            end


            //========================================
            // HEADER 2
            //========================================
            2: begin

                pkt.header2 = vif.mon_cb.tx_data;
              $display("EP_MON :: MEM_RD  \n HEADER[0] = %08h\n HEADER[1] = %08h\n HEADER[2] = %08h", 
                     pkt.header0,
                     pkt.header1,
                     pkt.header2);
                $display("EP_MON :: MEM_RD TLP COMPLETE");
               
                // 3 DW header captured
              
                memory_rd_rcp_done.trigger();
                mem_rd_hdr_cnt = 0;
                ep.write(pkt);
                // Send to analysis port if required
                //mem_rd_ep.write(pkt);

                pkt = null;
            end
        endcase
    end
end
 
endtask*/
 
 
  
//============================================New modification============================================================//
  
task monitor_config_read_completion();

  bit [2:0] fmt;
  bit [4:0] type_t;

  //==========================================================
  // Capture first DW and decode TLP type from FMT + TYPE
  //==========================================================
  if (hdr_cnt == 0)
  begin

    hdr0 = vif.mon_cb.tx_data;

    // Decode FMT and TYPE from actual transmitted TLP
    fmt    = hdr0[31:29];
    type_t = hdr0[28:24];

    case ({fmt, type_t})

      //======================================================
      // CFG READ
      //======================================================
      {3'b000, 5'b00100}:
      begin
        current_tlp_type = TLP_CFG_RD;

        pkt = dll_packet::type_id::create("cfg_pkt");

        pkt.header0 = hdr0;

        hdr_cnt = 1;

        `uvm_info("EP_MON",
                  $sformatf("CFG_RD detected : HEADER0=%08h",
                            hdr0),
                  UVM_MEDIUM)
      end


      //======================================================
      // CFG WRITE
      //======================================================
      {3'b010, 5'b00100}:
      begin
        current_tlp_type = TLP_CFG_WR;

        pkt = dll_packet::type_id::create("cfg_wr_pkt");

        pkt.header0 = hdr0;

        hdr_cnt = 1;

        `uvm_info("EP_MON",
                  $sformatf("CFG_WR detected : HEADER0=%08h",
                            hdr0),
                  UVM_MEDIUM)
      end


      //======================================================
      // MEMORY READ
      //======================================================
      {3'b000, 5'b00000}:
      begin
        current_tlp_type = TLP_MEM_RD;

        pkt = dll_packet::type_id::create("mem_rd_pkt");

        pkt.header0 = hdr0;

        hdr_cnt = 1;

        `uvm_info("EP_MON",
                  $sformatf("MEM_RD detected : HEADER0=%08h",
                            hdr0),
                  UVM_MEDIUM)
      end


      //======================================================
      // MEMORY WRITE
      //======================================================
      {3'b010, 5'b00000}:
      begin
        current_tlp_type = TLP_MEM_WR;

        pkt = dll_packet::type_id::create("mem_wr_pkt");

        pkt.header0 = hdr0;

        // Decode PCIe payload length
        expected_payload_count = hdr0[9:0];

        // PCIe encoded length 0 means 1024 DW
        if (expected_payload_count == 0)
          expected_payload_count = 1024;

        payload_count = 0;

        hdr_cnt = 1;

        `uvm_info("EP_MON",
                  $sformatf("MEM_WR detected : HEADER0=%08h PAYLOAD=%0d DW",
                            hdr0,
                            expected_payload_count),
                  UVM_MEDIUM)
      end


      //======================================================
      // UNKNOWN TLP
      //======================================================
      default:
      begin
        current_tlp_type = TLP_NONE;
        hdr_cnt = 0;
        pkt = null;
      end

    endcase

  end


  //==========================================================
  // HEADER 1
  //==========================================================
  else if (hdr_cnt == 1)
  begin

    hdr1 = vif.mon_cb.tx_data;

    pkt.header1 = hdr1;

    hdr_cnt = 2;

  end


  //==========================================================
  // HEADER 2
  //==========================================================
  else if (hdr_cnt == 2)
  begin

    hdr2 = vif.mon_cb.tx_data;

    pkt.header2 = hdr2;

    //========================================================
    // CFG READ
    //========================================================
    if (current_tlp_type == TLP_CFG_RD)
    begin

      if (tlp_cnt < 16)
      begin

        $display(
          "MON: time=%0t CFG_RD TLP=%0d HEADER0=%08h HEADER1=%08h HEADER2=%08h",
          $time,
          tlp_cnt,
          pkt.header0,
          pkt.header1,
          pkt.header2
        );

        ep.write(pkt);

        tlp_cnt++;

        hdr_cnt = 0;

        pkt = null;

      end

    end


    //========================================================
    // CFG WRITE
    //
    // Header is complete.
    // Next handshaked DW will be payload.
    //========================================================
    else if (current_tlp_type == TLP_CFG_WR)
    begin

      hdr_cnt = 3;

    end


    //========================================================
    // MEMORY READ
    //========================================================
    else if (current_tlp_type == TLP_MEM_RD)
    begin

      $display(
        "EP_MON :: MEM_RD\n HEADER[0] = %08h\n HEADER[1] = %08h\n HEADER[2] = %08h",
        pkt.header0,
        pkt.header1,
        pkt.header2
      );

      $display("EP_MON :: MEM_RD TLP COMPLETE");

      memory_rd_rcp_done.trigger();

      mem_rd_hdr_cnt = 0;

      ep.write(pkt);

      pkt = null;

      hdr_cnt = 0;

    end


    //========================================================
    // MEMORY WRITE
    //
    // Header is complete.
    // Next handshaked DW will be payload.
    //========================================================
    else if (current_tlp_type == TLP_MEM_WR)
    begin

      hdr_cnt = 3;

    end

  end


  //==========================================================
  // PAYLOAD
  //==========================================================
  else if (hdr_cnt >= 3)
  begin

    //========================================================
    // CFG WRITE PAYLOAD
    //========================================================
    if (current_tlp_type == TLP_CFG_WR)
    begin

      pkt.payload[0] = vif.mon_cb.tx_data;

      $display(
        "MON: time=%0t CFG_WR HEADER0=%08h HEADER1=%08h HEADER2=%08h PAYLOAD=%08h",
        $time,
        pkt.header0,
        pkt.header1,
        pkt.header2,
        pkt.payload[0]
      );

      ep.write(pkt);

      // Enumeration completed
      hdr_cnt = 0;
      tlp_cnt = 0;

      pkt = null;
      vif.enumeration_done_tb = 1'b1;
      tlp_reception_done.trigger();

    end


    //========================================================
    // MEMORY WRITE PAYLOAD
    //========================================================
    else if (current_tlp_type == TLP_MEM_WR)
    begin

      pkt.payload[payload_count] = vif.mon_cb.tx_data;

      memory_model::mem2[payload_count] = vif.mon_cb.tx_data;

      payload_count++;

      //======================================================
      // Complete MEM_WR TLP
      //======================================================
      if (payload_count == expected_payload_count)
      begin

        $display("EP_MON :: MEM_WR TLP COMPLETE");
        $display("EP_MON :: HEADER = 3 DW");
        $display("EP_MON :: PAYLOAD = %0d DW",
                  expected_payload_count);

        ep.write(pkt);

        // Prepare for next TLP
        hdr_cnt = 0;

        payload_count = 0;

        expected_payload_count = 0;

        pkt = null;

        mem_wr_hdr_cnt = 0;

        mem_write_cmp_done.trigger();

      end
    end
  end
endtask
  
         
 virtual task run_phase(uvm_phase phase);

  forever begin
    @(vif.mon_cb);

    if (!link_training_done) begin
      monitor_link_training();
    end

    if (vif.mon_cb.tx_valid && vif.mon_cb.tx_ready) begin
      monitor_config_read_completion();
    end
  end
endtask
endclass

    

 
    
    