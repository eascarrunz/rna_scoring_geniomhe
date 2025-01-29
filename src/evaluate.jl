include("util.jl")
include("data_frame.jl")
include("euclid.jl")
include("pdb.jl")

k = 3
EDGES = 0:20

function interpolate_score(profile, edges, x)
    first_edge = first(edges)
    last_edge = last(edges)
    edge_step = step(edges)

    x1 = floor(Int, (x - first_edge) / edge_step)
    # in_range = first_edge ≤ x < last_edge
    # in_range || return 0.0
    i1 = x1 + 1
    i1 ≥ lastindex(profile) && return 0.0
    x2 = min(x1 + edge_step, last_edge)
    y1, y2 = profile[i1], profile[i1 + 1]
    
    return (y1 * (x2 - x) + y2 * (x - x1)) / (x2 - x1)
end

function interpolate_score(profile, val)
    l = round(Int, val, RoundDown)
    r = round(Int, val, RoundUp)
    dl = abs(val - l)
    dr = abs(r - val)
    d = dr + dl
    lval = profile[l + 1]
    rval = profile[r + 1]
    s = rval * dl
    s += lval * dr
    s /= d

    return s
end

"""
    inter_atomic_distance_map(f, df, k)
"""
function inter_atomic_distance_map(f::Function, df, k)
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
            f(nuc_i, nuc_j, d)
        end
    end

    return nothing
end

function make_score_computer(s::Ref, profile_dict, edges)
    return function compute_score(nuc1, nuc2, d)
        nuc_pair = Symbol(*(extrema((nuc1, nuc2))...))
        profile = profile_dict[nuc_pair]

        s[] += interpolate_score(profile, edges, d)
    end
end


function main()
    isempty(ARGS) && error("No input files given")
    indir = "output"
    interaction_profiles =
        Dict(x => read_scores(Float64, joinpath(indir, "interaction_profile_" * string(x) * ".txt")) for x in nuc_pairs)
    
    println(stdout, "File\tLength\tScore")
    for file in ARGS
        df = read_atoms(file; name="C3'")
        check_sequence(df, quiet = true) || continue
        s = Ref(0.0)
        compute_score = make_score_computer(s, interaction_profiles, EDGES)
        inter_atomic_distance_map(compute_score, df, k)
        println(stdout, file, '\t', length(df), '\t', s[])
    end

    return 0
end

main()
