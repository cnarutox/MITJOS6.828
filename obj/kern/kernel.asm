
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f010004c:	81 c3 bc 32 01 00    	add    $0x132bc,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 50 11 f0    	mov    $0xf0115060,%edx
f0100058:	c7 c0 c0 56 11 f0    	mov    $0xf01156c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 ad 22 00 00       	call   f0102316 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 58 f4 fe ff    	lea    -0x10ba8(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 38 17 00 00       	call   f01017ba <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 5b 0c 00 00       	call   f0100ce2 <mem_init>
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
f01000a7:	81 c3 61 32 01 00    	add    $0x13261,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 56 11 f0    	mov    $0xf01156c4,%eax
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
f01000da:	8d 83 73 f4 fe ff    	lea    -0x10b8d(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 d4 16 00 00       	call   f01017ba <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 93 16 00 00       	call   f0101783 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 af f4 fe ff    	lea    -0x10b51(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 bc 16 00 00       	call   f01017ba <cprintf>
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
f010010d:	81 c3 fb 31 01 00    	add    $0x131fb,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 8b f4 fe ff    	lea    -0x10b75(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 8f 16 00 00       	call   f01017ba <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 4c 16 00 00       	call   f0101783 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 af f4 fe ff    	lea    -0x10b51(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 75 16 00 00       	call   f01017ba <cprintf>
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
f010017c:	81 c3 8c 31 01 00    	add    $0x1318c,%ebx
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
f010018f:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010019e:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
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
f01001c7:	81 c3 41 31 01 00    	add    $0x13141,%ebx
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
f01001fb:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 d8 f5 fe 	movzbl -0x10a28(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 d8 f4 fe 	movzbl -0x10b28(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
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
f010026a:	8d 83 a5 f4 fe ff    	lea    -0x10b5b(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 44 15 00 00       	call   f01017ba <cprintf>
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
f0100286:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
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
f010029b:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 d8 f5 fe 	movzbl -0x10a28(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
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
f01002fd:	81 c3 0b 30 01 00    	add    $0x1300b,%ebx
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
f01003bc:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
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
f0100423:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
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
f0100495:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 8c 1e 00 00       	call   f0102363 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 fe 2d 01 00       	add    $0x12dfe,%eax
	if (serial_exists)
f010050f:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 4b ce fe ff    	lea    -0x131b5(%eax),%eax
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
f0100538:	05 d0 2d 01 00       	add    $0x12dd0,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b5 ce fe ff    	lea    -0x1314b(%eax),%eax
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
f0100556:	81 c3 b2 2d 01 00    	add    $0x12db2,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100582:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
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
f0100598:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
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
f01005b2:	81 c3 56 2d 01 00    	add    $0x12d56,%ebx
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
f01005d9:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
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
f0100612:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
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
f0100675:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
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
f010069c:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 b1 f4 fe ff    	lea    -0x10b4f(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 f9 10 00 00       	call   f01017ba <cprintf>
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
f01006ff:	81 c3 09 2c 01 00    	add    $0x12c09,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 d8 f6 fe ff    	lea    -0x10928(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 f6 f6 fe ff    	lea    -0x1090a(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 fb f6 fe ff    	lea    -0x10905(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 98 10 00 00       	call   f01017ba <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 64 f7 fe ff    	lea    -0x1089c(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 04 f7 fe ff    	lea    -0x108fc(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 81 10 00 00       	call   f01017ba <cprintf>
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
f0100753:	81 c3 b5 2b 01 00    	add    $0x12bb5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100759:	8d 83 0d f7 fe ff    	lea    -0x108f3(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	e8 55 10 00 00       	call   f01017ba <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100765:	83 c4 08             	add    $0x8,%esp
f0100768:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076e:	8d 83 8c f7 fe ff    	lea    -0x10874(%ebx),%eax
f0100774:	50                   	push   %eax
f0100775:	e8 40 10 00 00       	call   f01017ba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010077a:	83 c4 0c             	add    $0xc,%esp
f010077d:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100783:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100789:	50                   	push   %eax
f010078a:	57                   	push   %edi
f010078b:	8d 83 b4 f7 fe ff    	lea    -0x1084c(%ebx),%eax
f0100791:	50                   	push   %eax
f0100792:	e8 23 10 00 00       	call   f01017ba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100797:	83 c4 0c             	add    $0xc,%esp
f010079a:	c7 c0 59 27 10 f0    	mov    $0xf0102759,%eax
f01007a0:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a6:	52                   	push   %edx
f01007a7:	50                   	push   %eax
f01007a8:	8d 83 d8 f7 fe ff    	lea    -0x10828(%ebx),%eax
f01007ae:	50                   	push   %eax
f01007af:	e8 06 10 00 00       	call   f01017ba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b4:	83 c4 0c             	add    $0xc,%esp
f01007b7:	c7 c0 60 50 11 f0    	mov    $0xf0115060,%eax
f01007bd:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c3:	52                   	push   %edx
f01007c4:	50                   	push   %eax
f01007c5:	8d 83 fc f7 fe ff    	lea    -0x10804(%ebx),%eax
f01007cb:	50                   	push   %eax
f01007cc:	e8 e9 0f 00 00       	call   f01017ba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007d1:	83 c4 0c             	add    $0xc,%esp
f01007d4:	c7 c6 c0 56 11 f0    	mov    $0xf01156c0,%esi
f01007da:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007e0:	50                   	push   %eax
f01007e1:	56                   	push   %esi
f01007e2:	8d 83 20 f8 fe ff    	lea    -0x107e0(%ebx),%eax
f01007e8:	50                   	push   %eax
f01007e9:	e8 cc 0f 00 00       	call   f01017ba <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007ee:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007f1:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01007f7:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	c1 fe 0a             	sar    $0xa,%esi
f01007fc:	56                   	push   %esi
f01007fd:	8d 83 44 f8 fe ff    	lea    -0x107bc(%ebx),%eax
f0100803:	50                   	push   %eax
f0100804:	e8 b1 0f 00 00       	call   f01017ba <cprintf>
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
f010082e:	81 c3 da 2a 01 00    	add    $0x12ada,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100834:	8d 83 70 f8 fe ff    	lea    -0x10790(%ebx),%eax
f010083a:	50                   	push   %eax
f010083b:	e8 7a 0f 00 00       	call   f01017ba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100840:	8d 83 94 f8 fe ff    	lea    -0x1076c(%ebx),%eax
f0100846:	89 04 24             	mov    %eax,(%esp)
f0100849:	e8 6c 0f 00 00       	call   f01017ba <cprintf>
f010084e:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100851:	8d bb 2a f7 fe ff    	lea    -0x108d6(%ebx),%edi
f0100857:	eb 4a                	jmp    f01008a3 <monitor+0x83>
f0100859:	83 ec 08             	sub    $0x8,%esp
f010085c:	0f be c0             	movsbl %al,%eax
f010085f:	50                   	push   %eax
f0100860:	57                   	push   %edi
f0100861:	e8 73 1a 00 00       	call   f01022d9 <strchr>
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
f0100894:	8d 83 2f f7 fe ff    	lea    -0x108d1(%ebx),%eax
f010089a:	50                   	push   %eax
f010089b:	e8 1a 0f 00 00       	call   f01017ba <cprintf>
f01008a0:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a3:	8d 83 26 f7 fe ff    	lea    -0x108da(%ebx),%eax
f01008a9:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01008ac:	83 ec 0c             	sub    $0xc,%esp
f01008af:	ff 75 a4             	pushl  -0x5c(%ebp)
f01008b2:	e8 ea 17 00 00       	call   f01020a1 <readline>
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
f01008e2:	e8 f2 19 00 00       	call   f01022d9 <strchr>
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
f010090b:	8d 83 f6 f6 fe ff    	lea    -0x1090a(%ebx),%eax
f0100911:	50                   	push   %eax
f0100912:	ff 75 a8             	pushl  -0x58(%ebp)
f0100915:	e8 61 19 00 00       	call   f010227b <strcmp>
f010091a:	83 c4 10             	add    $0x10,%esp
f010091d:	85 c0                	test   %eax,%eax
f010091f:	74 38                	je     f0100959 <monitor+0x139>
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	8d 83 04 f7 fe ff    	lea    -0x108fc(%ebx),%eax
f010092a:	50                   	push   %eax
f010092b:	ff 75 a8             	pushl  -0x58(%ebp)
f010092e:	e8 48 19 00 00       	call   f010227b <strcmp>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	74 1a                	je     f0100954 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f010093a:	83 ec 08             	sub    $0x8,%esp
f010093d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100940:	8d 83 4c f7 fe ff    	lea    -0x108b4(%ebx),%eax
f0100946:	50                   	push   %eax
f0100947:	e8 6e 0e 00 00       	call   f01017ba <cprintf>
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
f0100969:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
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
f0100987:	e8 9b 0d 00 00       	call   f0101727 <__x86.get_pc_thunk.dx>
f010098c:	81 c2 7c 29 01 00    	add    $0x1297c,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100992:	83 ba 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%edx)
f0100999:	74 1e                	je     f01009b9 <boot_alloc+0x36>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010099b:	8b 9a 90 1f 00 00    	mov    0x1f90(%edx),%ebx
	nextfree = ROUNDUP( (char*)(nextfree + n), PGSIZE);
f01009a1:	8d 8c 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%ecx
f01009a8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01009ae:	89 8a 90 1f 00 00    	mov    %ecx,0x1f90(%edx)
	return result;
}
f01009b4:	89 d8                	mov    %ebx,%eax
f01009b6:	5b                   	pop    %ebx
f01009b7:	5d                   	pop    %ebp
f01009b8:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009b9:	c7 c1 c0 56 11 f0    	mov    $0xf01156c0,%ecx
f01009bf:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f01009c5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01009cb:	89 8a 90 1f 00 00    	mov    %ecx,0x1f90(%edx)
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
f01009e1:	81 c3 27 29 01 00    	add    $0x12927,%ebx
f01009e7:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009e9:	50                   	push   %eax
f01009ea:	e8 44 0d 00 00       	call   f0101733 <mc146818_read>
f01009ef:	89 c6                	mov    %eax,%esi
f01009f1:	83 c7 01             	add    $0x1,%edi
f01009f4:	89 3c 24             	mov    %edi,(%esp)
f01009f7:	e8 37 0d 00 00       	call   f0101733 <mc146818_read>
f01009fc:	c1 e0 08             	shl    $0x8,%eax
f01009ff:	09 f0                	or     %esi,%eax
}
f0100a01:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a04:	5b                   	pop    %ebx
f0100a05:	5e                   	pop    %esi
f0100a06:	5f                   	pop    %edi
f0100a07:	5d                   	pop    %ebp
f0100a08:	c3                   	ret    

f0100a09 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a09:	55                   	push   %ebp
f0100a0a:	89 e5                	mov    %esp,%ebp
f0100a0c:	53                   	push   %ebx
f0100a0d:	83 ec 04             	sub    $0x4,%esp
f0100a10:	e8 12 0d 00 00       	call   f0101727 <__x86.get_pc_thunk.dx>
f0100a15:	81 c2 f3 28 01 00    	add    $0x128f3,%edx
	return (pp - pages) << PGSHIFT;
f0100a1b:	c7 c1 d0 56 11 f0    	mov    $0xf01156d0,%ecx
f0100a21:	2b 01                	sub    (%ecx),%eax
f0100a23:	c1 f8 03             	sar    $0x3,%eax
f0100a26:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100a29:	89 c1                	mov    %eax,%ecx
f0100a2b:	c1 e9 0c             	shr    $0xc,%ecx
f0100a2e:	c7 c3 c8 56 11 f0    	mov    $0xf01156c8,%ebx
f0100a34:	39 0b                	cmp    %ecx,(%ebx)
f0100a36:	76 0a                	jbe    f0100a42 <page2kva+0x39>
	return (void *)(pa + KERNBASE);
f0100a38:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return KADDR(page2pa(pp));
}
f0100a3d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a40:	c9                   	leave  
f0100a41:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a42:	50                   	push   %eax
f0100a43:	8d 82 bc f8 fe ff    	lea    -0x10744(%edx),%eax
f0100a49:	50                   	push   %eax
f0100a4a:	6a 52                	push   $0x52
f0100a4c:	8d 82 98 fa fe ff    	lea    -0x10568(%edx),%eax
f0100a52:	50                   	push   %eax
f0100a53:	89 d3                	mov    %edx,%ebx
f0100a55:	e8 3f f6 ff ff       	call   f0100099 <_panic>

f0100a5a <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a5a:	55                   	push   %ebp
f0100a5b:	89 e5                	mov    %esp,%ebp
f0100a5d:	56                   	push   %esi
f0100a5e:	53                   	push   %ebx
f0100a5f:	e8 c7 0c 00 00       	call   f010172b <__x86.get_pc_thunk.cx>
f0100a64:	81 c1 a4 28 01 00    	add    $0x128a4,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a6a:	89 d3                	mov    %edx,%ebx
f0100a6c:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a6f:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a72:	a8 01                	test   $0x1,%al
f0100a74:	74 5a                	je     f0100ad0 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a76:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100a7b:	89 c6                	mov    %eax,%esi
f0100a7d:	c1 ee 0c             	shr    $0xc,%esi
f0100a80:	c7 c3 c8 56 11 f0    	mov    $0xf01156c8,%ebx
f0100a86:	3b 33                	cmp    (%ebx),%esi
f0100a88:	73 2b                	jae    f0100ab5 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a8a:	c1 ea 0c             	shr    $0xc,%edx
f0100a8d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a93:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a9a:	89 c2                	mov    %eax,%edx
f0100a9c:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aa4:	85 d2                	test   %edx,%edx
f0100aa6:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100aab:	0f 44 c2             	cmove  %edx,%eax
}
f0100aae:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ab1:	5b                   	pop    %ebx
f0100ab2:	5e                   	pop    %esi
f0100ab3:	5d                   	pop    %ebp
f0100ab4:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ab5:	50                   	push   %eax
f0100ab6:	8d 81 bc f8 fe ff    	lea    -0x10744(%ecx),%eax
f0100abc:	50                   	push   %eax
f0100abd:	68 a7 02 00 00       	push   $0x2a7
f0100ac2:	8d 81 a6 fa fe ff    	lea    -0x1055a(%ecx),%eax
f0100ac8:	50                   	push   %eax
f0100ac9:	89 cb                	mov    %ecx,%ebx
f0100acb:	e8 c9 f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100ad0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ad5:	eb d7                	jmp    f0100aae <check_va2pa+0x54>

f0100ad7 <page_init>:
{
f0100ad7:	55                   	push   %ebp
f0100ad8:	89 e5                	mov    %esp,%ebp
f0100ada:	57                   	push   %edi
f0100adb:	56                   	push   %esi
f0100adc:	53                   	push   %ebx
f0100add:	83 ec 08             	sub    $0x8,%esp
f0100ae0:	e8 4a 0c 00 00       	call   f010172f <__x86.get_pc_thunk.si>
f0100ae5:	81 c6 23 28 01 00    	add    $0x12823,%esi
	page_free_list = NULL;
f0100aeb:	c7 86 94 1f 00 00 00 	movl   $0x0,0x1f94(%esi)
f0100af2:	00 00 00 
	int num_alloc = ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;
f0100af5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100afa:	e8 84 fe ff ff       	call   f0100983 <boot_alloc>
	for (i = 0; i < npages; i++) {
f0100aff:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100b04:	c7 c7 c8 56 11 f0    	mov    $0xf01156c8,%edi
			pages[i].pp_ref = 0;
f0100b0a:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100b10:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < npages; i++) {
f0100b13:	eb 38                	jmp    f0100b4d <page_init+0x76>
		else if(i >= 1 && i < npages_basemem)
f0100b15:	39 9e 98 1f 00 00    	cmp    %ebx,0x1f98(%esi)
f0100b1b:	76 4c                	jbe    f0100b69 <page_init+0x92>
f0100b1d:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
			pages[i].pp_ref = 0;
f0100b24:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100b2a:	89 ca                	mov    %ecx,%edx
f0100b2c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b2f:	03 10                	add    (%eax),%edx
f0100b31:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list; 
f0100b37:	8b 86 94 1f 00 00    	mov    0x1f94(%esi),%eax
f0100b3d:	89 02                	mov    %eax,(%edx)
			page_free_list = &pages[i];
f0100b3f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b42:	03 08                	add    (%eax),%ecx
f0100b44:	89 8e 94 1f 00 00    	mov    %ecx,0x1f94(%esi)
	for (i = 0; i < npages; i++) {
f0100b4a:	83 c3 01             	add    $0x1,%ebx
f0100b4d:	39 1f                	cmp    %ebx,(%edi)
f0100b4f:	0f 86 8b 00 00 00    	jbe    f0100be0 <page_init+0x109>
		if(i == 0)
f0100b55:	85 db                	test   %ebx,%ebx
f0100b57:	75 bc                	jne    f0100b15 <page_init+0x3e>
			pages[i].pp_ref = 1;
f0100b59:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100b5f:	8b 00                	mov    (%eax),%eax
f0100b61:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0100b67:	eb e1                	jmp    f0100b4a <page_init+0x73>
		else if(i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE )
f0100b69:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100b6f:	83 f8 5f             	cmp    $0x5f,%eax
f0100b72:	77 11                	ja     f0100b85 <page_init+0xae>
			pages[i].pp_ref = 1;
f0100b74:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100b7a:	8b 00                	mov    (%eax),%eax
f0100b7c:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f0100b83:	eb c5                	jmp    f0100b4a <page_init+0x73>
		else if( i >= EXTPHYSMEM / PGSIZE && i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
f0100b85:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100b8b:	77 29                	ja     f0100bb6 <page_init+0xdf>
f0100b8d:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0100b94:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b97:	89 c2                	mov    %eax,%edx
f0100b99:	03 11                	add    (%ecx),%edx
f0100b9b:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list; 
f0100ba1:	8b 8e 94 1f 00 00    	mov    0x1f94(%esi),%ecx
f0100ba7:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100ba9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bac:	03 01                	add    (%ecx),%eax
f0100bae:	89 86 94 1f 00 00    	mov    %eax,0x1f94(%esi)
f0100bb4:	eb 94                	jmp    f0100b4a <page_init+0x73>
		else if( i >= EXTPHYSMEM / PGSIZE && i < ( (int)(boot_alloc(0)) - KERNBASE)/PGSIZE)
f0100bb6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bbb:	e8 c3 fd ff ff       	call   f0100983 <boot_alloc>
f0100bc0:	05 00 00 00 10       	add    $0x10000000,%eax
f0100bc5:	c1 e8 0c             	shr    $0xc,%eax
f0100bc8:	39 d8                	cmp    %ebx,%eax
f0100bca:	76 c1                	jbe    f0100b8d <page_init+0xb6>
			 pages[i].pp_ref = 1; 
f0100bcc:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100bd2:	8b 00                	mov    (%eax),%eax
f0100bd4:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f0100bdb:	e9 6a ff ff ff       	jmp    f0100b4a <page_init+0x73>
}
f0100be0:	83 c4 08             	add    $0x8,%esp
f0100be3:	5b                   	pop    %ebx
f0100be4:	5e                   	pop    %esi
f0100be5:	5f                   	pop    %edi
f0100be6:	5d                   	pop    %ebp
f0100be7:	c3                   	ret    

f0100be8 <page_alloc>:
{
f0100be8:	55                   	push   %ebp
f0100be9:	89 e5                	mov    %esp,%ebp
f0100beb:	56                   	push   %esi
f0100bec:	53                   	push   %ebx
f0100bed:	e8 5d f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100bf2:	81 c3 16 27 01 00    	add    $0x12716,%ebx
    if (page_free_list == NULL)
f0100bf8:	8b b3 94 1f 00 00    	mov    0x1f94(%ebx),%esi
f0100bfe:	85 f6                	test   %esi,%esi
f0100c00:	74 14                	je     f0100c16 <page_alloc+0x2e>
	page_free_list = result->pp_link;
f0100c02:	8b 06                	mov    (%esi),%eax
f0100c04:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	result->pp_link = NULL;
f0100c0a:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
    if (alloc_flags & ALLOC_ZERO)
f0100c10:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100c14:	75 09                	jne    f0100c1f <page_alloc+0x37>
}
f0100c16:	89 f0                	mov    %esi,%eax
f0100c18:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c1b:	5b                   	pop    %ebx
f0100c1c:	5e                   	pop    %esi
f0100c1d:	5d                   	pop    %ebp
f0100c1e:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0100c1f:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100c25:	89 f2                	mov    %esi,%edx
f0100c27:	2b 10                	sub    (%eax),%edx
f0100c29:	89 d0                	mov    %edx,%eax
f0100c2b:	c1 f8 03             	sar    $0x3,%eax
f0100c2e:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0100c31:	89 c1                	mov    %eax,%ecx
f0100c33:	c1 e9 0c             	shr    $0xc,%ecx
f0100c36:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f0100c3c:	3b 0a                	cmp    (%edx),%ecx
f0100c3e:	73 1a                	jae    f0100c5a <page_alloc+0x72>
        memset(page2kva(result), 0, PGSIZE);
f0100c40:	83 ec 04             	sub    $0x4,%esp
f0100c43:	68 00 10 00 00       	push   $0x1000
f0100c48:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100c4a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c4f:	50                   	push   %eax
f0100c50:	e8 c1 16 00 00       	call   f0102316 <memset>
f0100c55:	83 c4 10             	add    $0x10,%esp
f0100c58:	eb bc                	jmp    f0100c16 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c5a:	50                   	push   %eax
f0100c5b:	8d 83 bc f8 fe ff    	lea    -0x10744(%ebx),%eax
f0100c61:	50                   	push   %eax
f0100c62:	6a 52                	push   $0x52
f0100c64:	8d 83 98 fa fe ff    	lea    -0x10568(%ebx),%eax
f0100c6a:	50                   	push   %eax
f0100c6b:	e8 29 f4 ff ff       	call   f0100099 <_panic>

f0100c70 <page_free>:
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	53                   	push   %ebx
f0100c74:	83 ec 04             	sub    $0x4,%esp
f0100c77:	e8 d3 f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100c7c:	81 c3 8c 26 01 00    	add    $0x1268c,%ebx
f0100c82:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(pp->pp_ref == 0);
f0100c85:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100c8a:	75 18                	jne    f0100ca4 <page_free+0x34>
	assert(pp->pp_link == NULL);
f0100c8c:	83 38 00             	cmpl   $0x0,(%eax)
f0100c8f:	75 32                	jne    f0100cc3 <page_free+0x53>
	pp->pp_link = page_free_list;
f0100c91:	8b 8b 94 1f 00 00    	mov    0x1f94(%ebx),%ecx
f0100c97:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f0100c99:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f0100c9f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100ca2:	c9                   	leave  
f0100ca3:	c3                   	ret    
	assert(pp->pp_ref == 0);
f0100ca4:	8d 83 b2 fa fe ff    	lea    -0x1054e(%ebx),%eax
f0100caa:	50                   	push   %eax
f0100cab:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100cb1:	50                   	push   %eax
f0100cb2:	68 45 01 00 00       	push   $0x145
f0100cb7:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100cbd:	50                   	push   %eax
f0100cbe:	e8 d6 f3 ff ff       	call   f0100099 <_panic>
	assert(pp->pp_link == NULL);
f0100cc3:	8d 83 d7 fa fe ff    	lea    -0x10529(%ebx),%eax
f0100cc9:	50                   	push   %eax
f0100cca:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100cd0:	50                   	push   %eax
f0100cd1:	68 46 01 00 00       	push   $0x146
f0100cd6:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100cdc:	50                   	push   %eax
f0100cdd:	e8 b7 f3 ff ff       	call   f0100099 <_panic>

f0100ce2 <mem_init>:
{
f0100ce2:	55                   	push   %ebp
f0100ce3:	89 e5                	mov    %esp,%ebp
f0100ce5:	57                   	push   %edi
f0100ce6:	56                   	push   %esi
f0100ce7:	53                   	push   %ebx
f0100ce8:	83 ec 3c             	sub    $0x3c,%esp
f0100ceb:	e8 5f f4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100cf0:	81 c3 18 26 01 00    	add    $0x12618,%ebx
	basemem = nvram_read(NVRAM_BASELO);
f0100cf6:	b8 15 00 00 00       	mov    $0x15,%eax
f0100cfb:	e8 d3 fc ff ff       	call   f01009d3 <nvram_read>
f0100d00:	89 c7                	mov    %eax,%edi
	extmem = nvram_read(NVRAM_EXTLO);
f0100d02:	b8 17 00 00 00       	mov    $0x17,%eax
f0100d07:	e8 c7 fc ff ff       	call   f01009d3 <nvram_read>
f0100d0c:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100d0e:	b8 34 00 00 00       	mov    $0x34,%eax
f0100d13:	e8 bb fc ff ff       	call   f01009d3 <nvram_read>
f0100d18:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f0100d1b:	85 c0                	test   %eax,%eax
f0100d1d:	75 0e                	jne    f0100d2d <mem_init+0x4b>
		totalmem = basemem;
f0100d1f:	89 f8                	mov    %edi,%eax
	else if (extmem)
f0100d21:	85 f6                	test   %esi,%esi
f0100d23:	74 0d                	je     f0100d32 <mem_init+0x50>
		totalmem = 1 * 1024 + extmem;
f0100d25:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100d2b:	eb 05                	jmp    f0100d32 <mem_init+0x50>
		totalmem = 16 * 1024 + ext16mem;
f0100d2d:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0100d32:	89 c1                	mov    %eax,%ecx
f0100d34:	c1 e9 02             	shr    $0x2,%ecx
f0100d37:	c7 c2 c8 56 11 f0    	mov    $0xf01156c8,%edx
f0100d3d:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0100d3f:	89 fa                	mov    %edi,%edx
f0100d41:	c1 ea 02             	shr    $0x2,%edx
f0100d44:	89 93 98 1f 00 00    	mov    %edx,0x1f98(%ebx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100d4a:	89 c2                	mov    %eax,%edx
f0100d4c:	29 fa                	sub    %edi,%edx
f0100d4e:	52                   	push   %edx
f0100d4f:	57                   	push   %edi
f0100d50:	50                   	push   %eax
f0100d51:	8d 83 e0 f8 fe ff    	lea    -0x10720(%ebx),%eax
f0100d57:	50                   	push   %eax
f0100d58:	e8 5d 0a 00 00       	call   f01017ba <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100d5d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100d62:	e8 1c fc ff ff       	call   f0100983 <boot_alloc>
f0100d67:	c7 c6 cc 56 11 f0    	mov    $0xf01156cc,%esi
f0100d6d:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0100d6f:	83 c4 0c             	add    $0xc,%esp
f0100d72:	68 00 10 00 00       	push   $0x1000
f0100d77:	6a 00                	push   $0x0
f0100d79:	50                   	push   %eax
f0100d7a:	e8 97 15 00 00       	call   f0102316 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100d7f:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0100d81:	83 c4 10             	add    $0x10,%esp
f0100d84:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d89:	77 19                	ja     f0100da4 <mem_init+0xc2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d8b:	50                   	push   %eax
f0100d8c:	8d 83 1c f9 fe ff    	lea    -0x106e4(%ebx),%eax
f0100d92:	50                   	push   %eax
f0100d93:	68 8f 00 00 00       	push   $0x8f
f0100d98:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100d9e:	50                   	push   %eax
f0100d9f:	e8 f5 f2 ff ff       	call   f0100099 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100da4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100daa:	83 ca 05             	or     $0x5,%edx
f0100dad:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f0100db3:	c7 c6 c8 56 11 f0    	mov    $0xf01156c8,%esi
f0100db9:	8b 06                	mov    (%esi),%eax
f0100dbb:	c1 e0 03             	shl    $0x3,%eax
f0100dbe:	e8 c0 fb ff ff       	call   f0100983 <boot_alloc>
f0100dc3:	c7 c2 d0 56 11 f0    	mov    $0xf01156d0,%edx
f0100dc9:	89 02                	mov    %eax,(%edx)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0100dcb:	83 ec 04             	sub    $0x4,%esp
f0100dce:	8b 16                	mov    (%esi),%edx
f0100dd0:	c1 e2 03             	shl    $0x3,%edx
f0100dd3:	52                   	push   %edx
f0100dd4:	6a 00                	push   $0x0
f0100dd6:	50                   	push   %eax
f0100dd7:	e8 3a 15 00 00       	call   f0102316 <memset>
	page_init();
f0100ddc:	e8 f6 fc ff ff       	call   f0100ad7 <page_init>
	if (!page_free_list)
f0100de1:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0100de7:	83 c4 10             	add    $0x10,%esp
f0100dea:	85 c0                	test   %eax,%eax
f0100dec:	74 5d                	je     f0100e4b <mem_init+0x169>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100dee:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100df1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100df4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100df7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100dfa:	c7 c1 d0 56 11 f0    	mov    $0xf01156d0,%ecx
f0100e00:	89 c2                	mov    %eax,%edx
f0100e02:	2b 11                	sub    (%ecx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e04:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e0a:	0f 95 c2             	setne  %dl
f0100e0d:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e10:	8b 74 95 e0          	mov    -0x20(%ebp,%edx,4),%esi
f0100e14:	89 06                	mov    %eax,(%esi)
			tp[pagetype] = &pp->pp_link;
f0100e16:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e1a:	8b 00                	mov    (%eax),%eax
f0100e1c:	85 c0                	test   %eax,%eax
f0100e1e:	75 e0                	jne    f0100e00 <mem_init+0x11e>
		*tp[1] = 0;
f0100e20:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e23:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e29:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e2c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e2f:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100e31:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0100e34:	89 b3 94 1f 00 00    	mov    %esi,0x1f94(%ebx)
f0100e3a:	c7 c7 d0 56 11 f0    	mov    $0xf01156d0,%edi
	if (PGNUM(pa) >= npages)
f0100e40:	c7 c0 c8 56 11 f0    	mov    $0xf01156c8,%eax
f0100e46:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e49:	eb 33                	jmp    f0100e7e <mem_init+0x19c>
		panic("'page_free_list' is a null pointer!");
f0100e4b:	83 ec 04             	sub    $0x4,%esp
f0100e4e:	8d 83 40 f9 fe ff    	lea    -0x106c0(%ebx),%eax
f0100e54:	50                   	push   %eax
f0100e55:	68 e8 01 00 00       	push   $0x1e8
f0100e5a:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	e8 33 f2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e66:	52                   	push   %edx
f0100e67:	8d 83 bc f8 fe ff    	lea    -0x10744(%ebx),%eax
f0100e6d:	50                   	push   %eax
f0100e6e:	6a 52                	push   $0x52
f0100e70:	8d 83 98 fa fe ff    	lea    -0x10568(%ebx),%eax
f0100e76:	50                   	push   %eax
f0100e77:	e8 1d f2 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e7c:	8b 36                	mov    (%esi),%esi
f0100e7e:	85 f6                	test   %esi,%esi
f0100e80:	74 3d                	je     f0100ebf <mem_init+0x1dd>
	return (pp - pages) << PGSHIFT;
f0100e82:	89 f0                	mov    %esi,%eax
f0100e84:	2b 07                	sub    (%edi),%eax
f0100e86:	c1 f8 03             	sar    $0x3,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100e89:	89 c2                	mov    %eax,%edx
f0100e8b:	c1 e2 0c             	shl    $0xc,%edx
f0100e8e:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f0100e93:	75 e7                	jne    f0100e7c <mem_init+0x19a>
	if (PGNUM(pa) >= npages)
f0100e95:	89 d0                	mov    %edx,%eax
f0100e97:	c1 e8 0c             	shr    $0xc,%eax
f0100e9a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100e9d:	3b 01                	cmp    (%ecx),%eax
f0100e9f:	73 c5                	jae    f0100e66 <mem_init+0x184>
			memset(page2kva(pp), 0x97, 128);
f0100ea1:	83 ec 04             	sub    $0x4,%esp
f0100ea4:	68 80 00 00 00       	push   $0x80
f0100ea9:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100eae:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100eb4:	52                   	push   %edx
f0100eb5:	e8 5c 14 00 00       	call   f0102316 <memset>
f0100eba:	83 c4 10             	add    $0x10,%esp
f0100ebd:	eb bd                	jmp    f0100e7c <mem_init+0x19a>
	first_free_page = (char *) boot_alloc(0);
f0100ebf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ec4:	e8 ba fa ff ff       	call   f0100983 <boot_alloc>
f0100ec9:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ecc:	8b 93 94 1f 00 00    	mov    0x1f94(%ebx),%edx
		assert(pp >= pages);
f0100ed2:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0100ed8:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100eda:	c7 c0 c8 56 11 f0    	mov    $0xf01156c8,%eax
f0100ee0:	8b 00                	mov    (%eax),%eax
f0100ee2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100ee5:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100ee8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100eeb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100eee:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ef3:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0100ef6:	e9 f3 00 00 00       	jmp    f0100fee <mem_init+0x30c>
		assert(pp >= pages);
f0100efb:	8d 83 eb fa fe ff    	lea    -0x10515(%ebx),%eax
f0100f01:	50                   	push   %eax
f0100f02:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100f08:	50                   	push   %eax
f0100f09:	68 02 02 00 00       	push   $0x202
f0100f0e:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100f14:	50                   	push   %eax
f0100f15:	e8 7f f1 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100f1a:	8d 83 f7 fa fe ff    	lea    -0x10509(%ebx),%eax
f0100f20:	50                   	push   %eax
f0100f21:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100f27:	50                   	push   %eax
f0100f28:	68 03 02 00 00       	push   $0x203
f0100f2d:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100f33:	50                   	push   %eax
f0100f34:	e8 60 f1 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f39:	8d 83 64 f9 fe ff    	lea    -0x1069c(%ebx),%eax
f0100f3f:	50                   	push   %eax
f0100f40:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100f46:	50                   	push   %eax
f0100f47:	68 04 02 00 00       	push   $0x204
f0100f4c:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100f52:	50                   	push   %eax
f0100f53:	e8 41 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100f58:	8d 83 0b fb fe ff    	lea    -0x104f5(%ebx),%eax
f0100f5e:	50                   	push   %eax
f0100f5f:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100f65:	50                   	push   %eax
f0100f66:	68 07 02 00 00       	push   $0x207
f0100f6b:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100f71:	50                   	push   %eax
f0100f72:	e8 22 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f77:	8d 83 1c fb fe ff    	lea    -0x104e4(%ebx),%eax
f0100f7d:	50                   	push   %eax
f0100f7e:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100f84:	50                   	push   %eax
f0100f85:	68 08 02 00 00       	push   $0x208
f0100f8a:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100f90:	50                   	push   %eax
f0100f91:	e8 03 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f96:	8d 83 98 f9 fe ff    	lea    -0x10668(%ebx),%eax
f0100f9c:	50                   	push   %eax
f0100f9d:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100fa3:	50                   	push   %eax
f0100fa4:	68 09 02 00 00       	push   $0x209
f0100fa9:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100faf:	50                   	push   %eax
f0100fb0:	e8 e4 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100fb5:	8d 83 35 fb fe ff    	lea    -0x104cb(%ebx),%eax
f0100fbb:	50                   	push   %eax
f0100fbc:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0100fc2:	50                   	push   %eax
f0100fc3:	68 0a 02 00 00       	push   $0x20a
f0100fc8:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0100fce:	50                   	push   %eax
f0100fcf:	e8 c5 f0 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100fd4:	89 c6                	mov    %eax,%esi
f0100fd6:	c1 ee 0c             	shr    $0xc,%esi
f0100fd9:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f0100fdc:	76 71                	jbe    f010104f <mem_init+0x36d>
	return (void *)(pa + KERNBASE);
f0100fde:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fe3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100fe6:	77 7d                	ja     f0101065 <mem_init+0x383>
			++nfree_extmem;
f0100fe8:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fec:	8b 12                	mov    (%edx),%edx
f0100fee:	85 d2                	test   %edx,%edx
f0100ff0:	0f 84 8e 00 00 00    	je     f0101084 <mem_init+0x3a2>
		assert(pp >= pages);
f0100ff6:	39 d1                	cmp    %edx,%ecx
f0100ff8:	0f 87 fd fe ff ff    	ja     f0100efb <mem_init+0x219>
		assert(pp < pages + npages);
f0100ffe:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101001:	0f 83 13 ff ff ff    	jae    f0100f1a <mem_init+0x238>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101007:	89 d0                	mov    %edx,%eax
f0101009:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010100c:	a8 07                	test   $0x7,%al
f010100e:	0f 85 25 ff ff ff    	jne    f0100f39 <mem_init+0x257>
	return (pp - pages) << PGSHIFT;
f0101014:	c1 f8 03             	sar    $0x3,%eax
f0101017:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f010101a:	85 c0                	test   %eax,%eax
f010101c:	0f 84 36 ff ff ff    	je     f0100f58 <mem_init+0x276>
		assert(page2pa(pp) != IOPHYSMEM);
f0101022:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101027:	0f 84 4a ff ff ff    	je     f0100f77 <mem_init+0x295>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010102d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101032:	0f 84 5e ff ff ff    	je     f0100f96 <mem_init+0x2b4>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101038:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010103d:	0f 84 72 ff ff ff    	je     f0100fb5 <mem_init+0x2d3>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101043:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101048:	77 8a                	ja     f0100fd4 <mem_init+0x2f2>
			++nfree_basemem;
f010104a:	83 c7 01             	add    $0x1,%edi
f010104d:	eb 9d                	jmp    f0100fec <mem_init+0x30a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010104f:	50                   	push   %eax
f0101050:	8d 83 bc f8 fe ff    	lea    -0x10744(%ebx),%eax
f0101056:	50                   	push   %eax
f0101057:	6a 52                	push   $0x52
f0101059:	8d 83 98 fa fe ff    	lea    -0x10568(%ebx),%eax
f010105f:	50                   	push   %eax
f0101060:	e8 34 f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101065:	8d 83 bc f9 fe ff    	lea    -0x10644(%ebx),%eax
f010106b:	50                   	push   %eax
f010106c:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101072:	50                   	push   %eax
f0101073:	68 0b 02 00 00       	push   $0x20b
f0101078:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f010107e:	50                   	push   %eax
f010107f:	e8 15 f0 ff ff       	call   f0100099 <_panic>
f0101084:	8b 75 cc             	mov    -0x34(%ebp),%esi
	assert(nfree_basemem > 0);
f0101087:	85 ff                	test   %edi,%edi
f0101089:	7e 2e                	jle    f01010b9 <mem_init+0x3d7>
	assert(nfree_extmem > 0);
f010108b:	85 f6                	test   %esi,%esi
f010108d:	7e 49                	jle    f01010d8 <mem_init+0x3f6>
	cprintf("check_page_free_list() succeeded!\n");
f010108f:	83 ec 0c             	sub    $0xc,%esp
f0101092:	8d 83 04 fa fe ff    	lea    -0x105fc(%ebx),%eax
f0101098:	50                   	push   %eax
f0101099:	e8 1c 07 00 00       	call   f01017ba <cprintf>
	if (!pages)
f010109e:	83 c4 10             	add    $0x10,%esp
f01010a1:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f01010a7:	83 38 00             	cmpl   $0x0,(%eax)
f01010aa:	74 4b                	je     f01010f7 <mem_init+0x415>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010ac:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01010b2:	be 00 00 00 00       	mov    $0x0,%esi
f01010b7:	eb 5e                	jmp    f0101117 <mem_init+0x435>
	assert(nfree_basemem > 0);
f01010b9:	8d 83 4f fb fe ff    	lea    -0x104b1(%ebx),%eax
f01010bf:	50                   	push   %eax
f01010c0:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01010c6:	50                   	push   %eax
f01010c7:	68 13 02 00 00       	push   $0x213
f01010cc:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01010d2:	50                   	push   %eax
f01010d3:	e8 c1 ef ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f01010d8:	8d 83 61 fb fe ff    	lea    -0x1049f(%ebx),%eax
f01010de:	50                   	push   %eax
f01010df:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01010e5:	50                   	push   %eax
f01010e6:	68 14 02 00 00       	push   $0x214
f01010eb:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01010f1:	50                   	push   %eax
f01010f2:	e8 a2 ef ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f01010f7:	83 ec 04             	sub    $0x4,%esp
f01010fa:	8d 83 72 fb fe ff    	lea    -0x1048e(%ebx),%eax
f0101100:	50                   	push   %eax
f0101101:	68 27 02 00 00       	push   $0x227
f0101106:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f010110c:	50                   	push   %eax
f010110d:	e8 87 ef ff ff       	call   f0100099 <_panic>
		++nfree;
f0101112:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101115:	8b 00                	mov    (%eax),%eax
f0101117:	85 c0                	test   %eax,%eax
f0101119:	75 f7                	jne    f0101112 <mem_init+0x430>
	assert((pp0 = page_alloc(0)));
f010111b:	83 ec 0c             	sub    $0xc,%esp
f010111e:	6a 00                	push   $0x0
f0101120:	e8 c3 fa ff ff       	call   f0100be8 <page_alloc>
f0101125:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101128:	83 c4 10             	add    $0x10,%esp
f010112b:	85 c0                	test   %eax,%eax
f010112d:	0f 84 e7 01 00 00    	je     f010131a <mem_init+0x638>
	assert((pp1 = page_alloc(0)));
f0101133:	83 ec 0c             	sub    $0xc,%esp
f0101136:	6a 00                	push   $0x0
f0101138:	e8 ab fa ff ff       	call   f0100be8 <page_alloc>
f010113d:	89 c7                	mov    %eax,%edi
f010113f:	83 c4 10             	add    $0x10,%esp
f0101142:	85 c0                	test   %eax,%eax
f0101144:	0f 84 ef 01 00 00    	je     f0101339 <mem_init+0x657>
	assert((pp2 = page_alloc(0)));
f010114a:	83 ec 0c             	sub    $0xc,%esp
f010114d:	6a 00                	push   $0x0
f010114f:	e8 94 fa ff ff       	call   f0100be8 <page_alloc>
f0101154:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101157:	83 c4 10             	add    $0x10,%esp
f010115a:	85 c0                	test   %eax,%eax
f010115c:	0f 84 f6 01 00 00    	je     f0101358 <mem_init+0x676>
	assert(pp1 && pp1 != pp0);
f0101162:	39 7d d4             	cmp    %edi,-0x2c(%ebp)
f0101165:	0f 84 0c 02 00 00    	je     f0101377 <mem_init+0x695>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010116b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010116e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101171:	0f 84 1f 02 00 00    	je     f0101396 <mem_init+0x6b4>
f0101177:	39 c7                	cmp    %eax,%edi
f0101179:	0f 84 17 02 00 00    	je     f0101396 <mem_init+0x6b4>
	return (pp - pages) << PGSHIFT;
f010117f:	c7 c0 d0 56 11 f0    	mov    $0xf01156d0,%eax
f0101185:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101187:	c7 c0 c8 56 11 f0    	mov    $0xf01156c8,%eax
f010118d:	8b 10                	mov    (%eax),%edx
f010118f:	c1 e2 0c             	shl    $0xc,%edx
f0101192:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101195:	29 c8                	sub    %ecx,%eax
f0101197:	c1 f8 03             	sar    $0x3,%eax
f010119a:	c1 e0 0c             	shl    $0xc,%eax
f010119d:	39 d0                	cmp    %edx,%eax
f010119f:	0f 83 10 02 00 00    	jae    f01013b5 <mem_init+0x6d3>
f01011a5:	89 f8                	mov    %edi,%eax
f01011a7:	29 c8                	sub    %ecx,%eax
f01011a9:	c1 f8 03             	sar    $0x3,%eax
f01011ac:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01011af:	39 c2                	cmp    %eax,%edx
f01011b1:	0f 86 1d 02 00 00    	jbe    f01013d4 <mem_init+0x6f2>
f01011b7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01011ba:	29 c8                	sub    %ecx,%eax
f01011bc:	c1 f8 03             	sar    $0x3,%eax
f01011bf:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01011c2:	39 c2                	cmp    %eax,%edx
f01011c4:	0f 86 29 02 00 00    	jbe    f01013f3 <mem_init+0x711>
	fl = page_free_list;
f01011ca:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f01011d0:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f01011d3:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f01011da:	00 00 00 
	assert(!page_alloc(0));
f01011dd:	83 ec 0c             	sub    $0xc,%esp
f01011e0:	6a 00                	push   $0x0
f01011e2:	e8 01 fa ff ff       	call   f0100be8 <page_alloc>
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	0f 85 20 02 00 00    	jne    f0101412 <mem_init+0x730>
	page_free(pp0);
f01011f2:	83 ec 0c             	sub    $0xc,%esp
f01011f5:	ff 75 d4             	pushl  -0x2c(%ebp)
f01011f8:	e8 73 fa ff ff       	call   f0100c70 <page_free>
	page_free(pp1);
f01011fd:	89 3c 24             	mov    %edi,(%esp)
f0101200:	e8 6b fa ff ff       	call   f0100c70 <page_free>
	page_free(pp2);
f0101205:	83 c4 04             	add    $0x4,%esp
f0101208:	ff 75 d0             	pushl  -0x30(%ebp)
f010120b:	e8 60 fa ff ff       	call   f0100c70 <page_free>
	assert((pp0 = page_alloc(0)));
f0101210:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101217:	e8 cc f9 ff ff       	call   f0100be8 <page_alloc>
f010121c:	89 c7                	mov    %eax,%edi
f010121e:	83 c4 10             	add    $0x10,%esp
f0101221:	85 c0                	test   %eax,%eax
f0101223:	0f 84 08 02 00 00    	je     f0101431 <mem_init+0x74f>
	assert((pp1 = page_alloc(0)));
f0101229:	83 ec 0c             	sub    $0xc,%esp
f010122c:	6a 00                	push   $0x0
f010122e:	e8 b5 f9 ff ff       	call   f0100be8 <page_alloc>
f0101233:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101236:	83 c4 10             	add    $0x10,%esp
f0101239:	85 c0                	test   %eax,%eax
f010123b:	0f 84 0f 02 00 00    	je     f0101450 <mem_init+0x76e>
	assert((pp2 = page_alloc(0)));
f0101241:	83 ec 0c             	sub    $0xc,%esp
f0101244:	6a 00                	push   $0x0
f0101246:	e8 9d f9 ff ff       	call   f0100be8 <page_alloc>
f010124b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010124e:	83 c4 10             	add    $0x10,%esp
f0101251:	85 c0                	test   %eax,%eax
f0101253:	0f 84 16 02 00 00    	je     f010146f <mem_init+0x78d>
	assert(pp1 && pp1 != pp0);
f0101259:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010125c:	0f 84 2c 02 00 00    	je     f010148e <mem_init+0x7ac>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101262:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101265:	39 c7                	cmp    %eax,%edi
f0101267:	0f 84 40 02 00 00    	je     f01014ad <mem_init+0x7cb>
f010126d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101270:	0f 84 37 02 00 00    	je     f01014ad <mem_init+0x7cb>
	assert(!page_alloc(0));
f0101276:	83 ec 0c             	sub    $0xc,%esp
f0101279:	6a 00                	push   $0x0
f010127b:	e8 68 f9 ff ff       	call   f0100be8 <page_alloc>
f0101280:	83 c4 10             	add    $0x10,%esp
f0101283:	85 c0                	test   %eax,%eax
f0101285:	0f 85 41 02 00 00    	jne    f01014cc <mem_init+0x7ea>
	memset(page2kva(pp0), 1, PGSIZE);
f010128b:	89 f8                	mov    %edi,%eax
f010128d:	e8 77 f7 ff ff       	call   f0100a09 <page2kva>
f0101292:	83 ec 04             	sub    $0x4,%esp
f0101295:	68 00 10 00 00       	push   $0x1000
f010129a:	6a 01                	push   $0x1
f010129c:	50                   	push   %eax
f010129d:	e8 74 10 00 00       	call   f0102316 <memset>
	page_free(pp0);
f01012a2:	89 3c 24             	mov    %edi,(%esp)
f01012a5:	e8 c6 f9 ff ff       	call   f0100c70 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01012aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01012b1:	e8 32 f9 ff ff       	call   f0100be8 <page_alloc>
f01012b6:	83 c4 10             	add    $0x10,%esp
f01012b9:	85 c0                	test   %eax,%eax
f01012bb:	0f 84 2a 02 00 00    	je     f01014eb <mem_init+0x809>
	assert(pp && pp0 == pp);
f01012c1:	39 c7                	cmp    %eax,%edi
f01012c3:	0f 85 41 02 00 00    	jne    f010150a <mem_init+0x828>
	c = page2kva(pp);
f01012c9:	e8 3b f7 ff ff       	call   f0100a09 <page2kva>
f01012ce:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
		assert(c[i] == 0);
f01012d4:	80 38 00             	cmpb   $0x0,(%eax)
f01012d7:	0f 85 4c 02 00 00    	jne    f0101529 <mem_init+0x847>
f01012dd:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01012e0:	39 c2                	cmp    %eax,%edx
f01012e2:	75 f0                	jne    f01012d4 <mem_init+0x5f2>
	page_free_list = fl;
f01012e4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01012e7:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
	page_free(pp0);
f01012ed:	83 ec 0c             	sub    $0xc,%esp
f01012f0:	57                   	push   %edi
f01012f1:	e8 7a f9 ff ff       	call   f0100c70 <page_free>
	page_free(pp1);
f01012f6:	83 c4 04             	add    $0x4,%esp
f01012f9:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012fc:	e8 6f f9 ff ff       	call   f0100c70 <page_free>
	page_free(pp2);
f0101301:	83 c4 04             	add    $0x4,%esp
f0101304:	ff 75 d0             	pushl  -0x30(%ebp)
f0101307:	e8 64 f9 ff ff       	call   f0100c70 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010130c:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
f0101312:	83 c4 10             	add    $0x10,%esp
f0101315:	e9 33 02 00 00       	jmp    f010154d <mem_init+0x86b>
	assert((pp0 = page_alloc(0)));
f010131a:	8d 83 8d fb fe ff    	lea    -0x10473(%ebx),%eax
f0101320:	50                   	push   %eax
f0101321:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101327:	50                   	push   %eax
f0101328:	68 2f 02 00 00       	push   $0x22f
f010132d:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101333:	50                   	push   %eax
f0101334:	e8 60 ed ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101339:	8d 83 a3 fb fe ff    	lea    -0x1045d(%ebx),%eax
f010133f:	50                   	push   %eax
f0101340:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101346:	50                   	push   %eax
f0101347:	68 30 02 00 00       	push   $0x230
f010134c:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101352:	50                   	push   %eax
f0101353:	e8 41 ed ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101358:	8d 83 b9 fb fe ff    	lea    -0x10447(%ebx),%eax
f010135e:	50                   	push   %eax
f010135f:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101365:	50                   	push   %eax
f0101366:	68 31 02 00 00       	push   $0x231
f010136b:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101371:	50                   	push   %eax
f0101372:	e8 22 ed ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101377:	8d 83 cf fb fe ff    	lea    -0x10431(%ebx),%eax
f010137d:	50                   	push   %eax
f010137e:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101384:	50                   	push   %eax
f0101385:	68 34 02 00 00       	push   $0x234
f010138a:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101390:	50                   	push   %eax
f0101391:	e8 03 ed ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101396:	8d 83 28 fa fe ff    	lea    -0x105d8(%ebx),%eax
f010139c:	50                   	push   %eax
f010139d:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01013a3:	50                   	push   %eax
f01013a4:	68 35 02 00 00       	push   $0x235
f01013a9:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01013af:	50                   	push   %eax
f01013b0:	e8 e4 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01013b5:	8d 83 e1 fb fe ff    	lea    -0x1041f(%ebx),%eax
f01013bb:	50                   	push   %eax
f01013bc:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01013c2:	50                   	push   %eax
f01013c3:	68 36 02 00 00       	push   $0x236
f01013c8:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01013ce:	50                   	push   %eax
f01013cf:	e8 c5 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01013d4:	8d 83 fe fb fe ff    	lea    -0x10402(%ebx),%eax
f01013da:	50                   	push   %eax
f01013db:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01013e1:	50                   	push   %eax
f01013e2:	68 37 02 00 00       	push   $0x237
f01013e7:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01013ed:	50                   	push   %eax
f01013ee:	e8 a6 ec ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013f3:	8d 83 1b fc fe ff    	lea    -0x103e5(%ebx),%eax
f01013f9:	50                   	push   %eax
f01013fa:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101400:	50                   	push   %eax
f0101401:	68 38 02 00 00       	push   $0x238
f0101406:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f010140c:	50                   	push   %eax
f010140d:	e8 87 ec ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101412:	8d 83 38 fc fe ff    	lea    -0x103c8(%ebx),%eax
f0101418:	50                   	push   %eax
f0101419:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010141f:	50                   	push   %eax
f0101420:	68 3f 02 00 00       	push   $0x23f
f0101425:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f010142b:	50                   	push   %eax
f010142c:	e8 68 ec ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101431:	8d 83 8d fb fe ff    	lea    -0x10473(%ebx),%eax
f0101437:	50                   	push   %eax
f0101438:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010143e:	50                   	push   %eax
f010143f:	68 46 02 00 00       	push   $0x246
f0101444:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f010144a:	50                   	push   %eax
f010144b:	e8 49 ec ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101450:	8d 83 a3 fb fe ff    	lea    -0x1045d(%ebx),%eax
f0101456:	50                   	push   %eax
f0101457:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010145d:	50                   	push   %eax
f010145e:	68 47 02 00 00       	push   $0x247
f0101463:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101469:	50                   	push   %eax
f010146a:	e8 2a ec ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010146f:	8d 83 b9 fb fe ff    	lea    -0x10447(%ebx),%eax
f0101475:	50                   	push   %eax
f0101476:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010147c:	50                   	push   %eax
f010147d:	68 48 02 00 00       	push   $0x248
f0101482:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101488:	50                   	push   %eax
f0101489:	e8 0b ec ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010148e:	8d 83 cf fb fe ff    	lea    -0x10431(%ebx),%eax
f0101494:	50                   	push   %eax
f0101495:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010149b:	50                   	push   %eax
f010149c:	68 4a 02 00 00       	push   $0x24a
f01014a1:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01014a7:	50                   	push   %eax
f01014a8:	e8 ec eb ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014ad:	8d 83 28 fa fe ff    	lea    -0x105d8(%ebx),%eax
f01014b3:	50                   	push   %eax
f01014b4:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01014ba:	50                   	push   %eax
f01014bb:	68 4b 02 00 00       	push   $0x24b
f01014c0:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01014c6:	50                   	push   %eax
f01014c7:	e8 cd eb ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01014cc:	8d 83 38 fc fe ff    	lea    -0x103c8(%ebx),%eax
f01014d2:	50                   	push   %eax
f01014d3:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01014d9:	50                   	push   %eax
f01014da:	68 4c 02 00 00       	push   $0x24c
f01014df:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01014e5:	50                   	push   %eax
f01014e6:	e8 ae eb ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014eb:	8d 83 47 fc fe ff    	lea    -0x103b9(%ebx),%eax
f01014f1:	50                   	push   %eax
f01014f2:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01014f8:	50                   	push   %eax
f01014f9:	68 51 02 00 00       	push   $0x251
f01014fe:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101504:	50                   	push   %eax
f0101505:	e8 8f eb ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f010150a:	8d 83 65 fc fe ff    	lea    -0x1039b(%ebx),%eax
f0101510:	50                   	push   %eax
f0101511:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101517:	50                   	push   %eax
f0101518:	68 52 02 00 00       	push   $0x252
f010151d:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101523:	50                   	push   %eax
f0101524:	e8 70 eb ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101529:	8d 83 75 fc fe ff    	lea    -0x1038b(%ebx),%eax
f010152f:	50                   	push   %eax
f0101530:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101536:	50                   	push   %eax
f0101537:	68 55 02 00 00       	push   $0x255
f010153c:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101542:	50                   	push   %eax
f0101543:	e8 51 eb ff ff       	call   f0100099 <_panic>
		--nfree;
f0101548:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010154b:	8b 00                	mov    (%eax),%eax
f010154d:	85 c0                	test   %eax,%eax
f010154f:	75 f7                	jne    f0101548 <mem_init+0x866>
	assert(nfree == 0);
f0101551:	85 f6                	test   %esi,%esi
f0101553:	0f 85 83 00 00 00    	jne    f01015dc <mem_init+0x8fa>
	cprintf("check_page_alloc() succeeded!\n");
f0101559:	83 ec 0c             	sub    $0xc,%esp
f010155c:	8d 83 48 fa fe ff    	lea    -0x105b8(%ebx),%eax
f0101562:	50                   	push   %eax
f0101563:	e8 52 02 00 00       	call   f01017ba <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101568:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156f:	e8 74 f6 ff ff       	call   f0100be8 <page_alloc>
f0101574:	89 c7                	mov    %eax,%edi
f0101576:	83 c4 10             	add    $0x10,%esp
f0101579:	85 c0                	test   %eax,%eax
f010157b:	74 7e                	je     f01015fb <mem_init+0x919>
	assert((pp1 = page_alloc(0)));
f010157d:	83 ec 0c             	sub    $0xc,%esp
f0101580:	6a 00                	push   $0x0
f0101582:	e8 61 f6 ff ff       	call   f0100be8 <page_alloc>
f0101587:	89 c6                	mov    %eax,%esi
f0101589:	83 c4 10             	add    $0x10,%esp
f010158c:	85 c0                	test   %eax,%eax
f010158e:	0f 84 86 00 00 00    	je     f010161a <mem_init+0x938>
	assert((pp2 = page_alloc(0)));
f0101594:	83 ec 0c             	sub    $0xc,%esp
f0101597:	6a 00                	push   $0x0
f0101599:	e8 4a f6 ff ff       	call   f0100be8 <page_alloc>
f010159e:	83 c4 10             	add    $0x10,%esp
f01015a1:	85 c0                	test   %eax,%eax
f01015a3:	0f 84 90 00 00 00    	je     f0101639 <mem_init+0x957>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015a9:	39 f7                	cmp    %esi,%edi
f01015ab:	0f 84 a7 00 00 00    	je     f0101658 <mem_init+0x976>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015b1:	39 c7                	cmp    %eax,%edi
f01015b3:	74 08                	je     f01015bd <mem_init+0x8db>
f01015b5:	39 c6                	cmp    %eax,%esi
f01015b7:	0f 85 ba 00 00 00    	jne    f0101677 <mem_init+0x995>
f01015bd:	8d 83 28 fa fe ff    	lea    -0x105d8(%ebx),%eax
f01015c3:	50                   	push   %eax
f01015c4:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01015ca:	50                   	push   %eax
f01015cb:	68 c1 02 00 00       	push   $0x2c1
f01015d0:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01015d6:	50                   	push   %eax
f01015d7:	e8 bd ea ff ff       	call   f0100099 <_panic>
	assert(nfree == 0);
f01015dc:	8d 83 7f fc fe ff    	lea    -0x10381(%ebx),%eax
f01015e2:	50                   	push   %eax
f01015e3:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01015e9:	50                   	push   %eax
f01015ea:	68 62 02 00 00       	push   $0x262
f01015ef:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01015f5:	50                   	push   %eax
f01015f6:	e8 9e ea ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01015fb:	8d 83 8d fb fe ff    	lea    -0x10473(%ebx),%eax
f0101601:	50                   	push   %eax
f0101602:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101608:	50                   	push   %eax
f0101609:	68 bb 02 00 00       	push   $0x2bb
f010160e:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101614:	50                   	push   %eax
f0101615:	e8 7f ea ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010161a:	8d 83 a3 fb fe ff    	lea    -0x1045d(%ebx),%eax
f0101620:	50                   	push   %eax
f0101621:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101627:	50                   	push   %eax
f0101628:	68 bc 02 00 00       	push   $0x2bc
f010162d:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101633:	50                   	push   %eax
f0101634:	e8 60 ea ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101639:	8d 83 b9 fb fe ff    	lea    -0x10447(%ebx),%eax
f010163f:	50                   	push   %eax
f0101640:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101646:	50                   	push   %eax
f0101647:	68 bd 02 00 00       	push   $0x2bd
f010164c:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101652:	50                   	push   %eax
f0101653:	e8 41 ea ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101658:	8d 83 cf fb fe ff    	lea    -0x10431(%ebx),%eax
f010165e:	50                   	push   %eax
f010165f:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f0101665:	50                   	push   %eax
f0101666:	68 c0 02 00 00       	push   $0x2c0
f010166b:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f0101671:	50                   	push   %eax
f0101672:	e8 22 ea ff ff       	call   f0100099 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101677:	c7 83 94 1f 00 00 00 	movl   $0x0,0x1f94(%ebx)
f010167e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101681:	83 ec 0c             	sub    $0xc,%esp
f0101684:	6a 00                	push   $0x0
f0101686:	e8 5d f5 ff ff       	call   f0100be8 <page_alloc>
f010168b:	83 c4 10             	add    $0x10,%esp
f010168e:	85 c0                	test   %eax,%eax
f0101690:	74 1f                	je     f01016b1 <mem_init+0x9cf>
f0101692:	8d 83 38 fc fe ff    	lea    -0x103c8(%ebx),%eax
f0101698:	50                   	push   %eax
f0101699:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f010169f:	50                   	push   %eax
f01016a0:	68 c8 02 00 00       	push   $0x2c8
f01016a5:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01016ab:	50                   	push   %eax
f01016ac:	e8 e8 e9 ff ff       	call   f0100099 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01016b1:	8d 83 68 fa fe ff    	lea    -0x10598(%ebx),%eax
f01016b7:	50                   	push   %eax
f01016b8:	8d 83 c2 fa fe ff    	lea    -0x1053e(%ebx),%eax
f01016be:	50                   	push   %eax
f01016bf:	68 ce 02 00 00       	push   $0x2ce
f01016c4:	8d 83 a6 fa fe ff    	lea    -0x1055a(%ebx),%eax
f01016ca:	50                   	push   %eax
f01016cb:	e8 c9 e9 ff ff       	call   f0100099 <_panic>

f01016d0 <page_decref>:
{
f01016d0:	55                   	push   %ebp
f01016d1:	89 e5                	mov    %esp,%ebp
f01016d3:	83 ec 08             	sub    $0x8,%esp
f01016d6:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01016d9:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01016dd:	83 e8 01             	sub    $0x1,%eax
f01016e0:	66 89 42 04          	mov    %ax,0x4(%edx)
f01016e4:	66 85 c0             	test   %ax,%ax
f01016e7:	74 02                	je     f01016eb <page_decref+0x1b>
}
f01016e9:	c9                   	leave  
f01016ea:	c3                   	ret    
		page_free(pp);
f01016eb:	83 ec 0c             	sub    $0xc,%esp
f01016ee:	52                   	push   %edx
f01016ef:	e8 7c f5 ff ff       	call   f0100c70 <page_free>
f01016f4:	83 c4 10             	add    $0x10,%esp
}
f01016f7:	eb f0                	jmp    f01016e9 <page_decref+0x19>

f01016f9 <pgdir_walk>:
{
f01016f9:	55                   	push   %ebp
f01016fa:	89 e5                	mov    %esp,%ebp
}
f01016fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101701:	5d                   	pop    %ebp
f0101702:	c3                   	ret    

f0101703 <page_insert>:
{
f0101703:	55                   	push   %ebp
f0101704:	89 e5                	mov    %esp,%ebp
}
f0101706:	b8 00 00 00 00       	mov    $0x0,%eax
f010170b:	5d                   	pop    %ebp
f010170c:	c3                   	ret    

f010170d <page_lookup>:
{
f010170d:	55                   	push   %ebp
f010170e:	89 e5                	mov    %esp,%ebp
}
f0101710:	b8 00 00 00 00       	mov    $0x0,%eax
f0101715:	5d                   	pop    %ebp
f0101716:	c3                   	ret    

f0101717 <page_remove>:
{
f0101717:	55                   	push   %ebp
f0101718:	89 e5                	mov    %esp,%ebp
}
f010171a:	5d                   	pop    %ebp
f010171b:	c3                   	ret    

f010171c <tlb_invalidate>:
{
f010171c:	55                   	push   %ebp
f010171d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010171f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101722:	0f 01 38             	invlpg (%eax)
}
f0101725:	5d                   	pop    %ebp
f0101726:	c3                   	ret    

f0101727 <__x86.get_pc_thunk.dx>:
f0101727:	8b 14 24             	mov    (%esp),%edx
f010172a:	c3                   	ret    

f010172b <__x86.get_pc_thunk.cx>:
f010172b:	8b 0c 24             	mov    (%esp),%ecx
f010172e:	c3                   	ret    

f010172f <__x86.get_pc_thunk.si>:
f010172f:	8b 34 24             	mov    (%esp),%esi
f0101732:	c3                   	ret    

f0101733 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101733:	55                   	push   %ebp
f0101734:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101736:	8b 45 08             	mov    0x8(%ebp),%eax
f0101739:	ba 70 00 00 00       	mov    $0x70,%edx
f010173e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010173f:	ba 71 00 00 00       	mov    $0x71,%edx
f0101744:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101745:	0f b6 c0             	movzbl %al,%eax
}
f0101748:	5d                   	pop    %ebp
f0101749:	c3                   	ret    

f010174a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010174a:	55                   	push   %ebp
f010174b:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010174d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101750:	ba 70 00 00 00       	mov    $0x70,%edx
f0101755:	ee                   	out    %al,(%dx)
f0101756:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101759:	ba 71 00 00 00       	mov    $0x71,%edx
f010175e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010175f:	5d                   	pop    %ebp
f0101760:	c3                   	ret    

f0101761 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101761:	55                   	push   %ebp
f0101762:	89 e5                	mov    %esp,%ebp
f0101764:	53                   	push   %ebx
f0101765:	83 ec 10             	sub    $0x10,%esp
f0101768:	e8 e2 e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010176d:	81 c3 9b 1b 01 00    	add    $0x11b9b,%ebx
	cputchar(ch);
f0101773:	ff 75 08             	pushl  0x8(%ebp)
f0101776:	e8 4b ef ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f010177b:	83 c4 10             	add    $0x10,%esp
f010177e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101781:	c9                   	leave  
f0101782:	c3                   	ret    

f0101783 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101783:	55                   	push   %ebp
f0101784:	89 e5                	mov    %esp,%ebp
f0101786:	53                   	push   %ebx
f0101787:	83 ec 14             	sub    $0x14,%esp
f010178a:	e8 c0 e9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010178f:	81 c3 79 1b 01 00    	add    $0x11b79,%ebx
	int cnt = 0;
f0101795:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010179c:	ff 75 0c             	pushl  0xc(%ebp)
f010179f:	ff 75 08             	pushl  0x8(%ebp)
f01017a2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01017a5:	50                   	push   %eax
f01017a6:	8d 83 59 e4 fe ff    	lea    -0x11ba7(%ebx),%eax
f01017ac:	50                   	push   %eax
f01017ad:	e8 18 04 00 00       	call   f0101bca <vprintfmt>
	return cnt;
}
f01017b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017b8:	c9                   	leave  
f01017b9:	c3                   	ret    

f01017ba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01017ba:	55                   	push   %ebp
f01017bb:	89 e5                	mov    %esp,%ebp
f01017bd:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01017c0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01017c3:	50                   	push   %eax
f01017c4:	ff 75 08             	pushl  0x8(%ebp)
f01017c7:	e8 b7 ff ff ff       	call   f0101783 <vcprintf>
	va_end(ap);

	return cnt;
}
f01017cc:	c9                   	leave  
f01017cd:	c3                   	ret    

f01017ce <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01017ce:	55                   	push   %ebp
f01017cf:	89 e5                	mov    %esp,%ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	53                   	push   %ebx
f01017d4:	83 ec 14             	sub    $0x14,%esp
f01017d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01017da:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01017dd:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01017e0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01017e3:	8b 32                	mov    (%edx),%esi
f01017e5:	8b 01                	mov    (%ecx),%eax
f01017e7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01017ea:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01017f1:	eb 2f                	jmp    f0101822 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01017f3:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01017f6:	39 c6                	cmp    %eax,%esi
f01017f8:	7f 49                	jg     f0101843 <stab_binsearch+0x75>
f01017fa:	0f b6 0a             	movzbl (%edx),%ecx
f01017fd:	83 ea 0c             	sub    $0xc,%edx
f0101800:	39 f9                	cmp    %edi,%ecx
f0101802:	75 ef                	jne    f01017f3 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101804:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101807:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010180a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010180e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0101811:	73 35                	jae    f0101848 <stab_binsearch+0x7a>
			*region_left = m;
f0101813:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101816:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0101818:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010181b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0101822:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0101825:	7f 4e                	jg     f0101875 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0101827:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010182a:	01 f0                	add    %esi,%eax
f010182c:	89 c3                	mov    %eax,%ebx
f010182e:	c1 eb 1f             	shr    $0x1f,%ebx
f0101831:	01 c3                	add    %eax,%ebx
f0101833:	d1 fb                	sar    %ebx
f0101835:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0101838:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010183b:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010183f:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0101841:	eb b3                	jmp    f01017f6 <stab_binsearch+0x28>
			l = true_m + 1;
f0101843:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0101846:	eb da                	jmp    f0101822 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0101848:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010184b:	76 14                	jbe    f0101861 <stab_binsearch+0x93>
			*region_right = m - 1;
f010184d:	83 e8 01             	sub    $0x1,%eax
f0101850:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101853:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101856:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0101858:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010185f:	eb c1                	jmp    f0101822 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101861:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101864:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0101866:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010186a:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010186c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0101873:	eb ad                	jmp    f0101822 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0101875:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101879:	74 16                	je     f0101891 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010187b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010187e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101880:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101883:	8b 0e                	mov    (%esi),%ecx
f0101885:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101888:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010188b:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010188f:	eb 12                	jmp    f01018a3 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0101891:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101894:	8b 00                	mov    (%eax),%eax
f0101896:	83 e8 01             	sub    $0x1,%eax
f0101899:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010189c:	89 07                	mov    %eax,(%edi)
f010189e:	eb 16                	jmp    f01018b6 <stab_binsearch+0xe8>
		     l--)
f01018a0:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01018a3:	39 c1                	cmp    %eax,%ecx
f01018a5:	7d 0a                	jge    f01018b1 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01018a7:	0f b6 1a             	movzbl (%edx),%ebx
f01018aa:	83 ea 0c             	sub    $0xc,%edx
f01018ad:	39 fb                	cmp    %edi,%ebx
f01018af:	75 ef                	jne    f01018a0 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01018b1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01018b4:	89 07                	mov    %eax,(%edi)
	}
}
f01018b6:	83 c4 14             	add    $0x14,%esp
f01018b9:	5b                   	pop    %ebx
f01018ba:	5e                   	pop    %esi
f01018bb:	5f                   	pop    %edi
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    

f01018be <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01018be:	55                   	push   %ebp
f01018bf:	89 e5                	mov    %esp,%ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	53                   	push   %ebx
f01018c4:	83 ec 2c             	sub    $0x2c,%esp
f01018c7:	e8 5f fe ff ff       	call   f010172b <__x86.get_pc_thunk.cx>
f01018cc:	81 c1 3c 1a 01 00    	add    $0x11a3c,%ecx
f01018d2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01018d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01018d8:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01018db:	8d 81 8a fc fe ff    	lea    -0x10376(%ecx),%eax
f01018e1:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f01018e3:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01018ea:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f01018ed:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01018f4:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f01018f7:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01018fe:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0101904:	0f 86 f4 00 00 00    	jbe    f01019fe <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010190a:	c7 c0 7d 82 10 f0    	mov    $0xf010827d,%eax
f0101910:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0101916:	0f 86 88 01 00 00    	jbe    f0101aa4 <debuginfo_eip+0x1e6>
f010191c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010191f:	c7 c0 bb 9f 10 f0    	mov    $0xf0109fbb,%eax
f0101925:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0101929:	0f 85 7c 01 00 00    	jne    f0101aab <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010192f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0101936:	c7 c0 ac 31 10 f0    	mov    $0xf01031ac,%eax
f010193c:	c7 c2 7c 82 10 f0    	mov    $0xf010827c,%edx
f0101942:	29 c2                	sub    %eax,%edx
f0101944:	c1 fa 02             	sar    $0x2,%edx
f0101947:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010194d:	83 ea 01             	sub    $0x1,%edx
f0101950:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0101953:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0101956:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0101959:	83 ec 08             	sub    $0x8,%esp
f010195c:	53                   	push   %ebx
f010195d:	6a 64                	push   $0x64
f010195f:	e8 6a fe ff ff       	call   f01017ce <stab_binsearch>
	if (lfile == 0)
f0101964:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101967:	83 c4 10             	add    $0x10,%esp
f010196a:	85 c0                	test   %eax,%eax
f010196c:	0f 84 40 01 00 00    	je     f0101ab2 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101972:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0101975:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101978:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010197b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010197e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101981:	83 ec 08             	sub    $0x8,%esp
f0101984:	53                   	push   %ebx
f0101985:	6a 24                	push   $0x24
f0101987:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010198a:	c7 c0 ac 31 10 f0    	mov    $0xf01031ac,%eax
f0101990:	e8 39 fe ff ff       	call   f01017ce <stab_binsearch>

	if (lfun <= rfun) {
f0101995:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101998:	83 c4 10             	add    $0x10,%esp
f010199b:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f010199e:	7f 79                	jg     f0101a19 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01019a0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01019a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019a6:	c7 c2 ac 31 10 f0    	mov    $0xf01031ac,%edx
f01019ac:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f01019af:	8b 11                	mov    (%ecx),%edx
f01019b1:	c7 c0 bb 9f 10 f0    	mov    $0xf0109fbb,%eax
f01019b7:	81 e8 7d 82 10 f0    	sub    $0xf010827d,%eax
f01019bd:	39 c2                	cmp    %eax,%edx
f01019bf:	73 09                	jae    f01019ca <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01019c1:	81 c2 7d 82 10 f0    	add    $0xf010827d,%edx
f01019c7:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01019ca:	8b 41 08             	mov    0x8(%ecx),%eax
f01019cd:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01019d0:	83 ec 08             	sub    $0x8,%esp
f01019d3:	6a 3a                	push   $0x3a
f01019d5:	ff 77 08             	pushl  0x8(%edi)
f01019d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019db:	e8 1a 09 00 00       	call   f01022fa <strfind>
f01019e0:	2b 47 08             	sub    0x8(%edi),%eax
f01019e3:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01019e6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01019e9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01019ec:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01019ef:	c7 c2 ac 31 10 f0    	mov    $0xf01031ac,%edx
f01019f5:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f01019f9:	83 c4 10             	add    $0x10,%esp
f01019fc:	eb 29                	jmp    f0101a27 <debuginfo_eip+0x169>
  	        panic("User address");
f01019fe:	83 ec 04             	sub    $0x4,%esp
f0101a01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a04:	8d 83 94 fc fe ff    	lea    -0x1036c(%ebx),%eax
f0101a0a:	50                   	push   %eax
f0101a0b:	6a 7f                	push   $0x7f
f0101a0d:	8d 83 a1 fc fe ff    	lea    -0x1035f(%ebx),%eax
f0101a13:	50                   	push   %eax
f0101a14:	e8 80 e6 ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0101a19:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0101a1c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101a1f:	eb af                	jmp    f01019d0 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101a21:	83 ee 01             	sub    $0x1,%esi
f0101a24:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0101a27:	39 f3                	cmp    %esi,%ebx
f0101a29:	7f 3a                	jg     f0101a65 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0101a2b:	0f b6 10             	movzbl (%eax),%edx
f0101a2e:	80 fa 84             	cmp    $0x84,%dl
f0101a31:	74 0b                	je     f0101a3e <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101a33:	80 fa 64             	cmp    $0x64,%dl
f0101a36:	75 e9                	jne    f0101a21 <debuginfo_eip+0x163>
f0101a38:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0101a3c:	74 e3                	je     f0101a21 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101a3e:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0101a41:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a44:	c7 c0 ac 31 10 f0    	mov    $0xf01031ac,%eax
f0101a4a:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0101a4d:	c7 c0 bb 9f 10 f0    	mov    $0xf0109fbb,%eax
f0101a53:	81 e8 7d 82 10 f0    	sub    $0xf010827d,%eax
f0101a59:	39 c2                	cmp    %eax,%edx
f0101a5b:	73 08                	jae    f0101a65 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101a5d:	81 c2 7d 82 10 f0    	add    $0xf010827d,%edx
f0101a63:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101a65:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101a68:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101a6b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0101a70:	39 cb                	cmp    %ecx,%ebx
f0101a72:	7d 4a                	jge    f0101abe <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0101a74:	8d 53 01             	lea    0x1(%ebx),%edx
f0101a77:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0101a7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a7d:	c7 c0 ac 31 10 f0    	mov    $0xf01031ac,%eax
f0101a83:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0101a87:	eb 07                	jmp    f0101a90 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0101a89:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0101a8d:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0101a90:	39 d1                	cmp    %edx,%ecx
f0101a92:	74 25                	je     f0101ab9 <debuginfo_eip+0x1fb>
f0101a94:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101a97:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0101a9b:	74 ec                	je     f0101a89 <debuginfo_eip+0x1cb>
	return 0;
f0101a9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101aa2:	eb 1a                	jmp    f0101abe <debuginfo_eip+0x200>
		return -1;
f0101aa4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101aa9:	eb 13                	jmp    f0101abe <debuginfo_eip+0x200>
f0101aab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101ab0:	eb 0c                	jmp    f0101abe <debuginfo_eip+0x200>
		return -1;
f0101ab2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101ab7:	eb 05                	jmp    f0101abe <debuginfo_eip+0x200>
	return 0;
f0101ab9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101abe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ac1:	5b                   	pop    %ebx
f0101ac2:	5e                   	pop    %esi
f0101ac3:	5f                   	pop    %edi
f0101ac4:	5d                   	pop    %ebp
f0101ac5:	c3                   	ret    

f0101ac6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101ac6:	55                   	push   %ebp
f0101ac7:	89 e5                	mov    %esp,%ebp
f0101ac9:	57                   	push   %edi
f0101aca:	56                   	push   %esi
f0101acb:	53                   	push   %ebx
f0101acc:	83 ec 2c             	sub    $0x2c,%esp
f0101acf:	e8 57 fc ff ff       	call   f010172b <__x86.get_pc_thunk.cx>
f0101ad4:	81 c1 34 18 01 00    	add    $0x11834,%ecx
f0101ada:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101add:	89 c7                	mov    %eax,%edi
f0101adf:	89 d6                	mov    %edx,%esi
f0101ae1:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ae4:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101ae7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101aea:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101aed:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101af0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101af5:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0101af8:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101afb:	39 d3                	cmp    %edx,%ebx
f0101afd:	72 09                	jb     f0101b08 <printnum+0x42>
f0101aff:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101b02:	0f 87 83 00 00 00    	ja     f0101b8b <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0101b08:	83 ec 0c             	sub    $0xc,%esp
f0101b0b:	ff 75 18             	pushl  0x18(%ebp)
f0101b0e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b11:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0101b14:	53                   	push   %ebx
f0101b15:	ff 75 10             	pushl  0x10(%ebp)
f0101b18:	83 ec 08             	sub    $0x8,%esp
f0101b1b:	ff 75 dc             	pushl  -0x24(%ebp)
f0101b1e:	ff 75 d8             	pushl  -0x28(%ebp)
f0101b21:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b24:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b27:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101b2a:	e8 f1 09 00 00       	call   f0102520 <__udivdi3>
f0101b2f:	83 c4 18             	add    $0x18,%esp
f0101b32:	52                   	push   %edx
f0101b33:	50                   	push   %eax
f0101b34:	89 f2                	mov    %esi,%edx
f0101b36:	89 f8                	mov    %edi,%eax
f0101b38:	e8 89 ff ff ff       	call   f0101ac6 <printnum>
f0101b3d:	83 c4 20             	add    $0x20,%esp
f0101b40:	eb 13                	jmp    f0101b55 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101b42:	83 ec 08             	sub    $0x8,%esp
f0101b45:	56                   	push   %esi
f0101b46:	ff 75 18             	pushl  0x18(%ebp)
f0101b49:	ff d7                	call   *%edi
f0101b4b:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0101b4e:	83 eb 01             	sub    $0x1,%ebx
f0101b51:	85 db                	test   %ebx,%ebx
f0101b53:	7f ed                	jg     f0101b42 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101b55:	83 ec 08             	sub    $0x8,%esp
f0101b58:	56                   	push   %esi
f0101b59:	83 ec 04             	sub    $0x4,%esp
f0101b5c:	ff 75 dc             	pushl  -0x24(%ebp)
f0101b5f:	ff 75 d8             	pushl  -0x28(%ebp)
f0101b62:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b65:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b68:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101b6b:	89 f3                	mov    %esi,%ebx
f0101b6d:	e8 ce 0a 00 00       	call   f0102640 <__umoddi3>
f0101b72:	83 c4 14             	add    $0x14,%esp
f0101b75:	0f be 84 06 af fc fe 	movsbl -0x10351(%esi,%eax,1),%eax
f0101b7c:	ff 
f0101b7d:	50                   	push   %eax
f0101b7e:	ff d7                	call   *%edi
}
f0101b80:	83 c4 10             	add    $0x10,%esp
f0101b83:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b86:	5b                   	pop    %ebx
f0101b87:	5e                   	pop    %esi
f0101b88:	5f                   	pop    %edi
f0101b89:	5d                   	pop    %ebp
f0101b8a:	c3                   	ret    
f0101b8b:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101b8e:	eb be                	jmp    f0101b4e <printnum+0x88>

f0101b90 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101b90:	55                   	push   %ebp
f0101b91:	89 e5                	mov    %esp,%ebp
f0101b93:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0101b96:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101b9a:	8b 10                	mov    (%eax),%edx
f0101b9c:	3b 50 04             	cmp    0x4(%eax),%edx
f0101b9f:	73 0a                	jae    f0101bab <sprintputch+0x1b>
		*b->buf++ = ch;
f0101ba1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0101ba4:	89 08                	mov    %ecx,(%eax)
f0101ba6:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ba9:	88 02                	mov    %al,(%edx)
}
f0101bab:	5d                   	pop    %ebp
f0101bac:	c3                   	ret    

f0101bad <printfmt>:
{
f0101bad:	55                   	push   %ebp
f0101bae:	89 e5                	mov    %esp,%ebp
f0101bb0:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101bb3:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101bb6:	50                   	push   %eax
f0101bb7:	ff 75 10             	pushl  0x10(%ebp)
f0101bba:	ff 75 0c             	pushl  0xc(%ebp)
f0101bbd:	ff 75 08             	pushl  0x8(%ebp)
f0101bc0:	e8 05 00 00 00       	call   f0101bca <vprintfmt>
}
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	c9                   	leave  
f0101bc9:	c3                   	ret    

f0101bca <vprintfmt>:
{
f0101bca:	55                   	push   %ebp
f0101bcb:	89 e5                	mov    %esp,%ebp
f0101bcd:	57                   	push   %edi
f0101bce:	56                   	push   %esi
f0101bcf:	53                   	push   %ebx
f0101bd0:	83 ec 2c             	sub    $0x2c,%esp
f0101bd3:	e8 77 e5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101bd8:	81 c3 30 17 01 00    	add    $0x11730,%ebx
f0101bde:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101be1:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101be4:	e9 8e 03 00 00       	jmp    f0101f77 <.L35+0x48>
		padc = ' ';
f0101be9:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0101bed:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101bf4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0101bfb:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101c02:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101c07:	89 4d cc             	mov    %ecx,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101c0a:	8d 47 01             	lea    0x1(%edi),%eax
f0101c0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c10:	0f b6 17             	movzbl (%edi),%edx
f0101c13:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101c16:	3c 55                	cmp    $0x55,%al
f0101c18:	0f 87 e1 03 00 00    	ja     f0101fff <.L22>
f0101c1e:	0f b6 c0             	movzbl %al,%eax
f0101c21:	89 d9                	mov    %ebx,%ecx
f0101c23:	03 8c 83 3c fd fe ff 	add    -0x102c4(%ebx,%eax,4),%ecx
f0101c2a:	ff e1                	jmp    *%ecx

f0101c2c <.L67>:
f0101c2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101c2f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101c33:	eb d5                	jmp    f0101c0a <vprintfmt+0x40>

f0101c35 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101c35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0101c38:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101c3c:	eb cc                	jmp    f0101c0a <vprintfmt+0x40>

f0101c3e <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101c3e:	0f b6 d2             	movzbl %dl,%edx
f0101c41:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101c44:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0101c49:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101c4c:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101c50:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0101c53:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101c56:	83 f9 09             	cmp    $0x9,%ecx
f0101c59:	77 55                	ja     f0101cb0 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0101c5b:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101c5e:	eb e9                	jmp    f0101c49 <.L29+0xb>

f0101c60 <.L26>:
			precision = va_arg(ap, int);
f0101c60:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c63:	8b 00                	mov    (%eax),%eax
f0101c65:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c68:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c6b:	8d 40 04             	lea    0x4(%eax),%eax
f0101c6e:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101c71:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0101c74:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101c78:	79 90                	jns    f0101c0a <vprintfmt+0x40>
				width = precision, precision = -1;
f0101c7a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c7d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101c80:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101c87:	eb 81                	jmp    f0101c0a <vprintfmt+0x40>

f0101c89 <.L27>:
f0101c89:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101c8c:	85 c0                	test   %eax,%eax
f0101c8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c93:	0f 49 d0             	cmovns %eax,%edx
f0101c96:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101c99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c9c:	e9 69 ff ff ff       	jmp    f0101c0a <vprintfmt+0x40>

f0101ca1 <.L23>:
f0101ca1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0101ca4:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101cab:	e9 5a ff ff ff       	jmp    f0101c0a <vprintfmt+0x40>
f0101cb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cb3:	eb bf                	jmp    f0101c74 <.L26+0x14>

f0101cb5 <.L33>:
			lflag++;
f0101cb5:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101cb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101cbc:	e9 49 ff ff ff       	jmp    f0101c0a <vprintfmt+0x40>

f0101cc1 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101cc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cc4:	8d 78 04             	lea    0x4(%eax),%edi
f0101cc7:	83 ec 08             	sub    $0x8,%esp
f0101cca:	56                   	push   %esi
f0101ccb:	ff 30                	pushl  (%eax)
f0101ccd:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101cd0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101cd3:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101cd6:	e9 99 02 00 00       	jmp    f0101f74 <.L35+0x45>

f0101cdb <.L32>:
			err = va_arg(ap, int);
f0101cdb:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cde:	8d 78 04             	lea    0x4(%eax),%edi
f0101ce1:	8b 00                	mov    (%eax),%eax
f0101ce3:	99                   	cltd   
f0101ce4:	31 d0                	xor    %edx,%eax
f0101ce6:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101ce8:	83 f8 06             	cmp    $0x6,%eax
f0101ceb:	7f 27                	jg     f0101d14 <.L32+0x39>
f0101ced:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0101cf4:	85 d2                	test   %edx,%edx
f0101cf6:	74 1c                	je     f0101d14 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101cf8:	52                   	push   %edx
f0101cf9:	8d 83 d4 fa fe ff    	lea    -0x1052c(%ebx),%eax
f0101cff:	50                   	push   %eax
f0101d00:	56                   	push   %esi
f0101d01:	ff 75 08             	pushl  0x8(%ebp)
f0101d04:	e8 a4 fe ff ff       	call   f0101bad <printfmt>
f0101d09:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101d0c:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101d0f:	e9 60 02 00 00       	jmp    f0101f74 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0101d14:	50                   	push   %eax
f0101d15:	8d 83 c7 fc fe ff    	lea    -0x10339(%ebx),%eax
f0101d1b:	50                   	push   %eax
f0101d1c:	56                   	push   %esi
f0101d1d:	ff 75 08             	pushl  0x8(%ebp)
f0101d20:	e8 88 fe ff ff       	call   f0101bad <printfmt>
f0101d25:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101d28:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0101d2b:	e9 44 02 00 00       	jmp    f0101f74 <.L35+0x45>

f0101d30 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101d30:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d33:	83 c0 04             	add    $0x4,%eax
f0101d36:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d39:	8b 45 14             	mov    0x14(%ebp),%eax
f0101d3c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101d3e:	85 ff                	test   %edi,%edi
f0101d40:	8d 83 c0 fc fe ff    	lea    -0x10340(%ebx),%eax
f0101d46:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101d49:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101d4d:	0f 8e b5 00 00 00    	jle    f0101e08 <.L36+0xd8>
f0101d53:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101d57:	75 08                	jne    f0101d61 <.L36+0x31>
f0101d59:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101d5c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101d5f:	eb 6d                	jmp    f0101dce <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101d61:	83 ec 08             	sub    $0x8,%esp
f0101d64:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d67:	57                   	push   %edi
f0101d68:	e8 49 04 00 00       	call   f01021b6 <strnlen>
f0101d6d:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101d70:	29 c2                	sub    %eax,%edx
f0101d72:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101d75:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101d78:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101d7c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101d7f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101d82:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101d84:	eb 10                	jmp    f0101d96 <.L36+0x66>
					putch(padc, putdat);
f0101d86:	83 ec 08             	sub    $0x8,%esp
f0101d89:	56                   	push   %esi
f0101d8a:	ff 75 e0             	pushl  -0x20(%ebp)
f0101d8d:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101d90:	83 ef 01             	sub    $0x1,%edi
f0101d93:	83 c4 10             	add    $0x10,%esp
f0101d96:	85 ff                	test   %edi,%edi
f0101d98:	7f ec                	jg     f0101d86 <.L36+0x56>
f0101d9a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101d9d:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101da0:	85 d2                	test   %edx,%edx
f0101da2:	b8 00 00 00 00       	mov    $0x0,%eax
f0101da7:	0f 49 c2             	cmovns %edx,%eax
f0101daa:	29 c2                	sub    %eax,%edx
f0101dac:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101daf:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101db2:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101db5:	eb 17                	jmp    f0101dce <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101db7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101dbb:	75 30                	jne    f0101ded <.L36+0xbd>
					putch(ch, putdat);
f0101dbd:	83 ec 08             	sub    $0x8,%esp
f0101dc0:	ff 75 0c             	pushl  0xc(%ebp)
f0101dc3:	50                   	push   %eax
f0101dc4:	ff 55 08             	call   *0x8(%ebp)
f0101dc7:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101dca:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101dce:	83 c7 01             	add    $0x1,%edi
f0101dd1:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101dd5:	0f be c2             	movsbl %dl,%eax
f0101dd8:	85 c0                	test   %eax,%eax
f0101dda:	74 52                	je     f0101e2e <.L36+0xfe>
f0101ddc:	85 f6                	test   %esi,%esi
f0101dde:	78 d7                	js     f0101db7 <.L36+0x87>
f0101de0:	83 ee 01             	sub    $0x1,%esi
f0101de3:	79 d2                	jns    f0101db7 <.L36+0x87>
f0101de5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101de8:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101deb:	eb 32                	jmp    f0101e1f <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101ded:	0f be d2             	movsbl %dl,%edx
f0101df0:	83 ea 20             	sub    $0x20,%edx
f0101df3:	83 fa 5e             	cmp    $0x5e,%edx
f0101df6:	76 c5                	jbe    f0101dbd <.L36+0x8d>
					putch('?', putdat);
f0101df8:	83 ec 08             	sub    $0x8,%esp
f0101dfb:	ff 75 0c             	pushl  0xc(%ebp)
f0101dfe:	6a 3f                	push   $0x3f
f0101e00:	ff 55 08             	call   *0x8(%ebp)
f0101e03:	83 c4 10             	add    $0x10,%esp
f0101e06:	eb c2                	jmp    f0101dca <.L36+0x9a>
f0101e08:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101e0b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101e0e:	eb be                	jmp    f0101dce <.L36+0x9e>
				putch(' ', putdat);
f0101e10:	83 ec 08             	sub    $0x8,%esp
f0101e13:	56                   	push   %esi
f0101e14:	6a 20                	push   $0x20
f0101e16:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0101e19:	83 ef 01             	sub    $0x1,%edi
f0101e1c:	83 c4 10             	add    $0x10,%esp
f0101e1f:	85 ff                	test   %edi,%edi
f0101e21:	7f ed                	jg     f0101e10 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101e23:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101e26:	89 45 14             	mov    %eax,0x14(%ebp)
f0101e29:	e9 46 01 00 00       	jmp    f0101f74 <.L35+0x45>
f0101e2e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101e31:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101e34:	eb e9                	jmp    f0101e1f <.L36+0xef>

f0101e36 <.L31>:
f0101e36:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101e39:	83 f9 01             	cmp    $0x1,%ecx
f0101e3c:	7e 40                	jle    f0101e7e <.L31+0x48>
		return va_arg(*ap, long long);
f0101e3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e41:	8b 50 04             	mov    0x4(%eax),%edx
f0101e44:	8b 00                	mov    (%eax),%eax
f0101e46:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101e49:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101e4c:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e4f:	8d 40 08             	lea    0x8(%eax),%eax
f0101e52:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101e55:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101e59:	79 55                	jns    f0101eb0 <.L31+0x7a>
				putch('-', putdat);
f0101e5b:	83 ec 08             	sub    $0x8,%esp
f0101e5e:	56                   	push   %esi
f0101e5f:	6a 2d                	push   $0x2d
f0101e61:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101e64:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101e67:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101e6a:	f7 da                	neg    %edx
f0101e6c:	83 d1 00             	adc    $0x0,%ecx
f0101e6f:	f7 d9                	neg    %ecx
f0101e71:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101e74:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101e79:	e9 db 00 00 00       	jmp    f0101f59 <.L35+0x2a>
	else if (lflag)
f0101e7e:	85 c9                	test   %ecx,%ecx
f0101e80:	75 17                	jne    f0101e99 <.L31+0x63>
		return va_arg(*ap, int);
f0101e82:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e85:	8b 00                	mov    (%eax),%eax
f0101e87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101e8a:	99                   	cltd   
f0101e8b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101e8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e91:	8d 40 04             	lea    0x4(%eax),%eax
f0101e94:	89 45 14             	mov    %eax,0x14(%ebp)
f0101e97:	eb bc                	jmp    f0101e55 <.L31+0x1f>
		return va_arg(*ap, long);
f0101e99:	8b 45 14             	mov    0x14(%ebp),%eax
f0101e9c:	8b 00                	mov    (%eax),%eax
f0101e9e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101ea1:	99                   	cltd   
f0101ea2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101ea5:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ea8:	8d 40 04             	lea    0x4(%eax),%eax
f0101eab:	89 45 14             	mov    %eax,0x14(%ebp)
f0101eae:	eb a5                	jmp    f0101e55 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101eb0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101eb3:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101eb6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101ebb:	e9 99 00 00 00       	jmp    f0101f59 <.L35+0x2a>

f0101ec0 <.L37>:
f0101ec0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101ec3:	83 f9 01             	cmp    $0x1,%ecx
f0101ec6:	7e 15                	jle    f0101edd <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101ec8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ecb:	8b 10                	mov    (%eax),%edx
f0101ecd:	8b 48 04             	mov    0x4(%eax),%ecx
f0101ed0:	8d 40 08             	lea    0x8(%eax),%eax
f0101ed3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101ed6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101edb:	eb 7c                	jmp    f0101f59 <.L35+0x2a>
	else if (lflag)
f0101edd:	85 c9                	test   %ecx,%ecx
f0101edf:	75 17                	jne    f0101ef8 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101ee1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ee4:	8b 10                	mov    (%eax),%edx
f0101ee6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101eeb:	8d 40 04             	lea    0x4(%eax),%eax
f0101eee:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101ef1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101ef6:	eb 61                	jmp    f0101f59 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101ef8:	8b 45 14             	mov    0x14(%ebp),%eax
f0101efb:	8b 10                	mov    (%eax),%edx
f0101efd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101f02:	8d 40 04             	lea    0x4(%eax),%eax
f0101f05:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101f08:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101f0d:	eb 4a                	jmp    f0101f59 <.L35+0x2a>

f0101f0f <.L34>:
			putch('X', putdat);
f0101f0f:	83 ec 08             	sub    $0x8,%esp
f0101f12:	56                   	push   %esi
f0101f13:	6a 58                	push   $0x58
f0101f15:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101f18:	83 c4 08             	add    $0x8,%esp
f0101f1b:	56                   	push   %esi
f0101f1c:	6a 58                	push   $0x58
f0101f1e:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0101f21:	83 c4 08             	add    $0x8,%esp
f0101f24:	56                   	push   %esi
f0101f25:	6a 58                	push   $0x58
f0101f27:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101f2a:	83 c4 10             	add    $0x10,%esp
f0101f2d:	eb 45                	jmp    f0101f74 <.L35+0x45>

f0101f2f <.L35>:
			putch('0', putdat);
f0101f2f:	83 ec 08             	sub    $0x8,%esp
f0101f32:	56                   	push   %esi
f0101f33:	6a 30                	push   $0x30
f0101f35:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101f38:	83 c4 08             	add    $0x8,%esp
f0101f3b:	56                   	push   %esi
f0101f3c:	6a 78                	push   $0x78
f0101f3e:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101f41:	8b 45 14             	mov    0x14(%ebp),%eax
f0101f44:	8b 10                	mov    (%eax),%edx
f0101f46:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101f4b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101f4e:	8d 40 04             	lea    0x4(%eax),%eax
f0101f51:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101f54:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101f59:	83 ec 0c             	sub    $0xc,%esp
f0101f5c:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101f60:	57                   	push   %edi
f0101f61:	ff 75 e0             	pushl  -0x20(%ebp)
f0101f64:	50                   	push   %eax
f0101f65:	51                   	push   %ecx
f0101f66:	52                   	push   %edx
f0101f67:	89 f2                	mov    %esi,%edx
f0101f69:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f6c:	e8 55 fb ff ff       	call   f0101ac6 <printnum>
			break;
f0101f71:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0101f74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101f77:	83 c7 01             	add    $0x1,%edi
f0101f7a:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101f7e:	83 f8 25             	cmp    $0x25,%eax
f0101f81:	0f 84 62 fc ff ff    	je     f0101be9 <vprintfmt+0x1f>
			if (ch == '\0')
f0101f87:	85 c0                	test   %eax,%eax
f0101f89:	0f 84 91 00 00 00    	je     f0102020 <.L22+0x21>
			putch(ch, putdat);
f0101f8f:	83 ec 08             	sub    $0x8,%esp
f0101f92:	56                   	push   %esi
f0101f93:	50                   	push   %eax
f0101f94:	ff 55 08             	call   *0x8(%ebp)
f0101f97:	83 c4 10             	add    $0x10,%esp
f0101f9a:	eb db                	jmp    f0101f77 <.L35+0x48>

f0101f9c <.L38>:
f0101f9c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	if (lflag >= 2)
f0101f9f:	83 f9 01             	cmp    $0x1,%ecx
f0101fa2:	7e 15                	jle    f0101fb9 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0101fa4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fa7:	8b 10                	mov    (%eax),%edx
f0101fa9:	8b 48 04             	mov    0x4(%eax),%ecx
f0101fac:	8d 40 08             	lea    0x8(%eax),%eax
f0101faf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101fb2:	b8 10 00 00 00       	mov    $0x10,%eax
f0101fb7:	eb a0                	jmp    f0101f59 <.L35+0x2a>
	else if (lflag)
f0101fb9:	85 c9                	test   %ecx,%ecx
f0101fbb:	75 17                	jne    f0101fd4 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0101fbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fc0:	8b 10                	mov    (%eax),%edx
f0101fc2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101fc7:	8d 40 04             	lea    0x4(%eax),%eax
f0101fca:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101fcd:	b8 10 00 00 00       	mov    $0x10,%eax
f0101fd2:	eb 85                	jmp    f0101f59 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0101fd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101fd7:	8b 10                	mov    (%eax),%edx
f0101fd9:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101fde:	8d 40 04             	lea    0x4(%eax),%eax
f0101fe1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101fe4:	b8 10 00 00 00       	mov    $0x10,%eax
f0101fe9:	e9 6b ff ff ff       	jmp    f0101f59 <.L35+0x2a>

f0101fee <.L25>:
			putch(ch, putdat);
f0101fee:	83 ec 08             	sub    $0x8,%esp
f0101ff1:	56                   	push   %esi
f0101ff2:	6a 25                	push   $0x25
f0101ff4:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101ff7:	83 c4 10             	add    $0x10,%esp
f0101ffa:	e9 75 ff ff ff       	jmp    f0101f74 <.L35+0x45>

f0101fff <.L22>:
			putch('%', putdat);
f0101fff:	83 ec 08             	sub    $0x8,%esp
f0102002:	56                   	push   %esi
f0102003:	6a 25                	push   $0x25
f0102005:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102008:	83 c4 10             	add    $0x10,%esp
f010200b:	89 f8                	mov    %edi,%eax
f010200d:	eb 03                	jmp    f0102012 <.L22+0x13>
f010200f:	83 e8 01             	sub    $0x1,%eax
f0102012:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0102016:	75 f7                	jne    f010200f <.L22+0x10>
f0102018:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010201b:	e9 54 ff ff ff       	jmp    f0101f74 <.L35+0x45>
}
f0102020:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102023:	5b                   	pop    %ebx
f0102024:	5e                   	pop    %esi
f0102025:	5f                   	pop    %edi
f0102026:	5d                   	pop    %ebp
f0102027:	c3                   	ret    

f0102028 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102028:	55                   	push   %ebp
f0102029:	89 e5                	mov    %esp,%ebp
f010202b:	53                   	push   %ebx
f010202c:	83 ec 14             	sub    $0x14,%esp
f010202f:	e8 1b e1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0102034:	81 c3 d4 12 01 00    	add    $0x112d4,%ebx
f010203a:	8b 45 08             	mov    0x8(%ebp),%eax
f010203d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102040:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102043:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102047:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010204a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102051:	85 c0                	test   %eax,%eax
f0102053:	74 2b                	je     f0102080 <vsnprintf+0x58>
f0102055:	85 d2                	test   %edx,%edx
f0102057:	7e 27                	jle    f0102080 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102059:	ff 75 14             	pushl  0x14(%ebp)
f010205c:	ff 75 10             	pushl  0x10(%ebp)
f010205f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102062:	50                   	push   %eax
f0102063:	8d 83 88 e8 fe ff    	lea    -0x11778(%ebx),%eax
f0102069:	50                   	push   %eax
f010206a:	e8 5b fb ff ff       	call   f0101bca <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010206f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102072:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102075:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102078:	83 c4 10             	add    $0x10,%esp
}
f010207b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010207e:	c9                   	leave  
f010207f:	c3                   	ret    
		return -E_INVAL;
f0102080:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0102085:	eb f4                	jmp    f010207b <vsnprintf+0x53>

f0102087 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102087:	55                   	push   %ebp
f0102088:	89 e5                	mov    %esp,%ebp
f010208a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010208d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102090:	50                   	push   %eax
f0102091:	ff 75 10             	pushl  0x10(%ebp)
f0102094:	ff 75 0c             	pushl  0xc(%ebp)
f0102097:	ff 75 08             	pushl  0x8(%ebp)
f010209a:	e8 89 ff ff ff       	call   f0102028 <vsnprintf>
	va_end(ap);

	return rc;
}
f010209f:	c9                   	leave  
f01020a0:	c3                   	ret    

f01020a1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01020a1:	55                   	push   %ebp
f01020a2:	89 e5                	mov    %esp,%ebp
f01020a4:	57                   	push   %edi
f01020a5:	56                   	push   %esi
f01020a6:	53                   	push   %ebx
f01020a7:	83 ec 1c             	sub    $0x1c,%esp
f01020aa:	e8 a0 e0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01020af:	81 c3 59 12 01 00    	add    $0x11259,%ebx
f01020b5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01020b8:	85 c0                	test   %eax,%eax
f01020ba:	74 13                	je     f01020cf <readline+0x2e>
		cprintf("%s", prompt);
f01020bc:	83 ec 08             	sub    $0x8,%esp
f01020bf:	50                   	push   %eax
f01020c0:	8d 83 d4 fa fe ff    	lea    -0x1052c(%ebx),%eax
f01020c6:	50                   	push   %eax
f01020c7:	e8 ee f6 ff ff       	call   f01017ba <cprintf>
f01020cc:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01020cf:	83 ec 0c             	sub    $0xc,%esp
f01020d2:	6a 00                	push   $0x0
f01020d4:	e8 0e e6 ff ff       	call   f01006e7 <iscons>
f01020d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01020dc:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01020df:	bf 00 00 00 00       	mov    $0x0,%edi
f01020e4:	eb 46                	jmp    f010212c <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01020e6:	83 ec 08             	sub    $0x8,%esp
f01020e9:	50                   	push   %eax
f01020ea:	8d 83 94 fe fe ff    	lea    -0x1016c(%ebx),%eax
f01020f0:	50                   	push   %eax
f01020f1:	e8 c4 f6 ff ff       	call   f01017ba <cprintf>
			return NULL;
f01020f6:	83 c4 10             	add    $0x10,%esp
f01020f9:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01020fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102101:	5b                   	pop    %ebx
f0102102:	5e                   	pop    %esi
f0102103:	5f                   	pop    %edi
f0102104:	5d                   	pop    %ebp
f0102105:	c3                   	ret    
			if (echoing)
f0102106:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010210a:	75 05                	jne    f0102111 <readline+0x70>
			i--;
f010210c:	83 ef 01             	sub    $0x1,%edi
f010210f:	eb 1b                	jmp    f010212c <readline+0x8b>
				cputchar('\b');
f0102111:	83 ec 0c             	sub    $0xc,%esp
f0102114:	6a 08                	push   $0x8
f0102116:	e8 ab e5 ff ff       	call   f01006c6 <cputchar>
f010211b:	83 c4 10             	add    $0x10,%esp
f010211e:	eb ec                	jmp    f010210c <readline+0x6b>
			buf[i++] = c;
f0102120:	89 f0                	mov    %esi,%eax
f0102122:	88 84 3b b8 1f 00 00 	mov    %al,0x1fb8(%ebx,%edi,1)
f0102129:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010212c:	e8 a5 e5 ff ff       	call   f01006d6 <getchar>
f0102131:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0102133:	85 c0                	test   %eax,%eax
f0102135:	78 af                	js     f01020e6 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102137:	83 f8 08             	cmp    $0x8,%eax
f010213a:	0f 94 c2             	sete   %dl
f010213d:	83 f8 7f             	cmp    $0x7f,%eax
f0102140:	0f 94 c0             	sete   %al
f0102143:	08 c2                	or     %al,%dl
f0102145:	74 04                	je     f010214b <readline+0xaa>
f0102147:	85 ff                	test   %edi,%edi
f0102149:	7f bb                	jg     f0102106 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010214b:	83 fe 1f             	cmp    $0x1f,%esi
f010214e:	7e 1c                	jle    f010216c <readline+0xcb>
f0102150:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0102156:	7f 14                	jg     f010216c <readline+0xcb>
			if (echoing)
f0102158:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010215c:	74 c2                	je     f0102120 <readline+0x7f>
				cputchar(c);
f010215e:	83 ec 0c             	sub    $0xc,%esp
f0102161:	56                   	push   %esi
f0102162:	e8 5f e5 ff ff       	call   f01006c6 <cputchar>
f0102167:	83 c4 10             	add    $0x10,%esp
f010216a:	eb b4                	jmp    f0102120 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010216c:	83 fe 0a             	cmp    $0xa,%esi
f010216f:	74 05                	je     f0102176 <readline+0xd5>
f0102171:	83 fe 0d             	cmp    $0xd,%esi
f0102174:	75 b6                	jne    f010212c <readline+0x8b>
			if (echoing)
f0102176:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010217a:	75 13                	jne    f010218f <readline+0xee>
			buf[i] = 0;
f010217c:	c6 84 3b b8 1f 00 00 	movb   $0x0,0x1fb8(%ebx,%edi,1)
f0102183:	00 
			return buf;
f0102184:	8d 83 b8 1f 00 00    	lea    0x1fb8(%ebx),%eax
f010218a:	e9 6f ff ff ff       	jmp    f01020fe <readline+0x5d>
				cputchar('\n');
f010218f:	83 ec 0c             	sub    $0xc,%esp
f0102192:	6a 0a                	push   $0xa
f0102194:	e8 2d e5 ff ff       	call   f01006c6 <cputchar>
f0102199:	83 c4 10             	add    $0x10,%esp
f010219c:	eb de                	jmp    f010217c <readline+0xdb>

f010219e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010219e:	55                   	push   %ebp
f010219f:	89 e5                	mov    %esp,%ebp
f01021a1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01021a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01021a9:	eb 03                	jmp    f01021ae <strlen+0x10>
		n++;
f01021ab:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01021ae:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01021b2:	75 f7                	jne    f01021ab <strlen+0xd>
	return n;
}
f01021b4:	5d                   	pop    %ebp
f01021b5:	c3                   	ret    

f01021b6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01021b6:	55                   	push   %ebp
f01021b7:	89 e5                	mov    %esp,%ebp
f01021b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01021bc:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01021bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01021c4:	eb 03                	jmp    f01021c9 <strnlen+0x13>
		n++;
f01021c6:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01021c9:	39 d0                	cmp    %edx,%eax
f01021cb:	74 06                	je     f01021d3 <strnlen+0x1d>
f01021cd:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01021d1:	75 f3                	jne    f01021c6 <strnlen+0x10>
	return n;
}
f01021d3:	5d                   	pop    %ebp
f01021d4:	c3                   	ret    

f01021d5 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01021d5:	55                   	push   %ebp
f01021d6:	89 e5                	mov    %esp,%ebp
f01021d8:	53                   	push   %ebx
f01021d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01021dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01021df:	89 c2                	mov    %eax,%edx
f01021e1:	83 c1 01             	add    $0x1,%ecx
f01021e4:	83 c2 01             	add    $0x1,%edx
f01021e7:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01021eb:	88 5a ff             	mov    %bl,-0x1(%edx)
f01021ee:	84 db                	test   %bl,%bl
f01021f0:	75 ef                	jne    f01021e1 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01021f2:	5b                   	pop    %ebx
f01021f3:	5d                   	pop    %ebp
f01021f4:	c3                   	ret    

f01021f5 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01021f5:	55                   	push   %ebp
f01021f6:	89 e5                	mov    %esp,%ebp
f01021f8:	53                   	push   %ebx
f01021f9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01021fc:	53                   	push   %ebx
f01021fd:	e8 9c ff ff ff       	call   f010219e <strlen>
f0102202:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0102205:	ff 75 0c             	pushl  0xc(%ebp)
f0102208:	01 d8                	add    %ebx,%eax
f010220a:	50                   	push   %eax
f010220b:	e8 c5 ff ff ff       	call   f01021d5 <strcpy>
	return dst;
}
f0102210:	89 d8                	mov    %ebx,%eax
f0102212:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102215:	c9                   	leave  
f0102216:	c3                   	ret    

f0102217 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102217:	55                   	push   %ebp
f0102218:	89 e5                	mov    %esp,%ebp
f010221a:	56                   	push   %esi
f010221b:	53                   	push   %ebx
f010221c:	8b 75 08             	mov    0x8(%ebp),%esi
f010221f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102222:	89 f3                	mov    %esi,%ebx
f0102224:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102227:	89 f2                	mov    %esi,%edx
f0102229:	eb 0f                	jmp    f010223a <strncpy+0x23>
		*dst++ = *src;
f010222b:	83 c2 01             	add    $0x1,%edx
f010222e:	0f b6 01             	movzbl (%ecx),%eax
f0102231:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0102234:	80 39 01             	cmpb   $0x1,(%ecx)
f0102237:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f010223a:	39 da                	cmp    %ebx,%edx
f010223c:	75 ed                	jne    f010222b <strncpy+0x14>
	}
	return ret;
}
f010223e:	89 f0                	mov    %esi,%eax
f0102240:	5b                   	pop    %ebx
f0102241:	5e                   	pop    %esi
f0102242:	5d                   	pop    %ebp
f0102243:	c3                   	ret    

f0102244 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102244:	55                   	push   %ebp
f0102245:	89 e5                	mov    %esp,%ebp
f0102247:	56                   	push   %esi
f0102248:	53                   	push   %ebx
f0102249:	8b 75 08             	mov    0x8(%ebp),%esi
f010224c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010224f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102252:	89 f0                	mov    %esi,%eax
f0102254:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102258:	85 c9                	test   %ecx,%ecx
f010225a:	75 0b                	jne    f0102267 <strlcpy+0x23>
f010225c:	eb 17                	jmp    f0102275 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010225e:	83 c2 01             	add    $0x1,%edx
f0102261:	83 c0 01             	add    $0x1,%eax
f0102264:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0102267:	39 d8                	cmp    %ebx,%eax
f0102269:	74 07                	je     f0102272 <strlcpy+0x2e>
f010226b:	0f b6 0a             	movzbl (%edx),%ecx
f010226e:	84 c9                	test   %cl,%cl
f0102270:	75 ec                	jne    f010225e <strlcpy+0x1a>
		*dst = '\0';
f0102272:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102275:	29 f0                	sub    %esi,%eax
}
f0102277:	5b                   	pop    %ebx
f0102278:	5e                   	pop    %esi
f0102279:	5d                   	pop    %ebp
f010227a:	c3                   	ret    

f010227b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010227b:	55                   	push   %ebp
f010227c:	89 e5                	mov    %esp,%ebp
f010227e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102281:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102284:	eb 06                	jmp    f010228c <strcmp+0x11>
		p++, q++;
f0102286:	83 c1 01             	add    $0x1,%ecx
f0102289:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010228c:	0f b6 01             	movzbl (%ecx),%eax
f010228f:	84 c0                	test   %al,%al
f0102291:	74 04                	je     f0102297 <strcmp+0x1c>
f0102293:	3a 02                	cmp    (%edx),%al
f0102295:	74 ef                	je     f0102286 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102297:	0f b6 c0             	movzbl %al,%eax
f010229a:	0f b6 12             	movzbl (%edx),%edx
f010229d:	29 d0                	sub    %edx,%eax
}
f010229f:	5d                   	pop    %ebp
f01022a0:	c3                   	ret    

