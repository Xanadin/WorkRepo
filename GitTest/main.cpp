#include <stdio.h>
#include <conio.h>
#include <string.h>
#include <assert.h>

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

namespace FSB
{
	const unsigned int FILESTATUS_READ = 1 << 1;
	const unsigned int FILESTATUS_WRITE = 1 << 2;
	const unsigned int FILESTATUS_APPEND = 1 << 3;

	class File
	{
		friend class FileManager;
	public:
		virtual void Read(void* buffer, size_t elemSize, size_t count) = 0;
		virtual void Write(const wchar_t* format) = 0;
		virtual void Append(const wchar_t* format) = 0;
	protected:
		const static size_t maxPath = 260;
		char m_name[maxPath];
		unsigned int m_status;
	};

	class StdFile : public File
	{
	public:
		StdFile()
		{
			strcpy_s(m_name, maxPath, "");
			m_file = NULL;
		}

		~StdFile()
		{
			Reset();
		}

		void Reset()
		{
			if (m_file) fclose(m_file);
			m_file = NULL;
			strcpy_s(m_name, maxPath, "");
		}

		void Read(void* buffer, size_t elemSize, size_t count)
		{
			if ( m_status & (FILESTATUS_WRITE | FILESTATUS_APPEND) )
			{
				fclose(m_file);
				m_file = NULL;
				m_status &= ~(FILESTATUS_WRITE | FILESTATUS_APPEND);
			}
				
			if ( ! (m_status & FILESTATUS_READ) )
			{
				fopen_s(&m_file, m_name, "r");
				assert(m_file);
				m_status |= FILESTATUS_READ;
			}	
			size_t res = fread(buffer, elemSize, count, m_file);
			assert(res == count);
		}
		void Write(const wchar_t* format)
		{
			if (m_status & (FILESTATUS_READ | FILESTATUS_APPEND))
			{
				fclose(m_file);
				m_file = NULL;
				m_status &= ~(FILESTATUS_READ | FILESTATUS_APPEND);
			}

			if (!(m_status & FILESTATUS_WRITE))
			{
				fopen_s(&m_file, m_name, "w");
				assert(m_file);
				m_status |= FILESTATUS_WRITE;
			}
			fwprintf(m_file, format);
		}

		void Append(const wchar_t* format)
		{
			fopen_s(&m_file, m_name, "a");
			assert(m_file);
			fwprintf(m_file, format);
			fclose(m_file);
		}
	private:
		FILE* m_file;
	};

	class FileManager
	{
	public:
		typedef unsigned int FileHandle;

		FileManager() {}

		FileHandle GetFile(const char* name)
		{
			// Check if already used
			for (int i = 0; i < maxFileUsage; ++i)
			{
				if (strcmp(name, m_FileVec[i].file.m_name) == 0)
				{
					++(m_FileVec[i].refCount);
					return i;
				}
			}
			// Find free index
			for (int i = 0; i < maxFileUsage; ++i)
			{
				if (m_FileVec[i].free)
				{
					strcpy_s(m_FileVec[i].file.m_name, File::maxPath, name);
					return i;
				}		
			}
			// No free handle
			return -1;
		}
		void Read(FileHandle handle, void* buffer, size_t elemSize, size_t count)
		{
			m_FileVec[handle].file.Read(buffer, elemSize, count);
		}
		void Write(FileHandle handle, const wchar_t* format )
		{
			m_FileVec[handle].file.Write(format);
		}
		void Append(FileHandle handle, const wchar_t* format)
		{
			m_FileVec[handle].file.Append(format);
		}

		void Free(FileHandle handle)
		{
			m_FileVec[handle].refCount--;
			if (m_FileVec[handle].refCount == 0)
			{
				m_FileVec[handle].Reset();
			}
		}

	private:

		struct FileRecord
		{
			FileRecord() : file(), free(true), refCount(0) {}
			void Reset()
			{
				file.Reset();
				free = true;
			}
			StdFile file;
			bool free;
			unsigned int refCount;
		};
		const static size_t maxFileUsage = 10;
		FileRecord m_FileVec[maxFileUsage];
	};

}	// namespace FSB

