;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RBP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "boolean-false?"
	dq 14
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x66, 0x61, 0x6C, 0x73, 0x65, 0x3F
	; L_constants + 1412:
	db T_string	; "boolean-true?"
	dq 13
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x2D
	db 0x74, 0x72, 0x75, 0x65, 0x3F
	; L_constants + 1434:
	db T_string	; "primitive?"
	dq 10
	db 0x70, 0x72, 0x69, 0x6D, 0x69, 0x74, 0x69, 0x76
	db 0x65, 0x3F
	; L_constants + 1453:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 1468:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 1486:
	db T_string	; "return"
	dq 6
	db 0x72, 0x65, 0x74, 0x75, 0x72, 0x6E
	; L_constants + 1501:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1514:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1527:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1540:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1567:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1581:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1595:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1609:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1623:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1637:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1651:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1665:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1680:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1695:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1710:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1725:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1740:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1755:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1770:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1785:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1800:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1815:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1830:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1845:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1860:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1875:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1890:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1905:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1919:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1932:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1944:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1962:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1976:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1993:
	db T_interned_symbol	; whatever
	dq L_constants + 1976
	; L_constants + 2002:
	db T_string	; "with"
	dq 4
	db 0x77, 0x69, 0x74, 0x68
	; L_constants + 2015:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 2029:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 2043:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 2055:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 2070:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 2086:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 2104:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2119:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2138:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2148:
	db T_integer	; 0
	dq 0
	; L_constants + 2157:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2191:
	db T_interned_symbol	; +
	dq L_constants + 2138
	; L_constants + 2200:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2241:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2251:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2264:
	db T_interned_symbol	; -
	dq L_constants + 2241
	; L_constants + 2273:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2283:
	db T_integer	; 1
	dq 1
	; L_constants + 2292:
	db T_interned_symbol	; *
	dq L_constants + 2273
	; L_constants + 2301:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2311:
	db T_interned_symbol	; /
	dq L_constants + 2301
	; L_constants + 2320:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2333:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2343:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2354:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2364:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2375:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2385:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2412:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2385
	; L_constants + 2421:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2463:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2478:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2494:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2509:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2524:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2540:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2562:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2582:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2591:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2643:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 2652:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2704:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2725:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2746:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 2761:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2782:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2803:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 2818:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2836:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 2854:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 2868:
	db T_integer	; 2
	dq 2
	; L_constants + 2877:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 2890:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 2902:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 2917:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2934:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 2948:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2970:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 2992:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3015:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3038:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3062:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3086:
	db T_string	; "make-list-generator...
	dq 19
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x67, 0x65, 0x6E, 0x65, 0x72, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 3114:
	db T_string	; "make-string-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3144:
	db T_string	; "make-vector-generat...
	dq 21
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x67, 0x65, 0x6E, 0x65
	db 0x72, 0x61, 0x74, 0x6F, 0x72
	; L_constants + 3174:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3192:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3201:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3217:
	db T_char, 0x0A	; #\newline
	; L_constants + 3219:
	db T_string	; "void"
	dq 4
	db 0x76, 0x6F, 0x69, 0x64
free_var_0:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2273

free_var_1:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2138

free_var_2:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2241

free_var_3:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2301

free_var_4:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2333

free_var_5:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2343

free_var_6:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2375

free_var_7:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2354

free_var_8:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2364

free_var_9:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_10:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_11:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_12:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_13:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_14:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_15:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_16:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_17:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_18:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_19:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_20:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_21:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_22:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_23:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_24:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_25:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_26:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_27:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_28:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2157

free_var_29:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_30:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2890

free_var_31:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2055

free_var_32:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2104

free_var_33:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2015

free_var_34:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2934

free_var_35:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1665

free_var_36:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1680

free_var_37:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_38:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1695

free_var_39:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1710

free_var_40:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1567

free_var_41:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1501

free_var_42:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1725

free_var_43:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1740

free_var_44:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1581

free_var_45:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1755

free_var_46:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1770

free_var_47:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1595

free_var_48:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1514

free_var_49:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_50:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1785

free_var_51:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1800

free_var_52:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1609

free_var_53:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1815

free_var_54:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1830

free_var_55:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1623

free_var_56:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1527

free_var_57:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1845

free_var_58:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1860

free_var_59:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1637

free_var_60:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1875

free_var_61:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_62:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1651

free_var_63:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1540

free_var_64:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_65:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_66:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2540

free_var_67:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2562

free_var_68:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2478

free_var_69:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2463

free_var_70:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2494

free_var_71:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2524

free_var_72:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2509

free_var_73:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_74:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_75:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_76:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2902

free_var_77:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_78:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2854

free_var_79:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2320

free_var_80:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2086

free_var_81:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2119

free_var_82:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_83:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_84:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_85:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_86:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1919

free_var_87:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1962

free_var_88:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2725

free_var_89:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2704

free_var_90:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1905

free_var_91:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3174

free_var_92:	; location of make-list-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3086

free_var_93:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_94:	; location of make-string-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3114

free_var_95:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_96:	; location of make-vector-generator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3144

free_var_97:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2043

free_var_98:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2836

free_var_99:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3201

free_var_100:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1932

free_var_101:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_102:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_103:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2877

free_var_104:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2029

free_var_105:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_106:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2818

free_var_107:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2803

free_var_108:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1944

free_var_109:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2251

free_var_110:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_111:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_112:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2070

free_var_113:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2761

free_var_114:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2948

free_var_115:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_116:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_117:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2992

free_var_118:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3038

free_var_119:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_120:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2917

free_var_121:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_122:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_123:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2746

free_var_124:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2782

free_var_125:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2970

free_var_126:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_127:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_128:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3015

free_var_129:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3062

free_var_130:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_131:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_132:	; location of void
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3219

free_var_133:	; location of with
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2002

free_var_134:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_135:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        push 0
        push 0
        push Lend
        enter 0, 0
	; building closure for null?
	mov rdi, free_var_101
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_105
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_73
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_121
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_131
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_110
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_83
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_102
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_74
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_134
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_49
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_64
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_115
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_126
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_84
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_82
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_65
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_122
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_135
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_85
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_12
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_10
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_26
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_23
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_9
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_25
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_22
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_13
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_11
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_27
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_24
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_15
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_77
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_20
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_19
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_21
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_16
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_18
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_111
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_116
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_127
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_130
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_119
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_95
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_93
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_75
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_29
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04bf
	jmp .L_lambda_simple_end_04bf
.L_lambda_simple_code_04bf:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04bf:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06a8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06a8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06a8
.L_tc_recycle_frame_done_06a8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04bf:	; new closure is in rax
	mov qword [free_var_41], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c0
	jmp .L_lambda_simple_end_04c0
.L_lambda_simple_code_04c0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06a9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06a9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06a9
.L_tc_recycle_frame_done_06a9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c0:	; new closure is in rax
	mov qword [free_var_48], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c1
	jmp .L_lambda_simple_end_04c1
.L_lambda_simple_code_04c1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06aa:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06aa
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06aa
.L_tc_recycle_frame_done_06aa:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c1:	; new closure is in rax
	mov qword [free_var_56], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c2
	jmp .L_lambda_simple_end_04c2
.L_lambda_simple_code_04c2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ab:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ab
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ab
.L_tc_recycle_frame_done_06ab:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c2:	; new closure is in rax
	mov qword [free_var_63], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c3
	jmp .L_lambda_simple_end_04c3
.L_lambda_simple_code_04c3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c3:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ac:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ac
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ac
.L_tc_recycle_frame_done_06ac:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c3:	; new closure is in rax
	mov qword [free_var_37], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c4
	jmp .L_lambda_simple_end_04c4
.L_lambda_simple_code_04c4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ad:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ad
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ad
.L_tc_recycle_frame_done_06ad:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c4:	; new closure is in rax
	mov qword [free_var_40], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c5
	jmp .L_lambda_simple_end_04c5
.L_lambda_simple_code_04c5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c5:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ae:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ae
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ae
.L_tc_recycle_frame_done_06ae:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c5:	; new closure is in rax
	mov qword [free_var_44], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c6
	jmp .L_lambda_simple_end_04c6
.L_lambda_simple_code_04c6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06af:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06af
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06af
.L_tc_recycle_frame_done_06af:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c6:	; new closure is in rax
	mov qword [free_var_47], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c7
	jmp .L_lambda_simple_end_04c7
.L_lambda_simple_code_04c7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c7:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b0:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b0
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b0
.L_tc_recycle_frame_done_06b0:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c7:	; new closure is in rax
	mov qword [free_var_52], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c8
	jmp .L_lambda_simple_end_04c8
.L_lambda_simple_code_04c8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c8:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b1:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b1
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b1
.L_tc_recycle_frame_done_06b1:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c8:	; new closure is in rax
	mov qword [free_var_55], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04c9
	jmp .L_lambda_simple_end_04c9
.L_lambda_simple_code_04c9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04c9:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b2:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b2
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b2
.L_tc_recycle_frame_done_06b2:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04c9:	; new closure is in rax
	mov qword [free_var_59], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ca
	jmp .L_lambda_simple_end_04ca
.L_lambda_simple_code_04ca:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ca:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b3:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b3
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b3
.L_tc_recycle_frame_done_06b3:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ca:	; new closure is in rax
	mov qword [free_var_62], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04cb
	jmp .L_lambda_simple_end_04cb
.L_lambda_simple_code_04cb:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cb:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b4:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b4
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b4
.L_tc_recycle_frame_done_06b4:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cb:	; new closure is in rax
	mov qword [free_var_35], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04cc
	jmp .L_lambda_simple_end_04cc
