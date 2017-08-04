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

IntegerMulDiv_ endp

; -------------------------------------------------------------------------------------------

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

; According to the Visual C++ calling convention that is defined for 32-bit programs,
; a called function must preserve the values of the following registers: EBX, ESI, EDI, and EBP
; sono chiamati non-volatile registers

;	Stack

;	edi					[EBP-24]	Low Memory	[ESP]	push	^
;	esi					[EBP-20]								|
;	ebx					[EBP-16]								|
;	Localvar3			[EBP-12]		
;	Localvar2			[EBP-8]
;	Localvar1			[EBP-4]
;	ebp					[EBP]
;	return address		[EBP+4] = [ebp]
;	a					[EBP+8]
;	b					[EBP+12]
;	c					[EBP+16]
;	&s1					[EBP+20]								|
;	&s2					[EBP+24]								|
;	&s3					[EBP+28]	High Memory			pop		v

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
	mov [ebp-4], eax
	add [ebp-4], ebx
	add [ebp-4], ecx	;final 's3' result

; Save 's1', 's2', and 's3'
	mov eax, [ebp-12]	;Non si può fare un mov da memoria a memoria per cui si passa da un reg intermedio
	mov [edx], eax		;save 's1'
	mov eax, [ebp-8]
	mov [esi], eax		;save 's2'
	mov eax, [ebp-4]
	mov [edi], eax

; Function epilog
	pop edi
	pop esi
	pop ebx
	mov esp, ebp		;Release local storage space, poteva anche essere (add esp, 12)
	pop ebp
	ret

CalculateSums_ endp

; -----------------------------------------------------------------------------------------
;								MemoryAddressing_
; -----------------------------------------------------------------------------------------

; Simple lookup table (.const section data is read only)
			.const
FibVals		dword 0, 1, 1, 2, 3, 5, 8, 13
			dword 21, 34, 55, 89, 144, 233, 377, 610

NumFibVals_ dword ($ - FibVals) / sizeof dword			;$ indica l'indirizzo dell'istruzione corrente
			public NumFibVals_

; extern "C" int MemoryAddressing_(int i, int* v1, int* v2, int* v3, int* v4);
;
; Description: This function demonstrates various addressing
; modes that can be used to access operands in
; memory.
;
; Returns: 0 = error (invalid table index)
; 1 = success

	.code
MemoryAddressing_ proc
	push ebp
	mov ebp, esp
	push ebx
	push esi
	push edi


;	Stack

;	edi					[EBP-12]	Low Memory	[ESP]	push	^
;	esi					[EBP-8]									|
;	ebx					[EBP-4]									|
;	ebp					[EBP]
;	return address		[EBP+4] = [ebp]
;	i					[EBP+8]
;	&v1					[EBP+12]
;	&v2					[EBP+16]								|
;	&v3					[EBP+20]								|
;	&v4					[EBP+24]	High Memory			pop		v

; Make sure 'i' is valid
	xor eax,eax
	mov ecx, [ebp+8]			;ecx = i
	cmp ecx, 0
	jl InvalidIndex				;jump if i < 0
	cmp ecx, [NumFibVals_]
	jge InvalidIndex			;jump if i >= NumFibVals_

; Example #1 - base register
	mov ebx, offset FibVals		;ebx = &FibVals
	mov esi, [ebp+8]			;esi = i
	shl esi, 2					;esi = i * 4
	add ebx, esi				;ebx = &FibVals + i * 4
	mov eax, [ebx]				;Load table value
	mov edi, [ebp+12]
	mov [edi], eax				;Save to 'v1'

; Example #2 - base register + displacement
; esi is used as the base register
	mov esi, [ebp+8]			;esi = i
	shl esi, 2					;esi = i * 4
	mov eax, [esi + FibVals]	;Load table value
	mov edi, [ebp+16]
	mov	[edi], eax				;Save to 'v2'

; Example #3 - base register + index register
	mov ebx, offset FibVals		;ebx = &FibVals
	mov esi, [ebp+8]			;esi = i
	shl esi, 2					;esi = i * 4
	mov eax, [ebx+esi]			;Load table value
	mov edi, [ebp+20]
	mov [edi], eax				;Save to 'v3'

