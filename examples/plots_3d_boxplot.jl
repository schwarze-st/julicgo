using Plots
using StaticArrays
using IntervalArithmetic
using JLD2
using LaTeXStrings
include("../src/julicgo.jl")

# 1) Alle Kanten eines Würfels in Eckpunkt‐Indizes
const _BOX_EDGES3D = [
  (1,2),(2,3),(3,4),(4,1),  # Boden
  (5,6),(6,7),(7,8),(8,5),  # Decke
  (1,5),(2,6),(3,7),(4,8)   # Säulen
]

function plot_boxes3d(O::Vector, W::Vector; lw=1.5)
    plt = plot(legend=false, dpi=1200, size=(1000,1000))   # neuer Plot, keine Legende

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

function plot_data3d(names, epsilon, delta, minwidth, maxiter)
    for P in names
        println("Lade Beispiel $(P) aus Grundzüge der PO")
        @load "data/$(P)_$(epsilon)_$(delta)_$(minwidth)_$(maxiter/1000).jld2" O O_init W it_k elapsed
        println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
        println("Starte Plotting der Ergebnisse aus $P...")
        plt = plot_boxes3d(O_init, W)
        println("Fertig mit Plotting.")
        println("Schreibe Plot in svg...")
        savefig(plt, "plots/$(P)_$(epsilon)_$(delta)_$(minwidth)_$(maxiter/1000).svg")
    end
end

function draw_problems3d()
    plotlyjs()
    plt1 = Plots.plot(legend=false, dpi=1200, size=(1000,1000))
    # P195 
    ts = []; x1s = []; x2s = []
    ts = vcat(ts, range(0, 0.5*pi, length=50))  ; x1s = vcat(x1s, -ones(50))   ; x2s = vcat(x2s, zeros(50))
    x1s = vcat(x1s, range(-1,0,length=50))      ; x2s = vcat(x2s, zeros(50))   ; ts =  vcat(ts, ones(50)*0.5*pi)
    ts = vcat(ts, range(0.5*pi, pi, length=50)) ; x1s = vcat(x1s, zeros(50))   ; x2s = vcat(x2s, zeros(50))
    x2s = vcat(x2s, range(0,1,length=50))       ; x1s = vcat(x1s, zeros(50))   ; ts =  vcat(ts, ones(50)*pi)
    ts = vcat(ts, range(pi , 7/4*pi, length=50)); x1s = vcat(x1s, zeros(50))   ; x2s = vcat(x2s, ones(50))
    x1s = vcat(x1s, range(0,-1,length=50))      ; x2s = vcat(x2s, range(1,0,length=50)) ; ts = vcat(ts, ones(50)*7/4*pi)
    ts = vcat(ts, range(7/4*pi,2*pi, length=50)); x1s = vcat(x1s, -ones(50))   ; x2s = vcat(x2s, zeros(50))
    Plots.plot3d!(plt1,ts, x1s, x2s; color=:black, linewidth=2)
    xlabel!("t")
    ylabel!("x_1")
    zlabel!("x_2")
    savefig(plt1, "plots/P194_3d.svg")

    plt2 = Plots.plot(legend=false, dpi=1200, size=(1000,1000))
    t = []; x1 = []; x2 = []
    t = vcat(t, range(0, 0.5*pi, length=50))  ; x1 = vcat(x1, -ones(50))   ; x2 = vcat(x2, zeros(50))
    Plots.plot3d!(plt2, t, x1, x2; color=:black, linewidth=2)
    t = []; x1 = []; x2 = []
    t = vcat(t, range(0.5*pi+0.1, pi, length=50)) ; x1 = vcat(x1, zeros(50))   ; x2 = vcat(x2, zeros(50))
    t = vcat(t, ones(50)*pi);                 ; x1 = vcat(x1, zeros(50))   ; x2 = vcat(x2, range(0,1,length=50))
    t_temp = range(pi, 3/2*pi, length=50)
    x1_temp = -1 ./(1 .+ (cos.(t_temp) ./ sin.(t_temp)))
    x2_temp =  1 ./(1 .+ tan.(t_temp))
    t = vcat(t, t_temp);                      ; x1 = vcat(x1, x1_temp)     ; x2 = vcat(x2, x2_temp)
    t = vcat(t, range(3/2*pi,2*pi, length=50)); x1 = vcat(x1, -ones(50))   ; x2 = vcat(x2, zeros(50))  
    Plots.plot3d!(plt2, t, x1, x2; color=:black, linewidth=2)
    Plots.scatter3d!(plt2, [0.5*pi], [0.0], [0.0]; color=:black, alpha=0, 
        markersize=1.5, markerstrokealpha=1, markerstrokewidth=15)    
    Plots.scatter3d!(plt2, [0.5*pi], [-1.], [0.0]; color=:black, alpha=1, 
        markersize=1.5, markerstrokealpha=1, markerstrokewidth=15) 
    xlabel!("t")
    ylabel!("x1")
    zlabel!("x2")
    savefig(plt2, "plots/P195_3d.svg")
end

epsilon = 0.2
delta = 0.2
minwidth = 0.001
maxiter = 30000
names = ["P195"]#["P194","P195"]

#plot_data3d(names, epsilon, delta, minwidth, maxiter)
draw_problems3d()