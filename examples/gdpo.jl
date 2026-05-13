using StaticArrays
using JLD2 
include("../src/julicgo.jl")

f(x,t) = cos(t[1])*x[1]+sin(t[1])*x[2]
g1(x,t)= x[2] - x[1] - 1
g_vec = Vector{Function}()
push!(g_vec, g1)

lx = @SVector [-2., 0.]
ux = @SVector [0., 2.]
lt = @SVector [0.]
ut = @SVector [2*pi]

P194 = Problem(f, g_vec, lx, ux, lt, ut)

f2(x,t) = x[1]
g2(x,t)= cos(t[1])*x[1] + sin(t[1])*x[2]
push!(g_vec, g2)
lt2 = @SVector [0.51*pi]

P195 = Problem(f2, g_vec, lx, ux, lt2, ut)

epsilon = 0.2
delta = 0.2
maxiter = 50000

Problems = [P194, P195]
names = ["P194", "P195"]
for (k, P) in enumerate(Problems)
    println("Lade Beispiel $(names[k]) aus Grundzüge der PO")
    println("Start P-ICGO mit epsilon=$epsilon, delta=$delta, maxiter=$maxiter")
    t = time_ns()
    O, W = p_icgo(P, epsilon, delta, maxiter)
    elapsed = (time_ns() - t)/1e9
    println("Dauer: $elapsed s")
    @save "data/ex_gdpo_$(names[k])_$(epsilon)_$(delta).jld2" O W elapsed
end

