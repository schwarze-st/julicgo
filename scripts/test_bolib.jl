include("../data/BOLIBver2_julia/nonlinear_testbed.jl")

print(testbed)
println(length(testbed))

for i in 1:length(testbed)
    print(testbed[i])
    x = zeros(getfield(Main, Symbol("NX_",i)))
    y = zeros(getfield(Main, Symbol("NY_",i)))
    println("Testing instance $(testbed[i])")
    println("f(x,y) = ", getfield(Main, Symbol("f_",i))(x,y))
    println("g(x,y) = ", getfield(Main, Symbol("g_",i))(x,y))
end