class memory_model;


  static rand bit [31:0] mem1 [1023:0];
  
  
constraint mem1_random {
  foreach (mem1[i])
    mem1[i] inside {[32'h0000_0000 : 32'hFFFF_FFFF]};
}

  
  //====================================================
  // MEM2
  // 4 KB EP memory
  // 1024 locations × 32 bits = 4 KB
  //====================================================
  static bit [31:0] mem2 [1023:0];


  //====================================================
  // Address decoding
  //====================================================
 
  static function int decode_addr(bit [31:0] addr);
    return (addr - 32'hEC00_0000) / 4; 
  endfunction   
endclass