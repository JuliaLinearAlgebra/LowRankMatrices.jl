module LowRankMatricesSparseArraysExt

using LowRankMatrices: LowRankMatrix
using SparseArrays: SparseMatrixCSC
using LinearAlgebra: rank, mul!

function Base.:*(L::LowRankMatrix, A::SparseMatrixCSC)
    V = zeros(promote_type(eltype(L), eltype(A)), size(A, 2), rank(L))
    mul!(V, transpose(A), L.V)
    LowRankMatrix(copy(L.U), V)
end

function Base.:*(A::SparseMatrixCSC, L::LowRankMatrix)
    U = zeros(promote_type(eltype(A), eltype(L)), size(A, 1), rank(L))
    mul!(U, A, L.U)
    LowRankMatrix(U, copy(L.V))
end

end
