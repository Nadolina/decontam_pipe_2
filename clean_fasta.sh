#!/bin/sh 

## This is the final script for removing terminal gaps and contaminant scaffolds. 

scaffs=$1
outfile=$2

gfastats $scaffs -o $outfile --remove-terminal-gaps 

