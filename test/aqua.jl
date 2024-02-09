using Aqua
using LowRankMatrices
using Test

@testset "Project quality" begin
    Aqua.test_all(LowRankMatrices)
end
