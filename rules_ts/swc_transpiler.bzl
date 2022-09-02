load("@aspect_rules_swc//swc:defs.bzl", _swc_transpiler = "swc_transpiler")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

def swc_transpiler(name, **kwargs):
    _swc_transpiler(
        name = name,
        # exec_compatible_with = HOST_CONSTRAINTS,
        # tags = kwargs.pop("tags", []) + ["local"],
        **kwargs)
