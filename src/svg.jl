module SVG

export Point2D, draw, midpoint

struct Point2D
    x::Float64
    y::Float64

    Point2D(x::Real, y::Real) = new(x, y)
end

midpoint(p1::Point2D, p2::Point2D) =
    Point2D((p1.x + p2.x) / 2, (p1.y + p2.y) / 2)

const XML_INDENT = "    "

abstract type Element end

struct Root
    width::Float64
    height::Float64
    children::Vector{Element}

    Root(w::Real, h::Real) = new(w, h, Element[])
end

Base.push!(root::Root, e...) = push!(root.children, e...)

"""
    draw(io, element)

Write the code of an SVG element to an io.
"""
function draw(io::IO, root::Root)
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

struct Line <: Element
    p1::Point2D
    p2::Point2D
    class::String
    optattr::Dict{String,String}
    
    Line(p1, p2; class="", optattr = Dict{String,String}()) = new(p1, p2, class, optattr)
end

draw(io::IO, e::Line) =
    write(io, "<line ") +
        common_2p(io, e) +
        write(io, ' ') +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct PolyLine <: Element
    points::Vector{Point2D}
    class::String
    optattr::Dict{String,String}

    PolyLine(points; class="", optattr = Dict{String,String}()) = new(points, class, optattr)
end

draw(io::IO, e::PolyLine) =
    write(io, "<polyline points=\"$(join(("$(p.x),$(p.y)" for p in e.points), ' '))\" ") +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct Rect <: Element
    p::Point2D     # Coordinates of the top left
    w::Float64     # Width
    h::Float64     # Height
    class::String
    optattr::Dict{String,String}

    Rect(p, w::Real, h::Real; class="", optattr = Dict{String,String}()) = new(p, w, h, class, optattr)
end

draw(io::IO, e::Rect) =
    write(io, "<rect ") +
        common_1p(io, e) +
        write(io, " width=\"$(e.w)\" height=\"$(e.h)\" ") +
        common_class_attr(io, e) + write(io, "/>\n")


struct Circle <: Element
    c::Point2D  # Coordinates of the centre
    r::Float64  # Radius
    class::String
    optattr::Dict{String,String}

    Circle(c, r::Real; class="", optattr = Dict{String,String}()) = new(c, r, class, optattr)
end

draw(io::IO, e::Circle) =
    write(io, "<circle cx=\"$(e.c.x)\" cy=\"$(e.c.y)\" r=\"$(e.r)\" ") +
        common_class_attr(io, e) +
        write(io, "/>\n")


struct Text <: Element   # Warning: Remember to use SVG.Text to avoid conflict with Base.Text
    p::Point2D
    text::String
    class::String
    optattr::Dict{String,String}

    Text(p, text; class="", optattr = Dict{String,String}()) = new(p, text, class, optattr)
end

draw(io::IO, e::SVG.Text) =
    write(io, "<text ") +
        common_1p(io, e) +
        write(io, ' ') +
        common_class_attr(io, e) +
        write(io, ">$(e.text)</text>")

end # module SVG

# struct PlotFrame
#     p1::Point2D                      # Point 1 (upper left corner)
#     p2::Point2D                      # Point 2 (lower right corner)
#     xlims::Tuple{Float64, Float64}   # X axis limits (min, max)
#     ylims::Tuple{Float64, Float64}   # Y axis limits (min, max)
#     xspan::Float64                   # Length of the X axis
#     yspan::Float64                   # Length of the Y axis
#     children::Vector{SVGElement} # Content of the frame

#     PlotFrame(p1, p2, xlims, ylims) =
#         new(p1, p2, xlims, ylims, xlims[2] - xlims[1], ylims[2] - ylims[1])
# end

