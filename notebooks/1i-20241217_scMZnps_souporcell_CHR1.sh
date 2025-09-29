# Note: Had to copy all files to local directory (.) because the container could not find files elsewhere.
# Even symbolic links didn't work, likely due to the containerized environment.
# Ensure sufficient storage and permissions in the local directory.

# Step 1: Prepare files for MUT_single
# Copy the genome reference file to the local directory
cp /plus/scratch/users/valerie/sys/Danio_rerio_z11_CAAXRedCD4noprrg2/fasta/genome.fa .

# Copy the barcodes file for the MUT_single experiment
cp /plus/scratch/users/valerie/projects/20190602_NOSMutvsWT_IndividualLibs/MUT_single/outs/filtered_feature_bc_matrix/barcodes.tsv .

# Copy the BAM file and associated index files for the MUT_single experiment
cp /plus/scratch/users/valerie/projects/20190602_NOSMutvsWT_IndividualLibs/MUT_single/outs/possorted_genome_bam.bam* .

# Step 2: Subset BAM file to include only chromosome 1
# Use samtools to filter BAM file by chromosome 1 (-b for BAM output, -@10 for using 10 threads)
samtools view -@10 -b possorted_genome_bam.bam 1 > chromosome1.bam

# Step 3: Run Souporcell pipeline for MUT_single
# souporcell_pipeline.py: Main script of the Souporcell pipeline
# -i: Input BAM file (subsetted to chromosome 1)
# -b: Barcodes file for the cells
# -f: Genome reference FASTA file
# -t: Number of threads (10)
# -o: Output directory (MUT_single_chr1)
# -k: Number of clusters (2, expected for this analysis)
singularity exec /plus/scratch/@scratch_scott/projects/scmznos_valtor/project_results/souporcell/souporcell_latest.sif \
souporcell_pipeline.py \
-i chromosome1.bam \
-b barcodes.tsv \
-f genome.fa \
-t 10 \
-o MUT_single_chr1 \
-k 2

# Step 4: Prepare files for MUT_CD4
# Change to the output directory for Souporcell results
cd /plus/scratch/@scratch_scott/projects/scmznos_valtor/project_results/souporcell/

# Copy the genome reference file to the local directory
cp /plus/scratch/users/valerie/sys/Danio_rerio_z11_CAAXRedCD4noprrg2/fasta/genome.fa .

# Copy the barcodes file for the MUT_CD4 experiment (compressed)
cp /plus/scratch/users/valerie/projects/20190811_NOSMutvsWT_IndividualLibs/20190811_MUT_CD4/outs/filtered_feature_bc_matrix/barcodes.tsv.gz .

# Copy the BAM file for the MUT_CD4 experiment
cp /plus/scratch/users/valerie/projects/20190811_NOSMutvsWT_IndividualLibs/20190811_MUT_CD4/outs/possorted_genome_bam.bam .

# Step 5: Subset BAM file to include only chromosome 1
# Use samtools to filter BAM file by chromosome 1 (-b for BAM output, -@10 for using 10 threads)
samtools view -@10 -b possorted_genome_bam.bam 1 > chromosome1.bam

# Step 6: Run Souporcell pipeline for MUT_CD4
# souporcell_pipeline.py: Main script of the Souporcell pipeline
# -i: Input BAM file (subsetted to chromosome 1)
# -b: Barcodes file for the cells
# -f: Genome reference FASTA file
# -t: Number of threads (10)
# -o: Output directory (MUT_CD4_chr1)
# -k: Number of clusters (2, expected for this analysis)
singularity exec /plus/scratch/@scratch_scott/projects/scmznos_valtor/project_results/souporcell/souporcell_latest.sif \
souporcell_pipeline.py \
-i chromosome1.bam \
-b barcodes.tsv.gz \
-f genome.fa \
-t 10 \
-o MUT_CD4_chr1 \
-k 2
