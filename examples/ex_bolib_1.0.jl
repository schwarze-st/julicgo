using Plots
using StaticArrays
using IntervalArithmetic
using JLD2 
using LaTeXStrings
include("../src/julicgo.jl")

save=false
if save
    # Write examples from BOLIB 1.0 to data folder, so that they can be loaded in the tests
    f(y,x) = (y[1]-1)^2 - 1.5*x[1]*y[1]
    g_1(y,x) = -3*x[1]+y[1]+3
    g_2(y,x) = x[1]-0.5*y[1]-4
    g_3(y,x) = x[1]+y[1]-7
    g_tup = NTuple{3, Function}((g_1, g_2, g_3))

    ly = @SVector [0.]
    uy = @SVector [7.0]
    lx = @SVector [0.]
    ux = @SVector [7.0]

    Bard1988Ex1 = Problem(f, g_tup, ly, uy, lx, ux)
    save_object("data/BOLIBver2/Bard1988Ex1.jld2", Bard1988Ex1)

    f(y,x) = (y[1]-5)^2
    g_1(y,x) = -2*x[1]+y[1]-1
    g_2(y,x) = x[1]-2*y[1]+2
    g_3(y,x) = x[1]+2*y[1]-14
    g_tup = NTuple{3, Function}((g_1, g_2, g_3))
    ly = @SVector [1.]
    uy = @SVector [7.0]
    lx = @SVector [0.]
    ux = @SVector [8.0]

    ClarkWesterberg1990a = Problem(f, g_tup, ly, uy, lx, ux)
    save_object("data/BOLIBver2/ClarkWesterberg1990a.jld2", ClarkWesterberg1990a)
end



testbed = ["Bard1988Ex1","ClarkWesterberg1990a"]

run=true 

if run
    epsilon = 0.5
    delta = 0.5
    maxiter = 30000
    minwidth = epsilon*1e-4
    for name in testbed
        println("Lade Beispiel $name aus BOLIB 1.0")
        P = load_object("data/BOLIBver2/$(name).jld2")
        t = time_ns()
        println("Starte P-ICGO für $name")
        O, O_init, W, it_k = p_icgo(P, epsilon, delta, maxiter, minwidth)
        elapsed = (time_ns() - t)/1e9
        println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
        println("Anzahl der O-Boxen: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
        @save "data/$(name).jld2" O O_init W it_k elapsed
    end
end