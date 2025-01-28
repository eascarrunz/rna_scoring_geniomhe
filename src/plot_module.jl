include("svg.jl")

module SVGPlot
using ..SVG

export lines, plot

PLOTFRAME_DEFAULTS = (
    width = 400,
    height = 150,
    ptl = Point2D(50, 7.5),
    pbr = Point2D(390, 110)
)

mutable struct PlottingContext
    svgroot::SVG.Root                   # SVG root container
    svgptl::Point2D                     # SVG coordinates of the *Top Left* corner of the plotitng frame
    svgpbr::Point2D                     # SVG coordinates of the *Bottom Right* corner of the plotitng frame
    xlims::Tuple{Float64,Float64}
    ylims::Tuple{Float64,Float64}
    svgwidth::Float64
    svgheight::Float64
    xspan::Float64
    yspan::Float64

    function PlottingContext(root, p1, p2, xlims, ylims)
        ctx = new(root, p1, p2, xlims, ylims)
        recalc!(ctx)

        return ctx
    end
end


function recalc!(ctx::PlottingContext)
    ctx.xspan = ctx.xlims[2] - ctx.xlims[1]
    ctx.yspan = ctx.ylims[2] - ctx.ylims[1]
    ctx.svgwidth = ctx.svgpbr.x - ctx.svgptl.x
    ctx.svgheight = ctx.svgpbr.y - ctx.svgptl.y

    return nothing
end

mapx(x::Float64, ctx::PlottingContext) = ctx.svgptl.x + ctx.svgwidth * (x - ctx.xlims[1]) / ctx.xspan
mapy(y::Float64, ctx::PlottingContext) = ctx.svgpbr.y - ctx.svgheight * (y - ctx.ylims[1]) / ctx.yspan

"""
Map a point from the space of a data series to the SVG space of a plotting context.
"""
mapcoords(p::Point2D, ctx::PlottingContext) = Point2D(mapx(p.x, ctx), mapy(p.y, ctx))

function tick_params(data, nticks)
    ticks = range(extrema(data)..., length=nticks)
    ndigits = ceil(Int, clamp(- log10(step(ticks)), 0, 5)) + 1
    labels = (string(round(tick, digits=ndigits)) for tick in ticks)

    return ticks, labels
end


function decorate_yaxis(ctx::PlottingContext, Y, nticks=8)
    Yticks, ticklabels = tick_params(Y, nticks)
    for (ticklabel, y) in zip(ticklabels, Yticks)
        svgy = mapy(y, ctx)
        svgx_left = ctx.svgptl.x - 5
        push!(ctx.svgroot, SVG.Line(Point2D(ctx.svgptl.x, svgy), Point2D(svgx_left, svgy), optattr=Dict("stroke"=>"#000")))
        push!(ctx.svgroot, SVG.Text(Point2D(svgx_left, svgy), ticklabel, optattr=Dict("text-anchor"=>"end", "dominant-baseline"=>"middle", "font-size"=>"12")))
    end

    return nothing
end

function decorate_xaxis(ctx::PlottingContext, X, nticks=9)
    Xticks, ticklabels = tick_params(X, nticks)
    for (ticklabel, x) in zip(ticklabels, Xticks)
        svgx = mapx(x, ctx)
        svgy_bottom = ctx.svgpbr.y + 5
        push!(ctx.svgroot, SVG.Line(Point2D(svgx, ctx.svgpbr.y), Point2D(svgx, svgy_bottom), optattr=Dict("stroke"=>"#000")))
        push!(ctx.svgroot, SVG.Text(Point2D(svgx, svgy_bottom), ticklabel, optattr=Dict("text-anchor"=>"middle", "dominant-baseline"=>"hanging", "font-size"=>"12")))
    end
end

function lines(X, Y)
    xlims = extrema(X)
    ylims = extrema(Y)
    ctx = PlottingContext(
        SVG.Root(PLOTFRAME_DEFAULTS.width, PLOTFRAME_DEFAULTS.height),
        PLOTFRAME_DEFAULTS.ptl,
        PLOTFRAME_DEFAULTS.pbr,
        xlims,
        ylims
    )

    svgelems = Dict{Symbol,SVG.Element}()
    svgelems[:fig_border] = SVG.Rect(Point2D(0, 0), ctx.svgroot.width, ctx.svgroot.height, optattr = Dict("fill" => "#FFF", "stroke" => "#000"))
    svgelems[:frame_border] = SVG.Rect(ctx.svgptl, ctx.svgwidth, ctx.svgheight, optattr = Dict("fill" => "#FFF", "stroke" => "#000"))
    push!(ctx.svgroot, svgelems[:fig_border])
    push!(ctx.svgroot, svgelems[:frame_border])
    # svgelems[:x0] = SVG.Line(map(y -> mapcoords(Point2D(0.0, y), ctx), ylims)..., optattr = Dict("stroke" => "#000", "stroke-dasharray" => "4 1"))
    svgelems[:y0] = SVG.Line(map(x -> mapcoords(Point2D(x, 0.0), ctx), xlims)..., optattr = Dict("stroke" => "#000", "stroke-dasharray" => "4 1"))
    # push!(ctx.svgroot, svgelems[:x0])
    push!(ctx.svgroot, svgelems[:y0])
    svgpoints = mapcoords.(Point2D.(X, Y), Ref(ctx))
    svgelems[:series] = SVG.PolyLine(svgpoints, optattr = Dict("stroke" => "#000", "fill" => "rgba(0,0,0,0)"))
    push!(ctx.svgroot, svgelems[:series])

    decorate_yaxis(ctx, Y)
    decorate_xaxis(ctx, X)

    return ctx
end

plot(io::IO, ctx::PlottingContext) = draw(io::IO, ctx.svgroot)

end

