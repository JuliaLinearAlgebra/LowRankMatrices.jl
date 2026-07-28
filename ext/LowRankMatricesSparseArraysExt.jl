module LowRankMatricesSparseArraysExt

using LowRankMatrices: LowRankMatrix, lowrankmul
using SparseArrays: SparseMatrixCSC

function Base.:*(L::LowRankMatrix, A::SparseMatrixCSC)
    lowrankmul(L,A)
end
function Base.:*(A::SparseMatrixCSC, L::LowRankMatrix)
    lowrankmul(A,L)
end

end