.L_lambda_simple_code_04cc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cc:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b5:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b5
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b5
.L_tc_recycle_frame_done_06b5:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cc:	; new closure is in rax
	mov qword [free_var_36], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04cd
	jmp .L_lambda_simple_end_04cd
.L_lambda_simple_code_04cd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cd:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b6:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b6
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b6
.L_tc_recycle_frame_done_06b6:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cd:	; new closure is in rax
	mov qword [free_var_38], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ce
	jmp .L_lambda_simple_end_04ce
.L_lambda_simple_code_04ce:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ce:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b7:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b7
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b7
.L_tc_recycle_frame_done_06b7:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ce:	; new closure is in rax
	mov qword [free_var_39], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04cf
	jmp .L_lambda_simple_end_04cf
.L_lambda_simple_code_04cf:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04cf:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b8
.L_tc_recycle_frame_done_06b8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04cf:	; new closure is in rax
	mov qword [free_var_42], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d0
	jmp .L_lambda_simple_end_04d0
.L_lambda_simple_code_04d0:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d0:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06b9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06b9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06b9
.L_tc_recycle_frame_done_06b9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d0:	; new closure is in rax
	mov qword [free_var_43], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d1
	jmp .L_lambda_simple_end_04d1
.L_lambda_simple_code_04d1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d1:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ba:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ba
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ba
.L_tc_recycle_frame_done_06ba:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d1:	; new closure is in rax
	mov qword [free_var_45], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d2
	jmp .L_lambda_simple_end_04d2
.L_lambda_simple_code_04d2:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d2:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06bb:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06bb
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06bb
.L_tc_recycle_frame_done_06bb:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d2:	; new closure is in rax
	mov qword [free_var_46], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d3
	jmp .L_lambda_simple_end_04d3
.L_lambda_simple_code_04d3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d3:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06bc:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06bc
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06bc
.L_tc_recycle_frame_done_06bc:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d3:	; new closure is in rax
	mov qword [free_var_50], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d4
	jmp .L_lambda_simple_end_04d4
.L_lambda_simple_code_04d4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d4:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06bd:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06bd
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06bd
.L_tc_recycle_frame_done_06bd:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d4:	; new closure is in rax
	mov qword [free_var_51], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d5
	jmp .L_lambda_simple_end_04d5
.L_lambda_simple_code_04d5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d5:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06be:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06be
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06be
.L_tc_recycle_frame_done_06be:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d5:	; new closure is in rax
	mov qword [free_var_53], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d6
	jmp .L_lambda_simple_end_04d6
.L_lambda_simple_code_04d6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06bf:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06bf
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06bf
.L_tc_recycle_frame_done_06bf:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d6:	; new closure is in rax
	mov qword [free_var_54], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d7
	jmp .L_lambda_simple_end_04d7
.L_lambda_simple_code_04d7:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d7:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c0:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c0
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c0
.L_tc_recycle_frame_done_06c0:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d7:	; new closure is in rax
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d8
	jmp .L_lambda_simple_end_04d8
.L_lambda_simple_code_04d8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d8:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_48]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c1:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c1
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c1
.L_tc_recycle_frame_done_06c1:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d8:	; new closure is in rax
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04d9
	jmp .L_lambda_simple_end_04d9
.L_lambda_simple_code_04d9:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04d9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04d9:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_56]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c2:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c2
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c2
.L_tc_recycle_frame_done_06c2:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04d9:	; new closure is in rax
	mov qword [free_var_60], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04da
	jmp .L_lambda_simple_end_04da
.L_lambda_simple_code_04da:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04da
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04da:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_63]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c3:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c3
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c3
.L_tc_recycle_frame_done_06c3:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04da:	; new closure is in rax
	mov qword [free_var_61], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04db
	jmp .L_lambda_simple_end_04db
.L_lambda_simple_code_04db:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04db
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04db:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0039
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cb
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c4:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c4
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c4
.L_tc_recycle_frame_done_06c4:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03cb
.L_if_else_03cb:
	mov rax, L_constants + 2
.L_if_end_03cb:
.L_or_end_0039:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04db:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a2
	jmp .L_lambda_opt_end_00a2
.L_lambda_opt_code_00a2:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00a2:	; new closure is in rax
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04dc
	jmp .L_lambda_simple_end_04dc
.L_lambda_simple_code_04dc:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04dc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04dc:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_03cc
	mov rax, L_constants + 2
	jmp .L_if_end_03cc
.L_if_else_03cc:
	mov rax, L_constants + 3
.L_if_end_03cc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04dc:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04dd
	jmp .L_lambda_simple_end_04dd
.L_lambda_simple_code_04dd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04dd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04dd:
	enter 0, 0
	mov rax, PARAM(0)	; param q
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003a
	mov rax, PARAM(0)	; param q
	push rax
	push 1
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06c5:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c5
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c5
.L_tc_recycle_frame_done_06c5:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_003a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04dd:	; new closure is in rax
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04de
	jmp .L_lambda_simple_end_04de
.L_lambda_simple_code_04de:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04de
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04de:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04df
	jmp .L_lambda_simple_end_04df
.L_lambda_simple_code_04df:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04df
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04df:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cd
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_03cd
.L_if_else_03cd:
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06c6:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c6
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c6
.L_tc_recycle_frame_done_06c6:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03cd:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04df:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a3
	jmp .L_lambda_opt_end_00a3
.L_lambda_opt_code_00a3:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06c7:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c7
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c7
.L_tc_recycle_frame_done_06c7:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00a3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04de:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e0
	jmp .L_lambda_simple_end_04e0
.L_lambda_simple_code_04e0:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04e0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e0:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, PARAM(1)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06c8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c8
.L_tc_recycle_frame_done_06c8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04e0:	; new closure is in rax
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e1
	jmp .L_lambda_simple_end_04e1
.L_lambda_simple_code_04e1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e1:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e2
	jmp .L_lambda_simple_end_04e2
.L_lambda_simple_code_04e2:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04e2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e2:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ce
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06c9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06c9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06c9
.L_tc_recycle_frame_done_06c9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ce
.L_if_else_03ce:
	mov rax, PARAM(0)	; param a
.L_if_end_03ce:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04e2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a4
	jmp .L_lambda_opt_end_00a4
.L_lambda_opt_code_00a4:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_12]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06ca:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ca
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ca
.L_tc_recycle_frame_done_06ca:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00a4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e1:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_33], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a5
	jmp .L_lambda_opt_end_00a5
.L_lambda_opt_code_00a5:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e3
	jmp .L_lambda_simple_end_04e3
.L_lambda_simple_code_04e3:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e3:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e4
	jmp .L_lambda_simple_end_04e4
.L_lambda_simple_code_04e4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e4:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03cf
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003b
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06cc:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06cc
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06cc
.L_tc_recycle_frame_done_06cc:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_003b:
	jmp .L_if_end_03cf
.L_if_else_03cf:
	mov rax, L_constants + 2
.L_if_end_03cf:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e4:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06cd:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06cd
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06cd
.L_tc_recycle_frame_done_06cd:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d0
.L_if_else_03d0:
	mov rax, L_constants + 2
.L_if_end_03d0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e3:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06cb:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06cb
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06cb
.L_tc_recycle_frame_done_06cb:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00a5:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a6
	jmp .L_lambda_opt_end_00a6
.L_lambda_opt_code_00a6:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e5
	jmp .L_lambda_simple_end_04e5
.L_lambda_simple_code_04e5:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e5:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing loop
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e6
	jmp .L_lambda_simple_end_04e6
.L_lambda_simple_code_04e6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04e6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e6:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003c
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d1
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06cf:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06cf
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06cf
.L_tc_recycle_frame_done_06cf:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d1
.L_if_else_03d1:
	mov rax, L_constants + 2
.L_if_end_03d1:
.L_or_end_003c:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003d
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06d0:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d0
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d0
.L_tc_recycle_frame_done_06d0:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03d2
.L_if_else_03d2:
	mov rax, L_constants + 2
.L_if_end_03d2:
.L_or_end_003d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04e5:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ce:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ce
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ce
.L_tc_recycle_frame_done_06ce:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00a6:	; new closure is in rax
	mov qword [free_var_31], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e7
	jmp .L_lambda_simple_end_04e7
.L_lambda_simple_code_04e7:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04e7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e7:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing map1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing map-list
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e8
	jmp .L_lambda_simple_end_04e8
.L_lambda_simple_code_04e8:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04e8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e8:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d3
	mov rax, L_constants + 1
	jmp .L_if_end_03d3
.L_if_else_03d3:
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param f
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d1:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d1
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d1
.L_tc_recycle_frame_done_06d1:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04e8:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04e9
	jmp .L_lambda_simple_end_04e9
.L_lambda_simple_code_04e9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04e9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04e9:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d4
	mov rax, L_constants + 1
	jmp .L_if_end_03d4
.L_if_else_03d4:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d2:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d2
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d2
.L_tc_recycle_frame_done_06d2:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d4:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04e9:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a7
	jmp .L_lambda_opt_end_00a7
.L_lambda_opt_code_00a7:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d5
	mov rax, L_constants + 1
	jmp .L_if_end_03d5
.L_if_else_03d5:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d3:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d3
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d3
.L_tc_recycle_frame_done_06d3:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d5:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00a7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04e7:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ea
	jmp .L_lambda_simple_end_04ea
.L_lambda_simple_code_04ea:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ea:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04eb
	jmp .L_lambda_simple_end_04eb
