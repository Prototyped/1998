#include <stdio.h>
#include <stdlib.h>
#include <dir.h>
#include <io.h>
#include <fcntl.h>
#include <dos.h>

#define toupper(x) ((x >= 'a') && (x <= 'z')) ? (x - 32) : x;

int compare (char *str1, char *str2, unsigned slen);
int trunc (int handle);

int main (int argc, char *argv [])
{
	int handle;
	char i, *mp1, *mp2;
	char drive [MAXDRIVE];
	char dir [MAXDIR];
	char file [MAXFILE];
	char ext [MAXEXT];

	puts ("Virus Killer\n");

	if (argc == 1) {
		puts ("Usage: VK filename\n");
		return 1;
	}

	if ((handle = _open (argv [1], O_BINARY | O_RDWR)) == -1) {
		puts ("Error: Unable to open file ");
		puts (argv [1]);
		putchar ('\n');
		return 2;
	}

	if ((mp1 = (char *) malloc (0x18)) == NULL) {
		puts ("Error: Memory allocation error\n");
		return 3;
	}

	if (read (handle, mp1, 0x18) == -1) {
		puts ("Error: File read error\n");
		_close (handle);
		return 4;
	}

	if ((mp2 = (char *) malloc (0x18)) == NULL) {
		puts ("Error: Memory allocation error\n");
		return 3;
	}

	if (lseek (handle, -0x18L, SEEK_END) == -1L) {
		puts ("Error: File seek error\n");
		return 5;
	}

	if (read (handle, mp2, 0x18) == -1) {
		puts ("Error: File read error\n");
		_close (handle);
		return 4;
	}

	fnsplit (argv [1], drive, dir, file, ext);

	for (i = 0; i < 4; i ++) ext [i] = toupper (ext [i]);

	ext [4] = '\0';

	if (compare (ext, ".EXE", 3)) {
		if (compare (ext, ".COM", 3)) {
			puts ("Error: Given file is not EXE or COM file\n");
			return 6;
		}

		if (!compare (mp1 + 3, mp2 + 3, 0x15)) {
			puts ("Alert! Virus found in file ");
			puts (argv [1]);
			puts ("\n!");
			if (lseek (handle, 0L, SEEK_SET) == -1L) {
				puts ("Error: File seek error\n");
				_close (handle);
				return 5;
			}

			if (write (handle, mp2, 0x18) == -1) {
				puts ("Error: File write error\n");
				_close (handle);
				return 7;
			}

			free (mp1);
			free (mp2);

			if (lseek (handle, -0x1288L, SEEK_END) == -1L) {
				puts ("Error: File seek error\n");
				_close (handle);
				return 5;
			}

			if (write (handle, mp1, 0) == -1) {
				puts ("Error: File truncate error\n");
				_close (handle);
				return 7;
			}

			if (_close (handle)) {
				puts ("Error: File close error\n");
				return 8;
			}

			return -1;
		}

		else
		{
			puts ("Virus not found\n");

			if (_close (handle)) {
				puts ("Error: File close error\n");
				return 8;
			}

			free (mp1);
			free (mp2);
			return 0;
		}
	}

	else
	{
		if (compare (mp2, "MZ", 2)) {
			puts ("Virus not found\n");

			if (_close (handle)) {
				puts ("Error: File close error\n");
				return 8;
			}

			free (mp1);
			free (mp2);
			return 0;
		}

		puts ("Alert! Virus found in file ");
		puts (argv [1]);
		puts ("\n!");

		if (lseek (handle, 0L, SEEK_SET) == -1L) {
			puts ("Error: File seek error\n");
			_close (handle);
			return 5;
		}

		if (write (handle, mp2, 0x18) == -1) {
			puts ("Error: File write error\n");
			_close (handle);
			return 7;
		}

		free (mp1);
		free (mp2);

		if (lseek (handle, -0x1288L, SEEK_END) == -1) {
			puts ("Error: File seek error\n");
			_close (handle);
			return 5;
		}

		if (trunc (handle) == -1) {
			puts ("Error: File truncate error\n");
			_close (handle);
			return 9;
		}

		return -1;
	}
}

int compare (char *str1, char *str2, unsigned slen)
{
	int i;

	for (i = 0; ((i < slen) && (*(str1 + i) == *(str2 + i))); i ++);
	if (i != slen) return -1;
	else return 0;
}

int trunc (int handle)
{
	union REGS regs;

	regs.h.ah = 0x40;
	regs.x.bx = handle;
	regs.x.cx = 0;
	regs.x.dx = 0xFFFF;
	intdos (&regs, &regs);
	if (regs.x.flags & 1) return -1;

	if (_close (handle)) return -1;
	else return 0;
}

