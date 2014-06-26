Debug: bldr.s okldr.s kernel.s
	H:\Utilities\NASM\nasm -f bin bldr.s -o ..\Binary\bldr.bin
	H:\Utilities\NASM\nasm -f bin okldr.s -o ..\Binary\okldr.sys
	H:\Utilities\NASM\nasm -f bin kernel.s -o ..\Binary\kernel.sys
	H:\ouroborOS\Source\dd H:\ouroborOS\Binary\bldr.bin a:
	copy ..\Binary\okldr.sys a:
	copy ..\Binary\kernel.sys a:
	"c:\Program Files\Bochs-2.6.2\bochs.exe" -f ..\bochsrc.bxrc -q
