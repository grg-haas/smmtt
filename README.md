# Supervisor Domains Privileged ISA Extension

[SMMTT](https://github.com/riscv/riscv-smmtt) is a new isolation mechanism
proposed for RISC-V platforms. It has several benefits over PMP when considering
multi-tenant security use cases, especially in the case of confidential computing.
This repository holds the WIP implementations of SMMTT in various projects, mainly
including QEMU and OpenSBI. The hope is that many of these patches will eventually
be upstreamed into their respective open source projects.

This work is being done as part of a Linux Foundation Mentorship project,
specifically the [Supervisor Domains Priv. ISA Extension Emulation
](https://mentorship.lfx.linuxfoundation.org/project/6e721604-da4f-4647-b8c4-2d41fab55adc)
project.

## Repository structure

This repository mainly consists of a set of Makefiles, helper scripts, and submodules
containing the respective subprojects being integrated. An explanation of most files
and directories is below.

 - `mk/`: A variety of Makefiles, containing both helpers for building submodules
(`linux.mk`, `opensbi.mk`, `qemu.mk`, and `tests.mk`) as well as runtime utility
targets (`run.mk`, `utils.mk`). The build helpers are relatively straightforward, but
the run helpers do have some nuance (discussed [below](#debugging)).
 - `scripts/`: Various utility scripts.
  - `gdb/`: Helpers for loading symbol files when debugging, both using the run
helpers as well as CLion.
  - `templates/`: XML templates for generating run configurations in CLion.
 - `shared/include/smmtt_defs.h`: A shared header used in both OpenSBI and QEMU
containing bit encodings for SMMTT functionality. Much easier to do this than try to
keep the implementations synchronized manually.

Each submodule includes a couple different branches, with a consistent structure.
These include, in typical rebase order:

 - `master/main`: the current latest software version as pulled from upstream.
 - `to-upstream`: patches I have written that have been submitted for review
 - `feature/*`: feature branches for individual, separate high-level features.
Right now, these include `mpxy` for the beta message passing implementation in
OpenSBI/QEMU and `smmtt`

## Architecture

"smmtt-tables" node in device tree

## Build instructions


## Debugging
 
