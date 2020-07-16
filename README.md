# Reconstruction of Ancestral HAplotype Map of Inbred Strains (AHAMIS)

Version 1.0 as of 15 July, 2020

## Overview

In the process of establishing inbred strains in laboratories, the chromosomes of ancestral animals recombined to form the genomes of the inbred strains.  We reconstructed the patchwork of ancestral haplotypes in current inbred strains by using the whole genome sequences.  Since the ancestral laboratory animals were taken from genetically diverse wild rats, any chromosomal segment differed at many variants between two ancestral chromosomes.  An ancestral haplotype of a chromosomal segment (AHS) that was transmitted to multiple inbred strains appears as a haplotype segment shared among the strains.  Consequently, the haplotypes of a chromosomal segment across current inbred strains comprise of one or several classes of distinct haplotypes.  One class of haplotypes are distinct from other haplotypes at many variants on the chromosomal segment, and the variants are in complete linkage disequilibrium.  Using this property inversely, we reconstructed AHSs by observing variants in linkage disequilibrium.  By enumerating all AHSs and computing their overlaps, we reconstructed the map of AHSs in the inbred strains.

## Software

* `ahamis.R`
  + Main program written in R language
* `data/`
  + Dataset for 13 Wistar Kyoto colony-derived rat strains (including SHR/Izm, SHRSP/Izm and WKY/Izm)
* `VCFgenotypecount.pl`
  + Perl program for preprocessing your own VCF file
* `VCFgenotypeextract.pl`
  + Perl program for preprocessing your own VCF file

## How to preprocess your own data

* `VCFgenotypecount.pl`
  + Perl program to generate the genotypecount file from a VCF file
  + `zgrep -v ^# WKYvariantsinclSHR13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.vcf.gz | VCFgenotypecount.pl > WKYvariantsinclSHR13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.genotypecount`
* `VCFgenotypeextract.pl`
  + Perl program to process a VCF file and extract the position of SNPs with a specific strain distribution pattern. The argument `0_0_0_0_0_0_0_0_0_0_0_0_1` specifies the pattern and the output file. Put the output file in `genotype/` directory.
  + `zgrep -v ^# WKYvariantsinclSHR13.minGQ10_minDP4.maskhetgenotype.max-missing-count0.vcf.gz | VCFgenotypeextract.pl 0_0_0_0_0_0_0_0_0_0_0_0_1`

