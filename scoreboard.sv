`uvm_analysis_imp_decl(_axi_proc)
 `uvm_analysis_imp_decl(_ep)
`uvm_analysis_imp_decl(_axi_mem)
`uvm_analysis_imp_decl(_base_addr)

class axi_scoreboard extends uvm_scoreboard;

  
  `uvm_component_utils(axi_scoreboard)
   uvm_analysis_imp_axi_proc #(transaction, axi_scoreboard) analysis_export;
   uvm_analysis_imp_ep #(dll_packet, axi_scoreboard) ep_export;
   uvm_analysis_imp_axi_mem #(transaction, axi_scoreboard) axi_mem_imp;
   uvm_analysis_imp_base_addr #(bit [31:0], axi_scoreboard) addr_imp;
  
  typedef struct {
  bit [31:0] addr;
  bit [31:0] data;
} mem_entry_t;
  
  
  mem_entry_t mem_q[$], read_q[$];
  mem_entry_t entry,rd_entry;
  bit link_training_done;
  
    //====================================================
  // Config Read TLP structure
  //====================================================
  typedef struct {
    bit [31:0] header0;
    bit [31:0] header1;
    bit [31:0] header2;
  } cfg_rd_tlp_t;


  //====================================================
  // Config Write TLP structure
  //====================================================
  typedef struct {
    bit [31:0] header0;
    bit [31:0] header1;
    bit [31:0] header2;
    bit [31:0] payload[1024];
  } cfg_wr_tlp_t;
    
  static bit [9:0]  mem_rd_length;
  static bit [15:0] mem_rd_requester_id;
  static bit [7:0]  mem_rd_tag;
  static bit [3:0]  mem_rd_last_be;
  static bit [3:0]  mem_rd_first_be;
  static bit [31:0] mem_rd_address;
  
  bit [31:0] base_add;
 
 int payload_index = 0;
   // Stores 16 Config Read TLPs
  cfg_rd_tlp_t cfg_rd_q[$];
  cfg_rd_tlp_t cfg_rd_entry;

  // Stores Config Write TLPs
  cfg_wr_tlp_t cfg_wr_q[$];    
  cfg_wr_tlp_t cfg_wr_entry;
  
  // Stores memory Write TLPs
  cfg_wr_tlp_t mem_wr_tlp_q[$];
  cfg_wr_tlp_t mem_wr_tlp_entry;
  
   // Stores memory read TLPs
  cfg_rd_tlp_t mem_rd_tlp_q[$];
  cfg_rd_tlp_t mem_rd_tlp_entry;
  
  // Stores memory read TLPs payload packet from axi 
  cfg_wr_tlp_t mem_rd_axi_tlp_q[$];
  cfg_wr_tlp_t mem_rd_axi_tlp_entry;
  
  //To extract required information from memory read request
 // static mem_rd_extract mem_rd_req;
  
  int unsigned payload_dw = 0;

  function new(string name = "axi_scoreboard",uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  

  //-------------------------
  // Build Phase
  //-------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
    ep_export = new("ep_export", this);
    axi_mem_imp = new("axi_mem_imp", this);
    addr_imp = new("addr_imp", this);
  endfunction
  
 
  function void write_axi_proc(transaction tr);
  case(tr.op)

    RST_DUT: begin`uvm_info("SB",$sformatf("[%0t ns]========== SCOREBOARD : RESET ==========", $time),UVM_MEDIUM)
    end
        
   WR_TXN: begin
      entry.addr = tr.awaddr;
      entry.data = tr.wdata;

      mem_q.push_back(entry);

    if (((tr.awaddr >= 32'h1000) && (tr.awaddr <= 32'h101C)) ||
    (tr.awaddr == 32'h2000) ||
    (tr.awaddr == 32'h27FC) ||
    (tr.awaddr == 32'h2800) ||
    (tr.awaddr == 32'h2FFC) ||
    (tr.awaddr == 32'h2004)) begin
     
   /*  if (((tr.araddr >= 32'h1000) && (tr.araddr <= 32'h101C)) ||
         ((tr.araddr >= 32'h2000) && (tr.araddr <= 32'h27FC)) ||
    (tr.araddr == 32'h2800) || (tr.araddr == 32'h2FFC)) begin */
     
      `uvm_info("SB",
        $sformatf("\n[WRITE CAPTURED]\nADDR  = %08h\nDATA  = %08h\nBRESP = %0d\nBID   = %0d",
                  tr.awaddr,
                  tr.wdata,
                  tr.bresp,
                  tr.bid),
        UVM_MEDIUM)

     end
    end
    RD_TXN: begin

            rd_entry.addr = tr.araddr;
            rd_entry.data = tr.rdata;

            read_q.push_back(rd_entry);
      
      if (((tr.araddr >= 32'h1000) && (tr.araddr <= 32'h101C)) ||
    (tr.araddr == 32'h2000) ||
    (tr.araddr == 32'h27FC) ||
    (tr.araddr == 32'h2800) ||
    (tr.araddr == 32'h2FFC) ||
    (tr.araddr == 32'h2004)) begin
      
      
      /*if (((tr.araddr >= 32'h1000) && (tr.araddr <= 32'h101C)) ||
    ((tr.araddr >= 32'h2000) && (tr.araddr <= 32'h27FC)) ||
    (tr.araddr == 32'h2800) || (tr.araddr == 32'h2FFC)) begin*/


  `uvm_info("SB",
    $sformatf("\n[READ CAPTURED]\nADDR  = %08h\nDATA  = %08h\nRRESP = %0d\nRID   = %0d",
              tr.araddr,
              tr.rdata,
              tr.rresp,
              tr.rid),
    UVM_MEDIUM)
        end

end
  endcase
endfunction

  
function void write_ep(dll_packet pkt);


  if((pkt.vc_fc_status == 8'b11111111) && !link_training_done) begin
    link_training_done = 1;
     `uvm_info("SB",$sformatf("\n========== LINK TRAINING SUCCESSFUL ==========\nLINKUP = %0d\nDLL_VC_UP = %08b\nVC_FC_STATUS = %08b\n===============================================",
              pkt.linkup,
              pkt.dll_vc_up,
              pkt.vc_fc_status),
    UVM_MEDIUM)
  end
  
  //========================================
  // CONFIG READ TLP
  //========================================
  
  if (pkt.header0[31:24] == 8'b00000100) begin
  
   cfg_rd_entry.header0 = pkt.header0;
   cfg_rd_entry.header1 = pkt.header1;
   cfg_rd_entry.header2 = pkt.header2;

   cfg_rd_q.push_back(cfg_rd_entry);

end
  
  //========================================
  // CONFIG WRITE TLP
  //========================================
  if (pkt.header0[31:24] == 8'b01000100) begin
 
  cfg_wr_entry.header0 = pkt.header0;
  cfg_wr_entry.header1 = pkt.header1;
  cfg_wr_entry.header2 = pkt.header2;
  cfg_wr_entry.payload = pkt.payload;

  cfg_wr_q.push_back(cfg_wr_entry);

end
  
  //========================================
  // MEMORY WRITE TLP
  //========================================
  if (pkt.header0[31:24] == 8'b01000000) begin

   mem_wr_tlp_entry.header0  = pkt.header0;
   mem_wr_tlp_entry.header1  = pkt.header1;
   mem_wr_tlp_entry.header2  = pkt.header2;
   mem_wr_tlp_entry.payload  = pkt.payload;

   mem_wr_tlp_q.push_back(mem_wr_tlp_entry);

end
  
  //========================================
  // MEMORY READ TLP
  //========================================
if (pkt.header0[31:24] == 8'b00000000) begin

  mem_rd_tlp_entry.header0 = pkt.header0;
  mem_rd_tlp_entry.header1 = pkt.header1;
  mem_rd_tlp_entry.header2 = pkt.header2;

  mem_rd_tlp_q.push_back(mem_rd_tlp_entry);
  
  // Store Memory Read TLP   
    mem_rd_length       = pkt.header0[9:0];
    mem_rd_requester_id = pkt.header1[31:16];
    mem_rd_tag          = pkt.header1[15:8];
    mem_rd_last_be      = pkt.header1[7:4];
    mem_rd_first_be     = pkt.header1[3:0];
    mem_rd_address      = pkt.header2;  

end
  

endfunction
  
  function void write_base_addr(bit [31:0] addr);
    base_add = addr;
    `uvm_info("AXI_SB",$sformatf("Received FIRST AXI ADDRESS = %08h", base_add),UVM_MEDIUM)
endfunction
  
  function void write_axi_mem(transaction tr);
    
    
    mem_rd_axi_tlp_entry.payload[payload_index] = tr.wdata;

    payload_index++;

    if (tr.wlast == 1)
    begin
        mem_rd_axi_tlp_q.push_back(mem_rd_axi_tlp_entry);

        payload_index = 0;
    end

  endfunction
  
 
      
virtual function void report_phase(uvm_phase phase);

  
   int mem_index;
    int total_count;
    int pass_count = 0;
    int fail_count = 0;
    bit [31:0] expected_data;
    bit [31:0] received_data;
// Config Read TLPs
  //====================================================

  `uvm_info("SB","====================================================",UVM_NONE)

  `uvm_info("SB","STORED CONFIG READ TLPs",UVM_NONE)

  `uvm_info("SB","====================================================",UVM_NONE)

  for (int i = 0; i < cfg_rd_q.size(); i++) begin

    `uvm_info("SB",$sformatf(
        "\n---------- CONFIG READ TLP %0d ----------\nHeader0 = %08h\nHeader1 = %08h\nHeader2 = %08h\n",
        i,
        cfg_rd_q[i].header0,
        cfg_rd_q[i].header1,
        cfg_rd_q[i].header2),UVM_NONE);

  end
  //====================================================
  // Config Write TLPs
  //====================================================

  `uvm_info("SB",
    "====================================================",
    UVM_NONE)

  `uvm_info("SB",
    "          STORED CONFIG WRITE TLPs",
    UVM_NONE)

  `uvm_info("SB",
    "====================================================",
    UVM_NONE)

  for (int i = 0; i < cfg_wr_q.size(); i++) begin

    `uvm_info("SB",$sformatf("\n---------- CONFIG WRITE TLP %0d ----------\nHeader0 = %08h\nHeader1 = %08h\nHeader2 = %08h\nPayload = %08h\n------------------------------------------",
        i,
        cfg_wr_q[i].header0,
        cfg_wr_q[i].header1,
        cfg_wr_q[i].header2,
        cfg_wr_q[i].payload[0]
      ),
      UVM_NONE
    );

  end
  
  /* `uvm_info("MEM_WR_REPORT","========== MEMORY WRITE TLP QUEUE ==========",UVM_NONE)
    $display("Number of Memory Write TLPs = %0d",mem_wr_tlp_q.size());

  for (int i = 0; i < mem_wr_tlp_q.size(); i++) 
      begin

        $display("------------------------------------------------");
        $display("MEMORY WRITE TLP[%0d]", i);
        $display("HEADER0 = %08h", mem_wr_tlp_q[i].header0);
        $display("HEADER1 = %08h", mem_wr_tlp_q[i].header1);
        $display("HEADER2 = %08h", mem_wr_tlp_q[i].header2);
        
        payload_dw = mem_wr_tlp_q[i].header0[9:0];
        if (payload_dw == 0)
        payload_dw = 1024;

        for (int j = 0; j < payload_dw ; j++) 
          begin          
            $display("PAYLOAD[%0d] = %08h",j,mem_wr_tlp_q[i].payload[j]);
        end

    end

    $display("================================================");

  
  for (int i = 0; i < mem_rd_tlp_q.size(); i++)
  begin
    `uvm_info("MEM_RD_REPORT",
              $sformatf("MEMORY READ TLP[%0d] : \nHEADER[0]=%08h\nHEADER[1]=%08h\nHEADER[2]=%08h",i,
                mem_rd_tlp_q[i].header0,
                mem_rd_tlp_q[i].header1,
                mem_rd_tlp_q[i].header2),UVM_NONE)
  end

  `uvm_info("MEM_RD_REPORT",$sformatf("Total Memory Read TLPs = %0d", mem_rd_tlp_q.size()),UVM_NONE)
  
  `uvm_info("::",$sformatf("==================================================="),UVM_NONE)
     
  `uvm_info("AXI_REPORT",$sformatf("Total AXI bursts captured = %0d",mem_rd_axi_tlp_q.size()),UVM_LOW)
  $display("base_add = %08h",base_add);

    for (int i = 0; i < mem_rd_axi_tlp_q.size(); i++)
    begin
        $display("==========================================");
        $display("AXI BURST [%0d]", i);
        $display("==========================================");

        for (int j = 0; j < 16; j++)
        begin
            $display("PAYLOAD[%0d] = %08h",j,mem_rd_axi_tlp_q[i].payload[j]);
        end
    end  
  
  //============================================================
// MEM2 vs MEM_RD AXI PAYLOAD COMPARISON
//============================================================

`uvm_info("MEM_COMPARE",
          "===================================================",
          UVM_NONE)

`uvm_info("MEM_COMPARE",
          "          MEM2 vs MEM_RD AXI PAYLOAD",
          UVM_NONE)

`uvm_info("MEM_COMPARE",
          "===================================================",
          UVM_NONE)

total_count = 0;
pass_count  = 0;
fail_count  = 0;

$display("Number of AXI bursts = %0d", mem_rd_axi_tlp_q.size());
$display("DWORDs per burst     = 16");
$display("Total DWORDs         = %0d",
         mem_rd_axi_tlp_q.size() * 16);
$display("Total Bytes          = %0d",
         mem_rd_axi_tlp_q.size() * 16 * 4);*/

  $display("===================================================================================");

$display("===================================================================================");
$display("      COMPARING PAYLOAD: MEMORY READ vs MEMORY WRITE");
$display("===================================================================================");
//------------------------------------------------------------
// Compare every AXI burst
//------------------------------------------------------------
for (int burst = 0; burst < mem_rd_axi_tlp_q.size(); burst++)
begin

    $display("---------------------------------------------------");
    $display("Comparing AXI BURST [%0d]", burst);
    $display("---------------------------------------------------");

    //--------------------------------------------------------
    // Each AXI burst contains 16 DWORDs
    //--------------------------------------------------------
    for (int beat = 0; beat < 16; beat++)
    begin

        mem_index = (burst * 16) + beat;

        expected_data = memory_model::mem2[mem_index];
        received_data = mem_rd_axi_tlp_q[burst].payload[beat];

        total_count++;

        if (expected_data == received_data)
        begin
            pass_count++;
/*
            `uvm_info("MEM_COMPARE",
                      $sformatf(
                      "PASS [%0d] MEM2=%08h AXI_PAYLOAD=%08h",
                      mem_index,
                      expected_data,
                      received_data),
                      UVM_LOW)*/
        end
        else
        begin
            fail_count++;

            `uvm_error("MEM_COMPARE",
                       $sformatf(
                       "FAIL [%0d] MEM2=%08h AXI_PAYLOAD=%08h",
                       mem_index,
                       expected_data,
                       received_data))
        end

    end
end

//------------------------------------------------------------
// Final comparison result
//------------------------------------------------------------

$display("");
  $display("===================================================================================");
$display("             MEMORY COMPARE RESULT");
  $display("===================================================================================");
$display("Total AXI Bursts : %0d", mem_rd_axi_tlp_q.size());
$display("Total Compared   : %0d", total_count);
$display("Total Bytes      : %0d", total_count * 4);
$display("PASS             : %0d", pass_count);
$display("FAIL             : %0d", fail_count);
if (fail_count == 0)
begin
    $display("STATUS           : MEMORY COMPARE PASS : %0d/%0d DWORDs matched",
             pass_count,
             total_count);
end
else
begin
    $display("STATUS           : MEMORY COMPARE FAIL : PASS=%0d FAIL=%0d TOTAL=%0d",
             pass_count,
             fail_count,
             total_count);
end
$display("===================================================================================");



endfunction
endclass

