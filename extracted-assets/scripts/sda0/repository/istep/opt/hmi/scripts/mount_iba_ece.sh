#!/bin/ksh
case  ${HMI_BRAND} in
  
  01)
  mount -t udf /mnt/data/iba.mcv/text-ece/iba_text.iso /mnt/data/iba.mcv/swe1  
  /bin/inflator  /mnt/data/iba.mcv/swe1
  ln -sP /mnt/data/iba.mcv /mnt/data/iba
  ;;
  02)
  mount -t udf /mnt/data/iba.mini/text-ece/iba_text.iso /mnt/data/iba.mini/swe1
  /bin/inflator  /mnt/data/iba.mini/swe1
  ln -sP /mnt/data/iba.mini /mnt/data/iba
  ;;
  
  03)
  mount -t udf /mnt/data/iba.rr/text-ece/iba_text.iso /mnt/data/iba.rr/swe1  
  /bin/inflator  /mnt/data/iba.rr/swe1
  ln -sP /mnt/data/iba.rr /mnt/data/iba
  ;;
  *)
  mount -t udf /mnt/data/iba.bmw/text-ece/iba_text.iso /mnt/data/iba.bmw/swe1
  /bin/inflator  /mnt/data/iba.bmw/swe1
  ln -sP /mnt/data/iba.bmw /mnt/data/iba
  ;;
esac   
