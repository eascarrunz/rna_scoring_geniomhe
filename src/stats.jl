module SimpleHistograms

export MyHistogram
export update!

"""
A left-closed histogram containing edges and counts.
"""
struct MyHistogram{R<:AbstractRange}
    edges::R
    counts::Vector{Int}

    MyHistogram(r::R) where R <: AbstractRange = new{R}(r, zeros(Int, length(r) - 1))

    function MyHistogram(x, edges::R) where R <: AbstractRange
        h = MyHistogram(edges)
        update!(h, x)

        return h
    end
end


Base.length(h::MyHistogram) = length(h.counts)
Base.show(io::IO, h::MyHistogram) = print(io, "MyHistogram with $(length(h)) bins and $(sum(h.counts)) observations")


"""
    update!(histogram, observations)

Add observation(s) (scalar or collection) to a histogram.

Observations outside the histogram range are ignored.
"""
function update!(h::MyHistogram, x)
    first_edge = first(h.edges)
    last_edge = last(h.edges)
    edge_step = step(h.edges)

    for val in x
        i = floor(Int, (val - first_edge) / edge_step)    # Index of the bin, minus one
        in_range = first_edge ≤ val < last_edge

        #=
        val is in range: add 1 to the corresponding bin `i` + 1
        val is out of range: add 0 to bin 1
        =#
        @inbounds h.counts[i * in_range + 1] += in_range
    end

    return h
end
   
end