.L_lambda_simple_code_04eb:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04eb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04eb:
	enter 0, 0
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d5:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d5
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d5
.L_tc_recycle_frame_done_06d5:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04eb:	; new closure is in rax
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_06d4:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d4
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d4
.L_tc_recycle_frame_done_06d4:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ea:	; new closure is in rax
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ec
	jmp .L_lambda_simple_end_04ec
.L_lambda_simple_code_04ec:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ec
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ec:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run-1
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing run-2
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ed
	jmp .L_lambda_simple_end_04ed
.L_lambda_simple_code_04ed:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ed
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ed:
	enter 0, 0
	mov rax, PARAM(1)	; param sr
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d6
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_03d6
.L_if_else_03d6:
	mov rax, PARAM(1)	; param sr
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param sr
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d6:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d6
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d6
.L_tc_recycle_frame_done_06d6:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ed:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ee
	jmp .L_lambda_simple_end_04ee
.L_lambda_simple_code_04ee:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04ee
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ee:
	enter 0, 0
	mov rax, PARAM(0)	; param s1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d7
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_03d7
.L_if_else_03d7:
	mov rax, PARAM(1)	; param s2
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d7:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d7
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d7
.L_tc_recycle_frame_done_06d7:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d7:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ee:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a8
	jmp .L_lambda_opt_end_00a8
.L_lambda_opt_code_00a8:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d8
	mov rax, L_constants + 1
	jmp .L_if_end_03d8
.L_if_else_03d8:
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06d8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d8
.L_tc_recycle_frame_done_06d8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d8:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00a8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04ec:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_32], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ef
	jmp .L_lambda_simple_end_04ef
.L_lambda_simple_code_04ef:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ef
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ef:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f0
	jmp .L_lambda_simple_end_04f0
.L_lambda_simple_code_04f0:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04f0
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f0:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03d9
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_03d9
.L_if_else_03d9:
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_06d9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06d9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06d9
.L_tc_recycle_frame_done_06d9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03d9:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04f0:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00a9
	jmp .L_lambda_opt_end_00a9
.L_lambda_opt_code_00a9:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_06da:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06da
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06da
.L_tc_recycle_frame_done_06da:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_00a9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ef:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f1
	jmp .L_lambda_simple_end_04f1
.L_lambda_simple_code_04f1:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f1:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f2
	jmp .L_lambda_simple_end_04f2
.L_lambda_simple_code_04f2:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_04f2
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f2:
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_104]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03da
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_03da
.L_if_else_03da:
	mov rax, L_constants + 1
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_32]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06db:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06db
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06db
.L_tc_recycle_frame_done_06db:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03da:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_04f2:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00aa
	jmp .L_lambda_opt_end_00aa
.L_lambda_opt_code_00aa:	
	mov r9, 2
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_06dc:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06dc
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06dc
.L_tc_recycle_frame_done_06dc:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_00aa:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f1:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f3
	jmp .L_lambda_simple_end_04f3
.L_lambda_simple_code_04f3:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_04f3
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f3:
	enter 0, 0
	mov rax, L_constants + 2200
	push rax
	mov rax, L_constants + 2191
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06dd:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06dd
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06dd
.L_tc_recycle_frame_done_06dd:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_04f3:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f4
	jmp .L_lambda_simple_end_04f4
.L_lambda_simple_code_04f4:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f4:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f5
	jmp .L_lambda_simple_end_04f5
.L_lambda_simple_code_04f5:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04f5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f5:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e6
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03dd
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_11]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06df:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06df
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06df
.L_tc_recycle_frame_done_06df:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03dd
.L_if_else_03dd:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03dc
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e0:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e0
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e0
.L_tc_recycle_frame_done_06e0:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03dc
.L_if_else_03dc:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03db
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e1:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e1
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e1
.L_tc_recycle_frame_done_06e1:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03db
.L_if_else_03db:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06e2:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e2
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e2
.L_tc_recycle_frame_done_06e2:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03db:
.L_if_end_03dc:
.L_if_end_03dd:
	jmp .L_if_end_03e6
.L_if_else_03e6:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e5
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e0
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_28]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e3:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e3
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e3
.L_tc_recycle_frame_done_06e3:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e0
.L_if_else_03e0:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03df
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_9]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e4:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e4
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e4
.L_tc_recycle_frame_done_06e4:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03df
.L_if_else_03df:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03de
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e5:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e5
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e5
.L_tc_recycle_frame_done_06e5:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03de
.L_if_else_03de:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06e6:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e6
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e6
.L_tc_recycle_frame_done_06e6:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03de:
.L_if_end_03df:
.L_if_end_03e0:
	jmp .L_if_end_03e5
.L_if_else_03e5:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e4
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e3
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e7:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e7
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e7
.L_tc_recycle_frame_done_06e7:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e3
.L_if_else_03e3:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e2
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e8
.L_tc_recycle_frame_done_06e8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e2
.L_if_else_03e2:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e1
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_10]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06e9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06e9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06e9
.L_tc_recycle_frame_done_06e9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e1
.L_if_else_03e1:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06ea:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ea
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ea
.L_tc_recycle_frame_done_06ea:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e1:
.L_if_end_03e2:
.L_if_end_03e3:
	jmp .L_if_end_03e4
.L_if_else_03e4:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06eb:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06eb
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06eb
.L_tc_recycle_frame_done_06eb:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e4:
.L_if_end_03e5:
.L_if_end_03e6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04f5:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f6
	jmp .L_lambda_simple_end_04f6
.L_lambda_simple_code_04f6:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f6:
	enter 0, 0
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00ab
	jmp .L_lambda_opt_end_00ab
.L_lambda_opt_code_00ab:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_06ec:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ec
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ec
.L_tc_recycle_frame_done_06ec:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00ab:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f6:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06de:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06de
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06de
.L_tc_recycle_frame_done_06de:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f4:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_1], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f7
	jmp .L_lambda_simple_end_04f7
.L_lambda_simple_code_04f7:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_04f7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f7:
	enter 0, 0
	mov rax, L_constants + 2200
	push rax
	mov rax, L_constants + 2264
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06ed:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ed
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ed
.L_tc_recycle_frame_done_06ed:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_04f7:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f8
	jmp .L_lambda_simple_end_04f8
.L_lambda_simple_code_04f8:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04f8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f8:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04f9
	jmp .L_lambda_simple_end_04f9
.L_lambda_simple_code_04f9:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04f9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04f9:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f2
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e9
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_27]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06ef:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ef
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ef
.L_tc_recycle_frame_done_06ef:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e9
.L_if_else_03e9:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e8
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f0:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f0
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f0
.L_tc_recycle_frame_done_06f0:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e8
.L_if_else_03e8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_109]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03e7
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f1:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f1
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f1
.L_tc_recycle_frame_done_06f1:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03e7
.L_if_else_03e7:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06f2:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f2
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f2
.L_tc_recycle_frame_done_06f2:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03e7:
.L_if_end_03e8:
.L_if_end_03e9:
	jmp .L_if_end_03f2
.L_if_else_03f2:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f1
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ec
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f3:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f3
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f3
.L_tc_recycle_frame_done_06f3:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ec
.L_if_else_03ec:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03eb
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_25]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f4:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f4
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f4
.L_tc_recycle_frame_done_06f4:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03eb
.L_if_else_03eb:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ea
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f5:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f5
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f5
.L_tc_recycle_frame_done_06f5:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ea
.L_if_else_03ea:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06f6:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f6
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f6
.L_tc_recycle_frame_done_06f6:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ea:
.L_if_end_03eb:
.L_if_end_03ec:
	jmp .L_if_end_03f1
.L_if_else_03f1:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f0
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ef
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f7:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f7
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f7
.L_tc_recycle_frame_done_06f7:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ef
.L_if_else_03ef:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ee
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f8:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f8
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f8
.L_tc_recycle_frame_done_06f8:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ee
.L_if_else_03ee:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ed
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_26]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06f9:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06f9
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06f9
.L_tc_recycle_frame_done_06f9:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03ed
.L_if_else_03ed:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06fa:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06fa
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06fa
.L_tc_recycle_frame_done_06fa:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03ed:
.L_if_end_03ee:
.L_if_end_03ef:
	jmp .L_if_end_03f0
.L_if_else_03f0:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_06fb:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06fb
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06fb
.L_tc_recycle_frame_done_06fb:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03f0:
.L_if_end_03f1:
.L_if_end_03f2:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04f9:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04fa
	jmp .L_lambda_simple_end_04fa
.L_lambda_simple_code_04fa:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fa:
	enter 0, 0
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00ac
	jmp .L_lambda_opt_end_00ac
.L_lambda_opt_code_00ac:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f3
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2148
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06fc:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06fc
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06fc
.L_tc_recycle_frame_done_06fc:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f3
.L_if_else_03f3:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3		; arg count
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04fb
	jmp .L_lambda_simple_end_04fb
.L_lambda_simple_code_04fb:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fb:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06fe:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06fe
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06fe
.L_tc_recycle_frame_done_06fe:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fb:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06fd:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06fd
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06fd
.L_tc_recycle_frame_done_06fd:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03f3:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00ac:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fa:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_06ee:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ee
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ee
.L_tc_recycle_frame_done_06ee:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04f8:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_2], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04fc
	jmp .L_lambda_simple_end_04fc
.L_lambda_simple_code_04fc:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_04fc
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fc:
	enter 0, 0
	mov rax, L_constants + 2200
	push rax
	mov rax, L_constants + 2292
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_06ff:
	cmp r10, 0
	je .L_tc_recycle_frame_done_06ff
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_06ff
.L_tc_recycle_frame_done_06ff:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_04fc:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04fd
	jmp .L_lambda_simple_end_04fd
