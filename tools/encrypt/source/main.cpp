#include "ResourceEncrypt.h"
#include <cstring>

int main(int argc, char* argv[])
{
	if (argc < 4)
	{
		printf("ʹ��˵��: (E|D) ������Կ�ַ���  ���ܱ���ַ���   �ļ�·��\n");
		printf("          E ���� D ����");
		return 0;
	}

	bool isEncrpt = false;
	char* key = NULL;
	int keyLen = 0;
	char* sign = NULL;
	int signLen = 0;
	char* filepath = NULL;

	isEncrpt = strcmp(argv[1], "E") == 0;
	key = argv[2];
	sign = argv[3];
	filepath = argv[4];

	ResourceEncrypt  encrypt;
	encrypt.setEncrypt(key, strlen(key), sign, strlen(sign));
	
	if (isEncrpt)
		encrypt.checkEncryptFile(filepath);
	else
		encrypt.checkDecryptFile(filepath);
}