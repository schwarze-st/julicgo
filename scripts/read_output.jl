include("../src/julicgo.jl")
include("../data/BOLIBver2_julia/nonlinear_testbed.jl")
include("../data/BOLIBver2_julia/testbed_info.jl")
using JLD2, DataFrames, PrettyTables, CSV

# ─────  broadcast‑overload  ─────
import Base: +, -
#  Vector + Skalar
+(v::AbstractVector{T}, s::Number) where {T} = v .+ s
+(s::Number, v::AbstractVector{T}) where {T} = s .+ v
#  Vector - Skalar
-(v::AbstractVector{T}, s::Number) where {T} = v .- s
-(s::Number, v::AbstractVector{T}) where {T} = s .- v


function main(results_path::String)
    names = String[]
    o_len = Int[]
    o_i_len = Int[]
    w_len = Int[]
    times = Float64[]
    iterations = Int[]
    width_w_boxes = Float64[]
    nx = Int[]
    ny = Int[]
    ng = Int[]
    F_best = Float64[]
    F_lb = Float64[]
    F_rel = Float64[]
    for i in eachindex(testbed)
        if isfile("$results_path/nonlinear_$(i).jld2")
            @load "$results_path/nonlinear_$(i).jld2" O O_I W k time_curr
        else
            continue
        end
        push!(iterations,k)
        push!(o_len,length(O))        
        push!(o_i_len,length(O_I))
        push!(w_len,length(W))
        push!(times,time_curr)
        push!(names,testbed[i])
        push!(nx, getfield(Main, Symbol("NX_",i)))
        push!(ny, getfield(Main, Symbol("NY_",i)))
        push!(ng, getfield(Main, Symbol("ng_",i)))
        dim, xy, Ff = get_problem_info(testbed[i])
        push!(F_best, Ff[1])
        push!(width_w_boxes, enclose_w_boxes(W))
        if isfile("$results_path/nonlinear_$(i)_lb.jld2")
            @load "$results_path/nonlinear_$(i)_lb.jld2" lb
        else
            lb = compute_lower_bound(results_path, O, W, i, Ff[1])
            @save "$results_path/nonlinear_$(i)_lb.jld2" lb
        end
        push!(F_lb, lb)
        push!(F_rel, (F_best[end] - F_lb[end])/max(abs(F_best[end]), abs(F_lb[end]), 1e-6))
    end
    df = DataFrame(Name=names, n_x=nx, n_y=ny, n_g=ng, Time=times, Iterations=iterations, O_len=o_len, O_I_len=o_i_len, W_len=w_len, F_Best=F_best, F_LB=F_lb, F_rel=F_rel, Width_W_Boxes=width_w_boxes)
    CSV.write("$results_path/results.csv", df)
    show(df, allrows=true)
end

function compute_lower_bound(results_path::String, O, W, i, lb_paper)
        F_fun = getfield(Main, Symbol("F_",i))   
        G_fun = getfield(Main, Symbol("G_",i))
        # Change order: The leader variable x is the parameter
        Fhandle = (y, x) -> F_fun(x, y)   # (y,x) → (x,y)
        Ghandle = (y, x) -> G_fun(x, y)   # (y,x) → (x,y)
        l = 0
        lb = Inf
        for j in eachindex(O)
            intervalG = Ghandle(O[j].xbox, O[j].tbox)
            if !(intervalG isa AbstractVector && isempty(intervalG))
                if maximum(inf.(intervalG)) > 0
                    l += 1
                    continue
                end
            end
            intervalF = Fhandle(O[j].xbox, O[j].tbox)
            lb_j = inf(intervalF)
            if lb_j < lb
                lb = lb_j
            end
            if lb_j >= lb_paper
                l += 1
            end
        end
        for j in eachindex(W)
            intervalG = Ghandle(W[j].xbox, W[j].tbox)
            if !(intervalG isa AbstractVector && isempty(intervalG))
                if maximum(inf.(intervalG)) > 0
                    l += 1
                    continue
                end
            end
            intervalF = Fhandle(W[j].xbox, W[j].tbox)
            lb_j = inf(intervalF)
            if lb_j < lb
                lb = lb_j
            end
            if lb_j >= lb_paper
                l += 1
            end
        end
    return lb
end

function enclose_w_boxes(W)
        lower_vec = nothing; upper_vec = nothing
        for j in eachindex(W)
            t_box = W[j].tbox
            if j==1
                lower_vec = ones(length(t_box))*Inf
                upper_vec = -ones(length(t_box))*Inf
            end
            for k in eachindex(t_box)
                if lower_vec[k]>inf(t_box[k]); lower_vec[k] = inf(t_box[k]); end
                if upper_vec[k]<sup(t_box[k]); upper_vec[k] = sup(t_box[k]); end
            end
            
        end
        max_width = 0
        if lower_vec != nothing && upper_vec != nothing
            max_width = maximum(upper_vec-lower_vec)
        end
        return max_width
end

main("data/results_0831")
