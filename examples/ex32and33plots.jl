using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
using LaTeXStrings
include("../src/julicgo.jl")

rect(w, h, x, y) = Plots.Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])

function plot_boxes2d(plt, O, W, t_on_yaxis=true)
    for node in O
        if t_on_yaxis
            w = diam(node.xbox[1])
            h = diam(node.tbox[1])
            box = rect(w, h, inf(node.xbox[1]), inf(node.tbox[1]))
        else
            w = diam(node.tbox[1])
            h = diam(node.xbox[1])
            box = rect(w, h, inf(node.tbox[1]), inf(node.xbox[1]))
        end
        Plots.plot!(plt, box; color=:green, linewidth=0.1, alpha=0.5)
    end
    xx = Float64[]; yy = Float64[]
    for node in W
        if t_on_yaxis
            push!(xx, mid(node.xbox[1]))
            push!(yy, mid(node.tbox[1]))
        else
            push!(xx, mid(node.tbox[1]))
            push!(yy, mid(node.xbox[1]))
        end
    end
    Plots.scatter!(plt, xx, yy; 
        markersize=3, markershape=:rect, markerstrokewidth = 0,
        alpha=0.75, color=:red)
    return plt
end

function plot_ex32(epsilon, delta, minwidth, lw, color_g, colortext)
    @load "data/ex32_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed
    a_1(x) = (x[1]-2)^2 - 1
    a_2(x) = (x[1]-0.5)^2 - 0.25
    a_3(x) = (x[1]+0.5)^2 - 0.25
    g(x,t)= - t[1] + min(a_1(x), a_2(x), a_3(x))
    a = range(-2.5, 2.5, length=500)
    plt = Plots.plot(legend = false, dpi=1200, size=(800,600))
    plot!(plt, a, x->g([x], [0.0]); fillrange=length(a)*[1.0], fillalpha=0.2, alpha=0.5, color=color_g, linewidth=lw)
    annotate!(plt, (1.5, 0.5, text(L"G",18, colortext)))
    plt = plot_boxes2d(plt, O_init, W)
    xlabel!("x")
    ylabel!("t")
    xlims!(-2.0, 2.5)
    ylims!(-1.25, 1.0)
    #display(plt)
    Plots.savefig(plt, "plots/ex32_$(epsilon)_$(delta)_$(minwidth).png")
end

function plot_ex33(epsilon, delta, minwidth, lw, color_g, colortext)
    @load "data/ex33_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed
    g(x)= x[1]^4 - x[1]^2
    a = range(-2, 2, length=500)
    plt = Plots.plot(legend = false, dpi=1200, size=(800,600))
    plot!(plt, a, x->g(x); fillrange=length(a)*[-2.0], fillalpha=0.2, alpha=0.5, color=color_g, linewidth=lw)
    annotate!(plt, (1., -1., text(L"G",18, colortext)))
    plt = plot_boxes2d(plt, O_init, W)
    xlabel!("x")
    ylabel!("t")
    xlims!(-2, 2)
    ylims!(-2, 2)
    Plots.savefig(plt, "plots/ex33_$(epsilon)_$(delta)_$(minwidth).png")
end

function main(epsilon, delta, minwidth, lw, color_g, colortext)
    plot_ex32(epsilon, delta, minwidth, lw, color_g, colortext)
    plot_ex33(epsilon, delta, minwidth, lw, color_g, colortext)
end

main(0.1,0.1,0.0001,1.5,:blue,:darkblue)