DependencyParser.jl
===================

Dependency parser written in Julia.

Currently graph-based projective (Eisner algorithm) parsing only.


## Example Usage
julia Train.jl <train file> <model file> --iter <N>
julia Parse.jl <test file> <model file> <output file>

Files in CoNLL format.
