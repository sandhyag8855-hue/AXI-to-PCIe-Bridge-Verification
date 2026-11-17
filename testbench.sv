// Code your testbench here
// or browse Examples

`include "axi_package.sv"
`timescale 1ns/1ps

module tb_top;

  //-----------------------------------------
  // Clock & Reset
  //-----------------------------------------
  bit aclk;
  bit arst;
  bit tl_dll_clk;
  //-----------------------------------------
  // AXI Interfaces
  //-----------------------------------------
  axi_if vif(aclk, arst);                  // Processor AXI Interface
  memory_if mif(aclk, tl_dll_clk, arst);   // Memory AXI Interface
  
  //-----------------------------------------
  // DLL Interface
  //-----------------------------------------
  dll_if dll_vif(tl_dll_clk, arst);

  //-----------------------------------------
  // DUT
  //-----------------------------------------
  pcie_tl dut(

    .aclk(aclk),
    .arst(arst),

    //-----------------------------
    // AXI Processor Interface (_p)
    //-----------------------------
    .awvalid_p(vif.awvalid),
    .awready_p(vif.awready),
    .awid_p(vif.awid),
    .awaddr_p(vif.awaddr),
    .awlen_p(vif.awlen),
    .awburst_p(vif.awburst),
    .awsize_p(vif.awsize),

    .wvalid_p(vif.wvalid),
    .wready_p(vif.wready),
    .wdata_p(vif.wdata),
    .wstrb_p(vif.wstrb),
    .wid_p(vif.wid),
    .wlast_p(vif.wlast),

    .bvalid_p(vif.bvalid),
    .bready_p(vif.bready),
    .bid_p(vif.bid),
    .bresp_p(vif.bresp),

    .arvalid_p(vif.arvalid),
    .arready_p(vif.arready),
    .arid_p(vif.arid),
    .araddr_p(vif.araddr),
    .arlen_p(vif.arlen),
    .arburst_p(vif.arburst),
    .arsize_p(vif.arsize),

    .rvalid_p(vif.rvalid),
    .rready_p(vif.rready),
    .rdata_p(vif.rdata),
    .rid_p(vif.rid),
    .rlast_p(vif.rlast),
    .rresp_p(vif.rresp),

    //-----------------------------
    // AXI Memory Interface (_m)
    //-----------------------------
    .awvalid_m(mif.awvalid),
    .awready_m(mif.awready),
    .awid_m(mif.awid),
    .awaddr_m(mif.awaddr),
    .awlen_m(mif.awlen),
    .awburst_m(mif.awburst),
    .awsize_m(mif.awsize),

    .wvalid_m(mif.wvalid),
    .wready_m(mif.wready),
    .wdata_m(mif.wdata),
    .wstrb_m(mif.wstrb),
    .wid_m(mif.wid),
    .wlast_m(mif.wlast),

    .bvalid_m(mif.bvalid),
    .bready_m(mif.bready),
    .bid_m(mif.bid),
    .bresp_m(mif.bresp),

    .arvalid_m(mif.arvalid),
    .arready_m(mif.arready),
    .arid_m(mif.arid),
    .araddr_m(mif.araddr),
    .arlen_m(mif.arlen),
    .arburst_m(mif.arburst),
    .arsize_m(mif.arsize),

    .rvalid_m(mif.rvalid),
    .rready_m(mif.rready),
    .rdata_m(mif.rdata),
    .rid_m(mif.rid),
    .rlast_m(mif.rlast),
    .rresp_m(mif.rresp),

    //-----------------------------
    // DLL Interface
    //-----------------------------
    .tl_dll_clk(dll_vif.tl_dll_clk),
    .tx_data_o(dll_vif.tx_data),
    .tx_valid_o(dll_vif.tx_valid),
    .tx_ready_i(dll_vif.tx_ready),
    .vc_num(dll_vif.vc_num),

    .rx_data_i(dll_vif.rx_data),
    .rx_valid_i(dll_vif.rx_valid),
    .rx_ready_o(dll_vif.rx_ready),
    .dll_vc_up(dll_vif.dll_vc_up),
    .linkup(dll_vif.linkup),
    .vc_fc_status_o(dll_vif.vc_fc_status),
    .tlp_type_mon_o(dll_vif.tlp_type_mon),
    .target_device_type_o(dll_vif.target_device_type)
  );
  
   pcie_assertions pcie_assertions_i (.dll_vif(dll_vif));

  //-----------------------------------------
  // Clock Generation
  //-----------------------------------------
  initial begin
    aclk = 0;
    forever #5 aclk = ~aclk;
  end

  initial begin
    tl_dll_clk = 0;
    forever #4 tl_dll_clk = ~tl_dll_clk;
  end

  //-----------------------------------------
  // Reset Generation
  //-----------------------------------------
  initial begin
    arst = 1;
    #20;
    arst = 0;
  end

  //-----------------------------------------
  // Default Values
  //-----------------------------------------

  
  //-----------------------------------------
  // UVM Configuration
  //-----------------------------------------
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
    uvm_config_db#(virtual memory_if)::set(null, "*", "mif", mif);
    uvm_config_db#(virtual dll_if)::set(null, "*", "dll_vif", dll_vif);
  end
  
  initial begin
    run_test("axi_write_test");
  end
  
  initial begin
    #400000000;
    $finish;
  end

