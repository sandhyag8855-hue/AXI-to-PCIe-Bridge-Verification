class axi_base_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_base_seq)
  `NEW_OBJ

  // Raise objection before sequence starts
  task pre_body();
    uvm_phase phase = get_starting_phase();

    if (phase != null) begin
      phase.phase_done.set_drain_time(this, 100);
      phase.raise_objection(this);
    end
  endtask

  // Drop objection after sequence completes
  task post_body();
    uvm_phase phase = get_starting_phase();

    if (phase != null) begin
      phase.drop_objection(this);
    end
  endtask

endclass


class axi_rst_dut extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_rst_dut)

  transaction tr;

  function new(string name = "axi_rst_dut");
    super.new(name);
  endfunction

  virtual task body();

    tr = transaction::type_id::create("tr");
    `uvm_info("RST_SEQ", "Sending Reset Transaction", UVM_LOW)

    start_item(tr);
    tr.op = RST_DUT;
    finish_item(tr);

  endtask

endclass

class axi_multiple_wr_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_multiple_wr_seq)

  transaction tr;

  function new(string name = "axi_multiple_wr_seq");
    super.new(name);
  endfunction

    bit [31:0] addr;
    bit [31:0] data;
  
    //--------------------------------
    // 8 WRITE TRANSACTIONS
    //--------------------------------
    virtual task body();
       addr = 32'h1000;
    
       repeat(8) begin
        tr = transaction::type_id::create("tr");

        start_item(tr);
        
        tr.awid    = 0;
        tr.awlen   = 0;
        tr.awsize  = 3'b010;
        tr.awburst = 2'b01;
        tr.op      = WR_TXN;
        tr.awaddr  = addr;
        tr.wdata   = get_data(addr);

        finish_item(tr);
        addr += 4;
    end    
endtask
    
     function bit [31:0] get_data(bit [31:0] addr);

    case(addr)
        32'h1000: get_data = 32'h00000000;
        32'h1004: get_data = 32'h00000001;
        32'h1008: get_data = 32'h00000000;
        32'h100C: get_data = 32'hec000000;
        32'h1010: get_data = 32'h00000000;
        32'h1014: get_data = 32'h00000000;
        32'h1018: get_data = 32'h00000000;
        32'h101C: get_data = 32'hFFFFFFFF;

        default: get_data = 32'h0;
    endcase
endfunction
endclass

class axi_multiple_rd_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_multiple_rd_seq)
  transaction tr;

  function new(string name = "axi_multiple_rd_seq");
    super.new(name);
  endfunction

  bit [31:0] addr;

  //--------------------------------
  // 8 READ TRANSACTIONS
  //--------------------------------
  virtual task body();
    addr = 32'h1000;

    repeat (8) begin
      tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.arid    = 0;
      tr.arlen   = 0;
      tr.arsize  = 3'b010;
      tr.arburst = 2'b01;
      tr.op      = RD_TXN;
      tr.araddr  = addr;
      finish_item(tr);
      addr += 4;
    end
  endtask
endclass


class axi_rx_desc_wr_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_rx_desc_wr_seq)

  transaction tr;
  int unsigned rx_length;

  function new(string name = "axi_rx_desc_wr_seq");
    super.new(name);
  endfunction

  virtual task body();

    tr = transaction::type_id::create("tr");
    
    //====================================================
    // 1. Configure MAX_PAYLOAD_SIZE
    //    Register : 0x1018
    //
    //    Value is in BYTES
    //====================================================

   /* tr = transaction::type_id::create("tr");
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h1018;   
    //tr.wdata = 32'h0000_0040;  // 64   BYTES
    //tr.wdata = 32'h0000_0080;  // 128  BYTES
    //tr.wdata = 32'h0000_0100;  // 256  BYTES
    tr.wdata = 32'h0000_0200;  // 512  BYTES
    //tr.wdata = 32'h0000_0400;  // 1024 BYTES
    //tr.wdata = 32'h0000_0800;  // 2048 BYTES
    //tr.wdata = 32'h0000_1000;  // 4096 BYTES

    finish_item(tr);
    */
    
    //====================================================
    // 2. RX DESCRIPTOR LENGTH
    //    Register : 0x2800
    //
    //    [31:16] = Length in DWORDS
    //
    //    1 DWORD = 4 BYTES
    //====================================================
   
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h2800;
    tr.wdata   = 32'h0010_0000; //// RX descriptor LENGTH: 16 DW = 64 bytes
    //tr.wdata = 32'h0020_0000; // 128 BYTES = 32 DW 
    //tr.wdata = 32'h0040_0000; // 256 BYTES = 64 DW 
    //tr.wdata = 32'h0080_0000; // 512 BYTES = 128 DW 
    //tr.wdata = 32'h0100_0000; // 1024 BYTES = 256 DW 
    //tr.wdata = 32'h0200_0000; // 2048 BYTES = 512 DW 
    //tr.wdata = 32'h0400_0000; // 4096 BYTES = 1024 DW
    rx_length = tr.wdata[31:16];
    finish_item(tr);

    //====================================================
    // 3. RX DESCRIPTOR ADDRESS
    //    Register : 0x2804
    //
    //    Target memory address
    //====================================================

    tr = transaction::type_id::create("tr");
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h2804;    
    tr.wdata = 32'hEC00_0000;// RX descriptor ADDRESS: Memory Read target address

    finish_item(tr);

  endtask
