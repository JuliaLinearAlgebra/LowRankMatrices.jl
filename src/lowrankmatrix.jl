##
# Represent an m x n rank-r matrix
# A = U*Vᵗ
##
function _LowRankMatrix end

mutable struct LowRankMatrix{T} <: AbstractMatrix{T}
    U::Matrix{T} # m x r Matrix
    V::Matrix{T} # n x r Matrix

    global function _LowRankMatrix(U::AbstractMatrix{T}, V::AbstractMatrix{T}) where T
        m,r = size(U)
        n,rv = size(V)
        if r ≠ rv throw(ArgumentError("U and V must have same number of columns")) end
        new{T}(Matrix{T}(U), Matrix{T}(V))
    end
end

LowRankMatrix(U::AbstractMatrix, V::AbstractMatrix) = _LowRankMatrix(promote(U,V)...)
LowRankMatrix(U::AbstractVector, V::AbstractMatrix) = LowRankMatrix(reshape(U,length(U),1),V)
LowRankMatrix(U::AbstractMatrix, V::AbstractVector) = LowRankMatrix(U,reshape(V,length(V),1))
LowRankMatrix(U::AbstractVector, V::AbstractVector) =
    _LowRankMatrix(reshape(U,length(U),1), reshape(V,length(V),1))

LowRankMatrix{T}(::UndefInitializer, mn::NTuple{2,Int}, r::Int) where {T} =
    LowRankMatrix(Matrix{T}(undef,mn[1],r),Matrix{T}(undef,mn[2],r))

similar(L::LowRankMatrix, ::Type{T}, dims::Dims{2}) where {T} = LowRankMatrix{T}(undef, dims, rank(L))
similar(L::LowRankMatrix{T}) where {T} = LowRankMatrix{T}(undef, size(L), rank(L))
similar(L::LowRankMatrix{T}, dims::Dims{2}) where {T} = LowRankMatrix(undef, dims, rank(L))
similar(L::LowRankMatrix{T}, m::Int) where {T} = Vector{T}(undef, m)
similar(L::LowRankMatrix{T}, ::Type{S}) where {S,T} = LowRankMatrix{S}(undef, size(L), rank(L))

function LowRankMatrix{T}(A::AbstractMatrix{T}) where T
    U,Σ,V = svd(A)
    r = refactorsvd!(U,Σ,V)
    LowRankMatrix(U[:,1:r], V[:,1:r])
end

LowRankMatrix{T}(A::AbstractMatrix) where T = LowRankMatrix{T}(AbstractMatrix{T}(A))
LowRankMatrix(A::AbstractMatrix{T}) where T = LowRankMatrix{T}(A)

if !isdefined(Base, :require_one_based_indexing)
    function require_one_based_indexing(A...)
        !Base.has_offset_axes(A...) ||
            throw(ArgumentError("offset arrays are not supported but got an array with index other than 1"))
    end
else
    require_one_based_indexing(A...) = Base.require_one_based_indexing(A...)
end

# Moves Σ into U and V
function refactorsvd!(U::AbstractMatrix{S}, Σ::AbstractVector{T}, V::AbstractMatrix{S}) where {S,T}
	require_one_based_indexing(U, Σ, V)
    conj!(V)
    σmax = Σ[1]
    r = count(s->s>10σmax*eps(T),Σ)
    m,n = size(U,1),size(V,1)
    for k=1:r
        σk = sqrt(Σ[k])
        for i=1:m
            @inbounds U[i,k] *= σk
        end
        for j=1:n
            @inbounds V[j,k] *= σk
        end
    end
    r
end

function convert(::Type{LowRankMatrix{T}}, L::LowRankMatrix) where {T}
    L isa LowRankMatrix{T} && return L
    LowRankMatrix(convert(Matrix{T}, L.U), convert(Matrix{T}, L.V))
end

convert(::Type{Matrix{T}}, L::LowRankMatrix) where {T} = convert(Matrix{T}, Matrix(L))
promote_rule(::Type{LowRankMatrix{T}}, ::Type{LowRankMatrix{V}}) where {T,V} = LowRankMatrix{promote_type(T,V)}
promote_rule(::Type{LowRankMatrix{T}}, ::Type{Matrix{V}}) where {T,V} = Matrix{promote_type(T,V)}

