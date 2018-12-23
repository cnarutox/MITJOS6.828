
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 76 39 00 00       	call   f01039df <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 14 cb fe ff    	lea    -0x134ec(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 01 2e 00 00       	call   f0102e83 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 c0 11 00 00       	call   f0101247 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 8c 07 00 00       	call   f0100820 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 65 72 01 00    	add    $0x17265,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 5b 07 00 00       	call   f0100820 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 2f cb fe ff    	lea    -0x134d1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 9d 2d 00 00       	call   f0102e83 <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 5c 2d 00 00       	call   f0102e4c <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 c5 d9 fe ff    	lea    -0x1263b(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 85 2d 00 00       	call   f0102e83 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 47 cb fe ff    	lea    -0x134b9(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 58 2d 00 00       	call   f0102e83 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 15 2d 00 00       	call   f0102e4c <vcprintf>
	cprintf("\n");
f0100137:	8d 83 c5 d9 fe ff    	lea    -0x1263b(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 3e 2d 00 00       	call   f0102e83 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 90 71 01 00    	add    $0x17190,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 78 1f 00 00    	mov    0x1f78(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 78 1f 00 00    	mov    %edx,0x1f78(%ebx)
f010019e:	88 84 0b 74 1d 00 00 	mov    %al,0x1d74(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 45 71 01 00    	add    $0x17145,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 54 1d 00 00    	mov    %ecx,0x1d54(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 94 cc fe 	movzbl -0x1336c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 94 cb fe 	movzbl -0x1346c(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 61 cb fe ff    	lea    -0x1349f(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 0d 2c 00 00       	call   f0102e83 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 54 1d 00 00 40 	orl    $0x40,0x1d54(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 94 cc fe 	movzbl -0x1336c(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0f 70 01 00    	add    $0x1700f,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 7c 1f 00 00 	cmpw   $0x7cf,0x1f7c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 80 1f 00 00    	mov    0x1f80(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 7c 1f 00 00 	addw   $0x50,0x1f7c(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 7c 1f 00 00 	mov    %dx,0x1f7c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 80 1f 00 00    	mov    0x1f80(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 55 35 00 00       	call   f0103a2c <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 7c 1f 00 00 	subw   $0x50,0x1f7c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 6e 01 00       	add    $0x16e02,%eax
	if (serial_exists)
f010050f:	80 b8 88 1f 00 00 00 	cmpb   $0x0,0x1f88(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d4 6d 01 00       	add    $0x16dd4,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b1 8e fe ff    	lea    -0x1714f(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b6 6d 01 00    	add    $0x16db6,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 74 1f 00 00    	mov    0x1f74(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 78 1f 00 00    	cmp    0x1f78(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 74 1f 00 00    	mov    %ecx,0x1f74(%ebx)
f0100582:	0f b6 84 13 74 1d 00 	movzbl 0x1d74(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 74 1f 00 00 00 	movl   $0x0,0x1f74(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 5a 6d 01 00    	add    $0x16d5a,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 84 1f 00 00 b4 	movl   $0x3b4,0x1f84(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 84 1f 00 00    	mov    0x1f84(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 80 1f 00 00    	mov    %edi,0x1f80(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 7c 1f 00 00 	mov    %si,0x1f7c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 88 1f 00 00 	setne  0x1f88(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 84 1f 00 00 d4 	movl   $0x3d4,0x1f84(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 6d cb fe ff    	lea    -0x13493(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 c2 27 00 00       	call   f0102e83 <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 0d 6c 01 00    	add    $0x16c0d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 94 cd fe ff    	lea    -0x1326c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 b2 cd fe ff    	lea    -0x1324e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 b7 cd fe ff    	lea    -0x13249(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 61 27 00 00       	call   f0102e83 <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 20 ce fe ff    	lea    -0x131e0(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 c0 cd fe ff    	lea    -0x13240(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 4a 27 00 00       	call   f0102e83 <cprintf>
	return 0;
}
f0100739:	b8 00 00 00 00       	mov    $0x0,%eax
f010073e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100741:	5b                   	pop    %ebx
f0100742:	5e                   	pop    %esi
f0100743:	5d                   	pop    %ebp
f0100744:	c3                   	ret    

f0100745 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	57                   	push   %edi
f0100749:	56                   	push   %esi
f010074a:	53                   	push   %ebx
f010074b:	83 ec 18             	sub    $0x18,%esp
f010074e:	e8 fc f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100753:	81 c3 b9 6b 01 00    	add    $0x16bb9,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 c9 cd fe ff    	lea    -0x13237(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 1e 27 00 00       	call   f0102e83 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010076e:	8d 83 48 ce fe ff    	lea    -0x131b8(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 09 27 00 00       	call   f0102e83 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 70 ce fe ff    	lea    -0x13190(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 ec 26 00 00       	call   f0102e83 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 19 3e 10 f0    	mov    $0xf0103e19,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 94 ce fe ff    	lea    -0x1316c(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 cf 26 00 00       	call   f0102e83 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 b8 ce fe ff    	lea    -0x13148(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 b2 26 00 00       	call   f0102e83 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 dc ce fe ff    	lea    -0x13124(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 95 26 00 00       	call   f0102e83 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 00 cf fe ff    	lea    -0x13100(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 7a 26 00 00       	call   f0102e83 <cprintf>
	return 0;
}
f0100809:	b8 00 00 00 00       	mov    $0x0,%eax
f010080e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100811:	5b                   	pop    %ebx
f0100812:	5e                   	pop    %esi
f0100813:	5f                   	pop    %edi
f0100814:	5d                   	pop    %ebp
f0100815:	c3                   	ret    

f0100816 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100816:	55                   	push   %ebp
f0100817:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100819:	b8 00 00 00 00       	mov    $0x0,%eax
f010081e:	5d                   	pop    %ebp
f010081f:	c3                   	ret    

f0100820 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100820:	55                   	push   %ebp
f0100821:	89 e5                	mov    %esp,%ebp
f0100823:	57                   	push   %edi
f0100824:	56                   	push   %esi
f0100825:	53                   	push   %ebx
f0100826:	83 ec 68             	sub    $0x68,%esp
f0100829:	e8 21 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010082e:	81 c3 de 6a 01 00    	add    $0x16ade,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 2c cf fe ff    	lea    -0x130d4(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 43 26 00 00       	call   f0102e83 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 50 cf fe ff    	lea    -0x130b0(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 35 26 00 00       	call   f0102e83 <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb e6 cd fe ff    	lea    -0x1321a(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 3c 31 00 00       	call   f01039a2 <strchr>
f0100866:	83 c4 10             	add    $0x10,%esp
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 08                	je     f0100875 <monitor+0x55>
			*buf++ = 0;
f010086d:	c6 06 00             	movb   $0x0,(%esi)
f0100870:	8d 76 01             	lea    0x1(%esi),%esi
f0100873:	eb 79                	jmp    f01008ee <monitor+0xce>
		if (*buf == 0)
f0100875:	80 3e 00             	cmpb   $0x0,(%esi)
f0100878:	74 7f                	je     f01008f9 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f010087a:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010087e:	74 0f                	je     f010088f <monitor+0x6f>
		argv[argc++] = buf;
f0100880:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100883:	8d 48 01             	lea    0x1(%eax),%ecx
f0100886:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100889:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010088d:	eb 44                	jmp    f01008d3 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010088f:	83 ec 08             	sub    $0x8,%esp
f0100892:	6a 10                	push   $0x10
f0100894:	8d 83 eb cd fe ff    	lea    -0x13215(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 e3 25 00 00       	call   f0102e83 <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 e2 cd fe ff    	lea    -0x1321e(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 b3 2e 00 00       	call   f010376a <readline>
f01008b7:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008b9:	83 c4 10             	add    $0x10,%esp
f01008bc:	85 c0                	test   %eax,%eax
f01008be:	74 ec                	je     f01008ac <monitor+0x8c>
	argv[argc] = 0;
f01008c0:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008c7:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01008ce:	eb 1e                	jmp    f01008ee <monitor+0xce>
			buf++;
f01008d0:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d3:	0f b6 06             	movzbl (%esi),%eax
f01008d6:	84 c0                	test   %al,%al
f01008d8:	74 14                	je     f01008ee <monitor+0xce>
f01008da:	83 ec 08             	sub    $0x8,%esp
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	50                   	push   %eax
f01008e1:	57                   	push   %edi
f01008e2:	e8 bb 30 00 00       	call   f01039a2 <strchr>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 e2                	je     f01008d0 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f01008ee:	0f b6 06             	movzbl (%esi),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	0f 85 60 ff ff ff    	jne    f0100859 <monitor+0x39>
	argv[argc] = 0;
f01008f9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01008fc:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100903:	00 
	if (argc == 0)
f0100904:	85 c0                	test   %eax,%eax
f0100906:	74 9b                	je     f01008a3 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	8d 83 b2 cd fe ff    	lea    -0x1324e(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 2a 30 00 00       	call   f0103944 <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 c0 cd fe ff    	lea    -0x13240(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 11 30 00 00       	call   f0103944 <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 08 ce fe ff    	lea    -0x131f8(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 37 25 00 00       	call   f0102e83 <cprintf>
f010094c:	83 c4 10             	add    $0x10,%esp
f010094f:	e9 4f ff ff ff       	jmp    f01008a3 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100954:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100959:	83 ec 04             	sub    $0x4,%esp
f010095c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010095f:	ff 75 08             	pushl  0x8(%ebp)
f0100962:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100965:	52                   	push   %edx
f0100966:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100969:	ff 94 83 0c 1d 00 00 	call   *0x1d0c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100970:	83 c4 10             	add    $0x10,%esp
f0100973:	85 c0                	test   %eax,%eax
f0100975:	0f 89 28 ff ff ff    	jns    f01008a3 <monitor+0x83>
				break;
	}
}
f010097b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
f0100986:	53                   	push   %ebx
f0100987:	e8 64 24 00 00       	call   f0102df0 <__x86.get_pc_thunk.dx>
f010098c:	81 c2 80 69 01 00    	add    $0x16980,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100992:	83 ba 8c 1f 00 00 00 	cmpl   $0x0,0x1f8c(%edx)
f0100999:	74 1e                	je     f01009b9 <boot_alloc+0x36>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010099b:	8b 9a 8c 1f 00 00    	mov    0x1f8c(%edx),%ebx
	nextfree = ROUNDUP( (char*)(nextfree + n), PGSIZE);
f01009a1:	8d 8c 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%ecx
f01009a8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01009ae:	89 8a 8c 1f 00 00    	mov    %ecx,0x1f8c(%edx)
	return result;
}
f01009b4:	89 d8                	mov    %ebx,%eax
f01009b6:	5b                   	pop    %ebx
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009b9:	c7 c1 c0 96 11 f0    	mov    $0xf01196c0,%ecx
f01009bf:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f01009c5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01009cb:	89 8a 8c 1f 00 00    	mov    %ecx,0x1f8c(%edx)
f01009d1:	eb c8                	jmp    f010099b <boot_alloc+0x18>

f01009d3 <nvram_read>:
{
f01009d3:	55                   	push   %ebp
f01009d4:	89 e5                	mov    %esp,%ebp
f01009d6:	57                   	push   %edi
f01009d7:	56                   	push   %esi
f01009d8:	53                   	push   %ebx
f01009d9:	83 ec 18             	sub    $0x18,%esp
f01009dc:	e8 6e f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009e1:	81 c3 2b 69 01 00    	add    $0x1692b,%ebx
f01009e7:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009e9:	50                   	push   %eax
f01009ea:	e8 0d 24 00 00       	call   f0102dfc <mc146818_read>
f01009ef:	89 c6                	mov    %eax,%esi
f01009f1:	83 c7 01             	add    $0x1,%edi
f01009f4:	89 3c 24             	mov    %edi,(%esp)
f01009f7:	e8 00 24 00 00       	call   f0102dfc <mc146818_read>
f01009fc:	c1 e0 08             	shl    $0x8,%eax
f01009ff:	09 f0                	or     %esi,%eax
}
f0100a01:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a04:	5b                   	pop    %ebx
f0100a05:	5e                   	pop    %esi
f0100a06:	5f                   	pop    %edi
f0100a07:	5d                   	pop    %ebp
f0100a08:	c3                   	ret    

f0100a09 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a09:	55                   	push   %ebp
f0100a0a:	89 e5                	mov    %esp,%ebp
f0100a0c:	56                   	push   %esi
f0100a0d:	53                   	push   %ebx
f0100a0e:	e8 e1 23 00 00       	call   f0102df4 <__x86.get_pc_thunk.cx>
f0100a13:	81 c1 f9 68 01 00    	add    $0x168f9,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a19:	89 d3                	mov    %edx,%ebx
f0100a1b:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a1e:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a21:	a8 01                	test   $0x1,%al
f0100a23:	74 5a                	je     f0100a7f <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a2a:	89 c6                	mov    %eax,%esi
f0100a2c:	c1 ee 0c             	shr    $0xc,%esi
f0100a2f:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100a35:	3b 33                	cmp    (%ebx),%esi
f0100a37:	73 2b                	jae    f0100a64 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a39:	c1 ea 0c             	shr    $0xc,%edx
f0100a3c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a42:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a49:	89 c2                	mov    %eax,%edx
f0100a4b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a4e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a53:	85 d2                	test   %edx,%edx
f0100a55:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a5a:	0f 44 c2             	cmove  %edx,%eax
}
f0100a5d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a60:	5b                   	pop    %ebx
f0100a61:	5e                   	pop    %esi
f0100a62:	5d                   	pop    %ebp
f0100a63:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a64:	50                   	push   %eax
f0100a65:	8d 81 78 cf fe ff    	lea    -0x13088(%ecx),%eax
f0100a6b:	50                   	push   %eax
f0100a6c:	68 d9 02 00 00       	push   $0x2d9
f0100a71:	8d 81 f0 d6 fe ff    	lea    -0x12910(%ecx),%eax
f0100a77:	50                   	push   %eax
f0100a78:	89 cb                	mov    %ecx,%ebx
f0100a7a:	e8 1a f6 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100a7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100a84:	eb d7                	jmp    f0100a5d <check_va2pa+0x54>

f0100a86 <check_page_free_list>:
{
f0100a86:	55                   	push   %ebp
f0100a87:	89 e5                	mov    %esp,%ebp
f0100a89:	57                   	push   %edi
f0100a8a:	56                   	push   %esi
f0100a8b:	53                   	push   %ebx
f0100a8c:	83 ec 3c             	sub    $0x3c,%esp
f0100a8f:	e8 64 23 00 00       	call   f0102df8 <__x86.get_pc_thunk.di>
f0100a94:	81 c7 78 68 01 00    	add    $0x16878,%edi
f0100a9a:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a9d:	84 c0                	test   %al,%al
f0100a9f:	0f 85 dd 02 00 00    	jne    f0100d82 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100aa5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100aa8:	83 b8 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%eax)
f0100aaf:	74 0c                	je     f0100abd <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab1:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100ab8:	e9 2f 03 00 00       	jmp    f0100dec <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100abd:	83 ec 04             	sub    $0x4,%esp
f0100ac0:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ac3:	8d 83 9c cf fe ff    	lea    -0x13064(%ebx),%eax
f0100ac9:	50                   	push   %eax
f0100aca:	68 1a 02 00 00       	push   $0x21a
f0100acf:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100ad5:	50                   	push   %eax
f0100ad6:	e8 be f5 ff ff       	call   f0100099 <_panic>
f0100adb:	50                   	push   %eax
f0100adc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100adf:	8d 83 78 cf fe ff    	lea    -0x13088(%ebx),%eax
f0100ae5:	50                   	push   %eax
f0100ae6:	6a 52                	push   $0x52
f0100ae8:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0100aee:	50                   	push   %eax
f0100aef:	e8 a5 f5 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af4:	8b 36                	mov    (%esi),%esi
f0100af6:	85 f6                	test   %esi,%esi
f0100af8:	74 40                	je     f0100b3a <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100afa:	89 f0                	mov    %esi,%eax
f0100afc:	2b 07                	sub    (%edi),%eax
f0100afe:	c1 f8 03             	sar    $0x3,%eax
f0100b01:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b04:	89 c2                	mov    %eax,%edx
f0100b06:	c1 ea 16             	shr    $0x16,%edx
f0100b09:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100b0c:	73 e6                	jae    f0100af4 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100b0e:	89 c2                	mov    %eax,%edx
f0100b10:	c1 ea 0c             	shr    $0xc,%edx
f0100b13:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100b16:	3b 11                	cmp    (%ecx),%edx
f0100b18:	73 c1                	jae    f0100adb <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100b1a:	83 ec 04             	sub    $0x4,%esp
f0100b1d:	68 80 00 00 00       	push   $0x80
f0100b22:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100b27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b2c:	50                   	push   %eax
f0100b2d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b30:	e8 aa 2e 00 00       	call   f01039df <memset>
f0100b35:	83 c4 10             	add    $0x10,%esp
f0100b38:	eb ba                	jmp    f0100af4 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100b3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b3f:	e8 3f fe ff ff       	call   f0100983 <boot_alloc>
f0100b44:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b47:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b4a:	8b 97 90 1f 00 00    	mov    0x1f90(%edi),%edx
		assert(pp >= pages);
f0100b50:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100b56:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100b58:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100b5e:	8b 00                	mov    (%eax),%eax
f0100b60:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b63:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b66:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b69:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b6e:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b71:	e9 08 01 00 00       	jmp    f0100c7e <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100b76:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b79:	8d 83 0a d7 fe ff    	lea    -0x128f6(%ebx),%eax
f0100b7f:	50                   	push   %eax
f0100b80:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100b86:	50                   	push   %eax
f0100b87:	68 34 02 00 00       	push   $0x234
f0100b8c:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100b92:	50                   	push   %eax
f0100b93:	e8 01 f5 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100b98:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b9b:	8d 83 2b d7 fe ff    	lea    -0x128d5(%ebx),%eax
f0100ba1:	50                   	push   %eax
f0100ba2:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100ba8:	50                   	push   %eax
f0100ba9:	68 35 02 00 00       	push   $0x235
f0100bae:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100bb4:	50                   	push   %eax
f0100bb5:	e8 df f4 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bba:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bbd:	8d 83 c0 cf fe ff    	lea    -0x13040(%ebx),%eax
f0100bc3:	50                   	push   %eax
f0100bc4:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100bca:	50                   	push   %eax
f0100bcb:	68 36 02 00 00       	push   $0x236
f0100bd0:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100bd6:	50                   	push   %eax
f0100bd7:	e8 bd f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100bdc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bdf:	8d 83 3f d7 fe ff    	lea    -0x128c1(%ebx),%eax
f0100be5:	50                   	push   %eax
f0100be6:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100bec:	50                   	push   %eax
f0100bed:	68 39 02 00 00       	push   $0x239
f0100bf2:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100bf8:	50                   	push   %eax
f0100bf9:	e8 9b f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bfe:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c01:	8d 83 50 d7 fe ff    	lea    -0x128b0(%ebx),%eax
f0100c07:	50                   	push   %eax
f0100c08:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100c0e:	50                   	push   %eax
f0100c0f:	68 3a 02 00 00       	push   $0x23a
f0100c14:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100c1a:	50                   	push   %eax
f0100c1b:	e8 79 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c20:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c23:	8d 83 f4 cf fe ff    	lea    -0x1300c(%ebx),%eax
f0100c29:	50                   	push   %eax
f0100c2a:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100c30:	50                   	push   %eax
f0100c31:	68 3b 02 00 00       	push   $0x23b
f0100c36:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100c3c:	50                   	push   %eax
f0100c3d:	e8 57 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c42:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c45:	8d 83 69 d7 fe ff    	lea    -0x12897(%ebx),%eax
f0100c4b:	50                   	push   %eax
f0100c4c:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100c52:	50                   	push   %eax
f0100c53:	68 3c 02 00 00       	push   $0x23c
f0100c58:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100c5e:	50                   	push   %eax
f0100c5f:	e8 35 f4 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100c64:	89 c6                	mov    %eax,%esi
f0100c66:	c1 ee 0c             	shr    $0xc,%esi
f0100c69:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100c6c:	76 70                	jbe    f0100cde <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100c6e:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100c73:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100c76:	77 7f                	ja     f0100cf7 <check_page_free_list+0x271>
			++nfree_extmem;
f0100c78:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7c:	8b 12                	mov    (%edx),%edx
f0100c7e:	85 d2                	test   %edx,%edx
f0100c80:	0f 84 93 00 00 00    	je     f0100d19 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100c86:	39 d1                	cmp    %edx,%ecx
f0100c88:	0f 87 e8 fe ff ff    	ja     f0100b76 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100c8e:	39 d3                	cmp    %edx,%ebx
f0100c90:	0f 86 02 ff ff ff    	jbe    f0100b98 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c96:	89 d0                	mov    %edx,%eax
f0100c98:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c9b:	a8 07                	test   $0x7,%al
f0100c9d:	0f 85 17 ff ff ff    	jne    f0100bba <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100ca3:	c1 f8 03             	sar    $0x3,%eax
f0100ca6:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100ca9:	85 c0                	test   %eax,%eax
f0100cab:	0f 84 2b ff ff ff    	je     f0100bdc <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cb1:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cb6:	0f 84 42 ff ff ff    	je     f0100bfe <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cbc:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cc1:	0f 84 59 ff ff ff    	je     f0100c20 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc7:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ccc:	0f 84 70 ff ff ff    	je     f0100c42 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cd2:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cd7:	77 8b                	ja     f0100c64 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100cd9:	83 c7 01             	add    $0x1,%edi
f0100cdc:	eb 9e                	jmp    f0100c7c <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cde:	50                   	push   %eax
f0100cdf:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ce2:	8d 83 78 cf fe ff    	lea    -0x13088(%ebx),%eax
f0100ce8:	50                   	push   %eax
f0100ce9:	6a 52                	push   $0x52
f0100ceb:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0100cf1:	50                   	push   %eax
f0100cf2:	e8 a2 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cfa:	8d 83 18 d0 fe ff    	lea    -0x12fe8(%ebx),%eax
f0100d00:	50                   	push   %eax
f0100d01:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	68 3d 02 00 00       	push   $0x23d
f0100d0d:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100d13:	50                   	push   %eax
f0100d14:	e8 80 f3 ff ff       	call   f0100099 <_panic>
f0100d19:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100d1c:	85 ff                	test   %edi,%edi
f0100d1e:	7e 1e                	jle    f0100d3e <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100d20:	85 f6                	test   %esi,%esi
f0100d22:	7e 3c                	jle    f0100d60 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100d24:	83 ec 0c             	sub    $0xc,%esp
f0100d27:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d2a:	8d 83 60 d0 fe ff    	lea    -0x12fa0(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	e8 4d 21 00 00       	call   f0102e83 <cprintf>
}
f0100d36:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d39:	5b                   	pop    %ebx
f0100d3a:	5e                   	pop    %esi
f0100d3b:	5f                   	pop    %edi
f0100d3c:	5d                   	pop    %ebp
f0100d3d:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100d3e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d41:	8d 83 83 d7 fe ff    	lea    -0x1287d(%ebx),%eax
f0100d47:	50                   	push   %eax
f0100d48:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100d4e:	50                   	push   %eax
f0100d4f:	68 45 02 00 00       	push   $0x245
f0100d54:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100d5a:	50                   	push   %eax
f0100d5b:	e8 39 f3 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100d60:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d63:	8d 83 95 d7 fe ff    	lea    -0x1286b(%ebx),%eax
f0100d69:	50                   	push   %eax
f0100d6a:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100d70:	50                   	push   %eax
f0100d71:	68 46 02 00 00       	push   $0x246
f0100d76:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0100d7c:	50                   	push   %eax
f0100d7d:	e8 17 f3 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100d82:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100d85:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0100d8b:	85 c0                	test   %eax,%eax
f0100d8d:	0f 84 2a fd ff ff    	je     f0100abd <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d93:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100d96:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100d99:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d9c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100d9f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100da2:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100da8:	89 c2                	mov    %eax,%edx
f0100daa:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100dac:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100db2:	0f 95 c2             	setne  %dl
f0100db5:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100db8:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100dbc:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100dbe:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dc2:	8b 00                	mov    (%eax),%eax
f0100dc4:	85 c0                	test   %eax,%eax
f0100dc6:	75 e0                	jne    f0100da8 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100dc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dcb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100dd1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dd4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dd7:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100dd9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ddc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ddf:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100de5:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dec:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100def:	8b b0 90 1f 00 00    	mov    0x1f90(%eax),%esi
f0100df5:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100dfb:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100e01:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e04:	e9 ed fc ff ff       	jmp    f0100af6 <check_page_free_list+0x70>

f0100e09 <page_init>:
{
f0100e09:	55                   	push   %ebp
f0100e0a:	89 e5                	mov    %esp,%ebp
f0100e0c:	57                   	push   %edi
f0100e0d:	56                   	push   %esi
f0100e0e:	53                   	push   %ebx
f0100e0f:	83 ec 20             	sub    $0x20,%esp
f0100e12:	e8 38 f3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100e17:	81 c3 f5 64 01 00    	add    $0x164f5,%ebx
	page_free_list = NULL;
f0100e1d:	c7 83 90 1f 00 00 00 	movl   $0x0,0x1f90(%ebx)
f0100e24:	00 00 00 
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100e27:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2c:	e8 52 fb ff ff       	call   f0100983 <boot_alloc>
f0100e31:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e36:	c1 e8 0c             	shr    $0xc,%eax
f0100e39:	89 45 e0             	mov    %eax,-0x20(%ebp)
		else if(i >= 1 && i < npages_basemem)
f0100e3c:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100e42:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < npages; i++) {
f0100e45:	be 00 00 00 00       	mov    $0x0,%esi
f0100e4a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f0100e51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e56:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
			pages[i].pp_ref = 0;
f0100e5c:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
f0100e62:	89 7d dc             	mov    %edi,-0x24(%ebp)
			 pages[i].pp_ref = 1; 
f0100e65:	89 7d d8             	mov    %edi,-0x28(%ebp)
			pages[i].pp_ref = 1;
f0100e68:	89 7d e4             	mov    %edi,-0x1c(%ebp)
			pages[i].pp_ref = 0;
f0100e6b:	89 7d e8             	mov    %edi,-0x18(%ebp)
	for (i = 0; i < npages; i++) {
f0100e6e:	eb 2e                	jmp    f0100e9e <page_init+0x95>
		else if(i >= 1 && i < npages_basemem)
f0100e70:	39 45 ec             	cmp    %eax,-0x14(%ebp)
f0100e73:	76 41                	jbe    f0100eb6 <page_init+0xad>
f0100e75:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
			pages[i].pp_ref = 0;
f0100e7c:	89 ce                	mov    %ecx,%esi
f0100e7e:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100e81:	03 37                	add    (%edi),%esi
f0100e83:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list; 
f0100e89:	8b 7d f0             	mov    -0x10(%ebp),%edi
f0100e8c:	89 3e                	mov    %edi,(%esi)
			page_free_list = &pages[i];
f0100e8e:	8b 75 e8             	mov    -0x18(%ebp),%esi
f0100e91:	03 0e                	add    (%esi),%ecx
f0100e93:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100e96:	be 01 00 00 00       	mov    $0x1,%esi
	for (i = 0; i < npages; i++) {
f0100e9b:	83 c0 01             	add    $0x1,%eax
f0100e9e:	39 02                	cmp    %eax,(%edx)
f0100ea0:	76 70                	jbe    f0100f12 <page_init+0x109>
		if(i == 0)
f0100ea2:	85 c0                	test   %eax,%eax
f0100ea4:	75 ca                	jne    f0100e70 <page_init+0x67>
			pages[i].pp_ref = 1;
f0100ea6:	c7 c1 d0 96 11 f0    	mov    $0xf01196d0,%ecx
f0100eac:	8b 09                	mov    (%ecx),%ecx
f0100eae:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
f0100eb4:	eb e5                	jmp    f0100e9b <page_init+0x92>
		else if(i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE )
f0100eb6:	8d 88 60 ff ff ff    	lea    -0xa0(%eax),%ecx
f0100ebc:	83 f9 5f             	cmp    $0x5f,%ecx
f0100ebf:	77 0e                	ja     f0100ecf <page_init+0xc6>
			pages[i].pp_ref = 1;
f0100ec1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ec4:	8b 0f                	mov    (%edi),%ecx
f0100ec6:	66 c7 44 c1 04 01 00 	movw   $0x1,0x4(%ecx,%eax,8)
f0100ecd:	eb cc                	jmp    f0100e9b <page_init+0x92>
		else if( i >= EXTPHYSMEM / PGSIZE && i < num_alloc)
f0100ecf:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100ed4:	76 13                	jbe    f0100ee9 <page_init+0xe0>
f0100ed6:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f0100ed9:	76 0e                	jbe    f0100ee9 <page_init+0xe0>
			 pages[i].pp_ref = 1; 
f0100edb:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100ede:	8b 0f                	mov    (%edi),%ecx
f0100ee0:	66 c7 44 c1 04 01 00 	movw   $0x1,0x4(%ecx,%eax,8)
f0100ee7:	eb b2                	jmp    f0100e9b <page_init+0x92>
f0100ee9:	8d 34 c5 00 00 00 00 	lea    0x0(,%eax,8),%esi
			pages[i].pp_ref = 0;
f0100ef0:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ef3:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100ef6:	03 37                	add    (%edi),%esi
f0100ef8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
			pages[i].pp_link = page_free_list; 
f0100efe:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100f01:	89 0e                	mov    %ecx,(%esi)
			page_free_list = &pages[i];
f0100f03:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100f06:	03 0f                	add    (%edi),%ecx
f0100f08:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100f0b:	be 01 00 00 00       	mov    $0x1,%esi
f0100f10:	eb 89                	jmp    f0100e9b <page_init+0x92>
f0100f12:	89 f0                	mov    %esi,%eax
f0100f14:	84 c0                	test   %al,%al
f0100f16:	75 08                	jne    f0100f20 <page_init+0x117>
}
f0100f18:	83 c4 20             	add    $0x20,%esp
f0100f1b:	5b                   	pop    %ebx
f0100f1c:	5e                   	pop    %esi
f0100f1d:	5f                   	pop    %edi
f0100f1e:	5d                   	pop    %ebp
f0100f1f:	c3                   	ret    
f0100f20:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f23:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
f0100f29:	eb ed                	jmp    f0100f18 <page_init+0x10f>

f0100f2b <page_alloc>:
{
f0100f2b:	55                   	push   %ebp
f0100f2c:	89 e5                	mov    %esp,%ebp
f0100f2e:	56                   	push   %esi
f0100f2f:	53                   	push   %ebx
f0100f30:	e8 1a f2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f35:	81 c3 d7 63 01 00    	add    $0x163d7,%ebx
    if (page_free_list == NULL)
f0100f3b:	8b b3 90 1f 00 00    	mov    0x1f90(%ebx),%esi
f0100f41:	85 f6                	test   %esi,%esi
f0100f43:	74 14                	je     f0100f59 <page_alloc+0x2e>
	page_free_list = result->pp_link;
f0100f45:	8b 06                	mov    (%esi),%eax
f0100f47:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
	result->pp_link = NULL;
f0100f4d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
    if (alloc_flags & ALLOC_ZERO)
f0100f53:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f57:	75 09                	jne    f0100f62 <page_alloc+0x37>
}
f0100f59:	89 f0                	mov    %esi,%eax
f0100f5b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100f5e:	5b                   	pop    %ebx
f0100f5f:	5e                   	pop    %esi
f0100f60:	5d                   	pop    %ebp
f0100f61:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0100f62:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f68:	89 f2                	mov    %esi,%edx
f0100f6a:	2b 10                	sub    (%eax),%edx
f0100f6c:	89 d0                	mov    %edx,%eax
f0100f6e:	c1 f8 03             	sar    $0x3,%eax
f0100f71:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100f74:	89 c1                	mov    %eax,%ecx
f0100f76:	c1 e9 0c             	shr    $0xc,%ecx
f0100f79:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0100f7f:	3b 0a                	cmp    (%edx),%ecx
f0100f81:	73 1a                	jae    f0100f9d <page_alloc+0x72>
        memset(page2kva(result), 0, PGSIZE);
f0100f83:	83 ec 04             	sub    $0x4,%esp
f0100f86:	68 00 10 00 00       	push   $0x1000
f0100f8b:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100f8d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f92:	50                   	push   %eax
f0100f93:	e8 47 2a 00 00       	call   f01039df <memset>
f0100f98:	83 c4 10             	add    $0x10,%esp
f0100f9b:	eb bc                	jmp    f0100f59 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f9d:	50                   	push   %eax
f0100f9e:	8d 83 78 cf fe ff    	lea    -0x13088(%ebx),%eax
f0100fa4:	50                   	push   %eax
f0100fa5:	6a 52                	push   $0x52
f0100fa7:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0100fad:	50                   	push   %eax
f0100fae:	e8 e6 f0 ff ff       	call   f0100099 <_panic>

f0100fb3 <page_free>:
{
f0100fb3:	55                   	push   %ebp
f0100fb4:	89 e5                	mov    %esp,%ebp
f0100fb6:	53                   	push   %ebx
f0100fb7:	83 ec 04             	sub    $0x4,%esp
f0100fba:	e8 90 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100fbf:	81 c3 4d 63 01 00    	add    $0x1634d,%ebx
f0100fc5:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);
f0100fc8:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fcd:	75 18                	jne    f0100fe7 <page_free+0x34>
	assert(pp->pp_link == NULL);
f0100fcf:	83 38 00             	cmpl   $0x0,(%eax)
f0100fd2:	75 32                	jne    f0101006 <page_free+0x53>
	pp->pp_link = page_free_list;
f0100fd4:	8b 8b 90 1f 00 00    	mov    0x1f90(%ebx),%ecx
f0100fda:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0100fdc:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
}
f0100fe2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fe5:	c9                   	leave  
f0100fe6:	c3                   	ret    
	assert(pp->pp_ref == 0);
f0100fe7:	8d 83 a6 d7 fe ff    	lea    -0x1285a(%ebx),%eax
f0100fed:	50                   	push   %eax
f0100fee:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0100ff4:	50                   	push   %eax
f0100ff5:	68 44 01 00 00       	push   $0x144
f0100ffa:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f0101000:	50                   	push   %eax
f0101001:	e8 93 f0 ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL);
f0101006:	8d 83 b6 d7 fe ff    	lea    -0x1284a(%ebx),%eax
f010100c:	50                   	push   %eax
f010100d:	8d 83 16 d7 fe ff    	lea    -0x128ea(%ebx),%eax
f0101013:	50                   	push   %eax
f0101014:	68 45 01 00 00       	push   $0x145
f0101019:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f010101f:	50                   	push   %eax
f0101020:	e8 74 f0 ff ff       	call   f0100099 <_panic>

f0101025 <page_decref>:
{
f0101025:	55                   	push   %ebp
f0101026:	89 e5                	mov    %esp,%ebp
f0101028:	83 ec 08             	sub    $0x8,%esp
f010102b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010102e:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0101032:	83 e8 01             	sub    $0x1,%eax
f0101035:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101039:	66 85 c0             	test   %ax,%ax
f010103c:	74 02                	je     f0101040 <page_decref+0x1b>
}
f010103e:	c9                   	leave  
f010103f:	c3                   	ret    
		page_free(pp);
f0101040:	83 ec 0c             	sub    $0xc,%esp
f0101043:	52                   	push   %edx
f0101044:	e8 6a ff ff ff       	call   f0100fb3 <page_free>
f0101049:	83 c4 10             	add    $0x10,%esp
}
f010104c:	eb f0                	jmp    f010103e <page_decref+0x19>

f010104e <pgdir_walk>:
{
f010104e:	55                   	push   %ebp
f010104f:	89 e5                	mov    %esp,%ebp
f0101051:	57                   	push   %edi
f0101052:	56                   	push   %esi
f0101053:	53                   	push   %ebx
f0101054:	83 ec 0c             	sub    $0xc,%esp
f0101057:	e8 f3 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010105c:	81 c3 b0 62 01 00    	add    $0x162b0,%ebx
f0101062:	8b 7d 0c             	mov    0xc(%ebp),%edi
	unsigned int dic_off = PDX(va);
f0101065:	89 fe                	mov    %edi,%esi
f0101067:	c1 ee 16             	shr    $0x16,%esi
	pde_t * dic_entry_ptr = pgdir + dic_off;
f010106a:	c1 e6 02             	shl    $0x2,%esi
f010106d:	03 75 08             	add    0x8(%ebp),%esi
	if(!(*dic_entry_ptr & PTE_P))
f0101070:	f6 06 01             	testb  $0x1,(%esi)
f0101073:	75 2f                	jne    f01010a4 <pgdir_walk+0x56>
		if(create)
f0101075:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101079:	74 70                	je     f01010eb <pgdir_walk+0x9d>
			struct PageInfo* new_page = page_alloc(1);
f010107b:	83 ec 0c             	sub    $0xc,%esp
f010107e:	6a 01                	push   $0x1
f0101080:	e8 a6 fe ff ff       	call   f0100f2b <page_alloc>
			if(new_page == NULL)
f0101085:	83 c4 10             	add    $0x10,%esp
f0101088:	85 c0                	test   %eax,%eax
f010108a:	74 66                	je     f01010f2 <pgdir_walk+0xa4>
			new_page->pp_ref++;
f010108c:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101091:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101097:	2b 02                	sub    (%edx),%eax
f0101099:	c1 f8 03             	sar    $0x3,%eax
f010109c:	c1 e0 0c             	shl    $0xc,%eax
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f010109f:	83 c8 07             	or     $0x7,%eax
f01010a2:	89 06                	mov    %eax,(%esi)
	pte_t * page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f01010a4:	8b 06                	mov    (%esi),%eax
f01010a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01010ab:	89 c1                	mov    %eax,%ecx
f01010ad:	c1 e9 0c             	shr    $0xc,%ecx
f01010b0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01010b6:	3b 0a                	cmp    (%edx),%ecx
f01010b8:	73 18                	jae    f01010d2 <pgdir_walk+0x84>
	unsigned int page_off = PTX(va);
f01010ba:	c1 ef 0a             	shr    $0xa,%edi
	return &page_base[page_off];		
f01010bd:	81 e7 fc 0f 00 00    	and    $0xffc,%edi
f01010c3:	8d 84 38 00 00 00 f0 	lea    -0x10000000(%eax,%edi,1),%eax
}
f01010ca:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010cd:	5b                   	pop    %ebx
f01010ce:	5e                   	pop    %esi
f01010cf:	5f                   	pop    %edi
f01010d0:	5d                   	pop    %ebp
f01010d1:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010d2:	50                   	push   %eax
f01010d3:	8d 83 78 cf fe ff    	lea    -0x13088(%ebx),%eax
f01010d9:	50                   	push   %eax
f01010da:	68 7d 01 00 00       	push   $0x17d
f01010df:	8d 83 f0 d6 fe ff    	lea    -0x12910(%ebx),%eax
f01010e5:	50                   	push   %eax
f01010e6:	e8 ae ef ff ff       	call   f0100099 <_panic>
		else return NULL;      
f01010eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f0:	eb d8                	jmp    f01010ca <pgdir_walk+0x7c>
				return NULL;
f01010f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f7:	eb d1                	jmp    f01010ca <pgdir_walk+0x7c>

f01010f9 <page_lookup>:
{
f01010f9:	55                   	push   %ebp
f01010fa:	89 e5                	mov    %esp,%ebp
f01010fc:	56                   	push   %esi
f01010fd:	53                   	push   %ebx
f01010fe:	e8 4c f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101103:	81 c3 09 62 01 00    	add    $0x16209,%ebx
f0101109:	8b 75 10             	mov    0x10(%ebp),%esi
    pte_t *entry = pgdir_walk(pgdir, va, 0);
f010110c:	83 ec 04             	sub    $0x4,%esp
f010110f:	6a 00                	push   $0x0
f0101111:	ff 75 0c             	pushl  0xc(%ebp)
f0101114:	ff 75 08             	pushl  0x8(%ebp)
f0101117:	e8 32 ff ff ff       	call   f010104e <pgdir_walk>
    if(entry == NULL)
f010111c:	83 c4 10             	add    $0x10,%esp
f010111f:	85 c0                	test   %eax,%eax
f0101121:	74 46                	je     f0101169 <page_lookup+0x70>
f0101123:	89 c1                	mov    %eax,%ecx
    if(!(*entry & PTE_P))
f0101125:	8b 10                	mov    (%eax),%edx
f0101127:	f6 c2 01             	test   $0x1,%dl
f010112a:	74 44                	je     f0101170 <page_lookup+0x77>
f010112c:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010112f:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101135:	39 10                	cmp    %edx,(%eax)
f0101137:	76 18                	jbe    f0101151 <page_lookup+0x58>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101139:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010113f:	8b 00                	mov    (%eax),%eax
f0101141:	8d 04 d0             	lea    (%eax,%edx,8),%eax
    if(pte_store != NULL)
f0101144:	85 f6                	test   %esi,%esi
f0101146:	74 02                	je     f010114a <page_lookup+0x51>
        *pte_store = entry;
f0101148:	89 0e                	mov    %ecx,(%esi)
}
f010114a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010114d:	5b                   	pop    %ebx
f010114e:	5e                   	pop    %esi
f010114f:	5d                   	pop    %ebp
f0101150:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101151:	83 ec 04             	sub    $0x4,%esp
f0101154:	8d 83 84 d0 fe ff    	lea    -0x12f7c(%ebx),%eax
f010115a:	50                   	push   %eax
f010115b:	6a 4b                	push   $0x4b
f010115d:	8d 83 fc d6 fe ff    	lea    -0x12904(%ebx),%eax
f0101163:	50                   	push   %eax
f0101164:	e8 30 ef ff ff       	call   f0100099 <_panic>
        return NULL;
f0101169:	b8 00 00 00 00       	mov    $0x0,%eax
f010116e:	eb da                	jmp    f010114a <page_lookup+0x51>
        return NULL;
f0101170:	b8 00 00 00 00       	mov    $0x0,%eax
f0101175:	eb d3                	jmp    f010114a <page_lookup+0x51>

f0101177 <page_remove>:
{
f0101177:	55                   	push   %ebp
f0101178:	89 e5                	mov    %esp,%ebp
f010117a:	53                   	push   %ebx
f010117b:	83 ec 18             	sub    $0x18,%esp
f010117e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    pte_t *pte = NULL;
f0101181:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0101188:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010118b:	50                   	push   %eax
f010118c:	53                   	push   %ebx
f010118d:	ff 75 08             	pushl  0x8(%ebp)
f0101190:	e8 64 ff ff ff       	call   f01010f9 <page_lookup>
    if(page == NULL)
f0101195:	83 c4 10             	add    $0x10,%esp
f0101198:	85 c0                	test   %eax,%eax
f010119a:	75 05                	jne    f01011a1 <page_remove+0x2a>
}
f010119c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010119f:	c9                   	leave  
f01011a0:	c3                   	ret    
    page_decref(page);
f01011a1:	83 ec 0c             	sub    $0xc,%esp
f01011a4:	50                   	push   %eax
f01011a5:	e8 7b fe ff ff       	call   f0101025 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011aa:	0f 01 3b             	invlpg (%ebx)
    *pte = 0;
f01011ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f01011b6:	83 c4 10             	add    $0x10,%esp
f01011b9:	eb e1                	jmp    f010119c <page_remove+0x25>

f01011bb <page_insert>:
{
f01011bb:	55                   	push   %ebp
f01011bc:	89 e5                	mov    %esp,%ebp
f01011be:	57                   	push   %edi
f01011bf:	56                   	push   %esi
f01011c0:	53                   	push   %ebx
f01011c1:	83 ec 10             	sub    $0x10,%esp
f01011c4:	e8 2f 1c 00 00       	call   f0102df8 <__x86.get_pc_thunk.di>
f01011c9:	81 c7 43 61 01 00    	add    $0x16143,%edi
f01011cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
    pte_t *entry = pgdir_walk(pgdir, va, 1);
f01011d2:	6a 01                	push   $0x1
f01011d4:	ff 75 10             	pushl  0x10(%ebp)
f01011d7:	53                   	push   %ebx
f01011d8:	e8 71 fe ff ff       	call   f010104e <pgdir_walk>
    if(entry == NULL)
f01011dd:	83 c4 10             	add    $0x10,%esp
f01011e0:	85 c0                	test   %eax,%eax
f01011e2:	74 5c                	je     f0101240 <page_insert+0x85>
f01011e4:	89 c6                	mov    %eax,%esi
    pp->pp_ref++;
f01011e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011e9:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
    if((*entry) & PTE_P)
f01011ee:	f6 06 01             	testb  $0x1,(%esi)
f01011f1:	75 36                	jne    f0101229 <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f01011f3:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01011f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01011fc:	2b 08                	sub    (%eax),%ecx
f01011fe:	89 c8                	mov    %ecx,%eax
f0101200:	c1 f8 03             	sar    $0x3,%eax
f0101203:	c1 e0 0c             	shl    $0xc,%eax
    *entry = (page2pa(pp) | perm | PTE_P);
f0101206:	8b 55 14             	mov    0x14(%ebp),%edx
f0101209:	83 ca 01             	or     $0x1,%edx
f010120c:	09 d0                	or     %edx,%eax
f010120e:	89 06                	mov    %eax,(%esi)
    pgdir[PDX(va)] |= perm;
f0101210:	8b 45 10             	mov    0x10(%ebp),%eax
f0101213:	c1 e8 16             	shr    $0x16,%eax
f0101216:	8b 7d 14             	mov    0x14(%ebp),%edi
f0101219:	09 3c 83             	or     %edi,(%ebx,%eax,4)
    return 0;
f010121c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101221:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101224:	5b                   	pop    %ebx
f0101225:	5e                   	pop    %esi
f0101226:	5f                   	pop    %edi
f0101227:	5d                   	pop    %ebp
f0101228:	c3                   	ret    
f0101229:	8b 45 10             	mov    0x10(%ebp),%eax
f010122c:	0f 01 38             	invlpg (%eax)
        page_remove(pgdir, va);
f010122f:	83 ec 08             	sub    $0x8,%esp
f0101232:	ff 75 10             	pushl  0x10(%ebp)
f0101235:	53                   	push   %ebx
f0101236:	e8 3c ff ff ff       	call   f0101177 <page_remove>
f010123b:	83 c4 10             	add    $0x10,%esp
f010123e:	eb b3                	jmp    f01011f3 <page_insert+0x38>
		return -E_NO_MEM;
f0101240:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101245:	eb da                	jmp    f0101221 <page_insert+0x66>

f0101247 <mem_init>:
{
f0101247:	55                   	push   %ebp
f0101248:	89 e5                	mov    %esp,%ebp
f010124a:	57                   	push   %edi
f010124b:	56                   	push   %esi
f010124c:	53                   	push   %ebx
f010124d:	83 ec 3c             	sub    $0x3c,%esp
f0101250:	e8 a3 1b 00 00       	call   f0102df8 <__x86.get_pc_thunk.di>
f0101255:	81 c7 b7 60 01 00    	add    $0x160b7,%edi
	basemem = nvram_read(NVRAM_BASELO);
f010125b:	b8 15 00 00 00       	mov    $0x15,%eax
f0101260:	e8 6e f7 ff ff       	call   f01009d3 <nvram_read>
f0101265:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101267:	b8 17 00 00 00       	mov    $0x17,%eax
f010126c:	e8 62 f7 ff ff       	call   f01009d3 <nvram_read>
f0101271:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101273:	b8 34 00 00 00       	mov    $0x34,%eax
f0101278:	e8 56 f7 ff ff       	call   f01009d3 <nvram_read>
f010127d:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0101280:	85 c0                	test   %eax,%eax
f0101282:	0f 85 c4 00 00 00    	jne    f010134c <mem_init+0x105>
		totalmem = 1 * 1024 + extmem;
f0101288:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010128e:	85 f6                	test   %esi,%esi
f0101290:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101293:	89 c1                	mov    %eax,%ecx
f0101295:	c1 e9 02             	shr    $0x2,%ecx
f0101298:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010129e:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01012a0:	89 da                	mov    %ebx,%edx
f01012a2:	c1 ea 02             	shr    $0x2,%edx
f01012a5:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01012ab:	89 c2                	mov    %eax,%edx
f01012ad:	29 da                	sub    %ebx,%edx
f01012af:	52                   	push   %edx
f01012b0:	53                   	push   %ebx
f01012b1:	50                   	push   %eax
f01012b2:	8d 87 a4 d0 fe ff    	lea    -0x12f5c(%edi),%eax
f01012b8:	50                   	push   %eax
f01012b9:	89 fb                	mov    %edi,%ebx
f01012bb:	e8 c3 1b 00 00       	call   f0102e83 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01012c0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01012c5:	e8 b9 f6 ff ff       	call   f0100983 <boot_alloc>
f01012ca:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01012d0:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01012d2:	83 c4 0c             	add    $0xc,%esp
f01012d5:	68 00 10 00 00       	push   $0x1000
f01012da:	6a 00                	push   $0x0
f01012dc:	50                   	push   %eax
f01012dd:	e8 fd 26 00 00       	call   f01039df <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012e2:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01012e4:	83 c4 10             	add    $0x10,%esp
f01012e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012ec:	76 68                	jbe    f0101356 <mem_init+0x10f>
	return (physaddr_t)kva - KERNBASE;
f01012ee:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012f4:	83 ca 05             	or     $0x5,%edx
f01012f7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01012fd:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0101303:	8b 03                	mov    (%ebx),%eax
f0101305:	c1 e0 03             	shl    $0x3,%eax
f0101308:	e8 76 f6 ff ff       	call   f0100983 <boot_alloc>
f010130d:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0101313:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101315:	83 ec 04             	sub    $0x4,%esp
f0101318:	8b 13                	mov    (%ebx),%edx
f010131a:	c1 e2 03             	shl    $0x3,%edx
f010131d:	52                   	push   %edx
f010131e:	6a 00                	push   $0x0
f0101320:	50                   	push   %eax
f0101321:	89 fb                	mov    %edi,%ebx
f0101323:	e8 b7 26 00 00       	call   f01039df <memset>
	page_init();
f0101328:	e8 dc fa ff ff       	call   f0100e09 <page_init>
	check_page_free_list(1);
f010132d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101332:	e8 4f f7 ff ff       	call   f0100a86 <check_page_free_list>
	if (!pages)
f0101337:	83 c4 10             	add    $0x10,%esp
f010133a:	83 3e 00             	cmpl   $0x0,(%esi)
f010133d:	74 30                	je     f010136f <mem_init+0x128>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010133f:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f0101345:	be 00 00 00 00       	mov    $0x0,%esi
f010134a:	eb 43                	jmp    f010138f <mem_init+0x148>
		totalmem = 16 * 1024 + ext16mem;
f010134c:	05 00 40 00 00       	add    $0x4000,%eax
f0101351:	e9 3d ff ff ff       	jmp    f0101293 <mem_init+0x4c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101356:	50                   	push   %eax
f0101357:	8d 87 e0 d0 fe ff    	lea    -0x12f20(%edi),%eax
f010135d:	50                   	push   %eax
f010135e:	68 8f 00 00 00       	push   $0x8f
f0101363:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101369:	50                   	push   %eax
f010136a:	e8 2a ed ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f010136f:	83 ec 04             	sub    $0x4,%esp
f0101372:	8d 87 ca d7 fe ff    	lea    -0x12836(%edi),%eax
f0101378:	50                   	push   %eax
f0101379:	68 59 02 00 00       	push   $0x259
f010137e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101384:	50                   	push   %eax
f0101385:	e8 0f ed ff ff       	call   f0100099 <_panic>
		++nfree;
f010138a:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010138d:	8b 00                	mov    (%eax),%eax
f010138f:	85 c0                	test   %eax,%eax
f0101391:	75 f7                	jne    f010138a <mem_init+0x143>
	assert((pp0 = page_alloc(0)));
f0101393:	83 ec 0c             	sub    $0xc,%esp
f0101396:	6a 00                	push   $0x0
f0101398:	e8 8e fb ff ff       	call   f0100f2b <page_alloc>
f010139d:	89 c3                	mov    %eax,%ebx
f010139f:	83 c4 10             	add    $0x10,%esp
f01013a2:	85 c0                	test   %eax,%eax
f01013a4:	0f 84 3f 02 00 00    	je     f01015e9 <mem_init+0x3a2>
	assert((pp1 = page_alloc(0)));
f01013aa:	83 ec 0c             	sub    $0xc,%esp
f01013ad:	6a 00                	push   $0x0
f01013af:	e8 77 fb ff ff       	call   f0100f2b <page_alloc>
f01013b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013b7:	83 c4 10             	add    $0x10,%esp
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	0f 84 48 02 00 00    	je     f010160a <mem_init+0x3c3>
	assert((pp2 = page_alloc(0)));
f01013c2:	83 ec 0c             	sub    $0xc,%esp
f01013c5:	6a 00                	push   $0x0
f01013c7:	e8 5f fb ff ff       	call   f0100f2b <page_alloc>
f01013cc:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01013cf:	83 c4 10             	add    $0x10,%esp
f01013d2:	85 c0                	test   %eax,%eax
f01013d4:	0f 84 51 02 00 00    	je     f010162b <mem_init+0x3e4>
	assert(pp1 && pp1 != pp0);
f01013da:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01013dd:	0f 84 69 02 00 00    	je     f010164c <mem_init+0x405>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013e6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01013e9:	0f 84 7e 02 00 00    	je     f010166d <mem_init+0x426>
f01013ef:	39 c3                	cmp    %eax,%ebx
f01013f1:	0f 84 76 02 00 00    	je     f010166d <mem_init+0x426>
	return (pp - pages) << PGSHIFT;
f01013f7:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01013fd:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01013ff:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101405:	8b 10                	mov    (%eax),%edx
f0101407:	c1 e2 0c             	shl    $0xc,%edx
f010140a:	89 d8                	mov    %ebx,%eax
f010140c:	29 c8                	sub    %ecx,%eax
f010140e:	c1 f8 03             	sar    $0x3,%eax
f0101411:	c1 e0 0c             	shl    $0xc,%eax
f0101414:	39 d0                	cmp    %edx,%eax
f0101416:	0f 83 72 02 00 00    	jae    f010168e <mem_init+0x447>
f010141c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010141f:	29 c8                	sub    %ecx,%eax
f0101421:	c1 f8 03             	sar    $0x3,%eax
f0101424:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101427:	39 c2                	cmp    %eax,%edx
f0101429:	0f 86 80 02 00 00    	jbe    f01016af <mem_init+0x468>
f010142f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101432:	29 c8                	sub    %ecx,%eax
f0101434:	c1 f8 03             	sar    $0x3,%eax
f0101437:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010143a:	39 c2                	cmp    %eax,%edx
f010143c:	0f 86 8e 02 00 00    	jbe    f01016d0 <mem_init+0x489>
	fl = page_free_list;
f0101442:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f0101448:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f010144b:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f0101452:	00 00 00 
	assert(!page_alloc(0));
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 00                	push   $0x0
f010145a:	e8 cc fa ff ff       	call   f0100f2b <page_alloc>
f010145f:	83 c4 10             	add    $0x10,%esp
f0101462:	85 c0                	test   %eax,%eax
f0101464:	0f 85 87 02 00 00    	jne    f01016f1 <mem_init+0x4aa>
	page_free(pp0);
f010146a:	83 ec 0c             	sub    $0xc,%esp
f010146d:	53                   	push   %ebx
f010146e:	e8 40 fb ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f0101473:	83 c4 04             	add    $0x4,%esp
f0101476:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101479:	e8 35 fb ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f010147e:	83 c4 04             	add    $0x4,%esp
f0101481:	ff 75 d0             	pushl  -0x30(%ebp)
f0101484:	e8 2a fb ff ff       	call   f0100fb3 <page_free>
	assert((pp0 = page_alloc(0)));
f0101489:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101490:	e8 96 fa ff ff       	call   f0100f2b <page_alloc>
f0101495:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101498:	83 c4 10             	add    $0x10,%esp
f010149b:	85 c0                	test   %eax,%eax
f010149d:	0f 84 6f 02 00 00    	je     f0101712 <mem_init+0x4cb>
	assert((pp1 = page_alloc(0)));
f01014a3:	83 ec 0c             	sub    $0xc,%esp
f01014a6:	6a 00                	push   $0x0
f01014a8:	e8 7e fa ff ff       	call   f0100f2b <page_alloc>
f01014ad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014b0:	83 c4 10             	add    $0x10,%esp
f01014b3:	85 c0                	test   %eax,%eax
f01014b5:	0f 84 78 02 00 00    	je     f0101733 <mem_init+0x4ec>
	assert((pp2 = page_alloc(0)));
f01014bb:	83 ec 0c             	sub    $0xc,%esp
f01014be:	6a 00                	push   $0x0
f01014c0:	e8 66 fa ff ff       	call   f0100f2b <page_alloc>
f01014c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01014c8:	83 c4 10             	add    $0x10,%esp
f01014cb:	85 c0                	test   %eax,%eax
f01014cd:	0f 84 81 02 00 00    	je     f0101754 <mem_init+0x50d>
	assert(pp1 && pp1 != pp0);
f01014d3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01014d6:	39 4d d4             	cmp    %ecx,-0x2c(%ebp)
f01014d9:	0f 84 96 02 00 00    	je     f0101775 <mem_init+0x52e>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014df:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01014e2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01014e5:	0f 84 ab 02 00 00    	je     f0101796 <mem_init+0x54f>
f01014eb:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01014ee:	0f 84 a2 02 00 00    	je     f0101796 <mem_init+0x54f>
	assert(!page_alloc(0));
f01014f4:	83 ec 0c             	sub    $0xc,%esp
f01014f7:	6a 00                	push   $0x0
f01014f9:	e8 2d fa ff ff       	call   f0100f2b <page_alloc>
f01014fe:	83 c4 10             	add    $0x10,%esp
f0101501:	85 c0                	test   %eax,%eax
f0101503:	0f 85 ae 02 00 00    	jne    f01017b7 <mem_init+0x570>
f0101509:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010150f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101512:	2b 08                	sub    (%eax),%ecx
f0101514:	89 c8                	mov    %ecx,%eax
f0101516:	c1 f8 03             	sar    $0x3,%eax
f0101519:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010151c:	89 c1                	mov    %eax,%ecx
f010151e:	c1 e9 0c             	shr    $0xc,%ecx
f0101521:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101527:	3b 0a                	cmp    (%edx),%ecx
f0101529:	0f 83 a9 02 00 00    	jae    f01017d8 <mem_init+0x591>
	memset(page2kva(pp0), 1, PGSIZE);
f010152f:	83 ec 04             	sub    $0x4,%esp
f0101532:	68 00 10 00 00       	push   $0x1000
f0101537:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101539:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010153e:	50                   	push   %eax
f010153f:	89 fb                	mov    %edi,%ebx
f0101541:	e8 99 24 00 00       	call   f01039df <memset>
	page_free(pp0);
f0101546:	83 c4 04             	add    $0x4,%esp
f0101549:	ff 75 d4             	pushl  -0x2c(%ebp)
f010154c:	e8 62 fa ff ff       	call   f0100fb3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101551:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101558:	e8 ce f9 ff ff       	call   f0100f2b <page_alloc>
f010155d:	83 c4 10             	add    $0x10,%esp
f0101560:	85 c0                	test   %eax,%eax
f0101562:	0f 84 88 02 00 00    	je     f01017f0 <mem_init+0x5a9>
	assert(pp && pp0 == pp);
f0101568:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010156b:	0f 85 9e 02 00 00    	jne    f010180f <mem_init+0x5c8>
	return (pp - pages) << PGSHIFT;
f0101571:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101577:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010157a:	2b 10                	sub    (%eax),%edx
f010157c:	c1 fa 03             	sar    $0x3,%edx
f010157f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101582:	89 d1                	mov    %edx,%ecx
f0101584:	c1 e9 0c             	shr    $0xc,%ecx
f0101587:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010158d:	3b 08                	cmp    (%eax),%ecx
f010158f:	0f 83 99 02 00 00    	jae    f010182e <mem_init+0x5e7>
	return (void *)(pa + KERNBASE);
f0101595:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010159b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01015a1:	80 38 00             	cmpb   $0x0,(%eax)
f01015a4:	0f 85 9a 02 00 00    	jne    f0101844 <mem_init+0x5fd>
f01015aa:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01015ad:	39 d0                	cmp    %edx,%eax
f01015af:	75 f0                	jne    f01015a1 <mem_init+0x35a>
	page_free_list = fl;
f01015b1:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01015b4:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	page_free(pp0);
f01015ba:	83 ec 0c             	sub    $0xc,%esp
f01015bd:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015c0:	e8 ee f9 ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f01015c5:	83 c4 04             	add    $0x4,%esp
f01015c8:	ff 75 d0             	pushl  -0x30(%ebp)
f01015cb:	e8 e3 f9 ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f01015d0:	83 c4 04             	add    $0x4,%esp
f01015d3:	ff 75 cc             	pushl  -0x34(%ebp)
f01015d6:	e8 d8 f9 ff ff       	call   f0100fb3 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015db:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01015e1:	83 c4 10             	add    $0x10,%esp
f01015e4:	e9 81 02 00 00       	jmp    f010186a <mem_init+0x623>
	assert((pp0 = page_alloc(0)));
f01015e9:	8d 87 e5 d7 fe ff    	lea    -0x1281b(%edi),%eax
f01015ef:	50                   	push   %eax
f01015f0:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01015f6:	50                   	push   %eax
f01015f7:	68 61 02 00 00       	push   $0x261
f01015fc:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101602:	50                   	push   %eax
f0101603:	89 fb                	mov    %edi,%ebx
f0101605:	e8 8f ea ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010160a:	8d 87 fb d7 fe ff    	lea    -0x12805(%edi),%eax
f0101610:	50                   	push   %eax
f0101611:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101617:	50                   	push   %eax
f0101618:	68 62 02 00 00       	push   $0x262
f010161d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101623:	50                   	push   %eax
f0101624:	89 fb                	mov    %edi,%ebx
f0101626:	e8 6e ea ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010162b:	8d 87 11 d8 fe ff    	lea    -0x127ef(%edi),%eax
f0101631:	50                   	push   %eax
f0101632:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101638:	50                   	push   %eax
f0101639:	68 63 02 00 00       	push   $0x263
f010163e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101644:	50                   	push   %eax
f0101645:	89 fb                	mov    %edi,%ebx
f0101647:	e8 4d ea ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010164c:	8d 87 27 d8 fe ff    	lea    -0x127d9(%edi),%eax
f0101652:	50                   	push   %eax
f0101653:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101659:	50                   	push   %eax
f010165a:	68 66 02 00 00       	push   $0x266
f010165f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101665:	50                   	push   %eax
f0101666:	89 fb                	mov    %edi,%ebx
f0101668:	e8 2c ea ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010166d:	8d 87 04 d1 fe ff    	lea    -0x12efc(%edi),%eax
f0101673:	50                   	push   %eax
f0101674:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010167a:	50                   	push   %eax
f010167b:	68 67 02 00 00       	push   $0x267
f0101680:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101686:	50                   	push   %eax
f0101687:	89 fb                	mov    %edi,%ebx
f0101689:	e8 0b ea ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f010168e:	8d 87 39 d8 fe ff    	lea    -0x127c7(%edi),%eax
f0101694:	50                   	push   %eax
f0101695:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010169b:	50                   	push   %eax
f010169c:	68 68 02 00 00       	push   $0x268
f01016a1:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01016a7:	50                   	push   %eax
f01016a8:	89 fb                	mov    %edi,%ebx
f01016aa:	e8 ea e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01016af:	8d 87 56 d8 fe ff    	lea    -0x127aa(%edi),%eax
f01016b5:	50                   	push   %eax
f01016b6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01016bc:	50                   	push   %eax
f01016bd:	68 69 02 00 00       	push   $0x269
f01016c2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01016c8:	50                   	push   %eax
f01016c9:	89 fb                	mov    %edi,%ebx
f01016cb:	e8 c9 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01016d0:	8d 87 73 d8 fe ff    	lea    -0x1278d(%edi),%eax
f01016d6:	50                   	push   %eax
f01016d7:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01016dd:	50                   	push   %eax
f01016de:	68 6a 02 00 00       	push   $0x26a
f01016e3:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01016e9:	50                   	push   %eax
f01016ea:	89 fb                	mov    %edi,%ebx
f01016ec:	e8 a8 e9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01016f1:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f01016f7:	50                   	push   %eax
f01016f8:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01016fe:	50                   	push   %eax
f01016ff:	68 71 02 00 00       	push   $0x271
f0101704:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010170a:	50                   	push   %eax
f010170b:	89 fb                	mov    %edi,%ebx
f010170d:	e8 87 e9 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101712:	8d 87 e5 d7 fe ff    	lea    -0x1281b(%edi),%eax
f0101718:	50                   	push   %eax
f0101719:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010171f:	50                   	push   %eax
f0101720:	68 78 02 00 00       	push   $0x278
f0101725:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010172b:	50                   	push   %eax
f010172c:	89 fb                	mov    %edi,%ebx
f010172e:	e8 66 e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101733:	8d 87 fb d7 fe ff    	lea    -0x12805(%edi),%eax
f0101739:	50                   	push   %eax
f010173a:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101740:	50                   	push   %eax
f0101741:	68 79 02 00 00       	push   $0x279
f0101746:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010174c:	50                   	push   %eax
f010174d:	89 fb                	mov    %edi,%ebx
f010174f:	e8 45 e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101754:	8d 87 11 d8 fe ff    	lea    -0x127ef(%edi),%eax
f010175a:	50                   	push   %eax
f010175b:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101761:	50                   	push   %eax
f0101762:	68 7a 02 00 00       	push   $0x27a
f0101767:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010176d:	50                   	push   %eax
f010176e:	89 fb                	mov    %edi,%ebx
f0101770:	e8 24 e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101775:	8d 87 27 d8 fe ff    	lea    -0x127d9(%edi),%eax
f010177b:	50                   	push   %eax
f010177c:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101782:	50                   	push   %eax
f0101783:	68 7c 02 00 00       	push   $0x27c
f0101788:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010178e:	50                   	push   %eax
f010178f:	89 fb                	mov    %edi,%ebx
f0101791:	e8 03 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101796:	8d 87 04 d1 fe ff    	lea    -0x12efc(%edi),%eax
f010179c:	50                   	push   %eax
f010179d:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01017a3:	50                   	push   %eax
f01017a4:	68 7d 02 00 00       	push   $0x27d
f01017a9:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01017af:	50                   	push   %eax
f01017b0:	89 fb                	mov    %edi,%ebx
f01017b2:	e8 e2 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01017b7:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f01017bd:	50                   	push   %eax
f01017be:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01017c4:	50                   	push   %eax
f01017c5:	68 7e 02 00 00       	push   $0x27e
f01017ca:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01017d0:	50                   	push   %eax
f01017d1:	89 fb                	mov    %edi,%ebx
f01017d3:	e8 c1 e8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017d8:	50                   	push   %eax
f01017d9:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f01017df:	50                   	push   %eax
f01017e0:	6a 52                	push   $0x52
f01017e2:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f01017e8:	50                   	push   %eax
f01017e9:	89 fb                	mov    %edi,%ebx
f01017eb:	e8 a9 e8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017f0:	8d 87 9f d8 fe ff    	lea    -0x12761(%edi),%eax
f01017f6:	50                   	push   %eax
f01017f7:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01017fd:	50                   	push   %eax
f01017fe:	68 83 02 00 00       	push   $0x283
f0101803:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101809:	50                   	push   %eax
f010180a:	e8 8a e8 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f010180f:	8d 87 bd d8 fe ff    	lea    -0x12743(%edi),%eax
f0101815:	50                   	push   %eax
f0101816:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010181c:	50                   	push   %eax
f010181d:	68 84 02 00 00       	push   $0x284
f0101822:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101828:	50                   	push   %eax
f0101829:	e8 6b e8 ff ff       	call   f0100099 <_panic>
f010182e:	52                   	push   %edx
f010182f:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f0101835:	50                   	push   %eax
f0101836:	6a 52                	push   $0x52
f0101838:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f010183e:	50                   	push   %eax
f010183f:	e8 55 e8 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101844:	8d 87 cd d8 fe ff    	lea    -0x12733(%edi),%eax
f010184a:	50                   	push   %eax
f010184b:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101851:	50                   	push   %eax
f0101852:	68 87 02 00 00       	push   $0x287
f0101857:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010185d:	50                   	push   %eax
f010185e:	89 fb                	mov    %edi,%ebx
f0101860:	e8 34 e8 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101865:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101868:	8b 00                	mov    (%eax),%eax
f010186a:	85 c0                	test   %eax,%eax
f010186c:	75 f7                	jne    f0101865 <mem_init+0x61e>
	assert(nfree == 0);
f010186e:	85 f6                	test   %esi,%esi
f0101870:	0f 85 69 07 00 00    	jne    f0101fdf <mem_init+0xd98>
	cprintf("check_page_alloc() succeeded!\n");
f0101876:	83 ec 0c             	sub    $0xc,%esp
f0101879:	8d 87 24 d1 fe ff    	lea    -0x12edc(%edi),%eax
f010187f:	50                   	push   %eax
f0101880:	89 fb                	mov    %edi,%ebx
f0101882:	e8 fc 15 00 00       	call   f0102e83 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101887:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010188e:	e8 98 f6 ff ff       	call   f0100f2b <page_alloc>
f0101893:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101896:	83 c4 10             	add    $0x10,%esp
f0101899:	85 c0                	test   %eax,%eax
f010189b:	0f 84 5f 07 00 00    	je     f0102000 <mem_init+0xdb9>
	assert((pp1 = page_alloc(0)));
f01018a1:	83 ec 0c             	sub    $0xc,%esp
f01018a4:	6a 00                	push   $0x0
f01018a6:	e8 80 f6 ff ff       	call   f0100f2b <page_alloc>
f01018ab:	89 c6                	mov    %eax,%esi
f01018ad:	83 c4 10             	add    $0x10,%esp
f01018b0:	85 c0                	test   %eax,%eax
f01018b2:	0f 84 67 07 00 00    	je     f010201f <mem_init+0xdd8>
	assert((pp2 = page_alloc(0)));
f01018b8:	83 ec 0c             	sub    $0xc,%esp
f01018bb:	6a 00                	push   $0x0
f01018bd:	e8 69 f6 ff ff       	call   f0100f2b <page_alloc>
f01018c2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018c5:	83 c4 10             	add    $0x10,%esp
f01018c8:	85 c0                	test   %eax,%eax
f01018ca:	0f 84 6e 07 00 00    	je     f010203e <mem_init+0xdf7>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018d0:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01018d3:	0f 84 84 07 00 00    	je     f010205d <mem_init+0xe16>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018dc:	39 c6                	cmp    %eax,%esi
f01018de:	0f 84 98 07 00 00    	je     f010207c <mem_init+0xe35>
f01018e4:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01018e7:	0f 84 8f 07 00 00    	je     f010207c <mem_init+0xe35>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018ed:	8b 87 90 1f 00 00    	mov    0x1f90(%edi),%eax
f01018f3:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01018f6:	c7 87 90 1f 00 00 00 	movl   $0x0,0x1f90(%edi)
f01018fd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101900:	83 ec 0c             	sub    $0xc,%esp
f0101903:	6a 00                	push   $0x0
f0101905:	e8 21 f6 ff ff       	call   f0100f2b <page_alloc>
f010190a:	83 c4 10             	add    $0x10,%esp
f010190d:	85 c0                	test   %eax,%eax
f010190f:	0f 85 88 07 00 00    	jne    f010209d <mem_init+0xe56>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101915:	83 ec 04             	sub    $0x4,%esp
f0101918:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010191b:	50                   	push   %eax
f010191c:	6a 00                	push   $0x0
f010191e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101924:	ff 30                	pushl  (%eax)
f0101926:	e8 ce f7 ff ff       	call   f01010f9 <page_lookup>
f010192b:	83 c4 10             	add    $0x10,%esp
f010192e:	85 c0                	test   %eax,%eax
f0101930:	0f 85 86 07 00 00    	jne    f01020bc <mem_init+0xe75>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101936:	6a 02                	push   $0x2
f0101938:	6a 00                	push   $0x0
f010193a:	56                   	push   %esi
f010193b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101941:	ff 30                	pushl  (%eax)
f0101943:	e8 73 f8 ff ff       	call   f01011bb <page_insert>
f0101948:	83 c4 10             	add    $0x10,%esp
f010194b:	85 c0                	test   %eax,%eax
f010194d:	0f 89 88 07 00 00    	jns    f01020db <mem_init+0xe94>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101953:	83 ec 0c             	sub    $0xc,%esp
f0101956:	ff 75 d0             	pushl  -0x30(%ebp)
f0101959:	e8 55 f6 ff ff       	call   f0100fb3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010195e:	6a 02                	push   $0x2
f0101960:	6a 00                	push   $0x0
f0101962:	56                   	push   %esi
f0101963:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101969:	ff 30                	pushl  (%eax)
f010196b:	e8 4b f8 ff ff       	call   f01011bb <page_insert>
f0101970:	83 c4 20             	add    $0x20,%esp
f0101973:	85 c0                	test   %eax,%eax
f0101975:	0f 85 7f 07 00 00    	jne    f01020fa <mem_init+0xeb3>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010197b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101981:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101983:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101989:	8b 08                	mov    (%eax),%ecx
f010198b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010198e:	8b 13                	mov    (%ebx),%edx
f0101990:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101996:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101999:	29 c8                	sub    %ecx,%eax
f010199b:	c1 f8 03             	sar    $0x3,%eax
f010199e:	c1 e0 0c             	shl    $0xc,%eax
f01019a1:	39 c2                	cmp    %eax,%edx
f01019a3:	0f 85 70 07 00 00    	jne    f0102119 <mem_init+0xed2>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019a9:	ba 00 00 00 00       	mov    $0x0,%edx
f01019ae:	89 d8                	mov    %ebx,%eax
f01019b0:	e8 54 f0 ff ff       	call   f0100a09 <check_va2pa>
f01019b5:	89 f2                	mov    %esi,%edx
f01019b7:	2b 55 cc             	sub    -0x34(%ebp),%edx
f01019ba:	c1 fa 03             	sar    $0x3,%edx
f01019bd:	c1 e2 0c             	shl    $0xc,%edx
f01019c0:	39 d0                	cmp    %edx,%eax
f01019c2:	0f 85 72 07 00 00    	jne    f010213a <mem_init+0xef3>
	assert(pp1->pp_ref == 1);
f01019c8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019cd:	0f 85 88 07 00 00    	jne    f010215b <mem_init+0xf14>
	assert(pp0->pp_ref == 1);
f01019d3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01019d6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01019db:	0f 85 9b 07 00 00    	jne    f010217c <mem_init+0xf35>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01019e1:	6a 02                	push   $0x2
f01019e3:	68 00 10 00 00       	push   $0x1000
f01019e8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019eb:	53                   	push   %ebx
f01019ec:	e8 ca f7 ff ff       	call   f01011bb <page_insert>
f01019f1:	83 c4 10             	add    $0x10,%esp
f01019f4:	85 c0                	test   %eax,%eax
f01019f6:	0f 85 a1 07 00 00    	jne    f010219d <mem_init+0xf56>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01019fc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a01:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a07:	8b 00                	mov    (%eax),%eax
f0101a09:	e8 fb ef ff ff       	call   f0100a09 <check_va2pa>
f0101a0e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101a14:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a17:	2b 0a                	sub    (%edx),%ecx
f0101a19:	89 ca                	mov    %ecx,%edx
f0101a1b:	c1 fa 03             	sar    $0x3,%edx
f0101a1e:	c1 e2 0c             	shl    $0xc,%edx
f0101a21:	39 d0                	cmp    %edx,%eax
f0101a23:	0f 85 95 07 00 00    	jne    f01021be <mem_init+0xf77>
	assert(pp2->pp_ref == 1);
f0101a29:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a31:	0f 85 a8 07 00 00    	jne    f01021df <mem_init+0xf98>

	// should be no free memory
	assert(!page_alloc(0));
f0101a37:	83 ec 0c             	sub    $0xc,%esp
f0101a3a:	6a 00                	push   $0x0
f0101a3c:	e8 ea f4 ff ff       	call   f0100f2b <page_alloc>
f0101a41:	83 c4 10             	add    $0x10,%esp
f0101a44:	85 c0                	test   %eax,%eax
f0101a46:	0f 85 b4 07 00 00    	jne    f0102200 <mem_init+0xfb9>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a4c:	6a 02                	push   $0x2
f0101a4e:	68 00 10 00 00       	push   $0x1000
f0101a53:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a56:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a5c:	ff 30                	pushl  (%eax)
f0101a5e:	e8 58 f7 ff ff       	call   f01011bb <page_insert>
f0101a63:	83 c4 10             	add    $0x10,%esp
f0101a66:	85 c0                	test   %eax,%eax
f0101a68:	0f 85 b3 07 00 00    	jne    f0102221 <mem_init+0xfda>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a6e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a73:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a79:	8b 00                	mov    (%eax),%eax
f0101a7b:	e8 89 ef ff ff       	call   f0100a09 <check_va2pa>
f0101a80:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101a86:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a89:	2b 0a                	sub    (%edx),%ecx
f0101a8b:	89 ca                	mov    %ecx,%edx
f0101a8d:	c1 fa 03             	sar    $0x3,%edx
f0101a90:	c1 e2 0c             	shl    $0xc,%edx
f0101a93:	39 d0                	cmp    %edx,%eax
f0101a95:	0f 85 a7 07 00 00    	jne    f0102242 <mem_init+0xffb>
	assert(pp2->pp_ref == 1);
f0101a9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a9e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101aa3:	0f 85 ba 07 00 00    	jne    f0102263 <mem_init+0x101c>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101aa9:	83 ec 0c             	sub    $0xc,%esp
f0101aac:	6a 00                	push   $0x0
f0101aae:	e8 78 f4 ff ff       	call   f0100f2b <page_alloc>
f0101ab3:	83 c4 10             	add    $0x10,%esp
f0101ab6:	85 c0                	test   %eax,%eax
f0101ab8:	0f 85 c6 07 00 00    	jne    f0102284 <mem_init+0x103d>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101abe:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ac4:	8b 10                	mov    (%eax),%edx
f0101ac6:	8b 02                	mov    (%edx),%eax
f0101ac8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101acd:	89 c3                	mov    %eax,%ebx
f0101acf:	c1 eb 0c             	shr    $0xc,%ebx
f0101ad2:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101ad8:	3b 19                	cmp    (%ecx),%ebx
f0101ada:	0f 83 c5 07 00 00    	jae    f01022a5 <mem_init+0x105e>
	return (void *)(pa + KERNBASE);
f0101ae0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ae5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ae8:	83 ec 04             	sub    $0x4,%esp
f0101aeb:	6a 00                	push   $0x0
f0101aed:	68 00 10 00 00       	push   $0x1000
f0101af2:	52                   	push   %edx
f0101af3:	e8 56 f5 ff ff       	call   f010104e <pgdir_walk>
f0101af8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101afb:	8d 51 04             	lea    0x4(%ecx),%edx
f0101afe:	83 c4 10             	add    $0x10,%esp
f0101b01:	39 d0                	cmp    %edx,%eax
f0101b03:	0f 85 b7 07 00 00    	jne    f01022c0 <mem_init+0x1079>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b09:	6a 06                	push   $0x6
f0101b0b:	68 00 10 00 00       	push   $0x1000
f0101b10:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b13:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b19:	ff 30                	pushl  (%eax)
f0101b1b:	e8 9b f6 ff ff       	call   f01011bb <page_insert>
f0101b20:	83 c4 10             	add    $0x10,%esp
f0101b23:	85 c0                	test   %eax,%eax
f0101b25:	0f 85 b6 07 00 00    	jne    f01022e1 <mem_init+0x109a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b2b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b31:	8b 18                	mov    (%eax),%ebx
f0101b33:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b38:	89 d8                	mov    %ebx,%eax
f0101b3a:	e8 ca ee ff ff       	call   f0100a09 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101b3f:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b45:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b48:	2b 0a                	sub    (%edx),%ecx
f0101b4a:	89 ca                	mov    %ecx,%edx
f0101b4c:	c1 fa 03             	sar    $0x3,%edx
f0101b4f:	c1 e2 0c             	shl    $0xc,%edx
f0101b52:	39 d0                	cmp    %edx,%eax
f0101b54:	0f 85 a8 07 00 00    	jne    f0102302 <mem_init+0x10bb>
	assert(pp2->pp_ref == 1);
f0101b5a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b5d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b62:	0f 85 bb 07 00 00    	jne    f0102323 <mem_init+0x10dc>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101b68:	83 ec 04             	sub    $0x4,%esp
f0101b6b:	6a 00                	push   $0x0
f0101b6d:	68 00 10 00 00       	push   $0x1000
f0101b72:	53                   	push   %ebx
f0101b73:	e8 d6 f4 ff ff       	call   f010104e <pgdir_walk>
f0101b78:	83 c4 10             	add    $0x10,%esp
f0101b7b:	f6 00 04             	testb  $0x4,(%eax)
f0101b7e:	0f 84 c0 07 00 00    	je     f0102344 <mem_init+0x10fd>
	assert(kern_pgdir[0] & PTE_U);
f0101b84:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b8a:	8b 00                	mov    (%eax),%eax
f0101b8c:	f6 00 04             	testb  $0x4,(%eax)
f0101b8f:	0f 84 d0 07 00 00    	je     f0102365 <mem_init+0x111e>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b95:	6a 02                	push   $0x2
f0101b97:	68 00 10 00 00       	push   $0x1000
f0101b9c:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b9f:	50                   	push   %eax
f0101ba0:	e8 16 f6 ff ff       	call   f01011bb <page_insert>
f0101ba5:	83 c4 10             	add    $0x10,%esp
f0101ba8:	85 c0                	test   %eax,%eax
f0101baa:	0f 85 d6 07 00 00    	jne    f0102386 <mem_init+0x113f>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101bb0:	83 ec 04             	sub    $0x4,%esp
f0101bb3:	6a 00                	push   $0x0
f0101bb5:	68 00 10 00 00       	push   $0x1000
f0101bba:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bc0:	ff 30                	pushl  (%eax)
f0101bc2:	e8 87 f4 ff ff       	call   f010104e <pgdir_walk>
f0101bc7:	83 c4 10             	add    $0x10,%esp
f0101bca:	f6 00 02             	testb  $0x2,(%eax)
f0101bcd:	0f 84 d4 07 00 00    	je     f01023a7 <mem_init+0x1160>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101bd3:	83 ec 04             	sub    $0x4,%esp
f0101bd6:	6a 00                	push   $0x0
f0101bd8:	68 00 10 00 00       	push   $0x1000
f0101bdd:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101be3:	ff 30                	pushl  (%eax)
f0101be5:	e8 64 f4 ff ff       	call   f010104e <pgdir_walk>
f0101bea:	83 c4 10             	add    $0x10,%esp
f0101bed:	f6 00 04             	testb  $0x4,(%eax)
f0101bf0:	0f 85 d2 07 00 00    	jne    f01023c8 <mem_init+0x1181>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101bf6:	6a 02                	push   $0x2
f0101bf8:	68 00 00 40 00       	push   $0x400000
f0101bfd:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c00:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c06:	ff 30                	pushl  (%eax)
f0101c08:	e8 ae f5 ff ff       	call   f01011bb <page_insert>
f0101c0d:	83 c4 10             	add    $0x10,%esp
f0101c10:	85 c0                	test   %eax,%eax
f0101c12:	0f 89 d1 07 00 00    	jns    f01023e9 <mem_init+0x11a2>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101c18:	6a 02                	push   $0x2
f0101c1a:	68 00 10 00 00       	push   $0x1000
f0101c1f:	56                   	push   %esi
f0101c20:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c26:	ff 30                	pushl  (%eax)
f0101c28:	e8 8e f5 ff ff       	call   f01011bb <page_insert>
f0101c2d:	83 c4 10             	add    $0x10,%esp
f0101c30:	85 c0                	test   %eax,%eax
f0101c32:	0f 85 d2 07 00 00    	jne    f010240a <mem_init+0x11c3>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c38:	83 ec 04             	sub    $0x4,%esp
f0101c3b:	6a 00                	push   $0x0
f0101c3d:	68 00 10 00 00       	push   $0x1000
f0101c42:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c48:	ff 30                	pushl  (%eax)
f0101c4a:	e8 ff f3 ff ff       	call   f010104e <pgdir_walk>
f0101c4f:	83 c4 10             	add    $0x10,%esp
f0101c52:	f6 00 04             	testb  $0x4,(%eax)
f0101c55:	0f 85 d0 07 00 00    	jne    f010242b <mem_init+0x11e4>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101c5b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c61:	8b 18                	mov    (%eax),%ebx
f0101c63:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c68:	89 d8                	mov    %ebx,%eax
f0101c6a:	e8 9a ed ff ff       	call   f0100a09 <check_va2pa>
f0101c6f:	89 c2                	mov    %eax,%edx
f0101c71:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c74:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101c7a:	89 f1                	mov    %esi,%ecx
f0101c7c:	2b 08                	sub    (%eax),%ecx
f0101c7e:	89 c8                	mov    %ecx,%eax
f0101c80:	c1 f8 03             	sar    $0x3,%eax
f0101c83:	c1 e0 0c             	shl    $0xc,%eax
f0101c86:	39 c2                	cmp    %eax,%edx
f0101c88:	0f 85 be 07 00 00    	jne    f010244c <mem_init+0x1205>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c8e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c93:	89 d8                	mov    %ebx,%eax
f0101c95:	e8 6f ed ff ff       	call   f0100a09 <check_va2pa>
f0101c9a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101c9d:	0f 85 ca 07 00 00    	jne    f010246d <mem_init+0x1226>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ca3:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101ca8:	0f 85 e0 07 00 00    	jne    f010248e <mem_init+0x1247>
	assert(pp2->pp_ref == 0);
f0101cae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cb1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101cb6:	0f 85 f3 07 00 00    	jne    f01024af <mem_init+0x1268>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101cbc:	83 ec 0c             	sub    $0xc,%esp
f0101cbf:	6a 00                	push   $0x0
f0101cc1:	e8 65 f2 ff ff       	call   f0100f2b <page_alloc>
f0101cc6:	83 c4 10             	add    $0x10,%esp
f0101cc9:	85 c0                	test   %eax,%eax
f0101ccb:	0f 84 ff 07 00 00    	je     f01024d0 <mem_init+0x1289>
f0101cd1:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101cd4:	0f 85 f6 07 00 00    	jne    f01024d0 <mem_init+0x1289>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101cda:	83 ec 08             	sub    $0x8,%esp
f0101cdd:	6a 00                	push   $0x0
f0101cdf:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101ce5:	ff 33                	pushl  (%ebx)
f0101ce7:	e8 8b f4 ff ff       	call   f0101177 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101cec:	8b 1b                	mov    (%ebx),%ebx
f0101cee:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cf3:	89 d8                	mov    %ebx,%eax
f0101cf5:	e8 0f ed ff ff       	call   f0100a09 <check_va2pa>
f0101cfa:	83 c4 10             	add    $0x10,%esp
f0101cfd:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d00:	0f 85 eb 07 00 00    	jne    f01024f1 <mem_init+0x12aa>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d06:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d0b:	89 d8                	mov    %ebx,%eax
f0101d0d:	e8 f7 ec ff ff       	call   f0100a09 <check_va2pa>
f0101d12:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101d18:	89 f1                	mov    %esi,%ecx
f0101d1a:	2b 0a                	sub    (%edx),%ecx
f0101d1c:	89 ca                	mov    %ecx,%edx
f0101d1e:	c1 fa 03             	sar    $0x3,%edx
f0101d21:	c1 e2 0c             	shl    $0xc,%edx
f0101d24:	39 d0                	cmp    %edx,%eax
f0101d26:	0f 85 e6 07 00 00    	jne    f0102512 <mem_init+0x12cb>
	assert(pp1->pp_ref == 1);
f0101d2c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d31:	0f 85 fc 07 00 00    	jne    f0102533 <mem_init+0x12ec>
	assert(pp2->pp_ref == 0);
f0101d37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d3a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d3f:	0f 85 0f 08 00 00    	jne    f0102554 <mem_init+0x130d>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d45:	6a 00                	push   $0x0
f0101d47:	68 00 10 00 00       	push   $0x1000
f0101d4c:	56                   	push   %esi
f0101d4d:	53                   	push   %ebx
f0101d4e:	e8 68 f4 ff ff       	call   f01011bb <page_insert>
f0101d53:	83 c4 10             	add    $0x10,%esp
f0101d56:	85 c0                	test   %eax,%eax
f0101d58:	0f 85 17 08 00 00    	jne    f0102575 <mem_init+0x132e>
	assert(pp1->pp_ref);
f0101d5e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d63:	0f 84 2d 08 00 00    	je     f0102596 <mem_init+0x134f>
	assert(pp1->pp_link == NULL);
f0101d69:	83 3e 00             	cmpl   $0x0,(%esi)
f0101d6c:	0f 85 45 08 00 00    	jne    f01025b7 <mem_init+0x1370>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d72:	83 ec 08             	sub    $0x8,%esp
f0101d75:	68 00 10 00 00       	push   $0x1000
f0101d7a:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101d80:	ff 33                	pushl  (%ebx)
f0101d82:	e8 f0 f3 ff ff       	call   f0101177 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d87:	8b 1b                	mov    (%ebx),%ebx
f0101d89:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d8e:	89 d8                	mov    %ebx,%eax
f0101d90:	e8 74 ec ff ff       	call   f0100a09 <check_va2pa>
f0101d95:	83 c4 10             	add    $0x10,%esp
f0101d98:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d9b:	0f 85 37 08 00 00    	jne    f01025d8 <mem_init+0x1391>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101da1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da6:	89 d8                	mov    %ebx,%eax
f0101da8:	e8 5c ec ff ff       	call   f0100a09 <check_va2pa>
f0101dad:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101db0:	0f 85 43 08 00 00    	jne    f01025f9 <mem_init+0x13b2>
	assert(pp1->pp_ref == 0);
f0101db6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dbb:	0f 85 59 08 00 00    	jne    f010261a <mem_init+0x13d3>
	assert(pp2->pp_ref == 0);
f0101dc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101dc9:	0f 85 6c 08 00 00    	jne    f010263b <mem_init+0x13f4>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101dcf:	83 ec 0c             	sub    $0xc,%esp
f0101dd2:	6a 00                	push   $0x0
f0101dd4:	e8 52 f1 ff ff       	call   f0100f2b <page_alloc>
f0101dd9:	83 c4 10             	add    $0x10,%esp
f0101ddc:	39 c6                	cmp    %eax,%esi
f0101dde:	0f 85 78 08 00 00    	jne    f010265c <mem_init+0x1415>
f0101de4:	85 c0                	test   %eax,%eax
f0101de6:	0f 84 70 08 00 00    	je     f010265c <mem_init+0x1415>

	// should be no free memory
	assert(!page_alloc(0));
f0101dec:	83 ec 0c             	sub    $0xc,%esp
f0101def:	6a 00                	push   $0x0
f0101df1:	e8 35 f1 ff ff       	call   f0100f2b <page_alloc>
f0101df6:	83 c4 10             	add    $0x10,%esp
f0101df9:	85 c0                	test   %eax,%eax
f0101dfb:	0f 85 7c 08 00 00    	jne    f010267d <mem_init+0x1436>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e01:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e07:	8b 08                	mov    (%eax),%ecx
f0101e09:	8b 11                	mov    (%ecx),%edx
f0101e0b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e11:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101e17:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101e1a:	2b 18                	sub    (%eax),%ebx
f0101e1c:	89 d8                	mov    %ebx,%eax
f0101e1e:	c1 f8 03             	sar    $0x3,%eax
f0101e21:	c1 e0 0c             	shl    $0xc,%eax
f0101e24:	39 c2                	cmp    %eax,%edx
f0101e26:	0f 85 72 08 00 00    	jne    f010269e <mem_init+0x1457>
	kern_pgdir[0] = 0;
f0101e2c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101e32:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e35:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e3a:	0f 85 7f 08 00 00    	jne    f01026bf <mem_init+0x1478>
	pp0->pp_ref = 0;
f0101e40:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e43:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101e49:	83 ec 0c             	sub    $0xc,%esp
f0101e4c:	50                   	push   %eax
f0101e4d:	e8 61 f1 ff ff       	call   f0100fb3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101e52:	83 c4 0c             	add    $0xc,%esp
f0101e55:	6a 01                	push   $0x1
f0101e57:	68 00 10 40 00       	push   $0x401000
f0101e5c:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101e62:	ff 33                	pushl  (%ebx)
f0101e64:	e8 e5 f1 ff ff       	call   f010104e <pgdir_walk>
f0101e69:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e6c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101e6f:	8b 1b                	mov    (%ebx),%ebx
f0101e71:	8b 53 04             	mov    0x4(%ebx),%edx
f0101e74:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101e7a:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101e80:	8b 09                	mov    (%ecx),%ecx
f0101e82:	89 d0                	mov    %edx,%eax
f0101e84:	c1 e8 0c             	shr    $0xc,%eax
f0101e87:	83 c4 10             	add    $0x10,%esp
f0101e8a:	39 c8                	cmp    %ecx,%eax
f0101e8c:	0f 83 4e 08 00 00    	jae    f01026e0 <mem_init+0x1499>
	assert(ptep == ptep1 + PTX(va));
f0101e92:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101e98:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101e9b:	0f 85 5a 08 00 00    	jne    f01026fb <mem_init+0x14b4>
	kern_pgdir[PDX(va)] = 0;
f0101ea1:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101ea8:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101eab:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101eb1:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101eb7:	2b 18                	sub    (%eax),%ebx
f0101eb9:	89 d8                	mov    %ebx,%eax
f0101ebb:	c1 f8 03             	sar    $0x3,%eax
f0101ebe:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101ec1:	89 c2                	mov    %eax,%edx
f0101ec3:	c1 ea 0c             	shr    $0xc,%edx
f0101ec6:	39 d1                	cmp    %edx,%ecx
f0101ec8:	0f 86 4e 08 00 00    	jbe    f010271c <mem_init+0x14d5>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101ece:	83 ec 04             	sub    $0x4,%esp
f0101ed1:	68 00 10 00 00       	push   $0x1000
f0101ed6:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101edb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ee0:	50                   	push   %eax
f0101ee1:	89 fb                	mov    %edi,%ebx
f0101ee3:	e8 f7 1a 00 00       	call   f01039df <memset>
	page_free(pp0);
f0101ee8:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101eeb:	89 1c 24             	mov    %ebx,(%esp)
f0101eee:	e8 c0 f0 ff ff       	call   f0100fb3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101ef3:	83 c4 0c             	add    $0xc,%esp
f0101ef6:	6a 01                	push   $0x1
f0101ef8:	6a 00                	push   $0x0
f0101efa:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f00:	ff 30                	pushl  (%eax)
f0101f02:	e8 47 f1 ff ff       	call   f010104e <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101f07:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f0d:	2b 18                	sub    (%eax),%ebx
f0101f0f:	89 da                	mov    %ebx,%edx
f0101f11:	c1 fa 03             	sar    $0x3,%edx
f0101f14:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101f17:	89 d1                	mov    %edx,%ecx
f0101f19:	c1 e9 0c             	shr    $0xc,%ecx
f0101f1c:	83 c4 10             	add    $0x10,%esp
f0101f1f:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101f25:	3b 08                	cmp    (%eax),%ecx
f0101f27:	0f 83 07 08 00 00    	jae    f0102734 <mem_init+0x14ed>
	return (void *)(pa + KERNBASE);
f0101f2d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101f33:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101f36:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101f3c:	f6 00 01             	testb  $0x1,(%eax)
f0101f3f:	0f 85 07 08 00 00    	jne    f010274c <mem_init+0x1505>
f0101f45:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101f48:	39 d0                	cmp    %edx,%eax
f0101f4a:	75 f0                	jne    f0101f3c <mem_init+0xcf5>
	kern_pgdir[0] = 0;
f0101f4c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101f52:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f55:	8b 00                	mov    (%eax),%eax
f0101f57:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101f5d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101f60:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)

	// give free list back
	page_free_list = fl;
f0101f66:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0101f69:	89 9f 90 1f 00 00    	mov    %ebx,0x1f90(%edi)

	// free the pages we took
	page_free(pp0);
f0101f6f:	83 ec 0c             	sub    $0xc,%esp
f0101f72:	51                   	push   %ecx
f0101f73:	e8 3b f0 ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f0101f78:	89 34 24             	mov    %esi,(%esp)
f0101f7b:	e8 33 f0 ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f0101f80:	83 c4 04             	add    $0x4,%esp
f0101f83:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101f86:	e8 28 f0 ff ff       	call   f0100fb3 <page_free>

	cprintf("check_page() succeeded!\n");
f0101f8b:	8d 87 ae d9 fe ff    	lea    -0x12652(%edi),%eax
f0101f91:	89 04 24             	mov    %eax,(%esp)
f0101f94:	89 fb                	mov    %edi,%ebx
f0101f96:	e8 e8 0e 00 00       	call   f0102e83 <cprintf>
	pgdir = kern_pgdir;
f0101f9b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f9e:	8b 18                	mov    (%eax),%ebx
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0101fa0:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101fa6:	8b 00                	mov    (%eax),%eax
f0101fa8:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101fab:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0101fb2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101fb7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101fba:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101fc0:	8b 00                	mov    (%eax),%eax
f0101fc2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0101fc5:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0101fc8:	05 00 00 00 10       	add    $0x10000000,%eax
f0101fcd:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0101fd0:	be 00 00 00 00       	mov    $0x0,%esi
f0101fd5:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101fd8:	89 c3                	mov    %eax,%ebx
f0101fda:	e9 b1 07 00 00       	jmp    f0102790 <mem_init+0x1549>
	assert(nfree == 0);
f0101fdf:	8d 87 d7 d8 fe ff    	lea    -0x12729(%edi),%eax
f0101fe5:	50                   	push   %eax
f0101fe6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0101fec:	50                   	push   %eax
f0101fed:	68 94 02 00 00       	push   $0x294
f0101ff2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0101ff8:	50                   	push   %eax
f0101ff9:	89 fb                	mov    %edi,%ebx
f0101ffb:	e8 99 e0 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102000:	8d 87 e5 d7 fe ff    	lea    -0x1281b(%edi),%eax
f0102006:	50                   	push   %eax
f0102007:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010200d:	50                   	push   %eax
f010200e:	68 ed 02 00 00       	push   $0x2ed
f0102013:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102019:	50                   	push   %eax
f010201a:	e8 7a e0 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010201f:	8d 87 fb d7 fe ff    	lea    -0x12805(%edi),%eax
f0102025:	50                   	push   %eax
f0102026:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010202c:	50                   	push   %eax
f010202d:	68 ee 02 00 00       	push   $0x2ee
f0102032:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102038:	50                   	push   %eax
f0102039:	e8 5b e0 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010203e:	8d 87 11 d8 fe ff    	lea    -0x127ef(%edi),%eax
f0102044:	50                   	push   %eax
f0102045:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010204b:	50                   	push   %eax
f010204c:	68 ef 02 00 00       	push   $0x2ef
f0102051:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102057:	50                   	push   %eax
f0102058:	e8 3c e0 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010205d:	8d 87 27 d8 fe ff    	lea    -0x127d9(%edi),%eax
f0102063:	50                   	push   %eax
f0102064:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010206a:	50                   	push   %eax
f010206b:	68 f2 02 00 00       	push   $0x2f2
f0102070:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102076:	50                   	push   %eax
f0102077:	e8 1d e0 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010207c:	8d 87 04 d1 fe ff    	lea    -0x12efc(%edi),%eax
f0102082:	50                   	push   %eax
f0102083:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102089:	50                   	push   %eax
f010208a:	68 f3 02 00 00       	push   $0x2f3
f010208f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102095:	50                   	push   %eax
f0102096:	89 fb                	mov    %edi,%ebx
f0102098:	e8 fc df ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010209d:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f01020a3:	50                   	push   %eax
f01020a4:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01020aa:	50                   	push   %eax
f01020ab:	68 fa 02 00 00       	push   $0x2fa
f01020b0:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01020b6:	50                   	push   %eax
f01020b7:	e8 dd df ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01020bc:	8d 87 44 d1 fe ff    	lea    -0x12ebc(%edi),%eax
f01020c2:	50                   	push   %eax
f01020c3:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01020c9:	50                   	push   %eax
f01020ca:	68 fd 02 00 00       	push   $0x2fd
f01020cf:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01020d5:	50                   	push   %eax
f01020d6:	e8 be df ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01020db:	8d 87 7c d1 fe ff    	lea    -0x12e84(%edi),%eax
f01020e1:	50                   	push   %eax
f01020e2:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01020e8:	50                   	push   %eax
f01020e9:	68 00 03 00 00       	push   $0x300
f01020ee:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01020f4:	50                   	push   %eax
f01020f5:	e8 9f df ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01020fa:	8d 87 ac d1 fe ff    	lea    -0x12e54(%edi),%eax
f0102100:	50                   	push   %eax
f0102101:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102107:	50                   	push   %eax
f0102108:	68 04 03 00 00       	push   $0x304
f010210d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102113:	50                   	push   %eax
f0102114:	e8 80 df ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102119:	8d 87 dc d1 fe ff    	lea    -0x12e24(%edi),%eax
f010211f:	50                   	push   %eax
f0102120:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102126:	50                   	push   %eax
f0102127:	68 05 03 00 00       	push   $0x305
f010212c:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102132:	50                   	push   %eax
f0102133:	89 fb                	mov    %edi,%ebx
f0102135:	e8 5f df ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010213a:	8d 87 04 d2 fe ff    	lea    -0x12dfc(%edi),%eax
f0102140:	50                   	push   %eax
f0102141:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102147:	50                   	push   %eax
f0102148:	68 06 03 00 00       	push   $0x306
f010214d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102153:	50                   	push   %eax
f0102154:	89 fb                	mov    %edi,%ebx
f0102156:	e8 3e df ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010215b:	8d 87 e2 d8 fe ff    	lea    -0x1271e(%edi),%eax
f0102161:	50                   	push   %eax
f0102162:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102168:	50                   	push   %eax
f0102169:	68 07 03 00 00       	push   $0x307
f010216e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102174:	50                   	push   %eax
f0102175:	89 fb                	mov    %edi,%ebx
f0102177:	e8 1d df ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010217c:	8d 87 f3 d8 fe ff    	lea    -0x1270d(%edi),%eax
f0102182:	50                   	push   %eax
f0102183:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102189:	50                   	push   %eax
f010218a:	68 08 03 00 00       	push   $0x308
f010218f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102195:	50                   	push   %eax
f0102196:	89 fb                	mov    %edi,%ebx
f0102198:	e8 fc de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010219d:	8d 87 34 d2 fe ff    	lea    -0x12dcc(%edi),%eax
f01021a3:	50                   	push   %eax
f01021a4:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01021aa:	50                   	push   %eax
f01021ab:	68 0b 03 00 00       	push   $0x30b
f01021b0:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01021b6:	50                   	push   %eax
f01021b7:	89 fb                	mov    %edi,%ebx
f01021b9:	e8 db de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021be:	8d 87 70 d2 fe ff    	lea    -0x12d90(%edi),%eax
f01021c4:	50                   	push   %eax
f01021c5:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01021cb:	50                   	push   %eax
f01021cc:	68 0c 03 00 00       	push   $0x30c
f01021d1:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01021d7:	50                   	push   %eax
f01021d8:	89 fb                	mov    %edi,%ebx
f01021da:	e8 ba de ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01021df:	8d 87 04 d9 fe ff    	lea    -0x126fc(%edi),%eax
f01021e5:	50                   	push   %eax
f01021e6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01021ec:	50                   	push   %eax
f01021ed:	68 0d 03 00 00       	push   $0x30d
f01021f2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01021f8:	50                   	push   %eax
f01021f9:	89 fb                	mov    %edi,%ebx
f01021fb:	e8 99 de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102200:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f0102206:	50                   	push   %eax
f0102207:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010220d:	50                   	push   %eax
f010220e:	68 10 03 00 00       	push   $0x310
f0102213:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102219:	50                   	push   %eax
f010221a:	89 fb                	mov    %edi,%ebx
f010221c:	e8 78 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102221:	8d 87 34 d2 fe ff    	lea    -0x12dcc(%edi),%eax
f0102227:	50                   	push   %eax
f0102228:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010222e:	50                   	push   %eax
f010222f:	68 13 03 00 00       	push   $0x313
f0102234:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010223a:	50                   	push   %eax
f010223b:	89 fb                	mov    %edi,%ebx
f010223d:	e8 57 de ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102242:	8d 87 70 d2 fe ff    	lea    -0x12d90(%edi),%eax
f0102248:	50                   	push   %eax
f0102249:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010224f:	50                   	push   %eax
f0102250:	68 14 03 00 00       	push   $0x314
f0102255:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010225b:	50                   	push   %eax
f010225c:	89 fb                	mov    %edi,%ebx
f010225e:	e8 36 de ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102263:	8d 87 04 d9 fe ff    	lea    -0x126fc(%edi),%eax
f0102269:	50                   	push   %eax
f010226a:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102270:	50                   	push   %eax
f0102271:	68 15 03 00 00       	push   $0x315
f0102276:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010227c:	50                   	push   %eax
f010227d:	89 fb                	mov    %edi,%ebx
f010227f:	e8 15 de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102284:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f010228a:	50                   	push   %eax
f010228b:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102291:	50                   	push   %eax
f0102292:	68 19 03 00 00       	push   $0x319
f0102297:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010229d:	50                   	push   %eax
f010229e:	89 fb                	mov    %edi,%ebx
f01022a0:	e8 f4 dd ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01022a5:	50                   	push   %eax
f01022a6:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f01022ac:	50                   	push   %eax
f01022ad:	68 1c 03 00 00       	push   $0x31c
f01022b2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01022b8:	50                   	push   %eax
f01022b9:	89 fb                	mov    %edi,%ebx
f01022bb:	e8 d9 dd ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01022c0:	8d 87 a0 d2 fe ff    	lea    -0x12d60(%edi),%eax
f01022c6:	50                   	push   %eax
f01022c7:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01022cd:	50                   	push   %eax
f01022ce:	68 1d 03 00 00       	push   $0x31d
f01022d3:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01022d9:	50                   	push   %eax
f01022da:	89 fb                	mov    %edi,%ebx
f01022dc:	e8 b8 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01022e1:	8d 87 e0 d2 fe ff    	lea    -0x12d20(%edi),%eax
f01022e7:	50                   	push   %eax
f01022e8:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01022ee:	50                   	push   %eax
f01022ef:	68 20 03 00 00       	push   $0x320
f01022f4:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01022fa:	50                   	push   %eax
f01022fb:	89 fb                	mov    %edi,%ebx
f01022fd:	e8 97 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102302:	8d 87 70 d2 fe ff    	lea    -0x12d90(%edi),%eax
f0102308:	50                   	push   %eax
f0102309:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010230f:	50                   	push   %eax
f0102310:	68 21 03 00 00       	push   $0x321
f0102315:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010231b:	50                   	push   %eax
f010231c:	89 fb                	mov    %edi,%ebx
f010231e:	e8 76 dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102323:	8d 87 04 d9 fe ff    	lea    -0x126fc(%edi),%eax
f0102329:	50                   	push   %eax
f010232a:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102330:	50                   	push   %eax
f0102331:	68 22 03 00 00       	push   $0x322
f0102336:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010233c:	50                   	push   %eax
f010233d:	89 fb                	mov    %edi,%ebx
f010233f:	e8 55 dd ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102344:	8d 87 20 d3 fe ff    	lea    -0x12ce0(%edi),%eax
f010234a:	50                   	push   %eax
f010234b:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102351:	50                   	push   %eax
f0102352:	68 23 03 00 00       	push   $0x323
f0102357:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010235d:	50                   	push   %eax
f010235e:	89 fb                	mov    %edi,%ebx
f0102360:	e8 34 dd ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102365:	8d 87 15 d9 fe ff    	lea    -0x126eb(%edi),%eax
f010236b:	50                   	push   %eax
f010236c:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102372:	50                   	push   %eax
f0102373:	68 24 03 00 00       	push   $0x324
f0102378:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010237e:	50                   	push   %eax
f010237f:	89 fb                	mov    %edi,%ebx
f0102381:	e8 13 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102386:	8d 87 34 d2 fe ff    	lea    -0x12dcc(%edi),%eax
f010238c:	50                   	push   %eax
f010238d:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102393:	50                   	push   %eax
f0102394:	68 27 03 00 00       	push   $0x327
f0102399:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010239f:	50                   	push   %eax
f01023a0:	89 fb                	mov    %edi,%ebx
f01023a2:	e8 f2 dc ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01023a7:	8d 87 54 d3 fe ff    	lea    -0x12cac(%edi),%eax
f01023ad:	50                   	push   %eax
f01023ae:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01023b4:	50                   	push   %eax
f01023b5:	68 28 03 00 00       	push   $0x328
f01023ba:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01023c0:	50                   	push   %eax
f01023c1:	89 fb                	mov    %edi,%ebx
f01023c3:	e8 d1 dc ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01023c8:	8d 87 88 d3 fe ff    	lea    -0x12c78(%edi),%eax
f01023ce:	50                   	push   %eax
f01023cf:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01023d5:	50                   	push   %eax
f01023d6:	68 29 03 00 00       	push   $0x329
f01023db:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01023e1:	50                   	push   %eax
f01023e2:	89 fb                	mov    %edi,%ebx
f01023e4:	e8 b0 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01023e9:	8d 87 c0 d3 fe ff    	lea    -0x12c40(%edi),%eax
f01023ef:	50                   	push   %eax
f01023f0:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01023f6:	50                   	push   %eax
f01023f7:	68 2c 03 00 00       	push   $0x32c
f01023fc:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102402:	50                   	push   %eax
f0102403:	89 fb                	mov    %edi,%ebx
f0102405:	e8 8f dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010240a:	8d 87 f8 d3 fe ff    	lea    -0x12c08(%edi),%eax
f0102410:	50                   	push   %eax
f0102411:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102417:	50                   	push   %eax
f0102418:	68 2f 03 00 00       	push   $0x32f
f010241d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102423:	50                   	push   %eax
f0102424:	89 fb                	mov    %edi,%ebx
f0102426:	e8 6e dc ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010242b:	8d 87 88 d3 fe ff    	lea    -0x12c78(%edi),%eax
f0102431:	50                   	push   %eax
f0102432:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102438:	50                   	push   %eax
f0102439:	68 30 03 00 00       	push   $0x330
f010243e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102444:	50                   	push   %eax
f0102445:	89 fb                	mov    %edi,%ebx
f0102447:	e8 4d dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010244c:	8d 87 34 d4 fe ff    	lea    -0x12bcc(%edi),%eax
f0102452:	50                   	push   %eax
f0102453:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102459:	50                   	push   %eax
f010245a:	68 33 03 00 00       	push   $0x333
f010245f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102465:	50                   	push   %eax
f0102466:	89 fb                	mov    %edi,%ebx
f0102468:	e8 2c dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010246d:	8d 87 60 d4 fe ff    	lea    -0x12ba0(%edi),%eax
f0102473:	50                   	push   %eax
f0102474:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010247a:	50                   	push   %eax
f010247b:	68 34 03 00 00       	push   $0x334
f0102480:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102486:	50                   	push   %eax
f0102487:	89 fb                	mov    %edi,%ebx
f0102489:	e8 0b dc ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f010248e:	8d 87 2b d9 fe ff    	lea    -0x126d5(%edi),%eax
f0102494:	50                   	push   %eax
f0102495:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010249b:	50                   	push   %eax
f010249c:	68 36 03 00 00       	push   $0x336
f01024a1:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01024a7:	50                   	push   %eax
f01024a8:	89 fb                	mov    %edi,%ebx
f01024aa:	e8 ea db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01024af:	8d 87 3c d9 fe ff    	lea    -0x126c4(%edi),%eax
f01024b5:	50                   	push   %eax
f01024b6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01024bc:	50                   	push   %eax
f01024bd:	68 37 03 00 00       	push   $0x337
f01024c2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01024c8:	50                   	push   %eax
f01024c9:	89 fb                	mov    %edi,%ebx
f01024cb:	e8 c9 db ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01024d0:	8d 87 90 d4 fe ff    	lea    -0x12b70(%edi),%eax
f01024d6:	50                   	push   %eax
f01024d7:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01024dd:	50                   	push   %eax
f01024de:	68 3a 03 00 00       	push   $0x33a
f01024e3:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01024e9:	50                   	push   %eax
f01024ea:	89 fb                	mov    %edi,%ebx
f01024ec:	e8 a8 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024f1:	8d 87 b4 d4 fe ff    	lea    -0x12b4c(%edi),%eax
f01024f7:	50                   	push   %eax
f01024f8:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01024fe:	50                   	push   %eax
f01024ff:	68 3e 03 00 00       	push   $0x33e
f0102504:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010250a:	50                   	push   %eax
f010250b:	89 fb                	mov    %edi,%ebx
f010250d:	e8 87 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102512:	8d 87 60 d4 fe ff    	lea    -0x12ba0(%edi),%eax
f0102518:	50                   	push   %eax
f0102519:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010251f:	50                   	push   %eax
f0102520:	68 3f 03 00 00       	push   $0x33f
f0102525:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010252b:	50                   	push   %eax
f010252c:	89 fb                	mov    %edi,%ebx
f010252e:	e8 66 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102533:	8d 87 e2 d8 fe ff    	lea    -0x1271e(%edi),%eax
f0102539:	50                   	push   %eax
f010253a:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102540:	50                   	push   %eax
f0102541:	68 40 03 00 00       	push   $0x340
f0102546:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010254c:	50                   	push   %eax
f010254d:	89 fb                	mov    %edi,%ebx
f010254f:	e8 45 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102554:	8d 87 3c d9 fe ff    	lea    -0x126c4(%edi),%eax
f010255a:	50                   	push   %eax
f010255b:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102561:	50                   	push   %eax
f0102562:	68 41 03 00 00       	push   $0x341
f0102567:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010256d:	50                   	push   %eax
f010256e:	89 fb                	mov    %edi,%ebx
f0102570:	e8 24 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102575:	8d 87 d8 d4 fe ff    	lea    -0x12b28(%edi),%eax
f010257b:	50                   	push   %eax
f010257c:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102582:	50                   	push   %eax
f0102583:	68 44 03 00 00       	push   $0x344
f0102588:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010258e:	50                   	push   %eax
f010258f:	89 fb                	mov    %edi,%ebx
f0102591:	e8 03 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102596:	8d 87 4d d9 fe ff    	lea    -0x126b3(%edi),%eax
f010259c:	50                   	push   %eax
f010259d:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01025a3:	50                   	push   %eax
f01025a4:	68 45 03 00 00       	push   $0x345
f01025a9:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01025af:	50                   	push   %eax
f01025b0:	89 fb                	mov    %edi,%ebx
f01025b2:	e8 e2 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01025b7:	8d 87 59 d9 fe ff    	lea    -0x126a7(%edi),%eax
f01025bd:	50                   	push   %eax
f01025be:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01025c4:	50                   	push   %eax
f01025c5:	68 46 03 00 00       	push   $0x346
f01025ca:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01025d0:	50                   	push   %eax
f01025d1:	89 fb                	mov    %edi,%ebx
f01025d3:	e8 c1 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025d8:	8d 87 b4 d4 fe ff    	lea    -0x12b4c(%edi),%eax
f01025de:	50                   	push   %eax
f01025df:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01025e5:	50                   	push   %eax
f01025e6:	68 4a 03 00 00       	push   $0x34a
f01025eb:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01025f1:	50                   	push   %eax
f01025f2:	89 fb                	mov    %edi,%ebx
f01025f4:	e8 a0 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025f9:	8d 87 10 d5 fe ff    	lea    -0x12af0(%edi),%eax
f01025ff:	50                   	push   %eax
f0102600:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102606:	50                   	push   %eax
f0102607:	68 4b 03 00 00       	push   $0x34b
f010260c:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102612:	50                   	push   %eax
f0102613:	89 fb                	mov    %edi,%ebx
f0102615:	e8 7f da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010261a:	8d 87 6e d9 fe ff    	lea    -0x12692(%edi),%eax
f0102620:	50                   	push   %eax
f0102621:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102627:	50                   	push   %eax
f0102628:	68 4c 03 00 00       	push   $0x34c
f010262d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102633:	50                   	push   %eax
f0102634:	89 fb                	mov    %edi,%ebx
f0102636:	e8 5e da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010263b:	8d 87 3c d9 fe ff    	lea    -0x126c4(%edi),%eax
f0102641:	50                   	push   %eax
f0102642:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102648:	50                   	push   %eax
f0102649:	68 4d 03 00 00       	push   $0x34d
f010264e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102654:	50                   	push   %eax
f0102655:	89 fb                	mov    %edi,%ebx
f0102657:	e8 3d da ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010265c:	8d 87 38 d5 fe ff    	lea    -0x12ac8(%edi),%eax
f0102662:	50                   	push   %eax
f0102663:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102669:	50                   	push   %eax
f010266a:	68 50 03 00 00       	push   $0x350
f010266f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102675:	50                   	push   %eax
f0102676:	89 fb                	mov    %edi,%ebx
f0102678:	e8 1c da ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010267d:	8d 87 90 d8 fe ff    	lea    -0x12770(%edi),%eax
f0102683:	50                   	push   %eax
f0102684:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010268a:	50                   	push   %eax
f010268b:	68 53 03 00 00       	push   $0x353
f0102690:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102696:	50                   	push   %eax
f0102697:	89 fb                	mov    %edi,%ebx
f0102699:	e8 fb d9 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010269e:	8d 87 dc d1 fe ff    	lea    -0x12e24(%edi),%eax
f01026a4:	50                   	push   %eax
f01026a5:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01026ab:	50                   	push   %eax
f01026ac:	68 56 03 00 00       	push   $0x356
f01026b1:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01026b7:	50                   	push   %eax
f01026b8:	89 fb                	mov    %edi,%ebx
f01026ba:	e8 da d9 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01026bf:	8d 87 f3 d8 fe ff    	lea    -0x1270d(%edi),%eax
f01026c5:	50                   	push   %eax
f01026c6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01026cc:	50                   	push   %eax
f01026cd:	68 58 03 00 00       	push   $0x358
f01026d2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01026d8:	50                   	push   %eax
f01026d9:	89 fb                	mov    %edi,%ebx
f01026db:	e8 b9 d9 ff ff       	call   f0100099 <_panic>
f01026e0:	52                   	push   %edx
f01026e1:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f01026e7:	50                   	push   %eax
f01026e8:	68 5f 03 00 00       	push   $0x35f
f01026ed:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01026f3:	50                   	push   %eax
f01026f4:	89 fb                	mov    %edi,%ebx
f01026f6:	e8 9e d9 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026fb:	8d 87 7f d9 fe ff    	lea    -0x12681(%edi),%eax
f0102701:	50                   	push   %eax
f0102702:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102708:	50                   	push   %eax
f0102709:	68 60 03 00 00       	push   $0x360
f010270e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102714:	50                   	push   %eax
f0102715:	89 fb                	mov    %edi,%ebx
f0102717:	e8 7d d9 ff ff       	call   f0100099 <_panic>
f010271c:	50                   	push   %eax
f010271d:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f0102723:	50                   	push   %eax
f0102724:	6a 52                	push   $0x52
f0102726:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f010272c:	50                   	push   %eax
f010272d:	89 fb                	mov    %edi,%ebx
f010272f:	e8 65 d9 ff ff       	call   f0100099 <_panic>
f0102734:	52                   	push   %edx
f0102735:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f010273b:	50                   	push   %eax
f010273c:	6a 52                	push   $0x52
f010273e:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f0102744:	50                   	push   %eax
f0102745:	89 fb                	mov    %edi,%ebx
f0102747:	e8 4d d9 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f010274c:	8d 87 97 d9 fe ff    	lea    -0x12669(%edi),%eax
f0102752:	50                   	push   %eax
f0102753:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102759:	50                   	push   %eax
f010275a:	68 6a 03 00 00       	push   $0x36a
f010275f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102765:	50                   	push   %eax
f0102766:	89 fb                	mov    %edi,%ebx
f0102768:	e8 2c d9 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010276d:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102770:	8d 87 e0 d0 fe ff    	lea    -0x12f20(%edi),%eax
f0102776:	50                   	push   %eax
f0102777:	68 ac 02 00 00       	push   $0x2ac
f010277c:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102782:	50                   	push   %eax
f0102783:	89 fb                	mov    %edi,%ebx
f0102785:	e8 0f d9 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f010278a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102790:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102793:	76 3f                	jbe    f01027d4 <mem_init+0x158d>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102795:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f010279b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010279e:	e8 66 e2 ff ff       	call   f0100a09 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f01027a3:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f01027aa:	76 c1                	jbe    f010276d <mem_init+0x1526>
f01027ac:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f01027af:	39 d0                	cmp    %edx,%eax
f01027b1:	74 d7                	je     f010278a <mem_init+0x1543>
f01027b3:	8d 87 5c d5 fe ff    	lea    -0x12aa4(%edi),%eax
f01027b9:	50                   	push   %eax
f01027ba:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01027c0:	50                   	push   %eax
f01027c1:	68 ac 02 00 00       	push   $0x2ac
f01027c6:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01027cc:	50                   	push   %eax
f01027cd:	89 fb                	mov    %edi,%ebx
f01027cf:	e8 c5 d8 ff ff       	call   f0100099 <_panic>
f01027d4:	8b 5d d0             	mov    -0x30(%ebp),%ebx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027d7:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01027da:	c1 e0 0c             	shl    $0xc,%eax
f01027dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027e0:	be 00 00 00 00       	mov    $0x0,%esi
f01027e5:	eb 17                	jmp    f01027fe <mem_init+0x15b7>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027e7:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f01027ed:	89 d8                	mov    %ebx,%eax
f01027ef:	e8 15 e2 ff ff       	call   f0100a09 <check_va2pa>
f01027f4:	39 c6                	cmp    %eax,%esi
f01027f6:	75 66                	jne    f010285e <mem_init+0x1617>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027f8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027fe:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102801:	72 e4                	jb     f01027e7 <mem_init+0x15a0>
f0102803:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102808:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f010280e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102811:	05 00 80 00 20       	add    $0x20008000,%eax
f0102816:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102819:	89 f2                	mov    %esi,%edx
f010281b:	89 d8                	mov    %ebx,%eax
f010281d:	e8 e7 e1 ff ff       	call   f0100a09 <check_va2pa>
f0102822:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102829:	76 54                	jbe    f010287f <mem_init+0x1638>
f010282b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010282e:	8d 14 31             	lea    (%ecx,%esi,1),%edx
f0102831:	39 c2                	cmp    %eax,%edx
f0102833:	75 6a                	jne    f010289f <mem_init+0x1658>
f0102835:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010283b:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102841:	75 d6                	jne    f0102819 <mem_init+0x15d2>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102843:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102848:	89 d8                	mov    %ebx,%eax
f010284a:	e8 ba e1 ff ff       	call   f0100a09 <check_va2pa>
f010284f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102852:	75 6c                	jne    f01028c0 <mem_init+0x1679>
	for (i = 0; i < NPDENTRIES; i++) {
f0102854:	b8 00 00 00 00       	mov    $0x0,%eax
f0102859:	e9 ac 00 00 00       	jmp    f010290a <mem_init+0x16c3>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010285e:	8d 87 90 d5 fe ff    	lea    -0x12a70(%edi),%eax
f0102864:	50                   	push   %eax
f0102865:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f010286b:	50                   	push   %eax
f010286c:	68 b1 02 00 00       	push   $0x2b1
f0102871:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102877:	50                   	push   %eax
f0102878:	89 fb                	mov    %edi,%ebx
f010287a:	e8 1a d8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010287f:	ff b7 fc ff ff ff    	pushl  -0x4(%edi)
f0102885:	8d 87 e0 d0 fe ff    	lea    -0x12f20(%edi),%eax
f010288b:	50                   	push   %eax
f010288c:	68 b5 02 00 00       	push   $0x2b5
f0102891:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102897:	50                   	push   %eax
f0102898:	89 fb                	mov    %edi,%ebx
f010289a:	e8 fa d7 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010289f:	8d 87 b8 d5 fe ff    	lea    -0x12a48(%edi),%eax
f01028a5:	50                   	push   %eax
f01028a6:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01028ac:	50                   	push   %eax
f01028ad:	68 b5 02 00 00       	push   $0x2b5
f01028b2:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01028b8:	50                   	push   %eax
f01028b9:	89 fb                	mov    %edi,%ebx
f01028bb:	e8 d9 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01028c0:	8d 87 00 d6 fe ff    	lea    -0x12a00(%edi),%eax
f01028c6:	50                   	push   %eax
f01028c7:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f01028cd:	50                   	push   %eax
f01028ce:	68 b6 02 00 00       	push   $0x2b6
f01028d3:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01028d9:	50                   	push   %eax
f01028da:	89 fb                	mov    %edi,%ebx
f01028dc:	e8 b8 d7 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f01028e1:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01028e5:	74 51                	je     f0102938 <mem_init+0x16f1>
	for (i = 0; i < NPDENTRIES; i++) {
f01028e7:	83 c0 01             	add    $0x1,%eax
f01028ea:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01028ef:	0f 87 b3 00 00 00    	ja     f01029a8 <mem_init+0x1761>
		switch (i) {
f01028f5:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01028fa:	72 0e                	jb     f010290a <mem_init+0x16c3>
f01028fc:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102901:	76 de                	jbe    f01028e1 <mem_init+0x169a>
f0102903:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102908:	74 d7                	je     f01028e1 <mem_init+0x169a>
			if (i >= PDX(KERNBASE)) {
f010290a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010290f:	77 48                	ja     f0102959 <mem_init+0x1712>
				assert(pgdir[i] == 0);
f0102911:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102915:	74 d0                	je     f01028e7 <mem_init+0x16a0>
f0102917:	8d 87 e9 d9 fe ff    	lea    -0x12617(%edi),%eax
f010291d:	50                   	push   %eax
f010291e:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102924:	50                   	push   %eax
f0102925:	68 c5 02 00 00       	push   $0x2c5
f010292a:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102930:	50                   	push   %eax
f0102931:	89 fb                	mov    %edi,%ebx
f0102933:	e8 61 d7 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102938:	8d 87 c7 d9 fe ff    	lea    -0x12639(%edi),%eax
f010293e:	50                   	push   %eax
f010293f:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102945:	50                   	push   %eax
f0102946:	68 be 02 00 00       	push   $0x2be
f010294b:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102951:	50                   	push   %eax
f0102952:	89 fb                	mov    %edi,%ebx
f0102954:	e8 40 d7 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102959:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f010295c:	f6 c2 01             	test   $0x1,%dl
f010295f:	74 26                	je     f0102987 <mem_init+0x1740>
				assert(pgdir[i] & PTE_W);
f0102961:	f6 c2 02             	test   $0x2,%dl
f0102964:	75 81                	jne    f01028e7 <mem_init+0x16a0>
f0102966:	8d 87 d8 d9 fe ff    	lea    -0x12628(%edi),%eax
f010296c:	50                   	push   %eax
f010296d:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102973:	50                   	push   %eax
f0102974:	68 c3 02 00 00       	push   $0x2c3
f0102979:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f010297f:	50                   	push   %eax
f0102980:	89 fb                	mov    %edi,%ebx
f0102982:	e8 12 d7 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102987:	8d 87 c7 d9 fe ff    	lea    -0x12639(%edi),%eax
f010298d:	50                   	push   %eax
f010298e:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102994:	50                   	push   %eax
f0102995:	68 c2 02 00 00       	push   $0x2c2
f010299a:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f01029a0:	50                   	push   %eax
f01029a1:	89 fb                	mov    %edi,%ebx
f01029a3:	e8 f1 d6 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f01029a8:	83 ec 0c             	sub    $0xc,%esp
f01029ab:	8d 87 30 d6 fe ff    	lea    -0x129d0(%edi),%eax
f01029b1:	50                   	push   %eax
f01029b2:	89 fb                	mov    %edi,%ebx
f01029b4:	e8 ca 04 00 00       	call   f0102e83 <cprintf>
	lcr3(PADDR(kern_pgdir));
f01029b9:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01029bf:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01029c1:	83 c4 10             	add    $0x10,%esp
f01029c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01029c9:	0f 86 33 02 00 00    	jbe    f0102c02 <mem_init+0x19bb>
	return (physaddr_t)kva - KERNBASE;
f01029cf:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029d4:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f01029d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01029dc:	e8 a5 e0 ff ff       	call   f0100a86 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01029e1:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01029e4:	83 e0 f3             	and    $0xfffffff3,%eax
f01029e7:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029ec:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029ef:	83 ec 0c             	sub    $0xc,%esp
f01029f2:	6a 00                	push   $0x0
f01029f4:	e8 32 e5 ff ff       	call   f0100f2b <page_alloc>
f01029f9:	89 c6                	mov    %eax,%esi
f01029fb:	83 c4 10             	add    $0x10,%esp
f01029fe:	85 c0                	test   %eax,%eax
f0102a00:	0f 84 15 02 00 00    	je     f0102c1b <mem_init+0x19d4>
	assert((pp1 = page_alloc(0)));
f0102a06:	83 ec 0c             	sub    $0xc,%esp
f0102a09:	6a 00                	push   $0x0
f0102a0b:	e8 1b e5 ff ff       	call   f0100f2b <page_alloc>
f0102a10:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102a13:	83 c4 10             	add    $0x10,%esp
f0102a16:	85 c0                	test   %eax,%eax
f0102a18:	0f 84 1c 02 00 00    	je     f0102c3a <mem_init+0x19f3>
	assert((pp2 = page_alloc(0)));
f0102a1e:	83 ec 0c             	sub    $0xc,%esp
f0102a21:	6a 00                	push   $0x0
f0102a23:	e8 03 e5 ff ff       	call   f0100f2b <page_alloc>
f0102a28:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a2b:	83 c4 10             	add    $0x10,%esp
f0102a2e:	85 c0                	test   %eax,%eax
f0102a30:	0f 84 23 02 00 00    	je     f0102c59 <mem_init+0x1a12>
	page_free(pp0);
f0102a36:	83 ec 0c             	sub    $0xc,%esp
f0102a39:	56                   	push   %esi
f0102a3a:	e8 74 e5 ff ff       	call   f0100fb3 <page_free>
	return (pp - pages) << PGSHIFT;
f0102a3f:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102a45:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a48:	2b 08                	sub    (%eax),%ecx
f0102a4a:	89 c8                	mov    %ecx,%eax
f0102a4c:	c1 f8 03             	sar    $0x3,%eax
f0102a4f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102a52:	89 c1                	mov    %eax,%ecx
f0102a54:	c1 e9 0c             	shr    $0xc,%ecx
f0102a57:	83 c4 10             	add    $0x10,%esp
f0102a5a:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102a60:	3b 0a                	cmp    (%edx),%ecx
f0102a62:	0f 83 10 02 00 00    	jae    f0102c78 <mem_init+0x1a31>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a68:	83 ec 04             	sub    $0x4,%esp
f0102a6b:	68 00 10 00 00       	push   $0x1000
f0102a70:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102a72:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a77:	50                   	push   %eax
f0102a78:	e8 62 0f 00 00       	call   f01039df <memset>
	return (pp - pages) << PGSHIFT;
f0102a7d:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102a83:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a86:	2b 08                	sub    (%eax),%ecx
f0102a88:	89 c8                	mov    %ecx,%eax
f0102a8a:	c1 f8 03             	sar    $0x3,%eax
f0102a8d:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102a90:	89 c1                	mov    %eax,%ecx
f0102a92:	c1 e9 0c             	shr    $0xc,%ecx
f0102a95:	83 c4 10             	add    $0x10,%esp
f0102a98:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102a9e:	3b 0a                	cmp    (%edx),%ecx
f0102aa0:	0f 83 e8 01 00 00    	jae    f0102c8e <mem_init+0x1a47>
	memset(page2kva(pp2), 2, PGSIZE);
f0102aa6:	83 ec 04             	sub    $0x4,%esp
f0102aa9:	68 00 10 00 00       	push   $0x1000
f0102aae:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102ab0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ab5:	50                   	push   %eax
f0102ab6:	e8 24 0f 00 00       	call   f01039df <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102abb:	6a 02                	push   $0x2
f0102abd:	68 00 10 00 00       	push   $0x1000
f0102ac2:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102ac5:	53                   	push   %ebx
f0102ac6:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102acc:	ff 30                	pushl  (%eax)
f0102ace:	e8 e8 e6 ff ff       	call   f01011bb <page_insert>
	assert(pp1->pp_ref == 1);
f0102ad3:	83 c4 20             	add    $0x20,%esp
f0102ad6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102adb:	0f 85 c3 01 00 00    	jne    f0102ca4 <mem_init+0x1a5d>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ae1:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ae8:	01 01 01 
f0102aeb:	0f 85 d4 01 00 00    	jne    f0102cc5 <mem_init+0x1a7e>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102af1:	6a 02                	push   $0x2
f0102af3:	68 00 10 00 00       	push   $0x1000
f0102af8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102afb:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102b01:	ff 30                	pushl  (%eax)
f0102b03:	e8 b3 e6 ff ff       	call   f01011bb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b08:	83 c4 10             	add    $0x10,%esp
f0102b0b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b12:	02 02 02 
f0102b15:	0f 85 cb 01 00 00    	jne    f0102ce6 <mem_init+0x1a9f>
	assert(pp2->pp_ref == 1);
f0102b1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b1e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102b23:	0f 85 de 01 00 00    	jne    f0102d07 <mem_init+0x1ac0>
	assert(pp1->pp_ref == 0);
f0102b29:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102b2c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102b31:	0f 85 f1 01 00 00    	jne    f0102d28 <mem_init+0x1ae1>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b37:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b3e:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102b41:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102b47:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102b4a:	2b 08                	sub    (%eax),%ecx
f0102b4c:	89 c8                	mov    %ecx,%eax
f0102b4e:	c1 f8 03             	sar    $0x3,%eax
f0102b51:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102b54:	89 c1                	mov    %eax,%ecx
f0102b56:	c1 e9 0c             	shr    $0xc,%ecx
f0102b59:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102b5f:	3b 0a                	cmp    (%edx),%ecx
f0102b61:	0f 83 e2 01 00 00    	jae    f0102d49 <mem_init+0x1b02>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b67:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102b6e:	03 03 03 
f0102b71:	0f 85 ea 01 00 00    	jne    f0102d61 <mem_init+0x1b1a>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b77:	83 ec 08             	sub    $0x8,%esp
f0102b7a:	68 00 10 00 00       	push   $0x1000
f0102b7f:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102b85:	ff 30                	pushl  (%eax)
f0102b87:	e8 eb e5 ff ff       	call   f0101177 <page_remove>
	assert(pp2->pp_ref == 0);
f0102b8c:	83 c4 10             	add    $0x10,%esp
f0102b8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b92:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102b97:	0f 85 e5 01 00 00    	jne    f0102d82 <mem_init+0x1b3b>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b9d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102ba3:	8b 08                	mov    (%eax),%ecx
f0102ba5:	8b 11                	mov    (%ecx),%edx
f0102ba7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102bad:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102bb3:	89 f3                	mov    %esi,%ebx
f0102bb5:	2b 18                	sub    (%eax),%ebx
f0102bb7:	89 d8                	mov    %ebx,%eax
f0102bb9:	c1 f8 03             	sar    $0x3,%eax
f0102bbc:	c1 e0 0c             	shl    $0xc,%eax
f0102bbf:	39 c2                	cmp    %eax,%edx
f0102bc1:	0f 85 dc 01 00 00    	jne    f0102da3 <mem_init+0x1b5c>
	kern_pgdir[0] = 0;
f0102bc7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102bcd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bd2:	0f 85 ec 01 00 00    	jne    f0102dc4 <mem_init+0x1b7d>
	pp0->pp_ref = 0;
f0102bd8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102bde:	83 ec 0c             	sub    $0xc,%esp
f0102be1:	56                   	push   %esi
f0102be2:	e8 cc e3 ff ff       	call   f0100fb3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102be7:	8d 87 c4 d6 fe ff    	lea    -0x1293c(%edi),%eax
f0102bed:	89 04 24             	mov    %eax,(%esp)
f0102bf0:	89 fb                	mov    %edi,%ebx
f0102bf2:	e8 8c 02 00 00       	call   f0102e83 <cprintf>
}
f0102bf7:	83 c4 10             	add    $0x10,%esp
f0102bfa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102bfd:	5b                   	pop    %ebx
f0102bfe:	5e                   	pop    %esi
f0102bff:	5f                   	pop    %edi
f0102c00:	5d                   	pop    %ebp
f0102c01:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c02:	50                   	push   %eax
f0102c03:	8d 87 e0 d0 fe ff    	lea    -0x12f20(%edi),%eax
f0102c09:	50                   	push   %eax
f0102c0a:	68 d0 00 00 00       	push   $0xd0
f0102c0f:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102c15:	50                   	push   %eax
f0102c16:	e8 7e d4 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102c1b:	8d 87 e5 d7 fe ff    	lea    -0x1281b(%edi),%eax
f0102c21:	50                   	push   %eax
f0102c22:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102c28:	50                   	push   %eax
f0102c29:	68 85 03 00 00       	push   $0x385
f0102c2e:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102c34:	50                   	push   %eax
f0102c35:	e8 5f d4 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102c3a:	8d 87 fb d7 fe ff    	lea    -0x12805(%edi),%eax
f0102c40:	50                   	push   %eax
f0102c41:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102c47:	50                   	push   %eax
f0102c48:	68 86 03 00 00       	push   $0x386
f0102c4d:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102c53:	50                   	push   %eax
f0102c54:	e8 40 d4 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102c59:	8d 87 11 d8 fe ff    	lea    -0x127ef(%edi),%eax
f0102c5f:	50                   	push   %eax
f0102c60:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102c66:	50                   	push   %eax
f0102c67:	68 87 03 00 00       	push   $0x387
f0102c6c:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102c72:	50                   	push   %eax
f0102c73:	e8 21 d4 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c78:	50                   	push   %eax
f0102c79:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f0102c7f:	50                   	push   %eax
f0102c80:	6a 52                	push   $0x52
f0102c82:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f0102c88:	50                   	push   %eax
f0102c89:	e8 0b d4 ff ff       	call   f0100099 <_panic>
f0102c8e:	50                   	push   %eax
f0102c8f:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f0102c95:	50                   	push   %eax
f0102c96:	6a 52                	push   $0x52
f0102c98:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f0102c9e:	50                   	push   %eax
f0102c9f:	e8 f5 d3 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102ca4:	8d 87 e2 d8 fe ff    	lea    -0x1271e(%edi),%eax
f0102caa:	50                   	push   %eax
f0102cab:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102cb1:	50                   	push   %eax
f0102cb2:	68 8c 03 00 00       	push   $0x38c
f0102cb7:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102cbd:	50                   	push   %eax
f0102cbe:	89 fb                	mov    %edi,%ebx
f0102cc0:	e8 d4 d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102cc5:	8d 87 50 d6 fe ff    	lea    -0x129b0(%edi),%eax
f0102ccb:	50                   	push   %eax
f0102ccc:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102cd2:	50                   	push   %eax
f0102cd3:	68 8d 03 00 00       	push   $0x38d
f0102cd8:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102cde:	50                   	push   %eax
f0102cdf:	89 fb                	mov    %edi,%ebx
f0102ce1:	e8 b3 d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ce6:	8d 87 74 d6 fe ff    	lea    -0x1298c(%edi),%eax
f0102cec:	50                   	push   %eax
f0102ced:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102cf3:	50                   	push   %eax
f0102cf4:	68 8f 03 00 00       	push   $0x38f
f0102cf9:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102cff:	50                   	push   %eax
f0102d00:	89 fb                	mov    %edi,%ebx
f0102d02:	e8 92 d3 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102d07:	8d 87 04 d9 fe ff    	lea    -0x126fc(%edi),%eax
f0102d0d:	50                   	push   %eax
f0102d0e:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102d14:	50                   	push   %eax
f0102d15:	68 90 03 00 00       	push   $0x390
f0102d1a:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102d20:	50                   	push   %eax
f0102d21:	89 fb                	mov    %edi,%ebx
f0102d23:	e8 71 d3 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102d28:	8d 87 6e d9 fe ff    	lea    -0x12692(%edi),%eax
f0102d2e:	50                   	push   %eax
f0102d2f:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102d35:	50                   	push   %eax
f0102d36:	68 91 03 00 00       	push   $0x391
f0102d3b:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102d41:	50                   	push   %eax
f0102d42:	89 fb                	mov    %edi,%ebx
f0102d44:	e8 50 d3 ff ff       	call   f0100099 <_panic>
f0102d49:	50                   	push   %eax
f0102d4a:	8d 87 78 cf fe ff    	lea    -0x13088(%edi),%eax
f0102d50:	50                   	push   %eax
f0102d51:	6a 52                	push   $0x52
f0102d53:	8d 87 fc d6 fe ff    	lea    -0x12904(%edi),%eax
f0102d59:	50                   	push   %eax
f0102d5a:	89 fb                	mov    %edi,%ebx
f0102d5c:	e8 38 d3 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d61:	8d 87 98 d6 fe ff    	lea    -0x12968(%edi),%eax
f0102d67:	50                   	push   %eax
f0102d68:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102d6e:	50                   	push   %eax
f0102d6f:	68 93 03 00 00       	push   $0x393
f0102d74:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102d7a:	50                   	push   %eax
f0102d7b:	89 fb                	mov    %edi,%ebx
f0102d7d:	e8 17 d3 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102d82:	8d 87 3c d9 fe ff    	lea    -0x126c4(%edi),%eax
f0102d88:	50                   	push   %eax
f0102d89:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102d8f:	50                   	push   %eax
f0102d90:	68 95 03 00 00       	push   $0x395
f0102d95:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102d9b:	50                   	push   %eax
f0102d9c:	89 fb                	mov    %edi,%ebx
f0102d9e:	e8 f6 d2 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102da3:	8d 87 dc d1 fe ff    	lea    -0x12e24(%edi),%eax
f0102da9:	50                   	push   %eax
f0102daa:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102db0:	50                   	push   %eax
f0102db1:	68 98 03 00 00       	push   $0x398
f0102db6:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102dbc:	50                   	push   %eax
f0102dbd:	89 fb                	mov    %edi,%ebx
f0102dbf:	e8 d5 d2 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102dc4:	8d 87 f3 d8 fe ff    	lea    -0x1270d(%edi),%eax
f0102dca:	50                   	push   %eax
f0102dcb:	8d 87 16 d7 fe ff    	lea    -0x128ea(%edi),%eax
f0102dd1:	50                   	push   %eax
f0102dd2:	68 9a 03 00 00       	push   $0x39a
f0102dd7:	8d 87 f0 d6 fe ff    	lea    -0x12910(%edi),%eax
f0102ddd:	50                   	push   %eax
f0102dde:	89 fb                	mov    %edi,%ebx
f0102de0:	e8 b4 d2 ff ff       	call   f0100099 <_panic>

f0102de5 <tlb_invalidate>:
{
f0102de5:	55                   	push   %ebp
f0102de6:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102de8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102deb:	0f 01 38             	invlpg (%eax)
}
f0102dee:	5d                   	pop    %ebp
f0102def:	c3                   	ret    

f0102df0 <__x86.get_pc_thunk.dx>:
f0102df0:	8b 14 24             	mov    (%esp),%edx
f0102df3:	c3                   	ret    

f0102df4 <__x86.get_pc_thunk.cx>:
f0102df4:	8b 0c 24             	mov    (%esp),%ecx
f0102df7:	c3                   	ret    

f0102df8 <__x86.get_pc_thunk.di>:
f0102df8:	8b 3c 24             	mov    (%esp),%edi
f0102dfb:	c3                   	ret    

f0102dfc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102dfc:	55                   	push   %ebp
f0102dfd:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102dff:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e02:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e07:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102e08:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e0d:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102e0e:	0f b6 c0             	movzbl %al,%eax
}
f0102e11:	5d                   	pop    %ebp
f0102e12:	c3                   	ret    

f0102e13 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102e13:	55                   	push   %ebp
f0102e14:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102e16:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e19:	ba 70 00 00 00       	mov    $0x70,%edx
f0102e1e:	ee                   	out    %al,(%dx)
f0102e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e22:	ba 71 00 00 00       	mov    $0x71,%edx
f0102e27:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102e28:	5d                   	pop    %ebp
f0102e29:	c3                   	ret    

f0102e2a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102e2a:	55                   	push   %ebp
f0102e2b:	89 e5                	mov    %esp,%ebp
f0102e2d:	53                   	push   %ebx
f0102e2e:	83 ec 10             	sub    $0x10,%esp
f0102e31:	e8 19 d3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102e36:	81 c3 d6 44 01 00    	add    $0x144d6,%ebx
	cputchar(ch);
f0102e3c:	ff 75 08             	pushl  0x8(%ebp)
f0102e3f:	e8 82 d8 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0102e44:	83 c4 10             	add    $0x10,%esp
f0102e47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e4a:	c9                   	leave  
f0102e4b:	c3                   	ret    

f0102e4c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102e4c:	55                   	push   %ebp
f0102e4d:	89 e5                	mov    %esp,%ebp
f0102e4f:	53                   	push   %ebx
f0102e50:	83 ec 14             	sub    $0x14,%esp
f0102e53:	e8 f7 d2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102e58:	81 c3 b4 44 01 00    	add    $0x144b4,%ebx
	int cnt = 0;
f0102e5e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e65:	ff 75 0c             	pushl  0xc(%ebp)
f0102e68:	ff 75 08             	pushl  0x8(%ebp)
f0102e6b:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e6e:	50                   	push   %eax
f0102e6f:	8d 83 1e bb fe ff    	lea    -0x144e2(%ebx),%eax
f0102e75:	50                   	push   %eax
f0102e76:	e8 18 04 00 00       	call   f0103293 <vprintfmt>
	return cnt;
}
f0102e7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e7e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102e81:	c9                   	leave  
f0102e82:	c3                   	ret    

f0102e83 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e83:	55                   	push   %ebp
f0102e84:	89 e5                	mov    %esp,%ebp
f0102e86:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e89:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e8c:	50                   	push   %eax
f0102e8d:	ff 75 08             	pushl  0x8(%ebp)
f0102e90:	e8 b7 ff ff ff       	call   f0102e4c <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e95:	c9                   	leave  
f0102e96:	c3                   	ret    

f0102e97 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e97:	55                   	push   %ebp
f0102e98:	89 e5                	mov    %esp,%ebp
f0102e9a:	57                   	push   %edi
f0102e9b:	56                   	push   %esi
f0102e9c:	53                   	push   %ebx
f0102e9d:	83 ec 14             	sub    $0x14,%esp
f0102ea0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102ea3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102ea6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ea9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102eac:	8b 32                	mov    (%edx),%esi
f0102eae:	8b 01                	mov    (%ecx),%eax
f0102eb0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102eb3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102eba:	eb 2f                	jmp    f0102eeb <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102ebc:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0102ebf:	39 c6                	cmp    %eax,%esi
f0102ec1:	7f 49                	jg     f0102f0c <stab_binsearch+0x75>
f0102ec3:	0f b6 0a             	movzbl (%edx),%ecx
f0102ec6:	83 ea 0c             	sub    $0xc,%edx
f0102ec9:	39 f9                	cmp    %edi,%ecx
f0102ecb:	75 ef                	jne    f0102ebc <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102ecd:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102ed0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102ed3:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102ed7:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102eda:	73 35                	jae    f0102f11 <stab_binsearch+0x7a>
			*region_left = m;
f0102edc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102edf:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0102ee1:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0102ee4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0102eeb:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0102eee:	7f 4e                	jg     f0102f3e <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0102ef0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102ef3:	01 f0                	add    %esi,%eax
f0102ef5:	89 c3                	mov    %eax,%ebx
f0102ef7:	c1 eb 1f             	shr    $0x1f,%ebx
f0102efa:	01 c3                	add    %eax,%ebx
f0102efc:	d1 fb                	sar    %ebx
f0102efe:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0102f01:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102f04:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0102f08:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0102f0a:	eb b3                	jmp    f0102ebf <stab_binsearch+0x28>
			l = true_m + 1;
f0102f0c:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0102f0f:	eb da                	jmp    f0102eeb <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0102f11:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f14:	76 14                	jbe    f0102f2a <stab_binsearch+0x93>
			*region_right = m - 1;
f0102f16:	83 e8 01             	sub    $0x1,%eax
f0102f19:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102f1c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102f1f:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0102f21:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102f28:	eb c1                	jmp    f0102eeb <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102f2a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102f2d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0102f2f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102f33:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0102f35:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102f3c:	eb ad                	jmp    f0102eeb <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0102f3e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102f42:	74 16                	je     f0102f5a <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102f44:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f47:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102f49:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102f4c:	8b 0e                	mov    (%esi),%ecx
f0102f4e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102f51:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102f54:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0102f58:	eb 12                	jmp    f0102f6c <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0102f5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f5d:	8b 00                	mov    (%eax),%eax
f0102f5f:	83 e8 01             	sub    $0x1,%eax
f0102f62:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102f65:	89 07                	mov    %eax,(%edi)
f0102f67:	eb 16                	jmp    f0102f7f <stab_binsearch+0xe8>
		     l--)
f0102f69:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0102f6c:	39 c1                	cmp    %eax,%ecx
f0102f6e:	7d 0a                	jge    f0102f7a <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0102f70:	0f b6 1a             	movzbl (%edx),%ebx
f0102f73:	83 ea 0c             	sub    $0xc,%edx
f0102f76:	39 fb                	cmp    %edi,%ebx
f0102f78:	75 ef                	jne    f0102f69 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0102f7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102f7d:	89 07                	mov    %eax,(%edi)
	}
}
f0102f7f:	83 c4 14             	add    $0x14,%esp
f0102f82:	5b                   	pop    %ebx
f0102f83:	5e                   	pop    %esi
f0102f84:	5f                   	pop    %edi
f0102f85:	5d                   	pop    %ebp
f0102f86:	c3                   	ret    

f0102f87 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f87:	55                   	push   %ebp
f0102f88:	89 e5                	mov    %esp,%ebp
f0102f8a:	57                   	push   %edi
f0102f8b:	56                   	push   %esi
f0102f8c:	53                   	push   %ebx
f0102f8d:	83 ec 2c             	sub    $0x2c,%esp
f0102f90:	e8 5f fe ff ff       	call   f0102df4 <__x86.get_pc_thunk.cx>
f0102f95:	81 c1 77 43 01 00    	add    $0x14377,%ecx
f0102f9b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102f9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102fa1:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102fa4:	8d 81 f7 d9 fe ff    	lea    -0x12609(%ecx),%eax
f0102faa:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0102fac:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0102fb3:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0102fb6:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0102fbd:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0102fc0:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102fc7:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102fcd:	0f 86 f4 00 00 00    	jbe    f01030c7 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102fd3:	c7 c0 69 b4 10 f0    	mov    $0xf010b469,%eax
f0102fd9:	39 81 f8 ff ff ff    	cmp    %eax,-0x8(%ecx)
f0102fdf:	0f 86 88 01 00 00    	jbe    f010316d <debuginfo_eip+0x1e6>
f0102fe5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102fe8:	c7 c0 37 d2 10 f0    	mov    $0xf010d237,%eax
f0102fee:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0102ff2:	0f 85 7c 01 00 00    	jne    f0103174 <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102ff8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102fff:	c7 c0 1c 4f 10 f0    	mov    $0xf0104f1c,%eax
f0103005:	c7 c2 68 b4 10 f0    	mov    $0xf010b468,%edx
f010300b:	29 c2                	sub    %eax,%edx
f010300d:	c1 fa 02             	sar    $0x2,%edx
f0103010:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103016:	83 ea 01             	sub    $0x1,%edx
f0103019:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010301c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010301f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103022:	83 ec 08             	sub    $0x8,%esp
f0103025:	53                   	push   %ebx
f0103026:	6a 64                	push   $0x64
f0103028:	e8 6a fe ff ff       	call   f0102e97 <stab_binsearch>
	if (lfile == 0)
f010302d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103030:	83 c4 10             	add    $0x10,%esp
f0103033:	85 c0                	test   %eax,%eax
f0103035:	0f 84 40 01 00 00    	je     f010317b <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010303b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010303e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103041:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103044:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103047:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010304a:	83 ec 08             	sub    $0x8,%esp
f010304d:	53                   	push   %ebx
f010304e:	6a 24                	push   $0x24
f0103050:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103053:	c7 c0 1c 4f 10 f0    	mov    $0xf0104f1c,%eax
f0103059:	e8 39 fe ff ff       	call   f0102e97 <stab_binsearch>

	if (lfun <= rfun) {
f010305e:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103061:	83 c4 10             	add    $0x10,%esp
f0103064:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0103067:	7f 79                	jg     f01030e2 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103069:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010306c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010306f:	c7 c2 1c 4f 10 f0    	mov    $0xf0104f1c,%edx
f0103075:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103078:	8b 11                	mov    (%ecx),%edx
f010307a:	c7 c0 37 d2 10 f0    	mov    $0xf010d237,%eax
f0103080:	81 e8 69 b4 10 f0    	sub    $0xf010b469,%eax
f0103086:	39 c2                	cmp    %eax,%edx
f0103088:	73 09                	jae    f0103093 <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010308a:	81 c2 69 b4 10 f0    	add    $0xf010b469,%edx
f0103090:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103093:	8b 41 08             	mov    0x8(%ecx),%eax
f0103096:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103099:	83 ec 08             	sub    $0x8,%esp
f010309c:	6a 3a                	push   $0x3a
f010309e:	ff 77 08             	pushl  0x8(%edi)
f01030a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030a4:	e8 1a 09 00 00       	call   f01039c3 <strfind>
f01030a9:	2b 47 08             	sub    0x8(%edi),%eax
f01030ac:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01030af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01030b2:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01030b5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01030b8:	c7 c2 1c 4f 10 f0    	mov    $0xf0104f1c,%edx
f01030be:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01030c2:	83 c4 10             	add    $0x10,%esp
f01030c5:	eb 29                	jmp    f01030f0 <debuginfo_eip+0x169>
  	        panic("User address");
f01030c7:	83 ec 04             	sub    $0x4,%esp
f01030ca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030cd:	8d 83 01 da fe ff    	lea    -0x125ff(%ebx),%eax
f01030d3:	50                   	push   %eax
f01030d4:	6a 7f                	push   $0x7f
f01030d6:	8d 83 0e da fe ff    	lea    -0x125f2(%ebx),%eax
f01030dc:	50                   	push   %eax
f01030dd:	e8 b7 cf ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f01030e2:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f01030e5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01030e8:	eb af                	jmp    f0103099 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01030ea:	83 ee 01             	sub    $0x1,%esi
f01030ed:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f01030f0:	39 f3                	cmp    %esi,%ebx
f01030f2:	7f 3a                	jg     f010312e <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f01030f4:	0f b6 10             	movzbl (%eax),%edx
f01030f7:	80 fa 84             	cmp    $0x84,%dl
f01030fa:	74 0b                	je     f0103107 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01030fc:	80 fa 64             	cmp    $0x64,%dl
f01030ff:	75 e9                	jne    f01030ea <debuginfo_eip+0x163>
f0103101:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0103105:	74 e3                	je     f01030ea <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103107:	8d 14 76             	lea    (%esi,%esi,2),%edx
f010310a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010310d:	c7 c0 1c 4f 10 f0    	mov    $0xf0104f1c,%eax
f0103113:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103116:	c7 c0 37 d2 10 f0    	mov    $0xf010d237,%eax
f010311c:	81 e8 69 b4 10 f0    	sub    $0xf010b469,%eax
f0103122:	39 c2                	cmp    %eax,%edx
f0103124:	73 08                	jae    f010312e <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103126:	81 c2 69 b4 10 f0    	add    $0xf010b469,%edx
f010312c:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010312e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103131:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103134:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103139:	39 cb                	cmp    %ecx,%ebx
f010313b:	7d 4a                	jge    f0103187 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f010313d:	8d 53 01             	lea    0x1(%ebx),%edx
f0103140:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0103143:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103146:	c7 c0 1c 4f 10 f0    	mov    $0xf0104f1c,%eax
f010314c:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0103150:	eb 07                	jmp    f0103159 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0103152:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0103156:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103159:	39 d1                	cmp    %edx,%ecx
f010315b:	74 25                	je     f0103182 <debuginfo_eip+0x1fb>
f010315d:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103160:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103164:	74 ec                	je     f0103152 <debuginfo_eip+0x1cb>
	return 0;
f0103166:	b8 00 00 00 00       	mov    $0x0,%eax
f010316b:	eb 1a                	jmp    f0103187 <debuginfo_eip+0x200>
		return -1;
f010316d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103172:	eb 13                	jmp    f0103187 <debuginfo_eip+0x200>
f0103174:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103179:	eb 0c                	jmp    f0103187 <debuginfo_eip+0x200>
		return -1;
f010317b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103180:	eb 05                	jmp    f0103187 <debuginfo_eip+0x200>
	return 0;
f0103182:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103187:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010318a:	5b                   	pop    %ebx
f010318b:	5e                   	pop    %esi
f010318c:	5f                   	pop    %edi
f010318d:	5d                   	pop    %ebp
f010318e:	c3                   	ret    

f010318f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010318f:	55                   	push   %ebp
f0103190:	89 e5                	mov    %esp,%ebp
f0103192:	57                   	push   %edi
f0103193:	56                   	push   %esi
f0103194:	53                   	push   %ebx
f0103195:	83 ec 2c             	sub    $0x2c,%esp
f0103198:	e8 57 fc ff ff       	call   f0102df4 <__x86.get_pc_thunk.cx>
f010319d:	81 c1 6f 41 01 00    	add    $0x1416f,%ecx
f01031a3:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01031a6:	89 c7                	mov    %eax,%edi
f01031a8:	89 d6                	mov    %edx,%esi
f01031aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01031b0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01031b3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01031b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01031b9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01031be:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01031c1:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01031c4:	39 d3                	cmp    %edx,%ebx
f01031c6:	72 09                	jb     f01031d1 <printnum+0x42>
f01031c8:	39 45 10             	cmp    %eax,0x10(%ebp)
f01031cb:	0f 87 83 00 00 00    	ja     f0103254 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01031d1:	83 ec 0c             	sub    $0xc,%esp
f01031d4:	ff 75 18             	pushl  0x18(%ebp)
f01031d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01031da:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01031dd:	53                   	push   %ebx
f01031de:	ff 75 10             	pushl  0x10(%ebp)
f01031e1:	83 ec 08             	sub    $0x8,%esp
f01031e4:	ff 75 dc             	pushl  -0x24(%ebp)
f01031e7:	ff 75 d8             	pushl  -0x28(%ebp)
f01031ea:	ff 75 d4             	pushl  -0x2c(%ebp)
f01031ed:	ff 75 d0             	pushl  -0x30(%ebp)
f01031f0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01031f3:	e8 e8 09 00 00       	call   f0103be0 <__udivdi3>
f01031f8:	83 c4 18             	add    $0x18,%esp
f01031fb:	52                   	push   %edx
f01031fc:	50                   	push   %eax
f01031fd:	89 f2                	mov    %esi,%edx
f01031ff:	89 f8                	mov    %edi,%eax
f0103201:	e8 89 ff ff ff       	call   f010318f <printnum>
f0103206:	83 c4 20             	add    $0x20,%esp
f0103209:	eb 13                	jmp    f010321e <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010320b:	83 ec 08             	sub    $0x8,%esp
f010320e:	56                   	push   %esi
f010320f:	ff 75 18             	pushl  0x18(%ebp)
f0103212:	ff d7                	call   *%edi
f0103214:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103217:	83 eb 01             	sub    $0x1,%ebx
f010321a:	85 db                	test   %ebx,%ebx
f010321c:	7f ed                	jg     f010320b <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010321e:	83 ec 08             	sub    $0x8,%esp
f0103221:	56                   	push   %esi
f0103222:	83 ec 04             	sub    $0x4,%esp
f0103225:	ff 75 dc             	pushl  -0x24(%ebp)
f0103228:	ff 75 d8             	pushl  -0x28(%ebp)
f010322b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010322e:	ff 75 d0             	pushl  -0x30(%ebp)
f0103231:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103234:	89 f3                	mov    %esi,%ebx
f0103236:	e8 c5 0a 00 00       	call   f0103d00 <__umoddi3>
f010323b:	83 c4 14             	add    $0x14,%esp
f010323e:	0f be 84 06 1c da fe 	movsbl -0x125e4(%esi,%eax,1),%eax
f0103245:	ff 
f0103246:	50                   	push   %eax
f0103247:	ff d7                	call   *%edi
}
f0103249:	83 c4 10             	add    $0x10,%esp
f010324c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010324f:	5b                   	pop    %ebx
f0103250:	5e                   	pop    %esi
f0103251:	5f                   	pop    %edi
f0103252:	5d                   	pop    %ebp
f0103253:	c3                   	ret    
f0103254:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103257:	eb be                	jmp    f0103217 <printnum+0x88>

f0103259 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103259:	55                   	push   %ebp
f010325a:	89 e5                	mov    %esp,%ebp
f010325c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010325f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103263:	8b 10                	mov    (%eax),%edx
f0103265:	3b 50 04             	cmp    0x4(%eax),%edx
f0103268:	73 0a                	jae    f0103274 <sprintputch+0x1b>
		*b->buf++ = ch;
f010326a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010326d:	89 08                	mov    %ecx,(%eax)
f010326f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103272:	88 02                	mov    %al,(%edx)
}
f0103274:	5d                   	pop    %ebp
f0103275:	c3                   	ret    

f0103276 <printfmt>:
{
f0103276:	55                   	push   %ebp
f0103277:	89 e5                	mov    %esp,%ebp
f0103279:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010327c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010327f:	50                   	push   %eax
f0103280:	ff 75 10             	pushl  0x10(%ebp)
f0103283:	ff 75 0c             	pushl  0xc(%ebp)
f0103286:	ff 75 08             	pushl  0x8(%ebp)
f0103289:	e8 05 00 00 00       	call   f0103293 <vprintfmt>
}
f010328e:	83 c4 10             	add    $0x10,%esp
f0103291:	c9                   	leave  
f0103292:	c3                   	ret    

f0103293 <vprintfmt>:
{
f0103293:	55                   	push   %ebp
f0103294:	89 e5                	mov    %esp,%ebp
f0103296:	57                   	push   %edi
f0103297:	56                   	push   %esi
f0103298:	53                   	push   %ebx
f0103299:	83 ec 2c             	sub    $0x2c,%esp
f010329c:	e8 ae ce ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01032a1:	81 c3 6b 40 01 00    	add    $0x1406b,%ebx
f01032a7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01032aa:	8b 7d 10             	mov    0x10(%ebp),%edi
f01032ad:	e9 8e 03 00 00       	jmp    f0103640 <.L35+0x48>
		padc = ' ';
f01032b2:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01032b6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01032bd:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f01032c4:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01032cb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032d0:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01032d3:	8d 47 01             	lea    0x1(%edi),%eax
f01032d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032d9:	0f b6 17             	movzbl (%edi),%edx
f01032dc:	8d 42 dd             	lea    -0x23(%edx),%eax
f01032df:	3c 55                	cmp    $0x55,%al
f01032e1:	0f 87 e1 03 00 00    	ja     f01036c8 <.L22>
f01032e7:	0f b6 c0             	movzbl %al,%eax
f01032ea:	89 d9                	mov    %ebx,%ecx
f01032ec:	03 8c 83 a8 da fe ff 	add    -0x12558(%ebx,%eax,4),%ecx
f01032f3:	ff e1                	jmp    *%ecx

f01032f5 <.L67>:
f01032f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01032f8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01032fc:	eb d5                	jmp    f01032d3 <vprintfmt+0x40>

f01032fe <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01032fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0103301:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103305:	eb cc                	jmp    f01032d3 <vprintfmt+0x40>

f0103307 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0103307:	0f b6 d2             	movzbl %dl,%edx
f010330a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010330d:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0103312:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103315:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103319:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010331c:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010331f:	83 f9 09             	cmp    $0x9,%ecx
f0103322:	77 55                	ja     f0103379 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0103324:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103327:	eb e9                	jmp    f0103312 <.L29+0xb>

f0103329 <.L26>:
			precision = va_arg(ap, int);
f0103329:	8b 45 14             	mov    0x14(%ebp),%eax
f010332c:	8b 00                	mov    (%eax),%eax
f010332e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103331:	8b 45 14             	mov    0x14(%ebp),%eax
f0103334:	8d 40 04             	lea    0x4(%eax),%eax
f0103337:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010333a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f010333d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103341:	79 90                	jns    f01032d3 <vprintfmt+0x40>
				width = precision, precision = -1;
f0103343:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103346:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103349:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103350:	eb 81                	jmp    f01032d3 <vprintfmt+0x40>

f0103352 <.L27>:
f0103352:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103355:	85 c0                	test   %eax,%eax
f0103357:	ba 00 00 00 00       	mov    $0x0,%edx
f010335c:	0f 49 d0             	cmovns %eax,%edx
f010335f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103362:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103365:	e9 69 ff ff ff       	jmp    f01032d3 <vprintfmt+0x40>

f010336a <.L23>:
f010336a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010336d:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103374:	e9 5a ff ff ff       	jmp    f01032d3 <vprintfmt+0x40>
f0103379:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010337c:	eb bf                	jmp    f010333d <.L26+0x14>

f010337e <.L33>:
			lflag++;
f010337e:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103382:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0103385:	e9 49 ff ff ff       	jmp    f01032d3 <vprintfmt+0x40>

f010338a <.L30>:
			putch(va_arg(ap, int), putdat);
f010338a:	8b 45 14             	mov    0x14(%ebp),%eax
f010338d:	8d 78 04             	lea    0x4(%eax),%edi
f0103390:	83 ec 08             	sub    $0x8,%esp
f0103393:	56                   	push   %esi
f0103394:	ff 30                	pushl  (%eax)
f0103396:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103399:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010339c:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010339f:	e9 99 02 00 00       	jmp    f010363d <.L35+0x45>

f01033a4 <.L32>:
			err = va_arg(ap, int);
f01033a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01033a7:	8d 78 04             	lea    0x4(%eax),%edi
f01033aa:	8b 00                	mov    (%eax),%eax
f01033ac:	99                   	cltd   
f01033ad:	31 d0                	xor    %edx,%eax
f01033af:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033b1:	83 f8 06             	cmp    $0x6,%eax
f01033b4:	7f 27                	jg     f01033dd <.L32+0x39>
f01033b6:	8b 94 83 1c 1d 00 00 	mov    0x1d1c(%ebx,%eax,4),%edx
f01033bd:	85 d2                	test   %edx,%edx
f01033bf:	74 1c                	je     f01033dd <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01033c1:	52                   	push   %edx
f01033c2:	8d 83 28 d7 fe ff    	lea    -0x128d8(%ebx),%eax
f01033c8:	50                   	push   %eax
f01033c9:	56                   	push   %esi
f01033ca:	ff 75 08             	pushl  0x8(%ebp)
f01033cd:	e8 a4 fe ff ff       	call   f0103276 <printfmt>
f01033d2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01033d5:	89 7d 14             	mov    %edi,0x14(%ebp)
f01033d8:	e9 60 02 00 00       	jmp    f010363d <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f01033dd:	50                   	push   %eax
f01033de:	8d 83 34 da fe ff    	lea    -0x125cc(%ebx),%eax
f01033e4:	50                   	push   %eax
f01033e5:	56                   	push   %esi
f01033e6:	ff 75 08             	pushl  0x8(%ebp)
f01033e9:	e8 88 fe ff ff       	call   f0103276 <printfmt>
f01033ee:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01033f1:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01033f4:	e9 44 02 00 00       	jmp    f010363d <.L35+0x45>

f01033f9 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01033f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01033fc:	83 c0 04             	add    $0x4,%eax
f01033ff:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103402:	8b 45 14             	mov    0x14(%ebp),%eax
f0103405:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103407:	85 ff                	test   %edi,%edi
f0103409:	8d 83 2d da fe ff    	lea    -0x125d3(%ebx),%eax
f010340f:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103412:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103416:	0f 8e b5 00 00 00    	jle    f01034d1 <.L36+0xd8>
f010341c:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103420:	75 08                	jne    f010342a <.L36+0x31>
f0103422:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103425:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103428:	eb 6d                	jmp    f0103497 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010342a:	83 ec 08             	sub    $0x8,%esp
f010342d:	ff 75 d0             	pushl  -0x30(%ebp)
f0103430:	57                   	push   %edi
f0103431:	e8 49 04 00 00       	call   f010387f <strnlen>
f0103436:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103439:	29 c2                	sub    %eax,%edx
f010343b:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010343e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103441:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103445:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103448:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010344b:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f010344d:	eb 10                	jmp    f010345f <.L36+0x66>
					putch(padc, putdat);
f010344f:	83 ec 08             	sub    $0x8,%esp
f0103452:	56                   	push   %esi
f0103453:	ff 75 e0             	pushl  -0x20(%ebp)
f0103456:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103459:	83 ef 01             	sub    $0x1,%edi
f010345c:	83 c4 10             	add    $0x10,%esp
f010345f:	85 ff                	test   %edi,%edi
f0103461:	7f ec                	jg     f010344f <.L36+0x56>
f0103463:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103466:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103469:	85 d2                	test   %edx,%edx
f010346b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103470:	0f 49 c2             	cmovns %edx,%eax
f0103473:	29 c2                	sub    %eax,%edx
f0103475:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103478:	89 75 0c             	mov    %esi,0xc(%ebp)
f010347b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010347e:	eb 17                	jmp    f0103497 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103480:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103484:	75 30                	jne    f01034b6 <.L36+0xbd>
					putch(ch, putdat);
f0103486:	83 ec 08             	sub    $0x8,%esp
f0103489:	ff 75 0c             	pushl  0xc(%ebp)
f010348c:	50                   	push   %eax
f010348d:	ff 55 08             	call   *0x8(%ebp)
f0103490:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103493:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103497:	83 c7 01             	add    $0x1,%edi
f010349a:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010349e:	0f be c2             	movsbl %dl,%eax
f01034a1:	85 c0                	test   %eax,%eax
f01034a3:	74 52                	je     f01034f7 <.L36+0xfe>
f01034a5:	85 f6                	test   %esi,%esi
f01034a7:	78 d7                	js     f0103480 <.L36+0x87>
f01034a9:	83 ee 01             	sub    $0x1,%esi
f01034ac:	79 d2                	jns    f0103480 <.L36+0x87>
f01034ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034b1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01034b4:	eb 32                	jmp    f01034e8 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01034b6:	0f be d2             	movsbl %dl,%edx
f01034b9:	83 ea 20             	sub    $0x20,%edx
f01034bc:	83 fa 5e             	cmp    $0x5e,%edx
f01034bf:	76 c5                	jbe    f0103486 <.L36+0x8d>
					putch('?', putdat);
f01034c1:	83 ec 08             	sub    $0x8,%esp
f01034c4:	ff 75 0c             	pushl  0xc(%ebp)
f01034c7:	6a 3f                	push   $0x3f
f01034c9:	ff 55 08             	call   *0x8(%ebp)
f01034cc:	83 c4 10             	add    $0x10,%esp
f01034cf:	eb c2                	jmp    f0103493 <.L36+0x9a>
f01034d1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01034d4:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01034d7:	eb be                	jmp    f0103497 <.L36+0x9e>
				putch(' ', putdat);
f01034d9:	83 ec 08             	sub    $0x8,%esp
f01034dc:	56                   	push   %esi
f01034dd:	6a 20                	push   $0x20
f01034df:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01034e2:	83 ef 01             	sub    $0x1,%edi
f01034e5:	83 c4 10             	add    $0x10,%esp
f01034e8:	85 ff                	test   %edi,%edi
f01034ea:	7f ed                	jg     f01034d9 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01034ec:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01034ef:	89 45 14             	mov    %eax,0x14(%ebp)
f01034f2:	e9 46 01 00 00       	jmp    f010363d <.L35+0x45>
f01034f7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01034fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01034fd:	eb e9                	jmp    f01034e8 <.L36+0xef>

f01034ff <.L31>:
f01034ff:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103502:	83 f9 01             	cmp    $0x1,%ecx
f0103505:	7e 40                	jle    f0103547 <.L31+0x48>
		return va_arg(*ap, long long);
f0103507:	8b 45 14             	mov    0x14(%ebp),%eax
f010350a:	8b 50 04             	mov    0x4(%eax),%edx
f010350d:	8b 00                	mov    (%eax),%eax
f010350f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103512:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103515:	8b 45 14             	mov    0x14(%ebp),%eax
f0103518:	8d 40 08             	lea    0x8(%eax),%eax
f010351b:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f010351e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103522:	79 55                	jns    f0103579 <.L31+0x7a>
				putch('-', putdat);
f0103524:	83 ec 08             	sub    $0x8,%esp
f0103527:	56                   	push   %esi
f0103528:	6a 2d                	push   $0x2d
f010352a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010352d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103530:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103533:	f7 da                	neg    %edx
f0103535:	83 d1 00             	adc    $0x0,%ecx
f0103538:	f7 d9                	neg    %ecx
f010353a:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010353d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103542:	e9 db 00 00 00       	jmp    f0103622 <.L35+0x2a>
	else if (lflag)
f0103547:	85 c9                	test   %ecx,%ecx
f0103549:	75 17                	jne    f0103562 <.L31+0x63>
		return va_arg(*ap, int);
f010354b:	8b 45 14             	mov    0x14(%ebp),%eax
f010354e:	8b 00                	mov    (%eax),%eax
f0103550:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103553:	99                   	cltd   
f0103554:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103557:	8b 45 14             	mov    0x14(%ebp),%eax
f010355a:	8d 40 04             	lea    0x4(%eax),%eax
f010355d:	89 45 14             	mov    %eax,0x14(%ebp)
f0103560:	eb bc                	jmp    f010351e <.L31+0x1f>
		return va_arg(*ap, long);
f0103562:	8b 45 14             	mov    0x14(%ebp),%eax
f0103565:	8b 00                	mov    (%eax),%eax
f0103567:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010356a:	99                   	cltd   
f010356b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010356e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103571:	8d 40 04             	lea    0x4(%eax),%eax
f0103574:	89 45 14             	mov    %eax,0x14(%ebp)
f0103577:	eb a5                	jmp    f010351e <.L31+0x1f>
			num = getint(&ap, lflag);
f0103579:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010357c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010357f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103584:	e9 99 00 00 00       	jmp    f0103622 <.L35+0x2a>

f0103589 <.L37>:
f0103589:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f010358c:	83 f9 01             	cmp    $0x1,%ecx
f010358f:	7e 15                	jle    f01035a6 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0103591:	8b 45 14             	mov    0x14(%ebp),%eax
f0103594:	8b 10                	mov    (%eax),%edx
f0103596:	8b 48 04             	mov    0x4(%eax),%ecx
f0103599:	8d 40 08             	lea    0x8(%eax),%eax
f010359c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010359f:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035a4:	eb 7c                	jmp    f0103622 <.L35+0x2a>
	else if (lflag)
f01035a6:	85 c9                	test   %ecx,%ecx
f01035a8:	75 17                	jne    f01035c1 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01035aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01035ad:	8b 10                	mov    (%eax),%edx
f01035af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035b4:	8d 40 04             	lea    0x4(%eax),%eax
f01035b7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01035ba:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035bf:	eb 61                	jmp    f0103622 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f01035c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01035c4:	8b 10                	mov    (%eax),%edx
f01035c6:	b9 00 00 00 00       	mov    $0x0,%ecx
f01035cb:	8d 40 04             	lea    0x4(%eax),%eax
f01035ce:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01035d1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01035d6:	eb 4a                	jmp    f0103622 <.L35+0x2a>

f01035d8 <.L34>:
			putch('X', putdat);
f01035d8:	83 ec 08             	sub    $0x8,%esp
f01035db:	56                   	push   %esi
f01035dc:	6a 58                	push   $0x58
f01035de:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01035e1:	83 c4 08             	add    $0x8,%esp
f01035e4:	56                   	push   %esi
f01035e5:	6a 58                	push   $0x58
f01035e7:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01035ea:	83 c4 08             	add    $0x8,%esp
f01035ed:	56                   	push   %esi
f01035ee:	6a 58                	push   $0x58
f01035f0:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035f3:	83 c4 10             	add    $0x10,%esp
f01035f6:	eb 45                	jmp    f010363d <.L35+0x45>

f01035f8 <.L35>:
			putch('0', putdat);
f01035f8:	83 ec 08             	sub    $0x8,%esp
f01035fb:	56                   	push   %esi
f01035fc:	6a 30                	push   $0x30
f01035fe:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103601:	83 c4 08             	add    $0x8,%esp
f0103604:	56                   	push   %esi
f0103605:	6a 78                	push   $0x78
f0103607:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010360a:	8b 45 14             	mov    0x14(%ebp),%eax
f010360d:	8b 10                	mov    (%eax),%edx
f010360f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103614:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103617:	8d 40 04             	lea    0x4(%eax),%eax
f010361a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010361d:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103622:	83 ec 0c             	sub    $0xc,%esp
f0103625:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103629:	57                   	push   %edi
f010362a:	ff 75 e0             	pushl  -0x20(%ebp)
f010362d:	50                   	push   %eax
f010362e:	51                   	push   %ecx
f010362f:	52                   	push   %edx
f0103630:	89 f2                	mov    %esi,%edx
f0103632:	8b 45 08             	mov    0x8(%ebp),%eax
f0103635:	e8 55 fb ff ff       	call   f010318f <printnum>
			break;
f010363a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010363d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103640:	83 c7 01             	add    $0x1,%edi
f0103643:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103647:	83 f8 25             	cmp    $0x25,%eax
f010364a:	0f 84 62 fc ff ff    	je     f01032b2 <vprintfmt+0x1f>
			if (ch == '\0')
f0103650:	85 c0                	test   %eax,%eax
f0103652:	0f 84 91 00 00 00    	je     f01036e9 <.L22+0x21>
			putch(ch, putdat);
f0103658:	83 ec 08             	sub    $0x8,%esp
f010365b:	56                   	push   %esi
f010365c:	50                   	push   %eax
f010365d:	ff 55 08             	call   *0x8(%ebp)
f0103660:	83 c4 10             	add    $0x10,%esp
f0103663:	eb db                	jmp    f0103640 <.L35+0x48>

f0103665 <.L38>:
f0103665:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103668:	83 f9 01             	cmp    $0x1,%ecx
f010366b:	7e 15                	jle    f0103682 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f010366d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103670:	8b 10                	mov    (%eax),%edx
f0103672:	8b 48 04             	mov    0x4(%eax),%ecx
f0103675:	8d 40 08             	lea    0x8(%eax),%eax
f0103678:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010367b:	b8 10 00 00 00       	mov    $0x10,%eax
f0103680:	eb a0                	jmp    f0103622 <.L35+0x2a>
	else if (lflag)
f0103682:	85 c9                	test   %ecx,%ecx
f0103684:	75 17                	jne    f010369d <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103686:	8b 45 14             	mov    0x14(%ebp),%eax
f0103689:	8b 10                	mov    (%eax),%edx
f010368b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103690:	8d 40 04             	lea    0x4(%eax),%eax
f0103693:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103696:	b8 10 00 00 00       	mov    $0x10,%eax
f010369b:	eb 85                	jmp    f0103622 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f010369d:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a0:	8b 10                	mov    (%eax),%edx
f01036a2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036a7:	8d 40 04             	lea    0x4(%eax),%eax
f01036aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01036ad:	b8 10 00 00 00       	mov    $0x10,%eax
f01036b2:	e9 6b ff ff ff       	jmp    f0103622 <.L35+0x2a>

f01036b7 <.L25>:
			putch(ch, putdat);
f01036b7:	83 ec 08             	sub    $0x8,%esp
f01036ba:	56                   	push   %esi
f01036bb:	6a 25                	push   $0x25
f01036bd:	ff 55 08             	call   *0x8(%ebp)
			break;
f01036c0:	83 c4 10             	add    $0x10,%esp
f01036c3:	e9 75 ff ff ff       	jmp    f010363d <.L35+0x45>

f01036c8 <.L22>:
			putch('%', putdat);
f01036c8:	83 ec 08             	sub    $0x8,%esp
f01036cb:	56                   	push   %esi
f01036cc:	6a 25                	push   $0x25
f01036ce:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01036d1:	83 c4 10             	add    $0x10,%esp
f01036d4:	89 f8                	mov    %edi,%eax
f01036d6:	eb 03                	jmp    f01036db <.L22+0x13>
f01036d8:	83 e8 01             	sub    $0x1,%eax
f01036db:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01036df:	75 f7                	jne    f01036d8 <.L22+0x10>
f01036e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01036e4:	e9 54 ff ff ff       	jmp    f010363d <.L35+0x45>
}
f01036e9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01036ec:	5b                   	pop    %ebx
f01036ed:	5e                   	pop    %esi
f01036ee:	5f                   	pop    %edi
f01036ef:	5d                   	pop    %ebp
f01036f0:	c3                   	ret    

f01036f1 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01036f1:	55                   	push   %ebp
f01036f2:	89 e5                	mov    %esp,%ebp
f01036f4:	53                   	push   %ebx
f01036f5:	83 ec 14             	sub    $0x14,%esp
f01036f8:	e8 52 ca ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01036fd:	81 c3 0f 3c 01 00    	add    $0x13c0f,%ebx
f0103703:	8b 45 08             	mov    0x8(%ebp),%eax
f0103706:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103709:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010370c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103710:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103713:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010371a:	85 c0                	test   %eax,%eax
f010371c:	74 2b                	je     f0103749 <vsnprintf+0x58>
f010371e:	85 d2                	test   %edx,%edx
f0103720:	7e 27                	jle    f0103749 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103722:	ff 75 14             	pushl  0x14(%ebp)
f0103725:	ff 75 10             	pushl  0x10(%ebp)
f0103728:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010372b:	50                   	push   %eax
f010372c:	8d 83 4d bf fe ff    	lea    -0x140b3(%ebx),%eax
f0103732:	50                   	push   %eax
f0103733:	e8 5b fb ff ff       	call   f0103293 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103738:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010373b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010373e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103741:	83 c4 10             	add    $0x10,%esp
}
f0103744:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103747:	c9                   	leave  
f0103748:	c3                   	ret    
		return -E_INVAL;
f0103749:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010374e:	eb f4                	jmp    f0103744 <vsnprintf+0x53>

f0103750 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103750:	55                   	push   %ebp
f0103751:	89 e5                	mov    %esp,%ebp
f0103753:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103756:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103759:	50                   	push   %eax
f010375a:	ff 75 10             	pushl  0x10(%ebp)
f010375d:	ff 75 0c             	pushl  0xc(%ebp)
f0103760:	ff 75 08             	pushl  0x8(%ebp)
f0103763:	e8 89 ff ff ff       	call   f01036f1 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103768:	c9                   	leave  
f0103769:	c3                   	ret    

f010376a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010376a:	55                   	push   %ebp
f010376b:	89 e5                	mov    %esp,%ebp
f010376d:	57                   	push   %edi
f010376e:	56                   	push   %esi
f010376f:	53                   	push   %ebx
f0103770:	83 ec 1c             	sub    $0x1c,%esp
f0103773:	e8 d7 c9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103778:	81 c3 94 3b 01 00    	add    $0x13b94,%ebx
f010377e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103781:	85 c0                	test   %eax,%eax
f0103783:	74 13                	je     f0103798 <readline+0x2e>
		cprintf("%s", prompt);
f0103785:	83 ec 08             	sub    $0x8,%esp
f0103788:	50                   	push   %eax
f0103789:	8d 83 28 d7 fe ff    	lea    -0x128d8(%ebx),%eax
f010378f:	50                   	push   %eax
f0103790:	e8 ee f6 ff ff       	call   f0102e83 <cprintf>
f0103795:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103798:	83 ec 0c             	sub    $0xc,%esp
f010379b:	6a 00                	push   $0x0
f010379d:	e8 45 cf ff ff       	call   f01006e7 <iscons>
f01037a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01037a5:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01037a8:	bf 00 00 00 00       	mov    $0x0,%edi
f01037ad:	eb 46                	jmp    f01037f5 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01037af:	83 ec 08             	sub    $0x8,%esp
f01037b2:	50                   	push   %eax
f01037b3:	8d 83 00 dc fe ff    	lea    -0x12400(%ebx),%eax
f01037b9:	50                   	push   %eax
f01037ba:	e8 c4 f6 ff ff       	call   f0102e83 <cprintf>
			return NULL;
f01037bf:	83 c4 10             	add    $0x10,%esp
f01037c2:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01037c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01037ca:	5b                   	pop    %ebx
f01037cb:	5e                   	pop    %esi
f01037cc:	5f                   	pop    %edi
f01037cd:	5d                   	pop    %ebp
f01037ce:	c3                   	ret    
			if (echoing)
f01037cf:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01037d3:	75 05                	jne    f01037da <readline+0x70>
			i--;
f01037d5:	83 ef 01             	sub    $0x1,%edi
f01037d8:	eb 1b                	jmp    f01037f5 <readline+0x8b>
				cputchar('\b');
f01037da:	83 ec 0c             	sub    $0xc,%esp
f01037dd:	6a 08                	push   $0x8
f01037df:	e8 e2 ce ff ff       	call   f01006c6 <cputchar>
f01037e4:	83 c4 10             	add    $0x10,%esp
f01037e7:	eb ec                	jmp    f01037d5 <readline+0x6b>
			buf[i++] = c;
f01037e9:	89 f0                	mov    %esi,%eax
f01037eb:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f01037f2:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01037f5:	e8 dc ce ff ff       	call   f01006d6 <getchar>
f01037fa:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01037fc:	85 c0                	test   %eax,%eax
f01037fe:	78 af                	js     f01037af <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103800:	83 f8 08             	cmp    $0x8,%eax
f0103803:	0f 94 c2             	sete   %dl
f0103806:	83 f8 7f             	cmp    $0x7f,%eax
f0103809:	0f 94 c0             	sete   %al
f010380c:	08 c2                	or     %al,%dl
f010380e:	74 04                	je     f0103814 <readline+0xaa>
f0103810:	85 ff                	test   %edi,%edi
f0103812:	7f bb                	jg     f01037cf <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103814:	83 fe 1f             	cmp    $0x1f,%esi
f0103817:	7e 1c                	jle    f0103835 <readline+0xcb>
f0103819:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010381f:	7f 14                	jg     f0103835 <readline+0xcb>
			if (echoing)
f0103821:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103825:	74 c2                	je     f01037e9 <readline+0x7f>
				cputchar(c);
f0103827:	83 ec 0c             	sub    $0xc,%esp
f010382a:	56                   	push   %esi
f010382b:	e8 96 ce ff ff       	call   f01006c6 <cputchar>
f0103830:	83 c4 10             	add    $0x10,%esp
f0103833:	eb b4                	jmp    f01037e9 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103835:	83 fe 0a             	cmp    $0xa,%esi
f0103838:	74 05                	je     f010383f <readline+0xd5>
f010383a:	83 fe 0d             	cmp    $0xd,%esi
f010383d:	75 b6                	jne    f01037f5 <readline+0x8b>
			if (echoing)
f010383f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103843:	75 13                	jne    f0103858 <readline+0xee>
			buf[i] = 0;
f0103845:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f010384c:	00 
			return buf;
f010384d:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103853:	e9 6f ff ff ff       	jmp    f01037c7 <readline+0x5d>
				cputchar('\n');
f0103858:	83 ec 0c             	sub    $0xc,%esp
f010385b:	6a 0a                	push   $0xa
f010385d:	e8 64 ce ff ff       	call   f01006c6 <cputchar>
f0103862:	83 c4 10             	add    $0x10,%esp
f0103865:	eb de                	jmp    f0103845 <readline+0xdb>

f0103867 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010386d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103872:	eb 03                	jmp    f0103877 <strlen+0x10>
		n++;
f0103874:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103877:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010387b:	75 f7                	jne    f0103874 <strlen+0xd>
	return n;
}
f010387d:	5d                   	pop    %ebp
f010387e:	c3                   	ret    

f010387f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010387f:	55                   	push   %ebp
f0103880:	89 e5                	mov    %esp,%ebp
f0103882:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103885:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103888:	b8 00 00 00 00       	mov    $0x0,%eax
f010388d:	eb 03                	jmp    f0103892 <strnlen+0x13>
		n++;
f010388f:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103892:	39 d0                	cmp    %edx,%eax
f0103894:	74 06                	je     f010389c <strnlen+0x1d>
f0103896:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010389a:	75 f3                	jne    f010388f <strnlen+0x10>
	return n;
}
f010389c:	5d                   	pop    %ebp
f010389d:	c3                   	ret    

f010389e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010389e:	55                   	push   %ebp
f010389f:	89 e5                	mov    %esp,%ebp
f01038a1:	53                   	push   %ebx
f01038a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01038a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01038a8:	89 c2                	mov    %eax,%edx
f01038aa:	83 c1 01             	add    $0x1,%ecx
f01038ad:	83 c2 01             	add    $0x1,%edx
f01038b0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01038b4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01038b7:	84 db                	test   %bl,%bl
f01038b9:	75 ef                	jne    f01038aa <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01038bb:	5b                   	pop    %ebx
f01038bc:	5d                   	pop    %ebp
f01038bd:	c3                   	ret    

f01038be <strcat>:

char *
strcat(char *dst, const char *src)
{
f01038be:	55                   	push   %ebp
f01038bf:	89 e5                	mov    %esp,%ebp
f01038c1:	53                   	push   %ebx
f01038c2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01038c5:	53                   	push   %ebx
f01038c6:	e8 9c ff ff ff       	call   f0103867 <strlen>
f01038cb:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01038ce:	ff 75 0c             	pushl  0xc(%ebp)
f01038d1:	01 d8                	add    %ebx,%eax
f01038d3:	50                   	push   %eax
f01038d4:	e8 c5 ff ff ff       	call   f010389e <strcpy>
	return dst;
}
f01038d9:	89 d8                	mov    %ebx,%eax
f01038db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038de:	c9                   	leave  
f01038df:	c3                   	ret    

f01038e0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01038e0:	55                   	push   %ebp
f01038e1:	89 e5                	mov    %esp,%ebp
f01038e3:	56                   	push   %esi
f01038e4:	53                   	push   %ebx
f01038e5:	8b 75 08             	mov    0x8(%ebp),%esi
f01038e8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01038eb:	89 f3                	mov    %esi,%ebx
f01038ed:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01038f0:	89 f2                	mov    %esi,%edx
f01038f2:	eb 0f                	jmp    f0103903 <strncpy+0x23>
		*dst++ = *src;
f01038f4:	83 c2 01             	add    $0x1,%edx
f01038f7:	0f b6 01             	movzbl (%ecx),%eax
f01038fa:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01038fd:	80 39 01             	cmpb   $0x1,(%ecx)
f0103900:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103903:	39 da                	cmp    %ebx,%edx
f0103905:	75 ed                	jne    f01038f4 <strncpy+0x14>
	}
	return ret;
}
f0103907:	89 f0                	mov    %esi,%eax
f0103909:	5b                   	pop    %ebx
f010390a:	5e                   	pop    %esi
f010390b:	5d                   	pop    %ebp
f010390c:	c3                   	ret    

f010390d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010390d:	55                   	push   %ebp
f010390e:	89 e5                	mov    %esp,%ebp
f0103910:	56                   	push   %esi
f0103911:	53                   	push   %ebx
f0103912:	8b 75 08             	mov    0x8(%ebp),%esi
f0103915:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103918:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010391b:	89 f0                	mov    %esi,%eax
f010391d:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103921:	85 c9                	test   %ecx,%ecx
f0103923:	75 0b                	jne    f0103930 <strlcpy+0x23>
f0103925:	eb 17                	jmp    f010393e <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103927:	83 c2 01             	add    $0x1,%edx
f010392a:	83 c0 01             	add    $0x1,%eax
f010392d:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103930:	39 d8                	cmp    %ebx,%eax
f0103932:	74 07                	je     f010393b <strlcpy+0x2e>
f0103934:	0f b6 0a             	movzbl (%edx),%ecx
f0103937:	84 c9                	test   %cl,%cl
f0103939:	75 ec                	jne    f0103927 <strlcpy+0x1a>
		*dst = '\0';
f010393b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010393e:	29 f0                	sub    %esi,%eax
}
f0103940:	5b                   	pop    %ebx
f0103941:	5e                   	pop    %esi
f0103942:	5d                   	pop    %ebp
f0103943:	c3                   	ret    

f0103944 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103944:	55                   	push   %ebp
f0103945:	89 e5                	mov    %esp,%ebp
f0103947:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010394a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010394d:	eb 06                	jmp    f0103955 <strcmp+0x11>
		p++, q++;
f010394f:	83 c1 01             	add    $0x1,%ecx
f0103952:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103955:	0f b6 01             	movzbl (%ecx),%eax
f0103958:	84 c0                	test   %al,%al
f010395a:	74 04                	je     f0103960 <strcmp+0x1c>
f010395c:	3a 02                	cmp    (%edx),%al
f010395e:	74 ef                	je     f010394f <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103960:	0f b6 c0             	movzbl %al,%eax
f0103963:	0f b6 12             	movzbl (%edx),%edx
f0103966:	29 d0                	sub    %edx,%eax
}
f0103968:	5d                   	pop    %ebp
f0103969:	c3                   	ret    

f010396a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010396a:	55                   	push   %ebp
f010396b:	89 e5                	mov    %esp,%ebp
f010396d:	53                   	push   %ebx
f010396e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103971:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103974:	89 c3                	mov    %eax,%ebx
f0103976:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103979:	eb 06                	jmp    f0103981 <strncmp+0x17>
		n--, p++, q++;
f010397b:	83 c0 01             	add    $0x1,%eax
f010397e:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103981:	39 d8                	cmp    %ebx,%eax
f0103983:	74 16                	je     f010399b <strncmp+0x31>
f0103985:	0f b6 08             	movzbl (%eax),%ecx
f0103988:	84 c9                	test   %cl,%cl
f010398a:	74 04                	je     f0103990 <strncmp+0x26>
f010398c:	3a 0a                	cmp    (%edx),%cl
f010398e:	74 eb                	je     f010397b <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103990:	0f b6 00             	movzbl (%eax),%eax
f0103993:	0f b6 12             	movzbl (%edx),%edx
f0103996:	29 d0                	sub    %edx,%eax
}
f0103998:	5b                   	pop    %ebx
f0103999:	5d                   	pop    %ebp
f010399a:	c3                   	ret    
		return 0;
f010399b:	b8 00 00 00 00       	mov    $0x0,%eax
f01039a0:	eb f6                	jmp    f0103998 <strncmp+0x2e>

f01039a2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01039a2:	55                   	push   %ebp
f01039a3:	89 e5                	mov    %esp,%ebp
f01039a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01039a8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039ac:	0f b6 10             	movzbl (%eax),%edx
f01039af:	84 d2                	test   %dl,%dl
f01039b1:	74 09                	je     f01039bc <strchr+0x1a>
		if (*s == c)
f01039b3:	38 ca                	cmp    %cl,%dl
f01039b5:	74 0a                	je     f01039c1 <strchr+0x1f>
	for (; *s; s++)
f01039b7:	83 c0 01             	add    $0x1,%eax
f01039ba:	eb f0                	jmp    f01039ac <strchr+0xa>
			return (char *) s;
	return 0;
f01039bc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039c1:	5d                   	pop    %ebp
f01039c2:	c3                   	ret    

f01039c3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01039c3:	55                   	push   %ebp
f01039c4:	89 e5                	mov    %esp,%ebp
f01039c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01039c9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01039cd:	eb 03                	jmp    f01039d2 <strfind+0xf>
f01039cf:	83 c0 01             	add    $0x1,%eax
f01039d2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01039d5:	38 ca                	cmp    %cl,%dl
f01039d7:	74 04                	je     f01039dd <strfind+0x1a>
f01039d9:	84 d2                	test   %dl,%dl
f01039db:	75 f2                	jne    f01039cf <strfind+0xc>
			break;
	return (char *) s;
}
f01039dd:	5d                   	pop    %ebp
f01039de:	c3                   	ret    

f01039df <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01039df:	55                   	push   %ebp
f01039e0:	89 e5                	mov    %esp,%ebp
f01039e2:	57                   	push   %edi
f01039e3:	56                   	push   %esi
f01039e4:	53                   	push   %ebx
f01039e5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01039e8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01039eb:	85 c9                	test   %ecx,%ecx
f01039ed:	74 13                	je     f0103a02 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01039ef:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039f5:	75 05                	jne    f01039fc <memset+0x1d>
f01039f7:	f6 c1 03             	test   $0x3,%cl
f01039fa:	74 0d                	je     f0103a09 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01039fc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039ff:	fc                   	cld    
f0103a00:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103a02:	89 f8                	mov    %edi,%eax
f0103a04:	5b                   	pop    %ebx
f0103a05:	5e                   	pop    %esi
f0103a06:	5f                   	pop    %edi
f0103a07:	5d                   	pop    %ebp
f0103a08:	c3                   	ret    
		c &= 0xFF;
f0103a09:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103a0d:	89 d3                	mov    %edx,%ebx
f0103a0f:	c1 e3 08             	shl    $0x8,%ebx
f0103a12:	89 d0                	mov    %edx,%eax
f0103a14:	c1 e0 18             	shl    $0x18,%eax
f0103a17:	89 d6                	mov    %edx,%esi
f0103a19:	c1 e6 10             	shl    $0x10,%esi
f0103a1c:	09 f0                	or     %esi,%eax
f0103a1e:	09 c2                	or     %eax,%edx
f0103a20:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103a22:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103a25:	89 d0                	mov    %edx,%eax
f0103a27:	fc                   	cld    
f0103a28:	f3 ab                	rep stos %eax,%es:(%edi)
f0103a2a:	eb d6                	jmp    f0103a02 <memset+0x23>

f0103a2c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103a2c:	55                   	push   %ebp
f0103a2d:	89 e5                	mov    %esp,%ebp
f0103a2f:	57                   	push   %edi
f0103a30:	56                   	push   %esi
f0103a31:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a34:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a37:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103a3a:	39 c6                	cmp    %eax,%esi
f0103a3c:	73 35                	jae    f0103a73 <memmove+0x47>
f0103a3e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103a41:	39 c2                	cmp    %eax,%edx
f0103a43:	76 2e                	jbe    f0103a73 <memmove+0x47>
		s += n;
		d += n;
f0103a45:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a48:	89 d6                	mov    %edx,%esi
f0103a4a:	09 fe                	or     %edi,%esi
f0103a4c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103a52:	74 0c                	je     f0103a60 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103a54:	83 ef 01             	sub    $0x1,%edi
f0103a57:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103a5a:	fd                   	std    
f0103a5b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103a5d:	fc                   	cld    
f0103a5e:	eb 21                	jmp    f0103a81 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a60:	f6 c1 03             	test   $0x3,%cl
f0103a63:	75 ef                	jne    f0103a54 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103a65:	83 ef 04             	sub    $0x4,%edi
f0103a68:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103a6b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103a6e:	fd                   	std    
f0103a6f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a71:	eb ea                	jmp    f0103a5d <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a73:	89 f2                	mov    %esi,%edx
f0103a75:	09 c2                	or     %eax,%edx
f0103a77:	f6 c2 03             	test   $0x3,%dl
f0103a7a:	74 09                	je     f0103a85 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103a7c:	89 c7                	mov    %eax,%edi
f0103a7e:	fc                   	cld    
f0103a7f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a81:	5e                   	pop    %esi
f0103a82:	5f                   	pop    %edi
f0103a83:	5d                   	pop    %ebp
f0103a84:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a85:	f6 c1 03             	test   $0x3,%cl
f0103a88:	75 f2                	jne    f0103a7c <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103a8a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103a8d:	89 c7                	mov    %eax,%edi
f0103a8f:	fc                   	cld    
f0103a90:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a92:	eb ed                	jmp    f0103a81 <memmove+0x55>

f0103a94 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103a94:	55                   	push   %ebp
f0103a95:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103a97:	ff 75 10             	pushl  0x10(%ebp)
f0103a9a:	ff 75 0c             	pushl  0xc(%ebp)
f0103a9d:	ff 75 08             	pushl  0x8(%ebp)
f0103aa0:	e8 87 ff ff ff       	call   f0103a2c <memmove>
}
f0103aa5:	c9                   	leave  
f0103aa6:	c3                   	ret    

f0103aa7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103aa7:	55                   	push   %ebp
f0103aa8:	89 e5                	mov    %esp,%ebp
f0103aaa:	56                   	push   %esi
f0103aab:	53                   	push   %ebx
f0103aac:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aaf:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ab2:	89 c6                	mov    %eax,%esi
f0103ab4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103ab7:	39 f0                	cmp    %esi,%eax
f0103ab9:	74 1c                	je     f0103ad7 <memcmp+0x30>
		if (*s1 != *s2)
f0103abb:	0f b6 08             	movzbl (%eax),%ecx
f0103abe:	0f b6 1a             	movzbl (%edx),%ebx
f0103ac1:	38 d9                	cmp    %bl,%cl
f0103ac3:	75 08                	jne    f0103acd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103ac5:	83 c0 01             	add    $0x1,%eax
f0103ac8:	83 c2 01             	add    $0x1,%edx
f0103acb:	eb ea                	jmp    f0103ab7 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103acd:	0f b6 c1             	movzbl %cl,%eax
f0103ad0:	0f b6 db             	movzbl %bl,%ebx
f0103ad3:	29 d8                	sub    %ebx,%eax
f0103ad5:	eb 05                	jmp    f0103adc <memcmp+0x35>
	}

	return 0;
f0103ad7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103adc:	5b                   	pop    %ebx
f0103add:	5e                   	pop    %esi
f0103ade:	5d                   	pop    %ebp
f0103adf:	c3                   	ret    

f0103ae0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103ae0:	55                   	push   %ebp
f0103ae1:	89 e5                	mov    %esp,%ebp
f0103ae3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ae6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103ae9:	89 c2                	mov    %eax,%edx
f0103aeb:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103aee:	39 d0                	cmp    %edx,%eax
f0103af0:	73 09                	jae    f0103afb <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103af2:	38 08                	cmp    %cl,(%eax)
f0103af4:	74 05                	je     f0103afb <memfind+0x1b>
	for (; s < ends; s++)
f0103af6:	83 c0 01             	add    $0x1,%eax
f0103af9:	eb f3                	jmp    f0103aee <memfind+0xe>
			break;
	return (void *) s;
}
f0103afb:	5d                   	pop    %ebp
f0103afc:	c3                   	ret    

f0103afd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103afd:	55                   	push   %ebp
f0103afe:	89 e5                	mov    %esp,%ebp
f0103b00:	57                   	push   %edi
f0103b01:	56                   	push   %esi
f0103b02:	53                   	push   %ebx
f0103b03:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b06:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103b09:	eb 03                	jmp    f0103b0e <strtol+0x11>
		s++;
f0103b0b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103b0e:	0f b6 01             	movzbl (%ecx),%eax
f0103b11:	3c 20                	cmp    $0x20,%al
f0103b13:	74 f6                	je     f0103b0b <strtol+0xe>
f0103b15:	3c 09                	cmp    $0x9,%al
f0103b17:	74 f2                	je     f0103b0b <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103b19:	3c 2b                	cmp    $0x2b,%al
f0103b1b:	74 2e                	je     f0103b4b <strtol+0x4e>
	int neg = 0;
f0103b1d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103b22:	3c 2d                	cmp    $0x2d,%al
f0103b24:	74 2f                	je     f0103b55 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b26:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103b2c:	75 05                	jne    f0103b33 <strtol+0x36>
f0103b2e:	80 39 30             	cmpb   $0x30,(%ecx)
f0103b31:	74 2c                	je     f0103b5f <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b33:	85 db                	test   %ebx,%ebx
f0103b35:	75 0a                	jne    f0103b41 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b37:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103b3c:	80 39 30             	cmpb   $0x30,(%ecx)
f0103b3f:	74 28                	je     f0103b69 <strtol+0x6c>
		base = 10;
f0103b41:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b46:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103b49:	eb 50                	jmp    f0103b9b <strtol+0x9e>
		s++;
f0103b4b:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103b4e:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b53:	eb d1                	jmp    f0103b26 <strtol+0x29>
		s++, neg = 1;
f0103b55:	83 c1 01             	add    $0x1,%ecx
f0103b58:	bf 01 00 00 00       	mov    $0x1,%edi
f0103b5d:	eb c7                	jmp    f0103b26 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b5f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103b63:	74 0e                	je     f0103b73 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103b65:	85 db                	test   %ebx,%ebx
f0103b67:	75 d8                	jne    f0103b41 <strtol+0x44>
		s++, base = 8;
f0103b69:	83 c1 01             	add    $0x1,%ecx
f0103b6c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103b71:	eb ce                	jmp    f0103b41 <strtol+0x44>
		s += 2, base = 16;
f0103b73:	83 c1 02             	add    $0x2,%ecx
f0103b76:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b7b:	eb c4                	jmp    f0103b41 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103b7d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103b80:	89 f3                	mov    %esi,%ebx
f0103b82:	80 fb 19             	cmp    $0x19,%bl
f0103b85:	77 29                	ja     f0103bb0 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103b87:	0f be d2             	movsbl %dl,%edx
f0103b8a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b8d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103b90:	7d 30                	jge    f0103bc2 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103b92:	83 c1 01             	add    $0x1,%ecx
f0103b95:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103b99:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103b9b:	0f b6 11             	movzbl (%ecx),%edx
f0103b9e:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103ba1:	89 f3                	mov    %esi,%ebx
f0103ba3:	80 fb 09             	cmp    $0x9,%bl
f0103ba6:	77 d5                	ja     f0103b7d <strtol+0x80>
			dig = *s - '0';
f0103ba8:	0f be d2             	movsbl %dl,%edx
f0103bab:	83 ea 30             	sub    $0x30,%edx
f0103bae:	eb dd                	jmp    f0103b8d <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103bb0:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103bb3:	89 f3                	mov    %esi,%ebx
f0103bb5:	80 fb 19             	cmp    $0x19,%bl
f0103bb8:	77 08                	ja     f0103bc2 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103bba:	0f be d2             	movsbl %dl,%edx
f0103bbd:	83 ea 37             	sub    $0x37,%edx
f0103bc0:	eb cb                	jmp    f0103b8d <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103bc2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103bc6:	74 05                	je     f0103bcd <strtol+0xd0>
		*endptr = (char *) s;
f0103bc8:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103bcb:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103bcd:	89 c2                	mov    %eax,%edx
f0103bcf:	f7 da                	neg    %edx
f0103bd1:	85 ff                	test   %edi,%edi
f0103bd3:	0f 45 c2             	cmovne %edx,%eax
}
f0103bd6:	5b                   	pop    %ebx
f0103bd7:	5e                   	pop    %esi
f0103bd8:	5f                   	pop    %edi
f0103bd9:	5d                   	pop    %ebp
f0103bda:	c3                   	ret    
f0103bdb:	66 90                	xchg   %ax,%ax
f0103bdd:	66 90                	xchg   %ax,%ax
f0103bdf:	90                   	nop

f0103be0 <__udivdi3>:
f0103be0:	55                   	push   %ebp
f0103be1:	57                   	push   %edi
f0103be2:	56                   	push   %esi
f0103be3:	53                   	push   %ebx
f0103be4:	83 ec 1c             	sub    $0x1c,%esp
f0103be7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103beb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103bef:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103bf3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103bf7:	85 d2                	test   %edx,%edx
f0103bf9:	75 35                	jne    f0103c30 <__udivdi3+0x50>
f0103bfb:	39 f3                	cmp    %esi,%ebx
f0103bfd:	0f 87 bd 00 00 00    	ja     f0103cc0 <__udivdi3+0xe0>
f0103c03:	85 db                	test   %ebx,%ebx
f0103c05:	89 d9                	mov    %ebx,%ecx
f0103c07:	75 0b                	jne    f0103c14 <__udivdi3+0x34>
f0103c09:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c0e:	31 d2                	xor    %edx,%edx
f0103c10:	f7 f3                	div    %ebx
f0103c12:	89 c1                	mov    %eax,%ecx
f0103c14:	31 d2                	xor    %edx,%edx
f0103c16:	89 f0                	mov    %esi,%eax
f0103c18:	f7 f1                	div    %ecx
f0103c1a:	89 c6                	mov    %eax,%esi
f0103c1c:	89 e8                	mov    %ebp,%eax
f0103c1e:	89 f7                	mov    %esi,%edi
f0103c20:	f7 f1                	div    %ecx
f0103c22:	89 fa                	mov    %edi,%edx
f0103c24:	83 c4 1c             	add    $0x1c,%esp
f0103c27:	5b                   	pop    %ebx
f0103c28:	5e                   	pop    %esi
f0103c29:	5f                   	pop    %edi
f0103c2a:	5d                   	pop    %ebp
f0103c2b:	c3                   	ret    
f0103c2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c30:	39 f2                	cmp    %esi,%edx
f0103c32:	77 7c                	ja     f0103cb0 <__udivdi3+0xd0>
f0103c34:	0f bd fa             	bsr    %edx,%edi
f0103c37:	83 f7 1f             	xor    $0x1f,%edi
f0103c3a:	0f 84 98 00 00 00    	je     f0103cd8 <__udivdi3+0xf8>
f0103c40:	89 f9                	mov    %edi,%ecx
f0103c42:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c47:	29 f8                	sub    %edi,%eax
f0103c49:	d3 e2                	shl    %cl,%edx
f0103c4b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c4f:	89 c1                	mov    %eax,%ecx
f0103c51:	89 da                	mov    %ebx,%edx
f0103c53:	d3 ea                	shr    %cl,%edx
f0103c55:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103c59:	09 d1                	or     %edx,%ecx
f0103c5b:	89 f2                	mov    %esi,%edx
f0103c5d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c61:	89 f9                	mov    %edi,%ecx
f0103c63:	d3 e3                	shl    %cl,%ebx
f0103c65:	89 c1                	mov    %eax,%ecx
f0103c67:	d3 ea                	shr    %cl,%edx
f0103c69:	89 f9                	mov    %edi,%ecx
f0103c6b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103c6f:	d3 e6                	shl    %cl,%esi
f0103c71:	89 eb                	mov    %ebp,%ebx
f0103c73:	89 c1                	mov    %eax,%ecx
f0103c75:	d3 eb                	shr    %cl,%ebx
f0103c77:	09 de                	or     %ebx,%esi
f0103c79:	89 f0                	mov    %esi,%eax
f0103c7b:	f7 74 24 08          	divl   0x8(%esp)
f0103c7f:	89 d6                	mov    %edx,%esi
f0103c81:	89 c3                	mov    %eax,%ebx
f0103c83:	f7 64 24 0c          	mull   0xc(%esp)
f0103c87:	39 d6                	cmp    %edx,%esi
f0103c89:	72 0c                	jb     f0103c97 <__udivdi3+0xb7>
f0103c8b:	89 f9                	mov    %edi,%ecx
f0103c8d:	d3 e5                	shl    %cl,%ebp
f0103c8f:	39 c5                	cmp    %eax,%ebp
f0103c91:	73 5d                	jae    f0103cf0 <__udivdi3+0x110>
f0103c93:	39 d6                	cmp    %edx,%esi
f0103c95:	75 59                	jne    f0103cf0 <__udivdi3+0x110>
f0103c97:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103c9a:	31 ff                	xor    %edi,%edi
f0103c9c:	89 fa                	mov    %edi,%edx
f0103c9e:	83 c4 1c             	add    $0x1c,%esp
f0103ca1:	5b                   	pop    %ebx
f0103ca2:	5e                   	pop    %esi
f0103ca3:	5f                   	pop    %edi
f0103ca4:	5d                   	pop    %ebp
f0103ca5:	c3                   	ret    
f0103ca6:	8d 76 00             	lea    0x0(%esi),%esi
f0103ca9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103cb0:	31 ff                	xor    %edi,%edi
f0103cb2:	31 c0                	xor    %eax,%eax
f0103cb4:	89 fa                	mov    %edi,%edx
f0103cb6:	83 c4 1c             	add    $0x1c,%esp
f0103cb9:	5b                   	pop    %ebx
f0103cba:	5e                   	pop    %esi
f0103cbb:	5f                   	pop    %edi
f0103cbc:	5d                   	pop    %ebp
f0103cbd:	c3                   	ret    
f0103cbe:	66 90                	xchg   %ax,%ax
f0103cc0:	31 ff                	xor    %edi,%edi
f0103cc2:	89 e8                	mov    %ebp,%eax
f0103cc4:	89 f2                	mov    %esi,%edx
f0103cc6:	f7 f3                	div    %ebx
f0103cc8:	89 fa                	mov    %edi,%edx
f0103cca:	83 c4 1c             	add    $0x1c,%esp
f0103ccd:	5b                   	pop    %ebx
f0103cce:	5e                   	pop    %esi
f0103ccf:	5f                   	pop    %edi
f0103cd0:	5d                   	pop    %ebp
f0103cd1:	c3                   	ret    
f0103cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cd8:	39 f2                	cmp    %esi,%edx
f0103cda:	72 06                	jb     f0103ce2 <__udivdi3+0x102>
f0103cdc:	31 c0                	xor    %eax,%eax
f0103cde:	39 eb                	cmp    %ebp,%ebx
f0103ce0:	77 d2                	ja     f0103cb4 <__udivdi3+0xd4>
f0103ce2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ce7:	eb cb                	jmp    f0103cb4 <__udivdi3+0xd4>
f0103ce9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103cf0:	89 d8                	mov    %ebx,%eax
f0103cf2:	31 ff                	xor    %edi,%edi
f0103cf4:	eb be                	jmp    f0103cb4 <__udivdi3+0xd4>
f0103cf6:	66 90                	xchg   %ax,%ax
f0103cf8:	66 90                	xchg   %ax,%ax
f0103cfa:	66 90                	xchg   %ax,%ax
f0103cfc:	66 90                	xchg   %ax,%ax
f0103cfe:	66 90                	xchg   %ax,%ax

f0103d00 <__umoddi3>:
f0103d00:	55                   	push   %ebp
f0103d01:	57                   	push   %edi
f0103d02:	56                   	push   %esi
f0103d03:	53                   	push   %ebx
f0103d04:	83 ec 1c             	sub    $0x1c,%esp
f0103d07:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103d0b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103d0f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103d13:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103d17:	85 ed                	test   %ebp,%ebp
f0103d19:	89 f0                	mov    %esi,%eax
f0103d1b:	89 da                	mov    %ebx,%edx
f0103d1d:	75 19                	jne    f0103d38 <__umoddi3+0x38>
f0103d1f:	39 df                	cmp    %ebx,%edi
f0103d21:	0f 86 b1 00 00 00    	jbe    f0103dd8 <__umoddi3+0xd8>
f0103d27:	f7 f7                	div    %edi
f0103d29:	89 d0                	mov    %edx,%eax
f0103d2b:	31 d2                	xor    %edx,%edx
f0103d2d:	83 c4 1c             	add    $0x1c,%esp
f0103d30:	5b                   	pop    %ebx
f0103d31:	5e                   	pop    %esi
f0103d32:	5f                   	pop    %edi
f0103d33:	5d                   	pop    %ebp
f0103d34:	c3                   	ret    
f0103d35:	8d 76 00             	lea    0x0(%esi),%esi
f0103d38:	39 dd                	cmp    %ebx,%ebp
f0103d3a:	77 f1                	ja     f0103d2d <__umoddi3+0x2d>
f0103d3c:	0f bd cd             	bsr    %ebp,%ecx
f0103d3f:	83 f1 1f             	xor    $0x1f,%ecx
f0103d42:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103d46:	0f 84 b4 00 00 00    	je     f0103e00 <__umoddi3+0x100>
f0103d4c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103d51:	89 c2                	mov    %eax,%edx
f0103d53:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d57:	29 c2                	sub    %eax,%edx
f0103d59:	89 c1                	mov    %eax,%ecx
f0103d5b:	89 f8                	mov    %edi,%eax
f0103d5d:	d3 e5                	shl    %cl,%ebp
f0103d5f:	89 d1                	mov    %edx,%ecx
f0103d61:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103d65:	d3 e8                	shr    %cl,%eax
f0103d67:	09 c5                	or     %eax,%ebp
f0103d69:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103d6d:	89 c1                	mov    %eax,%ecx
f0103d6f:	d3 e7                	shl    %cl,%edi
f0103d71:	89 d1                	mov    %edx,%ecx
f0103d73:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103d77:	89 df                	mov    %ebx,%edi
f0103d79:	d3 ef                	shr    %cl,%edi
f0103d7b:	89 c1                	mov    %eax,%ecx
f0103d7d:	89 f0                	mov    %esi,%eax
f0103d7f:	d3 e3                	shl    %cl,%ebx
f0103d81:	89 d1                	mov    %edx,%ecx
f0103d83:	89 fa                	mov    %edi,%edx
f0103d85:	d3 e8                	shr    %cl,%eax
f0103d87:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d8c:	09 d8                	or     %ebx,%eax
f0103d8e:	f7 f5                	div    %ebp
f0103d90:	d3 e6                	shl    %cl,%esi
f0103d92:	89 d1                	mov    %edx,%ecx
f0103d94:	f7 64 24 08          	mull   0x8(%esp)
f0103d98:	39 d1                	cmp    %edx,%ecx
f0103d9a:	89 c3                	mov    %eax,%ebx
f0103d9c:	89 d7                	mov    %edx,%edi
f0103d9e:	72 06                	jb     f0103da6 <__umoddi3+0xa6>
f0103da0:	75 0e                	jne    f0103db0 <__umoddi3+0xb0>
f0103da2:	39 c6                	cmp    %eax,%esi
f0103da4:	73 0a                	jae    f0103db0 <__umoddi3+0xb0>
f0103da6:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103daa:	19 ea                	sbb    %ebp,%edx
f0103dac:	89 d7                	mov    %edx,%edi
f0103dae:	89 c3                	mov    %eax,%ebx
f0103db0:	89 ca                	mov    %ecx,%edx
f0103db2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103db7:	29 de                	sub    %ebx,%esi
f0103db9:	19 fa                	sbb    %edi,%edx
f0103dbb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103dbf:	89 d0                	mov    %edx,%eax
f0103dc1:	d3 e0                	shl    %cl,%eax
f0103dc3:	89 d9                	mov    %ebx,%ecx
f0103dc5:	d3 ee                	shr    %cl,%esi
f0103dc7:	d3 ea                	shr    %cl,%edx
f0103dc9:	09 f0                	or     %esi,%eax
f0103dcb:	83 c4 1c             	add    $0x1c,%esp
f0103dce:	5b                   	pop    %ebx
f0103dcf:	5e                   	pop    %esi
f0103dd0:	5f                   	pop    %edi
f0103dd1:	5d                   	pop    %ebp
f0103dd2:	c3                   	ret    
f0103dd3:	90                   	nop
f0103dd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103dd8:	85 ff                	test   %edi,%edi
f0103dda:	89 f9                	mov    %edi,%ecx
f0103ddc:	75 0b                	jne    f0103de9 <__umoddi3+0xe9>
f0103dde:	b8 01 00 00 00       	mov    $0x1,%eax
f0103de3:	31 d2                	xor    %edx,%edx
f0103de5:	f7 f7                	div    %edi
f0103de7:	89 c1                	mov    %eax,%ecx
f0103de9:	89 d8                	mov    %ebx,%eax
f0103deb:	31 d2                	xor    %edx,%edx
f0103ded:	f7 f1                	div    %ecx
f0103def:	89 f0                	mov    %esi,%eax
f0103df1:	f7 f1                	div    %ecx
f0103df3:	e9 31 ff ff ff       	jmp    f0103d29 <__umoddi3+0x29>
f0103df8:	90                   	nop
f0103df9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e00:	39 dd                	cmp    %ebx,%ebp
f0103e02:	72 08                	jb     f0103e0c <__umoddi3+0x10c>
f0103e04:	39 f7                	cmp    %esi,%edi
f0103e06:	0f 87 21 ff ff ff    	ja     f0103d2d <__umoddi3+0x2d>
f0103e0c:	89 da                	mov    %ebx,%edx
f0103e0e:	89 f0                	mov    %esi,%eax
f0103e10:	29 f8                	sub    %edi,%eax
f0103e12:	19 ea                	sbb    %ebp,%edx
f0103e14:	e9 14 ff ff ff       	jmp    f0103d2d <__umoddi3+0x2d>
