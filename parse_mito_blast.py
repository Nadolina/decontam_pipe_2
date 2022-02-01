## Parsing blast tabular output. 

## test file with two scaffolds (one a true mito contaminant) - scaff_52_741_mito_blast_bMelUnd1.tsv 

import csv
import pandas as pd

## Open tabular format output from blast of scaffolds against NCBI mitochondrial db
tabfile = []
with open("mito_blast_bMelUnd1_test5_nocov.tsv",'r') as file:
    file = csv.reader(file, delimiter = '\t')
    for line in file: 
        tabfile.append(line)

## put in some sort of ... if sum alignment lengths < total scaff length, do not bother checking for coverage 
dffile = pd.DataFrame(tabfile, columns = ['qseqid','sseqid','qlen','length','qcovhsp','eval','qstart','qend','qcovs'])

## list of all the unique scaffolds named in the blast output 
uniqScaffs = dffile.qseqid.unique()

for uniqScaff in uniqScaffs:

    rows = dffile.loc[dffile['qseqid'] == uniqScaff] ## isolate rows with a particular scaffold name 

    ## making a list of all the alignment start and end positions 
    starts = list(rows['qstart']) 
    ends = list(rows['qend'])
    totalScaffLength = (list(rows['qlen']))[0]

    # Some alignments start at the same position in the scaffold and overlap - this code block below just identifies the longest fragment starting from 
    # each unique start position and adds it to the dictionary. 
    # So each start position has one end position and thats whatever end position makes it the longest alignment from the start. 
    # MIGHT WANT TO TEST THIS OUT 
    startEnds = {}
    for i in range(len(starts)):
        if starts[i] not in startEnds.keys():
            startEnds[starts[i]] = ends[i]
        elif int(startEnds[starts[i]]) < int(ends[i]):
            startEnds[starts[i]] = int(ends[i])

    startEndsDf = pd.DataFrame()
    startEndsDf['starts'] = [int(key) for key in startEnds.keys()]
    startEndsDf['ends'] = [int(value) for value in startEnds.values()]

    startEndsDfSort = startEndsDf.sort_values('starts')

    startsSort = list(startEndsDfSort['starts'])
    endsSort = list(startEndsDfSort['ends'])

    coverage = 0 
    totalPositionsOverlaps = 0
    gapsBetweenAlignments = 0 
    for i in range(len(startsSort) - 1):
        alignLength = endsSort[i] - startsSort[i]
        overlapGapLength = startsSort[i+1] - endsSort[i]
        coverage += alignLength
        # print (overlapGapLength)
        if overlapGapLength < 0:
            totalPositionsOverlaps += overlapGapLength
            coverage = coverage - overlapGapLength ## If an overlap is caluclated, then the length of the overlap is removed from the total coverage because that would be 
            ## positions that were covered by two different alignments. 
        elif overlapGapLength > 0:
            gapsBetweenAlignments += overlapGapLength

    print ("\n%s scaffold coverage report." % uniqScaff)
    print ("Total length of scaffold: %s" % totalScaffLength)
    print ("Total alignment coverage: %i" % coverage)
    percentCov = (coverage/int(totalScaffLength)*100)
    print ("Percent of scaffold covered by alignment: %f" % percentCov + "%")

    


