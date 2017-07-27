IFDEF ASMX86_32
	.model flat,c
	.code

; extern "C" int CalcResult1_(int a, int b, int c);
; extern "C" int CalcResult2_(int a, int b, int c, int* quo, int* rem);
; extern "C" int CalcResult4_(int* y, const int* x, int n);

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