using StaticArrays, IntervalArithmetic

struct Problem{nx,nt,T}
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
  x_prime :: Union{SVector{nx, T},Nothing}              # incumbent in that box
  t_prime :: Union{SVector{nt, T},Nothing}              # incumbent in that box
  f_prime :: Union{T, Nothing}           # f value at incumbent
end

Box_Node(xbox, tbox) = Box_Node{length(xbox), length(tbox), eltype(xbox[1])}(xbox, tbox, nothing, nothing, nothing, nothing, nothing, nothing)  

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

function bounding_f(P::Problem{nx,nt,T}, xbox::SVector{nx, Interval{T}}, 
    tbox::SVector{nt, Interval{T}}) where {nx,nt,T}
    interval = P.f(xbox, tbox)
    return inf(interval), sup(interval)
end

function update_x_prime(
    P::Problem{nx,nt,T}, x_comp::SVector{nx, Interval{T}}, t_comp::SVector{nt, Interval{T}}, 
    x_prime::Union{SVector{nx, T},Nothing}, t_prime::Union{SVector{nt, T},Nothing}, 
    f_prime::T) where {nx,nt,T}
    x_mid = mid.(x_comp)
    t_mid = mid.(t_comp)
    if maximum([g_i(x_mid, t_mid) for g_i in P.g]) < 0
        f_mid = P.f(x_mid,t_mid)
        if f_mid<f_prime
            return x_mid, t_mid, f_mid
        else
            return x_prime, t_prime, f_prime
        end
    else
        return x_prime, t_prime, f_prime
    end
end

function initialize_W(P::Problem{nx,nt,T}, W::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing) where {nx,nt,T}
    x_comp = SVector{nx, Interval{T}}([interval(P.lowerx[i],P.upperx[i]) for i in eachindex(P.lowerx)]...)
    t_comp = SVector{nt, Interval{T}}([interval(P.lowert[i],P.uppert[i]) for i in eachindex(P.lowert)]...)
    first_node = Box_Node(x_comp, t_comp)
    first_node.l_omega, first_node.u_omega = bounding_omega(P, x_comp, t_comp)
    first_node.l_f, first_node.u_f = bounding_f(P, x_comp, t_comp)
    first_node.x_prime, first_node.t_prime, first_node.f_prime = update_x_prime(P, x_comp, t_comp, nothing, nothing, Inf)
    return [first_node]
end

function p_icgo(P::Problem{nx,nt,T}, W::Union{Vector{Box_Node{nx,nt,T}},Nothing}=nothing, 
    epsilon::Number=0.1, delta::Number=0.01) where {nx,nt,T}
    
    if isnothing(W)      
        W = initialize_W(P)
    end

    #while length(W)>0
    #    # TODO
    #end
    return W
end