; Example #4 - base register + index register * scale factor
	mov ebx, offset FibVals		;ebx = &FibVals
	mov esi, [ebp+8]			;esi = i
	mov eax, [ebx+esi*4]		;Load table value
	mov	edi, [ebp+24]
	mov	[edi], eax				;Save to 'v4'

	mov eax, 1

InvalidIndex:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret
MemoryAddressing_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								IntegerAddition_
; -----------------------------------------------------------------------------------------

; extern "C" void IntegerAddition_(char a, short b, int c, long long d);
;
; Description: This function demonstrates simple addition using
; various-sized integers.
;
; Returns: None.

; These are defined in IntegerAddition.cpp
		extern GlChar:byte
		extern GlShort:word
		extern GlInt:dword
		extern GlLongLong:qword

IntegerAddition_ proc
		push ebp
		mov ebp, esp

;	Stack

;	ebp					[EBP]		Low Memory	[ESP]	push	^
;	return address		[EBP+4] = [ebp]							|
;	a					[EBP+8]									|
;	b					[EBP+12]								|
;	c					[EBP+16]								|
;	d					[EBP+20]	High Memory			pop		v
;   Visual C++ size extends 8-bit and 16-bit values to 32 bits before pushing them onto the stack
;   This ensures that the stack pointer register ESP is always properly aligned to a 32-bit boundary

; Compute GlChar += a
		mov al, [ebp+8]
		add [GlChar], al

; Compute GlShort += b, note offset of 'b' on stack	
		mov ax, [ebp+12]
		add [GlShort], ax

; Compute GlInt += c, note offset of 'c' on stack
		mov eax, [ebp+16]
		add [GlInt], eax

; Compute GlLongLong += d, note use of dword ptr operator and adc
		mov eax, [ebp+20]
		mov edx, [ebp+24]
		add dword ptr [GlLongLong], eax			;dword ptr perchè GlLongLong altrimenti è dichiarato come 64 bit
		adc dword ptr [GlLongLong+4], edx		;add with carry, il carry della addizione precedente

		pop ebp
		ret
IntegerAddition_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								ConditionCodes
; -----------------------------------------------------------------------------------------

; extern "C" int SignedMinA_(int a, int b, int c);
;
; Description: Determines minimum of three signed integers
; using conditional jumps.
;
; Returns min(a, b, c)

SignedMinA_ proc
		push ebp
		mov ebp, esp

		mov eax, [ebp+8]			;eax = 'a'
		mov ecx, [ebp+12]			;ecx = 'b'

; Determine min(a, b)
		cmp eax, ecx
		jle @F						;eax <= ecx
		mov eac, ecx				;eax = min(a,b)

; Determine min(a, b, c)
	@@: mov ecx, [ebp+16]			;ecx = 'c'
		cmp eax, ecx
		jle @F
		mov eax, ecx				;eax - ecx > 0 => ecx < eax


	@@:	pop ebp
		ret
SignedMinA_ endp

; extern "C" int SignedMaxA_(int a, int b, int c);
;
; Description: Determines maximum of three signed integers
; using conditional jumps.
;
; Returns: max(a, b, c)

SignedMaxA_ proc
		push ebp
		mov ebp, esp

		mov eax, [ebp+8]			;eax = 'a'
		mov ecx, [ebp+12]			;ecx = 'b'

; Determine min(a, b)
		cmp eax, ecx
		jge @F						;eax >= ecx
		mov eac, ecx				;eax = max(a,b)

; Determine min(a, b, c)
	@@: mov ecx, [ebp+16]			;ecx = 'c'
		cmp eax, ecx
		jge @F
		mov eax, ecx				;eax - ecx < 0 => ecx > eax

	@@:	pop ebp
		ret
SignedMaxA_ endp

; extern "C" int SignedMinB_(int a, int b, int c);
;
; Description: Determines minimum of three signed integers
; using conditional moves.
;
; Returns min(a, b, c)

SignedMinB_ proc
		push ebp
		mov ebp, esp

	@@:	pop ebp
		ret
SignedMinB_ endp

; extern "C" int SignedMaxB_(int a, int b, int c);
;
; Description: Determines maximum of three signed integers
; using conditional moves.
;
; Returns: max(a, b, c)

SignedMaxB_ proc
		push ebp
		mov ebp, esp

	@@: pop ebp
		ret
SignedMaxB_ endp

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