// Assembly tests
extern "C" int CalcResult1_(int a, int b, int c);
extern "C" int CalcResult2_(int a, int b, int c, int* quo, int* rem);
extern "C" int CalcResult4_(int* y, const int* x, int n);

extern "C" int CalcSum_(int a, int b, int c);
extern "C" int IntegerMulDiv_(int a, int b, int* prod, int* quo, int* rem);
extern "C" void CalculateSums_(int a, int b, int c, int* s1, int* s2, int* s3);

void callIntegerMulDiv()
{
	printf("IntegerMulDiv\n");
	// IntegerMulDiv_
	int a = 21, b = 9;
	int prod = 0, quo = 0, rem = 0;
	int rc;

	rc = IntegerMulDiv_(a, b, &prod, &quo, &rem);
	printf(" Input1 - a:   %4d b:    %4d\n", a, b);
	printf("Output1 - rc:  %4d prod: %4d\n", rc, prod);
	printf("		  quo: %4d rem:	 %4d\n\n", quo, rem);

	a = -23;
	prod = quo = rem = 0;
	rc = IntegerMulDiv_(a, b, &prod, &quo, &rem);
	printf(" Input2 - a:   %4d b:    %4d\n", a, b);
	printf("Output2 - rc:  %4d prod: %4d\n", rc, prod);
	printf("		  quo: %4d rem:	 %4d\n\n", quo, rem);

	b = 0;
	prod = quo = rem = 0;
	rc = IntegerMulDiv_(a, b, &prod, &quo, &rem);
	printf(" Input3 - a:   %4d b:    %4d\n", a, b);
	printf("Output3 - rc:  %4d prod: %4d\n", rc, prod);
	printf("		  quo: %4d rem:	 %4d\n\n", quo, rem);
}

void callCalculateSums()
{
	printf("CalculateSums\n");
	int a = 3, b = 5, c = 8;
	int s1a, s2a, s3a;
	CalculateSums_(a, b, c, &s1a, &s2a, &s3a);
	// Compute the sums again so we can verify the results
	// of CalculateSums_().
	int s1b = a + b + c;
	int s2b = a * a + b * b + c * c;
	int s3b = a * a * a + b * b * b + c * c * c;

	printf("Input:  a:   %4d b:   %4d c:   %4d\n", a, b, c);
	printf("Output: s1a: %4d s2a: %4d s3a: %4d\n", s1a, s2a, s3a);
	printf("        s1b: %4d s2b: %4d s3b: %4d\n\n", s1b, s2b, s3b);
}

extern "C" int NumFibVals_;
extern "C" int MemoryAddressing_(int i, int* v1, int* v2, int* v3, int* v4);

void callMemoryAddressing()
{
	printf("MemoryAddressing\n");
	for (int i = -1; i < NumFibVals_ +1; i++)
	{
		int v1 = -1, v2 = -1, v3 = -1, v4 = -1;
		int rc = MemoryAddressing_(i, &v1, &v2, &v3, &v4);

		printf("i: %2d  rc: %2d - ", i, rc);
		printf("v1: %5d v2: %5d v3: %5d v4: %5d\n", v1, v2, v3, v4);
	}
	printf("\n");
}

extern "C" char GlChar = 10;
extern "C" short GlShort = 20;
extern "C" int GlInt = 30;
extern "C" long long GlLongLong = 0x00000000FFFFFFFE;

extern "C" void IntegerAddition_(char a, short b, int c, long long d);

void callIntegerAddition()
{
	printf("IntegerAddition\n");
	printf("Before GlChar:     %d\n", GlChar);
	printf("       GlShort:    %d\n", GlShort);
	printf("       GlInt:      %d\n", GlInt);
	printf("       GlLongLong: %lld\n", GlLongLong);
	printf("\n");

	IntegerAddition_(3, 5, -37, 11);

	printf("After GlChar:     %d\n", GlChar);
	printf("       GlShort:    %d\n", GlShort);
	printf("       GlInt:      %d\n", GlInt);
	printf("       GlLongLong: %lld\n", GlLongLong);
}

