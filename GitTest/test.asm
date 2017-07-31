IFDEF ASMX86_32
	.model flat,c
	.code

; extern "C" int CalcResult1_(int a, int b, int c);

CalcResult1_ proc
	push ebp
	mov ebp, esp

	mov eax, [ebp+8]	;eax = a
	mov ecx, [ebp+12]	;ecx = b
	mov edx, [ebp+16]	;edx = c

	add eax, ecx		;eax = a + b
	imul eax, edx		;eax = (a + b) * c

	pop ebp
	ret
CalcResult1_ endp

; extern "C" int CalcResult2_(int a, int b, int c, int* quo, int* rem);

CalcResult2_ proc
	push ebp
	mov ebp, esp

; Calculate (a + b) / c
	mov eax, [ebp+8]			;eax = a
	mov ecx, [ebp+12]			;ecx = b
	add eax, ecx				;eax = a + b

	cdq							;edx:eax contains dividend
	idiv dword ptr [ebp+16]		;eax = quotient, edx = rem

	mov ecx,[ebp+20]			;ecx = ptr to quo
	mov dword ptr [ecx], eax	;save quotient
	mov ecx, [ebp+24]			;ecx = ptr to rem
	mov dword ptr [ecx], edx	;save remainder

	pop ebp
	ret
CalcResult2_ endp

; extern "C" int CalcSum_(int a, int b, int c)
;
; Description: This function demonstrates passing arguments between
; a C++ function and an assembly language function.
;
; Returns: a + b + c

CalcSum_ proc

; Initialize a stack frame pointer
	push ebp
	mov ebp, esp

; Load the argument values
	mov eax, [ebp+8]				;eax = 'a'
	mov ecx, [ebp+12]				;ecx = 'b'
	mov edx, [ebp+16]				;edx = 'c'

; Calculate the sum
	add eax, ecx					;eax = 'a' + 'b'
	add eax, edx					;eax = 'a' + 'b' + 'c'

; Restore the caller's stack frame pointer
	pop ebp
	ret
CalcSum_ endp

; ------------------------------------------------------------------------------------

; extern "C" int IntegerMulDiv_(int a, int b, int* prod, int* quo, int* rem);
;
; Description: This function demonstrates use of the imul and idiv
; instructions. It also illustrates pointer usage.
;
; Returns: 0 Error (divisor is zero)
; 1 Success (divisor is zero)
;
; Computes: *prod = a * b;
; *quo = a / b
; *rem = a % b

IntegerMulDiv_ proc

; Function prolog
	push ebp
	mov ebp, esp
	push ebx

;	Stack

;	original ebx		;Low Memory
;	original ebp
;	return address
;	a
;	b
;	&prod
;	&quo
;	&rem				;High Memory

; Function prolog
	xor eax, eax					;set error return code = 0
	mov ecx, [ebp+8]				;ecx = 'a'
	mov edx, [ebp+12]				;edx = 'b'
	or edx, edx						;test for 0: (edx = edx - edx) se e solo se edx = 0 => ZF = 0. In più preserva il valore di edx
	jz InvalidDivisor				;jump if 'b' is zero

; Calculate product and save result
	imul edx, ecx					;edx = 'a' * 'b' troncando il risultato a 32 bit
	; per avere il risultato in 64 bit, si usa imul ecx (in questo caso) che salva il risultato in edx:eax
	mov ebx, [ebp+16]				;ebx = 'prod'
	mov [ebx], edx					;save product

; Calculate quotient and remainder, save results
	mov eax, ecx					;eax = 'a'
	cdq								;sign extend (Convert Dword to Quadword)
	;edx:eax contains dividend, idiv può eseguire anche divisioni a 16 o 8 bit, da cui la specificazione sotto delle dimensioni del divisore
	idiv dword ptr [ebp+12]			;eax = quo, edx = rem

	mov ebx, [ebp+20]				;ebx = 'quo'
	mov [ebx], eax					;save quotient
	mov ebx, [ebp+24]				;ebx = 'rem'
	mov [ebx], edx					;save remainder
	mov eax, 1

; Function epilog
InvalidDivisor:
	pop ebx
	pop ebp
	ret

