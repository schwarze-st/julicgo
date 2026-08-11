include("../data/BOLIBver2_julia/nonlinear_testbed.jl")
include("../data/BOLIBver2_julia/testbed_info.jl")
include("../src/julicgo.jl")
import LinearAlgebra: Diagonal
using JLD2, DataFrames, CSV

# ─────  broadcast‑overload  ─────
import Base: +, -

#  Vector + Skalar
+(v::AbstractVector{T}, s::Number) where {T} = v .+ s
+(s::Number, v::AbstractVector{T}) where {T} = s .+ v

#  Vector - Skalar
-(v::AbstractVector{T}, s::Number) where {T} = v .- s
-(s::Number, v::AbstractVector{T}) where {T} = s .- v

function to_svector(v::Vector{T}) where T
    SVector{length(v)}(v)
end


function main(result_folder::String)
    if !isdir(result_folder)
        mkdir(result_folder)
    end
    O_nonemp = 0
    epsilon=0.1; delta=0.1; maxiter=Inf; time_limit=5400; min_width=0; default_bound=5.0
    df_pars = DataFrame(Epsilon=epsilon, Delta=delta, Time_limit=time_limit, Default_bound=default_bound, Max_iter=maxiter, Min_width=min_width)
    CSV.write("$result_folder/parameters.csv", df_pars)
    println("We consider a testbed of length: ", length(testbed))
    println("The choosen tolerances are epsilon=$epsilon and delta=$delta")
    for i in eachindex(testbed)
        #if i>20 continue end
        x_l = getfield(Main, Symbol("x_l_",i)); x_u = getfield(Main, Symbol("x_u_",i))
        y_l = getfield(Main, Symbol("y_l_",i)); y_u = getfield(Main, Symbol("y_u_",i))
        name = testbed[i]
        if haskey(solutions, name)
            xy_best = solutions[name]
        else 
            xy_best = zeros((length(x_l)+length(y_l)))
        end
        for j in eachindex(x_l)
            if x_l[j]==-Inf
                x_l[j] = xy_best[j]-default_bound
            end
            if x_u[j]==Inf
                x_u[j] = xy_best[j]+default_bound
            end
        end
        for k in eachindex(y_l)
            if y_l[k]==-Inf
                y_l[k] = xy_best[k+length(x_l)]-default_bound
            end
            if y_u[k]==Inf
                y_u[k] = xy_best[k+length(x_l)]+default_bound
            end
        end
        println("Testing instance $i from testbed")
        println("   Name: $(testbed[i])")
        f_fun = getfield(Main, Symbol("f_",i))   
        g_fun = getfield(Main, Symbol("g_",i))   
        # Change order: The leader variable x is the parameter
        fhandle = (y, x) -> f_fun(x, y)   # (y,x) → (x,y)
        ghandle = (y, x) -> g_fun(x, y)
        P_curr = Problem(fhandle, ghandle, 
                            to_svector(y_l), to_svector(y_u), 
                            to_svector(x_l), to_svector(x_u))
        time_curr = @elapsed (O, O_I, W, k) = p_icgo(P_curr, epsilon, delta, maxiter, time_limit, min_width) 
        println("run time of instance $i is $time_curr seconds")
        println("It terminated with $(length(W)) boxes in W, $(length(O_I)) boxes in O_init, after $k iterations")
        @save "$result_folder/nonlinear_$(i).jld2" O O_I W k time_curr
        if length(O_I)>0; O_nonemp += 1; end
        println("-------------------------------------------")
    end
    println("Number of instances with nonempty O: ", O_nonemp)
    println("-------------------------------------------")
end

main("data/results_0811b")
