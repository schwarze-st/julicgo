
using JLD2, DataFrames, PrettyTables, CSV
include("../data/BOLIBver2_julia/nonlinear_testbed.jl")
include("../data/BOLIBver2_julia/testbed_info.jl")

function main(results_path::String)
    df_in = DataFrame(CSV.File("$results_path/results.csv"))
    parameters = DataFrame(CSV.File("$results_path/parameters.csv"))
    default_bound = parameters.Default_bound[1]
    nx = Int[]
    ny = Int[]
    ng = Int[]
    vols_x = Float64[]
    vols_y = Float64[]
    vols_xy = Float64[]
    ratio = Float64[]
    for i in eachindex(df_in.Name)
        index_testbed = findfirst(isequal(df_in.Name[i]), testbed)
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
        diff1 = x_u .- x_l
        v_x = prod(diff1[diff1.>0])
        push!(vols_x, v_x)
        diff2 = y_u .- y_l
        v_y = prod(diff2[diff2.>0])
        push!(vols_y, v_y)
        v_xy = v_x * v_y
        push!(vols_xy, v_xy)
        push!(ratio, (df_in.F_Best[i] - df_in.F_LB[i])/max(abs(df_in.F_Best[i]), abs(df_in.F_LB[i]), 1e-6))
    end
    df = DataFrame(name=df_in.Name, n_x=nx, n_y=ny, n_g=ng, vol_B_0=vols_xy, 
                    t=df_in.Time, iterations=df_in.Iterations, W_len=df_in.W_len, O_len=df_in.O_len, O_I_len = df_in.O_I_len, 
                    F_b=df_in.F_Best, F_l=df_in.F_LB, ratio=ratio)

    df_term = df[df[:,:W_len] .== 0, :]
    df_nterm = df[df[:,:W_len] .> 0, :]
    column_labels = [latex_cell"name", latex_cell"$n_x$", latex_cell"$n_y$", latex_cell"$n_g$", latex_cell"$\mbox{vol}(B_0)$", latex_cell"t", 
                    latex_cell"iterations", latex_cell"$|W|$", latex_cell"$|O|$", latex_cell"$|O^I|$", latex_cell"$F_{b}$", latex_cell"$F_{l}$", latex_cell"$(F_{b}-F_{l})_{r}$"]
    open("$results_path/tabelle.tex", "w") do f
        # formatters = [fmt__latex_sn(4)]
       formatters = [fmt__latex_sn(5,[5]), fmt__printf("%.2f", [6]),fmt__printf("%.3f", [11,12,13])]
       pretty_table(f, df_term, backend = :latex, column_labels = column_labels, 
                    style = LatexTableStyle(column_label = String[]), formatters=formatters, table_format = latex_table_format__booktabs)
       pretty_table(f, df_nterm, backend = :latex, column_labels = column_labels, 
                    style = LatexTableStyle(column_label = String[]), formatters=formatters, table_format = latex_table_format__booktabs)
    end
    CSV.write("$results_path/table_nterm.csv", df_nterm)
    CSV.write("$results_path/table_term.csv", df_term)
end

main("data/results_0807")