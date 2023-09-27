#!/bin/bash

# Define paths
VCF_DIR="/path/to/vcf_files"
FILTERED_DIR="/path/to/filtered_files"
CONVERTED_DIR="/path/to/converted_files"
EXTRACTED_DIR="/path/to/extracted_files"
SNPCHR_DIR="/path/to/snpchr_files"
GATK_PATH="/home/.../gatk-4.3.0.0/./gatk"
REF_GENOME="~/.../hg38/hg38.fa"
QUERY_OUTPUT="/path/to/Loreille_SNPs_Positions.tsv"

# bcftools filter SNPs DP
for i in "$VCF_DIR"/*.vcf.gz; do 
    bcftools filter "$i" -e 'FMT/DP<3 & FMT/GQ<30' -o "$FILTERED_DIR"/$(basename "$i").filtered
done

# GVCF_2_VCF_index
for i in "$FILTERED_DIR"/*.filtered; do 
    "$GATK_PATH" --java-options "-Xmx4g" GenotypeGVCFs -R "$REF_GENOME" -V "$i" -O "$CONVERTED_DIR"/$(basename "$i").converted.gz
    "$GATK_PATH" IndexFeatureFile -I "$CONVERTED_DIR"/$(basename "$i").converted.gz
done

# bgzip_index_vcf
for i in "$CONVERTED_DIR"/*.converted.gz; do 
    bgzip "$i"
    bcftools index "$CONVERTED_DIR"/$(basename "$i")
done

# bcftools_query_'%CHROM & %POS'
bcftools query -f '%CHROM %POS\n' "$QUERY_OUTPUT" 2>&1 | tee "$QUERY_OUTPUT"

# bcftools filter by Region
for i in "$CONVERTED_DIR"/*.converted.gz; do 
    bcftools view -R "$QUERY_OUTPUT" "$i" > "$EXTRACTED_DIR"/$(basename "$i").extracted
done

# Count number of variants per Chr and output to .txt file
for i in "$EXTRACTED_DIR"/*extracted; do 
    grep -v "^#" "$i" | cut -f 1 | sort | uniq -c > "$SNPCHR_DIR"/$(basename "$i").SNPchr
done

# Create the BED file with IDs
bcftools query -f '%CHROM\t%POS0\t%END\t%ID\n' panel.SNPs.vcf > panel.SNPs.vcf.ids.bed

# Annotate the file
for i in "$EXTRACTED_DIR"/*extracted; do 
    bcftools annotate -c CHROM,FROM,TO,ID -a panel.SNPs.vcf.ids.bed -o "${i%.extracted}.IDs.vcf" "$i"
done

# Example Loop using vcftools
# Define out path
OUT="/path/to/vcftools_output"
for i in "$VCF_DIR"/burn5_snps.vcf.gz; do
    vcftools --gzvcf "$i" --depth --out "$OUT"/$(basename "$i").individual.depth
    vcftools --gzvcf "$i" --site-mean-depth --out "$OUT"/$(basename "$i").site.depth
    vcftools --gzvcf "$i" --site-quality --out "$OUT"/$(basename "$i").quality
    vcftools --gzvcf "$i" --het --out "$OUT"/$(basename "$i").heterozygosity
    vcftools --gzvcf "$i" --missing-indv --out "$OUT"/$(basename "$i").individual.missing
    vcftools --gzvcf "$i" --missing-site --out "$OUT"/$(basename "$i").site.missing
    vcftools --gzvcf "$i" --relatedness --out "$OUT"/$(basename "$i").relatedness
done

