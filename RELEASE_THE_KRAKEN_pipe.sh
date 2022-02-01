#!/bin/sh

## Developing a shell pipeline for decontaminating genomes. 

## Input fasta file containing scaffolded genome. 
scaffs=$1
genome_id=$2

mkdir -p logs ## -p doesn't send an error if the directory exists

name=decontam.$genome_id
newdir=outputs.$genome_id
logs=logs/$name.%A_%a.logs

echo "Starting to convert any lowercase bases to uppercase."
echo "tr [:lower:] [:upper:] < $scaffs | \
    dustmasker -parse_seqids -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta'"
## Ensure all the nucleotides in the input fasta are in upper case before the file goes through soft-masking with dustmasker. 
tr [:lower:] [:upper:] < $scaffs | \
    dustmasker -parse_seqids -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta'

echo "Dustmasking complete - will begin to substitute all soft-masked bases for hardmasking."
echo "python3 sub_soft_hard_mask_pri_asm.py $newdir/masked_$scaffs $newdir/N_sub_masked_$scaffs"
## Substitute soft-masking (lowercase bases) for hard-masking ("N") with in-house py script. 
python3 sub_soft_hard_mask_pri_asm.py $newdir/masked_$scaffs $newdir/N_sub_masked_$scaffs

echo "Masking steps finished. Passing hard-masked scaffolds to Kraken2 for classification."
# echo "kraken2 --db standard_plus_db --conf 0.2 --threads 16 --classified-out $newdir/class_$scaffs --unclassified-out $newdir/unclass_$scaffs \
#  --use-names --output $newdir/classification_$scaffs $newdir/N_sub_masked_$scaffs > class_stats.txt"
# ## Run kraken2 on hard-masked scaffolds. 
# kraken2 --db standard_plus_db --conf 0.2 --threads 16 --classified-out $newdir/class_$scaffs --unclassified-out $newdir/unclass_$scaffs --use-names \
# --output $newdir/classification_$scaffs $newdir/N_sub_masked_$scaffs > class_stats.txt

name=kraken.$genome_id
cores=16
script=RELEASE_THE_KRAKEN3.sh

sbatch -J $name -p vgl -c $cores --time=$walltime -t $walltime --error=$log --output=$log \
    $script $newdir $scaffs

# ## Counting/printing number of unclassified scaffolds (not identified as contaminants).
# grep '>' $newdir/unclass_$scaffs | wc -l 

## Print statements about classified v. unclassified - currently going to slurm. 
## Also need to print report about classification - how many, which scaffolds, their classification. 
## Output about the masking would be good too - give them all the outputs. You already have the masked_sCarCar2_scaff_content.py for examples. 