.L_lambda_simple_code_04fd:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04fd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fd:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04fe
	jmp .L_lambda_simple_end_04fe
.L_lambda_simple_code_04fe:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_04fe
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04fe:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03ff
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f6
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_24]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0701:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0701
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0701
.L_tc_recycle_frame_done_0701:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f6
.L_if_else_03f6:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f5
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0702:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0702
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0702
.L_tc_recycle_frame_done_0702:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f5
.L_if_else_03f5:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f4
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0703:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0703
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0703
.L_tc_recycle_frame_done_0703:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f4
.L_if_else_03f4:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0704:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0704
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0704
.L_tc_recycle_frame_done_0704:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03f4:
.L_if_end_03f5:
.L_if_end_03f6:
	jmp .L_if_end_03ff
.L_if_else_03ff:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fe
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f9
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0705:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0705
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0705
.L_tc_recycle_frame_done_0705:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f9
.L_if_else_03f9:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f8
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_22]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0706:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0706
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0706
.L_tc_recycle_frame_done_0706:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f8
.L_if_else_03f8:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03f7
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0707:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0707
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0707
.L_tc_recycle_frame_done_0707:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03f7
.L_if_else_03f7:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0708:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0708
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0708
.L_tc_recycle_frame_done_0708:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03f7:
.L_if_end_03f8:
.L_if_end_03f9:
	jmp .L_if_end_03fe
.L_if_else_03fe:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fd
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fc
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0709:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0709
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0709
.L_tc_recycle_frame_done_0709:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fc
.L_if_else_03fc:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fb
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_070a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070a
.L_tc_recycle_frame_done_070a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fb
.L_if_else_03fb:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_03fa
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_23]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_070b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070b
.L_tc_recycle_frame_done_070b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_03fa
.L_if_else_03fa:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_070c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070c
.L_tc_recycle_frame_done_070c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03fa:
.L_if_end_03fb:
.L_if_end_03fc:
	jmp .L_if_end_03fd
.L_if_else_03fd:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_070d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070d
.L_tc_recycle_frame_done_070d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_03fd:
.L_if_end_03fe:
.L_if_end_03ff:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_04fe:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_04ff
	jmp .L_lambda_simple_end_04ff
.L_lambda_simple_code_04ff:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_04ff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_04ff:
	enter 0, 0
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00ad
	jmp .L_lambda_opt_end_00ad
.L_lambda_opt_code_00ad:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_070e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070e
.L_tc_recycle_frame_done_070e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00ad:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04ff:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0700:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0700
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0700
.L_tc_recycle_frame_done_0700:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_04fd:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_0], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0500
	jmp .L_lambda_simple_end_0500
.L_lambda_simple_code_0500:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0500
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0500:
	enter 0, 0
	mov rax, L_constants + 2200
	push rax
	mov rax, L_constants + 2311
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_070f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_070f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_070f
.L_tc_recycle_frame_done_070f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0500:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0501
	jmp .L_lambda_simple_end_0501
.L_lambda_simple_code_0501:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0501
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0501:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0502
	jmp .L_lambda_simple_end_0502
.L_lambda_simple_code_0502:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0502
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0502:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040b
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0402
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_15]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0711:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0711
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0711
.L_tc_recycle_frame_done_0711:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0402
.L_if_else_0402:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0401
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0712:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0712
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0712
.L_tc_recycle_frame_done_0712:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0401
.L_if_else_0401:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0400
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0713:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0713
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0713
.L_tc_recycle_frame_done_0713:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0400
.L_if_else_0400:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0714:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0714
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0714
.L_tc_recycle_frame_done_0714:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0400:
.L_if_end_0401:
.L_if_end_0402:
	jmp .L_if_end_040b
.L_if_else_040b:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040a
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0405
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0715:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0715
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0715
.L_tc_recycle_frame_done_0715:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0405
.L_if_else_0405:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0404
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_13]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0716:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0716
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0716
.L_tc_recycle_frame_done_0716:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0404
.L_if_else_0404:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0403
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0717:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0717
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0717
.L_tc_recycle_frame_done_0717:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0403
.L_if_else_0403:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0718:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0718
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0718
.L_tc_recycle_frame_done_0718:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0403:
.L_if_end_0404:
.L_if_end_0405:
	jmp .L_if_end_040a
.L_if_else_040a:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0409
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0408
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0719:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0719
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0719
.L_tc_recycle_frame_done_0719:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0408
.L_if_else_0408:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0407
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_071a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071a
.L_tc_recycle_frame_done_071a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0407
.L_if_else_0407:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0406
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_14]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_071b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071b
.L_tc_recycle_frame_done_071b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0406
.L_if_else_0406:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_071c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071c
.L_tc_recycle_frame_done_071c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0406:
.L_if_end_0407:
.L_if_end_0408:
	jmp .L_if_end_0409
.L_if_else_0409:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_071d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071d
.L_tc_recycle_frame_done_071d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0409:
.L_if_end_040a:
.L_if_end_040b:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0502:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0503
	jmp .L_lambda_simple_end_0503
.L_lambda_simple_code_0503:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0503
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0503:
	enter 0, 0
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00ae
	jmp .L_lambda_opt_end_00ae
.L_lambda_opt_code_00ae:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040c
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2283
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_071e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071e
.L_tc_recycle_frame_done_071e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040c
.L_if_else_040c:
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3		; arg count
	mov rax, qword [free_var_80]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0504
	jmp .L_lambda_simple_end_0504
.L_lambda_simple_code_0504:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0504
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0504:
	enter 0, 0
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0720:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0720
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0720
.L_tc_recycle_frame_done_0720:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0504:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_071f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_071f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_071f
.L_tc_recycle_frame_done_071f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_040c:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00ae:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0503:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0710:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0710
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0710
.L_tc_recycle_frame_done_0710:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0501:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_3], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0505
	jmp .L_lambda_simple_end_0505
.L_lambda_simple_code_0505:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0505
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0505:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040d
	mov rax, L_constants + 2283
	jmp .L_if_end_040d
.L_if_else_040d:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_79]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2
	mov rax, qword [free_var_0]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0721:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0721
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0721
.L_tc_recycle_frame_done_0721:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_040d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0505:	; new closure is in rax
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_6], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0506
	jmp .L_lambda_simple_end_0506
.L_lambda_simple_code_0506:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0506
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0506:
	enter 0, 0
	mov rax, L_constants + 2421
	push rax
	mov rax, L_constants + 2412
	push rax
	push 2
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0722:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0722
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0722
.L_tc_recycle_frame_done_0722:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0506:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0507
	jmp .L_lambda_simple_end_0507
.L_lambda_simple_code_0507:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0507
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0507:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0508
	jmp .L_lambda_simple_end_0508
.L_lambda_simple_code_0508:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0508
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0508:
	enter 0, 0
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0509
	jmp .L_lambda_simple_end_0509
.L_lambda_simple_code_0509:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0509
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0509:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0419
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0410
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0724:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0724
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0724
.L_tc_recycle_frame_done_0724:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0410
.L_if_else_0410:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040f
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0725:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0725
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0725
.L_tc_recycle_frame_done_0725:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040f
.L_if_else_040f:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_040e
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0726:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0726
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0726
.L_tc_recycle_frame_done_0726:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_040e
.L_if_else_040e:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0727:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0727
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0727
.L_tc_recycle_frame_done_0727:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_040e:
.L_if_end_040f:
.L_if_end_0410:
	jmp .L_if_end_0419
.L_if_else_0419:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0418
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0413
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_29]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0728:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0728
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0728
.L_tc_recycle_frame_done_0728:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0413
.L_if_else_0413:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0412
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0729:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0729
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0729
.L_tc_recycle_frame_done_0729:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0412
.L_if_else_0412:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0411
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_072a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072a
.L_tc_recycle_frame_done_072a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0411
.L_if_else_0411:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_072b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072b
.L_tc_recycle_frame_done_072b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0411:
.L_if_end_0412:
.L_if_end_0413:
	jmp .L_if_end_0418
.L_if_else_0418:
	mov rax, PARAM(0)	; param a
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0417
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_85]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0416
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_84]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_072c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072c
.L_tc_recycle_frame_done_072c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0416
.L_if_else_0416:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_83]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0415
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_82]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_072d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072d
.L_tc_recycle_frame_done_072d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0415
.L_if_else_0415:
	mov rax, PARAM(1)	; param b
	push rax
	push 1		; arg count
	mov rax, qword [free_var_110]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0414
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_072e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072e
.L_tc_recycle_frame_done_072e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0414
.L_if_else_0414:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_072f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_072f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_072f
.L_tc_recycle_frame_done_072f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0414:
.L_if_end_0415:
.L_if_end_0416:
	jmp .L_if_end_0417
.L_if_else_0417:
	push 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 0
	mov r12, rdi
	lea rdi, [r12 + -8]	; Dest_High
	lea rsi, [rsp + -8]	; Source_High
	mov r10, 0
.L_tc_recycle_frame_loop_0730:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0730
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0730
.L_tc_recycle_frame_done_0730:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0417:
.L_if_end_0418:
.L_if_end_0419:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0509:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0508:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050a
	jmp .L_lambda_simple_end_050a
.L_lambda_simple_code_050a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050a:
	enter 0, 0
	mov rax, qword [free_var_20]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_19]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_21]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3		; arg count
	mov rax, PARAM(0)	; param make-bin-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050b
	jmp .L_lambda_simple_end_050b
.L_lambda_simple_code_050b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050b:
	enter 0, 0
	mov rax, qword [free_var_17]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_16]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_18]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050c
	jmp .L_lambda_simple_end_050c
