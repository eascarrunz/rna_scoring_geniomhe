const nuc_symbols = "ACGU"

# List of possible nucleotide pairings. Nucleotides must be in alphabetical order in each pair.
const nuc_pairs = (:AA, :AC, :AG, :AU, :CC, :CG, :CU, :GG, :GU, :UU, :NN)

function beginswith(text::String, pattern::String)
    length(text) < length(pattern) && return false

    for (i, c) in enumerate(pattern)
        text[i] != c && return false
    end

    return true
end


function read_scores(T::Type{<:Number}, file)
    scores = Vector{T}()
    open(file) do io
        for line in eachline(io)
            s = strip(line)
            push!(scores, parse(T, s))
        end
    end

    return scores
end

function write_scores(file, scores)
    b = 0
    open(file, "w") do io
        for s in scores
            b += write(io, string(s), '\n')
        end
    end

    return b
end


function check_sequence(df; quiet = false)
    if length(df) == 0
        quiet || @warn "No valid data in file"
        return false
    end 

    observed_nuc_symbols = sort(unique(df.ResidueName))
    if ! all(occursin.(observed_nuc_symbols, nuc_symbols))
        quiet || @warn "Invalid nucleotide symbols in sequence: $(join(setdiff(observed_nuc_symbols, nuc_symbols), ' '))"
        return false
    end
    
    return true
end

# nuc_values = codepoint.(nuc_symbols) .|> Int
# nuc_values .-= minimum(nuc_values)
# nuc_value_combinations = Iterators.product(nuc_values, nuc_values)
# nuc_pair_values = map(sum, nuc_value_combinations)
# nuc_pair_hashes = nuc_pair_values .% 15

# nuc_symbols = ['A', 'C', 'G', 'U']
# nuc_pairs = Set(extrema(x) for x in Iterators.product(nuc_symbols, nuc_symbols)) |> collect |> sort

# """
#     nuc_pair_hash(nuc1::Char, nuc2::Char)
#     nuc_pair_hash(nucpair::String)

# Perfect hash for pairs of nucleotides (only A, C, G, and U).
# """
# function nuc_pair_hash(nuc1::Char, nuc2::Char)
#     nuc1, nuc2 = nuc2 > nuc1 ? (nuc2, nuc1) : (nuc1, nuc2)

#     return 1 + Int((codepoint(nuc1) + codepoint(nuc2)) % 15)
# end

# nuc_pair_hash(nucpair::String) = nuc_pair_hash(nucpair[1], nucpair[2])

# nuc_pair_hash_list = [nuc_pair_hash(x...) for x in nuc_pairs]
# max_hash = maximum(nuc_pair_hash_list)
# nuc_pair_keys = fill("XX", max_hash)

# for (nuc_pair, value) in zip(nuc_pairs, nuc_pair_hash_list)
#     nuc_pair_keys[value] = *(nuc_pair...)
# end

# nuc_pair_key(v) = nuc_pair_keys[v]

# struct NucPairMap{T}
#     values::Memory{T}

#     NucPairMap{T}() = new(Memory{T}(undef, max_hash))
# end

# Base.keys
# Base.haskey(::NucPairMap, key::Tuple{Char,Char}) = key ∈ nuc_pairs
# Base.haskey(::NucPairMap, key::String) = key ∈ nuc_pair_keys
# Base.getindex(dict::NucPairMap, key) = haskey(dict, key) ? dict.values[nuc_pair_hash(key)] : nothing
# function Base.setindex!(dict::NucPairMap, key, value)
#     haskey(dict, key) || throw(KeyError("key $(key) is not a valid nucleotide pair"))
#     dict.values[nuc_pair_hash(key)] = value

#     return nothing
# end
