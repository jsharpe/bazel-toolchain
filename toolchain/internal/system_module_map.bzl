# Copyright 2024 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@bazel_skylib//lib:paths.bzl", "paths")

def _system_module_map(ctx):
    module_map = ctx.actions.declare_file(ctx.attr.name + ".modulemap")

    absolute_path_dirs = []
    relative_include_prefixes = []
    for include_dir in ctx.attr.cxx_builtin_include_directories:
        if ctx.attr.sysroot_path and include_dir.startswith("%sysroot%"):
            include_dir = ctx.attr.sysroot_path + include_dir[len("%sysroot%"):]
        include_dir = paths.normalize(include_dir).replace("//", "/")
        if include_dir.startswith("/"):
            absolute_path_dirs.append(include_dir)
        else:
            relative_include_prefixes.append(include_dir + "/")

    # The builtin include directories are relative to the execroot, but the
    # paths in the module map must be relative to the directory that contains
    # the module map.
    execroot_prefix = (module_map.dirname.count("/") + 1) * "../"

    ctx.actions.run_shell(
        outputs = [module_map],
        inputs = ctx.attr.cxx_builtin_include_files[DefaultInfo].files,
        command = """
{tool} "$@" > {module_map}
""".format(
            tool = ctx.executable._generate_system_module_map.path,
            module_map = module_map.path,
        ),
        tools = [ctx.executable._generate_system_module_map],
        env = {"EXECROOT_PREFIX": execroot_prefix},
        mnemonic = "LLVMSystemModuleMap",
        progress_message = "Generating system module map",
    )
    return DefaultInfo(files = depset([module_map]))

system_module_map = rule(
    doc = """Generates a Clang module map for the toolchain and sysroot headers.""",
    implementation = _system_module_map,
    attrs = {
        "cxx_builtin_include_files": attr.label(mandatory = True),
        "cxx_builtin_include_directories": attr.string_list(mandatory = True),
        "sysroot_path": attr.string(),
        "_generate_system_module_map": attr.label(
            default = ":generate_system_module_map.sh",
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
    },
)