endmodule



module pcie_assertions(dll_if dll_vif);

  //==========================================================
  // PASS PRINT FLAGS
  //==========================================================
  bit vc_pass_printed       = 0;
  bit cfg_pass_printed      = 0;
  bit mem_pass_printed      = 0;
  bit cfg_wr_done;
  bit mem_wr_done;
  
  //==========================================================
  // 1. VC must not become UP when link is DOWN
  //==========================================================

  property p_no_vc_up_when_link_down;
    @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
      (dll_vif.linkup == 1'b0)
      |-> (dll_vif.dll_vc_up == 8'b0);
  endproperty

  assert property (p_no_vc_up_when_link_down)
  begin
    if (!vc_pass_printed) begin

      `uvm_info("PCIE_ASSERT_PASS",
        $sformatf("PASS @ %0t: VC remains DOWN while LINK is DOWN",
                  $time),
        UVM_LOW)

      vc_pass_printed = 1;
    end
  end
  else begin

    `uvm_error("PCIE_NEG_ASSERT",
      $sformatf("FAIL @ %0t: VC became UP while LINKUP=0: dll_vc_up=%08b",
                $time,
                dll_vif.dll_vc_up))
  end


  //==========================================================
  // 2. No CFG TLP before all DLL VCs are UP
  //==========================================================

  property p_no_enumeration_before_vc_up;
    @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    (dll_vif.dll_vc_up[7] != 1'b1)
      |->
      !((dll_vif.tx_data[28:24] == 5'b00110) ||   // CFG_RD
        (dll_vif.tx_data[28:24] == 5'b00101));     // CFG_WR
  endproperty

  assert property (p_no_enumeration_before_vc_up)
  begin
    if (!cfg_pass_printed) begin

      `uvm_info("PCIE_ASSERT_PASS",
        $sformatf("PASS @ %0t: No CFG TLP before all DLL VCs are UP",
                  $time),
        UVM_LOW)

      cfg_pass_printed = 1;
    end
  end
  else begin

    `uvm_error("PCIE_NEG_ASSERT",
      $sformatf("FAIL @ %0t: CFG TLP detected before all DLL VCs are UP: dll_vc_up=%02h tx_data=%08h",
                $time,
                dll_vif.dll_vc_up,
                dll_vif.tx_data))
  end


  //==========================================================
  // 3. No MEM_RD / MEM_WR before enumeration
  //==========================================================

  property p_no_mem_rd_wr_before_enumeration;
    @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
      !dll_vif.enumeration_done_tb |->
      !((dll_vif.tx_data[28:24] == 5'b00001) ||   // MEM_WR
        (dll_vif.tx_data[28:24] == 5'b00010));     // MEM_RD
  endproperty

  assert property (p_no_mem_rd_wr_before_enumeration)
  begin
    if (!mem_pass_printed) begin

      `uvm_info("PCIE_ASSERT_PASS",
        $sformatf("PASS @ %0t: No MEM_RD/MEM_WR before enumeration",
                  $time),
        UVM_LOW)

      mem_pass_printed = 1;
    end
  end
  else begin

    `uvm_error("PCIE_NEG_ASSERT",
      $sformatf("FAIL @ %0t: MEM_RD/MEM_WR detected before enumeration: tx_data=%08h",
                $time,
                dll_vif.tx_data))
  end

    
    //==========================================================
    // 4. No CFG TLP when link is DOWN
    //==========================================================

   property p_no_cfg_when_link_down;
     @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    (dll_vif.linkup == 1'b0)|->
    !((dll_vif.tx_data[31:24] == 8'b00000100) ||   // CFG_RD
      (dll_vif.tx_data[31:24] == 8'b01000100));     // CFG_WR
   endproperty

   assert property (p_no_cfg_when_link_down)
   else begin
   `uvm_error("PCIE_NEG_ASSERT",$sformatf("FAIL @ %0t: CFG TLP detected while LINKUP=0:     tx_data=%08h",$time,dll_vif.tx_data))
end
    
     
   //==========================================================
   // 5. No MEM_RD / MEM_WR when VC is DOWN
   //==========================================================

property p_no_mem_tlp_before_vc_up;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    (dll_vif.dll_vc_up[7] == 1'b0)
    |->
    !((dll_vif.tx_valid && dll_vif.tx_ready) &&
      ((dll_vif.tx_data[31:24] == 8'b00000000) ||   // MEM_RD
       (dll_vif.tx_data[31:24] == 8'b01000000)));   // MEM_WR
endproperty

assert property (p_no_mem_tlp_before_vc_up)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: MEM_RD/MEM_WR detected while VC is DOWN: tx_data=%08h",
              $time, dll_vif.tx_data))
end
  
  //==========================================================
  // 6. No MEM_RD / MEM_WR when LINK is DOWN
  //==========================================================

property p_no_mem_tlp_when_link_down;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    (dll_vif.linkup == 1'b0)
    |->
    !((dll_vif.tx_valid && dll_vif.tx_ready) &&
      ((dll_vif.tx_data[31:24] == 8'b00000000) ||   // MEM_RD
       (dll_vif.tx_data[31:24] == 8'b01000000)));   // MEM_WR
endproperty

assert property (p_no_mem_tlp_when_link_down)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: MEM_RD/MEM_WR detected while LINKUP=0: tx_data=%08h",
              $time, dll_vif.tx_data))
end
  
  //==========================================================
  // 7. No MEM_RD / MEM_WR before VC FC initialization
  //    is complete
  //==========================================================

property p_no_mem_tlp_before_vc_fc_done;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    (dll_vif.vc_fc_status != 8'hFF)
    |->
    !((dll_vif.tx_valid && dll_vif.tx_ready) &&
      ((dll_vif.tx_data[31:24] == 8'b00000000) ||   // MEM_RD
       (dll_vif.tx_data[31:24] == 8'b01000000)));   // MEM_WR
endproperty

assert property (p_no_mem_tlp_before_vc_fc_done)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: MEM_RD/MEM_WR detected before VC FC initialization: VC_FC_STATUS=%02h tx_data=%08h",
              $time,
              dll_vif.vc_fc_status,
              dll_vif.tx_data))
end
  
  
  //==========================================================
  // 8. CFG_WR must occur only after 16 CFG_RD TLPs
  //==========================================================

integer cfg_rd_assert_count;

always @(posedge dll_vif.tl_dll_clk) begin
  if (dll_vif.arst) begin
    cfg_rd_assert_count = 0;
  end
  else if (dll_vif.tx_valid && dll_vif.tx_ready) begin

    if (dll_vif.tx_data[31:24] == 8'b00000100) begin
      // CFG_RD
      if (cfg_rd_assert_count < 16)
        cfg_rd_assert_count++;
    end

  end
end


property p_cfg_wr_after_cfg_rd;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    ((dll_vif.tx_valid && dll_vif.tx_ready) &&
     (dll_vif.tx_data[31:24] == 8'b01000100))   // CFG_WR
    |-> (cfg_rd_assert_count == 16);
endproperty

assert property (p_cfg_wr_after_cfg_rd)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: CFG_WR detected before 16 CFG_RD TLPs: cfg_rd_count=%0d tx_data=%08h",
              $time,
              cfg_rd_assert_count,
              dll_vif.tx_data))
end
  
  //==========================================================
// 9. MEM_WR must occur only after CFG_WR
//==========================================================

bit cfg_wr_done;

always @(posedge dll_vif.tl_dll_clk) begin
  if (dll_vif.arst) begin
    cfg_wr_done = 1'b0;
  end
  else if (dll_vif.tx_valid && dll_vif.tx_ready) begin

    if (dll_vif.tx_data[31:24] == 8'b01000100) begin
      // CFG_WR detected
      cfg_wr_done = 1'b1;
    end

  end
end


property p_mem_wr_after_cfg_wr;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    ((dll_vif.tx_valid && dll_vif.tx_ready) &&
     (dll_vif.tx_data[31:24] == 8'b01000000))   // MEM_WR
    |-> cfg_wr_done;
endproperty

assert property (p_mem_wr_after_cfg_wr)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: MEM_WR detected before CFG_WR: tx_data=%08h",
              $time,
              dll_vif.tx_data))
end
  
  //==========================================================
// 10. MEM_RD must occur only after MEM_WR
//==========================================================

bit mem_wr_done;

always @(posedge dll_vif.tl_dll_clk) begin
  if (dll_vif.arst) begin
    mem_wr_done = 1'b0;
  end
  else if (dll_vif.tx_valid && dll_vif.tx_ready) begin

    if (dll_vif.tx_data[31:24] == 8'b01000000) begin
      // MEM_WR detected
      mem_wr_done = 1'b1;
    end

  end
end


property p_mem_rd_after_mem_wr;
  @(posedge dll_vif.tl_dll_clk) disable iff (dll_vif.arst)
    ((dll_vif.tx_valid && dll_vif.tx_ready) &&
     (dll_vif.tx_data[31:10] == 22'h000200))   // MEM_RD
    |-> mem_wr_done;
endproperty

assert property (p_mem_rd_after_mem_wr)
else begin
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf("FAIL @ %0t: MEM_RD detected before MEM_WR: tx_data=%08h",
              $time,
              dll_vif.tx_data))
end
  
  //==============================================================
  // Assertion #11 : Valid MEM_RD / MEM_WR Payload Length
  //
  // Checks that the payload length encoded in Header0[9:0]
  // is one of the supported PCIe memory transaction lengths.
  //
  // Supported lengths:
  //   16 DW   = 64 bytes
  //   32 DW   = 128 bytes
  //   64 DW   = 256 bytes
  //   128 DW  = 512 bytes
  //   256 DW  = 1024 bytes
  //   512 DW  = 2048 bytes
  //   0       = 1024 DW = 4096 bytes
  //==============================================================

property p_mem_payload_length_valid;

  @(posedge dll_vif.tl_dll_clk)
  disable iff (dll_vif.arst)

    // Check only when a valid TLP transfer occurs
    (dll_vif.tx_valid &&
     dll_vif.tx_ready &&

     // MEM_RD Header0 fixed fields
     // OR
     // MEM_WR Header0 fixed fields
     (((dll_vif.tx_data[31:10] == 8'b00000000 )) ||   //22'h000200
      ((dll_vif.tx_data[31:10] == 8'b01000000))))      //22'h110200

    // Check that Header0[9:0] contains a supported
    // payload length
    |->
    ((dll_vif.tx_data[9:0] == 10'd0)   ||   // 0 = 1024 DW
     (dll_vif.tx_data[9:0] == 10'd16)  ||   // 16 DW
     (dll_vif.tx_data[9:0] == 10'd32)  ||   // 32 DW
     (dll_vif.tx_data[9:0] == 10'd64)  ||   // 64 DW
     (dll_vif.tx_data[9:0] == 10'd128) ||   // 128 DW
     (dll_vif.tx_data[9:0] == 10'd256) ||   // 256 DW
     (dll_vif.tx_data[9:0] == 10'd512));     // 512 DW

endproperty


//==============================================================
// Assertion Result
//==============================================================

assert property (p_mem_payload_length_valid)

begin
  // Assertion passed
  // No message required for every successful transaction
end

else begin

  // Assertion failed when an unsupported payload
  // length is detected
  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf(
      "FAIL @ %0t: Invalid MEM TLP payload length: HEADER0=%08h LENGTH=%0d DW",
      $time,
      dll_vif.tx_data,
      dll_vif.tx_data[9:0]))

end
  
  
//==============================================================
// 12. No TLP transfer during RESET
//
// When reset is asserted, no TLP transfer shall take place.
// TLP transfer occurs only when TX_VALID && TX_READY are HIGH.
//==============================================================

   property p_no_tlp_transfer_during_reset;
  @(posedge dll_vif.tl_dll_clk)
    (dll_vif.arst === 1'b1)
    |->
    !((dll_vif.tx_valid === 1'b1) &&
      (dll_vif.tx_ready === 1'b1));
endproperty

//==============================================================
// Assertion Result
//==============================================================

assert property (p_no_tlp_transfer_during_reset)

else begin

  `uvm_error("PCIE_NEG_ASSERT",
    $sformatf(
      "FAIL @ %0t: TLP transfer detected while RESET is active: TX_VALID=%0b TX_READY=%0b TX_DATA=%08h",
      $time,
      dll_vif.tx_valid,
      dll_vif.tx_ready,
      dll_vif.tx_data))

end
  
endmodule