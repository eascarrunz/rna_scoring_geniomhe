struct Point2D
    x::Float64
    y::Float64

    Point2D(x::Real, y::Real) = new(x, y)
end

midpoint(p1::Point2D, p2::Point2D) =
    Point2D((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)

const XML_INDENT = "    "

abstract type SVGElement end

struct SVGRoot
    width::Float64
    height::Float64
    children::Vector{SVGElement}

    SVGRoot(w::Real, h::Real) = new(w, h, SVGElement[])
end

Base.push!(root::SVGRoot, e...) = push!(root.children, e...)

"""
    draw(io, element)

Write the code of an SVG element to an io.
"""
function draw(io::IO, root::SVGRoot)
    bytes = write(io, """<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n""") +
        write(io, """<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n""") +
        write(io, """<svg width="$(root.width)" height="$(root.height)" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n""")

    for c in root.children
        bytes += write(io, XML_INDENT)
        bytes += draw(io, c)
    end

    return bytes + write(io, "</svg>\n")
end


"""
Return the string of SVG attributes from a optattr dictionary.
"""
optattr_string(e) = join(("$(k)=\"$(v)\"" for (k, v) in pairs(e.optattr)), ' ')

"""
Write common SVG code for elements based on 1 point
"""
common_1p(io, e) = write(io, "x=\"$(e.p.x)\" y=\"$(e.p.y)\"")

"""
Write common SVG code for elements based on 2 points
"""
common_2p(io, e) = write(io, "x1=\"$(e.p1.x)\" y1=\"$(e.p1.y)\" x2=\"$(e.p2.x)\" y2=\"$(e.p2.y)\"")

"""
Write common SVG code for class and optional attributes.
"""
common_class_attr(io, e) =
    write(io, "class=\"$(e.class)\"" ^(! isempty(e.class)), ' ', optattr_string(e)...)

struct SVGLine <: SVGElement
    p1::Point2D
    p2::Point2D
    class::String
    optattr::Dict{String,String}
    
    SVGLine(p1, p2; class="", optattr = Dict{String,String}()) = new(p1, p2, class, optattr)
end

draw(io::IO, e::SVGLine) =
    write(io, "<line ") +
        common_2p(io, e) +
        write(io, ' ') +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct SVGPolyLine <: SVGElement
    points::Vector{Point2D}
    class::String
    optattr::Dict{String,String}

    SVGPolyLine(points; class="", optattr = Dict{String,String}()) = new(points, class, optattr)
end

draw(io::IO, e::SVGPolyLine) =
    write(io, "<polyline points=\"$(join(("$(p.x),$(p.y)" for p in e.points), ' '))\" ") +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct SVGRect <: SVGElement
    p::Point2D     # Coordinates of the top left
    w::Float64     # Width
    h::Float64     # Height
    class::String
    optattr::Dict{String,String}

    SVGRect(p, w::Real, h::Real; class="", optattr = Dict{String,String}()) = new(p, w, h, class, optattr)
end

draw(io::IO, e::SVGRect) =
    write(io, "<rect ") +
        common_1p(io, e) +
        write(io, " width=\"$(e.w)\" height=\"$(e.h)\" ") +
        common_class_attr(io, e) + write(io, "/>\n")


struct SVGCircle <: SVGElement
    c::Point2D  # Coordinates of the centre
    r::Float64  # Radius
    class::String
    optattr::Dict{String,String}

    SVGCircle(c, r::Real; class="", optattr = Dict{String,String}()) = new(c, r, class, optattr)
end

draw(io::IO, e::SVGCircle) =
    write(io, "<circle cx=\"$(e.c.x)\" cy=\"$(e.c.y)\" r=\"$(e.r)\" ") +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct SVGText <: SVGElement   # Warning: Remember to use SVGText to avoid conflict with Base.Text
    p::Point2D
    text::String
    class::String
    optattr::Dict{String,String}

    SVGText(p, text; class="", optattr = Dict{String,String}()) = new(p, text, class, optattr)
end

draw(io::IO, e::SVGText) =
    write(io, "<text ") +
        common_1p(io, e) +
        write(io, ' ') +
        common_class_attr(io, e) +
        write(io, ">$(e.text)</text>")
