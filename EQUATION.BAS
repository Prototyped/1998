10 CLS
20 INPUT "Enter number of variables: ", N
30 OPTION BASE 1: PRINT
40 DIM A(N, N), B(N, N), ARRAY(N), C(N), X(N)
50 FOR R = 1 TO N
60   FOR C = 1 TO N
70        PRINT "Enter Coefficient for variable"; C; "of equation"; R;
80        INPUT ": ", A(R, C)
90   NEXT C
100  PRINT : PRINT "Enter RHS of equation"; R; : INPUT ": ", ARRAY(R): PRINT
110 NEXT R
120 PRINT
170 FOR R = 1 TO N
180  FOR C = 1 TO N
190       B(R, C) = A(R, C)
200  NEXT C
210 NEXT R
220 FOR K = 1 TO N
230  C(K) = 0
240  P = B(K, 1)
250  IF P <> 0 THEN GOTO 370
260  FOR R = K + 1 TO N
270       C(K) = R
280       IF B(R, 1) = 0 THEN GOTO 350
290       FOR C = 1 TO N
300            S = B(K, C)
310            B(K, C) = B(R, C)
320            B(R, C) = S
330       NEXT C
340       GOTO 240
350  NEXT R
360  COLOR 15: PRINT "* * * "; : COLOR 30: PRINT "No solution exists"; : COLOR 15: PRINT " * * *": COLOR 7: END
370  FOR C = 1 TO N - 1
380       B(K, C) = B(K, C + 1) / P
390       NEXT C
400  B(K, N) = 1 / P
410  FOR R = 1 TO N
420       IF R = K THEN GOTO 480
430       S = B(R, 1)
440       FOR C = 1 TO N - 1
450            B(R, C) = B(R, C + 1) - S * B(K, C)
460       NEXT C
470       B(R, N) = -S * B(K, N)
480  NEXT R
490 NEXT K
500 FOR K = N - 1 TO 1 STEP -1
510  C = C(K)
520  IF C = 0 THEN 580
530  FOR R = 1 TO N
540       S = B(R, K)
550       B(R, K) = B(R, C)
560       B(R, C) = S
570  NEXT R
580 NEXT K
590 FOR R = 1 TO N
600       X(R) = 0
610       FOR K = 1 TO N
620            X(R) = X(R) + B(R, K) * ARRAY(K)
630 NEXT K, R
640 PRINT : PRINT : COLOR 14: PRINT "Results:": COLOR 7: PRINT : PRINT
650 FOR A = 1 TO N
660  PRINT "X"; RIGHT$(STR$(A), LEN(STR$(A)) - 1); " = "; X(A)
670 NEXT A
680 END
