10  SCREEN 0: CLS
20  INPUT "Enter number of data: ", n
30  DIM Raw(n, 2)
40  PRINT : PRINT , "x", "y"
50  Sum.x = 0: Sum.y = 0: Sum.xy = 0: Sum.x.squared = 0: Sum.y.squared = 0
60  FOR i = 1 TO n
70       PRINT i,
80       INPUT ; "", Raw(i, 0)
90       PRINT ,
100      INPUT "", Raw(i, 1)
110      Sum.x = Sum.x + Raw(i, 0)
120      Sum.y = Sum.y + Raw(i, 1)
130      Sum.xy = Sum.xy + Raw(i, 0) * Raw(i, 1)
140      Sum.x.squared = Sum.x.squared + Raw(i, 0) ^ 2
150      Sum.y.squared = Sum.y.squared + Raw(i, 1) ^ 2
160 NEXT i
170 A = (Sum.y * Sum.x.squared - Sum.xy * Sum.x) / (n * Sum.x.squared - Sum.x ^ 2)
180 B = (Sum.xy - Sum.x * Sum.y / n) / (Sum.x.squared - Sum.x ^ 2 / n)
190 PRINT "The required regression line equation is:"
200 PRINT "y = "; A;
210 IF SGN(B) = -1 THEN PRINT "-";  ELSE IF SGN(B) = 0 THEN PRINT : GOTO 230 ELSE PRINT "+";
220 PRINT ABS(B); "x"
230 PRINT "Correlation Coefficient: "; (Sum.xy - Sum.x * Sum.y / n) / SQR((Sum.x.squared - Sum.x ^ 2 / n) * (Sum.y.squared - Sum.y ^ 2 / n))
240 KEY OFF: LOCATE 25, 1: PRINT "Press a key to continue . . ."; : A$ = INPUT$(1)
250 SCREEN 2: CLS
260 x.max = 0: x.min = 0: y.max = 0: y.min = 0
270 FOR i = 1 TO n
280      IF Raw(i, 1) > y.max THEN y.max = Raw(i, 1)
290      IF Raw(i, 0) > x.max THEN x.max = Raw(i, 0)
300      IF Raw(i, 0) < x.min THEN x.min = Raw(i, 0)
310      IF Raw(i, 1) < y.min THEN y.min = Raw(i, 1)
320 NEXT i
330 y.min = y.min * 1.05: y.max = y.max * 1.05: x.min = x.min * 1.05: x.max = x.max * 1.05
340 IF (x.max - x.min) > (y.max - y.min) THEN Range = x.max - x.min ELSE Range = y.max - y.min
350 x.max = x.min + Range
360 y.max = y.min + Range
370 IF x.min < 0 AND x.max < 0 THEN x.max = 0
380 IF x.min > 0 AND x.max > 0 THEN x.min = 0
390 IF y.min < 0 AND y.max < 0 THEN y.max = 0
400 IF y.min > 0 AND y.max > 0 THEN y.min = 0
410 WINDOW (x.min * 4 / 3, y.min)-(x.max * 4 / 3, y.max)
420 LINE (x.min * 4 / 3, 0)-(x.max * 4 / 3, 0)
430 LINE (0, y.min)-(0, y.max)
440 FOR i = 1 TO n
450      PSET (Raw(i, 0), Raw(i, 1))
460      CIRCLE (Raw(i, 0), Raw(i, 1)), Range / 160
470 NEXT i
480 LINE (x.min * 4 / 3, x.min * 4 / 3 * B + A)-(x.max * 4 / 3, x.max * 4 / 3 * B + A)
490 A$ = INPUT$(1)
500 END