# struct AxisSpine
#     ax::Symbol      # :X or :Y
#     p1::Point2D
#     p2::Point2D
# end



    
# draw_svg_polyline(io::IO, points, stroke_color="#000") =
#     write(io, """<polyline points="$(join(("$(p.x),$(p.y)" for p in points), ' '))" stroke=$(stroke_color)/>""")
    

    
# """
# Map plot coordinates to SVG coordinates within a plot area
# """
# plot_svg_coord(pf::PlotFrame, p::Point2D) =
#     Point2D(
#         pf.p1.x + p.x / pf.xspan,
#         pf.p2.y - p.y / pf.yspan
#     )


# """
# Draw the spine of an axis of a plot area
# """
# function axis_spine(pf::PlotFrame, ax::Symbol, nticks, axgap = 2, tick_length = 5)
#     if ax == :X
#         axlims = pf.xlims
#         spinep1 = Point2D(pf.p1.x, pf.p2.y + axgap)
#         spinep2 = Point2D(pf.p2.x, pf.p2.y + axgap)
#         ticksX = range(spinep1.x, spinep2.x, length = nticks)
#         ticksP1 = (Point2D(x, spinep1.y) for x in ticksX)
#         ticksP2 = (Point2D(x, spinep1.y + tick_length) for x in ticksX)
#     elseif ax == :Y
#         axlims = pf.ylims
#         spinep1 = Point2D(pf.p1.x - axgap, pf.p1.y)
#         spinep2 = Point2D(pf.p1.x - axgap, pf.p2.y)
#     end

#     axrange = range(axlims..., length = nticks)
# end




# function draw_histogram(file, h::MyHistogram)
#     wcanvas, hcanvas = 400, 150
#     margins = (left = 50, right = 10, top = 7.5, bottom = 40)
#     wplot = wcanvas - margins.left - margins.right
#     hplot = hcanvas - margins.top - margins.bottom

#     bfill = "#000000"

#     b = length(h)    # Number of bins
#     bw = wplot / b   # Bin drawing width
#     bX = margins.left:bw:(wcanvas - margins.right)

#     bhmax = hplot           # Maximum bin height
#     bH = h.counts ./ maximum(h.counts) .* bhmax  # Bin heights
#     bY = margins.top + hplot .- bH

#     yticks_nb = 8
#     yticks_values = range(0.0, maximum(h.counts), length=yticks_nb)
#     yticksY = margins.top .+ hplot .- yticks_values ./ maximum(h.counts) .* bhmax
#     ticklength = 5

#     open(file, "w") do io
#         println(io, XML_DECLARATION)
#         println(io, """<svg width="$(wcanvas)" height="$(hcanvas)" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">""")

#         # Plotting frame
#         println(io, """$(XML_INDENT)<rect stroke="#000" fill="rgba(0,0,0,0)" x="$(margins.left)" y="$(margins.top)" width="$(wplot)" height="$(hplot)"/>""")

#         # Y ticks
#         for i in 1:yticks_nb
#             println(io, """$(XML_INDENT)<line x1="$(margins.left)" x2="$(margins.left - ticklength)" y1="$(yticksY[i])" y2="$(yticksY[i])" stroke="#000"/>""")
#             println(io, """$(XML_INDENT)<text x="$(margins.left - ticklength)" y="$(yticksY[i])" text-anchor="end" dominant-baseline="middle" font-size="12">$(round(Int, yticks_values[i]))</text>""")
#         end

#         # Bins
#         for i in 1:b
#             println(io, """$(XML_INDENT)<rect fill="$(bfill)" stroke="rgba(0,0,0,0)" x="$(bX[i])" y="$(bY[i])" width="$(bw)" height="$(bH[i])"/>""")
#         end

#         # X ticks
#         for i in 1:2:(b + 1)
#             println(io, """$(XML_INDENT)<line x1="$(bX[i])" x2="$(bX[i])" y1="$(margins.top + hplot)" y2="$(margins.top + hplot + ticklength)" stroke="#000"/>""")
#             println(io, """$(XML_INDENT)<text x="$(bX[i])" y="$(margins.top + hplot + ticklength)" text-anchor="middle" dominant-baseline="hanging" font-size="12">$(round(h.edges[i], digits=1))</text>""")
#         end

