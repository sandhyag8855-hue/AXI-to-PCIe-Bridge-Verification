class axi_slave_driver extends uvm_driver #(transaction);

  `uvm_component_utils(axi_slave_driver)

  // Virtual Interface
  virtual axi_if vif;
  transaction tr;
  bit [31:0] base_addr = 32'h1000;
  //-------------------------
  // Constructor
  //-------------------------
  function new(string name = "axi_slave_driver",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //-------------------------
  // Build Phase
  //-------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
      `uvm_fatal("DRV","Unable to get virtual interface");
     tr = transaction::type_id::create("tr");

  endfunction

  //-------------------------
  // Run Phase
  //-------------------------
 //================WRITE TASK=============================//
  task write_tx();

  //--------------------------------
  // WRITE ADDRESS CHANNEL (AW)
  //--------------------------------

  vif.awid    <= tr.awid;
  vif.awlen   <= tr.awlen;
  vif.awsize  <= tr.awsize;
  vif.awburst <= tr.awburst;
  vif.awaddr  <= tr.awaddr;

  vif.awvalid <= 1'b1;

  wait(vif.awready == 1'b1);
  @(posedge vif.aclk);

  vif.awvalid <= 1'b0;

  //--------------------------------
  // WRITE DATA CHANNEL (W)
  //--------------------------------

  vif.wdata  <= tr.wdata;
  vif.wvalid <= 1'b1;
  vif.wlast  <= 1'b1;

  wait(vif.wready == 1'b1);
  @(posedge vif.aclk);

  vif.wvalid <= 1'b0;
  vif.wlast  <= 1'b0;

  //--------------------------------
  // WRITE RESPONSE CHANNEL (B)
  //--------------------------------

  vif.bready <= 1'b1;

  wait(vif.bvalid == 1'b1);
  @(posedge vif.aclk);

  vif.bready <= 1'b0;
   /* if (((tr.awaddr >= 32'h1000) && (tr.awaddr <= 32'h101C)) ||
    (tr.awaddr == 32'h2000) ||
    (tr.awaddr == 32'h27FC) ||
    (tr.awaddr == 32'h2800) ||
    (tr.awaddr == 32'h2FFC))
    begin*/
    
    if (((tr.awaddr >= 32'h1000) && (tr.awaddr <= 32'h101C)) ||
    (tr.awaddr == 32'h2000) ||
    (tr.awaddr == 32'h2004) ||
    (tr.awaddr == 32'h27FC) ||
    (tr.awaddr == 32'h2800) ||
    (tr.awaddr == 32'h2FFC))
begin
    
  $display("Write transaction started :: DRIVER");
  `uvm_info("DRV",
    $sformatf("========== WRITE TRANSACTION ==========\nAWADDR=0x%04h\nWDATA=%08h\nBRESP=%0d\n======================================",
              tr.awaddr,
              tr.wdata,
              vif.bresp),
    UVM_MEDIUM)
    end
endtask
  
  
//================READ TASK=============================//
  
 task read_tx();

  //--------------------------------
  // READ ADDRESS CHANNEL (AR)
  //--------------------------------

  vif.arid    <= tr.arid;
  vif.arlen   <= tr.arlen;
  vif.arsize  <= tr.arsize;
  vif.arburst <= tr.arburst;
  vif.araddr  <= tr.araddr;

  vif.arvalid <= 1'b1;

  wait(vif.arready == 1'b1);
  @(posedge vif.aclk);

  vif.arvalid <= 1'b0;

  //--------------------------------
  // READ DATA CHANNEL (R)
  //--------------------------------

  vif.rready <= 1'b1;

  wait(vif.rvalid == 1'b1);
  @(posedge vif.aclk);

   if (((tr.araddr >= 32'h1000) && (tr.araddr <= 32'h101C)) ||
    (tr.araddr == 32'h2000) ||
    (tr.araddr == 32'h27FC) ||
    (tr.araddr == 32'h2800) ||
    (tr.araddr == 32'h2FFC)) begin

    $display("Read transaction started :: DRIVER");
  `uvm_info("DRV",
    $sformatf("========== READ TRANSACTION ==========\nARADDR = 0x%04h\nRDATA  = %08h\nRID    = %0d\nRRESP  = %0d\nRLAST  = %0d\n======================================",
              tr.araddr,
              vif.rdata,
              vif.rid,
              vif.rresp,
              vif.rlast),
    UVM_MEDIUM)
   end

  vif.rready <= 1'b0;

endtask
  

 //================RESET TASK=============================// 
  task reset_dut(); 
    begin
    `uvm_info("DRV", "System Reset : Start of Simulation", UVM_MEDIUM);
      end
  endtask 
  

  virtual task run_phase(uvm_phase phase);
       forever begin
         seq_item_port.get_next_item(tr);
            if(tr.op == RST_DUT)
             reset_dut();
         else if(tr.op == WR_TXN)
             write_tx();
         else if(tr.op == RD_TXN)
             read_tx();
         seq_item_port.item_done();
       end
  endtask

endclass