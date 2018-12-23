
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
f0100064:	e8 2e 3b 00 00       	call   f0103b97 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 d4 cc fe ff    	lea    -0x1332c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 b9 2f 00 00       	call   f010303b <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 12 12 00 00       	call   f0101299 <mem_init>
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
f01000da:	8d 83 ef cc fe ff    	lea    -0x13311(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 55 2f 00 00       	call   f010303b <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 14 2f 00 00       	call   f0103004 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 85 db fe ff    	lea    -0x1247b(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 3d 2f 00 00       	call   f010303b <cprintf>
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
f010011f:	8d 83 07 cd fe ff    	lea    -0x132f9(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 10 2f 00 00       	call   f010303b <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 cd 2e 00 00       	call   f0103004 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 85 db fe ff    	lea    -0x1247b(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 f6 2e 00 00       	call   f010303b <cprintf>
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
f0100217:	0f b6 84 13 54 ce fe 	movzbl -0x131ac(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 54 cd fe 	movzbl -0x132ac(%ebx,%edx,1),%ecx
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
f010026a:	8d 83 21 cd fe ff    	lea    -0x132df(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 c5 2d 00 00       	call   f010303b <cprintf>
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
f01002b1:	0f b6 84 13 54 ce fe 	movzbl -0x131ac(%ebx,%edx,1),%eax
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
f01004d2:	e8 0d 37 00 00       	call   f0103be4 <memmove>
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
f01006b5:	8d 83 2d cd fe ff    	lea    -0x132d3(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 7a 29 00 00       	call   f010303b <cprintf>
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
f0100708:	8d 83 54 cf fe ff    	lea    -0x130ac(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 72 cf fe ff    	lea    -0x1308e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 77 cf fe ff    	lea    -0x13089(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 19 29 00 00       	call   f010303b <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 e0 cf fe ff    	lea    -0x13020(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 80 cf fe ff    	lea    -0x13080(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 02 29 00 00       	call   f010303b <cprintf>
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
f0100759:	8d 83 89 cf fe ff    	lea    -0x13077(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 d6 28 00 00       	call   f010303b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010076e:	8d 83 08 d0 fe ff    	lea    -0x12ff8(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 c1 28 00 00       	call   f010303b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 30 d0 fe ff    	lea    -0x12fd0(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 a4 28 00 00       	call   f010303b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 d9 3f 10 f0    	mov    $0xf0103fd9,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 54 d0 fe ff    	lea    -0x12fac(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 87 28 00 00       	call   f010303b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 78 d0 fe ff    	lea    -0x12f88(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 6a 28 00 00       	call   f010303b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 9c d0 fe ff    	lea    -0x12f64(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 4d 28 00 00       	call   f010303b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 c0 d0 fe ff    	lea    -0x12f40(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 32 28 00 00       	call   f010303b <cprintf>
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
f0100834:	8d 83 ec d0 fe ff    	lea    -0x12f14(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 fb 27 00 00       	call   f010303b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 10 d1 fe ff    	lea    -0x12ef0(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 ed 27 00 00       	call   f010303b <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb a6 cf fe ff    	lea    -0x1305a(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 f4 32 00 00       	call   f0103b5a <strchr>
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
f0100894:	8d 83 ab cf fe ff    	lea    -0x13055(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 9b 27 00 00       	call   f010303b <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 a2 cf fe ff    	lea    -0x1305e(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 6b 30 00 00       	call   f0103922 <readline>
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
f01008e2:	e8 73 32 00 00       	call   f0103b5a <strchr>
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
f010090b:	8d 83 72 cf fe ff    	lea    -0x1308e(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 e2 31 00 00       	call   f0103afc <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 80 cf fe ff    	lea    -0x13080(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 c9 31 00 00       	call   f0103afc <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 c8 cf fe ff    	lea    -0x13038(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 ef 26 00 00       	call   f010303b <cprintf>
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
f0100987:	e8 1c 26 00 00       	call   f0102fa8 <__x86.get_pc_thunk.dx>
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
f01009ea:	e8 c5 25 00 00       	call   f0102fb4 <mc146818_read>
f01009ef:	89 c6                	mov    %eax,%esi
f01009f1:	83 c7 01             	add    $0x1,%edi
f01009f4:	89 3c 24             	mov    %edi,(%esp)
f01009f7:	e8 b8 25 00 00       	call   f0102fb4 <mc146818_read>
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
f0100a0e:	e8 99 25 00 00       	call   f0102fac <__x86.get_pc_thunk.cx>
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
f0100a65:	8d 81 38 d1 fe ff    	lea    -0x12ec8(%ecx),%eax
f0100a6b:	50                   	push   %eax
f0100a6c:	68 d8 02 00 00       	push   $0x2d8
f0100a71:	8d 81 b0 d8 fe ff    	lea    -0x12750(%ecx),%eax
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
f0100a8f:	e8 1c 25 00 00       	call   f0102fb0 <__x86.get_pc_thunk.di>
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
f0100ac3:	8d 83 5c d1 fe ff    	lea    -0x12ea4(%ebx),%eax
f0100ac9:	50                   	push   %eax
f0100aca:	68 19 02 00 00       	push   $0x219
f0100acf:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100ad5:	50                   	push   %eax
f0100ad6:	e8 be f5 ff ff       	call   f0100099 <_panic>
f0100adb:	50                   	push   %eax
f0100adc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100adf:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0100ae5:	50                   	push   %eax
f0100ae6:	6a 52                	push   $0x52
f0100ae8:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
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
f0100b30:	e8 62 30 00 00       	call   f0103b97 <memset>
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
f0100b79:	8d 83 ca d8 fe ff    	lea    -0x12736(%ebx),%eax
f0100b7f:	50                   	push   %eax
f0100b80:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100b86:	50                   	push   %eax
f0100b87:	68 33 02 00 00       	push   $0x233
f0100b8c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100b92:	50                   	push   %eax
f0100b93:	e8 01 f5 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100b98:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100b9b:	8d 83 eb d8 fe ff    	lea    -0x12715(%ebx),%eax
f0100ba1:	50                   	push   %eax
f0100ba2:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100ba8:	50                   	push   %eax
f0100ba9:	68 34 02 00 00       	push   $0x234
f0100bae:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100bb4:	50                   	push   %eax
f0100bb5:	e8 df f4 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bba:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bbd:	8d 83 80 d1 fe ff    	lea    -0x12e80(%ebx),%eax
f0100bc3:	50                   	push   %eax
f0100bc4:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100bca:	50                   	push   %eax
f0100bcb:	68 35 02 00 00       	push   $0x235
f0100bd0:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100bd6:	50                   	push   %eax
f0100bd7:	e8 bd f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100bdc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bdf:	8d 83 ff d8 fe ff    	lea    -0x12701(%ebx),%eax
f0100be5:	50                   	push   %eax
f0100be6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100bec:	50                   	push   %eax
f0100bed:	68 38 02 00 00       	push   $0x238
f0100bf2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100bf8:	50                   	push   %eax
f0100bf9:	e8 9b f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bfe:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c01:	8d 83 10 d9 fe ff    	lea    -0x126f0(%ebx),%eax
f0100c07:	50                   	push   %eax
f0100c08:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100c0e:	50                   	push   %eax
f0100c0f:	68 39 02 00 00       	push   $0x239
f0100c14:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100c1a:	50                   	push   %eax
f0100c1b:	e8 79 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c20:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c23:	8d 83 b4 d1 fe ff    	lea    -0x12e4c(%ebx),%eax
f0100c29:	50                   	push   %eax
f0100c2a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100c30:	50                   	push   %eax
f0100c31:	68 3a 02 00 00       	push   $0x23a
f0100c36:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100c3c:	50                   	push   %eax
f0100c3d:	e8 57 f4 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c42:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c45:	8d 83 29 d9 fe ff    	lea    -0x126d7(%ebx),%eax
f0100c4b:	50                   	push   %eax
f0100c4c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100c52:	50                   	push   %eax
f0100c53:	68 3b 02 00 00       	push   $0x23b
f0100c58:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
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
f0100ce2:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0100ce8:	50                   	push   %eax
f0100ce9:	6a 52                	push   $0x52
f0100ceb:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f0100cf1:	50                   	push   %eax
f0100cf2:	e8 a2 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cfa:	8d 83 d8 d1 fe ff    	lea    -0x12e28(%ebx),%eax
f0100d00:	50                   	push   %eax
f0100d01:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100d07:	50                   	push   %eax
f0100d08:	68 3c 02 00 00       	push   $0x23c
f0100d0d:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
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
f0100d2a:	8d 83 20 d2 fe ff    	lea    -0x12de0(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	e8 05 23 00 00       	call   f010303b <cprintf>
}
f0100d36:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d39:	5b                   	pop    %ebx
f0100d3a:	5e                   	pop    %esi
f0100d3b:	5f                   	pop    %edi
f0100d3c:	5d                   	pop    %ebp
f0100d3d:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100d3e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d41:	8d 83 43 d9 fe ff    	lea    -0x126bd(%ebx),%eax
f0100d47:	50                   	push   %eax
f0100d48:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100d4e:	50                   	push   %eax
f0100d4f:	68 44 02 00 00       	push   $0x244
f0100d54:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0100d5a:	50                   	push   %eax
f0100d5b:	e8 39 f3 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100d60:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d63:	8d 83 55 d9 fe ff    	lea    -0x126ab(%ebx),%eax
f0100d69:	50                   	push   %eax
f0100d6a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100d70:	50                   	push   %eax
f0100d71:	68 45 02 00 00       	push   $0x245
f0100d76:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
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
f0100f93:	e8 ff 2b 00 00       	call   f0103b97 <memset>
f0100f98:	83 c4 10             	add    $0x10,%esp
f0100f9b:	eb bc                	jmp    f0100f59 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f9d:	50                   	push   %eax
f0100f9e:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0100fa4:	50                   	push   %eax
f0100fa5:	6a 52                	push   $0x52
f0100fa7:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
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
f0100fe7:	8d 83 66 d9 fe ff    	lea    -0x1269a(%ebx),%eax
f0100fed:	50                   	push   %eax
f0100fee:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0100ff4:	50                   	push   %eax
f0100ff5:	68 43 01 00 00       	push   $0x143
f0100ffa:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101000:	50                   	push   %eax
f0101001:	e8 93 f0 ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL);
f0101006:	8d 83 76 d9 fe ff    	lea    -0x1268a(%ebx),%eax
f010100c:	50                   	push   %eax
f010100d:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101013:	50                   	push   %eax
f0101014:	68 44 01 00 00       	push   $0x144
f0101019:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
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
f01010d3:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f01010d9:	50                   	push   %eax
f01010da:	68 7c 01 00 00       	push   $0x17c
f01010df:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01010e5:	50                   	push   %eax
f01010e6:	e8 ae ef ff ff       	call   f0100099 <_panic>
		else return NULL;      
f01010eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f0:	eb d8                	jmp    f01010ca <pgdir_walk+0x7c>
				return NULL;
f01010f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f7:	eb d1                	jmp    f01010ca <pgdir_walk+0x7c>

f01010f9 <boot_map_region>:
{
f01010f9:	55                   	push   %ebp
f01010fa:	89 e5                	mov    %esp,%ebp
f01010fc:	57                   	push   %edi
f01010fd:	56                   	push   %esi
f01010fe:	53                   	push   %ebx
f01010ff:	83 ec 1c             	sub    $0x1c,%esp
f0101102:	89 c7                	mov    %eax,%edi
f0101104:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101107:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
    for(int nadd = 0; nadd < size; nadd += PGSIZE)
f010110a:	bb 00 00 00 00       	mov    $0x0,%ebx
        *entry = (pa | perm | PTE_P);
f010110f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101112:	83 c8 01             	or     $0x1,%eax
f0101115:	89 45 dc             	mov    %eax,-0x24(%ebp)
    for(int nadd = 0; nadd < size; nadd += PGSIZE)
f0101118:	eb 1f                	jmp    f0101139 <boot_map_region+0x40>
		pte_t *entry = pgdir_walk(pgdir,(void *)va, 1);
f010111a:	83 ec 04             	sub    $0x4,%esp
f010111d:	6a 01                	push   $0x1
f010111f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101122:	01 d8                	add    %ebx,%eax
f0101124:	50                   	push   %eax
f0101125:	57                   	push   %edi
f0101126:	e8 23 ff ff ff       	call   f010104e <pgdir_walk>
        *entry = (pa | perm | PTE_P);
f010112b:	0b 75 dc             	or     -0x24(%ebp),%esi
f010112e:	89 30                	mov    %esi,(%eax)
    for(int nadd = 0; nadd < size; nadd += PGSIZE)
f0101130:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101136:	83 c4 10             	add    $0x10,%esp
f0101139:	89 de                	mov    %ebx,%esi
f010113b:	03 75 08             	add    0x8(%ebp),%esi
f010113e:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101141:	77 d7                	ja     f010111a <boot_map_region+0x21>
}
f0101143:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101146:	5b                   	pop    %ebx
f0101147:	5e                   	pop    %esi
f0101148:	5f                   	pop    %edi
f0101149:	5d                   	pop    %ebp
f010114a:	c3                   	ret    

f010114b <page_lookup>:
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	56                   	push   %esi
f010114f:	53                   	push   %ebx
f0101150:	e8 fa ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101155:	81 c3 b7 61 01 00    	add    $0x161b7,%ebx
f010115b:	8b 75 10             	mov    0x10(%ebp),%esi
    pte_t *entry = pgdir_walk(pgdir, va, 0);
f010115e:	83 ec 04             	sub    $0x4,%esp
f0101161:	6a 00                	push   $0x0
f0101163:	ff 75 0c             	pushl  0xc(%ebp)
f0101166:	ff 75 08             	pushl  0x8(%ebp)
f0101169:	e8 e0 fe ff ff       	call   f010104e <pgdir_walk>
    if(entry == NULL)
f010116e:	83 c4 10             	add    $0x10,%esp
f0101171:	85 c0                	test   %eax,%eax
f0101173:	74 46                	je     f01011bb <page_lookup+0x70>
f0101175:	89 c1                	mov    %eax,%ecx
    if(!(*entry & PTE_P))
f0101177:	8b 10                	mov    (%eax),%edx
f0101179:	f6 c2 01             	test   $0x1,%dl
f010117c:	74 44                	je     f01011c2 <page_lookup+0x77>
f010117e:	c1 ea 0c             	shr    $0xc,%edx
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101181:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101187:	39 10                	cmp    %edx,(%eax)
f0101189:	76 18                	jbe    f01011a3 <page_lookup+0x58>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f010118b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101191:	8b 00                	mov    (%eax),%eax
f0101193:	8d 04 d0             	lea    (%eax,%edx,8),%eax
    if(pte_store != NULL)
f0101196:	85 f6                	test   %esi,%esi
f0101198:	74 02                	je     f010119c <page_lookup+0x51>
        *pte_store = entry;
f010119a:	89 0e                	mov    %ecx,(%esi)
}
f010119c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010119f:	5b                   	pop    %ebx
f01011a0:	5e                   	pop    %esi
f01011a1:	5d                   	pop    %ebp
f01011a2:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01011a3:	83 ec 04             	sub    $0x4,%esp
f01011a6:	8d 83 44 d2 fe ff    	lea    -0x12dbc(%ebx),%eax
f01011ac:	50                   	push   %eax
f01011ad:	6a 4b                	push   $0x4b
f01011af:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f01011b5:	50                   	push   %eax
f01011b6:	e8 de ee ff ff       	call   f0100099 <_panic>
        return NULL;
f01011bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c0:	eb da                	jmp    f010119c <page_lookup+0x51>
        return NULL;
f01011c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c7:	eb d3                	jmp    f010119c <page_lookup+0x51>

f01011c9 <page_remove>:
{
f01011c9:	55                   	push   %ebp
f01011ca:	89 e5                	mov    %esp,%ebp
f01011cc:	53                   	push   %ebx
f01011cd:	83 ec 18             	sub    $0x18,%esp
f01011d0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    pte_t *pte = NULL;
f01011d3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    struct PageInfo *page = page_lookup(pgdir, va, &pte);
f01011da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011dd:	50                   	push   %eax
f01011de:	53                   	push   %ebx
f01011df:	ff 75 08             	pushl  0x8(%ebp)
f01011e2:	e8 64 ff ff ff       	call   f010114b <page_lookup>
    if(page == NULL)
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	75 05                	jne    f01011f3 <page_remove+0x2a>
}
f01011ee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011f1:	c9                   	leave  
f01011f2:	c3                   	ret    
    page_decref(page);
f01011f3:	83 ec 0c             	sub    $0xc,%esp
f01011f6:	50                   	push   %eax
f01011f7:	e8 29 fe ff ff       	call   f0101025 <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011fc:	0f 01 3b             	invlpg (%ebx)
    *pte = 0;
f01011ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101202:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101208:	83 c4 10             	add    $0x10,%esp
f010120b:	eb e1                	jmp    f01011ee <page_remove+0x25>

f010120d <page_insert>:
{
f010120d:	55                   	push   %ebp
f010120e:	89 e5                	mov    %esp,%ebp
f0101210:	57                   	push   %edi
f0101211:	56                   	push   %esi
f0101212:	53                   	push   %ebx
f0101213:	83 ec 10             	sub    $0x10,%esp
f0101216:	e8 95 1d 00 00       	call   f0102fb0 <__x86.get_pc_thunk.di>
f010121b:	81 c7 f1 60 01 00    	add    $0x160f1,%edi
f0101221:	8b 5d 08             	mov    0x8(%ebp),%ebx
    pte_t *entry = pgdir_walk(pgdir, va, 1);
f0101224:	6a 01                	push   $0x1
f0101226:	ff 75 10             	pushl  0x10(%ebp)
f0101229:	53                   	push   %ebx
f010122a:	e8 1f fe ff ff       	call   f010104e <pgdir_walk>
    if(entry == NULL)
f010122f:	83 c4 10             	add    $0x10,%esp
f0101232:	85 c0                	test   %eax,%eax
f0101234:	74 5c                	je     f0101292 <page_insert+0x85>
f0101236:	89 c6                	mov    %eax,%esi
    pp->pp_ref++;
f0101238:	8b 45 0c             	mov    0xc(%ebp),%eax
f010123b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
    if((*entry) & PTE_P)
f0101240:	f6 06 01             	testb  $0x1,(%esi)
f0101243:	75 36                	jne    f010127b <page_insert+0x6e>
	return (pp - pages) << PGSHIFT;
f0101245:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010124b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010124e:	2b 08                	sub    (%eax),%ecx
f0101250:	89 c8                	mov    %ecx,%eax
f0101252:	c1 f8 03             	sar    $0x3,%eax
f0101255:	c1 e0 0c             	shl    $0xc,%eax
    *entry = (page2pa(pp) | perm | PTE_P);
f0101258:	8b 55 14             	mov    0x14(%ebp),%edx
f010125b:	83 ca 01             	or     $0x1,%edx
f010125e:	09 d0                	or     %edx,%eax
f0101260:	89 06                	mov    %eax,(%esi)
    pgdir[PDX(va)] |= perm;
f0101262:	8b 45 10             	mov    0x10(%ebp),%eax
f0101265:	c1 e8 16             	shr    $0x16,%eax
f0101268:	8b 7d 14             	mov    0x14(%ebp),%edi
f010126b:	09 3c 83             	or     %edi,(%ebx,%eax,4)
    return 0;
f010126e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101273:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101276:	5b                   	pop    %ebx
f0101277:	5e                   	pop    %esi
f0101278:	5f                   	pop    %edi
f0101279:	5d                   	pop    %ebp
f010127a:	c3                   	ret    
f010127b:	8b 45 10             	mov    0x10(%ebp),%eax
f010127e:	0f 01 38             	invlpg (%eax)
        page_remove(pgdir, va);
f0101281:	83 ec 08             	sub    $0x8,%esp
f0101284:	ff 75 10             	pushl  0x10(%ebp)
f0101287:	53                   	push   %ebx
f0101288:	e8 3c ff ff ff       	call   f01011c9 <page_remove>
f010128d:	83 c4 10             	add    $0x10,%esp
f0101290:	eb b3                	jmp    f0101245 <page_insert+0x38>
		return -E_NO_MEM;
f0101292:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101297:	eb da                	jmp    f0101273 <page_insert+0x66>

f0101299 <mem_init>:
{
f0101299:	55                   	push   %ebp
f010129a:	89 e5                	mov    %esp,%ebp
f010129c:	57                   	push   %edi
f010129d:	56                   	push   %esi
f010129e:	53                   	push   %ebx
f010129f:	83 ec 3c             	sub    $0x3c,%esp
f01012a2:	e8 4a f4 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f01012a7:	05 65 60 01 00       	add    $0x16065,%eax
f01012ac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f01012af:	b8 15 00 00 00       	mov    $0x15,%eax
f01012b4:	e8 1a f7 ff ff       	call   f01009d3 <nvram_read>
f01012b9:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01012bb:	b8 17 00 00 00       	mov    $0x17,%eax
f01012c0:	e8 0e f7 ff ff       	call   f01009d3 <nvram_read>
f01012c5:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01012c7:	b8 34 00 00 00       	mov    $0x34,%eax
f01012cc:	e8 02 f7 ff ff       	call   f01009d3 <nvram_read>
f01012d1:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01012d4:	85 c0                	test   %eax,%eax
f01012d6:	0f 85 cd 00 00 00    	jne    f01013a9 <mem_init+0x110>
		totalmem = 1 * 1024 + extmem;
f01012dc:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01012e2:	85 f6                	test   %esi,%esi
f01012e4:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01012e7:	89 c1                	mov    %eax,%ecx
f01012e9:	c1 e9 02             	shr    $0x2,%ecx
f01012ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01012ef:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01012f5:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01012f7:	89 da                	mov    %ebx,%edx
f01012f9:	c1 ea 02             	shr    $0x2,%edx
f01012fc:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101302:	89 c2                	mov    %eax,%edx
f0101304:	29 da                	sub    %ebx,%edx
f0101306:	52                   	push   %edx
f0101307:	53                   	push   %ebx
f0101308:	50                   	push   %eax
f0101309:	8d 87 64 d2 fe ff    	lea    -0x12d9c(%edi),%eax
f010130f:	50                   	push   %eax
f0101310:	89 fb                	mov    %edi,%ebx
f0101312:	e8 24 1d 00 00       	call   f010303b <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101317:	b8 00 10 00 00       	mov    $0x1000,%eax
f010131c:	e8 62 f6 ff ff       	call   f0100983 <boot_alloc>
f0101321:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f0101327:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101329:	83 c4 0c             	add    $0xc,%esp
f010132c:	68 00 10 00 00       	push   $0x1000
f0101331:	6a 00                	push   $0x0
f0101333:	50                   	push   %eax
f0101334:	e8 5e 28 00 00       	call   f0103b97 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101339:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010133b:	83 c4 10             	add    $0x10,%esp
f010133e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101343:	76 6e                	jbe    f01013b3 <mem_init+0x11a>
	return (physaddr_t)kva - KERNBASE;
f0101345:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010134b:	83 ca 05             	or     $0x5,%edx
f010134e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0101354:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101357:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f010135d:	8b 03                	mov    (%ebx),%eax
f010135f:	c1 e0 03             	shl    $0x3,%eax
f0101362:	e8 1c f6 ff ff       	call   f0100983 <boot_alloc>
f0101367:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f010136d:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010136f:	83 ec 04             	sub    $0x4,%esp
f0101372:	8b 13                	mov    (%ebx),%edx
f0101374:	c1 e2 03             	shl    $0x3,%edx
f0101377:	52                   	push   %edx
f0101378:	6a 00                	push   $0x0
f010137a:	50                   	push   %eax
f010137b:	89 fb                	mov    %edi,%ebx
f010137d:	e8 15 28 00 00       	call   f0103b97 <memset>
	page_init();
f0101382:	e8 82 fa ff ff       	call   f0100e09 <page_init>
	check_page_free_list(1);
f0101387:	b8 01 00 00 00       	mov    $0x1,%eax
f010138c:	e8 f5 f6 ff ff       	call   f0100a86 <check_page_free_list>
	if (!pages)
f0101391:	83 c4 10             	add    $0x10,%esp
f0101394:	83 3e 00             	cmpl   $0x0,(%esi)
f0101397:	74 36                	je     f01013cf <mem_init+0x136>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101399:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010139c:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f01013a2:	be 00 00 00 00       	mov    $0x0,%esi
f01013a7:	eb 49                	jmp    f01013f2 <mem_init+0x159>
		totalmem = 16 * 1024 + ext16mem;
f01013a9:	05 00 40 00 00       	add    $0x4000,%eax
f01013ae:	e9 34 ff ff ff       	jmp    f01012e7 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013b3:	50                   	push   %eax
f01013b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01013b7:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f01013bd:	50                   	push   %eax
f01013be:	68 8f 00 00 00       	push   $0x8f
f01013c3:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01013c9:	50                   	push   %eax
f01013ca:	e8 ca ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f01013cf:	83 ec 04             	sub    $0x4,%esp
f01013d2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01013d5:	8d 83 8a d9 fe ff    	lea    -0x12676(%ebx),%eax
f01013db:	50                   	push   %eax
f01013dc:	68 58 02 00 00       	push   $0x258
f01013e1:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01013e7:	50                   	push   %eax
f01013e8:	e8 ac ec ff ff       	call   f0100099 <_panic>
		++nfree;
f01013ed:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01013f0:	8b 00                	mov    (%eax),%eax
f01013f2:	85 c0                	test   %eax,%eax
f01013f4:	75 f7                	jne    f01013ed <mem_init+0x154>
	assert((pp0 = page_alloc(0)));
f01013f6:	83 ec 0c             	sub    $0xc,%esp
f01013f9:	6a 00                	push   $0x0
f01013fb:	e8 2b fb ff ff       	call   f0100f2b <page_alloc>
f0101400:	89 c3                	mov    %eax,%ebx
f0101402:	83 c4 10             	add    $0x10,%esp
f0101405:	85 c0                	test   %eax,%eax
f0101407:	0f 84 3b 02 00 00    	je     f0101648 <mem_init+0x3af>
	assert((pp1 = page_alloc(0)));
f010140d:	83 ec 0c             	sub    $0xc,%esp
f0101410:	6a 00                	push   $0x0
f0101412:	e8 14 fb ff ff       	call   f0100f2b <page_alloc>
f0101417:	89 c7                	mov    %eax,%edi
f0101419:	83 c4 10             	add    $0x10,%esp
f010141c:	85 c0                	test   %eax,%eax
f010141e:	0f 84 46 02 00 00    	je     f010166a <mem_init+0x3d1>
	assert((pp2 = page_alloc(0)));
f0101424:	83 ec 0c             	sub    $0xc,%esp
f0101427:	6a 00                	push   $0x0
f0101429:	e8 fd fa ff ff       	call   f0100f2b <page_alloc>
f010142e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101431:	83 c4 10             	add    $0x10,%esp
f0101434:	85 c0                	test   %eax,%eax
f0101436:	0f 84 50 02 00 00    	je     f010168c <mem_init+0x3f3>
	assert(pp1 && pp1 != pp0);
f010143c:	39 fb                	cmp    %edi,%ebx
f010143e:	0f 84 6a 02 00 00    	je     f01016ae <mem_init+0x415>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101444:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101447:	39 c7                	cmp    %eax,%edi
f0101449:	0f 84 81 02 00 00    	je     f01016d0 <mem_init+0x437>
f010144f:	39 c3                	cmp    %eax,%ebx
f0101451:	0f 84 79 02 00 00    	je     f01016d0 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f0101457:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010145a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101460:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101462:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101468:	8b 10                	mov    (%eax),%edx
f010146a:	c1 e2 0c             	shl    $0xc,%edx
f010146d:	89 d8                	mov    %ebx,%eax
f010146f:	29 c8                	sub    %ecx,%eax
f0101471:	c1 f8 03             	sar    $0x3,%eax
f0101474:	c1 e0 0c             	shl    $0xc,%eax
f0101477:	39 d0                	cmp    %edx,%eax
f0101479:	0f 83 73 02 00 00    	jae    f01016f2 <mem_init+0x459>
f010147f:	89 f8                	mov    %edi,%eax
f0101481:	29 c8                	sub    %ecx,%eax
f0101483:	c1 f8 03             	sar    $0x3,%eax
f0101486:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101489:	39 c2                	cmp    %eax,%edx
f010148b:	0f 86 83 02 00 00    	jbe    f0101714 <mem_init+0x47b>
f0101491:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101494:	29 c8                	sub    %ecx,%eax
f0101496:	c1 f8 03             	sar    $0x3,%eax
f0101499:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010149c:	39 c2                	cmp    %eax,%edx
f010149e:	0f 86 92 02 00 00    	jbe    f0101736 <mem_init+0x49d>
	fl = page_free_list;
f01014a4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014a7:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f01014ad:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01014b0:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f01014b7:	00 00 00 
	assert(!page_alloc(0));
f01014ba:	83 ec 0c             	sub    $0xc,%esp
f01014bd:	6a 00                	push   $0x0
f01014bf:	e8 67 fa ff ff       	call   f0100f2b <page_alloc>
f01014c4:	83 c4 10             	add    $0x10,%esp
f01014c7:	85 c0                	test   %eax,%eax
f01014c9:	0f 85 89 02 00 00    	jne    f0101758 <mem_init+0x4bf>
	page_free(pp0);
f01014cf:	83 ec 0c             	sub    $0xc,%esp
f01014d2:	53                   	push   %ebx
f01014d3:	e8 db fa ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f01014d8:	89 3c 24             	mov    %edi,(%esp)
f01014db:	e8 d3 fa ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f01014e0:	83 c4 04             	add    $0x4,%esp
f01014e3:	ff 75 d0             	pushl  -0x30(%ebp)
f01014e6:	e8 c8 fa ff ff       	call   f0100fb3 <page_free>
	assert((pp0 = page_alloc(0)));
f01014eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014f2:	e8 34 fa ff ff       	call   f0100f2b <page_alloc>
f01014f7:	89 c7                	mov    %eax,%edi
f01014f9:	83 c4 10             	add    $0x10,%esp
f01014fc:	85 c0                	test   %eax,%eax
f01014fe:	0f 84 76 02 00 00    	je     f010177a <mem_init+0x4e1>
	assert((pp1 = page_alloc(0)));
f0101504:	83 ec 0c             	sub    $0xc,%esp
f0101507:	6a 00                	push   $0x0
f0101509:	e8 1d fa ff ff       	call   f0100f2b <page_alloc>
f010150e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101511:	83 c4 10             	add    $0x10,%esp
f0101514:	85 c0                	test   %eax,%eax
f0101516:	0f 84 80 02 00 00    	je     f010179c <mem_init+0x503>
	assert((pp2 = page_alloc(0)));
f010151c:	83 ec 0c             	sub    $0xc,%esp
f010151f:	6a 00                	push   $0x0
f0101521:	e8 05 fa ff ff       	call   f0100f2b <page_alloc>
f0101526:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101529:	83 c4 10             	add    $0x10,%esp
f010152c:	85 c0                	test   %eax,%eax
f010152e:	0f 84 8a 02 00 00    	je     f01017be <mem_init+0x525>
	assert(pp1 && pp1 != pp0);
f0101534:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101537:	0f 84 a3 02 00 00    	je     f01017e0 <mem_init+0x547>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010153d:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101540:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101543:	0f 84 b9 02 00 00    	je     f0101802 <mem_init+0x569>
f0101549:	39 c7                	cmp    %eax,%edi
f010154b:	0f 84 b1 02 00 00    	je     f0101802 <mem_init+0x569>
	assert(!page_alloc(0));
f0101551:	83 ec 0c             	sub    $0xc,%esp
f0101554:	6a 00                	push   $0x0
f0101556:	e8 d0 f9 ff ff       	call   f0100f2b <page_alloc>
f010155b:	83 c4 10             	add    $0x10,%esp
f010155e:	85 c0                	test   %eax,%eax
f0101560:	0f 85 be 02 00 00    	jne    f0101824 <mem_init+0x58b>
f0101566:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101569:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010156f:	89 f9                	mov    %edi,%ecx
f0101571:	2b 08                	sub    (%eax),%ecx
f0101573:	89 c8                	mov    %ecx,%eax
f0101575:	c1 f8 03             	sar    $0x3,%eax
f0101578:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010157b:	89 c1                	mov    %eax,%ecx
f010157d:	c1 e9 0c             	shr    $0xc,%ecx
f0101580:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0101586:	3b 0a                	cmp    (%edx),%ecx
f0101588:	0f 83 b8 02 00 00    	jae    f0101846 <mem_init+0x5ad>
	memset(page2kva(pp0), 1, PGSIZE);
f010158e:	83 ec 04             	sub    $0x4,%esp
f0101591:	68 00 10 00 00       	push   $0x1000
f0101596:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101598:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010159d:	50                   	push   %eax
f010159e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015a1:	e8 f1 25 00 00       	call   f0103b97 <memset>
	page_free(pp0);
f01015a6:	89 3c 24             	mov    %edi,(%esp)
f01015a9:	e8 05 fa ff ff       	call   f0100fb3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01015ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015b5:	e8 71 f9 ff ff       	call   f0100f2b <page_alloc>
f01015ba:	83 c4 10             	add    $0x10,%esp
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	0f 84 97 02 00 00    	je     f010185c <mem_init+0x5c3>
	assert(pp && pp0 == pp);
f01015c5:	39 c7                	cmp    %eax,%edi
f01015c7:	0f 85 b1 02 00 00    	jne    f010187e <mem_init+0x5e5>
	return (pp - pages) << PGSHIFT;
f01015cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01015d0:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01015d6:	89 fa                	mov    %edi,%edx
f01015d8:	2b 10                	sub    (%eax),%edx
f01015da:	c1 fa 03             	sar    $0x3,%edx
f01015dd:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015e0:	89 d1                	mov    %edx,%ecx
f01015e2:	c1 e9 0c             	shr    $0xc,%ecx
f01015e5:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01015eb:	3b 08                	cmp    (%eax),%ecx
f01015ed:	0f 83 ad 02 00 00    	jae    f01018a0 <mem_init+0x607>
	return (void *)(pa + KERNBASE);
f01015f3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01015f9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01015ff:	80 38 00             	cmpb   $0x0,(%eax)
f0101602:	0f 85 ae 02 00 00    	jne    f01018b6 <mem_init+0x61d>
f0101608:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f010160b:	39 d0                	cmp    %edx,%eax
f010160d:	75 f0                	jne    f01015ff <mem_init+0x366>
	page_free_list = fl;
f010160f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101612:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101615:	89 8b 90 1f 00 00    	mov    %ecx,0x1f90(%ebx)
	page_free(pp0);
f010161b:	83 ec 0c             	sub    $0xc,%esp
f010161e:	57                   	push   %edi
f010161f:	e8 8f f9 ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f0101624:	83 c4 04             	add    $0x4,%esp
f0101627:	ff 75 d0             	pushl  -0x30(%ebp)
f010162a:	e8 84 f9 ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f010162f:	83 c4 04             	add    $0x4,%esp
f0101632:	ff 75 cc             	pushl  -0x34(%ebp)
f0101635:	e8 79 f9 ff ff       	call   f0100fb3 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010163a:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f0101640:	83 c4 10             	add    $0x10,%esp
f0101643:	e9 95 02 00 00       	jmp    f01018dd <mem_init+0x644>
	assert((pp0 = page_alloc(0)));
f0101648:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010164b:	8d 83 a5 d9 fe ff    	lea    -0x1265b(%ebx),%eax
f0101651:	50                   	push   %eax
f0101652:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101658:	50                   	push   %eax
f0101659:	68 60 02 00 00       	push   $0x260
f010165e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101664:	50                   	push   %eax
f0101665:	e8 2f ea ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010166a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010166d:	8d 83 bb d9 fe ff    	lea    -0x12645(%ebx),%eax
f0101673:	50                   	push   %eax
f0101674:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010167a:	50                   	push   %eax
f010167b:	68 61 02 00 00       	push   $0x261
f0101680:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101686:	50                   	push   %eax
f0101687:	e8 0d ea ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010168c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010168f:	8d 83 d1 d9 fe ff    	lea    -0x1262f(%ebx),%eax
f0101695:	50                   	push   %eax
f0101696:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010169c:	50                   	push   %eax
f010169d:	68 62 02 00 00       	push   $0x262
f01016a2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01016a8:	50                   	push   %eax
f01016a9:	e8 eb e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01016ae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016b1:	8d 83 e7 d9 fe ff    	lea    -0x12619(%ebx),%eax
f01016b7:	50                   	push   %eax
f01016b8:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01016be:	50                   	push   %eax
f01016bf:	68 65 02 00 00       	push   $0x265
f01016c4:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01016ca:	50                   	push   %eax
f01016cb:	e8 c9 e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016d0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016d3:	8d 83 c4 d2 fe ff    	lea    -0x12d3c(%ebx),%eax
f01016d9:	50                   	push   %eax
f01016da:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01016e0:	50                   	push   %eax
f01016e1:	68 66 02 00 00       	push   $0x266
f01016e6:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01016ec:	50                   	push   %eax
f01016ed:	e8 a7 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01016f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016f5:	8d 83 f9 d9 fe ff    	lea    -0x12607(%ebx),%eax
f01016fb:	50                   	push   %eax
f01016fc:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101702:	50                   	push   %eax
f0101703:	68 67 02 00 00       	push   $0x267
f0101708:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010170e:	50                   	push   %eax
f010170f:	e8 85 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101714:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101717:	8d 83 16 da fe ff    	lea    -0x125ea(%ebx),%eax
f010171d:	50                   	push   %eax
f010171e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101724:	50                   	push   %eax
f0101725:	68 68 02 00 00       	push   $0x268
f010172a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101730:	50                   	push   %eax
f0101731:	e8 63 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101736:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101739:	8d 83 33 da fe ff    	lea    -0x125cd(%ebx),%eax
f010173f:	50                   	push   %eax
f0101740:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101746:	50                   	push   %eax
f0101747:	68 69 02 00 00       	push   $0x269
f010174c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101752:	50                   	push   %eax
f0101753:	e8 41 e9 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101758:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010175b:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0101761:	50                   	push   %eax
f0101762:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101768:	50                   	push   %eax
f0101769:	68 70 02 00 00       	push   $0x270
f010176e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101774:	50                   	push   %eax
f0101775:	e8 1f e9 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010177a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010177d:	8d 83 a5 d9 fe ff    	lea    -0x1265b(%ebx),%eax
f0101783:	50                   	push   %eax
f0101784:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010178a:	50                   	push   %eax
f010178b:	68 77 02 00 00       	push   $0x277
f0101790:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101796:	50                   	push   %eax
f0101797:	e8 fd e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010179c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010179f:	8d 83 bb d9 fe ff    	lea    -0x12645(%ebx),%eax
f01017a5:	50                   	push   %eax
f01017a6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01017ac:	50                   	push   %eax
f01017ad:	68 78 02 00 00       	push   $0x278
f01017b2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01017b8:	50                   	push   %eax
f01017b9:	e8 db e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01017be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017c1:	8d 83 d1 d9 fe ff    	lea    -0x1262f(%ebx),%eax
f01017c7:	50                   	push   %eax
f01017c8:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01017ce:	50                   	push   %eax
f01017cf:	68 79 02 00 00       	push   $0x279
f01017d4:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01017da:	50                   	push   %eax
f01017db:	e8 b9 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01017e0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017e3:	8d 83 e7 d9 fe ff    	lea    -0x12619(%ebx),%eax
f01017e9:	50                   	push   %eax
f01017ea:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01017f0:	50                   	push   %eax
f01017f1:	68 7b 02 00 00       	push   $0x27b
f01017f6:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01017fc:	50                   	push   %eax
f01017fd:	e8 97 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101802:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101805:	8d 83 c4 d2 fe ff    	lea    -0x12d3c(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101812:	50                   	push   %eax
f0101813:	68 7c 02 00 00       	push   $0x27c
f0101818:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010181e:	50                   	push   %eax
f010181f:	e8 75 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101824:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101827:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f010182d:	50                   	push   %eax
f010182e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0101834:	50                   	push   %eax
f0101835:	68 7d 02 00 00       	push   $0x27d
f010183a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101840:	50                   	push   %eax
f0101841:	e8 53 e8 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101846:	50                   	push   %eax
f0101847:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f010184d:	50                   	push   %eax
f010184e:	6a 52                	push   $0x52
f0101850:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f0101856:	50                   	push   %eax
f0101857:	e8 3d e8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010185c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010185f:	8d 83 5f da fe ff    	lea    -0x125a1(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010186c:	50                   	push   %eax
f010186d:	68 82 02 00 00       	push   $0x282
f0101872:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0101878:	50                   	push   %eax
f0101879:	e8 1b e8 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f010187e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101881:	8d 83 7d da fe ff    	lea    -0x12583(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010188e:	50                   	push   %eax
f010188f:	68 83 02 00 00       	push   $0x283
f0101894:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010189a:	50                   	push   %eax
f010189b:	e8 f9 e7 ff ff       	call   f0100099 <_panic>
f01018a0:	52                   	push   %edx
f01018a1:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f01018a7:	50                   	push   %eax
f01018a8:	6a 52                	push   $0x52
f01018aa:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f01018b0:	50                   	push   %eax
f01018b1:	e8 e3 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f01018b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018b9:	8d 83 8d da fe ff    	lea    -0x12573(%ebx),%eax
f01018bf:	50                   	push   %eax
f01018c0:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01018c6:	50                   	push   %eax
f01018c7:	68 86 02 00 00       	push   $0x286
f01018cc:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01018d2:	50                   	push   %eax
f01018d3:	e8 c1 e7 ff ff       	call   f0100099 <_panic>
		--nfree;
f01018d8:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018db:	8b 00                	mov    (%eax),%eax
f01018dd:	85 c0                	test   %eax,%eax
f01018df:	75 f7                	jne    f01018d8 <mem_init+0x63f>
	assert(nfree == 0);
f01018e1:	85 f6                	test   %esi,%esi
f01018e3:	0f 85 55 08 00 00    	jne    f010213e <mem_init+0xea5>
	cprintf("check_page_alloc() succeeded!\n");
f01018e9:	83 ec 0c             	sub    $0xc,%esp
f01018ec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018ef:	8d 83 e4 d2 fe ff    	lea    -0x12d1c(%ebx),%eax
f01018f5:	50                   	push   %eax
f01018f6:	e8 40 17 00 00       	call   f010303b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101902:	e8 24 f6 ff ff       	call   f0100f2b <page_alloc>
f0101907:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010190a:	83 c4 10             	add    $0x10,%esp
f010190d:	85 c0                	test   %eax,%eax
f010190f:	0f 84 4b 08 00 00    	je     f0102160 <mem_init+0xec7>
	assert((pp1 = page_alloc(0)));
f0101915:	83 ec 0c             	sub    $0xc,%esp
f0101918:	6a 00                	push   $0x0
f010191a:	e8 0c f6 ff ff       	call   f0100f2b <page_alloc>
f010191f:	89 c7                	mov    %eax,%edi
f0101921:	83 c4 10             	add    $0x10,%esp
f0101924:	85 c0                	test   %eax,%eax
f0101926:	0f 84 56 08 00 00    	je     f0102182 <mem_init+0xee9>
	assert((pp2 = page_alloc(0)));
f010192c:	83 ec 0c             	sub    $0xc,%esp
f010192f:	6a 00                	push   $0x0
f0101931:	e8 f5 f5 ff ff       	call   f0100f2b <page_alloc>
f0101936:	89 c6                	mov    %eax,%esi
f0101938:	83 c4 10             	add    $0x10,%esp
f010193b:	85 c0                	test   %eax,%eax
f010193d:	0f 84 61 08 00 00    	je     f01021a4 <mem_init+0xf0b>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101943:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101946:	0f 84 7a 08 00 00    	je     f01021c6 <mem_init+0xf2d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010194c:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010194f:	0f 84 93 08 00 00    	je     f01021e8 <mem_init+0xf4f>
f0101955:	39 c7                	cmp    %eax,%edi
f0101957:	0f 84 8b 08 00 00    	je     f01021e8 <mem_init+0xf4f>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010195d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101960:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101966:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101969:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101970:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101973:	83 ec 0c             	sub    $0xc,%esp
f0101976:	6a 00                	push   $0x0
f0101978:	e8 ae f5 ff ff       	call   f0100f2b <page_alloc>
f010197d:	83 c4 10             	add    $0x10,%esp
f0101980:	85 c0                	test   %eax,%eax
f0101982:	0f 85 82 08 00 00    	jne    f010220a <mem_init+0xf71>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101988:	83 ec 04             	sub    $0x4,%esp
f010198b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010198e:	50                   	push   %eax
f010198f:	6a 00                	push   $0x0
f0101991:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101994:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010199a:	ff 30                	pushl  (%eax)
f010199c:	e8 aa f7 ff ff       	call   f010114b <page_lookup>
f01019a1:	83 c4 10             	add    $0x10,%esp
f01019a4:	85 c0                	test   %eax,%eax
f01019a6:	0f 85 80 08 00 00    	jne    f010222c <mem_init+0xf93>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019ac:	6a 02                	push   $0x2
f01019ae:	6a 00                	push   $0x0
f01019b0:	57                   	push   %edi
f01019b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019b4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01019ba:	ff 30                	pushl  (%eax)
f01019bc:	e8 4c f8 ff ff       	call   f010120d <page_insert>
f01019c1:	83 c4 10             	add    $0x10,%esp
f01019c4:	85 c0                	test   %eax,%eax
f01019c6:	0f 89 82 08 00 00    	jns    f010224e <mem_init+0xfb5>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019cc:	83 ec 0c             	sub    $0xc,%esp
f01019cf:	ff 75 d0             	pushl  -0x30(%ebp)
f01019d2:	e8 dc f5 ff ff       	call   f0100fb3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019d7:	6a 02                	push   $0x2
f01019d9:	6a 00                	push   $0x0
f01019db:	57                   	push   %edi
f01019dc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019df:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01019e5:	ff 30                	pushl  (%eax)
f01019e7:	e8 21 f8 ff ff       	call   f010120d <page_insert>
f01019ec:	83 c4 20             	add    $0x20,%esp
f01019ef:	85 c0                	test   %eax,%eax
f01019f1:	0f 85 79 08 00 00    	jne    f0102270 <mem_init+0xfd7>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01019f7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01019fa:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a00:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a02:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101a08:	8b 08                	mov    (%eax),%ecx
f0101a0a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101a0d:	8b 13                	mov    (%ebx),%edx
f0101a0f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a15:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a18:	29 c8                	sub    %ecx,%eax
f0101a1a:	c1 f8 03             	sar    $0x3,%eax
f0101a1d:	c1 e0 0c             	shl    $0xc,%eax
f0101a20:	39 c2                	cmp    %eax,%edx
f0101a22:	0f 85 6a 08 00 00    	jne    f0102292 <mem_init+0xff9>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a28:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a2d:	89 d8                	mov    %ebx,%eax
f0101a2f:	e8 d5 ef ff ff       	call   f0100a09 <check_va2pa>
f0101a34:	89 fa                	mov    %edi,%edx
f0101a36:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a39:	c1 fa 03             	sar    $0x3,%edx
f0101a3c:	c1 e2 0c             	shl    $0xc,%edx
f0101a3f:	39 d0                	cmp    %edx,%eax
f0101a41:	0f 85 6d 08 00 00    	jne    f01022b4 <mem_init+0x101b>
	assert(pp1->pp_ref == 1);
f0101a47:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a4c:	0f 85 84 08 00 00    	jne    f01022d6 <mem_init+0x103d>
	assert(pp0->pp_ref == 1);
f0101a52:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a55:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a5a:	0f 85 98 08 00 00    	jne    f01022f8 <mem_init+0x105f>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a60:	6a 02                	push   $0x2
f0101a62:	68 00 10 00 00       	push   $0x1000
f0101a67:	56                   	push   %esi
f0101a68:	53                   	push   %ebx
f0101a69:	e8 9f f7 ff ff       	call   f010120d <page_insert>
f0101a6e:	83 c4 10             	add    $0x10,%esp
f0101a71:	85 c0                	test   %eax,%eax
f0101a73:	0f 85 a1 08 00 00    	jne    f010231a <mem_init+0x1081>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a79:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a7e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a81:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101a87:	8b 00                	mov    (%eax),%eax
f0101a89:	e8 7b ef ff ff       	call   f0100a09 <check_va2pa>
f0101a8e:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101a94:	89 f1                	mov    %esi,%ecx
f0101a96:	2b 0a                	sub    (%edx),%ecx
f0101a98:	89 ca                	mov    %ecx,%edx
f0101a9a:	c1 fa 03             	sar    $0x3,%edx
f0101a9d:	c1 e2 0c             	shl    $0xc,%edx
f0101aa0:	39 d0                	cmp    %edx,%eax
f0101aa2:	0f 85 94 08 00 00    	jne    f010233c <mem_init+0x10a3>
	assert(pp2->pp_ref == 1);
f0101aa8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aad:	0f 85 ab 08 00 00    	jne    f010235e <mem_init+0x10c5>

	// should be no free memory
	assert(!page_alloc(0));
f0101ab3:	83 ec 0c             	sub    $0xc,%esp
f0101ab6:	6a 00                	push   $0x0
f0101ab8:	e8 6e f4 ff ff       	call   f0100f2b <page_alloc>
f0101abd:	83 c4 10             	add    $0x10,%esp
f0101ac0:	85 c0                	test   %eax,%eax
f0101ac2:	0f 85 b8 08 00 00    	jne    f0102380 <mem_init+0x10e7>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ac8:	6a 02                	push   $0x2
f0101aca:	68 00 10 00 00       	push   $0x1000
f0101acf:	56                   	push   %esi
f0101ad0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ad3:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ad9:	ff 30                	pushl  (%eax)
f0101adb:	e8 2d f7 ff ff       	call   f010120d <page_insert>
f0101ae0:	83 c4 10             	add    $0x10,%esp
f0101ae3:	85 c0                	test   %eax,%eax
f0101ae5:	0f 85 b7 08 00 00    	jne    f01023a2 <mem_init+0x1109>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aeb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101af3:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101af9:	8b 00                	mov    (%eax),%eax
f0101afb:	e8 09 ef ff ff       	call   f0100a09 <check_va2pa>
f0101b00:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101b06:	89 f1                	mov    %esi,%ecx
f0101b08:	2b 0a                	sub    (%edx),%ecx
f0101b0a:	89 ca                	mov    %ecx,%edx
f0101b0c:	c1 fa 03             	sar    $0x3,%edx
f0101b0f:	c1 e2 0c             	shl    $0xc,%edx
f0101b12:	39 d0                	cmp    %edx,%eax
f0101b14:	0f 85 aa 08 00 00    	jne    f01023c4 <mem_init+0x112b>
	assert(pp2->pp_ref == 1);
f0101b1a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b1f:	0f 85 c1 08 00 00    	jne    f01023e6 <mem_init+0x114d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b25:	83 ec 0c             	sub    $0xc,%esp
f0101b28:	6a 00                	push   $0x0
f0101b2a:	e8 fc f3 ff ff       	call   f0100f2b <page_alloc>
f0101b2f:	83 c4 10             	add    $0x10,%esp
f0101b32:	85 c0                	test   %eax,%eax
f0101b34:	0f 85 ce 08 00 00    	jne    f0102408 <mem_init+0x116f>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101b3a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b3d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b43:	8b 10                	mov    (%eax),%edx
f0101b45:	8b 02                	mov    (%edx),%eax
f0101b47:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101b4c:	89 c3                	mov    %eax,%ebx
f0101b4e:	c1 eb 0c             	shr    $0xc,%ebx
f0101b51:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101b57:	3b 19                	cmp    (%ecx),%ebx
f0101b59:	0f 83 cb 08 00 00    	jae    f010242a <mem_init+0x1191>
	return (void *)(pa + KERNBASE);
f0101b5f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b64:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101b67:	83 ec 04             	sub    $0x4,%esp
f0101b6a:	6a 00                	push   $0x0
f0101b6c:	68 00 10 00 00       	push   $0x1000
f0101b71:	52                   	push   %edx
f0101b72:	e8 d7 f4 ff ff       	call   f010104e <pgdir_walk>
f0101b77:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101b7a:	8d 51 04             	lea    0x4(%ecx),%edx
f0101b7d:	83 c4 10             	add    $0x10,%esp
f0101b80:	39 d0                	cmp    %edx,%eax
f0101b82:	0f 85 be 08 00 00    	jne    f0102446 <mem_init+0x11ad>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101b88:	6a 06                	push   $0x6
f0101b8a:	68 00 10 00 00       	push   $0x1000
f0101b8f:	56                   	push   %esi
f0101b90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b93:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b99:	ff 30                	pushl  (%eax)
f0101b9b:	e8 6d f6 ff ff       	call   f010120d <page_insert>
f0101ba0:	83 c4 10             	add    $0x10,%esp
f0101ba3:	85 c0                	test   %eax,%eax
f0101ba5:	0f 85 bd 08 00 00    	jne    f0102468 <mem_init+0x11cf>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bae:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bb4:	8b 18                	mov    (%eax),%ebx
f0101bb6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bbb:	89 d8                	mov    %ebx,%eax
f0101bbd:	e8 47 ee ff ff       	call   f0100a09 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101bc2:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bc5:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101bcb:	89 f1                	mov    %esi,%ecx
f0101bcd:	2b 0a                	sub    (%edx),%ecx
f0101bcf:	89 ca                	mov    %ecx,%edx
f0101bd1:	c1 fa 03             	sar    $0x3,%edx
f0101bd4:	c1 e2 0c             	shl    $0xc,%edx
f0101bd7:	39 d0                	cmp    %edx,%eax
f0101bd9:	0f 85 ab 08 00 00    	jne    f010248a <mem_init+0x11f1>
	assert(pp2->pp_ref == 1);
f0101bdf:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be4:	0f 85 c2 08 00 00    	jne    f01024ac <mem_init+0x1213>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101bea:	83 ec 04             	sub    $0x4,%esp
f0101bed:	6a 00                	push   $0x0
f0101bef:	68 00 10 00 00       	push   $0x1000
f0101bf4:	53                   	push   %ebx
f0101bf5:	e8 54 f4 ff ff       	call   f010104e <pgdir_walk>
f0101bfa:	83 c4 10             	add    $0x10,%esp
f0101bfd:	f6 00 04             	testb  $0x4,(%eax)
f0101c00:	0f 84 c8 08 00 00    	je     f01024ce <mem_init+0x1235>
	assert(kern_pgdir[0] & PTE_U);
f0101c06:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c09:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c0f:	8b 00                	mov    (%eax),%eax
f0101c11:	f6 00 04             	testb  $0x4,(%eax)
f0101c14:	0f 84 d6 08 00 00    	je     f01024f0 <mem_init+0x1257>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c1a:	6a 02                	push   $0x2
f0101c1c:	68 00 10 00 00       	push   $0x1000
f0101c21:	56                   	push   %esi
f0101c22:	50                   	push   %eax
f0101c23:	e8 e5 f5 ff ff       	call   f010120d <page_insert>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	0f 85 df 08 00 00    	jne    f0102512 <mem_init+0x1279>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c33:	83 ec 04             	sub    $0x4,%esp
f0101c36:	6a 00                	push   $0x0
f0101c38:	68 00 10 00 00       	push   $0x1000
f0101c3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c40:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c46:	ff 30                	pushl  (%eax)
f0101c48:	e8 01 f4 ff ff       	call   f010104e <pgdir_walk>
f0101c4d:	83 c4 10             	add    $0x10,%esp
f0101c50:	f6 00 02             	testb  $0x2,(%eax)
f0101c53:	0f 84 db 08 00 00    	je     f0102534 <mem_init+0x129b>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101c59:	83 ec 04             	sub    $0x4,%esp
f0101c5c:	6a 00                	push   $0x0
f0101c5e:	68 00 10 00 00       	push   $0x1000
f0101c63:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c66:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c6c:	ff 30                	pushl  (%eax)
f0101c6e:	e8 db f3 ff ff       	call   f010104e <pgdir_walk>
f0101c73:	83 c4 10             	add    $0x10,%esp
f0101c76:	f6 00 04             	testb  $0x4,(%eax)
f0101c79:	0f 85 d7 08 00 00    	jne    f0102556 <mem_init+0x12bd>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101c7f:	6a 02                	push   $0x2
f0101c81:	68 00 00 40 00       	push   $0x400000
f0101c86:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c8c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c92:	ff 30                	pushl  (%eax)
f0101c94:	e8 74 f5 ff ff       	call   f010120d <page_insert>
f0101c99:	83 c4 10             	add    $0x10,%esp
f0101c9c:	85 c0                	test   %eax,%eax
f0101c9e:	0f 89 d4 08 00 00    	jns    f0102578 <mem_init+0x12df>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ca4:	6a 02                	push   $0x2
f0101ca6:	68 00 10 00 00       	push   $0x1000
f0101cab:	57                   	push   %edi
f0101cac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101caf:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cb5:	ff 30                	pushl  (%eax)
f0101cb7:	e8 51 f5 ff ff       	call   f010120d <page_insert>
f0101cbc:	83 c4 10             	add    $0x10,%esp
f0101cbf:	85 c0                	test   %eax,%eax
f0101cc1:	0f 85 d3 08 00 00    	jne    f010259a <mem_init+0x1301>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cc7:	83 ec 04             	sub    $0x4,%esp
f0101cca:	6a 00                	push   $0x0
f0101ccc:	68 00 10 00 00       	push   $0x1000
f0101cd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cd4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cda:	ff 30                	pushl  (%eax)
f0101cdc:	e8 6d f3 ff ff       	call   f010104e <pgdir_walk>
f0101ce1:	83 c4 10             	add    $0x10,%esp
f0101ce4:	f6 00 04             	testb  $0x4,(%eax)
f0101ce7:	0f 85 cf 08 00 00    	jne    f01025bc <mem_init+0x1323>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ced:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cf0:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cf6:	8b 18                	mov    (%eax),%ebx
f0101cf8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cfd:	89 d8                	mov    %ebx,%eax
f0101cff:	e8 05 ed ff ff       	call   f0100a09 <check_va2pa>
f0101d04:	89 c2                	mov    %eax,%edx
f0101d06:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d09:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d0c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101d12:	89 f9                	mov    %edi,%ecx
f0101d14:	2b 08                	sub    (%eax),%ecx
f0101d16:	89 c8                	mov    %ecx,%eax
f0101d18:	c1 f8 03             	sar    $0x3,%eax
f0101d1b:	c1 e0 0c             	shl    $0xc,%eax
f0101d1e:	39 c2                	cmp    %eax,%edx
f0101d20:	0f 85 b8 08 00 00    	jne    f01025de <mem_init+0x1345>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d26:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d2b:	89 d8                	mov    %ebx,%eax
f0101d2d:	e8 d7 ec ff ff       	call   f0100a09 <check_va2pa>
f0101d32:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101d35:	0f 85 c5 08 00 00    	jne    f0102600 <mem_init+0x1367>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d3b:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101d40:	0f 85 dc 08 00 00    	jne    f0102622 <mem_init+0x1389>
	assert(pp2->pp_ref == 0);
f0101d46:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101d4b:	0f 85 f3 08 00 00    	jne    f0102644 <mem_init+0x13ab>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101d51:	83 ec 0c             	sub    $0xc,%esp
f0101d54:	6a 00                	push   $0x0
f0101d56:	e8 d0 f1 ff ff       	call   f0100f2b <page_alloc>
f0101d5b:	83 c4 10             	add    $0x10,%esp
f0101d5e:	39 c6                	cmp    %eax,%esi
f0101d60:	0f 85 00 09 00 00    	jne    f0102666 <mem_init+0x13cd>
f0101d66:	85 c0                	test   %eax,%eax
f0101d68:	0f 84 f8 08 00 00    	je     f0102666 <mem_init+0x13cd>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101d6e:	83 ec 08             	sub    $0x8,%esp
f0101d71:	6a 00                	push   $0x0
f0101d73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d76:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101d7c:	ff 33                	pushl  (%ebx)
f0101d7e:	e8 46 f4 ff ff       	call   f01011c9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d83:	8b 1b                	mov    (%ebx),%ebx
f0101d85:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d8a:	89 d8                	mov    %ebx,%eax
f0101d8c:	e8 78 ec ff ff       	call   f0100a09 <check_va2pa>
f0101d91:	83 c4 10             	add    $0x10,%esp
f0101d94:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d97:	0f 85 eb 08 00 00    	jne    f0102688 <mem_init+0x13ef>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d9d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da2:	89 d8                	mov    %ebx,%eax
f0101da4:	e8 60 ec ff ff       	call   f0100a09 <check_va2pa>
f0101da9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dac:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101db2:	89 f9                	mov    %edi,%ecx
f0101db4:	2b 0a                	sub    (%edx),%ecx
f0101db6:	89 ca                	mov    %ecx,%edx
f0101db8:	c1 fa 03             	sar    $0x3,%edx
f0101dbb:	c1 e2 0c             	shl    $0xc,%edx
f0101dbe:	39 d0                	cmp    %edx,%eax
f0101dc0:	0f 85 e4 08 00 00    	jne    f01026aa <mem_init+0x1411>
	assert(pp1->pp_ref == 1);
f0101dc6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101dcb:	0f 85 fb 08 00 00    	jne    f01026cc <mem_init+0x1433>
	assert(pp2->pp_ref == 0);
f0101dd1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101dd6:	0f 85 12 09 00 00    	jne    f01026ee <mem_init+0x1455>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101ddc:	6a 00                	push   $0x0
f0101dde:	68 00 10 00 00       	push   $0x1000
f0101de3:	57                   	push   %edi
f0101de4:	53                   	push   %ebx
f0101de5:	e8 23 f4 ff ff       	call   f010120d <page_insert>
f0101dea:	83 c4 10             	add    $0x10,%esp
f0101ded:	85 c0                	test   %eax,%eax
f0101def:	0f 85 1b 09 00 00    	jne    f0102710 <mem_init+0x1477>
	assert(pp1->pp_ref);
f0101df5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101dfa:	0f 84 32 09 00 00    	je     f0102732 <mem_init+0x1499>
	assert(pp1->pp_link == NULL);
f0101e00:	83 3f 00             	cmpl   $0x0,(%edi)
f0101e03:	0f 85 4b 09 00 00    	jne    f0102754 <mem_init+0x14bb>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e09:	83 ec 08             	sub    $0x8,%esp
f0101e0c:	68 00 10 00 00       	push   $0x1000
f0101e11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e14:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101e1a:	ff 33                	pushl  (%ebx)
f0101e1c:	e8 a8 f3 ff ff       	call   f01011c9 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e21:	8b 1b                	mov    (%ebx),%ebx
f0101e23:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e28:	89 d8                	mov    %ebx,%eax
f0101e2a:	e8 da eb ff ff       	call   f0100a09 <check_va2pa>
f0101e2f:	83 c4 10             	add    $0x10,%esp
f0101e32:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e35:	0f 85 3b 09 00 00    	jne    f0102776 <mem_init+0x14dd>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e3b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e40:	89 d8                	mov    %ebx,%eax
f0101e42:	e8 c2 eb ff ff       	call   f0100a09 <check_va2pa>
f0101e47:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e4a:	0f 85 48 09 00 00    	jne    f0102798 <mem_init+0x14ff>
	assert(pp1->pp_ref == 0);
f0101e50:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e55:	0f 85 5f 09 00 00    	jne    f01027ba <mem_init+0x1521>
	assert(pp2->pp_ref == 0);
f0101e5b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e60:	0f 85 76 09 00 00    	jne    f01027dc <mem_init+0x1543>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e66:	83 ec 0c             	sub    $0xc,%esp
f0101e69:	6a 00                	push   $0x0
f0101e6b:	e8 bb f0 ff ff       	call   f0100f2b <page_alloc>
f0101e70:	83 c4 10             	add    $0x10,%esp
f0101e73:	85 c0                	test   %eax,%eax
f0101e75:	0f 84 83 09 00 00    	je     f01027fe <mem_init+0x1565>
f0101e7b:	39 c7                	cmp    %eax,%edi
f0101e7d:	0f 85 7b 09 00 00    	jne    f01027fe <mem_init+0x1565>

	// should be no free memory
	assert(!page_alloc(0));
f0101e83:	83 ec 0c             	sub    $0xc,%esp
f0101e86:	6a 00                	push   $0x0
f0101e88:	e8 9e f0 ff ff       	call   f0100f2b <page_alloc>
f0101e8d:	83 c4 10             	add    $0x10,%esp
f0101e90:	85 c0                	test   %eax,%eax
f0101e92:	0f 85 88 09 00 00    	jne    f0102820 <mem_init+0x1587>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e98:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e9b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ea1:	8b 08                	mov    (%eax),%ecx
f0101ea3:	8b 11                	mov    (%ecx),%edx
f0101ea5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101eab:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101eb1:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101eb4:	2b 18                	sub    (%eax),%ebx
f0101eb6:	89 d8                	mov    %ebx,%eax
f0101eb8:	c1 f8 03             	sar    $0x3,%eax
f0101ebb:	c1 e0 0c             	shl    $0xc,%eax
f0101ebe:	39 c2                	cmp    %eax,%edx
f0101ec0:	0f 85 7c 09 00 00    	jne    f0102842 <mem_init+0x15a9>
	kern_pgdir[0] = 0;
f0101ec6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101ecc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101ecf:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ed4:	0f 85 8a 09 00 00    	jne    f0102864 <mem_init+0x15cb>
	pp0->pp_ref = 0;
f0101eda:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101edd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ee3:	83 ec 0c             	sub    $0xc,%esp
f0101ee6:	50                   	push   %eax
f0101ee7:	e8 c7 f0 ff ff       	call   f0100fb3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101eec:	83 c4 0c             	add    $0xc,%esp
f0101eef:	6a 01                	push   $0x1
f0101ef1:	68 00 10 40 00       	push   $0x401000
f0101ef6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef9:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101eff:	ff 33                	pushl  (%ebx)
f0101f01:	e8 48 f1 ff ff       	call   f010104e <pgdir_walk>
f0101f06:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f0c:	8b 1b                	mov    (%ebx),%ebx
f0101f0e:	8b 53 04             	mov    0x4(%ebx),%edx
f0101f11:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f17:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101f1a:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101f20:	8b 09                	mov    (%ecx),%ecx
f0101f22:	89 d0                	mov    %edx,%eax
f0101f24:	c1 e8 0c             	shr    $0xc,%eax
f0101f27:	83 c4 10             	add    $0x10,%esp
f0101f2a:	39 c8                	cmp    %ecx,%eax
f0101f2c:	0f 83 54 09 00 00    	jae    f0102886 <mem_init+0x15ed>
	assert(ptep == ptep1 + PTX(va));
f0101f32:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f38:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101f3b:	0f 85 61 09 00 00    	jne    f01028a2 <mem_init+0x1609>
	kern_pgdir[PDX(va)] = 0;
f0101f41:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101f48:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0101f4b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0101f51:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f54:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101f5a:	2b 18                	sub    (%eax),%ebx
f0101f5c:	89 d8                	mov    %ebx,%eax
f0101f5e:	c1 f8 03             	sar    $0x3,%eax
f0101f61:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101f64:	89 c2                	mov    %eax,%edx
f0101f66:	c1 ea 0c             	shr    $0xc,%edx
f0101f69:	39 d1                	cmp    %edx,%ecx
f0101f6b:	0f 86 53 09 00 00    	jbe    f01028c4 <mem_init+0x162b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f71:	83 ec 04             	sub    $0x4,%esp
f0101f74:	68 00 10 00 00       	push   $0x1000
f0101f79:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101f7e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f83:	50                   	push   %eax
f0101f84:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f87:	e8 0b 1c 00 00       	call   f0103b97 <memset>
	page_free(pp0);
f0101f8c:	83 c4 04             	add    $0x4,%esp
f0101f8f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101f92:	e8 1c f0 ff ff       	call   f0100fb3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101f97:	83 c4 0c             	add    $0xc,%esp
f0101f9a:	6a 01                	push   $0x1
f0101f9c:	6a 00                	push   $0x0
f0101f9e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fa1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101fa7:	ff 30                	pushl  (%eax)
f0101fa9:	e8 a0 f0 ff ff       	call   f010104e <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101fae:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101fb4:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101fb7:	2b 10                	sub    (%eax),%edx
f0101fb9:	c1 fa 03             	sar    $0x3,%edx
f0101fbc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101fbf:	89 d1                	mov    %edx,%ecx
f0101fc1:	c1 e9 0c             	shr    $0xc,%ecx
f0101fc4:	83 c4 10             	add    $0x10,%esp
f0101fc7:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0101fcd:	3b 08                	cmp    (%eax),%ecx
f0101fcf:	0f 83 08 09 00 00    	jae    f01028dd <mem_init+0x1644>
	return (void *)(pa + KERNBASE);
f0101fd5:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101fdb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101fde:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101fe4:	f6 00 01             	testb  $0x1,(%eax)
f0101fe7:	0f 85 09 09 00 00    	jne    f01028f6 <mem_init+0x165d>
f0101fed:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0101ff0:	39 d0                	cmp    %edx,%eax
f0101ff2:	75 f0                	jne    f0101fe4 <mem_init+0xd4b>
	kern_pgdir[0] = 0;
f0101ff4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ff7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ffd:	8b 00                	mov    (%eax),%eax
f0101fff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102005:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102008:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010200e:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102011:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)

	// free the pages we took
	page_free(pp0);
f0102017:	83 ec 0c             	sub    $0xc,%esp
f010201a:	50                   	push   %eax
f010201b:	e8 93 ef ff ff       	call   f0100fb3 <page_free>
	page_free(pp1);
f0102020:	89 3c 24             	mov    %edi,(%esp)
f0102023:	e8 8b ef ff ff       	call   f0100fb3 <page_free>
	page_free(pp2);
f0102028:	89 34 24             	mov    %esi,(%esp)
f010202b:	e8 83 ef ff ff       	call   f0100fb3 <page_free>

	cprintf("check_page() succeeded!\n");
f0102030:	8d 83 6e db fe ff    	lea    -0x12492(%ebx),%eax
f0102036:	89 04 24             	mov    %eax,(%esp)
f0102039:	e8 fd 0f 00 00       	call   f010303b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f010203e:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102044:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102046:	83 c4 10             	add    $0x10,%esp
f0102049:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010204e:	0f 86 c4 08 00 00    	jbe    f0102918 <mem_init+0x167f>
f0102054:	83 ec 08             	sub    $0x8,%esp
f0102057:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102059:	05 00 00 00 10       	add    $0x10000000,%eax
f010205e:	50                   	push   %eax
f010205f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102064:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102069:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010206c:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102072:	8b 00                	mov    (%eax),%eax
f0102074:	e8 80 f0 ff ff       	call   f01010f9 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102079:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f010207f:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102082:	83 c4 10             	add    $0x10,%esp
f0102085:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010208a:	0f 86 a4 08 00 00    	jbe    f0102934 <mem_init+0x169b>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102090:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102093:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0102099:	83 ec 08             	sub    $0x8,%esp
f010209c:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f010209e:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01020a1:	05 00 00 00 10       	add    $0x10000000,%eax
f01020a6:	50                   	push   %eax
f01020a7:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020ac:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020b1:	8b 03                	mov    (%ebx),%eax
f01020b3:	e8 41 f0 ff ff       	call   f01010f9 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01020b8:	83 c4 08             	add    $0x8,%esp
f01020bb:	6a 02                	push   $0x2
f01020bd:	6a 00                	push   $0x0
f01020bf:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01020c4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01020c9:	8b 03                	mov    (%ebx),%eax
f01020cb:	e8 29 f0 ff ff       	call   f01010f9 <boot_map_region>
	pgdir = kern_pgdir;
f01020d0:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01020d2:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01020d8:	8b 00                	mov    (%eax),%eax
f01020da:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01020dd:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01020e4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01020e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01020ec:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01020f2:	8b 00                	mov    (%eax),%eax
f01020f4:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f01020f7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f01020fa:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0102100:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102103:	bf 00 00 00 00       	mov    $0x0,%edi
f0102108:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f010210b:	0f 86 84 08 00 00    	jbe    f0102995 <mem_init+0x16fc>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102111:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f0102117:	89 f0                	mov    %esi,%eax
f0102119:	e8 eb e8 ff ff       	call   f0100a09 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010211e:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102125:	0f 86 2a 08 00 00    	jbe    f0102955 <mem_init+0x16bc>
f010212b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f010212e:	39 c2                	cmp    %eax,%edx
f0102130:	0f 85 3d 08 00 00    	jne    f0102973 <mem_init+0x16da>
	for (i = 0; i < n; i += PGSIZE)
f0102136:	81 c7 00 10 00 00    	add    $0x1000,%edi
f010213c:	eb ca                	jmp    f0102108 <mem_init+0xe6f>
	assert(nfree == 0);
f010213e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102141:	8d 83 97 da fe ff    	lea    -0x12569(%ebx),%eax
f0102147:	50                   	push   %eax
f0102148:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010214e:	50                   	push   %eax
f010214f:	68 93 02 00 00       	push   $0x293
f0102154:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010215a:	50                   	push   %eax
f010215b:	e8 39 df ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102160:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102163:	8d 83 a5 d9 fe ff    	lea    -0x1265b(%ebx),%eax
f0102169:	50                   	push   %eax
f010216a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102170:	50                   	push   %eax
f0102171:	68 ec 02 00 00       	push   $0x2ec
f0102176:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010217c:	50                   	push   %eax
f010217d:	e8 17 df ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102182:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102185:	8d 83 bb d9 fe ff    	lea    -0x12645(%ebx),%eax
f010218b:	50                   	push   %eax
f010218c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102192:	50                   	push   %eax
f0102193:	68 ed 02 00 00       	push   $0x2ed
f0102198:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010219e:	50                   	push   %eax
f010219f:	e8 f5 de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01021a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021a7:	8d 83 d1 d9 fe ff    	lea    -0x1262f(%ebx),%eax
f01021ad:	50                   	push   %eax
f01021ae:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01021b4:	50                   	push   %eax
f01021b5:	68 ee 02 00 00       	push   $0x2ee
f01021ba:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01021c0:	50                   	push   %eax
f01021c1:	e8 d3 de ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01021c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021c9:	8d 83 e7 d9 fe ff    	lea    -0x12619(%ebx),%eax
f01021cf:	50                   	push   %eax
f01021d0:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01021d6:	50                   	push   %eax
f01021d7:	68 f1 02 00 00       	push   $0x2f1
f01021dc:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01021e2:	50                   	push   %eax
f01021e3:	e8 b1 de ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01021e8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021eb:	8d 83 c4 d2 fe ff    	lea    -0x12d3c(%ebx),%eax
f01021f1:	50                   	push   %eax
f01021f2:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01021f8:	50                   	push   %eax
f01021f9:	68 f2 02 00 00       	push   $0x2f2
f01021fe:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102204:	50                   	push   %eax
f0102205:	e8 8f de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010220a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010220d:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102213:	50                   	push   %eax
f0102214:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010221a:	50                   	push   %eax
f010221b:	68 f9 02 00 00       	push   $0x2f9
f0102220:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102226:	50                   	push   %eax
f0102227:	e8 6d de ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010222c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010222f:	8d 83 04 d3 fe ff    	lea    -0x12cfc(%ebx),%eax
f0102235:	50                   	push   %eax
f0102236:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010223c:	50                   	push   %eax
f010223d:	68 fc 02 00 00       	push   $0x2fc
f0102242:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102248:	50                   	push   %eax
f0102249:	e8 4b de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010224e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102251:	8d 83 3c d3 fe ff    	lea    -0x12cc4(%ebx),%eax
f0102257:	50                   	push   %eax
f0102258:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010225e:	50                   	push   %eax
f010225f:	68 ff 02 00 00       	push   $0x2ff
f0102264:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010226a:	50                   	push   %eax
f010226b:	e8 29 de ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102270:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102273:	8d 83 6c d3 fe ff    	lea    -0x12c94(%ebx),%eax
f0102279:	50                   	push   %eax
f010227a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102280:	50                   	push   %eax
f0102281:	68 03 03 00 00       	push   $0x303
f0102286:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010228c:	50                   	push   %eax
f010228d:	e8 07 de ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102292:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102295:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f010229b:	50                   	push   %eax
f010229c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01022a2:	50                   	push   %eax
f01022a3:	68 04 03 00 00       	push   $0x304
f01022a8:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01022ae:	50                   	push   %eax
f01022af:	e8 e5 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01022b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022b7:	8d 83 c4 d3 fe ff    	lea    -0x12c3c(%ebx),%eax
f01022bd:	50                   	push   %eax
f01022be:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01022c4:	50                   	push   %eax
f01022c5:	68 05 03 00 00       	push   $0x305
f01022ca:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01022d0:	50                   	push   %eax
f01022d1:	e8 c3 dd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01022d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022d9:	8d 83 a2 da fe ff    	lea    -0x1255e(%ebx),%eax
f01022df:	50                   	push   %eax
f01022e0:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01022e6:	50                   	push   %eax
f01022e7:	68 06 03 00 00       	push   $0x306
f01022ec:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01022f2:	50                   	push   %eax
f01022f3:	e8 a1 dd ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01022f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022fb:	8d 83 b3 da fe ff    	lea    -0x1254d(%ebx),%eax
f0102301:	50                   	push   %eax
f0102302:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102308:	50                   	push   %eax
f0102309:	68 07 03 00 00       	push   $0x307
f010230e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102314:	50                   	push   %eax
f0102315:	e8 7f dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010231a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010231d:	8d 83 f4 d3 fe ff    	lea    -0x12c0c(%ebx),%eax
f0102323:	50                   	push   %eax
f0102324:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010232a:	50                   	push   %eax
f010232b:	68 0a 03 00 00       	push   $0x30a
f0102330:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102336:	50                   	push   %eax
f0102337:	e8 5d dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010233c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010233f:	8d 83 30 d4 fe ff    	lea    -0x12bd0(%ebx),%eax
f0102345:	50                   	push   %eax
f0102346:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010234c:	50                   	push   %eax
f010234d:	68 0b 03 00 00       	push   $0x30b
f0102352:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102358:	50                   	push   %eax
f0102359:	e8 3b dd ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010235e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102361:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0102367:	50                   	push   %eax
f0102368:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010236e:	50                   	push   %eax
f010236f:	68 0c 03 00 00       	push   $0x30c
f0102374:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010237a:	50                   	push   %eax
f010237b:	e8 19 dd ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102380:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102383:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102389:	50                   	push   %eax
f010238a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102390:	50                   	push   %eax
f0102391:	68 0f 03 00 00       	push   $0x30f
f0102396:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010239c:	50                   	push   %eax
f010239d:	e8 f7 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023a5:	8d 83 f4 d3 fe ff    	lea    -0x12c0c(%ebx),%eax
f01023ab:	50                   	push   %eax
f01023ac:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01023b2:	50                   	push   %eax
f01023b3:	68 12 03 00 00       	push   $0x312
f01023b8:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01023be:	50                   	push   %eax
f01023bf:	e8 d5 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023c7:	8d 83 30 d4 fe ff    	lea    -0x12bd0(%ebx),%eax
f01023cd:	50                   	push   %eax
f01023ce:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01023d4:	50                   	push   %eax
f01023d5:	68 13 03 00 00       	push   $0x313
f01023da:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01023e0:	50                   	push   %eax
f01023e1:	e8 b3 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01023e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023e9:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f01023ef:	50                   	push   %eax
f01023f0:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01023f6:	50                   	push   %eax
f01023f7:	68 14 03 00 00       	push   $0x314
f01023fc:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102402:	50                   	push   %eax
f0102403:	e8 91 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102408:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010240b:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102411:	50                   	push   %eax
f0102412:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102418:	50                   	push   %eax
f0102419:	68 18 03 00 00       	push   $0x318
f010241e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102424:	50                   	push   %eax
f0102425:	e8 6f dc ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010242a:	50                   	push   %eax
f010242b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010242e:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0102434:	50                   	push   %eax
f0102435:	68 1b 03 00 00       	push   $0x31b
f010243a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102440:	50                   	push   %eax
f0102441:	e8 53 dc ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102446:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102449:	8d 83 60 d4 fe ff    	lea    -0x12ba0(%ebx),%eax
f010244f:	50                   	push   %eax
f0102450:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102456:	50                   	push   %eax
f0102457:	68 1c 03 00 00       	push   $0x31c
f010245c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102462:	50                   	push   %eax
f0102463:	e8 31 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102468:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010246b:	8d 83 a0 d4 fe ff    	lea    -0x12b60(%ebx),%eax
f0102471:	50                   	push   %eax
f0102472:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102478:	50                   	push   %eax
f0102479:	68 1f 03 00 00       	push   $0x31f
f010247e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102484:	50                   	push   %eax
f0102485:	e8 0f dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010248a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010248d:	8d 83 30 d4 fe ff    	lea    -0x12bd0(%ebx),%eax
f0102493:	50                   	push   %eax
f0102494:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010249a:	50                   	push   %eax
f010249b:	68 20 03 00 00       	push   $0x320
f01024a0:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01024a6:	50                   	push   %eax
f01024a7:	e8 ed db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024af:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f01024b5:	50                   	push   %eax
f01024b6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01024bc:	50                   	push   %eax
f01024bd:	68 21 03 00 00       	push   $0x321
f01024c2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01024c8:	50                   	push   %eax
f01024c9:	e8 cb db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01024ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024d1:	8d 83 e0 d4 fe ff    	lea    -0x12b20(%ebx),%eax
f01024d7:	50                   	push   %eax
f01024d8:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01024de:	50                   	push   %eax
f01024df:	68 22 03 00 00       	push   $0x322
f01024e4:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01024ea:	50                   	push   %eax
f01024eb:	e8 a9 db ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024f3:	8d 83 d5 da fe ff    	lea    -0x1252b(%ebx),%eax
f01024f9:	50                   	push   %eax
f01024fa:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102500:	50                   	push   %eax
f0102501:	68 23 03 00 00       	push   $0x323
f0102506:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010250c:	50                   	push   %eax
f010250d:	e8 87 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102512:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102515:	8d 83 f4 d3 fe ff    	lea    -0x12c0c(%ebx),%eax
f010251b:	50                   	push   %eax
f010251c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102522:	50                   	push   %eax
f0102523:	68 26 03 00 00       	push   $0x326
f0102528:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010252e:	50                   	push   %eax
f010252f:	e8 65 db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102534:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102537:	8d 83 14 d5 fe ff    	lea    -0x12aec(%ebx),%eax
f010253d:	50                   	push   %eax
f010253e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102544:	50                   	push   %eax
f0102545:	68 27 03 00 00       	push   $0x327
f010254a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102550:	50                   	push   %eax
f0102551:	e8 43 db ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102556:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102559:	8d 83 48 d5 fe ff    	lea    -0x12ab8(%ebx),%eax
f010255f:	50                   	push   %eax
f0102560:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102566:	50                   	push   %eax
f0102567:	68 28 03 00 00       	push   $0x328
f010256c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102572:	50                   	push   %eax
f0102573:	e8 21 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102578:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010257b:	8d 83 80 d5 fe ff    	lea    -0x12a80(%ebx),%eax
f0102581:	50                   	push   %eax
f0102582:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102588:	50                   	push   %eax
f0102589:	68 2b 03 00 00       	push   $0x32b
f010258e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102594:	50                   	push   %eax
f0102595:	e8 ff da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010259a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010259d:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f01025a3:	50                   	push   %eax
f01025a4:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01025aa:	50                   	push   %eax
f01025ab:	68 2e 03 00 00       	push   $0x32e
f01025b0:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01025b6:	50                   	push   %eax
f01025b7:	e8 dd da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025bf:	8d 83 48 d5 fe ff    	lea    -0x12ab8(%ebx),%eax
f01025c5:	50                   	push   %eax
f01025c6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01025cc:	50                   	push   %eax
f01025cd:	68 2f 03 00 00       	push   $0x32f
f01025d2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01025d8:	50                   	push   %eax
f01025d9:	e8 bb da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01025de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025e1:	8d 83 f4 d5 fe ff    	lea    -0x12a0c(%ebx),%eax
f01025e7:	50                   	push   %eax
f01025e8:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01025ee:	50                   	push   %eax
f01025ef:	68 32 03 00 00       	push   $0x332
f01025f4:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01025fa:	50                   	push   %eax
f01025fb:	e8 99 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102600:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102603:	8d 83 20 d6 fe ff    	lea    -0x129e0(%ebx),%eax
f0102609:	50                   	push   %eax
f010260a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102610:	50                   	push   %eax
f0102611:	68 33 03 00 00       	push   $0x333
f0102616:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010261c:	50                   	push   %eax
f010261d:	e8 77 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102622:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102625:	8d 83 eb da fe ff    	lea    -0x12515(%ebx),%eax
f010262b:	50                   	push   %eax
f010262c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102632:	50                   	push   %eax
f0102633:	68 35 03 00 00       	push   $0x335
f0102638:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010263e:	50                   	push   %eax
f010263f:	e8 55 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102644:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102647:	8d 83 fc da fe ff    	lea    -0x12504(%ebx),%eax
f010264d:	50                   	push   %eax
f010264e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102654:	50                   	push   %eax
f0102655:	68 36 03 00 00       	push   $0x336
f010265a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102660:	50                   	push   %eax
f0102661:	e8 33 da ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102666:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102669:	8d 83 50 d6 fe ff    	lea    -0x129b0(%ebx),%eax
f010266f:	50                   	push   %eax
f0102670:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102676:	50                   	push   %eax
f0102677:	68 39 03 00 00       	push   $0x339
f010267c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102682:	50                   	push   %eax
f0102683:	e8 11 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102688:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010268b:	8d 83 74 d6 fe ff    	lea    -0x1298c(%ebx),%eax
f0102691:	50                   	push   %eax
f0102692:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102698:	50                   	push   %eax
f0102699:	68 3d 03 00 00       	push   $0x33d
f010269e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01026a4:	50                   	push   %eax
f01026a5:	e8 ef d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026aa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026ad:	8d 83 20 d6 fe ff    	lea    -0x129e0(%ebx),%eax
f01026b3:	50                   	push   %eax
f01026b4:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01026ba:	50                   	push   %eax
f01026bb:	68 3e 03 00 00       	push   $0x33e
f01026c0:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01026c6:	50                   	push   %eax
f01026c7:	e8 cd d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01026cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026cf:	8d 83 a2 da fe ff    	lea    -0x1255e(%ebx),%eax
f01026d5:	50                   	push   %eax
f01026d6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01026dc:	50                   	push   %eax
f01026dd:	68 3f 03 00 00       	push   $0x33f
f01026e2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01026e8:	50                   	push   %eax
f01026e9:	e8 ab d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01026ee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026f1:	8d 83 fc da fe ff    	lea    -0x12504(%ebx),%eax
f01026f7:	50                   	push   %eax
f01026f8:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01026fe:	50                   	push   %eax
f01026ff:	68 40 03 00 00       	push   $0x340
f0102704:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010270a:	50                   	push   %eax
f010270b:	e8 89 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102710:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102713:	8d 83 98 d6 fe ff    	lea    -0x12968(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102720:	50                   	push   %eax
f0102721:	68 43 03 00 00       	push   $0x343
f0102726:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010272c:	50                   	push   %eax
f010272d:	e8 67 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102732:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102735:	8d 83 0d db fe ff    	lea    -0x124f3(%ebx),%eax
f010273b:	50                   	push   %eax
f010273c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102742:	50                   	push   %eax
f0102743:	68 44 03 00 00       	push   $0x344
f0102748:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010274e:	50                   	push   %eax
f010274f:	e8 45 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102754:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102757:	8d 83 19 db fe ff    	lea    -0x124e7(%ebx),%eax
f010275d:	50                   	push   %eax
f010275e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102764:	50                   	push   %eax
f0102765:	68 45 03 00 00       	push   $0x345
f010276a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102770:	50                   	push   %eax
f0102771:	e8 23 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102776:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102779:	8d 83 74 d6 fe ff    	lea    -0x1298c(%ebx),%eax
f010277f:	50                   	push   %eax
f0102780:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102786:	50                   	push   %eax
f0102787:	68 49 03 00 00       	push   $0x349
f010278c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102792:	50                   	push   %eax
f0102793:	e8 01 d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102798:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010279b:	8d 83 d0 d6 fe ff    	lea    -0x12930(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01027a8:	50                   	push   %eax
f01027a9:	68 4a 03 00 00       	push   $0x34a
f01027ae:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01027b4:	50                   	push   %eax
f01027b5:	e8 df d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01027ba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027bd:	8d 83 2e db fe ff    	lea    -0x124d2(%ebx),%eax
f01027c3:	50                   	push   %eax
f01027c4:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01027ca:	50                   	push   %eax
f01027cb:	68 4b 03 00 00       	push   $0x34b
f01027d0:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01027d6:	50                   	push   %eax
f01027d7:	e8 bd d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01027dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027df:	8d 83 fc da fe ff    	lea    -0x12504(%ebx),%eax
f01027e5:	50                   	push   %eax
f01027e6:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01027ec:	50                   	push   %eax
f01027ed:	68 4c 03 00 00       	push   $0x34c
f01027f2:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01027f8:	50                   	push   %eax
f01027f9:	e8 9b d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01027fe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102801:	8d 83 f8 d6 fe ff    	lea    -0x12908(%ebx),%eax
f0102807:	50                   	push   %eax
f0102808:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f010280e:	50                   	push   %eax
f010280f:	68 4f 03 00 00       	push   $0x34f
f0102814:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010281a:	50                   	push   %eax
f010281b:	e8 79 d8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102820:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102823:	8d 83 50 da fe ff    	lea    -0x125b0(%ebx),%eax
f0102829:	50                   	push   %eax
f010282a:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102830:	50                   	push   %eax
f0102831:	68 52 03 00 00       	push   $0x352
f0102836:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010283c:	50                   	push   %eax
f010283d:	e8 57 d8 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102842:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102845:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f010284b:	50                   	push   %eax
f010284c:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102852:	50                   	push   %eax
f0102853:	68 55 03 00 00       	push   $0x355
f0102858:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010285e:	50                   	push   %eax
f010285f:	e8 35 d8 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102864:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102867:	8d 83 b3 da fe ff    	lea    -0x1254d(%ebx),%eax
f010286d:	50                   	push   %eax
f010286e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102874:	50                   	push   %eax
f0102875:	68 57 03 00 00       	push   $0x357
f010287a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102880:	50                   	push   %eax
f0102881:	e8 13 d8 ff ff       	call   f0100099 <_panic>
f0102886:	52                   	push   %edx
f0102887:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010288a:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0102890:	50                   	push   %eax
f0102891:	68 5e 03 00 00       	push   $0x35e
f0102896:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010289c:	50                   	push   %eax
f010289d:	e8 f7 d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a5:	8d 83 3f db fe ff    	lea    -0x124c1(%ebx),%eax
f01028ab:	50                   	push   %eax
f01028ac:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f01028b2:	50                   	push   %eax
f01028b3:	68 5f 03 00 00       	push   $0x35f
f01028b8:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01028be:	50                   	push   %eax
f01028bf:	e8 d5 d7 ff ff       	call   f0100099 <_panic>
f01028c4:	50                   	push   %eax
f01028c5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028c8:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f01028ce:	50                   	push   %eax
f01028cf:	6a 52                	push   $0x52
f01028d1:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	e8 bc d7 ff ff       	call   f0100099 <_panic>
f01028dd:	52                   	push   %edx
f01028de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e1:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f01028e7:	50                   	push   %eax
f01028e8:	6a 52                	push   $0x52
f01028ea:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f01028f0:	50                   	push   %eax
f01028f1:	e8 a3 d7 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01028f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f9:	8d 83 57 db fe ff    	lea    -0x124a9(%ebx),%eax
f01028ff:	50                   	push   %eax
f0102900:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102906:	50                   	push   %eax
f0102907:	68 69 03 00 00       	push   $0x369
f010290c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102912:	50                   	push   %eax
f0102913:	e8 81 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102918:	50                   	push   %eax
f0102919:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010291c:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0102922:	50                   	push   %eax
f0102923:	68 af 00 00 00       	push   $0xaf
f0102928:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010292e:	50                   	push   %eax
f010292f:	e8 65 d7 ff ff       	call   f0100099 <_panic>
f0102934:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102937:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f010293d:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0102943:	50                   	push   %eax
f0102944:	68 bb 00 00 00       	push   $0xbb
f0102949:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010294f:	50                   	push   %eax
f0102950:	e8 44 d7 ff ff       	call   f0100099 <_panic>
f0102955:	ff 75 c0             	pushl  -0x40(%ebp)
f0102958:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010295b:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0102961:	50                   	push   %eax
f0102962:	68 ab 02 00 00       	push   $0x2ab
f0102967:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010296d:	50                   	push   %eax
f010296e:	e8 26 d7 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102973:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102976:	8d 83 1c d7 fe ff    	lea    -0x128e4(%ebx),%eax
f010297c:	50                   	push   %eax
f010297d:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102983:	50                   	push   %eax
f0102984:	68 ab 02 00 00       	push   $0x2ab
f0102989:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f010298f:	50                   	push   %eax
f0102990:	e8 04 d7 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102995:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102998:	c1 e7 0c             	shl    $0xc,%edi
f010299b:	bb 00 00 00 00       	mov    $0x0,%ebx
f01029a0:	eb 17                	jmp    f01029b9 <mem_init+0x1720>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029a2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01029a8:	89 f0                	mov    %esi,%eax
f01029aa:	e8 5a e0 ff ff       	call   f0100a09 <check_va2pa>
f01029af:	39 c3                	cmp    %eax,%ebx
f01029b1:	75 51                	jne    f0102a04 <mem_init+0x176b>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029b3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01029b9:	39 fb                	cmp    %edi,%ebx
f01029bb:	72 e5                	jb     f01029a2 <mem_init+0x1709>
f01029bd:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01029c2:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01029c5:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f01029cb:	89 da                	mov    %ebx,%edx
f01029cd:	89 f0                	mov    %esi,%eax
f01029cf:	e8 35 e0 ff ff       	call   f0100a09 <check_va2pa>
f01029d4:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f01029d7:	39 c2                	cmp    %eax,%edx
f01029d9:	75 4b                	jne    f0102a26 <mem_init+0x178d>
f01029db:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029e1:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01029e7:	75 e2                	jne    f01029cb <mem_init+0x1732>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029e9:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01029ee:	89 f0                	mov    %esi,%eax
f01029f0:	e8 14 e0 ff ff       	call   f0100a09 <check_va2pa>
f01029f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029f8:	75 4e                	jne    f0102a48 <mem_init+0x17af>
	for (i = 0; i < NPDENTRIES; i++) {
f01029fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01029ff:	e9 8f 00 00 00       	jmp    f0102a93 <mem_init+0x17fa>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a04:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a07:	8d 83 50 d7 fe ff    	lea    -0x128b0(%ebx),%eax
f0102a0d:	50                   	push   %eax
f0102a0e:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102a14:	50                   	push   %eax
f0102a15:	68 b0 02 00 00       	push   $0x2b0
f0102a1a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102a20:	50                   	push   %eax
f0102a21:	e8 73 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a26:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a29:	8d 83 78 d7 fe ff    	lea    -0x12888(%ebx),%eax
f0102a2f:	50                   	push   %eax
f0102a30:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102a36:	50                   	push   %eax
f0102a37:	68 b4 02 00 00       	push   $0x2b4
f0102a3c:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102a42:	50                   	push   %eax
f0102a43:	e8 51 d6 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a48:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a4b:	8d 83 c0 d7 fe ff    	lea    -0x12840(%ebx),%eax
f0102a51:	50                   	push   %eax
f0102a52:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102a58:	50                   	push   %eax
f0102a59:	68 b5 02 00 00       	push   $0x2b5
f0102a5e:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102a64:	50                   	push   %eax
f0102a65:	e8 2f d6 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102a6a:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102a6e:	74 52                	je     f0102ac2 <mem_init+0x1829>
	for (i = 0; i < NPDENTRIES; i++) {
f0102a70:	83 c0 01             	add    $0x1,%eax
f0102a73:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102a78:	0f 87 bb 00 00 00    	ja     f0102b39 <mem_init+0x18a0>
		switch (i) {
f0102a7e:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102a83:	72 0e                	jb     f0102a93 <mem_init+0x17fa>
f0102a85:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102a8a:	76 de                	jbe    f0102a6a <mem_init+0x17d1>
f0102a8c:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a91:	74 d7                	je     f0102a6a <mem_init+0x17d1>
			if (i >= PDX(KERNBASE)) {
f0102a93:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a98:	77 4a                	ja     f0102ae4 <mem_init+0x184b>
				assert(pgdir[i] == 0);
f0102a9a:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102a9e:	74 d0                	je     f0102a70 <mem_init+0x17d7>
f0102aa0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aa3:	8d 83 a9 db fe ff    	lea    -0x12457(%ebx),%eax
f0102aa9:	50                   	push   %eax
f0102aaa:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102ab0:	50                   	push   %eax
f0102ab1:	68 c4 02 00 00       	push   $0x2c4
f0102ab6:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102abc:	50                   	push   %eax
f0102abd:	e8 d7 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ac2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ac5:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0102acb:	50                   	push   %eax
f0102acc:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102ad2:	50                   	push   %eax
f0102ad3:	68 bd 02 00 00       	push   $0x2bd
f0102ad8:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102ade:	50                   	push   %eax
f0102adf:	e8 b5 d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ae4:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102ae7:	f6 c2 01             	test   $0x1,%dl
f0102aea:	74 2b                	je     f0102b17 <mem_init+0x187e>
				assert(pgdir[i] & PTE_W);
f0102aec:	f6 c2 02             	test   $0x2,%dl
f0102aef:	0f 85 7b ff ff ff    	jne    f0102a70 <mem_init+0x17d7>
f0102af5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102af8:	8d 83 98 db fe ff    	lea    -0x12468(%ebx),%eax
f0102afe:	50                   	push   %eax
f0102aff:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102b05:	50                   	push   %eax
f0102b06:	68 c2 02 00 00       	push   $0x2c2
f0102b0b:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102b11:	50                   	push   %eax
f0102b12:	e8 82 d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1a:	8d 83 87 db fe ff    	lea    -0x12479(%ebx),%eax
f0102b20:	50                   	push   %eax
f0102b21:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102b27:	50                   	push   %eax
f0102b28:	68 c1 02 00 00       	push   $0x2c1
f0102b2d:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102b33:	50                   	push   %eax
f0102b34:	e8 60 d5 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b39:	83 ec 0c             	sub    $0xc,%esp
f0102b3c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102b3f:	8d 87 f0 d7 fe ff    	lea    -0x12810(%edi),%eax
f0102b45:	50                   	push   %eax
f0102b46:	89 fb                	mov    %edi,%ebx
f0102b48:	e8 ee 04 00 00       	call   f010303b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b4d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102b53:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102b55:	83 c4 10             	add    $0x10,%esp
f0102b58:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102b5d:	0f 86 44 02 00 00    	jbe    f0102da7 <mem_init+0x1b0e>
	return (physaddr_t)kva - KERNBASE;
f0102b63:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102b68:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102b6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b70:	e8 11 df ff ff       	call   f0100a86 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102b75:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b78:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b7b:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102b80:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b83:	83 ec 0c             	sub    $0xc,%esp
f0102b86:	6a 00                	push   $0x0
f0102b88:	e8 9e e3 ff ff       	call   f0100f2b <page_alloc>
f0102b8d:	89 c6                	mov    %eax,%esi
f0102b8f:	83 c4 10             	add    $0x10,%esp
f0102b92:	85 c0                	test   %eax,%eax
f0102b94:	0f 84 29 02 00 00    	je     f0102dc3 <mem_init+0x1b2a>
	assert((pp1 = page_alloc(0)));
f0102b9a:	83 ec 0c             	sub    $0xc,%esp
f0102b9d:	6a 00                	push   $0x0
f0102b9f:	e8 87 e3 ff ff       	call   f0100f2b <page_alloc>
f0102ba4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102ba7:	83 c4 10             	add    $0x10,%esp
f0102baa:	85 c0                	test   %eax,%eax
f0102bac:	0f 84 33 02 00 00    	je     f0102de5 <mem_init+0x1b4c>
	assert((pp2 = page_alloc(0)));
f0102bb2:	83 ec 0c             	sub    $0xc,%esp
f0102bb5:	6a 00                	push   $0x0
f0102bb7:	e8 6f e3 ff ff       	call   f0100f2b <page_alloc>
f0102bbc:	89 c7                	mov    %eax,%edi
f0102bbe:	83 c4 10             	add    $0x10,%esp
f0102bc1:	85 c0                	test   %eax,%eax
f0102bc3:	0f 84 3e 02 00 00    	je     f0102e07 <mem_init+0x1b6e>
	page_free(pp0);
f0102bc9:	83 ec 0c             	sub    $0xc,%esp
f0102bcc:	56                   	push   %esi
f0102bcd:	e8 e1 e3 ff ff       	call   f0100fb3 <page_free>
	return (pp - pages) << PGSHIFT;
f0102bd2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bd5:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102bdb:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102bde:	2b 08                	sub    (%eax),%ecx
f0102be0:	89 c8                	mov    %ecx,%eax
f0102be2:	c1 f8 03             	sar    $0x3,%eax
f0102be5:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102be8:	89 c1                	mov    %eax,%ecx
f0102bea:	c1 e9 0c             	shr    $0xc,%ecx
f0102bed:	83 c4 10             	add    $0x10,%esp
f0102bf0:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102bf6:	3b 0a                	cmp    (%edx),%ecx
f0102bf8:	0f 83 2b 02 00 00    	jae    f0102e29 <mem_init+0x1b90>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bfe:	83 ec 04             	sub    $0x4,%esp
f0102c01:	68 00 10 00 00       	push   $0x1000
f0102c06:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c08:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c0d:	50                   	push   %eax
f0102c0e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c11:	e8 81 0f 00 00       	call   f0103b97 <memset>
	return (pp - pages) << PGSHIFT;
f0102c16:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c19:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102c1f:	89 f9                	mov    %edi,%ecx
f0102c21:	2b 08                	sub    (%eax),%ecx
f0102c23:	89 c8                	mov    %ecx,%eax
f0102c25:	c1 f8 03             	sar    $0x3,%eax
f0102c28:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102c2b:	89 c1                	mov    %eax,%ecx
f0102c2d:	c1 e9 0c             	shr    $0xc,%ecx
f0102c30:	83 c4 10             	add    $0x10,%esp
f0102c33:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102c39:	3b 0a                	cmp    (%edx),%ecx
f0102c3b:	0f 83 fe 01 00 00    	jae    f0102e3f <mem_init+0x1ba6>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c41:	83 ec 04             	sub    $0x4,%esp
f0102c44:	68 00 10 00 00       	push   $0x1000
f0102c49:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c4b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c50:	50                   	push   %eax
f0102c51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c54:	e8 3e 0f 00 00       	call   f0103b97 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c59:	6a 02                	push   $0x2
f0102c5b:	68 00 10 00 00       	push   $0x1000
f0102c60:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102c63:	53                   	push   %ebx
f0102c64:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c67:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102c6d:	ff 30                	pushl  (%eax)
f0102c6f:	e8 99 e5 ff ff       	call   f010120d <page_insert>
	assert(pp1->pp_ref == 1);
f0102c74:	83 c4 20             	add    $0x20,%esp
f0102c77:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c7c:	0f 85 d3 01 00 00    	jne    f0102e55 <mem_init+0x1bbc>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c82:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c89:	01 01 01 
f0102c8c:	0f 85 e5 01 00 00    	jne    f0102e77 <mem_init+0x1bde>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c92:	6a 02                	push   $0x2
f0102c94:	68 00 10 00 00       	push   $0x1000
f0102c99:	57                   	push   %edi
f0102c9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102c9d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102ca3:	ff 30                	pushl  (%eax)
f0102ca5:	e8 63 e5 ff ff       	call   f010120d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102caa:	83 c4 10             	add    $0x10,%esp
f0102cad:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cb4:	02 02 02 
f0102cb7:	0f 85 dc 01 00 00    	jne    f0102e99 <mem_init+0x1c00>
	assert(pp2->pp_ref == 1);
f0102cbd:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cc2:	0f 85 f3 01 00 00    	jne    f0102ebb <mem_init+0x1c22>
	assert(pp1->pp_ref == 0);
f0102cc8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102ccb:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102cd0:	0f 85 07 02 00 00    	jne    f0102edd <mem_init+0x1c44>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102cd6:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102cdd:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102ce0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ce3:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102ce9:	89 f9                	mov    %edi,%ecx
f0102ceb:	2b 08                	sub    (%eax),%ecx
f0102ced:	89 c8                	mov    %ecx,%eax
f0102cef:	c1 f8 03             	sar    $0x3,%eax
f0102cf2:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102cf5:	89 c1                	mov    %eax,%ecx
f0102cf7:	c1 e9 0c             	shr    $0xc,%ecx
f0102cfa:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102d00:	3b 0a                	cmp    (%edx),%ecx
f0102d02:	0f 83 f7 01 00 00    	jae    f0102eff <mem_init+0x1c66>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d08:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d0f:	03 03 03 
f0102d12:	0f 85 fd 01 00 00    	jne    f0102f15 <mem_init+0x1c7c>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d18:	83 ec 08             	sub    $0x8,%esp
f0102d1b:	68 00 10 00 00       	push   $0x1000
f0102d20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d23:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d29:	ff 30                	pushl  (%eax)
f0102d2b:	e8 99 e4 ff ff       	call   f01011c9 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d30:	83 c4 10             	add    $0x10,%esp
f0102d33:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d38:	0f 85 f9 01 00 00    	jne    f0102f37 <mem_init+0x1c9e>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d3e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d41:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d47:	8b 08                	mov    (%eax),%ecx
f0102d49:	8b 11                	mov    (%ecx),%edx
f0102d4b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d51:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102d57:	89 f7                	mov    %esi,%edi
f0102d59:	2b 38                	sub    (%eax),%edi
f0102d5b:	89 f8                	mov    %edi,%eax
f0102d5d:	c1 f8 03             	sar    $0x3,%eax
f0102d60:	c1 e0 0c             	shl    $0xc,%eax
f0102d63:	39 c2                	cmp    %eax,%edx
f0102d65:	0f 85 ee 01 00 00    	jne    f0102f59 <mem_init+0x1cc0>
	kern_pgdir[0] = 0;
f0102d6b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102d71:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d76:	0f 85 ff 01 00 00    	jne    f0102f7b <mem_init+0x1ce2>
	pp0->pp_ref = 0;
f0102d7c:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d82:	83 ec 0c             	sub    $0xc,%esp
f0102d85:	56                   	push   %esi
f0102d86:	e8 28 e2 ff ff       	call   f0100fb3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d8b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d8e:	8d 83 84 d8 fe ff    	lea    -0x1277c(%ebx),%eax
f0102d94:	89 04 24             	mov    %eax,(%esp)
f0102d97:	e8 9f 02 00 00       	call   f010303b <cprintf>
}
f0102d9c:	83 c4 10             	add    $0x10,%esp
f0102d9f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102da2:	5b                   	pop    %ebx
f0102da3:	5e                   	pop    %esi
f0102da4:	5f                   	pop    %edi
f0102da5:	5d                   	pop    %ebp
f0102da6:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102da7:	50                   	push   %eax
f0102da8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dab:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0102db1:	50                   	push   %eax
f0102db2:	68 cf 00 00 00       	push   $0xcf
f0102db7:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102dbd:	50                   	push   %eax
f0102dbe:	e8 d6 d2 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102dc3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dc6:	8d 83 a5 d9 fe ff    	lea    -0x1265b(%ebx),%eax
f0102dcc:	50                   	push   %eax
f0102dcd:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	68 84 03 00 00       	push   $0x384
f0102dd9:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102ddf:	50                   	push   %eax
f0102de0:	e8 b4 d2 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102de5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102de8:	8d 83 bb d9 fe ff    	lea    -0x12645(%ebx),%eax
f0102dee:	50                   	push   %eax
f0102def:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102df5:	50                   	push   %eax
f0102df6:	68 85 03 00 00       	push   $0x385
f0102dfb:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102e01:	50                   	push   %eax
f0102e02:	e8 92 d2 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e07:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e0a:	8d 83 d1 d9 fe ff    	lea    -0x1262f(%ebx),%eax
f0102e10:	50                   	push   %eax
f0102e11:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102e17:	50                   	push   %eax
f0102e18:	68 86 03 00 00       	push   $0x386
f0102e1d:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102e23:	50                   	push   %eax
f0102e24:	e8 70 d2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e29:	50                   	push   %eax
f0102e2a:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0102e30:	50                   	push   %eax
f0102e31:	6a 52                	push   $0x52
f0102e33:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f0102e39:	50                   	push   %eax
f0102e3a:	e8 5a d2 ff ff       	call   f0100099 <_panic>
f0102e3f:	50                   	push   %eax
f0102e40:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0102e46:	50                   	push   %eax
f0102e47:	6a 52                	push   $0x52
f0102e49:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f0102e4f:	50                   	push   %eax
f0102e50:	e8 44 d2 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102e55:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e58:	8d 83 a2 da fe ff    	lea    -0x1255e(%ebx),%eax
f0102e5e:	50                   	push   %eax
f0102e5f:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102e65:	50                   	push   %eax
f0102e66:	68 8b 03 00 00       	push   $0x38b
f0102e6b:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102e71:	50                   	push   %eax
f0102e72:	e8 22 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102e77:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e7a:	8d 83 10 d8 fe ff    	lea    -0x127f0(%ebx),%eax
f0102e80:	50                   	push   %eax
f0102e81:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102e87:	50                   	push   %eax
f0102e88:	68 8c 03 00 00       	push   $0x38c
f0102e8d:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102e93:	50                   	push   %eax
f0102e94:	e8 00 d2 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102e99:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e9c:	8d 83 34 d8 fe ff    	lea    -0x127cc(%ebx),%eax
f0102ea2:	50                   	push   %eax
f0102ea3:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102ea9:	50                   	push   %eax
f0102eaa:	68 8e 03 00 00       	push   $0x38e
f0102eaf:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102eb5:	50                   	push   %eax
f0102eb6:	e8 de d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102ebb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ebe:	8d 83 c4 da fe ff    	lea    -0x1253c(%ebx),%eax
f0102ec4:	50                   	push   %eax
f0102ec5:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102ecb:	50                   	push   %eax
f0102ecc:	68 8f 03 00 00       	push   $0x38f
f0102ed1:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102ed7:	50                   	push   %eax
f0102ed8:	e8 bc d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102edd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ee0:	8d 83 2e db fe ff    	lea    -0x124d2(%ebx),%eax
f0102ee6:	50                   	push   %eax
f0102ee7:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102eed:	50                   	push   %eax
f0102eee:	68 90 03 00 00       	push   $0x390
f0102ef3:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102ef9:	50                   	push   %eax
f0102efa:	e8 9a d1 ff ff       	call   f0100099 <_panic>
f0102eff:	50                   	push   %eax
f0102f00:	8d 83 38 d1 fe ff    	lea    -0x12ec8(%ebx),%eax
f0102f06:	50                   	push   %eax
f0102f07:	6a 52                	push   $0x52
f0102f09:	8d 83 bc d8 fe ff    	lea    -0x12744(%ebx),%eax
f0102f0f:	50                   	push   %eax
f0102f10:	e8 84 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f18:	8d 83 58 d8 fe ff    	lea    -0x127a8(%ebx),%eax
f0102f1e:	50                   	push   %eax
f0102f1f:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102f25:	50                   	push   %eax
f0102f26:	68 92 03 00 00       	push   $0x392
f0102f2b:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102f31:	50                   	push   %eax
f0102f32:	e8 62 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102f37:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f3a:	8d 83 fc da fe ff    	lea    -0x12504(%ebx),%eax
f0102f40:	50                   	push   %eax
f0102f41:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102f47:	50                   	push   %eax
f0102f48:	68 94 03 00 00       	push   $0x394
f0102f4d:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102f53:	50                   	push   %eax
f0102f54:	e8 40 d1 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f59:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f5c:	8d 83 9c d3 fe ff    	lea    -0x12c64(%ebx),%eax
f0102f62:	50                   	push   %eax
f0102f63:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102f69:	50                   	push   %eax
f0102f6a:	68 97 03 00 00       	push   $0x397
f0102f6f:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102f75:	50                   	push   %eax
f0102f76:	e8 1e d1 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102f7b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f7e:	8d 83 b3 da fe ff    	lea    -0x1254d(%ebx),%eax
f0102f84:	50                   	push   %eax
f0102f85:	8d 83 d6 d8 fe ff    	lea    -0x1272a(%ebx),%eax
f0102f8b:	50                   	push   %eax
f0102f8c:	68 99 03 00 00       	push   $0x399
f0102f91:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102f97:	50                   	push   %eax
f0102f98:	e8 fc d0 ff ff       	call   f0100099 <_panic>

f0102f9d <tlb_invalidate>:
{
f0102f9d:	55                   	push   %ebp
f0102f9e:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fa0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fa3:	0f 01 38             	invlpg (%eax)
}
f0102fa6:	5d                   	pop    %ebp
f0102fa7:	c3                   	ret    

f0102fa8 <__x86.get_pc_thunk.dx>:
f0102fa8:	8b 14 24             	mov    (%esp),%edx
f0102fab:	c3                   	ret    

f0102fac <__x86.get_pc_thunk.cx>:
f0102fac:	8b 0c 24             	mov    (%esp),%ecx
f0102faf:	c3                   	ret    

f0102fb0 <__x86.get_pc_thunk.di>:
f0102fb0:	8b 3c 24             	mov    (%esp),%edi
f0102fb3:	c3                   	ret    

f0102fb4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102fb4:	55                   	push   %ebp
f0102fb5:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fb7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fba:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fbf:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102fc0:	ba 71 00 00 00       	mov    $0x71,%edx
f0102fc5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102fc6:	0f b6 c0             	movzbl %al,%eax
}
f0102fc9:	5d                   	pop    %ebp
f0102fca:	c3                   	ret    

f0102fcb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102fcb:	55                   	push   %ebp
f0102fcc:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fce:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fd1:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fd6:	ee                   	out    %al,(%dx)
f0102fd7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fda:	ba 71 00 00 00       	mov    $0x71,%edx
f0102fdf:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102fe0:	5d                   	pop    %ebp
f0102fe1:	c3                   	ret    

f0102fe2 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102fe2:	55                   	push   %ebp
f0102fe3:	89 e5                	mov    %esp,%ebp
f0102fe5:	53                   	push   %ebx
f0102fe6:	83 ec 10             	sub    $0x10,%esp
f0102fe9:	e8 61 d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102fee:	81 c3 1e 43 01 00    	add    $0x1431e,%ebx
	cputchar(ch);
f0102ff4:	ff 75 08             	pushl  0x8(%ebp)
f0102ff7:	e8 ca d6 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f0102ffc:	83 c4 10             	add    $0x10,%esp
f0102fff:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103002:	c9                   	leave  
f0103003:	c3                   	ret    

f0103004 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103004:	55                   	push   %ebp
f0103005:	89 e5                	mov    %esp,%ebp
f0103007:	53                   	push   %ebx
f0103008:	83 ec 14             	sub    $0x14,%esp
f010300b:	e8 3f d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103010:	81 c3 fc 42 01 00    	add    $0x142fc,%ebx
	int cnt = 0;
f0103016:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010301d:	ff 75 0c             	pushl  0xc(%ebp)
f0103020:	ff 75 08             	pushl  0x8(%ebp)
f0103023:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103026:	50                   	push   %eax
f0103027:	8d 83 d6 bc fe ff    	lea    -0x1432a(%ebx),%eax
f010302d:	50                   	push   %eax
f010302e:	e8 18 04 00 00       	call   f010344b <vprintfmt>
	return cnt;
}
f0103033:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103036:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103039:	c9                   	leave  
f010303a:	c3                   	ret    

f010303b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010303b:	55                   	push   %ebp
f010303c:	89 e5                	mov    %esp,%ebp
f010303e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103041:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103044:	50                   	push   %eax
f0103045:	ff 75 08             	pushl  0x8(%ebp)
f0103048:	e8 b7 ff ff ff       	call   f0103004 <vcprintf>
	va_end(ap);

	return cnt;
}
f010304d:	c9                   	leave  
f010304e:	c3                   	ret    

f010304f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010304f:	55                   	push   %ebp
f0103050:	89 e5                	mov    %esp,%ebp
f0103052:	57                   	push   %edi
f0103053:	56                   	push   %esi
f0103054:	53                   	push   %ebx
f0103055:	83 ec 14             	sub    $0x14,%esp
f0103058:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010305b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010305e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103061:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103064:	8b 32                	mov    (%edx),%esi
f0103066:	8b 01                	mov    (%ecx),%eax
f0103068:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010306b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103072:	eb 2f                	jmp    f01030a3 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103074:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0103077:	39 c6                	cmp    %eax,%esi
f0103079:	7f 49                	jg     f01030c4 <stab_binsearch+0x75>
f010307b:	0f b6 0a             	movzbl (%edx),%ecx
f010307e:	83 ea 0c             	sub    $0xc,%edx
f0103081:	39 f9                	cmp    %edi,%ecx
f0103083:	75 ef                	jne    f0103074 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103085:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103088:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010308b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010308f:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103092:	73 35                	jae    f01030c9 <stab_binsearch+0x7a>
			*region_left = m;
f0103094:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103097:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0103099:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010309c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01030a3:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01030a6:	7f 4e                	jg     f01030f6 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01030a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030ab:	01 f0                	add    %esi,%eax
f01030ad:	89 c3                	mov    %eax,%ebx
f01030af:	c1 eb 1f             	shr    $0x1f,%ebx
f01030b2:	01 c3                	add    %eax,%ebx
f01030b4:	d1 fb                	sar    %ebx
f01030b6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01030b9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030bc:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01030c0:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01030c2:	eb b3                	jmp    f0103077 <stab_binsearch+0x28>
			l = true_m + 1;
f01030c4:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01030c7:	eb da                	jmp    f01030a3 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01030c9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01030cc:	76 14                	jbe    f01030e2 <stab_binsearch+0x93>
			*region_right = m - 1;
f01030ce:	83 e8 01             	sub    $0x1,%eax
f01030d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030d4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01030d7:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01030d9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01030e0:	eb c1                	jmp    f01030a3 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01030e2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01030e5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01030e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01030eb:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01030ed:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01030f4:	eb ad                	jmp    f01030a3 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01030f6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01030fa:	74 16                	je     f0103112 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01030fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030ff:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103101:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103104:	8b 0e                	mov    (%esi),%ecx
f0103106:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103109:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010310c:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103110:	eb 12                	jmp    f0103124 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103112:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103115:	8b 00                	mov    (%eax),%eax
f0103117:	83 e8 01             	sub    $0x1,%eax
f010311a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010311d:	89 07                	mov    %eax,(%edi)
f010311f:	eb 16                	jmp    f0103137 <stab_binsearch+0xe8>
		     l--)
f0103121:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103124:	39 c1                	cmp    %eax,%ecx
f0103126:	7d 0a                	jge    f0103132 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0103128:	0f b6 1a             	movzbl (%edx),%ebx
f010312b:	83 ea 0c             	sub    $0xc,%edx
f010312e:	39 fb                	cmp    %edi,%ebx
f0103130:	75 ef                	jne    f0103121 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103132:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103135:	89 07                	mov    %eax,(%edi)
	}
}
f0103137:	83 c4 14             	add    $0x14,%esp
f010313a:	5b                   	pop    %ebx
f010313b:	5e                   	pop    %esi
f010313c:	5f                   	pop    %edi
f010313d:	5d                   	pop    %ebp
f010313e:	c3                   	ret    

f010313f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010313f:	55                   	push   %ebp
f0103140:	89 e5                	mov    %esp,%ebp
f0103142:	57                   	push   %edi
f0103143:	56                   	push   %esi
f0103144:	53                   	push   %ebx
f0103145:	83 ec 2c             	sub    $0x2c,%esp
f0103148:	e8 5f fe ff ff       	call   f0102fac <__x86.get_pc_thunk.cx>
f010314d:	81 c1 bf 41 01 00    	add    $0x141bf,%ecx
f0103153:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103156:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103159:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010315c:	8d 81 b7 db fe ff    	lea    -0x12449(%ecx),%eax
f0103162:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0103164:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010316b:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f010316e:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103175:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0103178:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010317f:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103185:	0f 86 f4 00 00 00    	jbe    f010327f <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010318b:	c7 c0 e5 b7 10 f0    	mov    $0xf010b7e5,%eax
f0103191:	39 81 f8 ff ff ff    	cmp    %eax,-0x8(%ecx)
f0103197:	0f 86 88 01 00 00    	jbe    f0103325 <debuginfo_eip+0x1e6>
f010319d:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01031a0:	c7 c0 08 d6 10 f0    	mov    $0xf010d608,%eax
f01031a6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01031aa:	0f 85 7c 01 00 00    	jne    f010332c <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01031b0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01031b7:	c7 c0 dc 50 10 f0    	mov    $0xf01050dc,%eax
f01031bd:	c7 c2 e4 b7 10 f0    	mov    $0xf010b7e4,%edx
f01031c3:	29 c2                	sub    %eax,%edx
f01031c5:	c1 fa 02             	sar    $0x2,%edx
f01031c8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01031ce:	83 ea 01             	sub    $0x1,%edx
f01031d1:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01031d4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01031d7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01031da:	83 ec 08             	sub    $0x8,%esp
f01031dd:	53                   	push   %ebx
f01031de:	6a 64                	push   $0x64
f01031e0:	e8 6a fe ff ff       	call   f010304f <stab_binsearch>
	if (lfile == 0)
f01031e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031e8:	83 c4 10             	add    $0x10,%esp
f01031eb:	85 c0                	test   %eax,%eax
f01031ed:	0f 84 40 01 00 00    	je     f0103333 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01031f3:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01031f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01031fc:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01031ff:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103202:	83 ec 08             	sub    $0x8,%esp
f0103205:	53                   	push   %ebx
f0103206:	6a 24                	push   $0x24
f0103208:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010320b:	c7 c0 dc 50 10 f0    	mov    $0xf01050dc,%eax
f0103211:	e8 39 fe ff ff       	call   f010304f <stab_binsearch>

	if (lfun <= rfun) {
f0103216:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103219:	83 c4 10             	add    $0x10,%esp
f010321c:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010321f:	7f 79                	jg     f010329a <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103221:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103224:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103227:	c7 c2 dc 50 10 f0    	mov    $0xf01050dc,%edx
f010322d:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103230:	8b 11                	mov    (%ecx),%edx
f0103232:	c7 c0 08 d6 10 f0    	mov    $0xf010d608,%eax
f0103238:	81 e8 e5 b7 10 f0    	sub    $0xf010b7e5,%eax
f010323e:	39 c2                	cmp    %eax,%edx
f0103240:	73 09                	jae    f010324b <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103242:	81 c2 e5 b7 10 f0    	add    $0xf010b7e5,%edx
f0103248:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010324b:	8b 41 08             	mov    0x8(%ecx),%eax
f010324e:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103251:	83 ec 08             	sub    $0x8,%esp
f0103254:	6a 3a                	push   $0x3a
f0103256:	ff 77 08             	pushl  0x8(%edi)
f0103259:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010325c:	e8 1a 09 00 00       	call   f0103b7b <strfind>
f0103261:	2b 47 08             	sub    0x8(%edi),%eax
f0103264:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103267:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010326a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010326d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103270:	c7 c2 dc 50 10 f0    	mov    $0xf01050dc,%edx
f0103276:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f010327a:	83 c4 10             	add    $0x10,%esp
f010327d:	eb 29                	jmp    f01032a8 <debuginfo_eip+0x169>
  	        panic("User address");
f010327f:	83 ec 04             	sub    $0x4,%esp
f0103282:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103285:	8d 83 c1 db fe ff    	lea    -0x1243f(%ebx),%eax
f010328b:	50                   	push   %eax
f010328c:	6a 7f                	push   $0x7f
f010328e:	8d 83 ce db fe ff    	lea    -0x12432(%ebx),%eax
f0103294:	50                   	push   %eax
f0103295:	e8 ff cd ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f010329a:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f010329d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032a0:	eb af                	jmp    f0103251 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01032a2:	83 ee 01             	sub    $0x1,%esi
f01032a5:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f01032a8:	39 f3                	cmp    %esi,%ebx
f01032aa:	7f 3a                	jg     f01032e6 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f01032ac:	0f b6 10             	movzbl (%eax),%edx
f01032af:	80 fa 84             	cmp    $0x84,%dl
f01032b2:	74 0b                	je     f01032bf <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01032b4:	80 fa 64             	cmp    $0x64,%dl
f01032b7:	75 e9                	jne    f01032a2 <debuginfo_eip+0x163>
f01032b9:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f01032bd:	74 e3                	je     f01032a2 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01032bf:	8d 14 76             	lea    (%esi,%esi,2),%edx
f01032c2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032c5:	c7 c0 dc 50 10 f0    	mov    $0xf01050dc,%eax
f01032cb:	8b 14 90             	mov    (%eax,%edx,4),%edx
f01032ce:	c7 c0 08 d6 10 f0    	mov    $0xf010d608,%eax
f01032d4:	81 e8 e5 b7 10 f0    	sub    $0xf010b7e5,%eax
f01032da:	39 c2                	cmp    %eax,%edx
f01032dc:	73 08                	jae    f01032e6 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01032de:	81 c2 e5 b7 10 f0    	add    $0xf010b7e5,%edx
f01032e4:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01032e6:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01032e9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032ec:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01032f1:	39 cb                	cmp    %ecx,%ebx
f01032f3:	7d 4a                	jge    f010333f <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f01032f5:	8d 53 01             	lea    0x1(%ebx),%edx
f01032f8:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f01032fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032fe:	c7 c0 dc 50 10 f0    	mov    $0xf01050dc,%eax
f0103304:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0103308:	eb 07                	jmp    f0103311 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f010330a:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f010330e:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0103311:	39 d1                	cmp    %edx,%ecx
f0103313:	74 25                	je     f010333a <debuginfo_eip+0x1fb>
f0103315:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103318:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f010331c:	74 ec                	je     f010330a <debuginfo_eip+0x1cb>
	return 0;
f010331e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103323:	eb 1a                	jmp    f010333f <debuginfo_eip+0x200>
		return -1;
f0103325:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010332a:	eb 13                	jmp    f010333f <debuginfo_eip+0x200>
f010332c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103331:	eb 0c                	jmp    f010333f <debuginfo_eip+0x200>
		return -1;
f0103333:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103338:	eb 05                	jmp    f010333f <debuginfo_eip+0x200>
	return 0;
f010333a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010333f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103342:	5b                   	pop    %ebx
f0103343:	5e                   	pop    %esi
f0103344:	5f                   	pop    %edi
f0103345:	5d                   	pop    %ebp
f0103346:	c3                   	ret    

f0103347 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103347:	55                   	push   %ebp
f0103348:	89 e5                	mov    %esp,%ebp
f010334a:	57                   	push   %edi
f010334b:	56                   	push   %esi
f010334c:	53                   	push   %ebx
f010334d:	83 ec 2c             	sub    $0x2c,%esp
f0103350:	e8 57 fc ff ff       	call   f0102fac <__x86.get_pc_thunk.cx>
f0103355:	81 c1 b7 3f 01 00    	add    $0x13fb7,%ecx
f010335b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010335e:	89 c7                	mov    %eax,%edi
f0103360:	89 d6                	mov    %edx,%esi
f0103362:	8b 45 08             	mov    0x8(%ebp),%eax
f0103365:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103368:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010336b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010336e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103371:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103376:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0103379:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010337c:	39 d3                	cmp    %edx,%ebx
f010337e:	72 09                	jb     f0103389 <printnum+0x42>
f0103380:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103383:	0f 87 83 00 00 00    	ja     f010340c <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103389:	83 ec 0c             	sub    $0xc,%esp
f010338c:	ff 75 18             	pushl  0x18(%ebp)
f010338f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103392:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103395:	53                   	push   %ebx
f0103396:	ff 75 10             	pushl  0x10(%ebp)
f0103399:	83 ec 08             	sub    $0x8,%esp
f010339c:	ff 75 dc             	pushl  -0x24(%ebp)
f010339f:	ff 75 d8             	pushl  -0x28(%ebp)
f01033a2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01033a5:	ff 75 d0             	pushl  -0x30(%ebp)
f01033a8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01033ab:	e8 f0 09 00 00       	call   f0103da0 <__udivdi3>
f01033b0:	83 c4 18             	add    $0x18,%esp
f01033b3:	52                   	push   %edx
f01033b4:	50                   	push   %eax
f01033b5:	89 f2                	mov    %esi,%edx
f01033b7:	89 f8                	mov    %edi,%eax
f01033b9:	e8 89 ff ff ff       	call   f0103347 <printnum>
f01033be:	83 c4 20             	add    $0x20,%esp
f01033c1:	eb 13                	jmp    f01033d6 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01033c3:	83 ec 08             	sub    $0x8,%esp
f01033c6:	56                   	push   %esi
f01033c7:	ff 75 18             	pushl  0x18(%ebp)
f01033ca:	ff d7                	call   *%edi
f01033cc:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01033cf:	83 eb 01             	sub    $0x1,%ebx
f01033d2:	85 db                	test   %ebx,%ebx
f01033d4:	7f ed                	jg     f01033c3 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01033d6:	83 ec 08             	sub    $0x8,%esp
f01033d9:	56                   	push   %esi
f01033da:	83 ec 04             	sub    $0x4,%esp
f01033dd:	ff 75 dc             	pushl  -0x24(%ebp)
f01033e0:	ff 75 d8             	pushl  -0x28(%ebp)
f01033e3:	ff 75 d4             	pushl  -0x2c(%ebp)
f01033e6:	ff 75 d0             	pushl  -0x30(%ebp)
f01033e9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01033ec:	89 f3                	mov    %esi,%ebx
f01033ee:	e8 cd 0a 00 00       	call   f0103ec0 <__umoddi3>
f01033f3:	83 c4 14             	add    $0x14,%esp
f01033f6:	0f be 84 06 dc db fe 	movsbl -0x12424(%esi,%eax,1),%eax
f01033fd:	ff 
f01033fe:	50                   	push   %eax
f01033ff:	ff d7                	call   *%edi
}
f0103401:	83 c4 10             	add    $0x10,%esp
f0103404:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103407:	5b                   	pop    %ebx
f0103408:	5e                   	pop    %esi
f0103409:	5f                   	pop    %edi
f010340a:	5d                   	pop    %ebp
f010340b:	c3                   	ret    
f010340c:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010340f:	eb be                	jmp    f01033cf <printnum+0x88>

f0103411 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103411:	55                   	push   %ebp
f0103412:	89 e5                	mov    %esp,%ebp
f0103414:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103417:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010341b:	8b 10                	mov    (%eax),%edx
f010341d:	3b 50 04             	cmp    0x4(%eax),%edx
f0103420:	73 0a                	jae    f010342c <sprintputch+0x1b>
		*b->buf++ = ch;
f0103422:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103425:	89 08                	mov    %ecx,(%eax)
f0103427:	8b 45 08             	mov    0x8(%ebp),%eax
f010342a:	88 02                	mov    %al,(%edx)
}
f010342c:	5d                   	pop    %ebp
f010342d:	c3                   	ret    

f010342e <printfmt>:
{
f010342e:	55                   	push   %ebp
f010342f:	89 e5                	mov    %esp,%ebp
f0103431:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103434:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103437:	50                   	push   %eax
f0103438:	ff 75 10             	pushl  0x10(%ebp)
f010343b:	ff 75 0c             	pushl  0xc(%ebp)
f010343e:	ff 75 08             	pushl  0x8(%ebp)
f0103441:	e8 05 00 00 00       	call   f010344b <vprintfmt>
}
f0103446:	83 c4 10             	add    $0x10,%esp
f0103449:	c9                   	leave  
f010344a:	c3                   	ret    

f010344b <vprintfmt>:
{
f010344b:	55                   	push   %ebp
f010344c:	89 e5                	mov    %esp,%ebp
f010344e:	57                   	push   %edi
f010344f:	56                   	push   %esi
f0103450:	53                   	push   %ebx
f0103451:	83 ec 2c             	sub    $0x2c,%esp
f0103454:	e8 f6 cc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103459:	81 c3 b3 3e 01 00    	add    $0x13eb3,%ebx
f010345f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103462:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103465:	e9 8e 03 00 00       	jmp    f01037f8 <.L35+0x48>
		padc = ' ';
f010346a:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010346e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103475:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f010347c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103483:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103488:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010348b:	8d 47 01             	lea    0x1(%edi),%eax
f010348e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103491:	0f b6 17             	movzbl (%edi),%edx
f0103494:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103497:	3c 55                	cmp    $0x55,%al
f0103499:	0f 87 e1 03 00 00    	ja     f0103880 <.L22>
f010349f:	0f b6 c0             	movzbl %al,%eax
f01034a2:	89 d9                	mov    %ebx,%ecx
f01034a4:	03 8c 83 68 dc fe ff 	add    -0x12398(%ebx,%eax,4),%ecx
f01034ab:	ff e1                	jmp    *%ecx

f01034ad <.L67>:
f01034ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01034b0:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01034b4:	eb d5                	jmp    f010348b <vprintfmt+0x40>

f01034b6 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01034b6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01034b9:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01034bd:	eb cc                	jmp    f010348b <vprintfmt+0x40>

f01034bf <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01034bf:	0f b6 d2             	movzbl %dl,%edx
f01034c2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f01034c5:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f01034ca:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01034cd:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01034d1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01034d4:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01034d7:	83 f9 09             	cmp    $0x9,%ecx
f01034da:	77 55                	ja     f0103531 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01034dc:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01034df:	eb e9                	jmp    f01034ca <.L29+0xb>

f01034e1 <.L26>:
			precision = va_arg(ap, int);
f01034e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01034e4:	8b 00                	mov    (%eax),%eax
f01034e6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01034e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ec:	8d 40 04             	lea    0x4(%eax),%eax
f01034ef:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01034f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01034f5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01034f9:	79 90                	jns    f010348b <vprintfmt+0x40>
				width = precision, precision = -1;
f01034fb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01034fe:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103501:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103508:	eb 81                	jmp    f010348b <vprintfmt+0x40>

f010350a <.L27>:
f010350a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010350d:	85 c0                	test   %eax,%eax
f010350f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103514:	0f 49 d0             	cmovns %eax,%edx
f0103517:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010351a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010351d:	e9 69 ff ff ff       	jmp    f010348b <vprintfmt+0x40>

f0103522 <.L23>:
f0103522:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0103525:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010352c:	e9 5a ff ff ff       	jmp    f010348b <vprintfmt+0x40>
f0103531:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103534:	eb bf                	jmp    f01034f5 <.L26+0x14>

f0103536 <.L33>:
			lflag++;
f0103536:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010353a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010353d:	e9 49 ff ff ff       	jmp    f010348b <vprintfmt+0x40>

f0103542 <.L30>:
			putch(va_arg(ap, int), putdat);
f0103542:	8b 45 14             	mov    0x14(%ebp),%eax
f0103545:	8d 78 04             	lea    0x4(%eax),%edi
f0103548:	83 ec 08             	sub    $0x8,%esp
f010354b:	56                   	push   %esi
f010354c:	ff 30                	pushl  (%eax)
f010354e:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103551:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103554:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0103557:	e9 99 02 00 00       	jmp    f01037f5 <.L35+0x45>

f010355c <.L32>:
			err = va_arg(ap, int);
f010355c:	8b 45 14             	mov    0x14(%ebp),%eax
f010355f:	8d 78 04             	lea    0x4(%eax),%edi
f0103562:	8b 00                	mov    (%eax),%eax
f0103564:	99                   	cltd   
f0103565:	31 d0                	xor    %edx,%eax
f0103567:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103569:	83 f8 06             	cmp    $0x6,%eax
f010356c:	7f 27                	jg     f0103595 <.L32+0x39>
f010356e:	8b 94 83 1c 1d 00 00 	mov    0x1d1c(%ebx,%eax,4),%edx
f0103575:	85 d2                	test   %edx,%edx
f0103577:	74 1c                	je     f0103595 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0103579:	52                   	push   %edx
f010357a:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0103580:	50                   	push   %eax
f0103581:	56                   	push   %esi
f0103582:	ff 75 08             	pushl  0x8(%ebp)
f0103585:	e8 a4 fe ff ff       	call   f010342e <printfmt>
f010358a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010358d:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103590:	e9 60 02 00 00       	jmp    f01037f5 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103595:	50                   	push   %eax
f0103596:	8d 83 f4 db fe ff    	lea    -0x1240c(%ebx),%eax
f010359c:	50                   	push   %eax
f010359d:	56                   	push   %esi
f010359e:	ff 75 08             	pushl  0x8(%ebp)
f01035a1:	e8 88 fe ff ff       	call   f010342e <printfmt>
f01035a6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01035a9:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01035ac:	e9 44 02 00 00       	jmp    f01037f5 <.L35+0x45>

f01035b1 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01035b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01035b4:	83 c0 04             	add    $0x4,%eax
f01035b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01035ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01035bd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01035bf:	85 ff                	test   %edi,%edi
f01035c1:	8d 83 ed db fe ff    	lea    -0x12413(%ebx),%eax
f01035c7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01035ca:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01035ce:	0f 8e b5 00 00 00    	jle    f0103689 <.L36+0xd8>
f01035d4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01035d8:	75 08                	jne    f01035e2 <.L36+0x31>
f01035da:	89 75 0c             	mov    %esi,0xc(%ebp)
f01035dd:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01035e0:	eb 6d                	jmp    f010364f <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01035e2:	83 ec 08             	sub    $0x8,%esp
f01035e5:	ff 75 d0             	pushl  -0x30(%ebp)
f01035e8:	57                   	push   %edi
f01035e9:	e8 49 04 00 00       	call   f0103a37 <strnlen>
f01035ee:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01035f1:	29 c2                	sub    %eax,%edx
f01035f3:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01035f6:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01035f9:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01035fd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103600:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103603:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103605:	eb 10                	jmp    f0103617 <.L36+0x66>
					putch(padc, putdat);
f0103607:	83 ec 08             	sub    $0x8,%esp
f010360a:	56                   	push   %esi
f010360b:	ff 75 e0             	pushl  -0x20(%ebp)
f010360e:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103611:	83 ef 01             	sub    $0x1,%edi
f0103614:	83 c4 10             	add    $0x10,%esp
f0103617:	85 ff                	test   %edi,%edi
f0103619:	7f ec                	jg     f0103607 <.L36+0x56>
f010361b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010361e:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0103621:	85 d2                	test   %edx,%edx
f0103623:	b8 00 00 00 00       	mov    $0x0,%eax
f0103628:	0f 49 c2             	cmovns %edx,%eax
f010362b:	29 c2                	sub    %eax,%edx
f010362d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103630:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103633:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103636:	eb 17                	jmp    f010364f <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0103638:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010363c:	75 30                	jne    f010366e <.L36+0xbd>
					putch(ch, putdat);
f010363e:	83 ec 08             	sub    $0x8,%esp
f0103641:	ff 75 0c             	pushl  0xc(%ebp)
f0103644:	50                   	push   %eax
f0103645:	ff 55 08             	call   *0x8(%ebp)
f0103648:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010364b:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010364f:	83 c7 01             	add    $0x1,%edi
f0103652:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103656:	0f be c2             	movsbl %dl,%eax
f0103659:	85 c0                	test   %eax,%eax
f010365b:	74 52                	je     f01036af <.L36+0xfe>
f010365d:	85 f6                	test   %esi,%esi
f010365f:	78 d7                	js     f0103638 <.L36+0x87>
f0103661:	83 ee 01             	sub    $0x1,%esi
f0103664:	79 d2                	jns    f0103638 <.L36+0x87>
f0103666:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103669:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010366c:	eb 32                	jmp    f01036a0 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010366e:	0f be d2             	movsbl %dl,%edx
f0103671:	83 ea 20             	sub    $0x20,%edx
f0103674:	83 fa 5e             	cmp    $0x5e,%edx
f0103677:	76 c5                	jbe    f010363e <.L36+0x8d>
					putch('?', putdat);
f0103679:	83 ec 08             	sub    $0x8,%esp
f010367c:	ff 75 0c             	pushl  0xc(%ebp)
f010367f:	6a 3f                	push   $0x3f
f0103681:	ff 55 08             	call   *0x8(%ebp)
f0103684:	83 c4 10             	add    $0x10,%esp
f0103687:	eb c2                	jmp    f010364b <.L36+0x9a>
f0103689:	89 75 0c             	mov    %esi,0xc(%ebp)
f010368c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010368f:	eb be                	jmp    f010364f <.L36+0x9e>
				putch(' ', putdat);
f0103691:	83 ec 08             	sub    $0x8,%esp
f0103694:	56                   	push   %esi
f0103695:	6a 20                	push   $0x20
f0103697:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010369a:	83 ef 01             	sub    $0x1,%edi
f010369d:	83 c4 10             	add    $0x10,%esp
f01036a0:	85 ff                	test   %edi,%edi
f01036a2:	7f ed                	jg     f0103691 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01036a4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01036a7:	89 45 14             	mov    %eax,0x14(%ebp)
f01036aa:	e9 46 01 00 00       	jmp    f01037f5 <.L35+0x45>
f01036af:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01036b2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01036b5:	eb e9                	jmp    f01036a0 <.L36+0xef>

f01036b7 <.L31>:
f01036b7:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f01036ba:	83 f9 01             	cmp    $0x1,%ecx
f01036bd:	7e 40                	jle    f01036ff <.L31+0x48>
		return va_arg(*ap, long long);
f01036bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01036c2:	8b 50 04             	mov    0x4(%eax),%edx
f01036c5:	8b 00                	mov    (%eax),%eax
f01036c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01036ca:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01036cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01036d0:	8d 40 08             	lea    0x8(%eax),%eax
f01036d3:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01036d6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01036da:	79 55                	jns    f0103731 <.L31+0x7a>
				putch('-', putdat);
f01036dc:	83 ec 08             	sub    $0x8,%esp
f01036df:	56                   	push   %esi
f01036e0:	6a 2d                	push   $0x2d
f01036e2:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01036e5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01036e8:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01036eb:	f7 da                	neg    %edx
f01036ed:	83 d1 00             	adc    $0x0,%ecx
f01036f0:	f7 d9                	neg    %ecx
f01036f2:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01036f5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01036fa:	e9 db 00 00 00       	jmp    f01037da <.L35+0x2a>
	else if (lflag)
f01036ff:	85 c9                	test   %ecx,%ecx
f0103701:	75 17                	jne    f010371a <.L31+0x63>
		return va_arg(*ap, int);
f0103703:	8b 45 14             	mov    0x14(%ebp),%eax
f0103706:	8b 00                	mov    (%eax),%eax
f0103708:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010370b:	99                   	cltd   
f010370c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010370f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103712:	8d 40 04             	lea    0x4(%eax),%eax
f0103715:	89 45 14             	mov    %eax,0x14(%ebp)
f0103718:	eb bc                	jmp    f01036d6 <.L31+0x1f>
		return va_arg(*ap, long);
f010371a:	8b 45 14             	mov    0x14(%ebp),%eax
f010371d:	8b 00                	mov    (%eax),%eax
f010371f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103722:	99                   	cltd   
f0103723:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103726:	8b 45 14             	mov    0x14(%ebp),%eax
f0103729:	8d 40 04             	lea    0x4(%eax),%eax
f010372c:	89 45 14             	mov    %eax,0x14(%ebp)
f010372f:	eb a5                	jmp    f01036d6 <.L31+0x1f>
			num = getint(&ap, lflag);
f0103731:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103734:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0103737:	b8 0a 00 00 00       	mov    $0xa,%eax
f010373c:	e9 99 00 00 00       	jmp    f01037da <.L35+0x2a>

f0103741 <.L37>:
f0103741:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103744:	83 f9 01             	cmp    $0x1,%ecx
f0103747:	7e 15                	jle    f010375e <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0103749:	8b 45 14             	mov    0x14(%ebp),%eax
f010374c:	8b 10                	mov    (%eax),%edx
f010374e:	8b 48 04             	mov    0x4(%eax),%ecx
f0103751:	8d 40 08             	lea    0x8(%eax),%eax
f0103754:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103757:	b8 0a 00 00 00       	mov    $0xa,%eax
f010375c:	eb 7c                	jmp    f01037da <.L35+0x2a>
	else if (lflag)
f010375e:	85 c9                	test   %ecx,%ecx
f0103760:	75 17                	jne    f0103779 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0103762:	8b 45 14             	mov    0x14(%ebp),%eax
f0103765:	8b 10                	mov    (%eax),%edx
f0103767:	b9 00 00 00 00       	mov    $0x0,%ecx
f010376c:	8d 40 04             	lea    0x4(%eax),%eax
f010376f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103772:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103777:	eb 61                	jmp    f01037da <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103779:	8b 45 14             	mov    0x14(%ebp),%eax
f010377c:	8b 10                	mov    (%eax),%edx
f010377e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103783:	8d 40 04             	lea    0x4(%eax),%eax
f0103786:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103789:	b8 0a 00 00 00       	mov    $0xa,%eax
f010378e:	eb 4a                	jmp    f01037da <.L35+0x2a>

f0103790 <.L34>:
			putch('X', putdat);
f0103790:	83 ec 08             	sub    $0x8,%esp
f0103793:	56                   	push   %esi
f0103794:	6a 58                	push   $0x58
f0103796:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0103799:	83 c4 08             	add    $0x8,%esp
f010379c:	56                   	push   %esi
f010379d:	6a 58                	push   $0x58
f010379f:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f01037a2:	83 c4 08             	add    $0x8,%esp
f01037a5:	56                   	push   %esi
f01037a6:	6a 58                	push   $0x58
f01037a8:	ff 55 08             	call   *0x8(%ebp)
			break;
f01037ab:	83 c4 10             	add    $0x10,%esp
f01037ae:	eb 45                	jmp    f01037f5 <.L35+0x45>

f01037b0 <.L35>:
			putch('0', putdat);
f01037b0:	83 ec 08             	sub    $0x8,%esp
f01037b3:	56                   	push   %esi
f01037b4:	6a 30                	push   $0x30
f01037b6:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01037b9:	83 c4 08             	add    $0x8,%esp
f01037bc:	56                   	push   %esi
f01037bd:	6a 78                	push   $0x78
f01037bf:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01037c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01037c5:	8b 10                	mov    (%eax),%edx
f01037c7:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f01037cc:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01037cf:	8d 40 04             	lea    0x4(%eax),%eax
f01037d2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01037d5:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f01037da:	83 ec 0c             	sub    $0xc,%esp
f01037dd:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01037e1:	57                   	push   %edi
f01037e2:	ff 75 e0             	pushl  -0x20(%ebp)
f01037e5:	50                   	push   %eax
f01037e6:	51                   	push   %ecx
f01037e7:	52                   	push   %edx
f01037e8:	89 f2                	mov    %esi,%edx
f01037ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ed:	e8 55 fb ff ff       	call   f0103347 <printnum>
			break;
f01037f2:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01037f5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01037f8:	83 c7 01             	add    $0x1,%edi
f01037fb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01037ff:	83 f8 25             	cmp    $0x25,%eax
f0103802:	0f 84 62 fc ff ff    	je     f010346a <vprintfmt+0x1f>
			if (ch == '\0')
f0103808:	85 c0                	test   %eax,%eax
f010380a:	0f 84 91 00 00 00    	je     f01038a1 <.L22+0x21>
			putch(ch, putdat);
f0103810:	83 ec 08             	sub    $0x8,%esp
f0103813:	56                   	push   %esi
f0103814:	50                   	push   %eax
f0103815:	ff 55 08             	call   *0x8(%ebp)
f0103818:	83 c4 10             	add    $0x10,%esp
f010381b:	eb db                	jmp    f01037f8 <.L35+0x48>

f010381d <.L38>:
f010381d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0103820:	83 f9 01             	cmp    $0x1,%ecx
f0103823:	7e 15                	jle    f010383a <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103825:	8b 45 14             	mov    0x14(%ebp),%eax
f0103828:	8b 10                	mov    (%eax),%edx
f010382a:	8b 48 04             	mov    0x4(%eax),%ecx
f010382d:	8d 40 08             	lea    0x8(%eax),%eax
f0103830:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103833:	b8 10 00 00 00       	mov    $0x10,%eax
f0103838:	eb a0                	jmp    f01037da <.L35+0x2a>
	else if (lflag)
f010383a:	85 c9                	test   %ecx,%ecx
f010383c:	75 17                	jne    f0103855 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f010383e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103841:	8b 10                	mov    (%eax),%edx
f0103843:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103848:	8d 40 04             	lea    0x4(%eax),%eax
f010384b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010384e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103853:	eb 85                	jmp    f01037da <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103855:	8b 45 14             	mov    0x14(%ebp),%eax
f0103858:	8b 10                	mov    (%eax),%edx
f010385a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010385f:	8d 40 04             	lea    0x4(%eax),%eax
f0103862:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103865:	b8 10 00 00 00       	mov    $0x10,%eax
f010386a:	e9 6b ff ff ff       	jmp    f01037da <.L35+0x2a>

f010386f <.L25>:
			putch(ch, putdat);
f010386f:	83 ec 08             	sub    $0x8,%esp
f0103872:	56                   	push   %esi
f0103873:	6a 25                	push   $0x25
f0103875:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103878:	83 c4 10             	add    $0x10,%esp
f010387b:	e9 75 ff ff ff       	jmp    f01037f5 <.L35+0x45>

f0103880 <.L22>:
			putch('%', putdat);
f0103880:	83 ec 08             	sub    $0x8,%esp
f0103883:	56                   	push   %esi
f0103884:	6a 25                	push   $0x25
f0103886:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103889:	83 c4 10             	add    $0x10,%esp
f010388c:	89 f8                	mov    %edi,%eax
f010388e:	eb 03                	jmp    f0103893 <.L22+0x13>
f0103890:	83 e8 01             	sub    $0x1,%eax
f0103893:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103897:	75 f7                	jne    f0103890 <.L22+0x10>
f0103899:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010389c:	e9 54 ff ff ff       	jmp    f01037f5 <.L35+0x45>
}
f01038a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038a4:	5b                   	pop    %ebx
f01038a5:	5e                   	pop    %esi
f01038a6:	5f                   	pop    %edi
f01038a7:	5d                   	pop    %ebp
f01038a8:	c3                   	ret    

f01038a9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038a9:	55                   	push   %ebp
f01038aa:	89 e5                	mov    %esp,%ebp
f01038ac:	53                   	push   %ebx
f01038ad:	83 ec 14             	sub    $0x14,%esp
f01038b0:	e8 9a c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01038b5:	81 c3 57 3a 01 00    	add    $0x13a57,%ebx
f01038bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01038be:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038c4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038c8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038cb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038d2:	85 c0                	test   %eax,%eax
f01038d4:	74 2b                	je     f0103901 <vsnprintf+0x58>
f01038d6:	85 d2                	test   %edx,%edx
f01038d8:	7e 27                	jle    f0103901 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038da:	ff 75 14             	pushl  0x14(%ebp)
f01038dd:	ff 75 10             	pushl  0x10(%ebp)
f01038e0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038e3:	50                   	push   %eax
f01038e4:	8d 83 05 c1 fe ff    	lea    -0x13efb(%ebx),%eax
f01038ea:	50                   	push   %eax
f01038eb:	e8 5b fb ff ff       	call   f010344b <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01038f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01038f3:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01038f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01038f9:	83 c4 10             	add    $0x10,%esp
}
f01038fc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01038ff:	c9                   	leave  
f0103900:	c3                   	ret    
		return -E_INVAL;
f0103901:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103906:	eb f4                	jmp    f01038fc <vsnprintf+0x53>

f0103908 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103908:	55                   	push   %ebp
f0103909:	89 e5                	mov    %esp,%ebp
f010390b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010390e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103911:	50                   	push   %eax
f0103912:	ff 75 10             	pushl  0x10(%ebp)
f0103915:	ff 75 0c             	pushl  0xc(%ebp)
f0103918:	ff 75 08             	pushl  0x8(%ebp)
f010391b:	e8 89 ff ff ff       	call   f01038a9 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103920:	c9                   	leave  
f0103921:	c3                   	ret    

f0103922 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103922:	55                   	push   %ebp
f0103923:	89 e5                	mov    %esp,%ebp
f0103925:	57                   	push   %edi
f0103926:	56                   	push   %esi
f0103927:	53                   	push   %ebx
f0103928:	83 ec 1c             	sub    $0x1c,%esp
f010392b:	e8 1f c8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103930:	81 c3 dc 39 01 00    	add    $0x139dc,%ebx
f0103936:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103939:	85 c0                	test   %eax,%eax
f010393b:	74 13                	je     f0103950 <readline+0x2e>
		cprintf("%s", prompt);
f010393d:	83 ec 08             	sub    $0x8,%esp
f0103940:	50                   	push   %eax
f0103941:	8d 83 e8 d8 fe ff    	lea    -0x12718(%ebx),%eax
f0103947:	50                   	push   %eax
f0103948:	e8 ee f6 ff ff       	call   f010303b <cprintf>
f010394d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103950:	83 ec 0c             	sub    $0xc,%esp
f0103953:	6a 00                	push   $0x0
f0103955:	e8 8d cd ff ff       	call   f01006e7 <iscons>
f010395a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010395d:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103960:	bf 00 00 00 00       	mov    $0x0,%edi
f0103965:	eb 46                	jmp    f01039ad <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103967:	83 ec 08             	sub    $0x8,%esp
f010396a:	50                   	push   %eax
f010396b:	8d 83 c0 dd fe ff    	lea    -0x12240(%ebx),%eax
f0103971:	50                   	push   %eax
f0103972:	e8 c4 f6 ff ff       	call   f010303b <cprintf>
			return NULL;
f0103977:	83 c4 10             	add    $0x10,%esp
f010397a:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010397f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103982:	5b                   	pop    %ebx
f0103983:	5e                   	pop    %esi
f0103984:	5f                   	pop    %edi
f0103985:	5d                   	pop    %ebp
f0103986:	c3                   	ret    
			if (echoing)
f0103987:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010398b:	75 05                	jne    f0103992 <readline+0x70>
			i--;
f010398d:	83 ef 01             	sub    $0x1,%edi
f0103990:	eb 1b                	jmp    f01039ad <readline+0x8b>
				cputchar('\b');
f0103992:	83 ec 0c             	sub    $0xc,%esp
f0103995:	6a 08                	push   $0x8
f0103997:	e8 2a cd ff ff       	call   f01006c6 <cputchar>
f010399c:	83 c4 10             	add    $0x10,%esp
f010399f:	eb ec                	jmp    f010398d <readline+0x6b>
			buf[i++] = c;
f01039a1:	89 f0                	mov    %esi,%eax
f01039a3:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f01039aa:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01039ad:	e8 24 cd ff ff       	call   f01006d6 <getchar>
f01039b2:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01039b4:	85 c0                	test   %eax,%eax
f01039b6:	78 af                	js     f0103967 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039b8:	83 f8 08             	cmp    $0x8,%eax
f01039bb:	0f 94 c2             	sete   %dl
f01039be:	83 f8 7f             	cmp    $0x7f,%eax
f01039c1:	0f 94 c0             	sete   %al
f01039c4:	08 c2                	or     %al,%dl
f01039c6:	74 04                	je     f01039cc <readline+0xaa>
f01039c8:	85 ff                	test   %edi,%edi
f01039ca:	7f bb                	jg     f0103987 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039cc:	83 fe 1f             	cmp    $0x1f,%esi
f01039cf:	7e 1c                	jle    f01039ed <readline+0xcb>
f01039d1:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01039d7:	7f 14                	jg     f01039ed <readline+0xcb>
			if (echoing)
f01039d9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039dd:	74 c2                	je     f01039a1 <readline+0x7f>
				cputchar(c);
f01039df:	83 ec 0c             	sub    $0xc,%esp
f01039e2:	56                   	push   %esi
f01039e3:	e8 de cc ff ff       	call   f01006c6 <cputchar>
f01039e8:	83 c4 10             	add    $0x10,%esp
f01039eb:	eb b4                	jmp    f01039a1 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01039ed:	83 fe 0a             	cmp    $0xa,%esi
f01039f0:	74 05                	je     f01039f7 <readline+0xd5>
f01039f2:	83 fe 0d             	cmp    $0xd,%esi
f01039f5:	75 b6                	jne    f01039ad <readline+0x8b>
			if (echoing)
f01039f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039fb:	75 13                	jne    f0103a10 <readline+0xee>
			buf[i] = 0;
f01039fd:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103a04:	00 
			return buf;
f0103a05:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103a0b:	e9 6f ff ff ff       	jmp    f010397f <readline+0x5d>
				cputchar('\n');
f0103a10:	83 ec 0c             	sub    $0xc,%esp
f0103a13:	6a 0a                	push   $0xa
f0103a15:	e8 ac cc ff ff       	call   f01006c6 <cputchar>
f0103a1a:	83 c4 10             	add    $0x10,%esp
f0103a1d:	eb de                	jmp    f01039fd <readline+0xdb>

f0103a1f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a1f:	55                   	push   %ebp
f0103a20:	89 e5                	mov    %esp,%ebp
f0103a22:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a25:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a2a:	eb 03                	jmp    f0103a2f <strlen+0x10>
		n++;
f0103a2c:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103a2f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a33:	75 f7                	jne    f0103a2c <strlen+0xd>
	return n;
}
f0103a35:	5d                   	pop    %ebp
f0103a36:	c3                   	ret    

f0103a37 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a37:	55                   	push   %ebp
f0103a38:	89 e5                	mov    %esp,%ebp
f0103a3a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a3d:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a40:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a45:	eb 03                	jmp    f0103a4a <strnlen+0x13>
		n++;
f0103a47:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a4a:	39 d0                	cmp    %edx,%eax
f0103a4c:	74 06                	je     f0103a54 <strnlen+0x1d>
f0103a4e:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103a52:	75 f3                	jne    f0103a47 <strnlen+0x10>
	return n;
}
f0103a54:	5d                   	pop    %ebp
f0103a55:	c3                   	ret    

f0103a56 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a56:	55                   	push   %ebp
f0103a57:	89 e5                	mov    %esp,%ebp
f0103a59:	53                   	push   %ebx
f0103a5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a5d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a60:	89 c2                	mov    %eax,%edx
f0103a62:	83 c1 01             	add    $0x1,%ecx
f0103a65:	83 c2 01             	add    $0x1,%edx
f0103a68:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103a6c:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103a6f:	84 db                	test   %bl,%bl
f0103a71:	75 ef                	jne    f0103a62 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a73:	5b                   	pop    %ebx
f0103a74:	5d                   	pop    %ebp
f0103a75:	c3                   	ret    

f0103a76 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a76:	55                   	push   %ebp
f0103a77:	89 e5                	mov    %esp,%ebp
f0103a79:	53                   	push   %ebx
f0103a7a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a7d:	53                   	push   %ebx
f0103a7e:	e8 9c ff ff ff       	call   f0103a1f <strlen>
f0103a83:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103a86:	ff 75 0c             	pushl  0xc(%ebp)
f0103a89:	01 d8                	add    %ebx,%eax
f0103a8b:	50                   	push   %eax
f0103a8c:	e8 c5 ff ff ff       	call   f0103a56 <strcpy>
	return dst;
}
f0103a91:	89 d8                	mov    %ebx,%eax
f0103a93:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a96:	c9                   	leave  
f0103a97:	c3                   	ret    

f0103a98 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a98:	55                   	push   %ebp
f0103a99:	89 e5                	mov    %esp,%ebp
f0103a9b:	56                   	push   %esi
f0103a9c:	53                   	push   %ebx
f0103a9d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103aa0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103aa3:	89 f3                	mov    %esi,%ebx
f0103aa5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103aa8:	89 f2                	mov    %esi,%edx
f0103aaa:	eb 0f                	jmp    f0103abb <strncpy+0x23>
		*dst++ = *src;
f0103aac:	83 c2 01             	add    $0x1,%edx
f0103aaf:	0f b6 01             	movzbl (%ecx),%eax
f0103ab2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103ab5:	80 39 01             	cmpb   $0x1,(%ecx)
f0103ab8:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103abb:	39 da                	cmp    %ebx,%edx
f0103abd:	75 ed                	jne    f0103aac <strncpy+0x14>
	}
	return ret;
}
f0103abf:	89 f0                	mov    %esi,%eax
f0103ac1:	5b                   	pop    %ebx
f0103ac2:	5e                   	pop    %esi
f0103ac3:	5d                   	pop    %ebp
f0103ac4:	c3                   	ret    

f0103ac5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103ac5:	55                   	push   %ebp
f0103ac6:	89 e5                	mov    %esp,%ebp
f0103ac8:	56                   	push   %esi
f0103ac9:	53                   	push   %ebx
f0103aca:	8b 75 08             	mov    0x8(%ebp),%esi
f0103acd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ad0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103ad3:	89 f0                	mov    %esi,%eax
f0103ad5:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103ad9:	85 c9                	test   %ecx,%ecx
f0103adb:	75 0b                	jne    f0103ae8 <strlcpy+0x23>
f0103add:	eb 17                	jmp    f0103af6 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103adf:	83 c2 01             	add    $0x1,%edx
f0103ae2:	83 c0 01             	add    $0x1,%eax
f0103ae5:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103ae8:	39 d8                	cmp    %ebx,%eax
f0103aea:	74 07                	je     f0103af3 <strlcpy+0x2e>
f0103aec:	0f b6 0a             	movzbl (%edx),%ecx
f0103aef:	84 c9                	test   %cl,%cl
f0103af1:	75 ec                	jne    f0103adf <strlcpy+0x1a>
		*dst = '\0';
f0103af3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103af6:	29 f0                	sub    %esi,%eax
}
f0103af8:	5b                   	pop    %ebx
f0103af9:	5e                   	pop    %esi
f0103afa:	5d                   	pop    %ebp
f0103afb:	c3                   	ret    

f0103afc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103afc:	55                   	push   %ebp
f0103afd:	89 e5                	mov    %esp,%ebp
f0103aff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b02:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b05:	eb 06                	jmp    f0103b0d <strcmp+0x11>
		p++, q++;
f0103b07:	83 c1 01             	add    $0x1,%ecx
f0103b0a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103b0d:	0f b6 01             	movzbl (%ecx),%eax
f0103b10:	84 c0                	test   %al,%al
f0103b12:	74 04                	je     f0103b18 <strcmp+0x1c>
f0103b14:	3a 02                	cmp    (%edx),%al
f0103b16:	74 ef                	je     f0103b07 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b18:	0f b6 c0             	movzbl %al,%eax
f0103b1b:	0f b6 12             	movzbl (%edx),%edx
f0103b1e:	29 d0                	sub    %edx,%eax
}
f0103b20:	5d                   	pop    %ebp
f0103b21:	c3                   	ret    

f0103b22 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b22:	55                   	push   %ebp
f0103b23:	89 e5                	mov    %esp,%ebp
f0103b25:	53                   	push   %ebx
f0103b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b29:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b2c:	89 c3                	mov    %eax,%ebx
f0103b2e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103b31:	eb 06                	jmp    f0103b39 <strncmp+0x17>
		n--, p++, q++;
f0103b33:	83 c0 01             	add    $0x1,%eax
f0103b36:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103b39:	39 d8                	cmp    %ebx,%eax
f0103b3b:	74 16                	je     f0103b53 <strncmp+0x31>
f0103b3d:	0f b6 08             	movzbl (%eax),%ecx
f0103b40:	84 c9                	test   %cl,%cl
f0103b42:	74 04                	je     f0103b48 <strncmp+0x26>
f0103b44:	3a 0a                	cmp    (%edx),%cl
f0103b46:	74 eb                	je     f0103b33 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b48:	0f b6 00             	movzbl (%eax),%eax
f0103b4b:	0f b6 12             	movzbl (%edx),%edx
f0103b4e:	29 d0                	sub    %edx,%eax
}
f0103b50:	5b                   	pop    %ebx
f0103b51:	5d                   	pop    %ebp
f0103b52:	c3                   	ret    
		return 0;
f0103b53:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b58:	eb f6                	jmp    f0103b50 <strncmp+0x2e>

f0103b5a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b5a:	55                   	push   %ebp
f0103b5b:	89 e5                	mov    %esp,%ebp
f0103b5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b60:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b64:	0f b6 10             	movzbl (%eax),%edx
f0103b67:	84 d2                	test   %dl,%dl
f0103b69:	74 09                	je     f0103b74 <strchr+0x1a>
		if (*s == c)
f0103b6b:	38 ca                	cmp    %cl,%dl
f0103b6d:	74 0a                	je     f0103b79 <strchr+0x1f>
	for (; *s; s++)
f0103b6f:	83 c0 01             	add    $0x1,%eax
f0103b72:	eb f0                	jmp    f0103b64 <strchr+0xa>
			return (char *) s;
	return 0;
f0103b74:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b79:	5d                   	pop    %ebp
f0103b7a:	c3                   	ret    

f0103b7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b7b:	55                   	push   %ebp
f0103b7c:	89 e5                	mov    %esp,%ebp
f0103b7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b81:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b85:	eb 03                	jmp    f0103b8a <strfind+0xf>
f0103b87:	83 c0 01             	add    $0x1,%eax
f0103b8a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103b8d:	38 ca                	cmp    %cl,%dl
f0103b8f:	74 04                	je     f0103b95 <strfind+0x1a>
f0103b91:	84 d2                	test   %dl,%dl
f0103b93:	75 f2                	jne    f0103b87 <strfind+0xc>
			break;
	return (char *) s;
}
f0103b95:	5d                   	pop    %ebp
f0103b96:	c3                   	ret    

f0103b97 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b97:	55                   	push   %ebp
f0103b98:	89 e5                	mov    %esp,%ebp
f0103b9a:	57                   	push   %edi
f0103b9b:	56                   	push   %esi
f0103b9c:	53                   	push   %ebx
f0103b9d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ba0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103ba3:	85 c9                	test   %ecx,%ecx
f0103ba5:	74 13                	je     f0103bba <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103ba7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bad:	75 05                	jne    f0103bb4 <memset+0x1d>
f0103baf:	f6 c1 03             	test   $0x3,%cl
f0103bb2:	74 0d                	je     f0103bc1 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bb4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bb7:	fc                   	cld    
f0103bb8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bba:	89 f8                	mov    %edi,%eax
f0103bbc:	5b                   	pop    %ebx
f0103bbd:	5e                   	pop    %esi
f0103bbe:	5f                   	pop    %edi
f0103bbf:	5d                   	pop    %ebp
f0103bc0:	c3                   	ret    
		c &= 0xFF;
f0103bc1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bc5:	89 d3                	mov    %edx,%ebx
f0103bc7:	c1 e3 08             	shl    $0x8,%ebx
f0103bca:	89 d0                	mov    %edx,%eax
f0103bcc:	c1 e0 18             	shl    $0x18,%eax
f0103bcf:	89 d6                	mov    %edx,%esi
f0103bd1:	c1 e6 10             	shl    $0x10,%esi
f0103bd4:	09 f0                	or     %esi,%eax
f0103bd6:	09 c2                	or     %eax,%edx
f0103bd8:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103bda:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103bdd:	89 d0                	mov    %edx,%eax
f0103bdf:	fc                   	cld    
f0103be0:	f3 ab                	rep stos %eax,%es:(%edi)
f0103be2:	eb d6                	jmp    f0103bba <memset+0x23>

f0103be4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103be4:	55                   	push   %ebp
f0103be5:	89 e5                	mov    %esp,%ebp
f0103be7:	57                   	push   %edi
f0103be8:	56                   	push   %esi
f0103be9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bec:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103bef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103bf2:	39 c6                	cmp    %eax,%esi
f0103bf4:	73 35                	jae    f0103c2b <memmove+0x47>
f0103bf6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103bf9:	39 c2                	cmp    %eax,%edx
f0103bfb:	76 2e                	jbe    f0103c2b <memmove+0x47>
		s += n;
		d += n;
f0103bfd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c00:	89 d6                	mov    %edx,%esi
f0103c02:	09 fe                	or     %edi,%esi
f0103c04:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c0a:	74 0c                	je     f0103c18 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c0c:	83 ef 01             	sub    $0x1,%edi
f0103c0f:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103c12:	fd                   	std    
f0103c13:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c15:	fc                   	cld    
f0103c16:	eb 21                	jmp    f0103c39 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c18:	f6 c1 03             	test   $0x3,%cl
f0103c1b:	75 ef                	jne    f0103c0c <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c1d:	83 ef 04             	sub    $0x4,%edi
f0103c20:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c23:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103c26:	fd                   	std    
f0103c27:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c29:	eb ea                	jmp    f0103c15 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c2b:	89 f2                	mov    %esi,%edx
f0103c2d:	09 c2                	or     %eax,%edx
f0103c2f:	f6 c2 03             	test   $0x3,%dl
f0103c32:	74 09                	je     f0103c3d <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c34:	89 c7                	mov    %eax,%edi
f0103c36:	fc                   	cld    
f0103c37:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c39:	5e                   	pop    %esi
f0103c3a:	5f                   	pop    %edi
f0103c3b:	5d                   	pop    %ebp
f0103c3c:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c3d:	f6 c1 03             	test   $0x3,%cl
f0103c40:	75 f2                	jne    f0103c34 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c42:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103c45:	89 c7                	mov    %eax,%edi
f0103c47:	fc                   	cld    
f0103c48:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c4a:	eb ed                	jmp    f0103c39 <memmove+0x55>

f0103c4c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c4c:	55                   	push   %ebp
f0103c4d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103c4f:	ff 75 10             	pushl  0x10(%ebp)
f0103c52:	ff 75 0c             	pushl  0xc(%ebp)
f0103c55:	ff 75 08             	pushl  0x8(%ebp)
f0103c58:	e8 87 ff ff ff       	call   f0103be4 <memmove>
}
f0103c5d:	c9                   	leave  
f0103c5e:	c3                   	ret    

f0103c5f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c5f:	55                   	push   %ebp
f0103c60:	89 e5                	mov    %esp,%ebp
f0103c62:	56                   	push   %esi
f0103c63:	53                   	push   %ebx
f0103c64:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c67:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c6a:	89 c6                	mov    %eax,%esi
f0103c6c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c6f:	39 f0                	cmp    %esi,%eax
f0103c71:	74 1c                	je     f0103c8f <memcmp+0x30>
		if (*s1 != *s2)
f0103c73:	0f b6 08             	movzbl (%eax),%ecx
f0103c76:	0f b6 1a             	movzbl (%edx),%ebx
f0103c79:	38 d9                	cmp    %bl,%cl
f0103c7b:	75 08                	jne    f0103c85 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103c7d:	83 c0 01             	add    $0x1,%eax
f0103c80:	83 c2 01             	add    $0x1,%edx
f0103c83:	eb ea                	jmp    f0103c6f <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103c85:	0f b6 c1             	movzbl %cl,%eax
f0103c88:	0f b6 db             	movzbl %bl,%ebx
f0103c8b:	29 d8                	sub    %ebx,%eax
f0103c8d:	eb 05                	jmp    f0103c94 <memcmp+0x35>
	}

	return 0;
f0103c8f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c94:	5b                   	pop    %ebx
f0103c95:	5e                   	pop    %esi
f0103c96:	5d                   	pop    %ebp
f0103c97:	c3                   	ret    

f0103c98 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c98:	55                   	push   %ebp
f0103c99:	89 e5                	mov    %esp,%ebp
f0103c9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103ca1:	89 c2                	mov    %eax,%edx
f0103ca3:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103ca6:	39 d0                	cmp    %edx,%eax
f0103ca8:	73 09                	jae    f0103cb3 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103caa:	38 08                	cmp    %cl,(%eax)
f0103cac:	74 05                	je     f0103cb3 <memfind+0x1b>
	for (; s < ends; s++)
f0103cae:	83 c0 01             	add    $0x1,%eax
f0103cb1:	eb f3                	jmp    f0103ca6 <memfind+0xe>
			break;
	return (void *) s;
}
f0103cb3:	5d                   	pop    %ebp
f0103cb4:	c3                   	ret    

f0103cb5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cb5:	55                   	push   %ebp
f0103cb6:	89 e5                	mov    %esp,%ebp
f0103cb8:	57                   	push   %edi
f0103cb9:	56                   	push   %esi
f0103cba:	53                   	push   %ebx
f0103cbb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103cbe:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103cc1:	eb 03                	jmp    f0103cc6 <strtol+0x11>
		s++;
f0103cc3:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103cc6:	0f b6 01             	movzbl (%ecx),%eax
f0103cc9:	3c 20                	cmp    $0x20,%al
f0103ccb:	74 f6                	je     f0103cc3 <strtol+0xe>
f0103ccd:	3c 09                	cmp    $0x9,%al
f0103ccf:	74 f2                	je     f0103cc3 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103cd1:	3c 2b                	cmp    $0x2b,%al
f0103cd3:	74 2e                	je     f0103d03 <strtol+0x4e>
	int neg = 0;
f0103cd5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103cda:	3c 2d                	cmp    $0x2d,%al
f0103cdc:	74 2f                	je     f0103d0d <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103cde:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103ce4:	75 05                	jne    f0103ceb <strtol+0x36>
f0103ce6:	80 39 30             	cmpb   $0x30,(%ecx)
f0103ce9:	74 2c                	je     f0103d17 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103ceb:	85 db                	test   %ebx,%ebx
f0103ced:	75 0a                	jne    f0103cf9 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103cef:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0103cf4:	80 39 30             	cmpb   $0x30,(%ecx)
f0103cf7:	74 28                	je     f0103d21 <strtol+0x6c>
		base = 10;
f0103cf9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cfe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103d01:	eb 50                	jmp    f0103d53 <strtol+0x9e>
		s++;
f0103d03:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0103d06:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d0b:	eb d1                	jmp    f0103cde <strtol+0x29>
		s++, neg = 1;
f0103d0d:	83 c1 01             	add    $0x1,%ecx
f0103d10:	bf 01 00 00 00       	mov    $0x1,%edi
f0103d15:	eb c7                	jmp    f0103cde <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d17:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103d1b:	74 0e                	je     f0103d2b <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0103d1d:	85 db                	test   %ebx,%ebx
f0103d1f:	75 d8                	jne    f0103cf9 <strtol+0x44>
		s++, base = 8;
f0103d21:	83 c1 01             	add    $0x1,%ecx
f0103d24:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103d29:	eb ce                	jmp    f0103cf9 <strtol+0x44>
		s += 2, base = 16;
f0103d2b:	83 c1 02             	add    $0x2,%ecx
f0103d2e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d33:	eb c4                	jmp    f0103cf9 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0103d35:	8d 72 9f             	lea    -0x61(%edx),%esi
f0103d38:	89 f3                	mov    %esi,%ebx
f0103d3a:	80 fb 19             	cmp    $0x19,%bl
f0103d3d:	77 29                	ja     f0103d68 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0103d3f:	0f be d2             	movsbl %dl,%edx
f0103d42:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103d45:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103d48:	7d 30                	jge    f0103d7a <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0103d4a:	83 c1 01             	add    $0x1,%ecx
f0103d4d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103d51:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0103d53:	0f b6 11             	movzbl (%ecx),%edx
f0103d56:	8d 72 d0             	lea    -0x30(%edx),%esi
f0103d59:	89 f3                	mov    %esi,%ebx
f0103d5b:	80 fb 09             	cmp    $0x9,%bl
f0103d5e:	77 d5                	ja     f0103d35 <strtol+0x80>
			dig = *s - '0';
f0103d60:	0f be d2             	movsbl %dl,%edx
f0103d63:	83 ea 30             	sub    $0x30,%edx
f0103d66:	eb dd                	jmp    f0103d45 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0103d68:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103d6b:	89 f3                	mov    %esi,%ebx
f0103d6d:	80 fb 19             	cmp    $0x19,%bl
f0103d70:	77 08                	ja     f0103d7a <strtol+0xc5>
			dig = *s - 'A' + 10;
f0103d72:	0f be d2             	movsbl %dl,%edx
f0103d75:	83 ea 37             	sub    $0x37,%edx
f0103d78:	eb cb                	jmp    f0103d45 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103d7a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d7e:	74 05                	je     f0103d85 <strtol+0xd0>
		*endptr = (char *) s;
f0103d80:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d83:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103d85:	89 c2                	mov    %eax,%edx
f0103d87:	f7 da                	neg    %edx
f0103d89:	85 ff                	test   %edi,%edi
f0103d8b:	0f 45 c2             	cmovne %edx,%eax
}
f0103d8e:	5b                   	pop    %ebx
f0103d8f:	5e                   	pop    %esi
f0103d90:	5f                   	pop    %edi
f0103d91:	5d                   	pop    %ebp
f0103d92:	c3                   	ret    
f0103d93:	66 90                	xchg   %ax,%ax
f0103d95:	66 90                	xchg   %ax,%ax
f0103d97:	66 90                	xchg   %ax,%ax
f0103d99:	66 90                	xchg   %ax,%ax
f0103d9b:	66 90                	xchg   %ax,%ax
f0103d9d:	66 90                	xchg   %ax,%ax
f0103d9f:	90                   	nop

f0103da0 <__udivdi3>:
f0103da0:	55                   	push   %ebp
f0103da1:	57                   	push   %edi
f0103da2:	56                   	push   %esi
f0103da3:	53                   	push   %ebx
f0103da4:	83 ec 1c             	sub    $0x1c,%esp
f0103da7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0103dab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103daf:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103db3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103db7:	85 d2                	test   %edx,%edx
f0103db9:	75 35                	jne    f0103df0 <__udivdi3+0x50>
f0103dbb:	39 f3                	cmp    %esi,%ebx
f0103dbd:	0f 87 bd 00 00 00    	ja     f0103e80 <__udivdi3+0xe0>
f0103dc3:	85 db                	test   %ebx,%ebx
f0103dc5:	89 d9                	mov    %ebx,%ecx
f0103dc7:	75 0b                	jne    f0103dd4 <__udivdi3+0x34>
f0103dc9:	b8 01 00 00 00       	mov    $0x1,%eax
f0103dce:	31 d2                	xor    %edx,%edx
f0103dd0:	f7 f3                	div    %ebx
f0103dd2:	89 c1                	mov    %eax,%ecx
f0103dd4:	31 d2                	xor    %edx,%edx
f0103dd6:	89 f0                	mov    %esi,%eax
f0103dd8:	f7 f1                	div    %ecx
f0103dda:	89 c6                	mov    %eax,%esi
f0103ddc:	89 e8                	mov    %ebp,%eax
f0103dde:	89 f7                	mov    %esi,%edi
f0103de0:	f7 f1                	div    %ecx
f0103de2:	89 fa                	mov    %edi,%edx
f0103de4:	83 c4 1c             	add    $0x1c,%esp
f0103de7:	5b                   	pop    %ebx
f0103de8:	5e                   	pop    %esi
f0103de9:	5f                   	pop    %edi
f0103dea:	5d                   	pop    %ebp
f0103deb:	c3                   	ret    
f0103dec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103df0:	39 f2                	cmp    %esi,%edx
f0103df2:	77 7c                	ja     f0103e70 <__udivdi3+0xd0>
f0103df4:	0f bd fa             	bsr    %edx,%edi
f0103df7:	83 f7 1f             	xor    $0x1f,%edi
f0103dfa:	0f 84 98 00 00 00    	je     f0103e98 <__udivdi3+0xf8>
f0103e00:	89 f9                	mov    %edi,%ecx
f0103e02:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e07:	29 f8                	sub    %edi,%eax
f0103e09:	d3 e2                	shl    %cl,%edx
f0103e0b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e0f:	89 c1                	mov    %eax,%ecx
f0103e11:	89 da                	mov    %ebx,%edx
f0103e13:	d3 ea                	shr    %cl,%edx
f0103e15:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103e19:	09 d1                	or     %edx,%ecx
f0103e1b:	89 f2                	mov    %esi,%edx
f0103e1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103e21:	89 f9                	mov    %edi,%ecx
f0103e23:	d3 e3                	shl    %cl,%ebx
f0103e25:	89 c1                	mov    %eax,%ecx
f0103e27:	d3 ea                	shr    %cl,%edx
f0103e29:	89 f9                	mov    %edi,%ecx
f0103e2b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103e2f:	d3 e6                	shl    %cl,%esi
f0103e31:	89 eb                	mov    %ebp,%ebx
f0103e33:	89 c1                	mov    %eax,%ecx
f0103e35:	d3 eb                	shr    %cl,%ebx
f0103e37:	09 de                	or     %ebx,%esi
f0103e39:	89 f0                	mov    %esi,%eax
f0103e3b:	f7 74 24 08          	divl   0x8(%esp)
f0103e3f:	89 d6                	mov    %edx,%esi
f0103e41:	89 c3                	mov    %eax,%ebx
f0103e43:	f7 64 24 0c          	mull   0xc(%esp)
f0103e47:	39 d6                	cmp    %edx,%esi
f0103e49:	72 0c                	jb     f0103e57 <__udivdi3+0xb7>
f0103e4b:	89 f9                	mov    %edi,%ecx
f0103e4d:	d3 e5                	shl    %cl,%ebp
f0103e4f:	39 c5                	cmp    %eax,%ebp
f0103e51:	73 5d                	jae    f0103eb0 <__udivdi3+0x110>
f0103e53:	39 d6                	cmp    %edx,%esi
f0103e55:	75 59                	jne    f0103eb0 <__udivdi3+0x110>
f0103e57:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103e5a:	31 ff                	xor    %edi,%edi
f0103e5c:	89 fa                	mov    %edi,%edx
f0103e5e:	83 c4 1c             	add    $0x1c,%esp
f0103e61:	5b                   	pop    %ebx
f0103e62:	5e                   	pop    %esi
f0103e63:	5f                   	pop    %edi
f0103e64:	5d                   	pop    %ebp
f0103e65:	c3                   	ret    
f0103e66:	8d 76 00             	lea    0x0(%esi),%esi
f0103e69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0103e70:	31 ff                	xor    %edi,%edi
f0103e72:	31 c0                	xor    %eax,%eax
f0103e74:	89 fa                	mov    %edi,%edx
f0103e76:	83 c4 1c             	add    $0x1c,%esp
f0103e79:	5b                   	pop    %ebx
f0103e7a:	5e                   	pop    %esi
f0103e7b:	5f                   	pop    %edi
f0103e7c:	5d                   	pop    %ebp
f0103e7d:	c3                   	ret    
f0103e7e:	66 90                	xchg   %ax,%ax
f0103e80:	31 ff                	xor    %edi,%edi
f0103e82:	89 e8                	mov    %ebp,%eax
f0103e84:	89 f2                	mov    %esi,%edx
f0103e86:	f7 f3                	div    %ebx
f0103e88:	89 fa                	mov    %edi,%edx
f0103e8a:	83 c4 1c             	add    $0x1c,%esp
f0103e8d:	5b                   	pop    %ebx
f0103e8e:	5e                   	pop    %esi
f0103e8f:	5f                   	pop    %edi
f0103e90:	5d                   	pop    %ebp
f0103e91:	c3                   	ret    
f0103e92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103e98:	39 f2                	cmp    %esi,%edx
f0103e9a:	72 06                	jb     f0103ea2 <__udivdi3+0x102>
f0103e9c:	31 c0                	xor    %eax,%eax
f0103e9e:	39 eb                	cmp    %ebp,%ebx
f0103ea0:	77 d2                	ja     f0103e74 <__udivdi3+0xd4>
f0103ea2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ea7:	eb cb                	jmp    f0103e74 <__udivdi3+0xd4>
f0103ea9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103eb0:	89 d8                	mov    %ebx,%eax
f0103eb2:	31 ff                	xor    %edi,%edi
f0103eb4:	eb be                	jmp    f0103e74 <__udivdi3+0xd4>
f0103eb6:	66 90                	xchg   %ax,%ax
f0103eb8:	66 90                	xchg   %ax,%ax
f0103eba:	66 90                	xchg   %ax,%ax
f0103ebc:	66 90                	xchg   %ax,%ax
f0103ebe:	66 90                	xchg   %ax,%ax

f0103ec0 <__umoddi3>:
f0103ec0:	55                   	push   %ebp
f0103ec1:	57                   	push   %edi
f0103ec2:	56                   	push   %esi
f0103ec3:	53                   	push   %ebx
f0103ec4:	83 ec 1c             	sub    $0x1c,%esp
f0103ec7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0103ecb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103ecf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103ed3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103ed7:	85 ed                	test   %ebp,%ebp
f0103ed9:	89 f0                	mov    %esi,%eax
f0103edb:	89 da                	mov    %ebx,%edx
f0103edd:	75 19                	jne    f0103ef8 <__umoddi3+0x38>
f0103edf:	39 df                	cmp    %ebx,%edi
f0103ee1:	0f 86 b1 00 00 00    	jbe    f0103f98 <__umoddi3+0xd8>
f0103ee7:	f7 f7                	div    %edi
f0103ee9:	89 d0                	mov    %edx,%eax
f0103eeb:	31 d2                	xor    %edx,%edx
f0103eed:	83 c4 1c             	add    $0x1c,%esp
f0103ef0:	5b                   	pop    %ebx
f0103ef1:	5e                   	pop    %esi
f0103ef2:	5f                   	pop    %edi
f0103ef3:	5d                   	pop    %ebp
f0103ef4:	c3                   	ret    
f0103ef5:	8d 76 00             	lea    0x0(%esi),%esi
f0103ef8:	39 dd                	cmp    %ebx,%ebp
f0103efa:	77 f1                	ja     f0103eed <__umoddi3+0x2d>
f0103efc:	0f bd cd             	bsr    %ebp,%ecx
f0103eff:	83 f1 1f             	xor    $0x1f,%ecx
f0103f02:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103f06:	0f 84 b4 00 00 00    	je     f0103fc0 <__umoddi3+0x100>
f0103f0c:	b8 20 00 00 00       	mov    $0x20,%eax
f0103f11:	89 c2                	mov    %eax,%edx
f0103f13:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f17:	29 c2                	sub    %eax,%edx
f0103f19:	89 c1                	mov    %eax,%ecx
f0103f1b:	89 f8                	mov    %edi,%eax
f0103f1d:	d3 e5                	shl    %cl,%ebp
f0103f1f:	89 d1                	mov    %edx,%ecx
f0103f21:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f25:	d3 e8                	shr    %cl,%eax
f0103f27:	09 c5                	or     %eax,%ebp
f0103f29:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103f2d:	89 c1                	mov    %eax,%ecx
f0103f2f:	d3 e7                	shl    %cl,%edi
f0103f31:	89 d1                	mov    %edx,%ecx
f0103f33:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103f37:	89 df                	mov    %ebx,%edi
f0103f39:	d3 ef                	shr    %cl,%edi
f0103f3b:	89 c1                	mov    %eax,%ecx
f0103f3d:	89 f0                	mov    %esi,%eax
f0103f3f:	d3 e3                	shl    %cl,%ebx
f0103f41:	89 d1                	mov    %edx,%ecx
f0103f43:	89 fa                	mov    %edi,%edx
f0103f45:	d3 e8                	shr    %cl,%eax
f0103f47:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f4c:	09 d8                	or     %ebx,%eax
f0103f4e:	f7 f5                	div    %ebp
f0103f50:	d3 e6                	shl    %cl,%esi
f0103f52:	89 d1                	mov    %edx,%ecx
f0103f54:	f7 64 24 08          	mull   0x8(%esp)
f0103f58:	39 d1                	cmp    %edx,%ecx
f0103f5a:	89 c3                	mov    %eax,%ebx
f0103f5c:	89 d7                	mov    %edx,%edi
f0103f5e:	72 06                	jb     f0103f66 <__umoddi3+0xa6>
f0103f60:	75 0e                	jne    f0103f70 <__umoddi3+0xb0>
f0103f62:	39 c6                	cmp    %eax,%esi
f0103f64:	73 0a                	jae    f0103f70 <__umoddi3+0xb0>
f0103f66:	2b 44 24 08          	sub    0x8(%esp),%eax
f0103f6a:	19 ea                	sbb    %ebp,%edx
f0103f6c:	89 d7                	mov    %edx,%edi
f0103f6e:	89 c3                	mov    %eax,%ebx
f0103f70:	89 ca                	mov    %ecx,%edx
f0103f72:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0103f77:	29 de                	sub    %ebx,%esi
f0103f79:	19 fa                	sbb    %edi,%edx
f0103f7b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0103f7f:	89 d0                	mov    %edx,%eax
f0103f81:	d3 e0                	shl    %cl,%eax
f0103f83:	89 d9                	mov    %ebx,%ecx
f0103f85:	d3 ee                	shr    %cl,%esi
f0103f87:	d3 ea                	shr    %cl,%edx
f0103f89:	09 f0                	or     %esi,%eax
f0103f8b:	83 c4 1c             	add    $0x1c,%esp
f0103f8e:	5b                   	pop    %ebx
f0103f8f:	5e                   	pop    %esi
f0103f90:	5f                   	pop    %edi
f0103f91:	5d                   	pop    %ebp
f0103f92:	c3                   	ret    
f0103f93:	90                   	nop
f0103f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f98:	85 ff                	test   %edi,%edi
f0103f9a:	89 f9                	mov    %edi,%ecx
f0103f9c:	75 0b                	jne    f0103fa9 <__umoddi3+0xe9>
f0103f9e:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fa3:	31 d2                	xor    %edx,%edx
f0103fa5:	f7 f7                	div    %edi
f0103fa7:	89 c1                	mov    %eax,%ecx
f0103fa9:	89 d8                	mov    %ebx,%eax
f0103fab:	31 d2                	xor    %edx,%edx
f0103fad:	f7 f1                	div    %ecx
f0103faf:	89 f0                	mov    %esi,%eax
f0103fb1:	f7 f1                	div    %ecx
f0103fb3:	e9 31 ff ff ff       	jmp    f0103ee9 <__umoddi3+0x29>
f0103fb8:	90                   	nop
f0103fb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103fc0:	39 dd                	cmp    %ebx,%ebp
f0103fc2:	72 08                	jb     f0103fcc <__umoddi3+0x10c>
f0103fc4:	39 f7                	cmp    %esi,%edi
f0103fc6:	0f 87 21 ff ff ff    	ja     f0103eed <__umoddi3+0x2d>
f0103fcc:	89 da                	mov    %ebx,%edx
f0103fce:	89 f0                	mov    %esi,%eax
f0103fd0:	29 f8                	sub    %edi,%eax
f0103fd2:	19 ea                	sbb    %ebp,%edx
f0103fd4:	e9 14 ff ff ff       	jmp    f0103eed <__umoddi3+0x2d>
