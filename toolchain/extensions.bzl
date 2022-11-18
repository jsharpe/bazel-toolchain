"""Entry point for extensions used by bzlmod."""

load("//toolchain:rules.bzl", "llvm_toolchain")

def _init(module_ctx):
    llvm_toolchain(name = "llvm_toolchain", llvm_version = "14.0.0")

toolchain = module_extension(implementation = _init)
