using IntervalArithmetic

a = interval(2.,3.)
b = interval(-1.,1.)
c = interval(0.,0.5)

f(x) = x^2 - 1

for x in [a,b,c]
    println(f(x))
end

g(x) = x[1]^2 + x[2]^2 - x[3]
nabla_g(x) = [2*x[1], 2*x[2], -1]

println(g([1.,0.,1.5]))
println(g([a,b,c]))
println(nabla_g([a,b,c]))

