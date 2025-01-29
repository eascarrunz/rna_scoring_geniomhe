using Pkg; Pkg.activate(".");

include("util.jl")
include("stats.jl")
include("pdb.jl")
include("euclid.jl")

using ..SimpleHistograms
# include("svg.jl")

const maxscore = 10.0

outdir = "output"

# Histograms
const EDGES = 0:20
const nucpair_histograms = NamedTuple(x => MyHistogram(EDGES) for x in nuc_pairs)

# Input
pdbfiles = readdir("data/native", join=true)
size_threshold = 2_500    # Maximum file size, in kB
global skipped_files = 0

function populate_atomic_distance_histograms!(histograms, df, k)
    coords_i = zeros(3)
    coords_j = zeros(3)
    nb = length(df.ResidueName)

    for i in eachindex(df.ResidueName)
        nuc_i = df.ResidueName[i]
        coords_i .= df.X[i], df.Y[i], df.Z[i]
        chain_i = df.ChainID[i]

        for j in (i + (k + 1)):nb
            chain_j = df.ChainID[j]
            chain_i == chain_j || break

            nuc_j = df.ResidueName[j]
            coords_j .= df.X[j], df.Y[j], df.Z[j]

            d = euclid(coords_i, coords_j)
            if d < 2.0
                @warn "d = $(d) found between atoms #$(i) ($(nuc_i)) and #$(j) ($(nuc_j))"
            end
            @assert d > 0.0

            histogram_name = Symbol(*(extrema((nuc_i, nuc_j))...))
            update!(histograms[histogram_name], d)
        end
    end

    return nothing
end


for pdbfile in pdbfiles
    @info "Processing $(pdbfile)"

    if stat(pdbfile).size > size_threshold * 1_000
        @warn "File $(pdbfile) exceeds the $(size_threshold) kB threshold and was skipped"
        continue
    end

    df = read_atoms(pdbfile; name="C3\'")
    if isempty(df)
        @warn "File $(pdbfile) was skipped because it contained no valid data"
        continue
    end

    observed_nuc_symbols = sort(unique(df.ResidueName))

    if length(observed_nuc_symbols) ≠ 4 || ! all(occursin.(observed_nuc_symbols, "ACGU"))
        @warn "Data file $(pdbfile) was skipped because it contained exotic nucleotide symbols"
        println(observed_nuc_symbols)
        global skipped_files += 1
        continue
    end

    populate_atomic_distance_histograms!(nucpair_histograms, df, 3)
end


# Compute the NN histogram
for h in nucpair_histograms[nuc_pairs[1:end-1]]
    nucpair_histograms[:NN].counts .+= h.counts
end

for (k, h) in pairs(nucpair_histograms)
    file = joinpath(outdir, "counts_" * string(k) * ".txt")
    write_scores(file, h.counts)
end

f = NamedTuple(k => v.counts / sum(v.counts) for (k, v) in pairs(nucpair_histograms))
ubar = NamedTuple(k => -log.(v ./ f.NN) for (k, v) in pairs(f))

for (k, x) in pairs(ubar)
    file = joinpath(outdir, "interaction_profile_" * string(k) * ".txt")
    scores = min.(x, maxscore)
    replace!(scores, NaN=>maxscore)
    write_scores(file, scores)
    # draw_interaction_profile("output/interaction_profile_$(k).svg", x)
end


# for (k, h) in pairs(nucpair_histograms)
#     hist_file = "output/histogram_$(k).svg"
#     draw_histogram(hist_file, h)
    
#     h.counts .+= 0.0001    # Laplacian smoothing
# end

# draw_interaction_profile("foo.svg", ubar.AU)

