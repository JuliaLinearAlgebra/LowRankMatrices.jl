module LowRankMatricesFillArraysExt

using LowRankMatrices
import LowRankMatrices: LowRankMatrix
using FillArrays
using FillArrays: AbstractFill

LowRankMatrix{T}(Z::Zeros, r::Int=0) where {T<:Number} =
    LowRankMatrix(zeros(T,size(Z,1),r), zeros(T,size(Z,2),r))
LowRankMatrix{T}(Z::Zeros, r::Int=0) where {T} =
    LowRankMatrix(zeros(T,size(Z,1),r), zeros(T,size(Z,2),r))

LowRankMatrix(Z::Zeros, r::Int=0) = LowRankMatrix{eltype(Z)}(Z, r)
function LowRankMatrix{T}(F::AbstractFill) where T
    v = T(FillArrays.getindex_value(F))
    m,n = size(F)
    LowRankMatrix(fill(v,m,1), fill(one(T),n,1))
end
LowRankMatrix(F::AbstractFill{T}) where T = LowRankMatrix{T}(F)


end