.L_lambda_simple_code_050c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050c:
	enter 0, 0
	mov r8, 1
mov r9, 4
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050d
	jmp .L_lambda_simple_end_050d
.L_lambda_simple_code_050d:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_050d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050d:
	enter 0, 0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0734:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0734
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0734
.L_tc_recycle_frame_done_0734:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_050d:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 4
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050e
	jmp .L_lambda_simple_end_050e
.L_lambda_simple_code_050e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_050e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050e:
	enter 0, 0
	mov r8, 1
mov r9, 5
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_050f
	jmp .L_lambda_simple_end_050f
.L_lambda_simple_code_050f:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_050f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_050f:
	enter 0, 0
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0736:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0736
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0736
.L_tc_recycle_frame_done_0736:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_050f:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 5
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0510
	jmp .L_lambda_simple_end_0510
.L_lambda_simple_code_0510:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0510
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0510:
	enter 0, 0
	mov r8, 1
mov r9, 6
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0511
	jmp .L_lambda_simple_end_0511
.L_lambda_simple_code_0511:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0511
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0511:
	enter 0, 0
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0738:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0738
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0738
.L_tc_recycle_frame_done_0738:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0511:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 6
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0512
	jmp .L_lambda_simple_end_0512
.L_lambda_simple_code_0512:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0512
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0512:
	enter 0, 0
	mov r8, 1
mov r9, 7
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0513
	jmp .L_lambda_simple_end_0513
.L_lambda_simple_code_0513:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0513
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0513:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 8
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0514
	jmp .L_lambda_simple_end_0514
.L_lambda_simple_code_0514:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0514
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0514:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 9
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0515
	jmp .L_lambda_simple_end_0515
.L_lambda_simple_code_0515:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0515
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0515:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003e
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041a
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_073b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073b
.L_tc_recycle_frame_done_073b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041a
.L_if_else_041a:
	mov rax, L_constants + 2
.L_if_end_041a:
.L_or_end_003e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0515:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 9
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00af
	jmp .L_lambda_opt_end_00af
.L_lambda_opt_code_00af:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_073c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073c
.L_tc_recycle_frame_done_073c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00af:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0514:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_073a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073a
.L_tc_recycle_frame_done_073a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0513:	; new closure is in rax
	push rax
	push 1
	mov r8, 1
mov r9, 7
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0516
	jmp .L_lambda_simple_end_0516
.L_lambda_simple_code_0516:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0516
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0516:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_4], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_5], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_7], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_8], rax
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-run
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_6], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0516:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0739:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0739
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0739
.L_tc_recycle_frame_done_0739:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0512:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0737:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0737
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0737
.L_tc_recycle_frame_done_0737:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0510:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0735:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0735
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0735
.L_tc_recycle_frame_done_0735:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050e:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0733:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0733
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0733
.L_tc_recycle_frame_done_0733:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050c:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0732:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0732
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0732
.L_tc_recycle_frame_done_0732:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050b:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0731:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0731
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0731
.L_tc_recycle_frame_done_0731:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_050a:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0723:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0723
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0723
.L_tc_recycle_frame_done_0723:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0507:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_71], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0517
	jmp .L_lambda_simple_end_0517
.L_lambda_simple_code_0517:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0517
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0517:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b0
	jmp .L_lambda_opt_end_00b0
.L_lambda_opt_code_00b0:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_65]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_073d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073d
.L_tc_recycle_frame_done_073d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0517:	; new closure is in rax
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0518
	jmp .L_lambda_simple_end_0518
.L_lambda_simple_code_0518:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0518
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0518:
	enter 0, 0
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_69], rax
	mov rax, sob_void

	mov rax, qword [free_var_5]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_68], rax
	mov rax, sob_void

	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_70], rax
	mov rax, sob_void

	mov rax, qword [free_var_7]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_72], rax
	mov rax, sob_void

	mov rax, qword [free_var_8]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_71], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0518:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_66], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 0
	mov qword [free_var_67], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0519
	jmp .L_lambda_simple_end_0519
.L_lambda_simple_code_0519:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0519
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0519:
	enter 0, 0
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_003f
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041b
	mov rax, PARAM(0)	; param e
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_90]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_073e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073e
.L_tc_recycle_frame_done_073e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041b
.L_if_else_041b:
	mov rax, L_constants + 2
.L_if_end_041b:
.L_or_end_003f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0519:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051a
	jmp .L_lambda_simple_end_051a
.L_lambda_simple_code_051a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051a:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b1
	jmp .L_lambda_opt_end_00b1
.L_lambda_opt_code_00b1:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param xs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041e
	mov rax, L_constants + 0
	jmp .L_if_end_041e
.L_if_else_041e:
	mov rax, PARAM(1)	; param xs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041c
	mov rax, PARAM(1)	; param xs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041c
.L_if_else_041c:
	mov rax, L_constants + 2
.L_if_end_041c:
	cmp rax, sob_boolean_false
	je .L_if_else_041d
	mov rax, PARAM(1)	; param xs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041d
.L_if_else_041d:
	mov rax, L_constants + 2591
	push rax
	mov rax, L_constants + 2582
	push rax
	push 2		; arg count
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_041d:
.L_if_end_041e:
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051b
	jmp .L_lambda_simple_end_051b
.L_lambda_simple_code_051b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051b:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0740:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0740
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0740
.L_tc_recycle_frame_done_0740:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051b:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_073f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_073f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_073f
.L_tc_recycle_frame_done_073f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051a:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051c
	jmp .L_lambda_simple_end_051c
.L_lambda_simple_code_051c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051c:
	enter 0, 0
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b2
	jmp .L_lambda_opt_end_00b2
.L_lambda_opt_code_00b2:	
	mov r9, 1
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(1)	; param chs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0421
	mov rax, L_constants + 4
	jmp .L_if_end_0421
.L_if_else_0421:
	mov rax, PARAM(1)	; param chs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_041f
	mov rax, PARAM(1)	; param chs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_041f
.L_if_else_041f:
	mov rax, L_constants + 2
.L_if_end_041f:
	cmp rax, sob_boolean_false
	je .L_if_else_0420
	mov rax, PARAM(1)	; param chs
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0420
.L_if_else_0420:
	mov rax, L_constants + 2652
	push rax
	mov rax, L_constants + 2643
	push rax
	push 2		; arg count
	mov rax, qword [free_var_77]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_0420:
.L_if_end_0421:
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051d
	jmp .L_lambda_simple_end_051d
.L_lambda_simple_code_051d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051d:
	enter 0, 0
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0742:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0742
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0742
.L_tc_recycle_frame_done_0742:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051d:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0741:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0741
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0741
.L_tc_recycle_frame_done_0741:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_00b2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051c:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051e
	jmp .L_lambda_simple_end_051e
.L_lambda_simple_code_051e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_051e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051e:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_051f
	jmp .L_lambda_simple_end_051f
.L_lambda_simple_code_051f:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_051f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_051f:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0422
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0743:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0743
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0743
.L_tc_recycle_frame_done_0743:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0422
.L_if_else_0422:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0520
	jmp .L_lambda_simple_end_0520
.L_lambda_simple_code_0520:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0520
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0520:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3		; arg count
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0520:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0744:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0744
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0744
.L_tc_recycle_frame_done_0744:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0422:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_051f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0521
	jmp .L_lambda_simple_end_0521
.L_lambda_simple_code_0521:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0521
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0521:
	enter 0, 0
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0745:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0745
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0745
.L_tc_recycle_frame_done_0745:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0521:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_051e:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0522
	jmp .L_lambda_simple_end_0522
.L_lambda_simple_code_0522:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0522
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0522:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0523
	jmp .L_lambda_simple_end_0523
.L_lambda_simple_code_0523:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0523
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0523:
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0423
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0746:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0746
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0746
.L_tc_recycle_frame_done_0746:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0423
.L_if_else_0423:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0524
	jmp .L_lambda_simple_end_0524
.L_lambda_simple_code_0524:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0524
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0524:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3		; arg count
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0524:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0747:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0747
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0747
.L_tc_recycle_frame_done_0747:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0423:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0523:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0525
	jmp .L_lambda_simple_end_0525
.L_lambda_simple_code_0525:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0525
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0525:
	enter 0, 0
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0748:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0748
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0748
.L_tc_recycle_frame_done_0748:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0525:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0522:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_88], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b3
	jmp .L_lambda_opt_end_00b3
.L_lambda_opt_code_00b3:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param s
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0749:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0749
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0749
.L_tc_recycle_frame_done_0749:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b3:	; new closure is in rax
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0526
	jmp .L_lambda_simple_end_0526
.L_lambda_simple_code_0526:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0526
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0526:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0527
	jmp .L_lambda_simple_end_0527
.L_lambda_simple_code_0527:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0527
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0527:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0424
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2		; arg count
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_074a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074a
.L_tc_recycle_frame_done_074a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0424
.L_if_else_0424:
	mov rax, L_constants + 1
.L_if_end_0424:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0527:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0528
	jmp .L_lambda_simple_end_0528
.L_lambda_simple_code_0528:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0528
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0528:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1		; arg count
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_074b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074b
.L_tc_recycle_frame_done_074b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0528:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0526:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0529
	jmp .L_lambda_simple_end_0529
.L_lambda_simple_code_0529:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0529
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0529:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052a
	jmp .L_lambda_simple_end_052a
.L_lambda_simple_code_052a:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_052a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052a:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0425
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2		; arg count
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_074c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074c
.L_tc_recycle_frame_done_074c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0425
.L_if_else_0425:
	mov rax, L_constants + 1
