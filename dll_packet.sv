typedef enum {
  LINK_TRAINING,
  CONFIG_READ,
  CONFIG_WRITE,
  MEMORY_WRITE,
  MEMORY_READ
} ep_state;

class dll_packet extends uvm_sequence_item;

  `uvm_object_utils(dll_packet)
  
  ep_state pkt_type;

  //=========================
  // TX (DUT -> TB)
  //=========================
  bit [31:0] tx_data;
  bit        tx_valid;
  bit [2:0]  vc_num;

  //=========================
  // RX (TB -> DUT)
  //=========================
  rand bit [31:0] rx_data;
  rand bit        rx_valid;

  //=========================
  // Handshake
  //=========================
  rand bit        tx_ready;
  bit             rx_ready;

  //=========================
  // Link Status
  //=========================
  bit [7:0] dll_vc_up;
  bit       linkup;
  
  
//config_read_tlp_headers
bit [31:0] header0;
bit [31:0] header1;
bit [31:0] header2;
bit [31:0] payload [1024];
bit [31:0] header;
  
 typedef struct {
    bit [31:0] payload[0:15];
  } mem_wr_tlp_t;
 
  mem_wr_tlp_t mem_wr_tlp_posted;
 
  //Debug port
  bit [7:0]  vc_fc_status;

  function new(string name = "dll_packet");
    super.new(name);
  endfunction

endclass