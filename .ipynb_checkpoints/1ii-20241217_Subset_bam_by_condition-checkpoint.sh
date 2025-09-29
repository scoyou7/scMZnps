# Create bam files per condition for generating alignment plot of condition specific SNPs (note inputs list of barcodes in txt files per cluster in the format 'CB:Z:AAACGAACATCGCTGG-1')

# Step 1: Define samples to process
# Two samples are being processed: MUT_CD4_chr1 and MUT_single_chr1
samples=( MUT_CD4_chr1 MUT_single_chr1 )

# Step 2: Loop over samples
for sample in "${samples[@]}"; do	

    # Step 3: Define conditions for filtering
    # Each sample is split into WT and KO clusters
    conditions=( WT KO )
    for condition in "${conditions[@]}"; do	
        # Define output directory and input BAM file
        outdir='/plus/scratch/@scratch_scott/projects/scmznos_valtor/project_results/souporcell/'$sample
        BAM_FILE=$outdir/'souporcell_minimap_tagged_sorted.bam'
        
        # Define the list of barcodes for this condition
        barcodes=$outdir/$condition'_barcodes_'$sample'.txt'
        
        # Extract the SAM header (contains metadata and reference information)
        samtools view -H $BAM_FILE > $outdir/$condition'_'$sample'_SAM_header'
        
        # Filter BAM alignments using the condition-specific barcode list
        # `LC_ALL=C` ensures compatibility with non-UTF-8 locales
        # `grep -F -f` performs a fixed-string match using the barcode list
        samtools view $BAM_FILE | LC_ALL=C grep -F -f $barcodes > $outdir/$condition'_'$sample'_SAM_body'
        
        # Combine the header and filtered alignments to create a new SAM file
        cat $outdir/$condition'_'$sample'_SAM_header' $outdir/$condition'_'$sample'_SAM_body' > $outdir/$condition'_'$sample'_filtered.sam'
        
        # Convert the SAM file to BAM format
        samtools view -b $outdir/$condition'_'$sample'_filtered.sam' > $outdir/$condition'_'$sample'_filtered.bam'
        
        # Clean up intermediate files to save disk space
        rm -fr $outdir/$condition'_'$sample'_filtered.sam'
        rm -fr $outdir/$condition'_'$sample'_SAM_body'
        rm -fr $outdir/$condition'_'$sample'_SAM_header'

    done

done

# Step 4: Merge condition-specific BAM files across samples
for condition in "${conditions[@]}"; do	
    # Define the output directory
    outdir='/plus/scratch/@scratch_scott/projects/scmznos_valtor/project_results/souporcell'

    # Merge BAM files for the same condition (e.g., WT or KO) from different samples
    samtools merge $outdir/$condition'_combined_chr1_filtered.bam' \
        $outdir/'MUT_CD4_chr1/'$condition'_MUT_CD4_chr1_filtered.bam' \
        $outdir/'MUT_single_chr1/'$condition'_MUT_single_chr1_filtered.bam'
    
    # Sort the merged BAM file for efficient indexing and querying
    samtools sort $outdir/$condition'_combined_chr1_filtered.bam' > $outdir/$condition'_combined_chr1_filtered_sorted.bam'
    
    # Index the sorted BAM file to allow rapid access to specific genomic regions
    samtools index $outdir/$condition'_combined_chr1_filtered_sorted.bam'
done

# Step 5: Create symbolic links for public access via IGV
# Links point to `/home/scott/public` for easy sharing
for condition in "${conditions[@]}"; do	
    ln -s $outdir/$condition'_combined_chr1_filtered_sorted.bam' '/home/scott/public/'$condition'_combined_chr1_filtered_sorted.bam'
    ln -s $outdir/$condition'_combined_chr1_filtered_sorted.bam.bai' '/home/scott/public/'$condition'_combined_chr1_filtered_sorted.bam.bai'
done
