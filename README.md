# DRAM-AXI4Lite

![GitHub stars](https://img.shields.io/github/stars/NexoZegknost/DDR-AXI4Lite?style=for-the-badge&logo=github) ![GitHub forks](https://img.shields.io/github/forks/NexoZegknost/DDR-AXI4Lite?style=for-the-badge&logo=github) ![GitHub issues](https://img.shields.io/github/issues/NexoZegknost/DDR-AXI4Lite?style=for-the-badge&logo=github) ![Last commit](https://img.shields.io/github/last-commit/NexoZegknost/DDR-AXI4Lite?style=for-the-badge&logo=github) ![License](https://img.shields.io/badge/license-LICENSE-green?style=for-the-badge)

## 📑 Table of Contents

- [Description](#description)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

## 📝 Description

DDR-AXI4Lite — a software project built with modern tooling.

## ⚡ Quick Start

```bash

# 1. Clone the repository
git clone https://github.com/NexoZegknost/DDR-AXI4Lite.git

# See the Development Setup section below
```

## 📁 Project Structure

```
.
├── DDR - AXI4Lite
│   ├── Arty-Z7-20-Master.xdc
│   ├── Constraint.xdc
│   ├── DDR - AXI4Lite.cache
│   │   ├── sim
│   │   │   └── ssm.db
│   │   └── wt
│   │       ├── project.wpc
│   │       ├── synthesis.wdf
│   │       ├── synthesis_details.wdf
│   │       ├── webtalk_pa.xml
│   │       └── xsim.wdf
│   ├── DDR - AXI4Lite.hw
│   │   └── DDR - AXI4Lite.lpr
│   ├── DDR - AXI4Lite.ip_user_files
│   │   └── README.txt
│   ├── DDR - AXI4Lite.runs
│   │   ├── .jobs
│   │   │   ├── vrs_config_1.xml
│   │   │   └── vrs_config_2.xml
│   │   ├── impl_1
│   │   │   ├── ISEWrap.js
│   │   │   ├── ISEWrap.sh
│   │   │   ├── dfx_runtime.txt
│   │   │   ├── gen_run.xml
│   │   │   ├── htr.txt
│   │   │   ├── init_design.pb
│   │   │   ├── mem_controller_top.tcl
│   │   │   ├── mem_controller_top.vdi
│   │   │   ├── mem_controller_top_drc_opted.pb
│   │   │   ├── mem_controller_top_drc_opted.rpt
│   │   │   ├── mem_controller_top_drc_opted.rpx
│   │   │   ├── mem_controller_top_opt.dcp
│   │   │   ├── opt_design.pb
│   │   │   ├── place_design.pb
│   │   │   ├── project.wdf
│   │   │   ├── rundef.js
│   │   │   ├── runme.bat
│   │   │   ├── runme.sh
│   │   │   ├── vivado.jou
│   │   │   └── vivado.pb
│   │   └── synth_1
│   │       ├── ISEWrap.js
│   │       ├── ISEWrap.sh
│   │       ├── __synthesis_is_complete__
│   │       ├── dfx_runtime.txt
│   │       ├── gen_run.xml
│   │       ├── htr.txt
│   │       ├── incr_synth_reason.pb
│   │       ├── mem_controller_top.dcp
│   │       ├── mem_controller_top.tcl
│   │       ├── mem_controller_top.vds
│   │       ├── mem_controller_top_utilization_synth.pb
│   │       ├── mem_controller_top_utilization_synth.rpt
│   │       ├── rundef.js
│   │       ├── runme.bat
│   │       ├── runme.sh
│   │       ├── vivado.jou
│   │       └── vivado.pb
│   ├── DDR - AXI4Lite.sim
│   │   └── sim_1
│   │       └── behav
│   │           └── xsim
│   │               └── ...
│   ├── DDR - AXI4Lite.srcs
│   │   ├── constrs_1
│   │   │   └── new
│   │   │       └── mem_controller_top.xdc
│   │   ├── sim_1
│   │   │   └── new
│   │   │       ├── mem_controller_tb.v
│   │   │       └── protocol_engine_tb.v
│   │   ├── sources_1
│   │   │   └── new
│   │   │       ├── axi_slave_interface.v
│   │   │       ├── cmd_scheduler.v
│   │   │       ├── mem_controller_top.v
│   │   │       ├── protocol_engine.v
│   │   │       └── refresh_timer.v
│   │   └── utils_1
│   │       └── imports
│   │           └── synth_1
│   │               └── ...
│   ├── DDR - AXI4Lite.xpr
│   ├── mem_controller_tb_behav.wcfg
│   └── protocol_engine_tb_behav.wcfg
├── LICENSE
└── reports
    ├── DRC
    │   ├── DRC_drc_1.txt
    │   └── drc_1.rpx
    ├── Methodology
    │   ├── methodology_report.txt
    │   └── ultrafast_methodology_1.rpx
    ├── Noise
    │   └── ssn_report.txt
    ├── Power
    │   ├── power_1.rpx
    │   ├── power_power_1.txt
    │   └── power_power_1.xpe
    ├── Resource
    │   ├── Power Summary.png
    │   ├── RTL Schematic.png
    │   ├── Spec.docx
    │   ├── Synthesized Design Package.png
    │   ├── Synthesized Ports.png
    │   ├── Synthesized Schematic.png
    │   └── SystemSpecification.pdf
    ├── Timing
    │   ├── timing_interaction_report.txt
    │   ├── timing_report.rpx
    │   └── timing_report.txt
    ├── Utilization
    │   └── utilization_report.txt
    └── Waveform
        └── protocol_engine.png
```
## Modules design
https://gist.github.com/NexoZegknost/d753cbc95a5cb089d8bd735e5c3fc6e5

## 👥 Contributing

Contributions are welcome! Here's the standard flow:

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/NexoZegknost/DDR-AXI4Lite.git`
3. **Branch**: `git checkout -b feature/your-feature`
4. **Commit**: `git commit -m 'feat: add some feature'`
5. **Push**: `git push origin feature/your-feature`
6. **Open** a pull request

Please follow the existing code style and include tests for new behavior where applicable.

## 📜 License

This project is licensed under the **LICENSE** License.
