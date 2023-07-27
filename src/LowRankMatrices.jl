module LowRankMatrices

import Base: similar, convert, promote_rule, size, fill!, getindex,
				*, +, -, \, /,
				Matrix, copy, copyto!

using LinearAlgebra
import LinearAlgebra: rank, transpose, adjoint, mul!

export LowRankMatrix

include("lowrankmatrix.jl")

if !isdefined(Base, :get_extension)
    include("../ext/LowRankMatricesFillArraysExt.jl")
end

end
