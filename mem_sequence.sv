class mem_write extends uvm_sequence #(transaction);

  `uvm_object_utils(mem_write)

  transaction tr;
  int unsigned  dma_length;

  function new(string name = "mem_write");
    super.new(name);
  endfunction

  virtual task body();

    //========================================
    // Generate one sequence item per burst
    //========================================   
     tr = transaction::type_id::create("tr");
      start_item(tr);
      tr.op      = WR_TXN;
      tr.arready = 1'b1;
      tr.num_bursts = dma_length / 64;
     // tr.num_bursts = (dma_length + 63) / 64;
      finish_item(tr);
  endtask
endclass


class mem_write_read extends uvm_sequence #(transaction);

    `uvm_object_utils(mem_write_read)

    transaction tr;

    function new(string name = "mem_write_read");
        super.new(name);
    endfunction

    virtual task body();

        tr = transaction::type_id::create("tr");

        start_item(tr);

        tr.op      = RD_TXN;
        tr.arready = 1'b1;

        tr.rvalid  = 1'b1;
        tr.rid     = 4'd0;
        tr.rresp   = 2'b00;
        tr.rlast   = 1'b0;

        finish_item(tr);

    endtask

endclass


class axi_memory_read extends uvm_sequence #(transaction);

    `uvm_object_utils(axi_memory_read)

    transaction tr;
    int unsigned rx_length;
  
    function new(string name = "axi_memory_read");
        super.new(name);
    endfunction

    virtual task body();

        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.op = AXI_MEM;
        tr.num_bursts = (rx_length) / 16;
        finish_item(tr);

    endtask
endclass

