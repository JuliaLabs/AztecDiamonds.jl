# TODO: remove once TestItemRunner v0.2.2 is released
import Pkg; Pkg.add(Pkg.PackageSpec(; name="TestItemRunner", rev="main"))
using TestItemRunner, CUDA

iscuda((; tags)) = :cuda in tags

if !(haskey(ENV, "BUILDKITE") && CUDA.functional()) # skip non-gpu tests on Buildkite CI
    @run_package_tests filter=!iscuda verbose=true
end

if CUDA.functional()
    @run_package_tests filter=iscuda verbose=true
end
