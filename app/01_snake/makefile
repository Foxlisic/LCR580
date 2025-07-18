all:
	z80asm -I../inc main.asm -o main.bin
	php ../../bin2mif.php 64 main.bin ../../c5/m64.mif
	../../lcr580 main.bin > main.log
