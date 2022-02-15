#!/bin/sh

## Developing a shell pipeline for decontaminating genomes. 

## Input fasta file containing scaffolded genome. 
scaffs=$1
genome_id=$2
 ## -p doesn't send an error if the directory exists

name=decontam.$genome_id
newdir=outputs.$scaffs
mkdir -p logs
logs=logs/$name.%A_%a.logs
walltime=2-0

mkdir $newdir
scaffList=`touch $newdir/contam_scaffs_$genome_id.txt`

## Ensure all the nucleotides in the input fasta are in upper case before the file goes through soft-masking with dustmasker. 
echo "Converting any lowercase bases to uppercase."
echo "tr a-z A-Z < $scaffs | \
    dustmasker -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta'"
tr a-z A-Z < $scaffs | \
    dustmasker -level 40 -out $newdir/masked_$scaffs -outfmt 'fasta'  

echo "Dustmasking complete - will begin to substitute all soft-masked bases for hardmasking."
echo "python3 sub_soft_hard_mask_pri_asm.py $newdir/masked_$scaffs $newdir/N_sub_masked_$scaffs "
## Substitute soft-masking (lowercase bases) for hard-masking ("N") with in-house py script. 
python3 sub_soft_hard_mask_pri_asm.py $newdir/masked_$scaffs $newdir/N_sub_masked_$scaffs

echo "Masking steps finished. Passing hard-masked scaffolds to Kraken2 for classification."
# echo "kraken2 --db standard_plus_db --conf 0.2 --threads 16 --classified-out $newdir/class_$scaffs --unclassified-out $newdir/unclass_$scaffs \
#  --use-names --output $newdir/classification_$scaffs $newdir/N_sub_masked_$scaffs > class_stats.txt"
# ## Run kraken2 on hard-masked scaffolds. 
# kraken2 --db standard_plus_db --conf 0.2 --threads 16 --classified-out $newdir/class_$scaffs --unclassified-out $newdir/unclass_$scaffs --use-names \
# --output $newdir/classification_$scaffs $newdir/N_sub_masked_$scaffs > class_stats.txt

name=kraken.$genome_id
cores=32
script=RELEASE_THE_KRAKEN3.sh
walltime=2-0

## I THINK THE --time=$walltime and/or the -t $walltime is interfering with submission of the kraken sbatch 
echo "sbatch -p vgl -c $cores --error=$logs --output=$logs $script $newdir $scaffs \n"
sbatch -p vgl -c $cores --error=$logs --output=$logs $script $newdir $scaffs | awk '{print $4}' > kraken_jid
#sbatch -p vgl -c $cores --time=$walltime -t $walltime --error=$log --output=$log \
    # $script $newdir $scaffs 

# jid1=`cat kraken_decontam_jid`

name=mitoBlast.$genome_id 
cores=32
script=submit_blast_mito_2.sh
# walltime=2-0
## also removed the --t $walltime for mito blast 

## removed the $scaffList output because it was giving me an ambiguous redirect paper 
echo "sbatch -J $name -p vgl -c $cores --error=$logs --output=$logs \
    $script $newdir/N_sub_masked_$scaffs $newdir/mito_blast_$scaffs $newdir/mito_blast_$scaffs.report"
sbatch -p vgl -c $cores --error=$logs --output=$logs \
    $script $newdir/N_sub_masked_$scaffs $newdir/mito_blast_$scaffs $newdir/mito_blast_$scaffs.report | awk '{print $4}' > mito_jid

jid1=`cat kraken_jid`
jid2=`cat mito_jid`

# ## Parsing the blast output included in the submit_blast_mito_2.sh script 
# jid2=`cat mito_decontam_jid` ## MAKE THEM JID FILES NOT JUST OUTPUTS 


# if [[ $jid1 || $jid2 ]]; then  
#         dependency="--dependency=afterok:$jid1, $jid2"

# fi

# if [[ -e kraken_decontam_jid || -e mito_decontam_jid ]]; then
# 	dependency=`cat kraken_decontam.jid`
# 	dependency=$dependency,`cat mito_decontam.jid`
#     dependency="afterok:$dependency"
# fi

script=clean_fasta.sh

echo "sbatch -p vgl --error=$logs --output=$logs --dependency=afterok:$jid1,$jid2 $script $scaffs $newdir/trimmed_$scaffs"
sbatch -p vgl --error=$logs --output=$logs --dependency=afterok:$jid1,$jid2 $script $scaffs $newdir/trimmed_$scaffs

grep -i 'scaffold' $newdir/mito_blast_$scaffs.report | awk '{print $2}' | awk 'NR!=1 {print}'| tee -a $scaffList
grep -i 'scaffold' $newdir/class_$scaffs | awk '{print $1}' | tee -a $scaffList


##Tried: 
## --time=$walltime $dependency
## the dependency format in the meryl script 
## with the -z flags, which aren't recognized 
## with dependency="--dependency=afterok:$dependency" instead of the -d flag 


# # ## Counting/printing number of unclassified scaffolds (not identified as contaminants).
# # grep '>' $newdir/unclass_$scaffs | wc -l 

# ## Print statements about classified v. unclassified - currently going to slurm. 
# ## Also need to print report about classification - how many, which scaffolds, their classification. 
# ## Output about the masking would be good too - give them all the outputs. You already have the masked_sCarCar2_scaff_content.py for examples. 











