# TEsingle benchmarking scripts
Scripts used for benchmarking TE quantification of simulated single cell/nuclei reads

## Overview
This repository contains the code used to generate the benchmarking results for comparing various single-cell/nuclei TE quantification software.

The pipeline is dividied into four portions:
1. Generating index/reference databases for various software (genomic FASTA + gene & TE annotations -> software-specific reference database)
2. Running the quantification software (simulated FASTQ + software-specific reference database -> quantification output)
3. Calculating accuracy of quantification (quantification output + simulated "ground truth" -> accuracy metric (F1 score)
4. Generating figures in publication (accuracy metric -> figures)

Files required for this pipeline can be downloaded from [Zenodo]().

## Installation

### Dependencies
- Python >= v3.9 (tested on v3.12.3)
- [samtools](https://github.com/samtools/samtools) v1.20
- [bedtools](https://bedtools.readthedocs.io/en/latest/) >= v2.29.2 (tested on v.2.31.1)
- [STAR](https://anaconda.org/bioconda/star) v2.7.11b
- [JupyterLab](https://jupyter.org/) >= v4.3.4 (tested on v4.4.1)
- [R](https://www.r-project.org/) >= v4 (tested on v4.3.3) : [installation instructions](https://cran.r-project.org/doc/FAQ/R-FAQ.html#How-can-R-be-installed_003f)
- [Cell Ranger](https://www.10xgenomics.com/support/software/cell-ranger/downloads) v8.0.1 : [installation instructions](https://www.10xgenomics.com/support/software/cell-ranger/latest/tutorials/cr-tutorial-in#tutorial)
- [scTE](https://github.com/JiekaiLab/scTE) [April 2024 commit](https://github.com/JiekaiLab/scTE/tree/566f6ab3baaf76cd006ab965edc08e4576eb73c9) : [installation instructions](https://github.com/JiekaiLab/scTE/blob/master/README.md)
- [SoloTE](https://github.com/bvaldebenitom/SoloTE) [May 2024 commit](https://github.com/bvaldebenitom/SoloTE/tree/b90b144912358b405183e47eb566e1e90f657d9f) : [installation instructions](https://github.com/bvaldebenitom/SoloTE/blob/main/README.md)
- [TEsingle](https://github.com/mhammell-laboratory/TEsingle) v1.0 : [installation instructions](https://github.com/mhammell-laboratory/TEsingle/blob/main/README.rst)

A `conda` environment YAML file is provided in the repository that would install Python, bedtools, JupyterLab, samtools and STAR. Please follow these [instructions](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#creating-an-environment-from-an-environment-yml-file) to create a conda environment from the YAML file.

### Obtaining benchmarking pipeline code
```
$ git clone https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts.git
```

## How to use the pipeline

### Reference database generation
`STAR`, Cell Ranger and `scTE` requires generation of indices/reference databases prior to their use. The code is provided in the [index_generation](https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts/tree/main/index_generation) subfolder.

#### System requirements
- CPU: 10
- Memory: 7G per core (70G total)
- Allowed time: up to 12 hours

#### Generating STAR index
To generate the STAR index, you will need the `T2T_geneTE_forSTAR.gtf.gz` file in `index_generation_files.zip` from the [TEsingle benchmarking data repository](). You can then use the [T2T_STAR_index_generation.sh](https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts/blob/main/index_generation/T2T_STAR_index_generation.sh) script, either locally, or submitted to a SLURM cluster.
```
# If setting up for the first time
$ mkdir index_building
$ cd index_building
# Copying GTF from downloaded repository
$ mv /path/to/T2T_geneTE_forSTAR.gtf.gz .
$ gunzip T2T_geneTE_forSTAR.gtf.gz
# For running locally
$ sh /path/to/T2T_STAR_index_generation.sh T2T_STAR_index
# For submission to SLURM
$ sbatch /path/to/T2T_STAR_index_generation.sh T2T_STAR_index
```
The code will download the T2T (CHM v2) genome FASTA, and use the provided GTF to generate a STAR index in the specified output folder (`T2T_STAR_index`), which can then be used for benchmarking runs.

#### Generating Cell Ranger reference database
To generate the Cell Ranger custom reference database, you will need the `T2T_geneTE_forCellRangerTE.gtf.gz` file in `index_generation_files.zip` from the [TEsingle benchmarking data repository](). You can then use the [T2T_CellRangerTE_mkref.sh](https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts/blob/main/index_generation/T2T_CellRangerTE_mkref.sh) script, either locally or submitted to a SLURM cluster.
```
# If setting up for the first time
$ mkdir index_building
$ cd index_building
# Copying GTF from downloaded repository
$ mv /path/to/T2T_geneTE_forCellRangerTE.gtf.gz .
$ gunzip T2T_geneTE_forCellRangerTE.gtf.gz
# For running locally
$ sh /path/to/T2T_CellRangerTE_mkref.sh T2T_CellRangerTE_db
# For submission to SLURM
$ sbatch /path/to/T2T_CellRangerTE_mkref.sh T2T_CellRangerTE_db
```
The code will download the T2T (CHM v2) genome FASTA, and use the provided GTF to generate a CellRanger custom reference database in the specified output folder (`T2T_CellrangerTE_db`), which can be used for benchmarking CellRanger-TE.

#### Generating scTE no intron index
To generate the scTE index (nointron), you will need `T2T_gene_scTE.gtf.gz` and `T2T_TE_scTE.bed.gz` files in `index_generation_files.zip` from the [TEsingle benchmarking data repository](). You can then use the [T2T_scTE_build.sh](https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts/blob/main/index_generation/T2T_scTE_build.sh) script, either locally or submitted to a SLURM cluster.
```
# If setting up for the first time
$ mkdir index_building
$ cd index_building
# Copying files from downloaded repository
$ mv /path/to/T2T_gene_scTE.gtf.gz /path/to/T2T_TE_scTE.bed.gz .
$ gunzip T2T_gene_scTE.gtf.gz T2T_TE_scTE.bed.gz
# For running locally
$ sh /path/to/T2T_scTE_build.sh
# For submission to SLURM
$ sbatch /path/to/T2T_scTE_build.sh
```
The code will take the two annotation files (`T2T_gene_scTE.gtf.gz` and `T2T_TE_scTE.bed.gz`) and generate a scTE index (`T2T_scTE.nointron.idx`), which can be used for benchmarking scTE.

### Running software for benchmarking
To perform the benchmarking, you will need to obtain the simulated FASTQ in `simulated_fastq.zip` from the [TEsingle benchmarking data repository](). The code is provided in the [`software_running`](https://github.com/mhammell-laboratory/TEsingle_benchmarking_scripts/tree/main/software_running) subfolder

#### Running STARsolo-TE
You will need to obtain and gunzip `barcode_whitelist.txt.gz` in `run_files.zip` from the [TEsingle benchmarking data repository](), in addition to the simulated FASTQ.

##### System requirements
- CPU: 10
- Memory: 50G per core (500G total)
- Allowed time: up to 5 days

```
# For running locally
$ sh /path/to/T2T_STARsoloTE.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz
$ sh /path/to/T2T_STARsoloTE.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz
# For submitting to SLURM
$ sbatch /path/to/T2T_STARsoloTE.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz
$ sbatch /path/to/T2T_STARsoloTE.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz
```
This will generate output folders (`T2T_simulated_wholecell_STARsoloTE` and `T2T_simulated_singleNuclei_STARsoloTE`) containing the run outputs.

#### Running CellRanger-TE
You will need to ensure that the simulated FASTQ files (I1, R1 and R2) are all in the same folder when using this script.

##### System requirements
- CPU: 16
- Memory: 30G per core (480G total)
- Allowed time: up to 5 days

```
# For running locally
$ sh /path/to/T2T_STARsoloTE.sh /path/to/T2T_CellRangerTE_db /path/to/T2T_simulated_wholecell_R2.fastq.gz
$ sh /path/to/T2T_STARsoloTE.sh /path/to/T2T_CellRangerTE_db /path/to/T2T_simulated_singleNuclei_R2.fastq.gz
# For submitting to SLURM
$ sbatch /path/to/T2T_STARsoloTE.sh /path/to/T2T_CellRangerTE_db /path/to/T2T_simulated_wholecell_R2.fastq.gz
$ sbatch /path/to/T2T_STARsoloTE.sh /path/to/T2T_CellRangerTE_db /path/to/T2T_simulated_singleNuclei_R2.fastq.gz
```
This will generate output folders (`T2T_simulated_wholecell_CRTE` and `T2T_simulated_singleNuclei_CRTE`) containing the run outputs.

#### Running scTE
You will need to obtain and gunzip `barcode_whitelist.txt.gz` in `run_files.zip` from the [TEsingle benchmarking data repository](), in addition to the simulated FASTQ.

##### System requirements
- CPU: 10
- Memory: 50G per core (500G total)
- Allowed time: up to 5 days

```
# For running locally
$ sh /path/to/T2T_scTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/T2T_scTE.nointron.idx
$ sh /path/to/T2T_scTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/T2T_scTE.nointron.idx
# For submitting to SLURM
$ sbatch /path/to/T2T_scTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/T2T_scTE.nointron.idx
$ sbatch /path/to/T2T_scTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/T2T_scTE.nointron.idx
```
This will generate two output files (`T2T_simulated_wholecell_scTE_nointron.csv` and `T2T_simulated_singleNuclei_scTE_nointron.csv`) containing the run outputs.

#### Running SoloTE
You will need to obtain and gunzip `barcode_whitelist.txt.gz` and `T2T_TE_SoloTE.bed.gz` in `run_files.zip` from the [TEsingle benchmarking data repository](), in addition to the simulated FASTQ. You will also need the `SoloTE_pipeline.py` script, which should be provided when obtaining SoloTE.

##### System requirements
- CPU: 10
- Memory: 50G per core (500G total)
- Allowed time: up to 5 days

```
# For running locally
$ sh /path/to/T2T_SoloTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/SoloTE_pipeline.py /path/to/T2T_TE_soloTE.bed
$ sh /path/to/T2T_SoloTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/SoloTE_pipeline.py /path/to/T2T_TE_soloTE.bed
# For submitting to SLURM
$ sbatch /path/to/T2T_SoloTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/SoloTE_pipeline.py /path/to/T2T_TE_soloTE.bed
$ sbatch /path/to/T2T_SoloTE_run.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/SoloTE_pipeline.py /path/to/T2T_TE_soloTE.bed
```
This will generate a folder (`SoloTE_runs`), with the following folders (`T2T_simulated_wholecell_SoloTE_output` and `T2T_simulated_singleNuclei_SoloTE_output`) containing the run outputs.

#### Running TEsingle
You will need to obtain and gunzip `T2T_TEsingle_gene.gtf.gz` and `T2T_TEsingle_TE.gtf.gz` in `run_files.zip` from the [TEsingle benchmarking data repository](), in addition to the simulated FASTQ.

##### System requirements
- CPU: 10
- Memory: 50G per core (500G total)
- Allowed time: up to 5 days

```
$ sh /path/to/T2T_TEsingle.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/T2T_TEsingle_gene.gtf /path/to/T2T_TEsingle_TE.gtf
$ sh /path/to/T2T_TEsingle.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/T2T_TEsingle_gene.gtf /path/to/T2T_TEsingle_TE.gtf
# For submitting to SLURM
$ sbatch /path/to/T2T_TEsingle.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_wholecell_R1.fastq.gz /path/to/T2T_simulated_wholecell_R2.fastq.gz /path/to/T2T_TEsingle_gene.gtf /path/to/T2T_TEsingle_TE.gtf
$ sbatch /path/to/T2T_TEsingle.sh /path/to/T2T_STAR_index /path/to/barcode_whitelist.txt /path/to/T2T_simulated_singleNuclei_R1.fastq.gz /path/to/T2T_simulated_singleNuclei_R2.fastq.gz /path/to/T2T_TEsingle_gene.gtf /path/to/T2T_TEsingle_TE.gtf
```
This will generate 3 files each:
- `T2T_simulated_{wholecell,singleNuclei}_TEsingle.annots`: contains the list of features/annotations
- `T2T_simulated_{wholecell,singleNuclei}_TEsingle.cbcs`: contains the list of barcodes
- `T2T_simulated_{wholecell,singleNuclei}_TEsingle.mtx`: contains the counts in matrix format

