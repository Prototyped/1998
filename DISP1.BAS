ON ERROR GOTO ErrHandler
DIM PIX(7682)
SCREEN 2
CLS
OUT &H3D9, 7
PAINT (319, 199), 3
OPEN "star.prn" FOR BINARY AS #1
'FOR A = 1 TO 35
'WHILE (ASC(INPUT$(1, 1)) <> 10)
'WEND
'NEXT
GOSUB Search
X = 0
Start:
A$ = INPUT$(1, 1)
A = ASC(A$)
IF A = 255 THEN LINE (X, Y)-(X, Y + 7), 0: GOTO Skip
IF A = 0 THEN GOTO Skip
IF X >= 640 THEN GOTO Skip
FOR Z = 0 TO 7
IF (A AND 2 ^ (7 - Z)) THEN PSET (X, Z + Y), 0
NEXT
Skip:
'A$ = INPUT$(1, 1)
'C = C + 2
IF C > I THEN GOTO Start2
C = C + 1
X = X + 1
GOTO Start
Start2:
'Y = Y + 4
'Y = Y + 8
'IF Y >= 199 THEN GOTO Pause
Restart:
GOSUB Search
'X = 0
C = 0
'A$ = INPUT$(25 * I \ 100, 1)
'I = I - 25 * I \ 100
IF EOF(1) THEN END
GOTO Start
ErrHandler:
END
Pause:
IF INKEY$ = "" THEN GOTO Pause
GET (0, 8)-(639, 199), PIX
PUT (0, 0), PIX, PSET
LINE (0, 192)-(639, 199), 3, BF
Y = 192
RETURN
Search:
A$ = INPUT$(2, 1)
Search1:
IF MID$(A$, 1, 1) = CHR$(13) THEN X = 0
IF MID$(A$, 1, 1) = CHR$(10) THEN IF Y < 192 THEN Y = Y + 8 ELSE GOSUB Pause
IF A$ = CHR$(&H1B) + CHR$(&H5A) THEN GOTO Search2
MID$(A$, 1) = MID$(A$, 2, 1)
MID$(A$, 2) = INPUT$(1, 1)
GOTO Search1
Search2:
I = CVI(INPUT$(2, 1)) - 2
RETURN

