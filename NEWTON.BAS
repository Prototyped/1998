10   ON ERROR GOTO 80
20   DEF FNF# (X#) = (X#) ^ -(1 / 3) + SIN(4 * X# ^ .123123123#) - LOG(ABS(3.33323 * X# ^ .04))
30   DEF FNG# (X#) = -1 / 3 * (X#) ^ (-4 / 3) + 4 * .123123123# * X# ^ (.123123123# - 1) * COS(4 * X# ^ .123123123#) - .04 / X#
40   INPUT "Enter a seed: ", X#
50   GOSUB 210
60   PRINT "Solution: x# ="; X#
70   END
80   IF ERR <> 11 THEN ON ERROR GOTO 0: ERROR ERR
90   IF FNF#(X#) = 0 THEN PRINT 0: PRINT "Solution: x# ="; X#: END
100  IF FNF#(X#) <> 0 THEN PRINT "The seed is at a stationary point. Solving for roots on either side of the stationary point:"
110  Y# = X#
120  X# = 11 / 10 * X#
130  IF X# = 0 THEN X# = .1
140  GOSUB 210
150  PRINT "One solution: "; X#
160  X# = 9 / 10 * Y#
170  IF X# = 0 THEN X# = -.1
180  GOSUB 210
190  PRINT "Another solution:"; X#
200  END
210  IF FNF#(X#) = 0 THEN 260
220       PRINT X#, FNF#(X#) / FNG#(X#)
230       X# = X# - FNF#(X#) / FNG#(X#)
240  IF INKEY$ <> "" THEN 260
250  GOTO 210
260  RETURN

