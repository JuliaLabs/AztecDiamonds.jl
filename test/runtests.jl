using TestItemRunner, CUDA

iscuda((; tags)) = :cuda in tags

if !(haskey(ENV, "BUILDKITE") && CUDA.functional()) # skip non-gpu tests on Buildkite CI
    @run_package_tests filter=!iscuda #verbose=true
end

if CUDA.functional()
    @run_package_tests filter=iscuda #verbose=true
end
