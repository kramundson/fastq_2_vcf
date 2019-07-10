#!/bin/bash
#
#SBATCH --job-name=4xSNP
#SBATCH -c 1 # Number of cores
#SBATCH -N 1 # Ensure that all cores are on one machine
#SBATCH --mem=1G # Memory pool for all cores in MB (see also --mem-per-cpu)
#SBATCH --time 5-00:00:00 # 5 day runtime
#SBATCH -p production # Partition to submit to
#SBATCH -o 2018_1107_snake.out # File to which STDOUT will be written
#SBATCH -e 2018_1107_snake.err # File to which STDERR will be written
#SBATCH --mail-type=ALL # Type of email notification- BEGIN,END,FAIL,ALL
#SBATCH --mail-user=kramundson@ucdavis.edu # Email to which notifications will be sent

date
hostname
aklog

WORKDIR="/share/comailab/kramundson/ximena/tetraploid_snps"
CONDA="ximena"

cd $WORKDIR
source activate $CONDA

snakemake -j 7 -s 1_init_files.snakes --cluster-config cluster.yaml --cluster "sbatch -p {cluster.partition} -n {cluster.n} -t {cluster.time} -c {cluster.c} --mem-per-cpu {cluster.mempercpu}" -k -w 120
snakemake -j 999 -s 2_fastq_to_vcf.snakes --cluster-config cluster.yaml --cluster "sbatch -p {cluster.partition} -n {cluster.n} -t {cluster.time} -c {cluster.c} --mem-per-cpu {cluster.mempercpu}" -k -w 120
# snakemake -j 999 -s 3_bam_to_vcf.snakes --rerun-incomplete --cluster-config cluster.yaml --cluster "sbatch -p {cluster.partition} -n {cluster.n} -t {cluster.time} -c {cluster.c} --mem-per-cpu {cluster.mempercpu}" -k -w 120

source deactivate

date
exit
