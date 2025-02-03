PLOTFRAME_DEFAULTS = (
    width = 400,
    height = 150,
    ptl = Point2D(50, 7.5),
    pbr = Point2D(390, 110)
)

mutable struct PlottingContext
    svgroot::SVGRoot                   # SVG root container
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

mapx(x::Real, ctx::PlottingContext) = ctx.svgptl.x + ctx.svgwidth * (x - ctx.xlims[1]) / ctx.xspan
mapy(y::Real, ctx::PlottingContext) = ctx.svgpbr.y - ctx.svgheight * (y - ctx.ylims[1]) / ctx.yspan

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
        push!(ctx.svgroot, SVGLine(Point2D(ctx.svgptl.x, svgy), Point2D(svgx_left, svgy), optattr=Dict("stroke"=>"#000")))
        push!(ctx.svgroot, SVGText(Point2D(svgx_left, svgy), ticklabel, optattr=Dict("text-anchor"=>"end", "dominant-baseline"=>"middle", "font-size"=>"12")))
    end

    return nothing
end

function decorate_xaxis!(ctx::PlottingContext, X, nticks=9)
    Xticks, ticklabels = tick_params(X, nticks)
    for (ticklabel, x) in zip(ticklabels, Xticks)
        svgx = mapx(x, ctx)
        svgy_bottom = ctx.svgpbr.y + 5
        push!(ctx.svgroot, SVGLine(Point2D(svgx, ctx.svgpbr.y), Point2D(svgx, svgy_bottom), optattr=Dict("stroke"=>"#000")))
        push!(ctx.svgroot, SVGText(Point2D(svgx, svgy_bottom), ticklabel, optattr=Dict("text-anchor"=>"middle", "dominant-baseline"=>"hanging", "font-size"=>"12")))
    end
end

function add_xlabel!(ctx::PlottingContext, text)
    xlabel_anchor = Point2D((ctx.svgpbr.x + ctx.svgptl.x) / 2, ctx.svgpbr.y + 30)
    xlabel_text = SVGText(xlabel_anchor, text, optattr = Dict("text-anchor"=>"middle", "dominant-baseline"=>"middle", "font-size"=>"12"))
    push!(ctx.svgroot, xlabel_text)
end

function add_ylabel!(ctx::PlottingContext, text)
    ylabel_anchor = Point2D(ctx.svgptl.x - 35, (ctx.svgpbr.y + ctx.svgptl.y) / 2)
    ylabel_text = SVGText(ylabel_anchor, text, optattr = Dict("text-anchor"=>"middle", "dominant-baseline"=>"central", "font-size"=>"12", "transform"=>"rotate(-90 $(ylabel_anchor.x) $(ylabel_anchor.y))"))
    push!(ctx.svgroot, ylabel_text)
end

function lines(X, Y)
    xlims = extrema(X)
    ylims = extrema(Y)
    ctx = PlottingContext(
        SVGRoot(PLOTFRAME_DEFAULTS.width, PLOTFRAME_DEFAULTS.height),
        PLOTFRAME_DEFAULTS.ptl,
        PLOTFRAME_DEFAULTS.pbr,
        xlims,
        ylims
    )

    svgelems = Dict{Symbol,SVGElement}()
    svgelems[:fig_border] = SVGRect(Point2D(0, 0), ctx.svgroot.width, ctx.svgroot.height, optattr = Dict("fill" => "#FFF", "stroke" => "#000"))
    svgelems[:frame_border] = SVGRect(ctx.svgptl, ctx.svgwidth, ctx.svgheight, optattr = Dict("fill" => "#FFF", "stroke" => "#000"))
    push!(ctx.svgroot, svgelems[:fig_border])
    push!(ctx.svgroot, svgelems[:frame_border])
    # svgelems[:x0] = SVGLine(map(y -> mapcoords(Point2D(0.0, y), ctx), ylims)..., optattr = Dict("stroke" => "#000", "stroke-dasharray" => "4 1"))
    svgelems[:y0] = SVGLine(map(x -> mapcoords(Point2D(x, 0.0), ctx), xlims)..., optattr = Dict("stroke" => "#000", "stroke-dasharray" => "4 1"))
    # push!(ctx.svgroot, svgelems[:x0])
    push!(ctx.svgroot, svgelems[:y0])
    svgpoints = mapcoords.(Point2D.(X, Y), Ref(ctx))
    svgelems[:series] = SVGPolyLine(svgpoints, optattr = Dict("stroke" => "#000", "fill" => "rgba(0,0,0,0)"))
    push!(ctx.svgroot, svgelems[:series])

    decorate_yaxis(ctx, Y)
    decorate_xaxis!(ctx, X)

    return ctx
end

function plot_histogram(h::SimpleHistogram)
    ylims = (0, maximum(h.counts))
    xlims = first(h.edges), last(h.edges)
    
    ctx = PlottingContext(
        SVGRoot(PLOTFRAME_DEFAULTS.width, PLOTFRAME_DEFAULTS.height),
        PLOTFRAME_DEFAULTS.ptl,
        PLOTFRAME_DEFAULTS.pbr,
        xlims,
        ylims
        )
    b = length(h)    # Number of bins
    bw = mapx(first(h.edges) + step(h.edges), ctx) - mapx(first(h.edges), ctx)

    svgelems = Dict{Symbol,SVGElement}()

    # Frame
    svgelems[:fig_border] = SVGRect(Point2D(0, 0), ctx.svgroot.width, ctx.svgroot.height, optattr = Dict("fill" => "#FFF", "stroke" => "#000"))
    push!(ctx.svgroot, svgelems[:fig_border])
    
    l = first(h.edges)
    y0 = mapy(0.0, ctx)
    for i in 1:b
        r = l + step(h.edges)
        height = Float64(h.counts[i])
        x = Float64(l)
        anchor = mapcoords(Point2D(x, height), ctx)
        bar = SVGRect(anchor, bw, y0 - anchor.y, optattr = Dict("fill" => "#000", "stroke" => "#FFF"))
        push!(ctx.svgroot, bar)
        l = r
    end
    
    svgelems[:frame_border] = SVGRect(ctx.svgptl, ctx.svgwidth, ctx.svgheight, optattr = Dict("fill" => "rgba(1, 1, 1, 0)", "stroke" => "#000"))
    push!(ctx.svgroot, svgelems[:frame_border])

    decorate_xaxis!(ctx, xlims)
    decorate_yaxis(ctx, ylims)

    return ctx
end


plot(io::IO, ctx::PlottingContext) = draw(io::IO, ctx.svgroot)

