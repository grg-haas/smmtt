import os

# Constants
KERNEL32_LOAD_ADDR = 0x80400000
KERNEL64_LOAD_ADDR = 0x80200000
KERNEL_SECONDARY_LOAD_ADDR = 0x90000000

class DiscoveryBreakpoint(gdb.Breakpoint):
	def __init__(self):
		super().__init__('_fw_start', temporary=True, internal=True)
		self.hit = False
		self.SMMTT_BITS = None
		self.SMMTT_ISOL = None
		self.SMMTT_TEST = None

	def determine_name(self, arch):
		name = arch.name()
		if name == 'riscv:rv32':
			self.SMMTT_BITS = '32'
		elif name == 'riscv:rv64':
			self.SMMTT_BITS = '64'
		else:
			print(f'Unknown bits for arch {name}')
			exit(-1)

	def determine_isol(self, arch):
		regs = arch.registers()
		if regs.find('mttp') is None:
			self.SMMTT_ISOL = 'max'
		else:
			self.SMMTT_ISOL = 'smmtt'

	def determine_test(self):
		# We'll do this by comparing memory at the kernel load address
		# to the different binary files we support, up to a total of
		# 16 kb
		addr = None
		linuxmem = None
		testmem = None
		unittestmem = None

		if self.SMMTT_BITS == '32':
			addr = KERNEL32_LOAD_ADDR
			with open('build/dbg/linux32/arch/riscv/boot/Image', 'rb') as f:
				linuxmem = f.read(16 * 1024)

			with open('build/dbg/tests32/riscv/sbi.flat', 'rb') as f:
				testmem = f.read(16 * 1024)

			with open('build/dbg/tests32/riscv/smmtt.flat', 'rb') as f:
				unittestmem = f.read(16 * 1024)

		elif self.SMMTT_BITS == '64':
			addr = KERNEL64_LOAD_ADDR
			with open('build/dbg/linux64/arch/riscv/boot/Image', 'rb') as f:
				linuxmem = f.read(16 * 1024)

			with open('build/dbg/tests64/riscv/sbi.flat', 'rb') as f:
				testmem = f.read(16 * 1024)

			with open('build/dbg/tests64/riscv/smmtt.flat', 'rb') as f:
				unittestmem = f.read(16 * 1024)

		# Read the first 16 kilobytes
		inf = gdb.selected_inferior()
		mem = [int.from_bytes(a, 'big') for a in inf.read_memory(addr, 16 * 1024)]

		if all([a == b for a, b in zip(mem, linuxmem)]):
			self.SMMTT_TEST = 'linux'
		elif all([a == b for a, b in zip(mem, testmem)]):
			self.SMMTT_TEST = 'tests'
		elif all([a == b for a, b in zip(mem, unittestmem)]):
			self.SMMTT_TEST = 'unittests'
		else:
			print(f'Unrecognized kernel memory')
			exit(-1)


	def stop(self):
		if not self.hit:
			self.hit = True
			arch = gdb.selected_frame().architecture()
			if self.SMMTT_BITS is None:
				self.determine_name(arch)

			if self.SMMTT_ISOL is None:
				self.determine_isol(arch)

			if self.SMMTT_TEST is None:
				self.determine_test()

			self.add_symbol_files()
		return False

	def add_symbol_files(self):
		print('add_symbol_files called')
		OPENSBI_BUILDDIR = os.getenv(f'OPENSBI{self.SMMTT_BITS}_BUILDDIR')
		if OPENSBI_BUILDDIR is None:
			OPENSBI_BUILDDIR = f'build/dbg/opensbi{self.SMMTT_BITS}'

		LINUX_BUILDDIR = os.getenv(f'LINUX{self.SMMTT_BITS}_BUILDDIR')
		if LINUX_BUILDDIR is None:
			LINUX_BUILDDIR = f'build/dbg/linux{self.SMMTT_BITS}'

		TESTS_BUILDDIR = os.getenv(f'TESTS{self.SMMTT_BITS}_BUILDDIR')
		if TESTS_BUILDDIR is None:
			TESTS_BUILDDIR = f'build/dbg/tests{self.SMMTT_BITS}'

		# Always add opensbi symbol files
		gdb.execute(f'add-symbol-file {OPENSBI_BUILDDIR}/platform/generic/firmware/fw_jump.elf')

		# Add test-specific files
		if self.SMMTT_TEST == 'linux':
			gdb.execute(f'add-symbol-file {LINUX_BUILDDIR}/vmlinux')

		elif self.SMMTT_TEST == 'tests':
			gdb.execute(f'add-symbol-file -o {hex(KERNEL_SECONDARY_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/sbi.elf')

			if self.SMMTT_BITS == '32':
				gdb.execute(f'add-symbol-file -o {hex(KERNEL32_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/sbi.elf')
			elif self.SMMTT_BITS == '64':
				gdb.execute(f'add-symbol-file -o {hex(KERNEL64_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/sbi.elf')

		elif self.SMMTT_TEST == 'unittests':
			gdb.execute(f'add-symbol-file -o {hex(KERNEL_SECONDARY_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/smmtt.elf')

			if self.SMMTT_BITS == '32':
				gdb.execute(f'add-symbol-file -o {hex(KERNEL32_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/smmtt.elf')
			elif self.SMMTT_BITS == '64':
				gdb.execute(f'add-symbol-file -o {hex(KERNEL64_LOAD_ADDR)} {TESTS_BUILDDIR}/riscv/smmtt.elf')

# We need to defer feature discovery until we have a stack frame.
# Otherwise, GDB does not expose the information we need. In this case,
# we assume something external (typically CLion) has loaded the initial
# OpenSBI symbol file for us so we can set this breakpoint. We'll also
# make sure to only break on the coldbooting thread.

db = DiscoveryBreakpoint()
