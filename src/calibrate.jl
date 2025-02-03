include("infoholder.jl")
include("util.jl")
include("histograms.jl")
include("pdb.jl")
include("euclid.jl")

const maxscore = 10.0
k = 3

outdir = "output"

# Input
pdbfiles = readdir("data/native", join=true)
# Size threshold used during development, to speed up calculations
size_threshold = 1_000_000    # Maximum file size, in kB
global skipped_files = 0

function make_distance_histogram_updater(histogram_dict)
    return function update_distance_histogram!(nuc1, nuc2, d)
        histogram_name = Symbol(*(extrema((nuc1, nuc2))...))
        update!(histogram_dict[histogram_name], d)
    end

    return nothing
end

function main()
    # Histograms
    EDGES = 0:20
    nucpair_histograms = NamedTuple(x => SimpleHistogram(EDGES) for x in nuc_pairs)

    update_distance_histogram! = make_distance_histogram_updater(nucpair_histograms)
    for pdbfile in pdbfiles
        @info "Processing $(pdbfile)"
    
        if stat(pdbfile).size > size_threshold * 1_000
            @warn "File $(pdbfile) exceeds the $(size_threshold) kB threshold and was skipped"
            continue
        end

        df = read_atoms(pdbfile; name="C3\'")
    
        isvalid = check_sequence(df; quiet = false)
        global skipped_files += isvalid
        isvalid || continue
    
        inter_atomic_distance_map(update_distance_histogram!, df, k)
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
        replace!(scores, NaN => maxscore)
        write_scores(file, scores)
    end
end

main()
