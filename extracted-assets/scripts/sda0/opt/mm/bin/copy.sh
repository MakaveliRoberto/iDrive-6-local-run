#!/bin/ksh
CONSOLE=/dev/console

echo "[DBC-Marker] Ent DB copy Begin" > $CONSOLE
# Print the size of the backup MME DB
ls -l /mnt/quota/mm/backup/mme > $CONSOLE

# Simple quick copy of the file with DMA enabled. Typical measured transfer rates 
# from HDD to RAM is >10 MB/s
qkcp -vvv -V -W -m /ram/dma /mnt/quota/mm/backup/mme /ramdisk/mm/ > $CONSOLE

# Print the size of the copied MME DB, just to see for debugging purposes.
ls -l /ramdisk/mm/mme > $CONSOLE

echo "[DBC-Marker] Ent DB copy Done" > $CONSOLE

# EOS

