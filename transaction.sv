typedef enum bit [2:0] {
  WR_TXN,
  RD_TXN,
  RST_DUT,
  AXI_MEM
} oper_mode;

class transaction extends uvm_sequence_item;

  `uvm_object_utils(transaction)

  function new(string name = "transaction");
    super.new(name);
  endfunction

  oper_mode op;

  //-----------------------------
  // Write Address Channel (AW)
  //-----------------------------
  bit        awvalid;
  bit        awready;
  bit [3:0]  awid;
  bit [3:0]  awlen;
  bit [2:0]  awsize;
  bit [31:0] awaddr;
  bit [1:0]  awburst;

  //-----------------------------
  // Write Data Channel (W)
  //-----------------------------
  bit        wvalid;
  bit        wready;
  bit [3:0]  wid;
 // bit [31:0] wdata[$];   // Entire burst
  bit [31:0] wdata;
  bit [3:0]  wstrb;
  bit        wlast;

  //-----------------------------
  // Write Response Channel (B)
  //-----------------------------
  bit        bvalid;
  bit        bready;
  bit [3:0]  bid;
  bit [1:0]  bresp;

  //-----------------------------
  // Read Address Channel (AR)
  //-----------------------------
  bit        arvalid;
  bit        arready;
  bit [3:0]  arid;
  bit [3:0]  arlen;
  bit [2:0]  arsize;
  bit [31:0] araddr;
  bit [1:0]  arburst;

  //-----------------------------
  // Read Data Channel (R)
  //-----------------------------
  bit        rvalid;
  bit        rready;
  bit [3:0]  rid;
 // bit [31:0] rdata[$];   // Entire read burst
  bit [31:0] rdata;
  bit        rlast;
  bit [1:0]  rresp;
  
  int unsigned dma_length;
  int unsigned num_bursts;
  
endclass