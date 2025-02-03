include("util.jl")
include("histograms.jl")
include("svg.jl")
include("svg_plotting.jl")

indir = "output"
outdir = "output"
const count_prefix = joinpath(indir, "counts_")
const score_prefix = joinpath(indir, "interaction_profile_")
const EDGES = 0:20

infiles = readdir(indir, join=true)
count_files = filter(x -> startswith(x, count_prefix) && endswith(x, ".txt"), infiles)
score_files = filter(x -> startswith(x, score_prefix) && endswith(x, ".txt"), infiles)

println(score_files)

for infile in score_files
    scores = read_scores(Float64, infile)
    pushfirst!(scores, first(scores))
    ctx = lines(0:20, scores)
    add_xlabel!(ctx, "d [Å]")
    add_ylabel!(ctx, "Pairwise score")
    outfile = replace(infile, ".txt"=>".svg")
    open(outfile, "w") do io
        plot(io, ctx)
    end
end

for infile in count_files
    counts = read_scores(Int64, infile)
    h = SimpleHistogram(EDGES)
    h.counts .= counts
    ctx = plot_histogram(h)
    add_xlabel!(ctx, "d [Å]")
    outfile = replace(infile, ".txt" => ".svg")
    open(outfile, "w") do io
        plot(io, ctx)
    end
end

# for file in count_files
#     counts = read_scores(Int, file)
#     h = MyHistogram(EDGES, counts)
# end