.L_if_end_0425:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_052a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052b
	jmp .L_lambda_simple_end_052b
.L_lambda_simple_code_052b:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052b:
	enter 0, 0
	mov rax, PARAM(0)	; param v
	push rax
	push 1		; arg count
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_074d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074d
.L_tc_recycle_frame_done_074d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0529:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052c
	jmp .L_lambda_simple_end_052c
.L_lambda_simple_code_052c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052c:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 0		; arg count
	mov rax, qword [free_var_122]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_074e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074e
.L_tc_recycle_frame_done_074e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052c:	; new closure is in rax
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052d
	jmp .L_lambda_simple_end_052d
.L_lambda_simple_code_052d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052d:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2148
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_074f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_074f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_074f
.L_tc_recycle_frame_done_074f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052d:	; new closure is in rax
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052e
	jmp .L_lambda_simple_end_052e
.L_lambda_simple_code_052e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052e:
	enter 0, 0
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0750:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0750
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0750
.L_tc_recycle_frame_done_0750:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052e:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_052f
	jmp .L_lambda_simple_end_052f
.L_lambda_simple_code_052f:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_052f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_052f:
	enter 0, 0
	mov rax, L_constants + 2868
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2		; arg count
	mov rax, qword [free_var_111]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0751:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0751
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0751
.L_tc_recycle_frame_done_0751:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_052f:	; new closure is in rax
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0530
	jmp .L_lambda_simple_end_0530
.L_lambda_simple_code_0530:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0530
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0530:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_78]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_100]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0752:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0752
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0752
.L_tc_recycle_frame_done_0752:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0530:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0531
	jmp .L_lambda_simple_end_0531
.L_lambda_simple_code_0531:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0531
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0531:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	push rax
	push 1		; arg count
	mov rax, qword [free_var_98]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0426
	mov rax, PARAM(0)	; param x
	push rax
	push 1
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0753:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0753
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0753
.L_tc_recycle_frame_done_0753:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0426
.L_if_else_0426:
	mov rax, PARAM(0)	; param x
.L_if_end_0426:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0531:	; new closure is in rax
	mov qword [free_var_30], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0532
	jmp .L_lambda_simple_end_0532
.L_lambda_simple_code_0532:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0532
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0532:
	enter 0, 0
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0427
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_105]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0427
.L_if_else_0427:
	mov rax, L_constants + 2
.L_if_end_0427:
	cmp rax, sob_boolean_false
	je .L_if_else_0433
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0428
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0754:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0754
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0754
.L_tc_recycle_frame_done_0754:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0428
.L_if_else_0428:
	mov rax, L_constants + 2
.L_if_end_0428:
	jmp .L_if_end_0433
.L_if_else_0433:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_042a
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_131]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0429
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0429
.L_if_else_0429:
	mov rax, L_constants + 2
.L_if_end_0429:
	jmp .L_if_end_042a
.L_if_else_042a:
	mov rax, L_constants + 2
.L_if_end_042a:
	cmp rax, sob_boolean_false
	je .L_if_else_0432
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_76]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0755:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0755
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0755
.L_tc_recycle_frame_done_0755:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0432
.L_if_else_0432:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_042c
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_121]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_042b
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_042b
.L_if_else_042b:
	mov rax, L_constants + 2
.L_if_end_042b:
	jmp .L_if_end_042c
.L_if_else_042c:
	mov rax, L_constants + 2
.L_if_end_042c:
	cmp rax, sob_boolean_false
	je .L_if_else_0431
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_120]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0756:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0756
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0756
.L_tc_recycle_frame_done_0756:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0431
.L_if_else_0431:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_042d
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_102]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_042d
.L_if_else_042d:
	mov rax, L_constants + 2
.L_if_end_042d:
	cmp rax, sob_boolean_false
	je .L_if_else_0430
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0757:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0757
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0757
.L_tc_recycle_frame_done_0757:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0430
.L_if_else_0430:
	mov rax, PARAM(0)	; param e1
	push rax
	push 1		; arg count
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_042e
	mov rax, PARAM(1)	; param e2
	push rax
	push 1		; arg count
	mov rax, qword [free_var_73]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_042e
.L_if_else_042e:
	mov rax, L_constants + 2
.L_if_end_042e:
	cmp rax, sob_boolean_false
	je .L_if_else_042f
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_70]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0758:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0758
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0758
.L_tc_recycle_frame_done_0758:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_042f
.L_if_else_042f:
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0759:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0759
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0759
.L_tc_recycle_frame_done_0759:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_042f:
.L_if_end_0430:
.L_if_end_0431:
.L_if_end_0432:
.L_if_end_0433:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0532:	; new closure is in rax
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0533
	jmp .L_lambda_simple_end_0533
.L_lambda_simple_code_0533:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0533
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0533:
	enter 0, 0
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0435
	mov rax, L_constants + 2
	jmp .L_if_end_0435
.L_if_else_0435:
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_41]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_75]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0434
	mov rax, PARAM(1)	; param s
	push rax
	push 1
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_075a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075a
.L_tc_recycle_frame_done_075a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0434
.L_if_else_0434:
	mov rax, PARAM(1)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2
	mov rax, qword [free_var_34]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_075b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075b
.L_tc_recycle_frame_done_075b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0434:
.L_if_end_0435:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0533:	; new closure is in rax
	mov qword [free_var_34], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0534
	jmp .L_lambda_simple_end_0534
.L_lambda_simple_code_0534:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0534
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0534:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0535
	jmp .L_lambda_simple_end_0535
.L_lambda_simple_code_0535:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0535
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0535:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0436
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0436
.L_if_else_0436:
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0536
	jmp .L_lambda_simple_end_0536
.L_lambda_simple_code_0536:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0536
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0536:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_075d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075d
.L_tc_recycle_frame_done_075d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0536:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_075c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075c
.L_tc_recycle_frame_done_075c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0436:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0535:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0537
	jmp .L_lambda_simple_end_0537
.L_lambda_simple_code_0537:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_0537
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0537:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0437
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2		; arg count
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3		; arg count
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 40
	mov r12, rdi
	lea rdi, [r12 + 32]	; Dest_High
	lea rsi, [rsp + 32]	; Source_High
	mov r10, 5
.L_tc_recycle_frame_loop_075e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075e
.L_tc_recycle_frame_done_075e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0437
.L_if_else_0437:
	mov rax, PARAM(1)	; param i
.L_if_end_0437:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_0537:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b4
	jmp .L_lambda_opt_end_00b4
.L_lambda_opt_code_00b4:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_075f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_075f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_075f
.L_tc_recycle_frame_done_075f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0534:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	mov rax, L_constants + 1993
	push rax
	push 2		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0538
	jmp .L_lambda_simple_end_0538
.L_lambda_simple_code_0538:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0538
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0538:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(1)	; boxing add
	mov qword [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0539
	jmp .L_lambda_simple_end_0539
.L_lambda_simple_code_0539:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0539
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0539:
	enter 0, 0
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_101]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0438
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_0438
.L_if_else_0438:
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(2)	; param s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_49]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053a
	jmp .L_lambda_simple_end_053a
.L_lambda_simple_code_053a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053a:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1		; arg count
	mov rax, qword [free_var_64]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_0761:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0761
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0761
.L_tc_recycle_frame_done_0761:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053a:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0760:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0760
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0760
.L_tc_recycle_frame_done_0760:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0438:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0539:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053b
	jmp .L_lambda_simple_end_053b
.L_lambda_simple_code_053b:	
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_053b
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053b:
	enter 0, 0
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0439
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2		; arg count
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3		; arg count
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 40
	mov r12, rdi
	lea rdi, [r12 + 32]	; Dest_High
	lea rsi, [rsp + 32]	; Source_High
	mov r10, 5
.L_tc_recycle_frame_loop_0762:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0762
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0762
.L_tc_recycle_frame_done_0762:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0439
.L_if_else_0439:
	mov rax, PARAM(1)	; param i
.L_if_end_0439:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_053b:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_opt_code_00b5
	jmp .L_lambda_opt_end_00b5
.L_lambda_opt_code_00b5:	
	mov r9, 0
	call opt_fix_stack
	enter 0, 0
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_97]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2		; arg count
	mov rax, qword [free_var_33]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_0763:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0763
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0763
.L_tc_recycle_frame_done_0763:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_00b5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0538:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053c
	jmp .L_lambda_simple_end_053c
.L_lambda_simple_code_053c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053c:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1		; arg count
	mov rax, qword [free_var_113]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_88]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0764:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0764
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0764
.L_tc_recycle_frame_done_0764:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053c:	; new closure is in rax
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053d
	jmp .L_lambda_simple_end_053d
.L_lambda_simple_code_053d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053d:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push 1		; arg count
	mov rax, qword [free_var_124]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, qword [free_var_112]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, qword [free_var_89]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0765:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0765
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0765
.L_tc_recycle_frame_done_0765:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053d:	; new closure is in rax
	mov qword [free_var_128], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053e
	jmp .L_lambda_simple_end_053e
.L_lambda_simple_code_053e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_053e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053e:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_053f
	jmp .L_lambda_simple_end_053f
.L_lambda_simple_code_053f:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_053f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_053f:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043a
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2		; arg count
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0540
	jmp .L_lambda_simple_end_0540
.L_lambda_simple_code_0540:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0540
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0540:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2		; arg count
	mov rax, qword [free_var_116]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3		; arg count
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3		; arg count
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_0767:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0767
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0767
.L_tc_recycle_frame_done_0767:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0540:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0766:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0766
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0766
.L_tc_recycle_frame_done_0766:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_043a
.L_if_else_043a:
	mov rax, PARAM(0)	; param str
