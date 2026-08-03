include("../data/BOLIBver2_julia/nonlinear_testbed.jl")
include("../data/BOLIBver2_julia/testbed_info.jl")
include("../src/julicgo.jl")
import LinearAlgebra: Diagonal
using JLD2 


function main()
    p = 0
    q = 0
    t_ulim = 0
    t_uten = 0
    t_uone = 0
    for i=1:100
        @load "data/results_0801/nonlinear_$(i).jld2" O O_I W k time_curr options
        if length(O_I)>0; p+=1; end
        if time_curr<3600; t_ulim +=1; end
        if length(W)==0; q+=1; end
        if time_curr<600; t_uten +=1; end
        if time_curr<60; t_uone +=1; end
    end
    println("The test run of 1 hour per instance is complete, we report the following results: ")
    println("The testbed included 100 instances")
    println("We report the number of instances, with ")
    println("   - nonempty approximation O: ",p)
    println("   - termination within 1h:    ",t_ulim)
    println("   - termination with empty W: ",q)
    println("   - termination within 600s:  ",t_uten)
    println("   - termination within 60s    ",t_uone)
end

main()
