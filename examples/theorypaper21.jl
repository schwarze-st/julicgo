using StaticArrays
using JLD2 
using Profile
include("../src/julicgo.jl")

f(x,t) = x[1]
a_1(x) = (x[1]-2)^2 - 1
a_2(x) = (x[1]-0.5)^2 - 0.25
a_3(x) = (x[1]+0.5)^2 - 0.25
g(x,t)= - t[1] + min(a_1(x), a_2(x), a_3(x))
g_vec = Vector{Function}()
push!(g_vec, g)

lx = @SVector [-2.5]
ux = @SVector [2.5]
lt = @SVector [-1.5]
ut = @SVector [1.5]

P21 = Problem(f, g_vec, lx, ux, lt, ut)

epsilon = 0.1
delta = 0.1
maxiter = 30000
minwidth = epsilon*1e-3
profiling = false

t = time_ns()
O, O_init, W, it_k = p_icgo(P21, epsilon, delta, maxiter, minwidth)
elapsed = (time_ns() - t)/1e9
println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
println("Anzahl der O-Boxen: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
@save "data/ex21_$(epsilon)_$(delta)_$(minwidth)_$(maxiter/1000).jld2" O O_init W it_k elapsed