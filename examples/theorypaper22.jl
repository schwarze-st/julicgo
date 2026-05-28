using StaticArrays
using JLD2 
using Profile
include("../src/julicgo.jl")

f(x,t) = x[1]^2 - max(0, -1-x[1])
g(x,t)= t[1] - x[1]^4 + x[1]^2
g_vec = Vector{Function}()
push!(g_vec, g)

lx = @SVector [-2.]
ux = @SVector [2.]
lt = @SVector [-2.]
ut = @SVector [2.]

P22 = Problem(f, g_vec, lx, ux, lt, ut)

epsilon = 0.1
delta = 0.1
maxiter = 30000
minwidth = epsilon*1e-3
profiling = false

t = time_ns()
O, O_init, W, it_k = p_icgo(P22, epsilon, delta, maxiter, minwidth)
elapsed = (time_ns() - t)/1e9
println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
println("Anzahl der O-Boxen: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
@save "data/ex22_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed