"""
Sloppy DataFrame implementation, with no functions for removing rows or columns.
"""
struct DataFrame
    names::Vector{Symbol}
    dict::Dict{Symbol,Int}
    values::Vector{Vector}

    DataFrame() = new(Vector{Symbol}(), Dict{Symbol,Int}(),Vector{Vector}())
    function DataFrame(; kwargs...)
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

Base.length(df::DataFrame) = length(first(getfield(df, :values)))
Base.size(df::DataFrame) = length(df), length(getfield(df, :values))
Base.names(df::DataFrame) = getfield(df, :names)
Base.haskey(df::DataFrame, key) = haskey(getfield(df, :dict), key)
function Base.getindex(df::DataFrame, key::Symbol)
    i = getfield(df, :dict)[key]

    return getfield(df, :values)[i]
end
Base.getproperty(df::DataFrame, key::Symbol) = df[key]
itercols(df::DataFrame) = ((k = v) for (k, v) in zip(getfield(df, :names), getfield(df, :values)))
_get_row(df::DataFrame, i) = ((k = v[i]) for (k, v) in zip(names(df), getfield(df, :values)))
iterrows(df::DataFrame) = (_get_row(df, i) for i in 1:length(df))
function Base.push!(df::DataFrame, kvpairs)
    for (k, v) in pairs(kvpairs)
        push!(df[k], v)
    end

    return nothing
end

function Base.show(io::IO, df::DataFrame)
    println(io, join(names(df), '\t'))
    for row in iterrows(df)
        println(io, first(row))
        # for value in row
        #     println(io, value, '\t')
        # end
    end
end


