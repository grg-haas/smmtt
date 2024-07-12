import os

# First, we need to detect whether we are running in the QEMU GDB or the other
# GDB instance for running programs. To do so, we'll set two breakpoints on
# early functions in both of these and check which we hit first. Note that we
# do rely on something external adding the initial symbol file so we hit these
# breakpoints.

class CustomBreakpoint(gdb.Breakpoint):
	def __init__(self, func):
		super().__init__(func, internal=True)
		self.done = False

	def stop(self):
		self.done = True


class QEMUBreakpoint(CustomBreakpoint):
	def __init__(self):
		super().__init__('qemu_init')

	def stop(self):
		super().stop()
		print('Detected QEMU')
		return False

class OpenSBIBreakpoint(CustomBreakpoint):
	def __init__(self):
		super().__init__('sbi_init')

	def stop(self):
		super().stop()
		print('Detected OpenSBI')

		# Also add the symbol file for the tests to this one
		frame = gdb.selected_frame()
		arch = frame.architecture().name()

		if arch == 'riscv:rv32':
			gdb.execute(f'add-symbol-file -o {hex(0x80400000)} build/dbg/tests32/riscv/sbi.elf')
		elif arch == 'riscv:rv64':
			gdb.execute(f'add-symbol-file -o {hex(0x80200000)} build/dbg/tests64/riscv/sbi.elf')

		return False

# Instantiate breakpoints
qb = QEMUBreakpoint()
ob = OpenSBIBreakpoint()
breakpoints = [qb, ob]

# Initialize a handler to clean up once we've done init
def stop_handler(event):
	if any([b.done for b in breakpoints]):
		for b in breakpoints:
			b.delete()

		gdb.events.stop.disconnect(stop_handler)

gdb.events.stop.connect(stop_handler)
