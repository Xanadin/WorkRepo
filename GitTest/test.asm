IFDEF ASMX86_32
	.model flat,c
	include TestStruct_.inc
	extern malloc:proc
	extern free:proc
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
		; sarebbe jbe per numeri senza segno
		mov eax, ecx				;eax = min(a,b)

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
		; sarebbe jae per numeri senza segno
		mov eax, ecx				;eax = max(a,b)

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
		mov eax, [ebp+8]			;eax = 'a'
		mov ecx, [ebp+12]			;ecx = 'b'

; Determine smallest value using the CMOVG instruction
		cmp eax, ecx
		cmovg eax, ecx				;se eax > ecx allora eax = ecx
		;cmova per numeri senza segno
		mov ecx, [ebp+16]			;ecx = 'c'
		cmp eax, ecx
		cmovg eax, ecx				;eax = min(a, b, c)

		pop ebp
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
		mov eax, [ebp+8]			;eax = 'a'
		mov ecx, [ebp+12]			;ecx = 'b'

; Determine largest value using the CMOVL instruction
		cmp eax, ecx
		cmovl eax, ecx				;eax = max(a, b)
		;cmovb per numeri senza segno
		mov ecx, [ebp+16]			;ecx = 'c'
		cmp eax, ecx
		cmovl eax, ecx				;eax = max(a, b, c)

		pop ebp
		ret
SignedMaxB_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CalcArraySum
; -----------------------------------------------------------------------------------------

; extern "C" int CalcArraySum_(const int* x, int n);
;
; Description: This function sums the elements of a signed integer array.
; 

CalcArraySum_ proc
		push ebp
		mov ebp, esp
; Load arguments and initialize sum
		mov edx, [ebp+8]			;edx = 'x'
		mov ecx, [ebp+12]			;ecx = 'n'
		xor eax, eax				;eax = sum = 0

; Make sure 'n' is greater than zero
		cmp ecx, 0
		jle InvalidCount

; Calculate the array element sum
@@:		add eax, [edx]				;add next element to sum
		add edx, 4					;set pointer to next element
		dec ecx						;adjust counter (and set the flags)
		jnz @B

InvalidCount:
		pop ebp
		ret
CalcArraySum_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CalcArraySquares
; -----------------------------------------------------------------------------------------

; extern "C" int CalcArraySquares_(int* y, const int* x, int n);
;
;Description: This function cComputes y[i] = x[i] * x[i].
;
; Returns: Sum of the elements in array y.

CalcArraySquares_ proc
		push ebp
		mov ebp, esp
		push ebx
		push esi
		push edi

; Load arguments
		mov edi, [ebp+8]			;edi = 'y'
		mov esi, [ebp+12]			;esi = 'x'
		mov ecx, [ebp+16]			;ecx = 'n'

; Initialize array sum register, calculate size of array in bytes,
; and initialize element offset register.
		xor eax, eax				;eax = sum of 'y' array = 0
		cmp ecx, 0
		jle EmptyArray
		shl ecx, 2					;ecx = ecx*4
		xor ebx, ebx				;ebx = array element offset = 0

; Repeat loop until finished
@@:		mov edx, [esi+ebx]			;load next x[i]
		imul edx, edx				;compute x[i] * x[i]
		mov [edi+ebx], edx			;save result to y[i]
		add eax, edx				;update running sum
		add ebx, 4					;update array element offset
		cmp ebx, ecx				;ebx < n ?
		jl @B						;jump if not finished (ebx >= n)

EmptyArray:
		pop edi
		pop esi
		pop ebx
		pop ebp
		ret
CalcArraySquares_ endp
; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CalcArraySquares
; -----------------------------------------------------------------------------------------

; extern "C" int CalcMatrixRowColSums_(const int* x, int nrows, int ncols, int* row_sums, int* col_sums);
;
; Description: The following function sums the rows and columns of a 2-D matrix.
;
; Returns: 0 = 'nrows' or 'ncols' is invalid
; 1 = success

CalcMatrixRowColSums_ proc
		push ebp
		mov ebp, esp
		push ebx
		push esi
		push edi

; Make sure 'nrow' and 'ncol' are valid
		xor eax, eax					;error return code
		cmp dword ptr [ebp+12], 0		;[ebp+12] = 'nrows'
		jle InvalidArg					;jump if nrows <= 0
		mov ecx, [ebp+16]				;ecx = 'ncols'
		cmp ecx, 0
		jle InvalidArg					;jump if ncols <= 0

; Initialize elements of 'col_sums' array to zero
		mov edi, [ebp+24]				;edi = 'col_sums'
		xor eax, eax					;eax = fill value
		rep stosd						;fill array with eax value
		;repeat store string doubleword
		;stosd salva nella posizione di edi il valore di eax e avanza il puntatore edi al valore successivo
		;rep ripete l'istruzione seguente e decrementa ecx di 1 fino a quando non arriva a zero

