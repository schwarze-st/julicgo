using IntervalArithmetic

setdisplay(:full)
a = interval(2.,3.)
b = interval(-1.,1.)
c = interval(0.,0.5)

f(x::Number) = x^2 - 1
f(x::Interval) = x^2 - interval(1.,1.)

for x in [a,b,c]
    println(f(x))
end

g(x) = x[1]^2 + x[2]^2 - x[3]
nabla_g(x::Number) = [2*x[1], 2*x[2], -1]

println(g([1.,0.,1.5])) # with floating point numbers
println(g([interval(1.,1.),interval(0.,0.),interval(1.5,1.5)])) # with 1-point intervals
println(g([a,b,c])) # with intervals
println(nabla_g([a,b,c]))

d = Inf
println(d)
typeof(d)
