include("util.jl")
include("stats.jl")
include("plot_module.jl")

using .SVGPlot

indir = "output"
outdir = "output"
const count_prefix = "counts_"
const score_prefix = joinpath(indir, "interaction_scores_")
const EDGES = 0:20

infiles = readdir(indir, join=true)
count_files = filter(x -> startswith(x, count_prefix) && endswith(x, ".txt"), infiles)
score_files = filter(x -> startswith(x, score_prefix) && endswith(x, ".txt"), infiles)

println(score_files)

for infile in score_files
    scores = read_scores(Float64, infile)
    pushfirst!(scores, first(scores))
    ctx = SVGPlot.lines(0:20, scores)
    outfile = replace(infile, ".txt"=>".svg")
    open(outfile, "w") do io
        plot(io, ctx)
    end
end



# for file in count_files
#     counts = read_scores(Int, file)
#     h = MyHistogram(EDGES, counts)
# end


