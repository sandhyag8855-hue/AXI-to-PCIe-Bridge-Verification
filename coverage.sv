`uvm_analysis_imp_decl(_cfg)
`uvm_analysis_imp_decl(_mem)

class ep_coverage extends uvm_subscriber #(dll_packet);

  `uvm_component_utils(ep_coverage)
  
  uvm_analysis_imp #(dll_packet, ep_coverage) ep_imp;


  //========================================================
  // Variable to store LINKUP value
  //========================================================
  bit linkup;
  bit [7:0] dll_vc_up;
  bit [31:0] header0;
  bit [31:0] header1;
  bit [31:0] header2;
  int cfg_rd_count = 0;
  int tlp_length;
  bit [7:0] tlp_fmt_type ;
  
  //============================================================
  // PROTOCOL ORDERING
  //============================================================
  
  int protocol_order;
  bit linkup_seen;
  bit vc_up_seen;
  bit cfg_rd_seen;
  bit cfg_wr_seen;
  bit mem_wr_seen;

  //========================================================
  // Constructor
  //========================================================
  function new(string name = "ep_coverage",uvm_component parent = null);
    super.new(name, parent);
    
    ep_imp  = new("ep_imp", this);
  //  cfg_imp = new("cfg_imp", this);
  //  mem_imp = new("mem_imp", this);
    

    // Create covergroup
    linkup_cg = new();
    dll_vc_up_cg = new();
    mem_wr_tlp_cg = new();
    mem_rd_tlp_cg = new();
    cfg_tlp_cg = new();
    cfg_rd_count_cg = new();
    tlp_type_cg = new();
    payload_size_cg = new();
    memory_address_cg = new();
    protocol_order_cg = new();
  endfunction


  //========================================================
  // LINK-UP COVERAGE
  //========================================================
  covergroup linkup_cg;
  cp_linkup: coverpoint linkup {bins bit0_one = {1'b1};}
  endgroup
  
  covergroup dll_vc_up_cg;
  cp_vc_bit0: coverpoint  dll_vc_up[0] {bins bit0_one = {1};}
  cp_vc_bit1: coverpoint  dll_vc_up[1] {bins bit1_one = {1};}
  cp_vc_bit2: coverpoint  dll_vc_up[2] {bins bit2_one = {1};}
  cp_vc_bit3: coverpoint  dll_vc_up[3] {bins bit3_one = {1};}
  cp_vc_bit4: coverpoint  dll_vc_up[4] {bins bit4_one = {1};}
  cp_vc_bit5: coverpoint  dll_vc_up[5] {bins bit5_one = {1};}
  cp_vc_bit6: coverpoint  dll_vc_up[6] {bins bit6_one = {1};}
  cp_vc_bit7: coverpoint  dll_vc_up[7] {bins bit7_one = {1};}
endgroup
  

  covergroup tlp_type_cg;
   cp_tlp_type : coverpoint {header0[31:29], header0[28:24]} {

    bins CFG_RD = {8'b00000100};
    bins CFG_WR = {8'b01000100};
    bins MEM_RD = {8'b00000000};
    bins MEM_WR = {8'b01000000};

  }
endgroup
  
 //============================================================
 // PAYLOAD SIZE COVERAGE
 //============================================================
covergroup payload_size_cg;

  cp_payload_size : coverpoint header0[9:0] {

    bins valid_payload_size = {
      10'd16,
      10'd32,
      10'd64,
      10'd128,
      10'd256,
      10'd512,
      10'd0
    };

  }
endgroup
  
  /*covergroup memory_address_cg;
  cp_memory_address : coverpoint header2 {

    bins valid_memory_address = {
      32'hEC00_0000
    };

  }
endgroup*/
  
  
  covergroup memory_address_cg;

  cp_memory_address : coverpoint header2 {

    // Valid 4-KB memory address range
    bins valid_memory_address = {
      [32'hEC00_0000 : 32'hEC00_0FFF]
    };

    // Any address outside the valid 4-KB range
    illegal_bins invalid_memory_address = {
      [32'h0000_0000 : 32'hEBFF_FFFF],
      [32'hEC00_1000 : 32'hFFFF_FFFF]
    };

  }

endgroup
  
  
   //============================================================
  // PROTOCOL ORDERING COVERAGE
  //==============================================================
  
  covergroup protocol_order_cg;

   cp_protocol_order : coverpoint protocol_order {

    bins LINK_UP_TO_VC_UP =
      {1};

    bins VC_UP_TO_CFG_RD =
      {2};

    bins CFG_RD_TO_CFG_WR =
      {3};

    bins CFG_WR_TO_MEM_WR =
      {4};

    bins MEM_WR_TO_MEM_RD =
      {5};

  }
endgroup
  
 
  covergroup mem_wr_tlp_cg;

  //============================================================
  // HEADER 0 : header[0]
  //============================================================

  // FMT [31:29]
  cp_fmt : coverpoint header0[31:29] {

    bins mem_wr_fmt = {3'b010};

  }

  // TYPE [28:24]
  cp_type : coverpoint header0[28:24] {

    bins mem_wr_type = {5'b00000};

  }

  // TAG[9] -> Header[0][23]
  // tag = 10'h123 = 01_0010_0011
  // TAG[9] = 0
  cp_tag9 : coverpoint header0[23] {

    bins tag9_zero = {1'b0};

  }

  // TC [22:20]
  cp_tc : coverpoint header0[22:20] {

    bins tc_zero = {3'b000};

  }

  // TAG[8] -> Header[0][19]
  // TAG[8] = 1
  cp_tag8 : coverpoint header0[19] {

    bins tag8_one = {1'b1};

  }

  // Attr[2] [18]
  cp_attr2 : coverpoint header0[18] {

    bins attr2_zero = {1'b0};

  }

  // LN [17]
  cp_ln : coverpoint header0[17] {

    bins ln_zero = {1'b0};

  }

  // TH [16]
  cp_th : coverpoint header0[16] {

    bins th_zero = {1'b0};

  }

  // TD [15]
  cp_td : coverpoint header0[15] {

    bins td_zero = {1'b0};

  }

  // EP [14]
  cp_ep : coverpoint header0[14] {

    bins ep_zero = {1'b0};

  }

  // Attr[1:0] [13:12]
  cp_attr10 : coverpoint header0[13:12] {

    bins attr_zero = {2'b00};

  }

  // AT [11:10]
  cp_at : coverpoint header0[11:10] {

    bins at_zero = {2'b00};

  }

  // TLP Length [9:0]
  cp_length : coverpoint header0[9:0] {

  bins valid_length = {
    10'd16,
    10'd32,
    10'd64,
    10'd128,
    10'd256,
    10'd512,
    10'd0
  };

  }


  //============================================================
  // HEADER 1 : header[1]
  //============================================================

  // Requester Bus Number
  // Header[1][31:24]
  // HEADER1 = 000023FF
  cp_requester_bus : coverpoint header1[31:24] {

    bins requester_bus = {8'h00};

  }

  // Requester Device Number
  // Header[1][23:19]
  cp_requester_device : coverpoint header1[23:19] {

    bins requester_device = {5'h00};

  }

  // Requester Function Number
  // Header[1][18:16]
  cp_requester_function : coverpoint header1[18:16] {

    bins requester_function = {3'h0};

  }

  // TAG[7:0] -> Header[1][15:8]
  // tag = 10'h123
  // TAG[7:0] = 8'h23
  cp_tag_low : coverpoint header1[15:8] {

    bins tag_low = {8'h23};

  }

  // First DW Byte Enable [7:4]
  cp_first_dw_be : coverpoint header1[7:4] {

    bins first_dw_be = {4'hF};

  }

  // Last DW Byte Enable [3:0]
  cp_last_dw_be : coverpoint header1[3:0] {

    bins last_dw_be = {4'hF};

  }


  //============================================================
  // HEADER 2 : header[2]
  //============================================================

  // Memory Address [31:0]
  cp_memory_address : coverpoint header2 {

    bins memory_address = {32'hEC00_0000};

  }

endgroup
  
 
 
  covergroup mem_rd_tlp_cg;

  //============================================================
  // HEADER 0 : header[0]
  //============================================================

  // FMT [31:29]
  cp_fmt : coverpoint header0[31:29] {
    bins mem_rd_fmt = {3'b000};
  }

  // TYPE [28:24]
  cp_type : coverpoint header0[28:24] {
    bins mem_rd_type = {5'b00000};
  }

  // TAG[9] -> Header[0][23]
  // tag = 10'h123 = 01_0010_0011
  // TAG[9] = 0
  cp_tag9 : coverpoint header0[23] {
    bins tag9_zero = {1'b0};
  }

  // TC [22:20]
  cp_tc : coverpoint header0[22:20] {
    bins tc_zero = {3'b000};
  }

  // TAG[8] -> Header[0][19]
  // TAG[8] = 1
  cp_tag8 : coverpoint header0[19] {
    bins tag8_one = {1'b1};
  }

  // Attr[2] [18]
  cp_attr2 : coverpoint header0[18] {
    bins attr2_zero = {1'b0};
  }

  // LN [17]
  cp_ln : coverpoint header0[17] {
    bins ln_zero = {1'b0};
  }

  // TH [16]
  cp_th : coverpoint header0[16] {
    bins th_zero = {1'b0};
  }

  // TD [15]
  cp_td : coverpoint header0[15] {
    bins td_zero = {1'b0};
  }

  // EP [14]
  cp_ep : coverpoint header0[14] {
    bins ep_zero = {1'b0};
  }

  // Attr[1:0] [13:12]
  cp_attr10 : coverpoint header0[13:12] {
    bins attr_zero = {2'b00};
  }

  // AT [11:10]
  cp_at : coverpoint header0[11:10] {
    bins at_zero = {2'b00};
  }

  // TLP Length [9:0]
  // 0 represents 1024 DW
cp_length : coverpoint header0[9:0] {
  bins valid_length = {
    10'd16,
    10'd32,
    10'd64,
    10'd128,
    10'd256,
    10'd512,
    10'd0
  };
}


  //============================================================
  // HEADER 1 : header[1]
  //============================================================

  // Requester Bus Number [31:24]
  cp_requester_bus : coverpoint header1[31:24] {
    bins requester_bus = {8'h00};
  }

  // Requester Device Number [23:19]
  cp_requester_device : coverpoint header1[23:19] {
    bins requester_device = {5'h00};
  }

  // Requester Function Number [18:16]
  cp_requester_function : coverpoint header1[18:16] {
    bins requester_function = {3'h0};
  }

  // TAG[7:0] -> Header[1][15:8]
  cp_tag_low : coverpoint header1[15:8] {
    bins tag_low = {8'h23};
  }

  // First DW Byte Enable [7:4]
  cp_first_dw_be : coverpoint header1[7:4] {
    bins first_dw_be = {4'hF};
  }

  // Last DW Byte Enable [3:0]
  cp_last_dw_be : coverpoint header1[3:0] {
    bins last_dw_be = {4'hF};
  }


  //============================================================
  // HEADER 2 : header[2]
  //============================================================

  // Memory Address [31:0]
  cp_memory_address : coverpoint header2 {
    bins memory_address = {32'hEC00_0000};
  }

endgroup
  
  
  covergroup cfg_tlp_cg;

  //============================================================
  // HEADER 0 : header[0]
  //============================================================

  // FMT [31:29]
  // CFG_RD0 -> 000
  // CFG_WR0 -> 010
  cp_fmt : coverpoint header0[31:29] {
    bins cfg_rd_fmt = {3'b000};
    bins cfg_wr_fmt = {3'b010};
  }

  // TYPE [28:24]
  // CFG Type 0 only
  // CFG_RD0 / CFG_WR0 -> 00100
  cp_type : coverpoint header0[28:24] {
    bins cfg_type0 = {5'b00100};
  }

  // TAG[9] -> Header[0][23]
  // tag = 10'h123 = 01_0010_0011
  // TAG[9] = 0
  cp_tag9 : coverpoint header0[23] {
    bins tag9_zero = {1'b0};
  }

  // Traffic Class [22:20]
  cp_tc : coverpoint header0[22:20] {
    bins tc_zero = {3'b000};
  }

  // TAG[8] -> Header[0][19]
  // TAG[8] = 1
  cp_tag8 : coverpoint header0[19] {
    bins tag8_one = {1'b1};
  }

  // Attr[2] [18]
  cp_attr2 : coverpoint header0[18] {
    bins attr2_zero = {1'b0};
  }

  // LN [17]
  cp_ln : coverpoint header0[17] {
    bins ln_zero = {1'b0};
  }

  // TH [16]
  cp_th : coverpoint header0[16] {
    bins th_zero = {1'b0};
  }

  // TD [15]
  cp_td : coverpoint header0[15] {
    bins td_zero = {1'b0};
  }

  // EP [14]
  cp_ep : coverpoint header0[14] {
    bins ep_zero = {1'b0};
  }

  // Attr[1:0] [13:12]
  cp_attr10 : coverpoint header0[13:12] {
    bins attr_zero = {2'b00};
  }

  // AT [11:10]
  cp_at : coverpoint header0[11:10] {
    bins at_zero = {2'b00};
  }

  // Packet Length [9:0]
  // CFG_RD0 -> 0
  // CFG_WR0 -> 1
  cp_length : coverpoint header0[9:0] {
    bins cfg_rd_length = {10'd0};
    bins cfg_wr_length = {10'd1};
  }


  //============================================================
  // HEADER 1 : header[1]
  //============================================================

  // Requester Bus Number [31:24]
  cp_requester_bus : coverpoint header1[31:24] {
    bins requester_bus = {8'h00};
  }

  // Requester Device Number [23:19]
  cp_requester_device : coverpoint header1[23:19] {
    bins requester_device = {5'h00};
  }

  // Requester Function Number [18:16]
  cp_requester_function : coverpoint header1[18:16] {
    bins requester_function = {3'h0};
  }

  // TAG[7:0] [15:8]
  // tag = 10'h123 -> 8'h23
  cp_tag_low : coverpoint header1[15:8] {
    bins tag_low = {8'h23};
  }

  // First DW Byte Enable [7:4]
  // CFG TLP uses 0000 in your DUT
  cp_first_dw_be : coverpoint header1[7:4] {
    bins first_dw_be = {4'h0};
  }

  // Last DW Byte Enable [3:0]
  cp_last_dw_be : coverpoint header1[3:0] {
    bins last_dw_be = {4'hF};
  }


  //============================================================
  // HEADER 2 : header[2]
  //============================================================

  // Target Bus Number [31:24]
  cp_target_bus : coverpoint header2[31:24] {
    bins target_bus = {8'h01};
  }

  // Target Device Number [23:19]
  cp_target_device : coverpoint header2[23:19] {
    bins target_device = {5'h01};
  }

  // Target Function Number [18:16]
  cp_target_function : coverpoint header2[18:16] {
    bins target_function = {3'h0};
  }

  // Reserved [15:12]
  cp_reserved_15_12 : coverpoint header2[15:12] {
    bins reserved_zero = {4'b0000};
  }

  // Extended Register Number [11:8]
  cp_ext_reg_num : coverpoint header2[11:8] {
    bins ext_reg_num = {4'h0};
  }

  // Register Number [7:2]
  cp_reg_num : coverpoint header2[7:2] {
    bins reg_num = {6'h00};
  }

  // Reserved [1:0]
  cp_reserved_1_0 : coverpoint header2[1:0] {
    bins reserved_zero = {2'b00};
  }

endgroup
  
  covergroup cfg_rd_count_cg;

  // CFG_RD must occur exactly 16 times
  cp_cfg_rd_count : coverpoint cfg_rd_count {

    bins exactly_16 = {16};

  }

endgroup
  
  
  
   //========================================================
   // Receive transaction from EP monitor
   //========================================================
 /* virtual function void write(dll_packet t);
    
    //========================================================
    // LINKUP COVERAGE
    //========================================================
    linkup = t.linkup;
    linkup_cg.sample(); 
    
   if (linkup == 1'b1) begin
    // Protocol ordering
    linkup_seen = 1'b1;
end
    
    //========================================================
    // DLL_VC_UP COVERAGE
    //========================================================
    dll_vc_up = t.dll_vc_up;
    dll_vc_up_cg.sample();
    
    
    if (t.dll_vc_up[7] == 1'b1) begin

    // Existing DLL VC UP coverage remains here
    //========================================================
    // PROTOCOL ORDER: LINK_UP -> DLL_VC_UP
    //========================================================
    if (linkup_seen && !vc_up_seen) begin
        protocol_order = 1;
        protocol_order_cg.sample();
        vc_up_seen = 1'b1;
      
    end
end      
endfunction*/
  
/*  virtual function void write_cfg(dll_packet t);

   
   header0 = t.header0;
   header1 = t.header1;
   header2 = t.header2;
   if (header0[31:24] == 8'h04) begin
   cfg_rd_count++;
   end
    
    //=========================================================
    // TLP TYPE COVERAGE
    //=========================================================
    tlp_fmt_type = {header0[31:29], header0[28:24]};
    tlp_type_cg.sample();
    cfg_rd_count_cg.sample();
    cfg_tlp_cg.sample();
    
   //==========================================================
   // PROTOCOL ORDER: DLL VC UP -> CFG_RD
   //==========================================================
    if (vc_up_seen && !cfg_rd_seen) begin
    protocol_order = 2;
    protocol_order_cg.sample();
    cfg_rd_seen = 1'b1;   
   end 
    
    if (header0[31:24] == 8'h44) begin
    //======================================================
    // PROTOCOL ORDER: CFG_RD -> CFG_WR
    //======================================================
    if (cfg_rd_seen && !cfg_wr_seen) begin

        protocol_order = 3;
        protocol_order_cg.sample();
        cfg_wr_seen = 1'b1;
    end
end    
endfunction
   
  virtual function void write_mem(dll_packet t);

   header0 = t.header0;
   header1 = t.header1;
   header2 = t.header2;
   // Length field = Header DW0 [9:0]
   tlp_length = header0[9:0];
    
   if (tlp_length == 0)
    tlp_length = 1024;
     mem_wr_tlp_cg.sample();
     mem_rd_tlp_cg.sample();
     payload_size_cg.sample();
    
   //=========================================================
   // TLP TYPE COVERAGE
   // FMT [31:29] + TYPE [28:24]
   //=========================================================
   tlp_fmt_type = {header0[31:29], header0[28:24]};
   tlp_type_cg.sample();
   memory_address_cg.sample();
    
    
  if (header0[31:24] == 8'b01000000)  begin
    //======================================================
    // PROTOCOL ORDER: CFG_WR -> MEM_WR
    //======================================================
    if (cfg_wr_seen && !mem_wr_seen) begin
        protocol_order = 4;
        protocol_order_cg.sample();
        mem_wr_seen = 1'b1;       
    end
end   
    
    
    if (header0[31:24] == 8'b00000000) begin
    //======================================================
    // PROTOCOL ORDER: MEM_WR -> MEM_RD
    //======================================================
    if (mem_wr_seen) begin
        protocol_order = 5;
        protocol_order_cg.sample();        
    end
end
endfunction
*/
  
//========================================================
// Receive transaction from EP monitor
//========================================================
virtual function void write(dll_packet t);

  //========================================================
  // Store packet information in internal variables
  //========================================================
  linkup    = t.linkup;
  dll_vc_up = t.dll_vc_up;

  header0   = t.header0;
  header1   = t.header1;
  header2   = t.header2;


  //========================================================
  // LINKUP COVERAGE
  //========================================================
  linkup_cg.sample();

  if (linkup == 1'b1) begin

    // Protocol ordering
    linkup_seen = 1'b1;

  end


  //========================================================
  // DLL_VC_UP COVERAGE
  //========================================================
  dll_vc_up_cg.sample();

  if (dll_vc_up[7] == 1'b1) begin

    //========================================================
    // PROTOCOL ORDER: LINK_UP -> DLL_VC_UP
    //========================================================
    if (linkup_seen && !vc_up_seen) begin

      protocol_order = 1;
      protocol_order_cg.sample();
      vc_up_seen = 1'b1;

    end

  end


  //========================================================
  // CFG TLP
  // CFG_RD = 8'h04
  // CFG_WR = 8'h44
  //========================================================
  if ((header0[31:24] == 8'h04) ||
      (header0[31:24] == 8'h44)) begin


    //=========================================================
    // CFG_RD COUNT
    //=========================================================
    if (header0[31:24] == 8'h04) begin

      cfg_rd_count++;

    end


    //=========================================================
    // TLP TYPE COVERAGE
    //=========================================================
    tlp_fmt_type = {header0[31:29], header0[28:24]};
    tlp_type_cg.sample();
    cfg_rd_count_cg.sample();
    cfg_tlp_cg.sample();


    //==========================================================
    // PROTOCOL ORDER: DLL VC UP -> CFG_RD
    //==========================================================
    if (vc_up_seen && !cfg_rd_seen) begin

      protocol_order = 2;
      protocol_order_cg.sample();
      cfg_rd_seen = 1'b1;

    end


    //==========================================================
    // PROTOCOL ORDER: CFG_RD -> CFG_WR
    //==========================================================
    if (header0[31:24] == 8'h44) begin

      if (cfg_rd_seen && !cfg_wr_seen) begin

        protocol_order = 3;
        protocol_order_cg.sample();
        cfg_wr_seen = 1'b1;

      end

    end

  end


  //========================================================
  // MEMORY TLP
  // MEM_WR = 8'b01000000
  // MEM_RD = 8'b00000000
  //========================================================
  if ((header0[31:24] == 8'b01000000) ||
      (header0[31:24] == 8'b00000000)) begin


    //========================================================
    // Length field = Header DW0 [9:0]
    //========================================================
    tlp_length = header0[9:0];

    if (tlp_length == 0)
      tlp_length = 1024;


    //=========================================================
    // MEMORY TLP COVERAGE
    //=========================================================
    mem_wr_tlp_cg.sample();
    mem_rd_tlp_cg.sample();
    payload_size_cg.sample();


    //=========================================================
    // TLP TYPE COVERAGE
    // FMT [31:29] + TYPE [28:24]
    //=========================================================
    tlp_fmt_type = {header0[31:29], header0[28:24]};
    tlp_type_cg.sample();

    memory_address_cg.sample();


    //========================================================
    // MEM_WR
    //========================================================
    if (header0[31:24] == 8'b01000000) begin

      //======================================================
      // PROTOCOL ORDER: CFG_WR -> MEM_WR
      //======================================================
      if (cfg_wr_seen && !mem_wr_seen) begin

        protocol_order = 4;
        protocol_order_cg.sample();
        mem_wr_seen = 1'b1;

      end

    end


    //========================================================
    // MEM_RD
    //========================================================
    if (header0[31:24] == 8'b00000000) begin

      //======================================================
      // PROTOCOL ORDER: MEM_WR -> MEM_RD
      //======================================================
      if (mem_wr_seen) begin

        protocol_order = 5;
        protocol_order_cg.sample();

      end

    end

  end

endfunction
  
function void report_phase(uvm_phase phase);
  
  real overall_coverage;
  real mem_wr_coverage;
  real mem_rd_coverage;
  real cfg_tlp_coverage;
  real cfg_rd_count_coverage; 
  real tlp_type_coverage; 
  real payload_size_coverage;
  real memory_address_coverage;
  real protocol_order_coverage;
  super.report_phase(phase);  
  
  //============================================================
  // Calculate coverage
  //============================================================
    
  cfg_tlp_coverage = cfg_tlp_cg.get_coverage();
  mem_wr_coverage   = mem_wr_tlp_cg.get_coverage();
  mem_rd_coverage   = mem_rd_tlp_cg.get_coverage();
  tlp_type_coverage = tlp_type_cg.get_coverage();
  cfg_rd_count_coverage = cfg_rd_count_cg.cp_cfg_rd_count.get_coverage();
  payload_size_coverage = payload_size_cg.get_coverage();
  memory_address_coverage =  memory_address_cg.get_coverage();
  protocol_order_coverage = protocol_order_cg.get_coverage();
  //============================================================
  // Calculate overall coverage
  //============================================================
  overall_coverage =
  (linkup_cg.get_coverage() +
   dll_vc_up_cg.get_coverage() +
   cfg_tlp_coverage +
   cfg_rd_count_coverage +
   mem_wr_coverage +
   mem_rd_coverage +
   tlp_type_coverage +
   payload_size_coverage +
   memory_address_coverage +
   protocol_order_coverage) / 10.0;
  //============================================================
  // Final Coverage Report
  //============================================================
  `uvm_info("EP_COV",
    "============================================================",
    UVM_NONE)

  `uvm_info("EP_COV",
    "                 FINAL COVERAGE REPORT",
    UVM_NONE)

  `uvm_info("EP_COV",
    "============================================================",
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL LINKUP         : %0b", linkup),
    UVM_NONE)

  `uvm_info("EP_COV",
    "------------------------------------------------------------",
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL DLL_VC_UP      : %08b", dll_vc_up),
    UVM_NONE)

  `uvm_info("EP_COV",
    "------------------------------------------------------------",
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL CFG_RD COUNT   : %0d", cfg_rd_count),
    UVM_NONE)

  `uvm_info("EP_COV",
    "------------------------------------------------------------",
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL FMT + TYPE     : %08h", header0[31:24]),
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL TAG            : %02b",
              {header0[23], header0[19]}),
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  FINAL TLP LENGTH     : %0d", tlp_length),
    UVM_NONE)
  

  `uvm_info("EP_COV",
    "------------------------------------------------------------",
    UVM_NONE)

  `uvm_info("EP_COV",
    $sformatf("  OVERALL COVERAGE     : %0.2f%%",
              overall_coverage),
    UVM_NONE)

  `uvm_info("EP_COV",
    "============================================================",
    UVM_NONE)

endfunction  
endclass