#!/bin/sh

newdir=$1 
scaffs=$2

kraken2 --db standard_plus_db --conf 0.2 --threads 16 \
	--classified-out $newdir/class_$scaffs --unclassified-out $newdir/unclass_$scaffs --use-names \
	--output $newdir/classification_$scaffs $newdir/N_sub_masked_$scaffs 