; -------------------------------------------------------------------------------------------

IntegerMulDiv_ endp

; extern "C" void CalculateSums_(int a, int b, int c, int* s1, int* s2, int* s3);
;
; Description: This function demonstrates a complete assembly language prolog and epilog.
;
; Returns: None.
;
; Computes: *s1 = a + b + c
; *s2 = a * a + b * b + c * c
; *s3 = a * a * a + b * b * b + c * c * c

CalculateSums_ proc

; Function prolog
	push ebp
	mov ebp, esp
	sub esp, 12			;Allocate local storage space for 3*32bit variables
	push ebx
	push esi
	push edi

;	Stack

;	edi					[EBP-24]	Low Memory	[ESP]
;	esi					[EBP-20]
;	ebx					[EBP-16]
;	Localvar3			[EBP-12]		
;	Localvar2			[EBP-8]
;	Localvar1			[EBP-4]
;	ebp					EBP
;	return address		[original EBP]
;	a					[EBP+8]
;	b					[EBP+12]
;	c					[EBP+16]
;	&s1					[EBP+20]
;	&s2					[EBP+24]
;	&s3					[EBP+28]	High Memory

; Load arguments
	mov eax, [ebp+8]	;EAX = 'a'
	mov ebx, [ebp+12]	;EBX = 'b'
	mov ecx, [ebp+16]	;ECX = 'c'
	mov edx, [ebp+20]	;EDX = '&s1'
	mov esi, [ebp+24]	;ESI = '&s2'
	mov edi, [ebp+28]	;EDI = '&s3'

; Compute 's1'
	mov [ebp-12], eax
	add	[ebp-12], ebx
	add [ebp-12], ecx	;final 's1' result

; Compute 's2'
	imul eax, eax
	imul ebx, ebx
	imul ecx, ecx
	mov [ebp-8], eax
	add [ebp-8], ebx
	add [ebp-8], ecx	;final 's2' result

; Compute 's3'
	imul eax, [ebp+8]
	imul ebx, [ebp+12]
	imul ecx, [ebp+16]
	mox [ebp-4], eax
	add [ebp-4], ebx
	add [ebp-4], ecx	;final 's3' result

; Save 's1', 's2', and 's3'

	mov eax, [ebp-12]
; Function epilog
	ret

CalculateSums_ endp

; -----------------------------------------------------------------------------------------

; extern "C" int CalcResult4_(int* y, const int* x, int n);

CalcResult4_ proc
		push ebp
		mov ebp, esp
		push ebx
		push esi

		mov ecx, [ebp+8]			;ecx = ptr to y
		mov edx, [ebp+12]			;edx = ptr to x
		mov ebx, [ebp+16]			;ebx = n
		test ebx, ebx				;is n <= 0?
		jle Error					;jump if n <= 0

		xor esi, esi				;i = 0;
@@:		mov eax, [edx+esi*4]		;eax = x[i]
		imul eax, eax				;eax = x[i] * x[i]
		mov [ecx+esi*4], eax		;save result to y[i]

		add esi, 1					;i = i + 1
		cmp esi, ebx
		jl @B						;jump if i < n

		mov eax, 1					;set success return code
		pop esi
		pop ebx
		pop ebp
		ret

Error:	xor eax, eax				;set error return code
		pop esi
		pop ebx
		pop ebp
		ret
CalcResult4_ endp
ENDIF

IFDEF ASMX86_64
	.code

CalcResult4_ proc
		; Register arguments: rcx = ptr to y, rdx = ptr to x, and r8d = n
		movsxd r8, r8d					;sign-extend n to 64 bits
		test r8, r8						;is n <= 0?
		jle Error						;jump if n <= 0

		xor r9, r9						;i = 0;
@@:		mov eax, [rdx+r9*4]				;eax = x[i]
		imul eax, eax					;eax == x[i] * x[i]
		mov [rcx+r9*4], eax				;save result to y[i]

		add r9, 1						;i = i + 1
		cmp r9, r8
		jl @B							;jump if i < n

		mov eax, 1						;set success return code
		ret

Error:	xor eax, eax					;set error return code
		ret
CalcResult4_ endp
ENDIF

	end