#include <stdio.h>
#include <conio.h>
#include <string.h>

class MyString
{
public:

	MyString(const char* str = "")	//default constructor
	{
		strcpy_s(m_str, customStringLength, str);
		m_currentLength = strnlen_s(m_str, customStringLength);
	}

	MyString(int num)
	{
		sprintf_s(m_str, customStringLength, "%d", num);
		m_currentLength = strnlen_s(m_str, customStringLength);
	}

	MyString(double num)
	{
		sprintf_s(m_str, customStringLength, "%f", num);
		// remove trailing zeroes
		char* p;
		p = strchr(m_str, '\0');
		--p;
		while (*p == '0' || *p == '.') *p-- = '\0';
		m_currentLength = strnlen_s(m_str, customStringLength);
	}

	MyString(const MyString& rhs)	//copy constructor
	{
		strcpy_s(m_str, customStringLength, rhs.GetString());
		m_currentLength = rhs.GetLength();
	}

	MyString& operator = (const MyString& rhs)	//assignment operator
	{
		strcpy_s(m_str, customStringLength, rhs.GetString());
		m_currentLength = rhs.GetLength();
		return *this;
	}

	const char* GetString() const
	{
		return m_str;
	}

	size_t GetLength() const
	{
		return m_currentLength;
	}

	MyString& operator += (const MyString& rhs)
	{
		strcat_s(m_str, customStringLength, rhs.GetString());
		m_currentLength += rhs.GetLength();
		return *this;
	}

	MyString& operator *= (const int rhs)
	{
		char buff[customStringLength] = "";
		int i = 0;
		for (; i < rhs; ++i)
		{
			strcat_s(buff, customStringLength, m_str);
		}
		strcpy_s(m_str, customStringLength, buff);
		m_currentLength *= i;
		return *this;
	}

	template <typename T> MyString& operator += (const T& rhs)
	{
		MyString buff(rhs);
		strcat_s(m_str, customStringLength, buff.GetString());
		m_currentLength += buff.GetLength();
		return *this;
	}

	template <typename T> MyString operator + (const T& rhs)
	{
		MyString temp( GetString() );
		temp += rhs;
		return temp;
	}

	void Print()
	{
		printf("%s\n", m_str);
	}

private:
	const static size_t customStringLength = 80;
	size_t m_currentLength;  // '\0' not included
	char m_str[customStringLength];

};

class StringManager
{
	
};

int main()
{
	
	printf("Hello World\n");
	char line[200] = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; // 80 x 'a' + \0
	printf("%.80s", line);
	// array of strings
	char array[3][6] = { "abcde", "12345", "00000" };	//null terminated /0
	for (size_t i = 0; i < 3; i++)
	{
		printf("%s\n", array[i]);
	}
	char array1[][15] = { "La prima", "La seconda", "La terza" };	// Array possono avere n righe ma le colonne devono essere fissate
	char multiline[160] = "";
	size_t maxchar = 120;
	for (size_t i = 0; i < maxchar; i++)
	{ 
		strcat_s(multiline, maxchar + 1, "b");
	}
	printf("%s\n", multiline);				// Ripetizione di maxchar lettere
	strcpy_s(multiline, 160, "");			// Reset stringa
	strcat_s(multiline, 10, "resetline");	// Reset a nuovo valore
	printf("%s\n", multiline);
	
	const size_t strl = 80;
	char a[strl] = "primo ";
	char* b = "secondo\n";
	strcat_s(a, strl, b);
	printf(a);

	int vint[4] = { 2, 3, 5, 8 };	// Static initialization
	printf("%d, %d, %d, %d\n", vint[0], vint[1], vint[2], vint[3]);
	printf("%f\n", 25.14);
	MyString alfa("Provicchia");
	printf("%d\n", alfa.GetLength());
	alfa += 4;
	alfa.Print();

	printf("%d\n", alfa.GetLength());
	MyString beta(3.145);
	beta.Print();
	printf("%d\n", beta.GetLength());
	MyString delta = alfa + 14 + " Fatto";
	delta.Print();
	MyString gamma("a");
	gamma *= 10;
	gamma.Print();
	printf("%d\n", gamma.GetLength());
	gamma = "Acc";
	gamma.Print();
	printf("%d\n", gamma.GetLength());
	_getch();
	return 0;
}

