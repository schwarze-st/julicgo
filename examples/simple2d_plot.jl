using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
include("../src/julicgo.jl")

@load "data/meine_boxen.jld2" O W

rect(w, h, x, y) = Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])

plt = plot(legend = false)

for node in O
    w = diam(node.tbox[1])
    h = diam(node.xbox[1])
    box = rect(w, h, inf(node.tbox[1]), inf(node.xbox[1]))
    plot!(box)
end
