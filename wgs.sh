#!/bin/bash

mkdir $1/../resultats_paired_to_paired

#Dé-zippage des fichiers d'intérêt.
#gunzip $1/*.gz

#annotation des reads
$1/../soft/bowtie2-build $1/../databases/all_genome.fasta $1/../databases/indexion

#paired end-to-end
$1/../soft/bowtie2 --very-fast --end-to-end -x $1/../databases/all_genome.fasta -1 $1/*_R1.fastq -2 $1/*_R2.fastq -S $1/../resultats_paired_to_paired/paired.sam

#Convertion SAM en BAM
samtools view -h -1 $1/../resultats_paired_to_paired/paired.sam -o $1/../resultats_paired_to_paired/paired.bam

#Trie et indexion
samtools sort $1/../resultats_paired_to_paired/paired.bam -o $1/../resultats_paired_to_paired/trie.bam

samtools index $1/../resultats_paired_to_paired/trie.bam

#Extraction du comptage
samtools idxstats $1/../resultats_paired_to_paired/trie.bam > $1/../resultats_paired_to_paired/stats.tsv

grep ">" $1/../databases/all_genome.fasta|cut -f 2 -d ">" >$1/../resultats_paired_to_paired/association.tsv

#Assemblage génome
$1/../soft/megahit -1 $1/*_R1.fastq -2 $1/*_R2.fastq --k-list 21 --mem-flag 0 -o $1/../resultats_paired_to_paired/assemblage

#Prédictions
$1/../soft/prodigal -i $1/../resultats_paired_to_paired/assemblage/final.contigs.fa -d $1/../resultats_paired_to_paired/assemblage/genes.fna

#sed "s:>:*\n>:g" $1/../resultats_paired_to_paired/assemblage/genes.fna | sed -n "/partial=00/,/*/p"|grep -v "*" > $1/../resultats_paired_to_paired/assemblage/genes_full.fna

#Blast
$1/../soft/blastn -query $1/../resultats_paired_to_paired/assemblage/genes_full.fna -db $1/../databases/resfinder.fna -perc_identity 0.8 -qcov_hsp_perc 0.8 -evalue 1E-3 -out $1/../Resultats_BLASTn.txt -outfmt "6 qseqid pident qcovs ppos evalue bitscore" -best_hit_score_edge 1E-5
sed -i '1iqseqid\tpident\tqcovs\tppos\tevalue\tbitscore' $1/../Resultats_BLASTn.txt
