# Flambeau
# Copyright (c) 2020 Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  std/[strutils, os]

# (Almost) raw bindings to PyTorch Tensors
# -----------------------------------------------------------------------
#
# This provides almost raw bindings to PyTorch tensors.
#
# Differences:
# - `&=`, `|=` and `^=` have been renamed bitand, bitor, bitxor
# - `index` and `index_put` have a common `[]` and `[]=` interface.
#   This allows Nim to be similar to the Python interface.
#   It also avoids exposing the "Slice" and "None" index helpers.
#
# Names were not "Nimified" (camel-cased) to ease
# searching in PyTorch and libtorch docs

# #######################################################################
#
#                          C++ Interop
#
# #######################################################################

# Libraries
# -----------------------------------------------------------------------
# I don't think we can do dynamic loading with C++11
# So link directly

const libPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/../libtorch/lib/"

when defined(windows):
  const libSuffix = ".dll"
elif defined(maxosx): # TODO check this
  const libSuffix = ".dylib" # MacOS
else:
  const libSuffix = ".so" # BSD / Linux

{.link: libPath & "libc10" & libSuffix.}
{.link: libPath & "libtorch_cpu" & libSuffix.}

# Headers
# -----------------------------------------------------------------------

const headersPath = currentSourcePath.rsplit(DirSep, 1)[0] & "/../libtorch/include"
const torchHeadersPath = headersPath / "torch/csrc/api/include"
const torchHeader = torchHeadersPath / "torch/torch.h"

{.passC: "-I" & headersPath.}
{.passC: "-I" & torchHeadersPath.}

{.push header: torchHeader.}

# TensorOptions
# -----------------------------------------------------------------------
type
  TensorOptions* {.importcpp: "torch::TensorOptions", bycopy.} = object

func init*(T: type TensorOptions): TensorOptions {.constructor,importcpp: "torch::TensorOptions".}

# Scalars
# -----------------------------------------------------------------------
# Scalars are defined in libtorch/include/c10/core/Scalar.h
# as tagged unions of double, int64, complex
# And C++ types are implicitly convertible to Scalar
#
# Hence in Nim we don't need to care about Scalar or defined converters
# (except maybe for complex)
type Scalar* = SomeNumber or bool

# Tensors
# -----------------------------------------------------------------------

type
  Tensor* {.importcpp: "torch::Tensor", byref.} = object

# Strings & Debugging
# -----------------------------------------------------------------------

proc print*(t: Tensor) {.sideeffect, importcpp: "torch::print(@)".}

# Metadata
# -----------------------------------------------------------------------

func dim*(t: Tensor): int64 {.sideeffect, importcpp: "#.dim()".}
func reset*(t: var Tensor) {.importcpp: "#.reset()".}
func `==`*(a, b: Tensor): bool {.importcpp: "#.is_same(#)".}

func ndimension*(t: Tensor): int64 {.importcpp: "#.ndimension()".}
func nbytes*(t: Tensor): uint {.importcpp: "#.nbytes()".}
func numel*(t: Tensor): int64 {.importcpp: "#.numel()".}
func itemsize*(t: Tensor): uint {.importcpp: "#.itemsize()".}
func element_size*(t: Tensor): int64 {.importcpp: "#.element_size()".}

# Backend
# -----------------------------------------------------------------------

func has_storage*(t: Tensor): bool {.importcpp: "#.has_storage()".}
func get_device*(t: Tensor): int64 {.importcpp: "#.get_device()".}
func is_cuda*(t: Tensor): bool {.importcpp: "#.is_cuda()".}
func is_hip*(t: Tensor): bool {.importcpp: "#.is_hip()".}
func is_sparse*(t: Tensor): bool {.importcpp: "#.is_sparse()".}
func is_mkldnn*(t: Tensor): bool {.importcpp: "#.is_mkldnn()".}
func is_vulkan*(t: Tensor): bool {.importcpp: "#.is_vulkan()".}
func is_quantized*(t: Tensor): bool {.importcpp: "#.is_quantized()".}
func is_meta*(t: Tensor): bool {.importcpp: "#.is_meta()".}

# Constructors
# -----------------------------------------------------------------------

func init*(T: type Tensor): Tensor {.constructor,importcpp: "torch::Tensor".}

# Indexing
# -----------------------------------------------------------------------
# libtorch/include/ATen/TensorIndexing.h
# and https://pytorch.org/cppdocs/notes/tensor_indexing.html

# Unsure what those corresponds to in Python
# func `[]`*(a: Tensor, index: Scalar): Tensor {.importcpp: "#[#]".}
# func `[]`*(a: Tensor, index: Tensor): Tensor {.importcpp: "#[#]".}
# func `[]`*(a: Tensor, index: int64): Tensor {.importcpp: "#[#]".}

func index*(a: Tensor): Tensor {.varargs, importcpp: "#.index({@})".}
  ## Tensor indexing. It is recommended
  ## to Nimify this in a high-level wrapper.
  ## `tensor.index(indexers)`

# We can't use the construct `#.index_put_({@}, #)`
# so hardcode sizes,
# 6d seems reasonable, that would be a batch of 3D videos (videoID/batchID, Time, Color Channel, Height, Width, Depth)
# If you need more you likely aren't indexing individual values.

func index_put*(a: var Tensor, i0: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.
func index_put*(a: var Tensor, i0, i1: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#, #}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.
func index_put*(a: var Tensor, i0, i1, i2: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#, #, #}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.
func index_put*(a: var Tensor, i0, i1, i2, i3: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#, #, #, #}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.
func index_put*(a: var Tensor, i0, i1, i2, i3, i4: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#, #, #, #, #}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.
func index_put*(a: var Tensor, i0, i1, i2, i3, i4, i5: auto, val: Scalar or Tensor) {.importcpp: "#.index_put_({#, #, #, #, #, #}, #)".}
  ## Tensor mutation at index. It is recommended
  ## to Nimify this in a high-level wrapper.

# Operators
# -----------------------------------------------------------------------

func `not`*(t: Tensor): Tensor {.importcpp: "~#".}
func `-`*(t: Tensor): Tensor {.importcpp: "-#".}
func `+=`*(a: var Tensor, b: Tensor) {.importcpp: "# += #".}
func `+=`*(a: var Tensor, s: Scalar) {.importcpp: "# += #".}
func `-=`*(a: var Tensor, b: Tensor) {.importcpp: "# -= #".}
func `-=`*(a: var Tensor, s: Scalar) {.importcpp: "# -= #".}
func `*=`*(a: var Tensor, b: Tensor) {.importcpp: "# *= #".}
func `*=`*(a: var Tensor, s: Scalar) {.importcpp: "# *= #".}
func `/=`*(a: var Tensor, b: Tensor) {.importcpp: "# /= #".}
func `/=`*(a: var Tensor, s: Scalar) {.importcpp: "# /= #".}
func bitand*(a: var Tensor, s: Tensor) {.importcpp: "# &= #".}
  ## In-place bitwise `and`.
func bitor*(a: var Tensor, s: Tensor) {.importcpp: "# |= #".}
  ## In-place bitwise `or`.
func bitxor*(a: var Tensor, s: Tensor) {.importcpp: "# ^= #".}
  ## In-place bitwise `xor`.

# Functions.h
# -----------------------------------------------------------------------

func eye*(n: int64): Tensor {.importcpp: "torch::eye(@)".}
