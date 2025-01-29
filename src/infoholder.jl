"""
The poor man's data frame implementation. With no functions for removing rows or columns.
"""
struct InfoHolder
    names::Vector{Symbol}
    dict::Dict{Symbol,Int}
    values::Vector{Vector}

    InfoHolder() = new(Vector{Symbol}(), Dict{Symbol,Int}(),Vector{Vector}())
    function InfoHolder(; kwargs...)
        df = new(Vector{Symbol}(), Dict{Symbol,Int}(),Vector{Vector}())
        for (i, (k, v)) in enumerate(pairs(kwargs))
            if ! isempty(getfield(df, :values))
                length(v) == length(df) ||
                    error("cannot add column of length $(length(v)) to a data frame of length $(length(df))")
            end
            push!(getfield(df, :names), k)
            getfield(df, :dict)[k] = i
            push!(getfield(df, :values), v)
        end

        return df
    end
end

Base.length(df::InfoHolder) = length(first(getfield(df, :values)))
Base.size(df::InfoHolder) = length(df), length(getfield(df, :values))
Base.names(df::InfoHolder) = getfield(df, :names)
Base.haskey(df::InfoHolder, key) = haskey(getfield(df, :dict), key)
function Base.getindex(df::InfoHolder, key::Symbol)
    i = getfield(df, :dict)[key]

    return getfield(df, :values)[i]
end
Base.getproperty(df::InfoHolder, key::Symbol) = df[key]
itercols(df::InfoHolder) = ((k = v) for (k, v) in zip(getfield(df, :names), getfield(df, :values)))
_get_row(df::InfoHolder, i) = ((k = v[i]) for (k, v) in zip(names(df), getfield(df, :values)))
iterrows(df::InfoHolder) = (_get_row(df, i) for i in 1:length(df))
function Base.push!(df::InfoHolder, kvpairs)
    for (k, v) in pairs(kvpairs)
        push!(df[k], v)
    end

    return nothing
end

function Base.show(io::IO, df::InfoHolder)
    println(io, join(names(df), '\t'))
    for row in iterrows(df)
        println(io, first(row))
    end
end