size(L::LowRankMatrix) = size(L.U,1),size(L.V,1)
rank(L::LowRankMatrix) = size(L.U,2)
transpose(L::LowRankMatrix) = LowRankMatrix(L.V,L.U) # TODO: change for 0.7
adjoint(L::LowRankMatrix{T}) where {T<:Real} = LowRankMatrix(L.V,L.U)
adjoint(L::LowRankMatrix) = LowRankMatrix(conj(L.V),conj(L.U))
fill!(L::LowRankMatrix{T}, x::T) where {T} = (fill!(L.U, sqrt(abs(x)/rank(L))); fill!(L.V,sqrt(abs(x)/rank(L))/sign(x)); L)

function unsafe_getindex(L::LowRankMatrix, i::Int, j::Int)
    ret = zero(eltype(L))
    @inbounds for k=1:rank(L)
        ret = muladd(L.U[i,k],L.V[j,k],ret)
    end
    return ret
end

function getindex(L::LowRankMatrix, i::Int, j::Int)
    m,n = size(L)
    if 1 ≤ i ≤ m && 1 ≤ j ≤ n
        unsafe_getindex(L,i,j)
    else
        throw(BoundsError())
    end
end
getindex(L::LowRankMatrix, i::Int, jr::AbstractRange) = transpose(eltype(L)[L[i,j] for j=jr])
getindex(L::LowRankMatrix, ir::AbstractRange, j::Int) = eltype(L)[L[i,j] for i=ir]
getindex(L::LowRankMatrix, ir::AbstractRange, jr::AbstractRange) = eltype(L)[L[i,j] for i=ir,j=jr]
Matrix(L::LowRankMatrix) = L[1:size(L,1),1:size(L,2)]

# constructors

copy(L::LowRankMatrix) = LowRankMatrix(copy(L.U),copy(L.V))
copyto!(L::LowRankMatrix, N::LowRankMatrix) = (copyto!(L.U,N.U); copyto!(L.V,N.V);L)


# algebra

for op in (:+,:-)
    @eval begin
        $op(L::LowRankMatrix) = LowRankMatrix($op(L.U),L.V)

        $op(a::Bool, L::LowRankMatrix{Bool}) = error("Not callable")
        $op(L::LowRankMatrix{Bool}, a::Bool) = error("Not callable")
        $op(a::Number,L::LowRankMatrix) = $op(LowRankMatrix(Fill(a,size(L))), L)
        $op(L::LowRankMatrix,a::Number) = $op(L, LowRankMatrix(Fill(a,size(L))))

        function $op(L::LowRankMatrix, M::LowRankMatrix)
            size(L) == size(M) || throw(DimensionMismatch("A has dimensions $(size(L)) but B has dimensions $(size(M))"))
            LowRankMatrix(hcat(L.U,$op(M.U)), hcat(L.V,M.V))
        end
        $op(L::LowRankMatrix,A::Matrix) = $op(promote(L,A)...)
        $op(A::Matrix,L::LowRankMatrix) = $op(promote(A,L)...)
    end
end

*(a::Number, L::LowRankMatrix) = LowRankMatrix(a*L.U,L.V)
*(L::LowRankMatrix, a::Number) = LowRankMatrix(L.U,L.V*a)

# override default:

*(A::LowRankMatrix, B::Adjoint{T,LowRankMatrix{T}}) where T = A*adjoint(B)

function mul!(b::AbstractVector, L::LowRankMatrix, x::AbstractVector)
    temp = zeros(promote_type(eltype(L),eltype(x)), rank(L))
    mul!(temp, transpose(L.V), x)
    mul!(b, L.U, temp)
    b
end
function *(L::LowRankMatrix, M::LowRankMatrix)
    T = promote_type(eltype(L),eltype(M))
    temp = zeros(T,rank(L),rank(M))
    mul!(temp, transpose(L.V), M.U)
    V = zeros(T,size(M,2),rank(L))
    mul!(V, M.V, transpose(temp))
    LowRankMatrix(copy(L.U),V)
end



function *(L::LowRankMatrix, A::Matrix)
    V = zeros(promote_type(eltype(L),eltype(A)),size(A,2),rank(L))
    mul!(V, transpose(A), L.V)
    LowRankMatrix(copy(L.U),V)
end



function *(A::Matrix, L::LowRankMatrix)
    U = zeros(promote_type(eltype(A),eltype(L)),size(A,1),rank(L))
    mul!(U,A,L.U)
    LowRankMatrix(U,copy(L.V))
end

\(L::LowRankMatrix, b::AbstractVecOrMat) = transpose(L.V) \ (L.U \ b)
