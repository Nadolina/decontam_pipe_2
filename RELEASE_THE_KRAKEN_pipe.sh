#!/bin/sh

## Developing a shell pipeline for decontaminating genomes. 

## Input fasta file containing scaffolded genome. 
scaffs=$1
genome_id=$2

mkdir -p logs ## -p doesn't send an error if the directory exists

name=decontam.$genome_id
newdir=outputs.$scaffs
logs=logs/$name.%A_%a.logs
walltime=2-0

mkdir $newdir
scaffList=`touch $newdir/contam_scaffs.txt`

## Ensure all the nucleotides in the input fasta are in upper case before the file goes through soft-masking with dustmasker. 
echo "Converting any lowercase bases to uppercase."
echo "awk '{print toupper($0)}' $scaffs | \
    dustmasker -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta' \n"
awk '{print toupper($0)}' $scaffs | \
    dustmasker -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta' 

echo "Dustmasking complete - will begin to substitute all soft-masked bases for hardmasking."
echo "python3 sub_soft_hard_mask_pri_asm.py $newdir/masked_$scaffs $newdir/N_sub_masked_$scaffs \n"
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
walltime=2-0

sbatch -J $name -p vgl -c $cores --time=$walltime -t $walltime --error=$log --output=$log \
    $script $newdir $scaffs 

jid=`head class_$scaffs`
if [ -z $jid ]; then 
        dependency=""
else 
        dependency="--dependency=afterok:$jid"
fi

name=mitoBlast.$genome_id 
cores=32
script=submit_blast_mito_2.sh
walltime=2-0

sbatch -J $name -p vgl -c $cores --time=$walltime --error=$log --output=$log \
    $script $newdir/N_sub_masked_$scaffs $newdir/mito_blast_$scaffs

## Parsing the blast output included in the submit_blast_mito_2.sh script 


# jid2=`head `

## SO I NEED THREE JIDS IN TOTAL? 

## mito jid, trim-Ns jid 
## steps in mito:
## run N_subbed_masked_scaffs against mito db 
## parse the mito output - creates DB and append scaffold names to 

# # ## Counting/printing number of unclassified scaffolds (not identified as contaminants).
# # grep '>' $newdir/unclass_$scaffs | wc -l 

# ## Print statements about classified v. unclassified - currently going to slurm. 
# ## Also need to print report about classification - how many, which scaffolds, their classification. 
# ## Output about the masking would be good too - give them all the outputs. You already have the masked_sCarCar2_scaff_content.py for examples. 











