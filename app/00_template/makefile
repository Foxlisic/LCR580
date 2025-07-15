all:
	z80asm main.asm -o main.bin
	php ../../bin2mif.php 32 main.bin ../../c4/m32.mif
	../../lcr580 main.bin -d > main.log
