GLOBAL _irq00handler
GLOBAL _irq01handler
GLOBAL _int80handler
GLOBAL _sti
GLOBAL _cli
GLOBAL picMasterMask
GLOBAL picSlaveMask

EXTERN keyboardHandler
EXTERN timertickHandler
EXTERN syscallHandler
EXTERN _vWrite

%macro pushaq 0
    push rax      ;save current rax
    push rbx      ;save current rbx
    push rcx      ;save current rcx
    push rdx      ;savepushaq current rdx
    push rbp      ;save current rbp
    push rdi       ;save current rdi
    push rsi       ;save current rsi
    push r8        ;save current r8
    push r9        ;save current r9
    push r10      ;save current r10
    push r11      ;save current r11
    push r12      ;save current r12
    push r13      ;save current r13
    push r14      ;save current r14
    push r15      ;save current r15
%endmacro

%macro popaq 0
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdi
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
%endmacro

%macro END_INT 0
	mov al, 20h ; Acknowledge interruption was treated
	out PIC_MASTER_CONTROL, al ; and PIC can recieve the next one

	popaq
	iretq
%endmacro

section .text
; Constants
PIC_MASTER_CONTROL	equ	0x20
PIC_MASTER_MASK		equ 0x21
PIC_SLAVE_CONTROL	equ	0xA0
PIC_SLAVE_MASK		equ	0xA1
KBD_PORT			equ	0x60
KBD_STATUS			equ 0x61

; Disable interruptions
_cli:
	cli
	ret

; Enable interruptions
_sti:
	sti
	ret

picMasterMask:
	push rbp
    mov rbp, rsp
    mov ax, si
    out	PIC_MASTER_MASK, al
    pop rbp
    retn

picSlaveMask:
	push    rbp
    mov     rbp, rsp
    mov     ax, si  
    out		PIC_SLAVE_MASK, al
    pop     rbp
    retn

; Timer tick
_irq00handler:
	pushaq

	call timertickHandler

	END_INT

; Keyboard
_irq01handler:
	pushaq
	
	in al, KBD_PORT

	mov rdi, rax
	call keyboardHandler

	in al, KBD_STATUS
	or al, 80h
	out KBD_STATUS, al
	and al, 7Fh
	out KBD_STATUS, al

	END_INT

; System call
; recieves the system call code in rax
; and parameters in rdi, rsi, rdx, r10, r8 and r9
; We won't be using more than 3 params
_int80handler:
	pushaq

	mov rcx, rdx
	mov rdx, rsi
	mov rsi, rdi
	mov rdi, rax
	call syscallHandler

	popaq
	iretq
