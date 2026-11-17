class mem_driver extends uvm_driver #(transaction);

  `uvm_component_utils(mem_driver)

  virtual memory_if mif;
  transaction tr;
  int index;
  int beat;
  int num_beats;
  memory_model mem_model;

  function new(string name = "mem_driver",uvm_component parent = null);
    super.new(name, parent);
  endfunction


  //========================================================
  // BUILD PHASE
  //========================================================
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual memory_if)::get(this,"","mif",mif)) 
      begin
      `uvm_fatal("MEM_DRV", "Memory AXI interface (mif) not found")
    end
    mem_model = new();
    if (!mem_model.randomize())
      begin
      `uvm_fatal("MEM_INIT", "Memory randomization failed");
      `uvm_info("MEM_INIT",$sformatf("MEM[0]=%08h MEM[1]=%08h MEM[15]=%08h",
              memory_model::mem1[0],
              memory_model::mem1[1],
              memory_model::mem1[15]),
    UVM_MEDIUM)
      end
  endfunction
  

task write_tx();

  for (int burst = 0; burst < tr.num_bursts; burst++) begin

    $display("%0t:: Hi iam burst = %0d",$time,burst);

    //======================================================
    // Drive ARREADY
    //======================================================
    @(mif.drv_cb);
    mif.drv_cb.arready <= 1'b1;

    //======================================================
    // Wait for DUT ARVALID
    //======================================================
    wait(mif.drv_cb.arvalid == 1'b1);

    //======================================================
    // AR handshake
    //======================================================
    if (mif.drv_cb.arvalid ) begin

      `uvm_info("MEM_DRV",$sformatf(
        "\n========== MEMORY READ ADDRESS ==========\nARADDR=0x%08h\nARLEN=%0d\nARID=%0d\nARBURST=%0b\nARSIZE=%0d\nARVALID=%0b\n=========================================",
        mif.drv_cb.araddr,
        mif.drv_cb.arlen,
        mif.drv_cb.arid,
        mif.drv_cb.arburst,
        mif.drv_cb.arsize,
        mif.drv_cb.arvalid
      ),UVM_MEDIUM);

      //====================================================
      // Get memory index and number of beats
      //====================================================
      index     = memory_model::decode_addr(mif.drv_cb.araddr);
      num_beats = mif.drv_cb.arlen + 1;

      //====================================================
      // Deassert ARREADY
      //====================================================
      mif.drv_cb.arready <= 1'b0;

      //====================================================
      // Send RDATA beats
      //====================================================
      for (beat = 0; beat < num_beats; beat++) begin

        mif.drv_cb.rdata  <= memory_model::mem1[index + beat];
        mif.drv_cb.rvalid <= 1'b1;
        mif.drv_cb.rlast  <= (beat == num_beats - 1);

        /*`uvm_info("MEM_DRV",
          $sformatf(
            "BURST[%0d/%0d] BEAT[%0d/%0d] ADDR=%08h DATA=%08h RVALID=1 RLAST=%0b",
            burst + 1,
            tr.num_bursts,
            beat,
            num_beats - 1,
            mif.drv_cb.araddr + (beat * 4),
            memory_model::mem1[index + beat],
            (beat == num_beats - 1)
          ),
          UVM_MEDIUM
        );*/

        //==================================================
        // Wait for DUT to accept this beat
        //==================================================
        do begin
          @(mif.drv_cb);
        end
        while (mif.drv_cb.rready !== 1'b1);

      end

      //====================================================
      // RLAST handshake is complete
      // Give DUT one clock to process RLAST
      //====================================================
      @(mif.drv_cb);

      //====================================================
      // End current burst
      //====================================================
      mif.drv_cb.rvalid <= 1'b0;
      mif.drv_cb.rlast  <= 1'b0;
      mif.drv_cb.rdata  <= '0;

    end

  end

  //========================================================
  // All bursts completed
  //========================================================
  mif.drv_cb.arready <= 1'b0;

endtask
  
    
  
  task read_tx();
  //--------------------------------
  // READ ADDRESS CHANNEL (AR)
  //--------------------------------
    wait(mif.arvalid == 1'b1)
    mif.arready <= tr.arready;
    
    
    @(posedge mif.tl_dll_clk);
    
    `uvm_info("DRV",$sformatf("MEM_DRV ::%0b",tr.arready),UVM_MEDIUM)
         
     if (mif.arvalid && mif.arready) 
       begin
        index = memory_model::decode_addr(mif.araddr);
        num_beats = mif.arlen + 1;

        `uvm_info("MEM_DRV",$sformatf("READ REQUEST : ADDR=0x%08h ARLEN=%0d BEATS=%0d INDEX=%0d",mif.araddr,mif.arlen,num_beats,index), UVM_MEDIUM)
           mif.arready <= 1'b0;
    end

    //--------------------------------
    // READ DATA CHANNEL
    //--------------------------------
    for (beat = 0; beat < num_beats; beat++) begin

        tr.rdata = memory_model::mem1[index + beat];

        mif.rdata  <= tr.rdata;
        mif.rvalid <= tr.rvalid;
        mif.rid    <= tr.rid;
        mif.rresp  <= tr.rresp;

        if (beat == num_beats - 1)
            mif.rlast <= 1'b1;
        else
            mif.rlast <= tr.rlast;

        //--------------------------------
        // R HANDSHAKE
        //--------------------------------
        wait (mif.rready == 1'b1);
        @(posedge mif.tl_dll_clk);

        if (mif.rvalid && mif.rready) begin
            `uvm_info("MEM_DRV",$sformatf("RDATA : BEAT=%0d DATA=0x%08h RVALID=%0b RREADY=%0b RLAST=%0b",
                    beat,
                    mif.rdata,
                    mif.rvalid,
                    mif.rready,
                    mif.rlast
                ), UVM_MEDIUM)
        end

        mif.rvalid <= 1'b0;

        if (beat == num_beats - 1)
            mif.rlast <= 1'b0;

    end 
   // mif.arready <= 1'b0;
endtask
  
task axi_mem_read();
  int temp_awlen;
  bit temp_wlast;
 // int num_burst;
  

  for (int burst = 0; burst < tr.num_bursts; burst++) begin

    `uvm_info("AXI_MEM",$sformatf("========== AXI BURST %0d / %0d ==========",burst, tr.num_bursts),
      UVM_MEDIUM)
  //========================================================
  // AXI WRITE ADDRESS PHASE
  //========================================================
 // @(posedge mif.aclk);

  //if (mif.awvalid == 1) begin
   
    @(posedge mif.aclk);   
    wait (mif.awvalid == 1);

    mif.awready = 1;
    
    // Store AWLEN temporarily
    temp_awlen = mif.awlen;
   
    `uvm_info("AXI_MEM",
      $sformatf("AWVALID=%0b AWREADY=%0b AWADDR=%08h AWLEN=%0d AWID=%0d AWBURST=%0b AWSIZE=%0d",
      mif.awvalid,
      mif.awready,
      mif.awaddr,
      mif.awlen,
      mif.awid,
      mif.awburst,
      mif.awsize),
      UVM_MEDIUM)
    
    

  //end
//  else begin
  //  mif.awready = 0;
 // end


  //========================================================
  // AXI WRITE DATA PHASE
  // AWLEN = 15 -> 16 DATA BEATS
  //========================================================
  @(posedge mif.aclk);
    for (int i = 0; i <= temp_awlen; i++) begin

     wait (mif.wvalid == 1);

   // if (mif.wvalid == 1) begin
      @(negedge mif.aclk);
      mif.wready = 1;
    
     
    
    
  // AXI clock / handshake
   @(posedge mif.aclk);
      
       if (mif.wlast  == 1) begin
       //mif.wready = 0;
      // mif.awready = 0;
      `uvm_info("AXI_MEM","LAST DATA BEAT RECEIVED",UVM_MEDIUM)
         @(negedge mif.aclk);
            mif.wready = 0;
      break;
    end
       
      
       // Deassert READY immediately after this beat
            @(negedge mif.aclk);
            mif.wready = 0;

    // Check last beat
     //@(posedge mif.aclk);
   

  //  mif.wready = 0;

  end

  //========================================================
  // AXI WRITE RESPONSE PHASE
  //========================================================

  mif.wready = 0;
  mif.awready = 0;
  @(posedge mif.aclk);

  mif.bid    = 0;
  mif.bvalid = 1;
  mif.bresp  = 2'b00;

  `uvm_info("AXI_MEM",$sformatf("BVALID=%0b BID=%0d BRESP=%0b",
    mif.bvalid,
    mif.bid,
    mif.bresp),
    UVM_MEDIUM)


  // Wait for DUT to accept response
  wait (mif.bready == 1);

    `uvm_info("AXI_MEM","BREADY received - response accepted",UVM_MEDIUM)
  @(posedge mif.aclk);

  mif.bvalid = 0;
  mif.bid    = 0;
  mif.bresp  = 2'b00;
   end
endtask
  
  


  //========================================================
  // RUN PHASE
  //========================================================
  virtual task run_phase(uvm_phase phase);
       forever begin    
         seq_item_port.get_next_item(tr);
            if(tr.op == WR_TXN)
              write_tx();
            if(tr.op == RD_TXN)
             read_tx();
         if (tr.op == AXI_MEM) 
             axi_mem_read();
         seq_item_port.item_done();
       end
  endtask
endclass