using StaticArrays
include("../src/julicgo.jl")

f(x,t) = x[1]

g1(x,t)= x[2] - x[1] - 1
g2(x,t)= cos(t[1])*x[1] + sin(t[1])*x[2]

g_vec = [g1, g2]

lx = @SVector [-1., 0.]
ux = @SVector [0., 1.]
lt = @SVector [0.]
ut = @SVector [2*pi]

P = Problem(f, g_vec, lx, ux, lt, ut)

p_icgo(P)