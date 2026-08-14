using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
using LaTeXStrings
include("../src/julicgo.jl")

Plots.gr()

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
        plot!(plt, box; color=:green, linewidth=0.1, alpha=0.5)
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
    scatter!(plt, xx, yy; markersize=1, markerstrokewidth = 0, alpha=0.5, color=:red)
    return plt
end

f(x,t) = -2*x[1]
g_1(x,t) = x[1] -0.5*t[1] - 5/4
g_2(x,t) = -x[1] -0.5*t[1] + 11/4
#g(x,t) = [g_1(x,t); g_2(x,t)]
g_tup = NTuple{2, Function}((g_1, g_2))

lx = @SVector [-2.5]
ux = @SVector [4.]
lt = @SVector [0.]
ut = @SVector [3.0]

P14 = Problem(f, g_tup, lx, ux, lt, ut)

epsilon = 0.5
delta = 0.5
maxiter = 30000
minwidth = 1e-5

t = time_ns()
O, O_init, W, it_k = p_icgo(P14, epsilon, delta, Inf, Inf, minwidth)
elapsed = (time_ns() - t)/1e9
println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
println("Anzahl der O-Boxen: $(length(O)), Anzahl der O^I-Boxen: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
@save "data/ex14_$(epsilon)_$(delta).jld2" O O_init W it_k elapsed

lw = 1.5

plt = Plots.plot(legend = false, xticks=0:0.5:3.5, yticks=0.5:0.5:3, dpi=1200, size=(800,600), framestyle=:box)

a = range(1.5, 3.0, length=200)
b = range(0.5, 3.0, length=200)
c = range(0.0,0.5, length=50)

ag1 = 5/4 .+ 0.5*a
ag2 = 11/4 .- 0.5*a

agd1 = 5/4 .+ 0.5*b .+ 0.5
agd2 = 11/4 .- 0.5*b .- 0.5

plot!(plt, b, agd2, fillrange=agd1, fillalpha=0.2, alpha=0.5, color=:blue, linewidth=lw)
plot!(plt, b, agd1; color=:blue, alpha=0.5,linewidth=lw)
plot!(plt, a, ag2, fillrange=ag1, fillalpha=0.2, alpha=0.5, color=:grey, linewidth=lw)
plot!(plt, a, ag1; color=:black, linewidth=2*lw)
plt = plot_boxes2d(plt, O_init, W, false)
annotate!(plt, [
    (2, 1.5, text(L"G_{\delta}", 18, :blue)),
    (2.5, 2, text(L"G", 18, :darkblue)),
    (2.1, 2.4, text(L"S", 18, :black))
    ])

xlabel!("t")
ylabel!("x")
xlims!(0.0, 3.0)
ylims!(0.5, 3.5)
display(plt)
Plots.savefig(plt, "plots/ex14_$(epsilon)_$(delta).png")