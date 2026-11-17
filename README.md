# PCIe-AXI Bridge Design Verification

## Project Overview

This project focuses on the functional verification of an AXI-PCIe Bridge using SystemVerilog and UVM (Universal Verification Methodology).

The objective is to develop a structured verification environment to verify communication between AXI and PCIe-related components and check expected transaction behavior.

## Technologies Used

- SystemVerilog
- UVM (Universal Verification Methodology)
- AXI Protocol
- PCIe Protocol
- Synopsys VCS using EDA

## Verification Environment

The testbench contains the following components:

- **AXI Agent:** Includes driver, sequencer, monitor and sequences.
- **Endpoint Agent:** Contains endpoint driver and monitor components.
- **Memory Agent:** Includes memory driver and monitor components.
- **Environment:** Integrates the verification components.
- **Scoreboard:** Used for transaction checking and comparison.
- **Memory Model:** Represents the memory model used in the testbench.
- **Coverage:** Contains functional coverage implementation.
- **Virtual Sequencer:** Coordinates multiple sequencers.

## Project Files

| File | Description |
|---|---|
| agent.sv | AXI agent |
| axi_package.sv | AXI package |
| axi_sequence.sv | AXI sequences |
| axi_sequencer.sv | AXI sequencer |
| driver.sv | AXI driver |
| environment.sv | UVM environment |
| ep_agent.sv | Endpoint agent |
| ep_driver.sv | Endpoint driver |
| ep_monitor.sv | Endpoint monitor |
| mem_agent.sv | Memory agent |
| mem_driver.sv | Memory driver |
| mem_monitor.sv | Memory monitor |
| memory_model.sv | Memory model |
| scoreboard.sv | Scoreboard |
| coverage.sv | Functional coverage |
| virtual_sequencer.sv | Virtual sequencer |

## Key Verification Components

1. UVM-based testbench architecture.
2. AXI transaction generation and monitoring.
3. Endpoint and memory agent integration.
4. Scoreboard-based transaction checking.
5. Functional coverage implementation.

## Learning Outcomes

- Understanding UVM testbench architecture.
- Working with AXI-based transactions.
- Understanding PCIe-related verification components.
- Developing reusable UVM components.
- Understanding scoreboard and functional coverage concepts.

## Author

**Sandhya G**

GitHub: [sandhyag8855-hue](https://github.com/sandhyag8855-hue)

---

*This repository is intended for educational and portfolio purposes.*