.L_if_end_043a:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_053f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0541
	jmp .L_lambda_simple_end_0541
.L_lambda_simple_code_0541:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0541
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0541:
	enter 0, 0
	mov rax, PARAM(0)	; param str
	push rax
	push 1		; arg count
	mov rax, qword [free_var_115]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0542
	jmp .L_lambda_simple_end_0542
.L_lambda_simple_code_0542:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0542
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0542:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043b
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_043b
.L_if_else_043b:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_0769:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0769
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0769
.L_tc_recycle_frame_done_0769:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_043b:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0542:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0768:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0768
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0768
.L_tc_recycle_frame_done_0768:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0541:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_053e:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_118], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 1993
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0543
	jmp .L_lambda_simple_end_0543
.L_lambda_simple_code_0543:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0543
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0543:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0544
	jmp .L_lambda_simple_end_0544
.L_lambda_simple_code_0544:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0544
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0544:
	enter 0, 0
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043c
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2		; arg count
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 3
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0545
	jmp .L_lambda_simple_end_0545
.L_lambda_simple_code_0545:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0545
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0545:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2		; arg count
	mov rax, qword [free_var_127]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3		; arg count
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3		; arg count
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_076b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076b
.L_tc_recycle_frame_done_076b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0545:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_076a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076a
.L_tc_recycle_frame_done_076a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_043c
.L_if_else_043c:
	mov rax, PARAM(0)	; param vec
.L_if_end_043c:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0544:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0546
	jmp .L_lambda_simple_end_0546
.L_lambda_simple_code_0546:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0546
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0546:
	enter 0, 0
	mov rax, PARAM(0)	; param vec
	push rax
	push 1		; arg count
	mov rax, qword [free_var_126]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0547
	jmp .L_lambda_simple_end_0547
.L_lambda_simple_code_0547:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0547
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0547:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043d
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_043d
.L_if_else_043d:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2148
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 24
	mov r12, rdi
	lea rdi, [r12 + 16]	; Dest_High
	lea rsi, [rsp + 16]	; Source_High
	mov r10, 3
.L_tc_recycle_frame_loop_076d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076d
.L_tc_recycle_frame_done_076d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_043d:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0547:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_076c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076c
.L_tc_recycle_frame_done_076c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0546:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0543:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0548
	jmp .L_lambda_simple_end_0548
.L_lambda_simple_code_0548:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0548
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0548:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0549
	jmp .L_lambda_simple_end_0549
.L_lambda_simple_code_0549:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0549
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0549:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054a
	jmp .L_lambda_simple_end_054a
.L_lambda_simple_code_054a:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054a:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043e
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 1		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_74]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_076f:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076f
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076f
.L_tc_recycle_frame_done_076f:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_043e
.L_if_else_043e:
	mov rax, L_constants + 1
.L_if_end_043e:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2148
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0770:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0770
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0770
.L_tc_recycle_frame_done_0770:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0549:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_076e:
	cmp r10, 0
	je .L_tc_recycle_frame_done_076e
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_076e
.L_tc_recycle_frame_done_076e:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0548:	; new closure is in rax
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054b
	jmp .L_lambda_simple_end_054b
.L_lambda_simple_code_054b:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054b:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_93]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054c
	jmp .L_lambda_simple_end_054c
.L_lambda_simple_code_054c:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054c:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054d
	jmp .L_lambda_simple_end_054d
.L_lambda_simple_code_054d:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054d:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054e
	jmp .L_lambda_simple_end_054e
.L_lambda_simple_code_054e:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_054e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054e:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_043f
	mov rax, PARAM(0)	; param i
	push rax
	push 1		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3		; arg count
	mov rax, qword [free_var_119]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0773:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0773
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0773
.L_tc_recycle_frame_done_0773:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_043f
.L_if_else_043f:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_043f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054e:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2148
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0774:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0774
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0774
.L_tc_recycle_frame_done_0774:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054d:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0772:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0772
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0772
.L_tc_recycle_frame_done_0772:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_054c:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0771:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0771
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0771
.L_tc_recycle_frame_done_0771:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054b:	; new closure is in rax
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_054f
	jmp .L_lambda_simple_end_054f
.L_lambda_simple_code_054f:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_054f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_054f:
	enter 0, 0
	mov rax, PARAM(0)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_95]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov r8, 2
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0550
	jmp .L_lambda_simple_end_0550
.L_lambda_simple_code_0550:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0550
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0550:
	enter 0, 0
	mov rax, L_constants + 1993
	push rax
	push 1
	mov r8, 1
mov r9, 2
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0551
	jmp .L_lambda_simple_end_0551
.L_lambda_simple_code_0551:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0551
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0551:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing run
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 3
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0552
	jmp .L_lambda_simple_end_0552
.L_lambda_simple_code_0552:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0552
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0552:
	enter 0, 0
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0440
	mov rax, PARAM(0)	; param i
	push rax
	push 1		; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var generator
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3		; arg count
	mov rax, qword [free_var_130]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0777:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0777
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0777
.L_tc_recycle_frame_done_0777:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0440
.L_if_else_0440:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_0440:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0552:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rax, L_constants + 2148
	push rax
	push 1
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0778:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0778
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0778
.L_tc_recycle_frame_done_0778:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0551:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0776:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0776
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0776
.L_tc_recycle_frame_done_0776:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0550:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_0775:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0775
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0775
.L_tc_recycle_frame_done_0775:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_054f:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0553
	jmp .L_lambda_simple_end_0553
.L_lambda_simple_code_0553:	
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_0553
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0553:
	enter 0, 0
	mov rax, PARAM(2)	; param n
	push rax
	push 1		; arg count
	mov rax, qword [free_var_135]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0443
	mov rax, L_constants + 3192
	jmp .L_if_end_0443
.L_if_else_0443:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2		; arg count
	mov rax, qword [free_var_4]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0442
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2		; arg count
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3		; arg count
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3192
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_0779:
	cmp r10, 0
	je .L_tc_recycle_frame_done_0779
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_0779
.L_tc_recycle_frame_done_0779:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_0442
.L_if_else_0442:
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2		; arg count
	mov rax, qword [free_var_6]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_0441
	mov rax, L_constants + 3192
	jmp .L_if_end_0441
.L_if_else_0441:
	mov rax, L_constants + 2283
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3		; arg count
	mov rax, qword [free_var_91]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3192
	push rax
	push 2
	mov rax, qword [free_var_3]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_077a:
	cmp r10, 0
	je .L_tc_recycle_frame_done_077a
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_077a
.L_tc_recycle_frame_done_077a:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_0441:
.L_if_end_0442:
.L_if_end_0443:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_0553:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0554
	jmp .L_lambda_simple_end_0554
.L_lambda_simple_code_0554:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0554
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0554:
	enter 0, 0
	mov rax, L_constants + 3217
	push rax
	push 1
	mov rax, qword [free_var_134]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 8
	mov r12, rdi
	lea rdi, [r12 + 0]	; Dest_High
	lea rsi, [rsp + 0]	; Source_High
	mov r10, 1
.L_tc_recycle_frame_loop_077b:
	cmp r10, 0
	je .L_tc_recycle_frame_done_077b
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_077b
.L_tc_recycle_frame_done_077b:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0554:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0555
	jmp .L_lambda_simple_end_0555
.L_lambda_simple_code_0555:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0555
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0555:
	enter 0, 0
	mov rax, L_constants + 0
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0555:	; new closure is in rax
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void
	mov rax, L_constants + 2148
	push rax
	push 1		; arg count
	mov r8, 0
mov r9, 0
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0556
	jmp .L_lambda_simple_end_0556