f01022a1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01022a1:	55                   	push   %ebp
f01022a2:	89 e5                	mov    %esp,%ebp
f01022a4:	53                   	push   %ebx
f01022a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01022a8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01022ab:	89 c3                	mov    %eax,%ebx
f01022ad:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01022b0:	eb 06                	jmp    f01022b8 <strncmp+0x17>
		n--, p++, q++;
f01022b2:	83 c0 01             	add    $0x1,%eax
f01022b5:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01022b8:	39 d8                	cmp    %ebx,%eax
f01022ba:	74 16                	je     f01022d2 <strncmp+0x31>
f01022bc:	0f b6 08             	movzbl (%eax),%ecx
f01022bf:	84 c9                	test   %cl,%cl
f01022c1:	74 04                	je     f01022c7 <strncmp+0x26>
f01022c3:	3a 0a                	cmp    (%edx),%cl
f01022c5:	74 eb                	je     f01022b2 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01022c7:	0f b6 00             	movzbl (%eax),%eax
f01022ca:	0f b6 12             	movzbl (%edx),%edx
f01022cd:	29 d0                	sub    %edx,%eax
}
f01022cf:	5b                   	pop    %ebx
f01022d0:	5d                   	pop    %ebp
f01022d1:	c3                   	ret    
		return 0;
