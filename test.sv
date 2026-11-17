class axi_write_test extends uvm_test;

  `uvm_component_utils(axi_write_test)

  //========================================================
  // Environment
  //========================================================
  axi_env env;


  //========================================================
  // Synchronization Event
  //========================================================
  //uvm_event link_up_done;


  function new(string name = "axi_write_test",
               uvm_component parent = null);

    super.new(name, parent);

  endfunction


  //========================================================
  // Build Phase
  //========================================================
  function void build_phase(uvm_phase phase);

    super.build_phase(phase);


    //======================================================
    // Create Environment
    //======================================================
    env = axi_env::type_id::create("env", this);


    //======================================================
    // Create Synchronization Event
    //======================================================
    //link_up_done = new("link_up_done");


    //======================================================
    // Pass link_up_done event to EP Driver
    //======================================================
   /* uvm_config_db#(uvm_event)::set(
      this,
      "env.e_agt.drv",
      "link_up_done",
      link_up_done
    );*/

  endfunction


  //========================================================
  // End of Elaboration
  //========================================================
  function void end_of_elaboration_phase(uvm_phase phase);

    super.end_of_elaboration_phase(phase);

    uvm_top.print_topology();

  endfunction


  //========================================================
  // Run Phase
  //========================================================
  task run_phase(uvm_phase phase);

    //======================================================
    // Main Virtual Sequence
    //======================================================
    main_virtual_sequence vseq;


    phase.raise_objection(this);


    //======================================================
    // Create Main Virtual Sequence
    //======================================================
    vseq = main_virtual_sequence::type_id::create("vseq");


    //======================================================
    // Start Virtual Sequence
    //======================================================
    vseq.start(env.vseqr);


    phase.drop_objection(this);

  endtask

endclass