.L_lambda_simple_code_0556:	
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_0556
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0556:
	enter 0, 0
	mov rdi, 8 * 1
	call malloc
	mov rbx, PARAM(0)	; boxing x
	mov qword [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0557
	jmp .L_lambda_simple_end_0557
.L_lambda_simple_code_0557:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0557
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0557:
	enter 0, 0
	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	mov rax, qword [rax]
	push rax
	push 2		; arg count
	mov rax, qword [free_var_2]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	mov rax, qword [rax]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0557:	; new closure is in rax
	push rax
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0558
	jmp .L_lambda_simple_end_0558
.L_lambda_simple_code_0558:	
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_0558
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0558:
	enter 0, 0
	mov rax, L_constants + 2283
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	mov rax, qword [rax]
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	pop qword [rax]
	mov rax, sob_void

	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var x
	mov rax, qword [rax]
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_0558:	; new closure is in rax
	push rax
	push 2
	mov r8, 1
mov r9, 1
	call extend_lexical_environment
	mov r9, rax
	mov rdi, 1 + 8 + 8
	call malloc
	mov byte [rax], T_closure
	mov qword [rax + 1], r9
	mov qword [rax + 1 + 8], .L_lambda_simple_code_0559
	jmp .L_lambda_simple_end_0559
.L_lambda_simple_code_0559:	
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_0559
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_0559:
	enter 0, 0
	push 0		; arg count
	mov rax, PARAM(1)	; param dec
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 0		; arg count
	mov rax, PARAM(0)	; param inc
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2		; arg count
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 0		; arg count
	mov rax, PARAM(0)	; param inc
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2
	mov rax, qword [free_var_1]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_077d:
	cmp r10, 0
	je .L_tc_recycle_frame_done_077d
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_077d
.L_tc_recycle_frame_done_077d:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_0559:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	push qword [rbp + 8*1]
	pop rbx
	pop rcx
	pop rdx
	mov r8, qword [rbp]
	mov r9, qword [rbp + 8*3]
	lea rdi, [rbp + 8*4 + r9*8]
	sub rdi, 16
	mov r12, rdi
	lea rdi, [r12 + 8]	; Dest_High
	lea rsi, [rsp + 8]	; Source_High
	mov r10, 2
.L_tc_recycle_frame_loop_077c:
	cmp r10, 0
	je .L_tc_recycle_frame_done_077c
	mov r11, qword [rsi]
	mov qword [rdi], r11
	sub rsi, 8
	sub rdi, 8
	dec r10
	jmp .L_tc_recycle_frame_loop_077c
.L_tc_recycle_frame_done_077c:
	mov qword [r12 - 8],  rdx	; New COUNT
	mov qword [r12 - 16], rcx	; New ENV
	mov qword [r12 - 24], rbx	; RET
	lea rsp, [r12 - 24]	; Update RSP
	mov rbp, r8
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_0556:	; new closure is in rax
	assert_closure(rax)
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
Lend:
	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, 0
        call exit

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_return:
	cmp qword [rsp + 8*2], 2
	jne L_error_arg_count_2
	mov rcx, qword [rsp + 8*3]
	assert_integer(rcx)
	mov rcx, qword [rcx + 1]
	cmp rcx, 0
	jl L_error_integer_range
	mov rax, qword [rsp + 8*4]
.L0:
        cmp rcx, 0
        je .L1
	mov rbp, qword [rbp]
	dec rcx
	jg .L0
.L1:
	mov rsp, rbp
	pop rbp
        pop rbx
        mov rcx, qword [rsp + 8*1]
        lea rsp, [rsp + 8*rcx + 8*2]
	jmp rbx

;;; r8 : params
;;; r9 : | env |
extend_lexical_environment:
    enter 0, 0
    push rbx
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push r12 

    mov r10, qword [rbp]    ; r10 = caller's rbp 
    mov rdi, r8             ; rdi = param count
    shl rdi, 3              ; rdi = bytes needed
    call malloc             ; rax = pointer to new rib
    mov rcx, r8             ; rcx = param count
    mov rbx, rax            ; rbx = pointer to rib start
    lea rdx, [r10 + 4 * 8]  ; rdx = Address of Arg 0 in the previous stack

.copy_params_loop:
    cmp rcx, 0              ; iterating each argument
    je .copy_params_end
    mov r10, qword [rdx]            
    mov qword [rbx], r10    ; assign the args from the prevous stack to the rib address
    add rdx, 8              
    add rbx, 8              
    dec rcx
    jmp .copy_params_loop

.copy_params_end:
    mov r12, rax            ; r12 = Pointer to the rib we just assigned to
    mov rdi, r9             ; rdi = env depth
    inc rdi                 ; +1 for the new rib
    shl rdi, 3              ; * 8 bytes
    call malloc             ; rax = pointer to new vector of pointers to the majors/ribs
  
    mov qword [rax], r12   ; insert the first rib we have set before newenv[0]  
    mov r11, qword [rbp]         ; get caller's rbp again
    mov r10, qword [r11 + 2 * 8] ; load old env (rbp + 16)

    mov rcx, r9                  ; env depth
    mov rbx, rax                 ; new env
    add rbx, 8                   ; newenv[1]
    
    ;iterating and copying the old env to the new env
    cmp rcx, 0
    je .copy_env_end

.copy_env_loop:  
    cmp rcx, 0
    je .copy_env_end
    
    mov r11, qword [r10]    
    mov qword [rbx], r11    
    
    add r10, 8              
    add rbx, 8              
    dec rcx
    jmp .copy_env_loop

.copy_env_end:
    ; rax is newEnv (return value)
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rbx
    leave
    ret

;;; fixing the stack
;;; R9 : List.length params'
opt_fix_stack:
        mov rcx, qword [rsp + 8*3] 	; count
        cmp rcx, r9
        jl L_error_arg_count_2
        jg .Lmore
        mov rsi, rsp
        sub rsp, 8*1
        mov rdi, rsp
        add rcx, 4
        cld
        rep movsq
        inc qword [rsp + 8*3] 		; ++count
        mov qword [rsp + 8*r9 + 8*4], sob_nil
        jmp .Ldone
.Lmore:
        mov rbx, [rsp + 8*3] 		; how many were pushed
        lea r11, [rsp + 8*rbx + 8*3] 	; ptr to top element in the frame
        mov r10, sob_nil     		; initial argl
        mov r12, r11			; backup ptr to top element
        sub rcx, r9			; size of list
.L0:
        cmp rcx, 0
        je .L0out
        mov rdi, 1 + 8 + 8 		; sizeof(pair)
        call malloc
        mov byte [rax], T_pair 		; rtti
        mov qword [rax + 1 + 8], r10 	; cdr
        mov rbx, qword [r11]
        mov qword [rax + 1], rbx 	; car
        mov r10, rax
        sub r11, 8*1
        dec rcx
        jmp .L0
.L0out:
        mov qword [r12], r10 		; set list
        lea rdi, [r12 - 8*1]
        lea rsi, [rsp + 8*r9 + 8*3]
        mov rcx, r9
        add rcx, 4
        std
        rep movsq
        cld
        lea rsp, [rdi + 8*1]
        lea rbx, [r9 + 1]
        mov qword [rsp + 8*3], rbx
.Ldone:
        ret

L_code_ptr_make_list:
	enter 0, 0
        cmp COUNT, 1
        je .L0
        cmp COUNT, 2
        je .L1
        jmp L_error_arg_count_12
.L0:
        mov r9, sob_void
        jmp .L2
.L1:
        mov r9, PARAM(1)
.L2:
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_arg_negative
        mov r8, sob_nil
.L3:
        cmp rcx, 0
        jle .L4
        mov rdi, 1 + 8 + 8
        call malloc
        mov byte [rax], T_pair
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        mov r8, rax
        dec rcx
        jmp .L3
.L4:
        mov rax, r8
        cmp COUNT, 2
        je .L5
        leave
        ret AND_KILL_FRAME(1)
.L5:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_is_primitive:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rax, PARAM(0)
	assert_closure(rax)
	cmp SOB_CLOSURE_ENV(rax), 0
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_end
.L_false:
	mov rax, sob_boolean_false
.L_end:
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_length:
	enter 0, 0
	cmp COUNT, 1
	jne L_error_arg_count_1
	mov rbx, PARAM(0)
	mov rdi, 0
.L:
	cmp byte [rbx], T_nil
	je .L_end
	assert_pair(rbx)
	mov rbx, SOB_PAIR_CDR(rbx)
	inc rdi
	jmp .L
.L_end:
	call make_integer
	leave
	ret AND_KILL_FRAME(1)

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
    enter 0, 0


    ; Check the argument count (located at rbp + 24)
    cmp qword [rbp + 24], 2
    jne L_error_incorrect_arity_simple  ; Jump to error handler if not exactly 2

    ; 1. Push Args Loop 
    mov rbx, qword [rbp + 40]    ; rbx = List (s)
    mov rdx, rbx                 ; Iterator
    xor r8, r8                   ; r8 = New Count

.push_loop:
    cmp byte [rdx], T_nil
    je .push_done
    mov rsi, qword [rdx + 1]     ; Car
    push rsi                     ; Push
    inc r8
    mov rdx, qword [rdx + 9]     ; Cdr
    jmp .push_loop

.push_done:
    ; 2. Reverse Arguments
    mov rcx, r8
    lea rsi, [rsp]
    lea rdi, [rsp + r8*8 - 8]
    shr rcx, 1
.rev_loop:
    cmp rcx, 0
    je .rev_done
    mov r10, [rsi]
    mov r11, [rdi]
    mov [rsi], r11
    mov [rdi], r10
    add rsi, 8
    sub rdi, 8
    dec rcx
    jmp .rev_loop
.rev_done:

    ; 3. Push Header (Count, Env)
    push r8                      ; New Count
    mov rax, qword [rbp + 32]    ; Procedure (f)
    cmp byte [rax], T_closure
    jne L_error_non_closure
    push qword [rax + 1]         ; New Env

    ; A. Save info from the Old Frame
    mov rbx, qword [rax + 9]     ; Target Code Pointer
    mov r10, qword [rbp]         ; Old Saved RBP
    mov r11, qword [rbp + 8]     ; Old Return Address
    lea rsi, [rsp+8+r8*8]       ; rsi=last new arg
    lea rdi, [rbp+8*5]      ; rsi =last arg in the apply frame      
    mov rcx, r8                  ; rcx= num of new args
.copy_bin_loop:
    cmp rcx, 0     
    je .bin_loop_done
    mov rdx, qword[rsi]
    mov qword [rdi], rdx
    sub rsi, 8
    sub rdi, 8
    dec rcx
    jmp .copy_bin_loop

.bin_loop_done:
    mov rcx, [rsp]  ;rcx=new env
    mov rdx, r8                  ; rdx = count
    shl rdx, 3                   ; rdx = count * 8
    neg rdx                      ; rax = -(count * 8)
    lea rsp, [rbp + 40 + 8]      ; rsp = Top + 8 
    add rsp, rdx                 ; rsp = Top + 8 - (count * 8)
    push r8     ; push new num of args
    push rcx    ; push new env
    push r11    ; push old ret address
    mov rbp, r10  ; reset the old rbp
    jmp rbx    ; jump to the the code of the function in tail position

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
        cmp dl, T_integer
        je .L_integer
	jmp .L_eq_false
.L_integer:
        mov rax, qword [rsi + 1]
        cmp rax, qword [rdi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_negative:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_negative
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_negative:
        db `!!! The argument cannot be negative.\n\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`

section .note.GNU-stack
        
