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

; Function prolog
	xor eax, eax					;set error return code
	mov ecx, [ebp+8]				;ecx = 'a'
	mov edx, [ebp+12]				;edx = 'b'
	or edx, edx
	jz InvalidDivisor				;jump if 'b' is zero

; Calculate product and save result
	imul edx, ecx					;edx = 'a' * 'b'
	mov ebx, [ebp+16]				;ebx = 'prod'
	mov [ebx], edx					;save product

; Calculate quotient and remainder, save results
	mov eax, ecx					;eax = 'a'
	cdq								;edx:eax contains dividend
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