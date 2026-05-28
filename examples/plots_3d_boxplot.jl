using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
include("../src/julicgo.jl")

# 1) Alle Kanten eines Würfels in Eckpunkt‐Indizes
const _BOX_EDGES3D = [
  (1,2),(2,3),(3,4),(4,1),  # Boden
  (5,6),(6,7),(7,8),(8,5),  # Decke
  (1,5),(2,6),(3,7),(4,8)   # Säulen
]

"""
    plot_boxes3d(O, W; lw=1.5)

Erzeugt und liefert einen 3D‐Plot, in dem
  - jede Box in `W` als schwarzes Drahtgitter,
  - jede Box in `O` als grünes Drahtgitter
gezeichnet wird.
"""
function plot_boxes3d(O::Vector, W::Vector; lw=1.5)
    #plotlyjs()

    plt = plot(legend=false, dpi=1200, size=(1000,1000))   # neuer Plot, keine Legende

    # Hilfsfunktion: aus einer Box die 8 Eckpunkte erhalten
    function _corners(box)
        ivs = vcat(box.tbox, box.xbox)            # SVector{3, Interval}
        lows = [inf(iv) for iv in ivs]
        ups  = [sup(iv) for iv in ivs]
        # 8 Eckpunkte (x,y,z)
        xs = ( lows[1], ups[1], ups[1], lows[1],
               lows[1], ups[1], ups[1], lows[1] )
        ys = ( lows[2], lows[2], ups[2], ups[2],
               lows[2], lows[2], ups[2], ups[2] )
        zs = ( lows[3], lows[3], lows[3], lows[3],
               ups[3], ups[3], ups[3], ups[3] )
        return xs, ys, zs
    end

    # 2) Alle O‐Boxen in grün zeichnen
    println("Plotte $(length(O)) O‐Boxen")
    for box in O
        xs, ys, zs = _corners(box)
        for (i,j) in _BOX_EDGES3D
            plot!(plt,
                  [xs[i], xs[j]],
                  [ys[i], ys[j]],
                  [zs[i], zs[j]];
                  color  = :green,
                  linewidth = lw)
        end
    end
    # 3) Alle W‐Boxen in schwarz scattern
    println("Plotte $(length(W)) W‐Boxen")
    tx = Float64[]; xx = Float64[]; yy = Float64[]
    for box in W
        ivs = vcat(box.tbox, box.xbox)  
        midpts = Float64[mid(iv) for iv in ivs]
        push!(tx, midpts[1]); push!(xx, midpts[2]); push!(yy, midpts[3])
    end
    scatter3d!(plt, tx, xx, yy;
        markersize      = lw*0.15,
        markerstrokewidth = 0,
        color           = :black
    )
    # 4) Beschriftungen
    xlabel!("t")
    ylabel!("x1")
    zlabel!("x2")
    return plt
end

epsilon = 0.2
delta = 0.2
minwidth = 0.001
for P in ["P195"]#["P194","P195"]
    println("Lade Beispiel $(P) aus Grundzüge der PO")
    @load "data/$(P)_$(epsilon)_$(delta)_$(minwidth)_30k.jld2" O O_init W it_k elapsed
    println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
    println("Starte Plotting der Ergebnisse aus $P...")
    plt = plot_boxes3d(O_init, W)
    println("Fertig mit Plotting.")
    #println("Zeige Plot...")
    #display(plt)
    println("Speichere Plot als svg...")
    savefig(plt, "plots/ex_gdpo_$(P)_$(epsilon)_$(delta)_$(minwidth).svg")
end