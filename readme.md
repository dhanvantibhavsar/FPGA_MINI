# VSD-FPGA-MINI-BOARD-INSTALLATION
### What is VSDSquadron FM (FPGA Mini) board?

The VSDSquadron FPGA(Field Programmable Gate Array) Mini (FM) is a compact and low-cost development board designed for FPGA prototyping and embedded system projects. This board provides a seamless hardware development experience with an integrated programmer, versatile GPIO access, and onboard memory, making it ideal for students, hobbyists, and developers exploring FPGA-based designs.[(source)](https://www.vlsisystemdesign.com/vsdsquadronfm/). 



#### How to run a project in the FPGA board?
Follow the steps to run a project:

**1.Navigate the specific folder**

       cd <project-folder>

**2.Build the binaries**

       make build

**3.Flash the code to external SRAM**

       sudo make flash

4.**To clean**

       make clean

       
### Dowmloading the required Open-source tools
- Download the required tools for VSDSquadronFM. 
- Project Icestorm, NextPNR and Yosys.
- These Opensource tools can be downloaded by   the following command:

#### Project icestorm
```
git clone https://github.com/YosysHQ/icestorm.git icestorm
     cd icestorm
     make -j$(nproc)
     sudo make install
```

#### NextPNR
```
     git clone --recursive https://github.com/YosysHQ/nextpnr nextpnr
     cd nextpnr
     cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local .
     make -j$(nproc)
     sudo make install
```

#### Yosys
```
     git clone https://github.com/YosysHQ/yosys.git yosys
     cd yosys
     make -j$(nproc)
     sudo make install
```
