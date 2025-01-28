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