#         println(io, """$(XML_INDENT)<text x="$(margins.left + wplot/2)" y="$(margins.top + hplot + ticklength+24)" text-anchor="middle" dominant-baseline="middle" font-size="12">d [Å]</text>""")
            
#         println(io, "</svg>")
#     end

#     return nothing
# end

# edges = nucpair_histograms.UU.edges
# d = [x + 0.5 * step(edges) for x in edges[1:end-1]]


# """
# Return a string with the SVG path commands necessary to plot lines between the points in a series of X, Y coordinates
# """
# function svg_path_commands(X, Y)
#     x, X = Iterators.peel(X)
#     y, Y = Iterators.peel(Y)

#     s = "M$(x) $(y)"
#     for (x, y) in zip(X, Y)
#         s *= " L$(x) $(y)"
#     end

#     return s
# end

# function draw_interaction_profile(file, ubar)
#     wcanvas, hcanvas = 400, 150
#     margins = (left = 50, right = 10, top = 7.5, bottom = 40)
#     wplot = wcanvas - margins.left - margins.right
#     hplot = hcanvas - margins.top - margins.bottom
#     Yfactor = 0.9    # Proportion of the Y axis used to plot the data (in order to leave some whitespace)

#     bfill = "#000000"

#     ubar = clamp.(ubar, -10, 10)

#     ubar_n = length(ubar)
#     d_step = wplot / ubar_n
#     dX = margins.left:d_step:(wcanvas - margins.right)

#     ubar_min, ubar_max = extrema(filter(! isnan, ubar))
#     ubar_span = ubar_min - ubar_max
#     ubarY = margins.top + hplot .- (ubar .- ubar_max) ./ ubar_span .* hplot .* Yfactor
#     clamp!(ubarY, -10, 10)

#     yticks_nb = 8
#     yticks_values = range(ubar_min, ubar_max, length=yticks_nb)
#     yticksY = margins.top .+ hplot .- yticks_values ./ maximum(ubar) .* hplot .* Yfactor
#     ticklength = 5

#     open(file, "w") do io
#         println(io, XML_DECLARATION)
#         println(io, """<svg width="$(wcanvas)" height="$(hcanvas)" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">""")

#         # Plotting frame
#         println(io, """$(XML_INDENT)<rect stroke="#000" fill="rgba(0,0,0,0)" x="$(margins.left)" y="$(margins.top)" width="$(wplot)" height="$(hplot)"/>""")

#         # Y ticks
#         for i in 1:yticks_nb
#             println(io, """$(XML_INDENT)<line x1="$(margins.left)" x2="$(margins.left - ticklength)" y1="$(yticksY[i])" y2="$(yticksY[i])" stroke="#000"/>""")
#             println(io, """$(XML_INDENT)<text x="$(margins.left - ticklength)" y="$(yticksY[i])" text-anchor="end" dominant-baseline="middle" font-size="12">$(round(yticks_values[i], digits=2))</text>""")
#         end

#         # Paths
#         path_string = svg_path_commands(dX, ubarY)
#         println(io, """$(XML_INDENT)<path d="$(path_string)" stroke="#000" fill="rgba(0,0,0,0)"/>""")

#         # X ticks
#         for i in 1:2:(ubar_n + 1)
#             println(io, """$(XML_INDENT)<line x1="$(dX[i])" x2="$(dX[i])" y1="$(margins.top + hplot)" y2="$(margins.top + hplot + ticklength)" stroke="#000"/>""")
#             println(io, """$(XML_INDENT)<text x="$(dX[i])" y="$(margins.top + hplot + ticklength)" text-anchor="middle" dominant-baseline="hanging" font-size="12">$(round(dX[i], digits=1))</text>""")
#         end

#         println(io, """$(XML_INDENT)<text x="$(margins.left + wplot/2)" y="$(margins.top + hplot + ticklength+24)" text-anchor="middle" dominant-baseline="middle" font-size="12">d [Å]</text>""")
            
#         println(io, "</svg>")
#     end

#     return nothing
# end


