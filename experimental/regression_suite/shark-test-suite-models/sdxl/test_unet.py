# Copyright 2024 Advanced Micro Devices, Inc.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import pytest
from ireers import *
import os
import setuptools

repo_root = os.getenv("TEST_SUITE_REPO_ROOT")
current_dir = repo_root + "/iree_special_models/sdxl/scheduled-unet"
iree_test_path_extension = os.getenv("IREE_TEST_PATH_EXTENSION", default=current_dir)
rocm_chip = os.getenv("ROCM_CHIP", default="gfx90a")

###############################################################################
# Fixtures
###############################################################################

sdxl_unet_inference_input_0 = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/inference_input.0.bin",
    group="sdxl_unet_inference_input_0",
)

sdxl_unet_inference_input_1 = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/inference_input.1.bin",
    group="sdxl_unet_inference_input_1",
)

sdxl_unet_inference_input_2 = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/inference_input.2.bin",
    group="sdxl_unet_inference_input_2",
)

sdxl_unet_inference_input_3 = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/inference_input.3.bin",
    group="sdxl_unet_inference_input_3",
)

sdxl_unet_inference_output_0 = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/inference_output.0.bin",
    group="sdxl_unet_inference_output_0",
)

sdxl_unet_real_weights = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/real_weights.irpa",
    group="sdxl_unet_real_weights",
)

sdxl_unet_mlir = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/model.mlirbc",
    group="sdxl_unet_mlir",
)

sdxl_unet_pipeline_mlir = fetch_source_fixture(
    "https://sharkpublic.blob.core.windows.net/sharkpublic/sai/sdxl-scheduled-unet/sdxl_unet_pipeline_bench_f16.mlir",
    group="sdxl_unet_pipeline_mlir",
)

CPU_COMPILE_FLAGS = [
    "--iree-hal-target-backends=llvm-cpu",
    "--iree-llvmcpu-target-cpu-features=host",
    "--iree-llvmcpu-fail-on-out-of-bounds-stack-allocation=false",
    "--iree-llvmcpu-distribution-size=32",
    "--iree-opt-const-eval=false",
    "--iree-llvmcpu-enable-ukernels=all",
    "--iree-global-opt-enable-quantized-matmul-reassociation",
]

COMMON_RUN_FLAGS = [
    f"--input=1x4x128x128xf16=@{sdxl_unet_inference_input_0.path}",
    f"--input=2x64x2048xf16=@{sdxl_unet_inference_input_1.path}",
    f"--input=2x1280xf16=@{sdxl_unet_inference_input_2.path}",
    f"--input=1xf16=@{sdxl_unet_inference_input_3.path}",
    f"--expected_output=1x4x128x128xf16=@{sdxl_unet_inference_output_0.path}",
]

ROCM_COMPILE_FLAGS = [
    "--iree-hal-target-backends=rocm",
    f"--iree-rocm-target-chip={rocm_chip}",
    "--iree-opt-const-eval=false",
    f"--iree-codegen-transform-dialect-library={iree_test_path_extension}/attention_and_matmul_spec.mlir",
    "--iree-global-opt-propagate-transposes=true",
    "--iree-global-opt-enable-fuse-horizontal-contractions=true",
    "--iree-flow-enable-aggressive-fusion=true",
    "--iree-opt-aggressively-propagate-transposes=true",
    "--iree-opt-outer-dim-concat=true",
    "--iree-vm-target-truncate-unsupported-floats",
    "--iree-llvmgpu-enable-prefetch=true",
    "--iree-opt-data-tiling=false",
    "--iree-codegen-gpu-native-math-precision=true",
    "--iree-codegen-llvmgpu-use-vector-distribution",
    "--iree-rocm-waves-per-eu=2",
    "--iree-execution-model=async-external",
    "--iree-preprocessing-pass-pipeline=builtin.module(iree-preprocessing-transpose-convolution-pipeline, util.func(iree-preprocessing-pad-to-intrinsics))",
    "--iree-scheduling-dump-statistics-format=json",
    "--iree-scheduling-dump-statistics-file=compilation_info.json",
]

ROCM_PIPELINE_COMPILE_FLAGS = [
    "--iree-hal-target-backends=rocm",
    f"--iree-rocm-target-chip={rocm_chip}",
    "--verify=false",
    "--iree-opt-const-eval=false",
]

###############################################################################
# CPU
###############################################################################

pipeline_cpu_vmfb = None
cpu_vmfb = None


def test_compile_unet_pipeline_cpu():
    pipeline_cpu_vmfb = iree_compile(
        sdxl_unet_pipeline_mlir,
        "cpu",
        CPU_COMPILE_FLAGS,
    )


def test_compile_unet_cpu():
    cpu_vmfb = iree_compile(sdxl_unet_mlir, "cpu", CPU_COMPILE_FLAGS)


@pytest.mark.depends(on=["test_compile_unet_pipeline_cpu", "test_compile_unet_cpu"])
def test_run_unet_cpu():
    return iree_run_module(
        cpu_vmfb,
        device="local-task",
        function="produce_image_latents",
        args=[
            f"--parameters=model={sdxl_unet_real_weights.path}",
            f"--module={pipeline_cpu_vmfb.path}",
            "--expected_f16_threshold=0.8f",
        ]
        + COMMON_RUN_FLAGS,
    )


###############################################################################
# ROCM
###############################################################################

pipeline_rocm_vmfb = None
rocm_vmfb = None


def test_compile_unet_pipeline_rocm():
    pipeline_rocm_vmfb = iree_compile(
        sdxl_unet_pipeline_mlir,
        f"rocm_{rocm_chip}",
        ROCM_PIPELINE_COMPILE_FLAGS,
    )


def test_compile_unet_rocm():
    rocm_vmfb = iree_compile(sdxl_unet_mlir, f"rocm_{rocm_chip}", ROCM_COMPILE_FLAGS)


@pytest.mark.depends(on=["test_compile_unet_pipeline_rocm", "test_compile_unet_rocm"])
def test_run_unet_rocm():
    return iree_run_module(
        rocm_vmfb,
        device="hip",
        function="produce_image_latents",
        args=[
            f"--parameters=model={sdxl_unet_real_weights.path}",
            f"--module={pipeline_rocm_vmfb.path}",
            "--expected_f16_threshold=0.7f",
        ]
        + COMMON_RUN_FLAGS,
    )
