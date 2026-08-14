using StaticArrays
using JLD2 
using Profile
include("../src/julicgo.jl")

function example32(epsilon, delta, maxiter, minwidth)
    f(x,t) = x[1]
    a_1(x) = (x[1]-2)^2 - 1
    a_2(x) = (x[1]-0.5)^2 - 0.25
    a_3(x) = (x[1]+0.5)^2 - 0.25
    g(x,t)= - t[1] + min(a_1(x), a_2(x), a_3(x))

    lx = @SVector [-2.]
    ux = @SVector [2.5]
    lt = @SVector [-1.25]
    ut = @SVector [1.0]

    P21 = Problem(f, (g,), lx, ux, lt, ut)
    println("Rechne Example $(32) mit epsilon=$(epsilon), delta=$(delta) und minwidth=$(minwidth)")
    t = time_ns()
    O, O_init, W, it_k = p_icgo(P21, epsilon, delta, maxiter, Inf, minwidth)
    elapsed = (time_ns() - t)/1e9
    println("P-ICGO ist fertig")
    println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
    println("Anzahl der O-Boxen: $(length(O)), Anzahl der Boxen in O^I: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
    @save "data/ex32_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed
end

function example33(epsilon, delta, maxiter, minwidth)
    f(x,t) = x[1]^2 - max(0, -1-x[1])
    g(x,t)= t[1] - x[1]^4 + x[1]^2
    g_tup = NTuple{1, Function}((g,))

    lx = @SVector [-2.]
    ux = @SVector [2.]
    lt = @SVector [-2.]
    ut = @SVector [2.]

    P22 = Problem(f, g_tup, lx, ux, lt, ut)
    println("Rechne Example $(33) mit epsilon=$(epsilon), delta=$(delta) und minwidth=$(minwidth)")
    t = time_ns()
    O, O_init, W, it_k = p_icgo(P22, epsilon, delta, maxiter, Inf, minwidth)
    elapsed = (time_ns() - t)/1e9
    println("P-ICGO ist fertig")
    println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
    println("Anzahl der O-Boxen: $(length(O)), Anzahl der Boxen in O^I: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
    @save "data/ex33_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed
end

example32(0.1, 0.1, Inf, 0.0001)
example33(0.1, 0.1, Inf, 0.0001)