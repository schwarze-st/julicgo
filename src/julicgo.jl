using StaticArrays, IntervalArithmetic

mutable struct Problem{nx,nt,T}
  f      :: Function                        # f( x::SVector{nx,Interval{T}},  t::SVector{nt,Interval{T}} )
  g      :: Tuple{Vararg{Function}}           # list g_i(x,t) ≤ 0
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
  width  :: Union{T, Nothing}            # width of box (max diameter of intervals in xbox and tbox)
end

function Box_Node(xbox::SVector{nx, Interval{T}}, tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    Box_Node{nx,nt,T}(xbox, tbox, nothing, nothing, nothing, nothing, nothing)
end

@inline diam(iv::Interval{T}) where {T} = sup(iv) - inf(iv)

function width(box::Box_Node{nx,nt,T}) where {nx,nt,T}
    max_width = -Inf
    @inbounds for i in eachindex(box.xbox)
        w = diam(box.xbox[i])
        if w > max_width
            max_width = w
        end
    end
    @inbounds for i in eachindex(box.tbox)
        w = diam(box.tbox[i])
        if w > max_width
            max_width = w
        end
    end
    return max_width
end

@inline function omega(
    P::Problem{nx,nt,T}, 
    x::SVector{nx,T}, 
    t::SVector{nt,T}) where {nx,nt,T<:Real}

    max_val = -Inf
    @inbounds for g_i in P.g
        val = g_i(x,t)
        if val > max_val
            max_val = val
        end
    end
    return max_val
end

@inline function bounding_omega(
    P::Problem{nx,nt,T},
    xbox::SVector{nx, Interval{T}},
    tbox::SVector{nt, Interval{T}}
  ) where {nx,nt,T}

  lo = -Inf
  hi = -Inf

  @inbounds for g_i in P.g
    iv = g_i(xbox, tbox)          
    v_lo = inf(iv)                
    v_hi = sup(iv)                
    if v_lo > lo; lo = v_lo; end  
    if v_hi > hi; hi = v_hi; end
  end

  return lo, hi
end

@inline function bounding_omega(
    P::Problem{nx,nt,T},
    x::MVector{nx,T},
    tbox::SVector{nt, Interval{T}}
  ) where {nx,nt,T}

  lo = -Inf
  hi = -Inf

  @inbounds for g_i in P.g
    iv = g_i(x, tbox)
    v_lo = inf(iv)
    v_hi = sup(iv)
    if v_lo > lo; lo = v_lo; end
    if v_hi > hi; hi = v_hi; end
  end

  return lo, hi
end


@inline function bounding_f(P::Problem{nx,nt,T}, xbox::SVector{nx, Interval{T}}, 
    tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    interval = P.f(xbox, tbox)
    return inf(interval), sup(interval)
end

@inline function bounding_f(P::Problem{nx,nt,T}, x::MVector{nx,T}, tbox::SVector{nt, Interval{T}}) where {nx,nt,T<:Real}
    interval = P.f(x, tbox)
    return inf(interval), sup(interval)
end

function initialize_W(P::Problem{nx,nt,T}) where {nx,nt,T}
    x_comp = SVector{nx, Interval{T}}([interval(P.lowerx[i],P.upperx[i]) for i in eachindex(P.lowerx)]...)
    t_comp = SVector{nt, Interval{T}}([interval(P.lowert[i],P.uppert[i]) for i in eachindex(P.lowert)]...)
    first_node = Box_Node(x_comp, t_comp)
    first_node.l_omega, first_node.u_omega = bounding_omega(P, x_comp, t_comp)
    first_node.l_f, first_node.u_f = bounding_f(P, x_comp, t_comp)
    first_node.width = width(first_node)
    return [first_node]
end

function improvementfunction_lb(P::Problem{nx,nt,T}, node::Box_Node{nx,nt,T}, current_node::Box_Node{nx,nt,T}, epsilon::Number) where {nx,nt,T}
    left = bounding_omega(P, node.xbox, current_node.tbox)[1]
    right = bounding_f(P, node.xbox, current_node.tbox)[1] - current_node.u_f
    return max(left, right), max(left,right+epsilon)
end

@inline function overlaps(tbox1::SVector{nt, Interval{T}}, tbox2::SVector{nt, Interval{T}}) where {nt,T}
  @inbounds for j in eachindex(tbox1)
    if intersect_interval(tbox1[j], tbox2[j]) !== emptyinterval()
      return true
    end
  end
  return false
end

@inline function partition(node::Box_Node{nx,nt,T}) where {nx,nt,T}
    maxw = zero(T)
    mode = 1     # 1 = xbox, 2 = tbox
    idx  = 1     # Index in der jeweiligen SVector
    @inbounds for i in 1:nx
        w = diam(node.xbox[i])
        if w > maxw
            maxw = w
            mode = 1
            idx  = i
        end
    end
    @inbounds for j in 1:nt
        w = diam(node.tbox[j])
        if w > maxw
            maxw = w
            mode = 2
            idx  = j
        end
    end
    # biscetion
    if mode == 1
        iv     = node.xbox[idx]
        lo, hi = inf(iv), sup(iv)
        m      = mid(iv)
        left_x  = setindex(node.xbox, interval(lo, m), idx)
        right_x = setindex(node.xbox, interval(m, hi), idx)
        left  = Box_Node(left_x,  node.tbox)
        right = Box_Node(right_x, node.tbox)
    else
        iv     = node.tbox[idx]
        lo, hi = inf(iv), sup(iv)
        m      = mid(iv)
        left_t  = setindex(node.tbox, interval(lo, m), idx)
        right_t = setindex(node.tbox, interval(m, hi), idx)
        left  = Box_Node(node.xbox, left_t)
        right = Box_Node(node.xbox, right_t)
    end
    return left, right
end


function p_icgo(P::Problem{nx,nt,T}, epsilon::Number=0.2, delta::Number=0.1, maxiter::Int=100000, minwidth::Number=1e-3,
    W::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing, O::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing) where {nx,nt,T}
    
    if isnothing(W)   
        W = initialize_W(P)
    end
    if isnothing(O)
        O = []
        O_init = []
    end
    sizehint!(W, 10_000)
    sizehint!(O, 10_000)
    sizehint!(O_init, 1_000)
    y_hat = MVector{nx,T}(undef) # preallocation for midpoints of b_hat_node
    k = 0
    current_ind = 1

    
    while length(W)>=current_ind && k<maxiter
        k = k + 1
        # select box in fifo scheme
        while W[current_ind].width < minwidth
            current_ind = current_ind + 1
            if length(W) < current_ind
                break
            end
        end
        if length(W) < current_ind
            break
        end
        current_node = W[current_ind]
        if current_node.l_omega > 0
            deleteat!(W, current_ind) # discard current node
        else 
            bestval_hat = Inf
            bestval_check = Inf
            hat_in_W = true
            hat_index = 0
            @inbounds for (i,node) in enumerate(W)
                if overlaps(current_node.tbox, node.tbox)
                    val, val_eps = improvementfunction_lb(P, node, current_node, epsilon)
                    if val < bestval_hat
                        bestval_hat = val
                        hat_index = i
                    end
                    if val_eps < bestval_check
                        bestval_check = val_eps
                    end
                end
            end
            @inbounds for (i,node) in enumerate(O)
                if overlaps(current_node.tbox, node.tbox)
                    val, val_eps = improvementfunction_lb(P, node, current_node, epsilon)
                    if val < bestval_hat
                        bestval_hat = val
                        hat_index = i
                        hat_in_W = false
                    end
                    if val_eps < bestval_check
                        bestval_check = val_eps
                    end
                end
            end
            if hat_in_W
                b_hat_node = W[hat_index]
            else
                b_hat_node = O[hat_index]
            end    
            y_hat .= mid.(b_hat_node.xbox)
            if max(bounding_omega(P, y_hat, current_node.tbox)[2], bounding_f(P, y_hat, current_node.tbox)[2] - current_node.l_f) < 0
                deleteat!(W, current_ind) # discard current node
            else
                if current_node.u_omega < delta && bestval_check >= 0
                    deleteat!(W, current_ind) # discard current node
                    push!(O_init, current_node) # move current node from W to O
                    push!(O, current_node)
                else
                    if b_hat_node !== current_node && width(b_hat_node) > width(current_node)*0.1
                        if hat_in_W
                            if current_ind < hat_index
                                deleteat!(W, [current_ind, hat_index])
                            else
                                deleteat!(W, [hat_index, current_ind])
                            end
                        else
                            deleteat!(O, hat_index)
                            deleteat!(W, current_ind)
                        end
                        b_hat_children = partition(b_hat_node)
                        @inbounds for child in b_hat_children
                            child.l_omega, child.u_omega = bounding_omega(P, child.xbox, child.tbox)
                            child.l_f, child.u_f = bounding_f(P, child.xbox, child.tbox)
                            child.width = width(child)
                            if hat_in_W
                                push!(W, child)
                            else
                                push!(O, child)
                            end
                        end
                    else
                        deleteat!(W, current_ind)
                    end
                    current_node_children = partition(current_node)
                    @inbounds for child in current_node_children
                        child.l_omega, child.u_omega = bounding_omega(P, child.xbox, child.tbox)
                        child.l_f, child.u_f = bounding_f(P, child.xbox, child.tbox)
                        child.width = width(child)
                        push!(W, child)
                    end
                end
            end 
        end
    end
    return O, O_init, W, k
end





