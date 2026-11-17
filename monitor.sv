class axi_slave_monitor extends uvm_monitor;

  `uvm_component_utils(axi_slave_monitor)

  uvm_analysis_port #(transaction) ap;

  // Virtual Interface
  virtual axi_if vif;

  function new(string name="axi_slave_monitor",
               uvm_component parent=null);
    super.new(name,parent);
  endfunction

  //--------------------------------------------------
  // Build Phase
  //--------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_fatal("MON","Unable to get virtual interface")

    ap = new("ap",this);

  endfunction

  //--------------------------------------------------
  // Run Phase
  //--------------------------------------------------
  virtual task run_phase(uvm_phase phase);

    transaction wr_tr;
    transaction rd_tr;
    transaction rst_tr;

    forever begin

      @(posedge vif.aclk);

      //------------------------------------------------
      // RESET
      //------------------------------------------------
      if(vif.arst == 1) begin

        rst_tr = transaction::type_id::create("rst_tr");

        rst_tr.op = RST_DUT;

        rst_tr.bready  = vif.bready;
        rst_tr.awready = vif.awready;
        rst_tr.wready  = vif.wready;
        rst_tr.bvalid  = vif.bvalid;
        rst_tr.bid     = vif.bid;
        rst_tr.bresp   = vif.bresp;

        rst_tr.arready = vif.arready;

        rst_tr.rvalid  = vif.rvalid;
        rst_tr.rid     = vif.rid;
        rst_tr.rlast   = vif.rlast;
        rst_tr.rresp   = vif.rresp;
        rst_tr.rdata   = vif.rdata;

        `uvm_info("MON",
        $sformatf("[%0t ns]========== RESET DETECTED ==========\narst=%0b",
                  $time,vif.arst),
        UVM_MEDIUM)

        ap.write(rst_tr);

      end
      else begin

        //------------------------------------------------
        // WRITE TRANSACTION
        //------------------------------------------------

        if(wr_tr == null) begin
          wr_tr = transaction::type_id::create("wr_tr");
          wr_tr.op = WR_TXN;
        end

        //---------------- AW ----------------
        if(vif.awvalid && vif.awready) begin

          wr_tr.awaddr  = vif.awaddr;
          wr_tr.awid    = vif.awid;
          wr_tr.awlen   = vif.awlen;
          wr_tr.awsize  = vif.awsize;
          wr_tr.awburst = vif.awburst;

        end

        //---------------- W ----------------
        if(vif.wvalid && vif.wready) begin

          wr_tr.wdata = vif.wdata;
          wr_tr.wstrb = vif.wstrb;
          wr_tr.wlast = vif.wlast;

        end

        //---------------- B ----------------
        if(vif.bvalid && vif.bready) begin

          wr_tr.bid   = vif.bid;
          wr_tr.bresp = vif.bresp;
          
       if ( ((wr_tr.awaddr >= 32'h1000) && (wr_tr.awaddr <= 32'h101C)) ||
       (wr_tr.awaddr == 32'h2000) ||
       (wr_tr.awaddr == 32'h27FC) ||
       (wr_tr.awaddr == 32'h2800) ||
       (wr_tr.awaddr == 32'h2FFC) ||
       (wr_tr.awaddr == 32'h2004)  ) begin
          
          `uvm_info("MON",
          $sformatf("========== COMPLETE WRITE TRANSACTION ==========\nAWADDR = 0x%04h\nWDATA = %08h\nBRESP = %0d\n================================================",
                    wr_tr.awaddr,
                    wr_tr.wdata,
                    wr_tr.bresp),
          UVM_MEDIUM)
       end

          ap.write(wr_tr);

          wr_tr = null;

        end

        //------------------------------------------------
        // READ TRANSACTION
        //------------------------------------------------

        if(rd_tr == null) begin
          rd_tr = transaction::type_id::create("rd_tr");
          rd_tr.op = RD_TXN;
        end

        //---------------- AR ----------------
        if(vif.arvalid && vif.arready) begin

          rd_tr.araddr  = vif.araddr;
          rd_tr.arid    = vif.arid;
          rd_tr.arlen   = vif.arlen;
          rd_tr.arsize  = vif.arsize;
          rd_tr.arburst = vif.arburst;

        end

        //---------------- R ----------------
        if(vif.rvalid && vif.rready) begin

          rd_tr.rdata = vif.rdata;
          rd_tr.rid   = vif.rid;
          rd_tr.rresp = vif.rresp;
          rd_tr.rlast = vif.rlast;

    if (((rd_tr.araddr >= 32'h1000) && (rd_tr.araddr <= 32'h101C)) ||
    (rd_tr.araddr == 32'h2000) ||
    (rd_tr.araddr == 32'h27FC) ||
    (rd_tr.araddr == 32'h2800) ||
    (rd_tr.araddr == 32'h2FFC))
      begin
          `uvm_info("MON",
          $sformatf("========== COMPLETE READ TRANSACTION ==========\nARADDR = 0x%04h\nRDATA = %08h\nRID = %0d\nRRESP = %0d\nRLAST = %0d\n================================================",
                    rd_tr.araddr,
                    rd_tr.rdata,
                    rd_tr.rid,
                    rd_tr.rresp,
                    rd_tr.rlast),
          UVM_MEDIUM)
    end
          ap.write(rd_tr);

          rd_tr = null;

        end

      end

    end

  endtask

endclass