f01022d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01022d7:	eb f6                	jmp    f01022cf <strncmp+0x2e>

f01022d9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01022d9:	55                   	push   %ebp
f01022da:	89 e5                	mov    %esp,%ebp
f01022dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01022df:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01022e3:	0f b6 10             	movzbl (%eax),%edx
f01022e6:	84 d2                	test   %dl,%dl
f01022e8:	74 09                	je     f01022f3 <strchr+0x1a>
		if (*s == c)
f01022ea:	38 ca                	cmp    %cl,%dl
f01022ec:	74 0a                	je     f01022f8 <strchr+0x1f>
	for (; *s; s++)
f01022ee:	83 c0 01             	add    $0x1,%eax
f01022f1:	eb f0                	jmp    f01022e3 <strchr+0xa>
			return (char *) s;
	return 0;
f01022f3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01022f8:	5d                   	pop    %ebp
f01022f9:	c3                   	ret    

f01022fa <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01022fa:	55                   	push   %ebp
f01022fb:	89 e5                	mov    %esp,%ebp
f01022fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102300:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102304:	eb 03                	jmp    f0102309 <strfind+0xf>
f0102306:	83 c0 01             	add    $0x1,%eax
f0102309:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010230c:	38 ca                	cmp    %cl,%dl
f010230e:	74 04                	je     f0102314 <strfind+0x1a>
f0102310:	84 d2                	test   %dl,%dl
f0102312:	75 f2                	jne    f0102306 <strfind+0xc>
			break;
	return (char *) s;
}
f0102314:	5d                   	pop    %ebp
f0102315:	c3                   	ret    

