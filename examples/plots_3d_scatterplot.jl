using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
include("../src/julicgo.jl")

# PlotlyJS-Backend aktivieren
plotlyjs()

#@load "data/ex_gdpo_0502_15000.jld2" O W
@load "data/ex_gdpo_0101_50000_wo05pi.jld2" O W

# Daten aufbereiten (wie gehabt)
tO, xO, yO = Float64[], Float64[], Float64[]
for node in O
    push!(tO, mid(node.tbox[1]))
    px = mid.(node.xbox)
    push!(xO, px[1]); push!(yO, px[2])
end

tW, xW, yW = Float64[], Float64[], Float64[]
for node in W
    push!(tW, mid(node.tbox[1]))
    px = mid.(node.xbox)
    push!(xW, px[1]); push!(yW, px[2])
end

# interaktiver 3D-Scatterplot mit Achsenbeschriftung
plt = plot(
  tO, xO, yO;
  size = (800, 600),
  title = "GDPO, ex. 1.9.5: Midpoints of boxes in O",
  seriestype = :scatter3d,
  markersize  = 1,
  color      = :blue,
  label      = "O",
  xlabel     = "t",
  ylabel     = "x₁",
  zlabel     = "x₂",
  )

display(plt)