; Initialize outer loop variables
		mov ebx, [ebp+8]				;ebx = 'x'
		xor esi, esi					;esi = i = 0

; Outer loop
Lp1:	mov edi, [ebp+20]				;edi = 'row_sums'
		mov dword ptr [edi + esi*4], 0	;row_sums[i] = 0

		xor edi,edi						;edi = j = 0
		mov edx, esi					;edx = i
		imul edx, [ebp+16]				;edx = i * ncols

; Inner loop
Lp2:	mov ecx, edx					;ecx = i * ncols
		add ecx, edi					;ecx = i * ncols + j
		mov eax, [ebx + ecx*4]			;eax = x[i * ncols + j]
		mov ecx, [ebp + 20]				;ecx = 'row_sums'
		add [ecx + esi*4], eax			;row_sums[i] += eax
		mov ecx, [ebp + 24]				;ecx = 'col_sums'
		add [ecx + edi*4], eax			;col_sums[i] += eax
; Is inner loop finished?
		inc edi							;j++
		cmp	edi, [ebp+16]				;j < ncols ?
		jl Lp2					
		
; Is outer loop finished?
		inc esi							;i++
		cmp esi, [ebp+12]				;i < nrows ?
		jl Lp1					
		mov eax, 1						;set success return code

InvalidArg:
		pop edi
		pop esi
		pop ebx
		pop ebp
		ret
CalcMatrixRowColSums_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CalcStructSum
; -----------------------------------------------------------------------------------------

; extern "C" __int64 CalcStructSum_(const TestStruct* ts);
;
; Description: This function sums the members of a TestStruc.
;
; Returns: Sum of 'ts' members as a 64-bit integer.

CalcStructSum_ proc
		push ebp
		mov ebp, esp
		push ebx
		push esi

; Compute ts->Val8 + ts->Val16, note sign extension to 32-bits
		mov esi, [ebp+8]
		movsx	eax, byte ptr [esi+TestStruct.Val8]
		movsx	ecx, word ptr [esi+TestStruct.Val16]
		add eax, ecx

; Sign extend previous sum to 64 bits, save result to ebx:ecx
		cdq							;sign extend eax in edx:eax ConvertDwordQuad
		mov ebx, eax				;save the lobits to ebx
		mov ecx, edx				;save the hibits to ecx

; Add ts->Val32 to sum
		mov	eax, [esi+TestStruct.Val32]
		cdq
		add eax, ebx
		adc edx, ecx

; Add ts->Val64 to sum
		add eax, dword ptr [esi+TestStruct.Val64]
		adc edx, dword ptr [esi+TestStruct.Val64+4]

		pop esi
		pop ebx
		pop ebp
		ret
CalcStructSum_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CreateTestStruct
; -----------------------------------------------------------------------------------------

; extern "C" TestStruct* CreateTestStruct_(__int8 val8, __int16 val16, __int32 val32, __int64 val64);
;
; Description: This function allocates and initializes a new TestStruct.
;
; Returns: A pointer to the new TestStruct or NULL error occurred.

CreateTestStruct_ proc
		push ebp
		mov ebp, esp

; Allocate a block of memory for the new TestStruct; note that
; malloc() returns a pointer to memory block in EAX
		push sizeof TestStruct							;inserisce nello stack l'argomento della funzione malloc (il numero di bytes da allocare)

;	sizeof(TestStruct)	[EBP-20]	Low Memory	[ESP]	push	^
;	ebp					[EBP]									|
;	return address		[EBP+4] = [ebp]							|
;	val8				[EBP+8]									|
;	val16				[EBP+12]								|
;	val32				[EBP+16]								|
;	val64				[EBP+20]	High Memory			pop		v

		call malloc
		add esp, 4					; ripristina lo stack eliminando gli argomenti della funzione chiamata
		or eax, eax					; NULL pointer test
		jz MallocError				; Jump if malloc failed

; Initialize the new TestStruct
		mov dl, [ebp+8]
		mov	[eax+TestStruct.Val8], dl
		mov dx, [ebp+12]
		mov [eax+TestStruct.Val16], dx
		mov edx, [ebp+16]
		mov [eax+TestStruct.Val32], edx
		mov ecx, [ebp+20]
		mov edx, [ebp+24]
		mov dword ptr [eax+TestStruct.Val64], ecx
		mov dword ptr [eax+TestStruct.Val64+4], edx

MallocError:
		pop ebp
		ret
CreateTestStruct_ endp

; extern "C" void ReleaseTestStruct_(TestStruct* p);
;
; Description: This function release a previously created TestStruct.
;
; Returns: None.

