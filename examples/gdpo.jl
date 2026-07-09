using StaticArrays
using JLD2 
using Profile
include("../src/julicgo.jl")

f(x,t) = cos(t[1])*x[1]+sin(t[1])*x[2]
f2(x,t) = x[1]
g1(x,t)= x[2] - x[1] - 1
g2(x,t) = cos(t[1])*x[1] + sin(t[1])*x[2]

lx = @SVector [-2., 0.]
ux = @SVector [0., 2.]
lt = @SVector [0.]
ut = @SVector [2*pi]

g_vec = Vector{Function}()
push!(g_vec, g1)
P194 = Problem(f, g_vec, lx, ux, lt, ut)

push!(g_vec, g2)
P195 = Problem(f2, g_vec, lx, ux, lt, ut)

epsilon = 0.2
delta = 0.2
maxiter = 30000
minwidth = 0.001
profiling = false

Problems = [P194, P195]
Problems = [P195] # for testing
names = ["P194", "P195"]
names = ["P195"] # for testing
for (k, P) in enumerate(Problems)
    println("Lade Beispiel $(names[k]) aus Grundzüge der PO")
    println("Start P-ICGO mit epsilon=$epsilon, delta=$delta, maxiter=$maxiter, minwidth=$minwidth")
    if profiling
        Profile.clear()                       
        @profile p_icgo(P, epsilon, delta, maxiter, minwidth)
        Profile.print(maxdepth=20, mincount=3)
    else
        t = time_ns()
        O, O_init, W, it_k = p_icgo(P, epsilon, delta, maxiter, minwidth)
        elapsed = (time_ns() - t)/1e9
        println("Anzahl Iterationen: $it_k, benötigte Zeit: $elapsed Sekunden.")
        println("Anzahl der O-Boxen: $(length(O_init)), Anzahl der W-Boxen: $(length(W))")
        @save "data/ex_gdpo_$(names[k])_$(epsilon)_$(delta)_$(minwidth).jld2" O O_init W it_k elapsed
    end

    
    
end

