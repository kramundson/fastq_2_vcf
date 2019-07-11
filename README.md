# Cohort genotyping from DNAseq short read data

All information obtained and or inferred with this software is without any implied
warranty of fitness for any purpose or use whatsoever.

Use at your own risk. I cannot provide support.

Know that everybody has written some version of this pipeline. Here's mine.
I'm working on a similar workflow that will use Snakemake to scatter/gather GATK4 HaplotypeCaller.

## Summary

This Snakemake workflow takes in paired end short reads (fastq format), and produces a
file of raw SNP, indel, and short haplotypes in VCF format. 

Note, raw variants should not be the final product of your analysis. 
You can and should apply post-hoc quality filters to raw variants according to your needs.

## Steps

1. Build DM1-3 v4.04 reference genome, including DM1-3 chloroplast and mitochondrion sequences
2. Download reads from NCBI SRA (sra-tools 2.8.2)
3. Read trim (cutadapt 1.15)
4. Alignment to reference (bwa mem 0.7.12-r1039)
5. Remove PCR duplicates (Picard 2.18.27-0)
6. Filter out pairs w/mates on different chromosomes
7. Soft clip one mate of an overlapping mate pair (bamUtil 1.0.14)
8. Merge reads by biological sample (samtools 1.9)
9. Define indel realign targets (GATK 3.8 RealignerTargetCreator)
10. Realign indels (GATK 3.8 IndelRealigner)
11. Call variants (freebayes 1.2)

## Software installation

1. Clone this repository

```
git clone https://github.com/kramundson/fastq_2_vcf
```

2. Install miniconda3

```
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# review license
# accept license
# accept or change home location
# yes to placing it in your path

source $HOME/.bashrc
```

3. Install dependencies using included file ```environment.yaml```

```
# TODO: include gatk into environment
# conda install -c bioconda gatk # then this becomes unnecessary

conda env create --name fastq2vcf -f environment.yaml
# follow prompts to finish environment build

# activate environment
source activate fastq2vcf
```

4. Install GATK 3.8

On its own, the conda recipe of GATK3 will not let you run GATK3. 
Per conda instructions, you must download a licensed version of GATK from the Broad
Institute to run gatk with conda.

For this workflow, download GATK 3.8-1-0gf15c1c3ef from
https://software.broadinstitute.org/gatk/download/archive to this folder.

Then, copy gatk3 to your conda folder:

```
# to add gatk executable to path via conda
gatk3-register GenomeAnalysisTK-3.8-1-0-gf15c1c3ef.tar.bz2
```

## Test case

Here, I've specified the workflow to run on a few samples that are publicly available in
NCBI SRA. To keep run time low, we'll only use a very small subset of reads from each
sample. I've included subsets in this repo, under the subdirectory ```data/reads```

Each sample is WGS of a different potato cultivar. To illustrate how different sequencing
libraries from the same cultivars are handled, multiple libraries of cultivars Atlantic
and Superior are included here.

```
snakemake -s 1_init_files.snakes --cores 8 > test_init.out 2> test_init.err
snakemake -s 2_fastq_to_vcf.snakes --cores 8 > test_fq2vcf.out 2> test_fq2vcf.err
```

## How to run with your own datasets

Here, we'll walk through an example of how to add new samples. In this case, we're going
to add more reads from NCBI SRA: SRR2069932, which is reference genotype DM1-3.

```
# make a backup copy of units.tsv just in case
cp units.tsv units.tsv.bak

# add sample info for DM1-3
printf "2x_DM1_3\tSRR2069932\SRR2069932_1.fastq.gz\tSRR2069932_2.fastq.gz\tmother\n' >> units.tsv
```

We also need to add the per-sample ploidy to the file ```freebayes-cnv-map.bed```.
Here, I made a backup of the current CNV map, substituted the sample name, and
appended the modified block to the existing CNV map.

```
# make a backup copy of freebayes-cnv-map.bed just in case
cp freebayes-cnv-map.bed freebayes-cnv-map.bed.bak

# Get rows of a diploid sample, subsitute sample name IVP101 by DM1_3 and append to file
head -n 14 freebayes-cnv-map.bed.bak | sed -e 's/IVP101/DM1_3/g' >> freebayes-cnv-map.bed
```

Then, rerun the test workflow:

```
snakemake -s 2_fastq_to_vcf.snakes --cores 8 > test2_fq2vcf.out 2> test2_fq2vcf.err
```

The workflow should run without errors and produce the final output file ```data/calls/all-calls.vcf```

To add your own reads that aren't on SRA, put the raw reads (uninterleaved fastq) in the
folder ```data/reads/```, add your sample to ```freebayes-cnv-map.bed``` and  fill out a
new row in ```units.tsv``` for each set of paired end reads.
The columns should be filled out as follows:

 * sample: the biological sample (will be merged with other reads originating from the same biological sample)
 * unit: unique combination of biological sample, sequencing library, flow cell, and lane. Each set of paired end reads should have a unique identifier.
 * fq1: name of forward reads file
 * fq2: name of reverse reads file

## Other notes

## TODO
 * make a more realistic test case.
 * Workflow for GATK4 HaplotypeCaller
