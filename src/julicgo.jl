using StaticArrays, IntervalArithmetic

mutable struct Problem{nx,nt,T}
  f      :: Function                        # f( x::SVector{nx,Interval{T}},  t::SVector{nt,Interval{T}} )
  g      :: Vector{Function}                # list g_i(x,t) ≤ 0
  lowerx :: SVector{nx,T}                   # bounds on x
  upperx :: SVector{nx,T}
  lowert :: SVector{nt,T}                   # bounds on t
  uppert :: SVector{nt,T}
end

mutable struct Box_Node{nx,nt,T}         # nx: dimension of x, nt: dimension of t, T: data type
  xbox    :: SVector{nx, Interval{T}}    #   
  tbox    :: SVector{nt, Interval{T}}    #  
  l_omega :: Union{T, Nothing}           # lower bound of w over box
  u_omega :: Union{T, Nothing}           # upper bound of w over box
  l_f     :: Union{T, Nothing}           # lower bound of f over box
  u_f     :: Union{T, Nothing}           # upper bound of f over box
end

function Box_Node(xbox::SVector{nx, Interval{T}}, tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    Box_Node{nx,nt,T}(xbox, tbox, nothing, nothing, nothing, nothing)
end

function width(box::Box_Node{nx,nt,T}) where {nx,nt,T}
    x_widths = [diam(box.xbox[i]) for i in eachindex(box.xbox)]
    t_widths = [diam(box.tbox[i]) for i in eachindex(box.tbox)]
    return maximum(vcat(x_widths, t_widths))
end

#Box_Node(xbox, tbox) = Box_Node{length(xbox), length(tbox), eltype(xbox[1])}(xbox, tbox, nothing, nothing, nothing, nothing)  

function omega(
    P::Problem{nx,nt,T}, 
    x::SVector{nx,T}, 
    t::SVector{nt,T}) where {nx,nt,T<:Real}
    return maximum([g_i(x,t) for g_i in P.g])
end

function bounding_omega(
    P::Problem{nx,nt,T}, xbox::SVector{nx, Interval{T}}, tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    gi_hulls = [g_i(xbox,tbox) for g_i in P.g]
    lower = maximum([inf(gi_hull) for gi_hull in gi_hulls])
    upper = maximum([sup(gi_hull) for gi_hull in gi_hulls])
    return lower, upper
end

function bounding_omega(
    P::Problem{nx,nt,T}, 
    x::SVector{nx,T}, 
    t_box::SVector{nt, Interval{T}}) where {nx,nt,T<:Real}
    gi_hulls = [g_i(x,t_box) for g_i in P.g]
    lower = maximum([inf(gi_hull) for gi_hull in gi_hulls])
    upper = maximum([sup(gi_hull) for gi_hull in gi_hulls])
    return lower, upper
end


function bounding_f(P::Problem{nx,nt,T}, xbox::SVector{nx, Interval{T}}, 
    tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    interval = P.f(xbox, tbox)
    return inf(interval), sup(interval)
end

function bounding_f(P::Problem{nx,nt,T}, x::SVector{nx,T}, tbox::SVector{nt, Interval{T}}) where {nx,nt,T<:Real}
    interval = P.f(x, tbox)
    return inf(interval), sup(interval)
end

function initialize_W(P::Problem{nx,nt,T}) where {nx,nt,T}
    x_comp = SVector{nx, Interval{T}}([interval(P.lowerx[i],P.upperx[i]) for i in eachindex(P.lowerx)]...)
    t_comp = SVector{nt, Interval{T}}([interval(P.lowert[i],P.uppert[i]) for i in eachindex(P.lowert)]...)
    println("x_comp: ", x_comp)
    println("t_comp: ", t_comp) 
    first_node = Box_Node(x_comp, t_comp)
    first_node.l_omega, first_node.u_omega = bounding_omega(P, x_comp, t_comp)
    first_node.l_f, first_node.u_f = bounding_f(P, x_comp, t_comp)
    return [first_node]
end

function improvementfunction_lb(P::Problem{nx,nt,T}, node::Box_Node{nx,nt,T}, current_node::Box_Node{nx,nt,T}, epsilon::Number) where {nx,nt,T}
    left = bounding_omega(P, node.xbox, current_node.tbox)[1]
    right = bounding_f(P, node.xbox, current_node.tbox)[1] - current_node.u_f + epsilon
    return max(left, right) 
end

function partition(node::Box_Node{nx,nt,T}) where {nx,nt,T}
    # bisect the box along the dimension with the largest width
    x_widths = [diam(node.xbox[i]) for i in eachindex(node.xbox)]
    t_widths = [diam(node.tbox[i]) for i in eachindex(node.tbox)]
    max_x_width, x_index = findmax(x_widths)
    max_t_width, t_index = findmax(t_widths)
    if max_x_width >= max_t_width
        # bisect along x dimension
        mid_point = mid(node.xbox[x_index])
        left_box = Box_Node(setindex(node.xbox, interval(inf(node.xbox[x_index]), mid_point), x_index), node.tbox)
        right_box = Box_Node(setindex(node.xbox, interval(mid_point, sup(node.xbox[x_index])), x_index), node.tbox)
    else
        # bisect along t dimension
        mid_point = mid(node.tbox[t_index])
        left_box = Box_Node(node.xbox, setindex(node.tbox, interval(inf(node.tbox[t_index]), mid_point), t_index))
        right_box = Box_Node(node.xbox, setindex(node.tbox, interval(mid_point, sup(node.tbox[t_index])), t_index))
    end
    return [left_box, right_box]
end

function p_icgo(P::Problem{nx,nt,T}, epsilon::Number=0.2, delta::Number=0.1, maxiter::Int=20000, prec::Number=0, 
    W::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing, O::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing) where {nx,nt,T}
    
    if isnothing(W)      
        W = initialize_W(P)
    end
    if isnothing(O)
        O = []
    end
    k = 0

    while length(W)>0 && k<maxiter
        k = k + 1
        k % 50 == 0 && println("Iteration: ", k, " |W|: ", length(W), " |O|: ", length(O))
        # select box in fifo scheme
        index = 1
        current_node = W[index]
        if current_node.l_omega > 0
            deleteat!(W, index) # discard current node
        else 
            # Generate sublist
            sublist = [node for node in vcat(W, O) if any([intersect_interval(current_node.tbox[i], node.tbox[i])!==emptyinterval() for i in eachindex(current_node.tbox)])]
            _, index_hat = findmin(improvementfunction_lb(P, node, current_node, 0) for node in sublist)
            b_hat_node = sublist[index_hat]
            y_hat = mid.(b_hat_node.xbox)
            if max(bounding_omega(P, y_hat, current_node.tbox)[2], bounding_f(P, y_hat, current_node.tbox)[2] - current_node.l_f) < 0
                deleteat!(W, index) # discard current node
            else
                if current_node.u_omega < delta
                        value_check, _ = findmin(improvementfunction_lb(P, node, current_node, epsilon) for node in sublist)
                        if value_check >= 0
                            push!(O,popat!(W, index)) # discard current node and append it to approximation
                        end
                end
                if length(W) >= index && W[index] === current_node
                    deleteat!(W, index) # discard current node
                    if b_hat_node !== current_node && width(b_hat_node) > width(current_node)*0.1
                        l_w = length(W)
                        filter!(node -> node !== b_hat_node, W) # remove b_hat_node from W
                        b_hat_in_W = true
                        if length(W) == l_w # if b_hat_node was not in W, remove it from O
                            filter!(node -> node !== b_hat_node, O)
                            b_hat_in_W = false
                        end
                        b_hat_children = partition(b_hat_node)
                        for child in b_hat_children
                            child.l_omega, child.u_omega = bounding_omega(P, child.xbox, child.tbox)
                            child.l_f, child.u_f = bounding_f(P, child.xbox, child.tbox)
                            if b_hat_in_W
                                push!(W, child)
                            else
                                push!(O, child)
                            end
                        end
                    end
                    current_node_children = partition(current_node)
                    for child in current_node_children
                        child.l_omega, child.u_omega = bounding_omega(P, child.xbox, child.tbox)
                        child.l_f, child.u_f = bounding_f(P, child.xbox, child.tbox)
                        push!(W, child)
                    end
                end
            end 
        end
    end
    return O, W
end





