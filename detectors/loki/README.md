

# Visualisation of raw loki readouts
These tools reads hdf5 files for loki dumped by the EFU. Notably
they read ringid, fenid, tubeid and the four amplitudes A, B, C, D
into a Scipp DataArray. Plotting is done using Plopp.

## strawpos.py
This script creates a figure with a historgram plot for each tube, with
position along the straw (y) against the straw id (x).

Both straw id and position are floating point values between 0 and 1 and
calculated acording to the formulae in the LoKI ICD.

## ampls.py
This scipt creates a figure with a historgram plot for each tube,
with amplitude B vs amplitude A.


## Filtering
Data can be filtered by ring id or fen id using -r  and -f options.
If no values are specified data is aggregated across all rings or
all fens.

This is useful for debugging when multiple tubes are installed, possibly
spanning multiple rings.

## Output
For each run a png file is created.


## References
https://scipp.github.io/
https://scipp.github.io/plopp/