extern "C" int SignedMinA_(int a, int b, int c);
extern "C" int SignedMaxA_(int a, int b, int c);
extern "C" int SignedMinB_(int a, int b, int c);
extern "C" int SignedMaxB_(int a, int b, int c);

void callConditionCodes()
{
	printf("ConditionCodes\n");

	int a, b, c;
	int smin_a, smax_a;
	int smin_b, smax_b;

	// SignedMin examples
	a = 2; b = 15; c = 8;
	smin_a = SignedMinA_(a, b, c);
	smin_b = SignedMinB_(a, b, c);
	printf("SignedMinA(%4d, %4d, %4d) = %4d\n", a, b, c, smin_a);
	printf("SignedMinB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smin_b);

	a = -3; b = -22; c = 28;
	smin_a = SignedMinA_(a, b, c);
	smin_b = SignedMinB_(a, b, c);
	printf("SignedMinA(%4d, %4d, %4d) = %4d\n", a, b, c, smin_a);
	printf("SignedMinB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smin_b);

	a = 17; b = 37; c = -11;
	smin_a = SignedMinA_(a, b, c);
	smin_b = SignedMinB_(a, b, c);
	printf("SignedMinA(%4d, %4d, %4d) = %4d\n", a, b, c, smin_a);
	printf("SignedMinB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smin_b);

	// SignedMax examples
	a = 10; b = 5; c = 3;
	smax_a = SignedMaxA_(a, b, c);
	smax_b = SignedMaxB_(a, b, c);
	printf("SignedMaxA(%4d, %4d, %4d) = %4d\n", a, b, c, smax_a);
	printf("SignedMaxB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smax_b);

	a = -3; b = 28; c = 15;
	smax_a = SignedMaxA_(a, b, c);
	smax_b = SignedMaxB_(a, b, c);
	printf("SignedMaxA(%4d, %4d, %4d) = %4d\n", a, b, c, smax_a);
	printf("SignedMaxB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smax_b);

	a = -25; b = -37; c = -17;
	smax_a = SignedMaxA_(a, b, c);
	smax_b = SignedMaxB_(a, b, c);
	printf("SignedMaxA(%4d, %4d, %4d) = %4d\n", a, b, c, smax_a);
	printf("SignedMaxB(%4d, %4d, %4d) = %4d\n\n", a, b, c, smax_b);
}

void callCalcResult4()
{
	printf("CalcResult4\n");

	const int n = 8;
	const int x[n] = { 3, 2, 5, 7, 8, 13, 20, 25 };
	int y[n];

	CalcResult4_(y, x, n);

#ifdef _WIN64
	const char* sp = "x64";
#else
	const char* sp = "Win32";
#endif

	printf("Results for solution platform %s\n\n", sp);
	printf("    x     y\n");
	printf("------------\n");

	for (int i = 0; i < n; i++) printf("%6d %6d\n", x[i], y[i]);
}

int main()
{
	
	printf("Hello World\n");

// Assembly functions
	int a1 = 30;
	int b1 = 20;
	int c1 = 10;
	int d1 = CalcResult1_(a1, b1, c1);
	printf("a: %4d b: %4d c: %4d\n", a1, b1, c1);
	printf("d: %4d\n", d1);

	int a2 = 75;
	int b2 = 125;
	int c2 = 7;
	int quo, rem;
	CalcResult2_(a2, b2, c2, &quo, &rem);
	printf("a: %4d b: %4d c: %4d\n", a2, b2, c2);
	printf("quo: %4d rem: %4d\n", quo, rem);

	int a21 = 17, b21 = 11, c21 = 14;
	int sum = CalcSum_(a21, b21, c21);
	printf(" a: %d\n", a21);
	printf(" b: %d\n", b21);
	printf(" c: %d\n", c21);
	printf(" sum: %d\n\n", sum);

	callIntegerMulDiv();
	callCalculateSums();
	callMemoryAddressing();
	callIntegerAddition();
	callConditionCodes();
	callCalcResult4();

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