f0102316 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102316:	55                   	push   %ebp
f0102317:	89 e5                	mov    %esp,%ebp
f0102319:	57                   	push   %edi
f010231a:	56                   	push   %esi
f010231b:	53                   	push   %ebx
f010231c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010231f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102322:	85 c9                	test   %ecx,%ecx
f0102324:	74 13                	je     f0102339 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102326:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010232c:	75 05                	jne    f0102333 <memset+0x1d>
f010232e:	f6 c1 03             	test   $0x3,%cl
f0102331:	74 0d                	je     f0102340 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102333:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102336:	fc                   	cld    
f0102337:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102339:	89 f8                	mov    %edi,%eax
f010233b:	5b                   	pop    %ebx
f010233c:	5e                   	pop    %esi
f010233d:	5f                   	pop    %edi
f010233e:	5d                   	pop    %ebp
f010233f:	c3                   	ret    
		c &= 0xFF;
f0102340:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102344:	89 d3                	mov    %edx,%ebx
f0102346:	c1 e3 08             	shl    $0x8,%ebx
f0102349:	89 d0                	mov    %edx,%eax
f010234b:	c1 e0 18             	shl    $0x18,%eax
f010234e:	89 d6                	mov    %edx,%esi
f0102350:	c1 e6 10             	shl    $0x10,%esi
f0102353:	09 f0                	or     %esi,%eax
f0102355:	09 c2                	or     %eax,%edx
f0102357:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0102359:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010235c:	89 d0                	mov    %edx,%eax
f010235e:	fc                   	cld    
f010235f:	f3 ab                	rep stos %eax,%es:(%edi)
f0102361:	eb d6                	jmp    f0102339 <memset+0x23>

