using StaticArrays
include("../src/julicgo.jl")
# TODO implement the example from the theory paper, which is a simple 2D example with one constraint and one time variable.
f(x,t) = -x[1]

g_1(x,t)= x[1] - t[1]
g_2(x,t)= -x[1] + t[1] - 1

g_vec = [g_1, g_2]

lx = @SVector [-5.]
ux = @SVector [5.]
lt = @SVector [-2.]
ut = @SVector [2.]

P = Problem(f, g_vec, lx, ux, lt, ut)

epsilon = 0.2
delta = 0.1
maxiter = 20000

O, W = p_icgo(P, epsilon, delta, maxiter)

# save O and W to file
using JLD2 

# Speichern
@save "data/meine_boxen.jld2" O W