ReleaseTestStruct_ proc
		push ebp
		mov ebp, esp

; Call free() to release previously created TestStruct
		push [ebp+8]				; inserisce nello stack il puntatore a ts
		call free
		add esp,4					; pulisce lo stack
		pop ebp
		ret
ReleaseTestStruct_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								CreateTestStruct
; -----------------------------------------------------------------------------------------

; extern "C" int CountChars_(wchar_t* s, wchar_t c);
;
; Description: This function counts the number of occurrences
; of 'c' in 's'
;
; Returns: Number of occurrences of 'c'

CountChars_ proc
		push ebp
		mov ebp, esp
		push esi

; Load parameters and initialize count registers
		mov esi, [ebp+8]			;esi = 's'
		mov cx, [ebp+12]			;cd = 'c'
		xor edx, edx				;edx = Number of occurrences

; Repeat loop until the entire string has been scanned
@@:		lodsw						;load next char into ax: LOaDStringWord (con char è lodsb che usa AL invece di AX)
		or ax, ax					;test for end-of-string: '\0'
		jz @F						;jump if end-of-string found
		cmp ax, cx					;test current char
		jne @B						;jump if no match
		inc edx						;update match count
		jmp @B

@@:		mov eax, edx				;eax = character count
		pop esi
		pop ebp
		ret
CountChars_ endp

; -----------------------------------------------------------------------------------------

; -----------------------------------------------------------------------------------------
;								ConcatStrings
; -----------------------------------------------------------------------------------------

; extern "C" int ConcatStrings_(wchar_t* des, int des_size, const wchar_t* const* src, int src_n);
;
; Description: This function performs string concatenation using
; multiple input strings.
;
; Returns: -1 Invalid 'des_size'
; n >=0 Length of concatenated string
; Locals Vars: 
; [ebp-4] = des_index
; [ebp-8] = i

ConcatStrings_ proc
		push ebp
		mov ebp, esp
		sub esp, 8
		push ebx
		push esi
		push edi

; Make sure 'des_size' is valid
		mov eax, -1
		mov ecx, [ebp+12]			;ecx = 'des_size'
		cmp ecx, 0
		jle Error

; Perform required initializations
		xor eax, eax
		mov ebx, [ebp+8]			;ebx = 'des'
		mov [ebx], ax				;*des = '\0'
		mov [ebp-4], eax			;des_index = 0
		mov [ebp-8], eax			;i = 0

; Repeat loop until concatenation is finished
Lp1:	mov eax, [ebp+16]			;eax = 'src'
		mov edx, [ebp-8]			;edx = i
		mov edi, [eax+edx*4]		;edi = src[i] (usato da scasw)
		mov esi, edi				;esi = src[i] (usato da movsw)

; Compute length of s[i]
		xor eax, eax				;eax = '\0'
		mov ecx, -1
		repne scasw					;find '\0'
; repne : repeats string instruction while ECX != 0 && EFLAGS.ZF == 0
; scasw (SCAnStringWord) : While (ECX != 0) {cmp [EDI], AX (set the flags); EDI += 2; ECX--}
		not ecx						;ecx = -(L + 2)
		dec ecx						;ecx = len(src[i])
; il complemento di -n è sempre n - 1 => (!(-(x+2))-1) = x
; the Visual C++ run-time environment assumes that EFLAGS.DF is always cleared. If an assembly language function sets EFLAGS.DF
; in order to perform an auto-decrement operation with a string instruction, the flag must be cleared before returning to the caller or using any library functions

; Compute des_index + src_len
		mov eax, [ebp-4]			;eax = des_index
		mov edx, eax				;edx = des_index_temp
		add eax, ecx				;des_index + len(src[i])

; Is des_index + src_len >=des_size?
		cmp eax, [ebp+12]
		jge Done
;Anche se sono uguali non va bene perchè bisogna poi aggiungere '\0'

; Update des_index
		add [ebp-4], ecx			;des_index += len(src[i])

; Copy src[i] to &des[des_index] (esi already contains src[i])
		inc ecx						;ecx = len(src[i]) + 1	(per includere '\0')
		lea edi, [ebx+edx*2]		;edi = &des[des_index_temp] LoadEffectiveAddress
		rep movsw					;perform string move
;REPeat MOVeStringWord copies the string pointed to by ESI to the memory location pointed to by EDI using the length specified by ECX

; Update i and repeat if not done
		mov eax, [ebp-8]
		inc eax
		mov [ebp-8], eax			;i++
		cmp eax, [ebp+20]
		jl Lp1

; Return length of concatenated string
Done:	mov eax, [ebp-4]			;eax = des_index
Error:	pop edi
		pop esi
		pop ebx
		mov esp, ebp
		pop ebp
		ret
ConcatStrings_ endp

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