f0102363 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102363:	55                   	push   %ebp
f0102364:	89 e5                	mov    %esp,%ebp
f0102366:	57                   	push   %edi
f0102367:	56                   	push   %esi
f0102368:	8b 45 08             	mov    0x8(%ebp),%eax
f010236b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010236e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102371:	39 c6                	cmp    %eax,%esi
f0102373:	73 35                	jae    f01023aa <memmove+0x47>
f0102375:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102378:	39 c2                	cmp    %eax,%edx
f010237a:	76 2e                	jbe    f01023aa <memmove+0x47>
		s += n;
		d += n;
f010237c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010237f:	89 d6                	mov    %edx,%esi
f0102381:	09 fe                	or     %edi,%esi
f0102383:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102389:	74 0c                	je     f0102397 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010238b:	83 ef 01             	sub    $0x1,%edi
f010238e:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0102391:	fd                   	std    
f0102392:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102394:	fc                   	cld    
f0102395:	eb 21                	jmp    f01023b8 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102397:	f6 c1 03             	test   $0x3,%cl
f010239a:	75 ef                	jne    f010238b <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010239c:	83 ef 04             	sub    $0x4,%edi
f010239f:	8d 72 fc             	lea    -0x4(%edx),%esi
f01023a2:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01023a5:	fd                   	std    
f01023a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01023a8:	eb ea                	jmp    f0102394 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01023aa:	89 f2                	mov    %esi,%edx
f01023ac:	09 c2                	or     %eax,%edx
f01023ae:	f6 c2 03             	test   $0x3,%dl
f01023b1:	74 09                	je     f01023bc <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01023b3:	89 c7                	mov    %eax,%edi
f01023b5:	fc                   	cld    
f01023b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01023b8:	5e                   	pop    %esi
f01023b9:	5f                   	pop    %edi
f01023ba:	5d                   	pop    %ebp
f01023bb:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01023bc:	f6 c1 03             	test   $0x3,%cl
f01023bf:	75 f2                	jne    f01023b3 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01023c1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01023c4:	89 c7                	mov    %eax,%edi
f01023c6:	fc                   	cld    
f01023c7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01023c9:	eb ed                	jmp    f01023b8 <memmove+0x55>

