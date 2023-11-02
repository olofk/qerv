<img align="right" src="https://svg.wavedrom.com/{signal:[{wave:'0.P...'},{wave:'023450',data:'Q E R V'}]}"/>

# SERV

[![Join the chat at https://gitter.im/librecores/serv](https://badges.gitter.im/librecores/serv.svg)](https://gitter.im/librecores/serv?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![CI status](https://github.com/olofk/serv/workflows/CI/badge.svg)](https://github.com/olofk/serv/actions?query=workflow%3ACI)

QERV is the four-bit perfomance-enhanced version of the award-winning SERV, the world's smallest RISC-V CPU

QERV builds upon SERV and will eventually be completely integrated. This repository is a staging area where QERV development will be performed until then. Apart from being faster and slightly larger, QERV is compatible with SERV, and we therefor recommend reading the [SERV documentation](https://serv.readthedocs.io/en/latest/) and see the [SERV repository](https://github.com/olofk/serv) for more detailed information.

## Quick start

QERV uses [FuseSoC](https://github.com/olofk/fusesoc) to handle its dependencies and run the design through different tool flows.

1. Install FuseSoC `pip3 install fusesoc`
2. Create an empty workspace directory and enter it `mkdir workspace && cd workspace`
3. From within your workspace directory add the required FuseSoC libraries
   - Base library `fusesoc library add fusesoc-cores https://github.com/fusesoc/fusesoc-cores`
   - SERV `fusesoc library add serv https://github.com/olofk/serv`
   - QERV `fusesoc library add qerv https://github.com/olofk/qerv`
4. FuseSoC should be able to see the QERV core. Verify this by running `fusesoc core show qerv`
5. We can now run a simulation of QERV executing a simple Zephyr application. `fusesoc run --target=verilator_tb servant --uart_baudrate=191000 --timeout=10000000` will launch a simulation using Verilator and printing out a text string twice before exiting. Other firmware can be loaded using the `--firmware` parameter.
6. Synthesizing a minimal version of QERV using Yosys for an iCE40 FPGA can be done with `fusesoc run --target=default --tool=icestorm qerv --pnr=none --WITH_CSR=0`
7. Create a GDS using OpenLANE `fusesoc run --target=sky130 qerv`. It is also possible to automatically download and run the EDA tools from Docker containers by setting the environment variable `EDALIZE_LAUNCHER` to `el_docker`, i.e. run the command `EDALIZE_LAUNCHER=el_docker fusesoc run --target=sky130 qerv` instead if you don't have the toolchain locally installed.