endclass


class axi_dma_config_read_write extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_dma_config_read_write)

  transaction tr;

  function new(string name = "axi_dma_config_read_write");
    super.new(name);
  endfunction

  virtual task body();

    //--------------------------------
    // Write 0x00000000 to 0x101C
    //--------------------------------
    tr = transaction::type_id::create("tr");

    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h101C;
    tr.wdata   = 32'h00000000;

    finish_item(tr);

  endtask

endclass



class axi_dma_mem_wr_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_dma_mem_wr_seq)

  transaction tr;
  int unsigned dma_length;

  function new(string name = "axi_dma_mem_wr_seq");
    super.new(name);
  endfunction


  virtual task body();
    dma_length = 64;       // 64 bytes
   // dma_length = 128;       // 128 bytes
   // dma_length = 256;      // 256 bytes
   // dma_length = 512;      // 512 bytes
   //dma_length = 1024;        // 1024 bytes
   // dma_length = 2048;     // 2048 bytes
   // dma_length = 4096;     // 4096 bytes

    tr = transaction::type_id::create("tr");
    //--------------------------------
    // 1. TLP TRANSFER CONFIG = MEM_WR
    // Address 0x1014
    //--------------------------------
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h1014;
    tr.wdata   = 32'h00000001;   // MEM_WR

    finish_item(tr);


    //--------------------------------
    // 2. TX DESCRIPTOR DW0
    // Address 0x2000
    //
    // [31:16] = length
    // 64 bytes = 16'h0040
    //
    // DW0 = 32'h0040_0000
    //--------------------------------
    tr = transaction::type_id::create("tr");
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h2000;
    tr.wdata = 32'h0040_0000;   // 64 bytes
    // tr.wdata = 32'h0080_0000;   // 128 bytes
    // tr.wdata = 32'h0100_0000;   // 256 bytes
    // tr.wdata = 32'h0200_0000;   // 512 bytes
    // tr.wdata = 32'h0400_0000;       // 1024 bytes
    // tr.wdata = 32'h0800_0000;   // 2048 bytes
    // tr.wdata = 32'h1000_0000;   // 4096 bytes
    finish_item(tr);


    //--------------------------------
    // 3. TX DESCRIPTOR DW1
    // Address 0x2004
    //
    // Source AXI memory address
    //--------------------------------
    tr = transaction::type_id::create("tr");
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h2004;
    tr.wdata   = 32'hEC00_0000;

    finish_item(tr);
    
    
    // MAX PAYLOAD = 256 bytes
    tr = transaction::type_id::create("tr");
    start_item(tr);
    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h1018;
    tr.wdata = 32'h00000040;       // 64 bytes
    //tr.wdata = 32'h0080_0000;   // 128 bytes
    //tr.wdata = 32'h00000100;     // 256 bytes
    // tr.wdata = 32'h00000200;     // 512 bytes
    // tr.wdata = 32'h00000400;     // 1024 bytes
    // tr.wdata = 32'h00000800;     // 2048 bytes
   // tr.wdata = 32'h00001000;     // 4096 bytes
    finish_item(tr);
    
     //--------------------------------
    // 4. DMA CONFIGURE = 1
    // Address 0x1010
    //--------------------------------
    tr = transaction::type_id::create("tr");
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h1010;
    tr.wdata   = 32'h00000001;

    finish_item(tr);
 
  endtask
endclass

class axi_dma_mem_rd_seq extends uvm_sequence #(transaction);

  `uvm_object_utils(axi_dma_mem_rd_seq)

  transaction tr;

  function new(string name = "axi_dma_mem_rd_seq");
    super.new(name);
  endfunction

  virtual task body();

    //--------------------------------
    // 1. DMA CONFIGURE = 1
    //--------------------------------
    tr = transaction::type_id::create("tr");

    // 1. TLP TRANSFER CONFIG = MEM_RD
     start_item(tr);

     tr.awid    = 0;
     tr.awlen   = 0;
     tr.awsize  = 3'b010;
     tr.awburst = 2'b01;
     tr.op      = WR_TXN;
     tr.awaddr  = 32'h1014;
     tr.wdata   = 32'h00000002;

     finish_item(tr);


    // 2. DMA CONFIGURE = 1
    start_item(tr);

    tr.awid    = 0;
    tr.awlen   = 0;
    tr.awsize  = 3'b010;
    tr.awburst = 2'b01;
    tr.op      = WR_TXN;
    tr.awaddr  = 32'h1010;
    tr.wdata   = 32'h00000001;

    finish_item(tr);

  endtask
endclass

