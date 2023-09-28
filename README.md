# Supplemental files
This repository contains supplemental files for the paper
_Targeted Enrichment of Whole-Genome SNPs from Highly Burned Skeletal Remains_

`extract.SNPs.sh` - Bash pipeline for processing and analyzing VCF files derived from whole-genome SNP data. The code performs filtering based on depth and quality metrics, converting GVCFs to VCFs, extracting specific regions of interest, counting variants per chromosome, and adding annotations. 
The code requires the following tools: 
* bcftools
* GATK
* bgzip
* vcftools