f01023cb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01023cb:	55                   	push   %ebp
f01023cc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01023ce:	ff 75 10             	pushl  0x10(%ebp)
f01023d1:	ff 75 0c             	pushl  0xc(%ebp)
f01023d4:	ff 75 08             	pushl  0x8(%ebp)
f01023d7:	e8 87 ff ff ff       	call   f0102363 <memmove>
}
f01023dc:	c9                   	leave  
f01023dd:	c3                   	ret    

f01023de <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01023de:	55                   	push   %ebp
f01023df:	89 e5                	mov    %esp,%ebp
f01023e1:	56                   	push   %esi
f01023e2:	53                   	push   %ebx
f01023e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01023e6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01023e9:	89 c6                	mov    %eax,%esi
f01023eb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01023ee:	39 f0                	cmp    %esi,%eax
f01023f0:	74 1c                	je     f010240e <memcmp+0x30>
		if (*s1 != *s2)
f01023f2:	0f b6 08             	movzbl (%eax),%ecx
f01023f5:	0f b6 1a             	movzbl (%edx),%ebx
f01023f8:	38 d9                	cmp    %bl,%cl
f01023fa:	75 08                	jne    f0102404 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01023fc:	83 c0 01             	add    $0x1,%eax
f01023ff:	83 c2 01             	add    $0x1,%edx
f0102402:	eb ea                	jmp    f01023ee <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0102404:	0f b6 c1             	movzbl %cl,%eax
f0102407:	0f b6 db             	movzbl %bl,%ebx
f010240a:	29 d8                	sub    %ebx,%eax
f010240c:	eb 05                	jmp    f0102413 <memcmp+0x35>
	}

	return 0;
