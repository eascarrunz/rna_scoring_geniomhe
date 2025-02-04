---
title: Project: Objective function for the RNA folding problem
author: Eduardo Ascarrunz
date: 2025-01-29
---
# Project: Objective function for the RNA folding problem

This repository contains scripts for computing scores for RNA conformation models based on pseudo Gibb's free energy profiles from empirical data.

## Usage and implementation

### 1. Downloading native sequence data

The "fetch_native.jl" script reads a list of RNA record handles and fetches them from the PDB data base. By default, it uses the lsit in the file "native_list.txt" and saves the pdb files into the directory "data/native".

Usage:

```bash
> julia -t 4 src/fetch_native.jl
```

The script automatically unzips the compressed files with *gunzip*. The option `-t` is used to indicate Julia how many threads to use to unzip files in parallel.

### 2. Computing profiles

Usage:

```bash
> julia src/calibrate.jl
```

The "calibrate.jl" script reads pdb files from "data/native" to compute free energy profiles of nucleotide-nucleotide interaction distances. The follows these specifications:

- Only consider distances from C3' atoms.

- Only consider distances between atoms in the same chain.

- Only consider nucleotides separated by at least 3 positions in the sequence (parameter `k` in the code).

- Observed distances are binned into 1 Å intervals between 0.0 Å and 20.0 Å.

- Compute distance histograms for each nucleotide type pairing (AA, AU, AC, and so on), as well as any-against-any (NN).

The pseudo-free energy score of a nucleotide pairing associated to each distance bin is computed with the formula

$$
-log\left(\dfrac{f_{pair}}{f_{all}}\right)
$$

Where $f_{pair}$ is the nucleotide pairing frequency of the bin and $f_{all}$ is the frequency of the bin across all nucleotide pairings.

I completely skip sequences containing nucleotide symbols other than A, C, G, and U, as the presence of other nucleotide types (e.g. GDP, ADP) can alter the interactions between neighbouring nucleotides in ways not considered by the models of interest. Moreover, those other nucleotides are too rare in the dataset to provide useful information.

The script will write out the resuts to the "output" directory. The bin counts of each nucleotide pairing are stored in a file called "counts_**PAIR**.txt". The free energy scores are likewise stored in a file called "interaction_profile_**PAIR**.txt". A file for the interaction profile of all the nucleotide pairings is also saved ( "interaction_profile_**NN**.txt"). Obviously, it contains no informative scores, but it can be useful as a sanity check for detecting numerical in the other files.


### 3. Plotting histograms and profiles

Usage:

```bash
> julia src/plot_profiles.jl
```

This script reads the output from the previous script (saved to "output"), and plots histograms ("counts_**PAIR**.svg") and interaction profile curves ("interaction_profile_**PAIR**.svg"), also saved to "output". A useless "interaction_profile_**NN**.svg" is also generated.

### 4. Using profiles in a scoring function

Usage:

```bash
> julia src/evaluate.jl <FILE LIST>
```

This scripts loads the interaction profiles computed with "calibrate.j" and uses them to compute free energy scores for RNA conformations from a list of pdb files. Scores are computed by linear interpolation of the binned interaction profiles. File names and sequence lengths are printed as well.

The directory "data/puzzles" contains two example data sets from RNA Puzzles. Here is an example of the use of "evaluate.jl" with one of the puzzles:

```bash
> julia src/evaluate.jl data/puzzles/pz1/*
File    Length  Score
data/puzzles/pz1/PZ1_Bujnicki_1.pdb     23      0.04530542191467946
data/puzzles/pz1/PZ1_Bujnicki_2.pdb     23      -0.03198109060300976
data/puzzles/pz1/PZ1_Bujnicki_3.pdb     23      -0.18870770584730984
data/puzzles/pz1/PZ1_Bujnicki_4.pdb     23      -0.0331728854768607
data/puzzles/pz1/PZ1_Bujnicki_5.pdb     23      -0.14594264395224799
data/puzzles/pz1/PZ1_Chen_1.pdb 46      2.607464431739462
data/puzzles/pz1/PZ1_Das_1.pdb  46      -0.9325755247333203
data/puzzles/pz1/PZ1_Das_2.pdb  46      -2.0405159251082687
data/puzzles/pz1/PZ1_Das_3.pdb  46      -1.6897314706723965
data/puzzles/pz1/PZ1_Das_4.pdb  46      -1.4306127938168713
data/puzzles/pz1/PZ1_Das_5.pdb  46      -3.3030584811800106
data/puzzles/pz1/PZ1_Dokholyan_1.pdb    23      -0.06079333615230492
data/puzzles/pz1/PZ1_Major_1.pdb        46      -4.0976790919335
data/puzzles/pz1/PZ1_Santalucia_1.pdb   46      -0.8964129015965427
data/puzzles/pz1/PZ1_solution_0.pdb     23      -0.01577494265586389
```

Note that the solution has the lowest (best) score. However, comparisons are not straightforward between sequences of different length.

### Dependencies

I made an effort to avoid dependencies outside of the Julia Standard Libary. For that reason, I do not include support for command-line options (e.g., `--help` is not implemented). However, it was not possible to avoid the use of *gunzip* (bundled with Linux) for unzipping the filed downloaded from PDB. The script "fetch_native.jl" calls gunzip directly, without any third-party libraries.

