## Adjoints Delta
@adjoint function evaluate(s::Delta, x::AbstractVector, y::AbstractVector)
  evaluate(s, x, y), Δ -> begin
    (nothing, nothing, nothing)
  end
end

@adjoint function pairwise(d::Delta, X::AbstractMatrix, Y::AbstractMatrix; dims=2)
  D = pairwise(d, X, Y; dims = dims)
  if dims == 1
      return D, Δ -> (nothing, nothing, nothing)
  else
      return D, Δ -> (nothing, nothing, nothing)
  end
end

@adjoint function pairwise(d::Delta, X::AbstractMatrix; dims=2)
  D = pairwise(d, X; dims = dims)
  if dims == 1
      return D, Δ -> (nothing, nothing)
  else
      return D, Δ -> (nothing, nothing)
  end
end

## Adjoints DotProduct
@adjoint function evaluate(s::DotProduct, x::AbstractVector, y::AbstractVector)
  dot(x, y), Δ -> begin
    (nothing, Δ .* y, Δ .* x)
  end
end

@adjoint function pairwise(d::DotProduct, X::AbstractMatrix, Y::AbstractMatrix; dims=2)
  D = pairwise(d, X, Y; dims = dims)
  if dims == 1
      return D, Δ -> (nothing, Δ * Y, (X' * Δ)')
  else
      return D, Δ -> (nothing, (Δ * Y')', X * Δ)
  end
end

@adjoint function pairwise(d::DotProduct, X::AbstractMatrix; dims=2)
  D = pairwise(d, X; dims = dims)
  if dims == 1
      return D, Δ -> (nothing, 2 * Δ * X)
  else
      return D, Δ -> (nothing, 2 * X * Δ)
  end
end

## Adjoints Sinus
@adjoint function evaluate(s::Sinus, x::AbstractVector, y::AbstractVector)
  d = (x - y)
  sind = sinpi.(d)
  val = sum(abs2, sind ./ s.r)
  gradx = 2π .* cospi.(d) .* sind ./ (s.r .^ 2)
  val, Δ -> begin
    ((r = -2Δ .* abs2.(sind) ./ s.r,), Δ * gradx, - Δ * gradx)
  end
end

@adjoint function pairwise(s::Sinus, X::AbstractMatrix, Y::AbstractMatrix; dims=2)
    D = pairwise(d, X, Y; dims = dims)
    throw(error("Sinus metric has no defined adjoint for now... PR welcome!"))
end

@adjoint function pairwise(s::Sinus, X::AbstractMatrix; dims=2)
  D = pairwise(d, X; dims = dims)
  throw(error("Sinus metric has no defined adjoint for now... PR welcome!"))
end

@adjoint function loggamma(x)
    first(logabsgamma(x)) , Δ -> (Δ .* polygamma(0, x), )
end

@adjoint function kappa(κ::MaternKernel, d::Real)
    ν = first(κ.ν)
    val, grad = pullback(_matern, ν, d)
    return ((iszero(d) ? one(d) : val),
    Δ -> begin
        ∇ = grad(Δ)
        return ((ν = [∇[1]],), iszero(d) ? zero(d) : ∇[2])
    end)
end

@adjoint function ColVecs(X::AbstractMatrix)
    back(Δ::NamedTuple) = (Δ.X,)
    back(Δ::AbstractMatrix) = (Δ,)
    function back(Δ::AbstractVector{<:AbstractVector{<:Real}})
        throw(error("In slow method"))
    end
    return ColVecs(X), back
end

@adjoint function RowVecs(X::AbstractMatrix)
    back(Δ::NamedTuple) = (Δ.X,)
    back(Δ::AbstractMatrix) = (Δ,)
    function back(Δ::AbstractVector{<:AbstractVector{<:Real}})
        throw(error("In slow method"))
    end
    return RowVecs(X), back
end

@adjoint function Base.map(t::Transform, X::ColVecs)
    pullback(_map, t, X)
end

@adjoint function Base.map(t::Transform, X::RowVecs)
    pullback(_map, t, X)
end
