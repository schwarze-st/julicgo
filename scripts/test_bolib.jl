include("../data/BOLIBver2_julia/nonlinear_testbed.jl")
import LinearAlgebra: Diagonal

print(testbed)
println(length(testbed))

for i in eachindex(testbed)
    println("Testing instance $i")
    x = ones(getfield(Main, Symbol("NX_",i)))
    y = ones(getfield(Main, Symbol("NY_",i)))
    println("Name: $(testbed[i])")
    Fxy = getfield(Main, Symbol("F_",i))(x,y) 
    Gxy = getfield(Main, Symbol("G_",i))(x,y)
    println("F(x,y) = ", Fxy)
    @assert Fxy isa Number   
    println("G(x,y) = ", Gxy)
    nG = getfield(Main, Symbol("nG_",i))
    if nG ==1
        @assert Gxy isa Number
        println(" G OK: length=1, elt=$(typeof(Gxy))")
    elseif nG > 1
        @assert Gxy isa AbstractVector
        @assert length(Gxy) == nG
        @assert eltype(Gxy) <: Real 
        println(" G OK: length=$(length(Gxy)), elt=$(eltype(Gxy))")
    else
        @assert Gxy isa AbstractVector
        @assert length(Gxy) == 0
        println(" G OK: length=0")
    end
    fxy = getfield(Main, Symbol("f_",i))(x,y)
    gxy = getfield(Main, Symbol("g_",i))(x,y)
    println("f(x,y) = ", fxy)
    @assert fxy isa Number
    println("g(x,y) = ", gxy)
    ng = getfield(Main, Symbol("ng_",i))
    if ng ==1
        @assert gxy isa Number
        println(" g OK: length=1, elt=$(typeof(gxy))")
    elseif ng > 1
        @assert gxy isa AbstractVector
        @assert length(gxy) == ng
        @assert eltype(gxy) <: Real
        println(" g OK: length=$(length(gxy)), elt=$(eltype(gxy))")
    else
        @assert gxy isa AbstractVector
        @assert length(gxy) == 0
        println(" g OK: length=0")
    end
    println("-------------------------------------------")
end