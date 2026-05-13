using StaticArrays, IntervalArithmetic

a = @SVector [interval(1.0, 2.0), interval(3.0, 4.0), interval(1.5, 2.5)]
b = @SVector [mid(ai) for ai in a]

b = [mid(ai) for ai in a]
print(b)
print(SVector{3,Float64}(b...))
print(mid.(a))
print(a[1]==emptyinterval())
print(intersect_interval(a[1],a[2]))
print(emptyinterval())
print(intersect_interval(a[1],a[3])!==emptyinterval())
print(intersect_interval(a[1],a[2])!==emptyinterval())
print(SVector{3,Float64}(mid.(a)...))