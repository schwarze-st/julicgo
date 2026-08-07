
using JLD2, DataFrames, PrettyTables, CSV

function main(results_path::String)
    df = DataFrame(CSV.File("$results_path/results.csv"))
    nx = Int[]
    ny = Int[]
    ng = Int[]
    vols_x = Float64[]
    vols_y = Float64[]
    vols_xy = Float64[]
    for i in eachindex(df.Name)
        index_testbed = findfirst(isequal(df.Name[i]), testbed)
        if index_testbed === nothing
            push!(nx,100)
            push!(ny,100)
            push!(ng,100)
            push!(vols_x,100.)
            push!(vols_y,100.)
            push!(vols_xy,100.)
        else
        push!(nx, getfield(Main, Symbol("NX_",index_testbed)))  
        push!(ny, getfield(Main, Symbol("NY_",index_testbed)))
        push!(ng, getfield(Main, Symbol("ng_",index_testbed)))
        x_l = getfield(Main, Symbol("x_l_",index_testbed)); x_u = getfield(Main, Symbol("x_u_",index_testbed))
        y_l = getfield(Main, Symbol("y_l_",index_testbed)); y_u = getfield(Main, Symbol("y_u_",index_testbed))
        name = testbed[index_testbed]
        if haskey(solutions, name)
            xy_best = solutions[name]
        else 
            xy_best = zeros((length(x_l)+length(y_l)))
        end
        for j in eachindex(x_l)
            if x_l[j]==-Inf
                x_l[j] = xy_best[j]-10.
            end
            if x_u[j]==Inf
                x_u[j] = xy_best[j]+10.
            end
        end
        for k in eachindex(y_l)
            if y_l[k]==-Inf
                y_l[k] = xy_best[k+length(x_l)]-10.
            end
            if y_u[k]==Inf
                y_u[k] = xy_best[k+length(x_l)]+10.
            end
        end
        v_x = prod(x_u .- x_l)
        push!(vols_x, v_x)
        v_y = prod(y_u .- y_l)
        push!(vols_y, v_y)
        v_xy = v_x * v_y
        push!(vols_xy, v_xy)
        end
    end
    df = DataFrame(Name=df.Name, Vols_x=vols_x, Vols_y=vols_y, Vols_xy=vols_xy, n_x=nx, n_y=ny, n_g=ng, Time=df.Time, Iterations=df.Iterations, O_len=df.O_len, W_len=df.W_len, W_len_less=df.W_len_less, F_Best=df.F_Best, F_LB=df.F_LB)
    sort!(df,:Time)
    show(df, allrows=true)
    
    #open("$results_path/tabelle.tex", "w") do f
     #   pretty_table(f, df, backend = :latex, formatters = [fmt__printf("%5.1f", [5])])
    #end
end

main("data/results_0804")