f010240e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102413:	5b                   	pop    %ebx
f0102414:	5e                   	pop    %esi
f0102415:	5d                   	pop    %ebp
f0102416:	c3                   	ret    

f0102417 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102417:	55                   	push   %ebp
f0102418:	89 e5                	mov    %esp,%ebp
f010241a:	8b 45 08             	mov    0x8(%ebp),%eax
f010241d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0102420:	89 c2                	mov    %eax,%edx
f0102422:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102425:	39 d0                	cmp    %edx,%eax
f0102427:	73 09                	jae    f0102432 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102429:	38 08                	cmp    %cl,(%eax)
f010242b:	74 05                	je     f0102432 <memfind+0x1b>
	for (; s < ends; s++)
f010242d:	83 c0 01             	add    $0x1,%eax
f0102430:	eb f3                	jmp    f0102425 <memfind+0xe>
			break;
	return (void *) s;
}
f0102432:	5d                   	pop    %ebp
f0102433:	c3                   	ret    

f0102434 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102434:	55                   	push   %ebp
f0102435:	89 e5                	mov    %esp,%ebp
f0102437:	57                   	push   %edi
f0102438:	56                   	push   %esi
f0102439:	53                   	push   %ebx
f010243a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010243d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102440:	eb 03                	jmp    f0102445 <strtol+0x11>
		s++;
