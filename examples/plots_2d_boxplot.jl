using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
include("../src/julicgo.jl")
plotlyjs()

@load "data/ex21_0.1_0.1_0.0001_30.0.jld2" O O_init W it_k elapsed

rect(w, h, x, y) = Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])

plt = plot(legend = false, dpi=1200, size=(800*1.5,600*1.5))

a_1(x) = (x[1]-2)^2 - 1
a_2(x) = (x[1]-0.5)^2 - 0.25
a_3(x) = (x[1]+0.5)^2 - 0.25
g(x,t)= - t[1] + min(a_1(x), a_2(x), a_3(x))
a = range(-2.5, 2.5, length=500)
plot!(a, x->g([x], [0.0]), color=:blue, linewidth=0.5, label="g(x,0)")

for node in O_init
    w = diam(node.xbox[1])
    h = diam(node.tbox[1])
    box = rect(w, h, inf(node.xbox[1]), inf(node.tbox[1]))
    plot!(box, color=:green, linewidth=0)
end

xx = Float64[]; yy = Float64[]
for node in W
    ivs = vcat(node.xbox, node.tbox)
    push!(xx, mid(ivs[1])); push!(yy, mid(ivs[2]))
end
scatter!(xx, yy; markersize=1, markerstrokewidth = 0, color=:red)

xlabel!("x")
ylabel!("t")
#display(plt)
xlims!(-2.5, 2.5)
ylims!(-1.5, 1.5)
savefig(plt, "plots/ex21_0.1_0.1_0.0001_30.0.svg")

