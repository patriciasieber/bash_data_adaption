#!/bin/sh

## stripts adapted from publication of prevorovski et al (2016)

path_to_species="/home/psieber/AlternativeSplicing/A_fumigatus/"

genome_fasta="/home/psieber/rnaseq_analysis/A_fumigatus/Aspergillus_fumigatusa1163.CADRE.31.dna.toplevel.fa"
genome_gtf="/home/psieber/rnaseq_analysis/A_fumigatus/Aspergillus_fumigatusa1163.CADRE.31.gtf"

file_comparisons="${path_to_species}/splicing_efficiency/comparisons.txt"

## take intron length from annotation stats
min_intron=10
max_intron=4000

############################################################
# extract transreads (spliced junction reads)
############################################################
# regtools 0.4.0 (https://regtools.readthedocs.io/en/latest/)

regtools_outdir=${path_to_species}/splicing_efficiency/transreads/
mkdir -p "${regtools_outdir}"

ls ${path_to_species}/*/bams/*merged.bam.sorted.bam > ${path_to_species}/splicing_efficiency/merged_bam_files.txt  ## edit if necessary
BAM_files=$(<${path_to_species}/splicing_efficiency/merged_bam_files.txt)
path_to_bams=(${BAM_files// / })

echo "check bam files:"
echo "${path_to_bams[@]}"
echo "____________________________"

annotated_suffix=".annotated"
for i in ${path_to_bams[@]};
do
	samtools index ${i}
	infile=$(echo ${i} | cut -d'/' -f 9)
	outfile="${regtools_outdir}${infile}.trans"
	echo "############################################"
	date
	echo "regtools processing file: ${infile}"
	echo "############################################"
	regtools junctions extract -i ${min_intron} -I ${max_intron} -o "${outfile}" "${i}"
	regtools junctions annotate -o "${outfile}${annotated_suffix}" "${outfile}" "${genome_fasta}" "${genome_gtf}"
	echo
done


############################################################
# compile transread counts and extract splice site coordinates
############################################################
# R 

Rscript --vanilla /home/psieber/bin/splicing_efficiency/junctions.R ${regtools_outdir} ${path_to_species}/splicing_efficiency


############################################################
# extract splice site (intron) coverage
############################################################
# bedtools v2.26.0
# Adjust the -S/-s "strandness" parameter according to your sequencing library preparation protocol.

ss_dir=${path_to_species}/splicing_efficiency/
ss5_file="introns_known_5ss.bed"
ss3_file="introns_known_3ss.bed"
counts_suffix=".counts"
bedtools_outdir=${path_to_species}/splicing_efficiency/introns/
mkdir "${bedtools_outdir}"
bedtools multicov -s -split -bed "${ss_dir}${ss5_file}" -bams ${BAM_files} > "${bedtools_outdir}${ss5_file}${counts_suffix}"
bedtools multicov -s -split -bed "${ss_dir}${ss3_file}" -bams ${BAM_files} > "${bedtools_outdir}${ss3_file}${counts_suffix}"

base=()
len_bams=${#path_to_bams[@]}
for ((i=0; i<$len_bams; i+=1));
do
	s="${path_to_bams[$i]}"
	base[$i]=${s##*/}
done
	
echo ${base[@]} > "${path_to_species}/splicing_efficiency/BAM_files"


############################################################
# calculate splicing efficiency and plot data
############################################################
# R

mkdir ${path_to_species}/splicing_efficiency/images/
mkdir ${path_to_species}/splicing_efficiency/efficiency/

##TODO define comparisons, include into script!!
Rscript --vanilla /home/psieber/bin/splicing_efficiency/efficiency.R ${path_to_species}/splicing_efficiency ${path_to_species}/splicing_efficiency/BAM_files ${file_comparisons}
