class mem_monitor extends uvm_monitor;

  `uvm_component_utils(mem_monitor)

  virtual memory_if mif;
  transaction tr;
  uvm_analysis_port #(transaction) mem_ap;
  uvm_analysis_port #(transaction) axi_mem_ap;
  uvm_analysis_port #(bit [31:0]) addr_ap;
  
  bit first_addr_captured;
  bit [31:0] first_awaddr;

  function new(string name = "mem_monitor",uvm_component parent = null);
    super.new(name, parent);
    mem_ap = new("mem_ap", this);
    axi_mem_ap = new("axi_mem_ap", this);
    addr_ap    = new("addr_ap", this);
  endfunction


  //========================================================
  // BUILD PHASE
  //========================================================
  virtual function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if (!uvm_config_db#(virtual memory_if)::get(this,"","mif",mif)) begin
    `uvm_fatal("MEM_MON","Memory AXI interface (mif) not found")
    end
  endfunction


  //========================================================
  // RUN PHASE
  //========================================================
  virtual task run_phase(uvm_phase phase);     
   fork
    begin
    forever begin

      
      @(posedge mif.tl_dll_clk);
       
      //----------------------------------------------------
      // Read Address Handshake
      //----------------------------------------------------
     if(mif.arvalid && mif.arready) 
        begin
        tr = transaction::type_id::create("tr");
        tr.arvalid = mif.arvalid;
        tr.arready = mif.arready;

        tr.araddr  = mif.araddr;
        tr.arlen   = mif.arlen;
        tr.arid    = mif.arid;
        tr.arburst = mif.arburst;
        tr.arsize  = mif.arsize;         
        `uvm_info("MEM_MON",$sformatf(
            "\n========== MEMORY READ ADDRESS ==========\nARADDR=0x%08h\nARLEN=%0d\nARID=%0d\nARBURST=%0b\nARSIZE= %0d\nARVALID=%0b\nARREADY=%0b\n=========================================",
            tr.araddr,
            tr.arlen,
            tr.arid,
            tr.arburst,
            tr.arsize,
            tr.arvalid,
            tr.arready),UVM_MEDIUM); 
            mem_ap.write(tr);

      end
   end
    end
//======================================New=================================================//
      
 begin
    forever begin  
      @(mif.mon_cb); //   @(posedge mif.aclk);  
       
//----------------------------------------------------
// AXI WRITE ADDRESS Handshake
//----------------------------------------------------
      if (mif.mon_cb.awvalid && mif.mon_cb.awready) //if (mif.awvalid && mif.awready)
begin    
    tr = transaction::type_id::create("aw_tr");   
    tr.awaddr  = mif.mon_cb.awaddr;  // mif.awaddr;
    tr.awlen   = mif.mon_cb.awlen;   //mif.awlen;
    tr.awsize  = mif.mon_cb.awsize;  //mif.awsize;
    tr.awburst = mif.mon_cb.awburst; //mif.awburst;
    tr.awid    = mif.mon_cb.awid;    //mif.awid;

    `uvm_info("AXI_MON",$sformatf("AWTRANSACTION:\nAWADDR=%08h\nAWLEN=%0d\nAWSIZE=%0d\nAWBURST=%0b\nAWID=%0d",
                tr.awaddr,
                tr.awlen,
                tr.awsize,
                tr.awburst,
                tr.awid),
      UVM_MEDIUM)
  
  if (!first_addr_captured)
    begin
        first_awaddr = mif.mon_cb.awaddr;
        first_addr_captured = 1;
      addr_ap.write(first_awaddr); 
      $display("Address = %08h",first_awaddr);
    end
end
    
      
//----------------------------------------------------
// AXI WRITE DATA Handshake
//----------------------------------------------------
      if (mif.mon_cb.wvalid && mif.mon_cb.wready) //if (mif.wvalid && mif.wready)
begin
    tr = transaction::type_id::create("w_tr");

    tr.wdata = mif.mon_cb.wdata; // mif.wdata;
    tr.wid   = mif.mon_cb.wid;   //mif.wid;
    tr.wlast = mif.mon_cb.wlast; //mif.wlast;
  
     axi_mem_ap.write(tr);   

    `uvm_info("AXI_MON",$sformatf("Time : %0t W: DATA=%08h ID=%0d LAST=%0b",$time,
                tr.wdata,
                tr.wid,
                tr.wlast),
      UVM_MEDIUM)
  
  
  
    end
 end  
 end
join
  endtask
endclass