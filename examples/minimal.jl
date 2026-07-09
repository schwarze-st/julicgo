# script.jl
using PlotlyJS

# 1) Testdaten
x = rand(100); y = rand(100); z = rand(100)

# 2) Erzeuge einen Trace
tr = PlotlyJS.scatter3d(
    x = x,
    y = y,
    z = z,
    mode   = "markers",
    marker = attr(size=4, symbol="square")  # quadratische Marker
)

# 3) Layout mit manueller Aspect‐Ratio
lyt = PlotlyJS.Layout(
    scene = attr(
        aspectmode   = "manual",
        aspectratio  = attr(x=3, y=1, z=1),
        xaxis        = attr(title="X (3× lang)"),
        yaxis        = attr(title="Y"),
        zaxis        = attr(title="Z")
    )
)

# 4) Figure bauen und als SVG speichern
fig = PlotlyJS.plot(tr; layout = lyt)
savefig(fig, "out.svg")   # klappt auch in einem .jl‐Skript ohne display()