f0102442:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0102445:	0f b6 01             	movzbl (%ecx),%eax
f0102448:	3c 20                	cmp    $0x20,%al
f010244a:	74 f6                	je     f0102442 <strtol+0xe>
f010244c:	3c 09                	cmp    $0x9,%al
f010244e:	74 f2                	je     f0102442 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0102450:	3c 2b                	cmp    $0x2b,%al
f0102452:	74 2e                	je     f0102482 <strtol+0x4e>
	int neg = 0;
f0102454:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0102459:	3c 2d                	cmp    $0x2d,%al
f010245b:	74 2f                	je     f010248c <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010245d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102463:	75 05                	jne    f010246a <strtol+0x36>
f0102465:	80 39 30             	cmpb   $0x30,(%ecx)
f0102468:	74 2c                	je     f0102496 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010246a:	85 db                	test   %ebx,%ebx
f010246c:	75 0a                	jne    f0102478 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010246e:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0102473:	80 39 30             	cmpb   $0x30,(%ecx)
f0102476:	74 28                	je     f01024a0 <strtol+0x6c>
		base = 10;
f0102478:	b8 00 00 00 00       	mov    $0x0,%eax
f010247d:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0102480:	eb 50                	jmp    f01024d2 <strtol+0x9e>
		s++;
f0102482:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0102485:	bf 00 00 00 00       	mov    $0x0,%edi
f010248a:	eb d1                	jmp    f010245d <strtol+0x29>
		s++, neg = 1;
f010248c:	83 c1 01             	add    $0x1,%ecx
f010248f:	bf 01 00 00 00       	mov    $0x1,%edi
f0102494:	eb c7                	jmp    f010245d <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102496:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010249a:	74 0e                	je     f01024aa <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010249c:	85 db                	test   %ebx,%ebx
f010249e:	75 d8                	jne    f0102478 <strtol+0x44>
		s++, base = 8;
f01024a0:	83 c1 01             	add    $0x1,%ecx
f01024a3:	bb 08 00 00 00       	mov    $0x8,%ebx
f01024a8:	eb ce                	jmp    f0102478 <strtol+0x44>
		s += 2, base = 16;
f01024aa:	83 c1 02             	add    $0x2,%ecx
f01024ad:	bb 10 00 00 00       	mov    $0x10,%ebx
f01024b2:	eb c4                	jmp    f0102478 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01024b4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01024b7:	89 f3                	mov    %esi,%ebx
f01024b9:	80 fb 19             	cmp    $0x19,%bl
f01024bc:	77 29                	ja     f01024e7 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01024be:	0f be d2             	movsbl %dl,%edx
f01024c1:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01024c4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01024c7:	7d 30                	jge    f01024f9 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01024c9:	83 c1 01             	add    $0x1,%ecx
f01024cc:	0f af 45 10          	imul   0x10(%ebp),%eax
f01024d0:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01024d2:	0f b6 11             	movzbl (%ecx),%edx
f01024d5:	8d 72 d0             	lea    -0x30(%edx),%esi
f01024d8:	89 f3                	mov    %esi,%ebx
f01024da:	80 fb 09             	cmp    $0x9,%bl
f01024dd:	77 d5                	ja     f01024b4 <strtol+0x80>
			dig = *s - '0';
f01024df:	0f be d2             	movsbl %dl,%edx
f01024e2:	83 ea 30             	sub    $0x30,%edx
f01024e5:	eb dd                	jmp    f01024c4 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01024e7:	8d 72 bf             	lea    -0x41(%edx),%esi
f01024ea:	89 f3                	mov    %esi,%ebx
f01024ec:	80 fb 19             	cmp    $0x19,%bl
f01024ef:	77 08                	ja     f01024f9 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01024f1:	0f be d2             	movsbl %dl,%edx
f01024f4:	83 ea 37             	sub    $0x37,%edx
f01024f7:	eb cb                	jmp    f01024c4 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01024f9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01024fd:	74 05                	je     f0102504 <strtol+0xd0>
		*endptr = (char *) s;
f01024ff:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102502:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0102504:	89 c2                	mov    %eax,%edx
f0102506:	f7 da                	neg    %edx
f0102508:	85 ff                	test   %edi,%edi
f010250a:	0f 45 c2             	cmovne %edx,%eax
}
f010250d:	5b                   	pop    %ebx
f010250e:	5e                   	pop    %esi
f010250f:	5f                   	pop    %edi
f0102510:	5d                   	pop    %ebp
f0102511:	c3                   	ret    
f0102512:	66 90                	xchg   %ax,%ax
f0102514:	66 90                	xchg   %ax,%ax
f0102516:	66 90                	xchg   %ax,%ax
f0102518:	66 90                	xchg   %ax,%ax
f010251a:	66 90                	xchg   %ax,%ax
f010251c:	66 90                	xchg   %ax,%ax
f010251e:	66 90                	xchg   %ax,%ax

f0102520 <__udivdi3>:
f0102520:	55                   	push   %ebp
f0102521:	57                   	push   %edi
f0102522:	56                   	push   %esi
f0102523:	53                   	push   %ebx
f0102524:	83 ec 1c             	sub    $0x1c,%esp
f0102527:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010252b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010252f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102533:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0102537:	85 d2                	test   %edx,%edx
f0102539:	75 35                	jne    f0102570 <__udivdi3+0x50>
f010253b:	39 f3                	cmp    %esi,%ebx
f010253d:	0f 87 bd 00 00 00    	ja     f0102600 <__udivdi3+0xe0>
f0102543:	85 db                	test   %ebx,%ebx
f0102545:	89 d9                	mov    %ebx,%ecx
f0102547:	75 0b                	jne    f0102554 <__udivdi3+0x34>
f0102549:	b8 01 00 00 00       	mov    $0x1,%eax
f010254e:	31 d2                	xor    %edx,%edx
f0102550:	f7 f3                	div    %ebx
f0102552:	89 c1                	mov    %eax,%ecx
f0102554:	31 d2                	xor    %edx,%edx
f0102556:	89 f0                	mov    %esi,%eax
f0102558:	f7 f1                	div    %ecx
f010255a:	89 c6                	mov    %eax,%esi
f010255c:	89 e8                	mov    %ebp,%eax
f010255e:	89 f7                	mov    %esi,%edi
f0102560:	f7 f1                	div    %ecx
f0102562:	89 fa                	mov    %edi,%edx
f0102564:	83 c4 1c             	add    $0x1c,%esp
f0102567:	5b                   	pop    %ebx
f0102568:	5e                   	pop    %esi
f0102569:	5f                   	pop    %edi
f010256a:	5d                   	pop    %ebp
f010256b:	c3                   	ret    
f010256c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102570:	39 f2                	cmp    %esi,%edx
f0102572:	77 7c                	ja     f01025f0 <__udivdi3+0xd0>
f0102574:	0f bd fa             	bsr    %edx,%edi
f0102577:	83 f7 1f             	xor    $0x1f,%edi
f010257a:	0f 84 98 00 00 00    	je     f0102618 <__udivdi3+0xf8>
f0102580:	89 f9                	mov    %edi,%ecx
f0102582:	b8 20 00 00 00       	mov    $0x20,%eax
f0102587:	29 f8                	sub    %edi,%eax
f0102589:	d3 e2                	shl    %cl,%edx
f010258b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010258f:	89 c1                	mov    %eax,%ecx
f0102591:	89 da                	mov    %ebx,%edx
f0102593:	d3 ea                	shr    %cl,%edx
f0102595:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0102599:	09 d1                	or     %edx,%ecx
f010259b:	89 f2                	mov    %esi,%edx
f010259d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01025a1:	89 f9                	mov    %edi,%ecx
f01025a3:	d3 e3                	shl    %cl,%ebx
f01025a5:	89 c1                	mov    %eax,%ecx
f01025a7:	d3 ea                	shr    %cl,%edx
f01025a9:	89 f9                	mov    %edi,%ecx
f01025ab:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01025af:	d3 e6                	shl    %cl,%esi
f01025b1:	89 eb                	mov    %ebp,%ebx
f01025b3:	89 c1                	mov    %eax,%ecx
f01025b5:	d3 eb                	shr    %cl,%ebx
f01025b7:	09 de                	or     %ebx,%esi
f01025b9:	89 f0                	mov    %esi,%eax
f01025bb:	f7 74 24 08          	divl   0x8(%esp)
f01025bf:	89 d6                	mov    %edx,%esi
f01025c1:	89 c3                	mov    %eax,%ebx
f01025c3:	f7 64 24 0c          	mull   0xc(%esp)
f01025c7:	39 d6                	cmp    %edx,%esi
f01025c9:	72 0c                	jb     f01025d7 <__udivdi3+0xb7>
f01025cb:	89 f9                	mov    %edi,%ecx
f01025cd:	d3 e5                	shl    %cl,%ebp
f01025cf:	39 c5                	cmp    %eax,%ebp
f01025d1:	73 5d                	jae    f0102630 <__udivdi3+0x110>
f01025d3:	39 d6                	cmp    %edx,%esi
f01025d5:	75 59                	jne    f0102630 <__udivdi3+0x110>
f01025d7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01025da:	31 ff                	xor    %edi,%edi
f01025dc:	89 fa                	mov    %edi,%edx
f01025de:	83 c4 1c             	add    $0x1c,%esp
f01025e1:	5b                   	pop    %ebx
f01025e2:	5e                   	pop    %esi
f01025e3:	5f                   	pop    %edi
f01025e4:	5d                   	pop    %ebp
f01025e5:	c3                   	ret    
f01025e6:	8d 76 00             	lea    0x0(%esi),%esi
f01025e9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01025f0:	31 ff                	xor    %edi,%edi
f01025f2:	31 c0                	xor    %eax,%eax
f01025f4:	89 fa                	mov    %edi,%edx
f01025f6:	83 c4 1c             	add    $0x1c,%esp
f01025f9:	5b                   	pop    %ebx
f01025fa:	5e                   	pop    %esi
f01025fb:	5f                   	pop    %edi
f01025fc:	5d                   	pop    %ebp
f01025fd:	c3                   	ret    
f01025fe:	66 90                	xchg   %ax,%ax
f0102600:	31 ff                	xor    %edi,%edi
f0102602:	89 e8                	mov    %ebp,%eax
f0102604:	89 f2                	mov    %esi,%edx
f0102606:	f7 f3                	div    %ebx
f0102608:	89 fa                	mov    %edi,%edx
f010260a:	83 c4 1c             	add    $0x1c,%esp
f010260d:	5b                   	pop    %ebx
f010260e:	5e                   	pop    %esi
f010260f:	5f                   	pop    %edi
f0102610:	5d                   	pop    %ebp
f0102611:	c3                   	ret    
f0102612:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102618:	39 f2                	cmp    %esi,%edx
f010261a:	72 06                	jb     f0102622 <__udivdi3+0x102>
f010261c:	31 c0                	xor    %eax,%eax
f010261e:	39 eb                	cmp    %ebp,%ebx
f0102620:	77 d2                	ja     f01025f4 <__udivdi3+0xd4>
f0102622:	b8 01 00 00 00       	mov    $0x1,%eax
f0102627:	eb cb                	jmp    f01025f4 <__udivdi3+0xd4>
f0102629:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102630:	89 d8                	mov    %ebx,%eax
f0102632:	31 ff                	xor    %edi,%edi
f0102634:	eb be                	jmp    f01025f4 <__udivdi3+0xd4>
f0102636:	66 90                	xchg   %ax,%ax
f0102638:	66 90                	xchg   %ax,%ax
f010263a:	66 90                	xchg   %ax,%ax
f010263c:	66 90                	xchg   %ax,%ax
f010263e:	66 90                	xchg   %ax,%ax

f0102640 <__umoddi3>:
f0102640:	55                   	push   %ebp
f0102641:	57                   	push   %edi
f0102642:	56                   	push   %esi
f0102643:	53                   	push   %ebx
f0102644:	83 ec 1c             	sub    $0x1c,%esp
f0102647:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010264b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010264f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0102653:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102657:	85 ed                	test   %ebp,%ebp
f0102659:	89 f0                	mov    %esi,%eax
f010265b:	89 da                	mov    %ebx,%edx
f010265d:	75 19                	jne    f0102678 <__umoddi3+0x38>
f010265f:	39 df                	cmp    %ebx,%edi
f0102661:	0f 86 b1 00 00 00    	jbe    f0102718 <__umoddi3+0xd8>
f0102667:	f7 f7                	div    %edi
f0102669:	89 d0                	mov    %edx,%eax
f010266b:	31 d2                	xor    %edx,%edx
f010266d:	83 c4 1c             	add    $0x1c,%esp
f0102670:	5b                   	pop    %ebx
f0102671:	5e                   	pop    %esi
f0102672:	5f                   	pop    %edi
f0102673:	5d                   	pop    %ebp
f0102674:	c3                   	ret    
f0102675:	8d 76 00             	lea    0x0(%esi),%esi
f0102678:	39 dd                	cmp    %ebx,%ebp
f010267a:	77 f1                	ja     f010266d <__umoddi3+0x2d>
f010267c:	0f bd cd             	bsr    %ebp,%ecx
f010267f:	83 f1 1f             	xor    $0x1f,%ecx
f0102682:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102686:	0f 84 b4 00 00 00    	je     f0102740 <__umoddi3+0x100>
f010268c:	b8 20 00 00 00       	mov    $0x20,%eax
f0102691:	89 c2                	mov    %eax,%edx
f0102693:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102697:	29 c2                	sub    %eax,%edx
f0102699:	89 c1                	mov    %eax,%ecx
f010269b:	89 f8                	mov    %edi,%eax
f010269d:	d3 e5                	shl    %cl,%ebp
f010269f:	89 d1                	mov    %edx,%ecx
f01026a1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026a5:	d3 e8                	shr    %cl,%eax
f01026a7:	09 c5                	or     %eax,%ebp
f01026a9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01026ad:	89 c1                	mov    %eax,%ecx
f01026af:	d3 e7                	shl    %cl,%edi
f01026b1:	89 d1                	mov    %edx,%ecx
f01026b3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01026b7:	89 df                	mov    %ebx,%edi
f01026b9:	d3 ef                	shr    %cl,%edi
f01026bb:	89 c1                	mov    %eax,%ecx
f01026bd:	89 f0                	mov    %esi,%eax
f01026bf:	d3 e3                	shl    %cl,%ebx
f01026c1:	89 d1                	mov    %edx,%ecx
f01026c3:	89 fa                	mov    %edi,%edx
f01026c5:	d3 e8                	shr    %cl,%eax
f01026c7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01026cc:	09 d8                	or     %ebx,%eax
f01026ce:	f7 f5                	div    %ebp
f01026d0:	d3 e6                	shl    %cl,%esi
f01026d2:	89 d1                	mov    %edx,%ecx
f01026d4:	f7 64 24 08          	mull   0x8(%esp)
f01026d8:	39 d1                	cmp    %edx,%ecx
f01026da:	89 c3                	mov    %eax,%ebx
f01026dc:	89 d7                	mov    %edx,%edi
f01026de:	72 06                	jb     f01026e6 <__umoddi3+0xa6>
f01026e0:	75 0e                	jne    f01026f0 <__umoddi3+0xb0>
f01026e2:	39 c6                	cmp    %eax,%esi
f01026e4:	73 0a                	jae    f01026f0 <__umoddi3+0xb0>
f01026e6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01026ea:	19 ea                	sbb    %ebp,%edx
f01026ec:	89 d7                	mov    %edx,%edi
f01026ee:	89 c3                	mov    %eax,%ebx
f01026f0:	89 ca                	mov    %ecx,%edx
f01026f2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01026f7:	29 de                	sub    %ebx,%esi
f01026f9:	19 fa                	sbb    %edi,%edx
f01026fb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01026ff:	89 d0                	mov    %edx,%eax
f0102701:	d3 e0                	shl    %cl,%eax
f0102703:	89 d9                	mov    %ebx,%ecx
f0102705:	d3 ee                	shr    %cl,%esi
f0102707:	d3 ea                	shr    %cl,%edx
f0102709:	09 f0                	or     %esi,%eax
f010270b:	83 c4 1c             	add    $0x1c,%esp
f010270e:	5b                   	pop    %ebx
f010270f:	5e                   	pop    %esi
f0102710:	5f                   	pop    %edi
f0102711:	5d                   	pop    %ebp
f0102712:	c3                   	ret    
f0102713:	90                   	nop
f0102714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102718:	85 ff                	test   %edi,%edi
f010271a:	89 f9                	mov    %edi,%ecx
f010271c:	75 0b                	jne    f0102729 <__umoddi3+0xe9>
f010271e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102723:	31 d2                	xor    %edx,%edx
f0102725:	f7 f7                	div    %edi
f0102727:	89 c1                	mov    %eax,%ecx
f0102729:	89 d8                	mov    %ebx,%eax
f010272b:	31 d2                	xor    %edx,%edx
f010272d:	f7 f1                	div    %ecx
f010272f:	89 f0                	mov    %esi,%eax
f0102731:	f7 f1                	div    %ecx
f0102733:	e9 31 ff ff ff       	jmp    f0102669 <__umoddi3+0x29>
f0102738:	90                   	nop
f0102739:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102740:	39 dd                	cmp    %ebx,%ebp
f0102742:	72 08                	jb     f010274c <__umoddi3+0x10c>
f0102744:	39 f7                	cmp    %esi,%edi
f0102746:	0f 87 21 ff ff ff    	ja     f010266d <__umoddi3+0x2d>
f010274c:	89 da                	mov    %ebx,%edx
f010274e:	89 f0                	mov    %esi,%eax
f0102750:	29 f8                	sub    %edi,%eax
f0102752:	19 ea                	sbb    %ebp,%edx
f0102754:	e9 14 ff ff ff       	jmp    f010266d <__umoddi3+0x2d>
