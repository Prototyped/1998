#include <iostream.h>

class jar {
	unsigned capacity;
public:
	jar (unsigned volume) { capacity = volume; };
	unsigned contents;
	friend void transfer (jar &dest, jar &src);
	friend void display (jar one, jar two, char *label1, char *label2);
	void discard (void) { contents = 0; };
	void fill (void) { contents = capacity; };
};

void transfer (jar &dest, jar &src)
{
	if (src.contents >= dest.capacity - dest.contents) {
		src.contents -= dest.capacity - dest.contents;
		dest.contents = dest.capacity;
	}
	else {
		dest.contents += src.contents;
		src.contents = 0;
	}
}

inline void display (jar one, jar two, char *label1, char *label2)
{
	printf ("Contents:\t%s: %2u\t%s: %2u\n", label1, one.contents, label2, two.contents);
}

char utable [] = { 1, 1, 1,
			    2, 4, 2, 4, 6, 8,
			    3, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9,
			    4, 4, 2, 4, 6, 8,
			    5, 1, 5,
			    6, 4, 2, 4, 6, 8,
			    7, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9,
			    8, 4, 2, 4, 6, 8,
			    9, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

void main (void)
{
	unsigned sizeA, sizeB, volume;
	char i = 0, j = 0;
	jar l, s;
	cout << "Enter sizes of jars and the volume required: ";
	cin >> sizeA >> sizeB >> volume;
	if (sizeA == sizeB) {
		if (sizeA == volume) {
			cout << "Either jar is filled, and its contents give the required volume.\n";
			return;
		}
		else {
			cout << "The volume cannot be obtained.\n";
			return;
		}
	}
	jar A (sizeA), B (sizeB);
	l.jar (sizeA > sizeB ? sizeA : sizeB);
	s.jar (sizeA < sizeB ? sizeA : sizeB);
	i = (l.capacity - s.capacity) % 10;
	while (j < sizeof (utable)) {
		while (utable [j] != i)
			j += utable [++j];
		if (j >= sizeof (utable)) {
			cerr << "Out of bounds error\n";
			return;
		}
		j ++;
		for (i = 0; i < utable [j]; i ++)
			if (!(volume % utable [i + j])) break;

}
