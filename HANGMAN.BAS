KEY OFF
KEY 15, CHR$(0) + CHR$(59)
ON KEY(15) GOSUB KeyCapture
KEY(15) ON
COLOR 7, 1
CLS
LOCATE 3, 5
COLOR 6, 7
PRINT " HangMan ";
LOCATE 23, 5
PRINT " HangMan ";
LOCATE 3, 66
PRINT " HangMan ";
LOCATE 23, 66
PRINT " HangMan ";
COLOR 5, 3
LOCATE 12, 26
PRINT " * * * ";
COLOR 30
PRINT "H A N G M A N";
COLOR 5
PRINT " * * * ";
LOCATE 25, 24
COLOR 1, 7
PRINT " --- Press any key to begin --- ";
A$ = INPUT$(1)
COLOR 7, 1
CLS
PRINT " Enter the word/words you have thought of at the prompt, and press Enter key."
LOCATE 25, 21
PRINT " --- Press Enter only to exit --- ";
LOCATE 12, 3
LINE INPUT "> "; Word$
IF Word$ = "" THEN END
CLS
PRINT TAB(11); "Now, guess at the word letter-by-letter or the whole word."
LOCATE 25, 6
PRINT "Press F1 to guess the whole word, a letter as a guess, or Esc to exit.";
Guess = 10
Display.string$ = ""
FOR Count = 1 TO LEN(Word$)
        IF MID$(Word$, Count, 1) >= "A" AND MID$(Word$, Count, 1) <= "Z" THEN Display.string$ = Display.string$ + "-": GOTO Continue
        IF MID$(Word$, Count, 1) >= "a" AND MID$(Word$, Count, 1) <= "z" THEN Display.string$ = Display.string$ + "-": GOTO Continue
        Display.string$ = Display.string$ + MID$(Word$, Count, 1)
Continue:
Word.in.uppercase$ = Word.in.uppercase$ + CHR$(ASC(MID$(Word$, Count, 1)) AND 223)
NEXT Count
LOCATE 10, INT((80 - LEN(Display.string$)) / 2)
PRINT Display.string$;
Loop1:
LOCATE 6, 32
PRINT "Guesses left:"; Guess
IF Guess <= 0 THEN LOCATE 18, 34: COLOR 30: PRINT "You're hung!": COLOR 7: END
Loop2:
A$ = INKEY$
IF A$ = "" THEN GOTO Loop2
IF A$ = CHR$(0) THEN IF INKEY$ = CHR$(59) THEN GOSUB KeyCapture: GOTO Loop1
IF A$ = CHR$(27) THEN END
IF INSTR(Word.in.uppercase$, CHR$(ASC(A$) AND 223)) = 0 THEN Guess = Guess - 1: GOTO Loop1
FOR Count = 1 TO LEN(Word$)
     IF MID$(Word.in.uppercase$, Count, 1) = CHR$(ASC(A$) AND 223) THEN MID$(Display.string$, Count, 1) = MID$(Word$, Count, 1)
NEXT Count
LOCATE 10, INT((80 - LEN(Display.string$)) / 2)
PRINT Display.string$;
IF Display.string$ = Word$ THEN LOCATE 18, 36: COLOR 30: PRINT "You won!": COLOR 7: END
GOTO Loop1
KeyCapture:
LOCATE 18, 26
PRINT "Now, guess the whole thing:"
LINE INPUT "> "; A$
A.in.uppercase$ = ""
FOR Count = 1 TO LEN(A$)
     A.in.uppercase$ = A.in.uppercase$ + CHR$(ASC(MID$(A$, Count, 1)) AND 223)
NEXT Count
LOCATE 18, 1
PRINT STRING$(240, 32);
IF A.in.uppercase$ = Word.in.uppercase$ THEN COLOR 30: LOCATE 18, 36: PRINT "You won!": COLOR 7: LOCATE 10, INT((80 - LEN(Word$)) / 2): PRINT Word$; : END
BEEP: COLOR 30: LOCATE 18, 33: PRINT "Wrong answer!": COLOR 7
Guess = Guess - 2
Time = TIMER
WHILE TIMER < Time + 4
WEND
LOCATE 18, 1
PRINT STRING$(240, 32);
RETURN

