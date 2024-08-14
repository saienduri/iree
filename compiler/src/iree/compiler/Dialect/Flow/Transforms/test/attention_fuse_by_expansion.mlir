// RUN: iree-opt --split-input-file --pass-pipeline="builtin.module(util.func(iree-flow-bubble-up-expand-shapes, canonicalize, cse, canonicalize))" %s | FileCheck %s

#map = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
#map1 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d2)>
#map2 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d4)>
#map3 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d4)>

util.func public @attention_static(%arg0: tensor<20x4096x16xf16>, %arg1: tensor<20x1024x16xf16>, %arg2: tensor<20x1024x64xf16>, %arg3: f16) -> tensor<2x10x4096x64xf16> {
  %0 = tensor.empty() : tensor<20x4096x64xf16>
  %1 = iree_linalg_ext.attention {indexing_maps = [#map, #map1, #map2, #map3]} ins(%arg0, %arg1, %arg2, %arg3 : tensor<20x4096x16xf16>, tensor<20x1024x16xf16>, tensor<20x1024x64xf16>, f16) outs(%0 : tensor<20x4096x64xf16>) -> tensor<20x4096x64xf16>
  %expanded = tensor.expand_shape %1 [[0, 1], [2], [3]] output_shape [2, 10, 4096, 64] : tensor<20x4096x64xf16> into tensor<2x10x4096x64xf16>
  util.return %expanded : tensor<2x10x4096x64xf16>
}

//  CHECK-DAG: #[[MAP0:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d2, d3)>
//  CHECK-DAG: #[[MAP1:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d4, d3)>
//  CHECK-DAG: #[[MAP2:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d4, d5)>
//  CHECK-DAG: #[[MAP3:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d2, d5)>
//      CHECK: func public @attention_static(
// CHECK-SAME:     %[[ARG0:[a-zA-Z0-9]+]]: tensor<20x4096x16xf16>
// CHECK-SAME:     %[[ARG1:[a-zA-Z0-9]+]]: tensor<20x1024x16xf16>
// CHECK-SAME:     %[[ARG2:[a-zA-Z0-9]+]]: tensor<20x1024x64xf16>
// CHECK-SAME:     %[[ARG3:.+]]: f16)
//  CHECK-DAG:   %[[EMPTY:.+]] = tensor.empty() : tensor<2x10x4096x64xf16>
//  CHECK-DAG:   %[[QUERY:.+]] = tensor.expand_shape %[[ARG0]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, 10, 4096, 16]
//  CHECK-DAG:   %[[KEY:.+]] = tensor.expand_shape %[[ARG1]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, 10, 1024, 16]
//  CHECK-DAG:   %[[CACHE:.+]] = tensor.expand_shape %[[ARG2]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, 10, 1024, 64]
//      CHECK:   %[[ATTENTION:.+]] = iree_linalg_ext.attention
// CHECK-SAME:       indexing_maps = [#[[MAP0]], #[[MAP1]], #[[MAP2]], #[[MAP3]]]
// CHECK-SAME:       ins(%[[QUERY]], %[[KEY]], %[[CACHE]], %[[ARG3]] :
// CHECK-SAME:       outs(%[[EMPTY]] :
//      CHECK:   util.return %[[ATTENTION]]

// -----

#map = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
#map1 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d2)>
#map2 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d4)>
#map3 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d4)>

util.func public @attention_expand_all(%arg0: tensor<20x4096x16xf16>, %arg1: tensor<20x1024x16xf16>, %arg2: tensor<20x1024x64xf16>, %arg3: f16) -> tensor<2x10x2048x2x2x32xf16> {
  %0 = tensor.empty() : tensor<20x4096x64xf16>
  %1 = iree_linalg_ext.attention {indexing_maps = [#map, #map1, #map2, #map3]} ins(%arg0, %arg1, %arg2, %arg3 : tensor<20x4096x16xf16>, tensor<20x1024x16xf16>, tensor<20x1024x64xf16>, f16) outs(%0 : tensor<20x4096x64xf16>) -> tensor<20x4096x64xf16>
  %expanded = tensor.expand_shape %1 [[0, 1], [2, 3], [4, 5]] output_shape [2, 10, 2048, 2, 2, 32] : tensor<20x4096x64xf16> into tensor<2x10x2048x2x2x32xf16>
  util.return %expanded : tensor<2x10x2048x2x2x32xf16>
}

//  CHECK-DAG: #[[MAP0:.+]] = affine_map<(d0, d1, d2, d3, d4, d5, d6, d7) -> (d0, d1, d2, d3, d4)>
//  CHECK-DAG: #[[MAP1:.+]] = affine_map<(d0, d1, d2, d3, d4, d5, d6, d7) -> (d0, d1, d5, d4)>
//  CHECK-DAG: #[[MAP2:.+]] = affine_map<(d0, d1, d2, d3, d4, d5, d6, d7) -> (d0, d1, d5, d6, d7)>
//  CHECK-DAG: #[[MAP3:.+]] = affine_map<(d0, d1, d2, d3, d4, d5, d6, d7) -> (d0, d1, d2, d3, d6, d7)>
//      CHECK: func public @attention_expand_all(
// CHECK-SAME:     %[[ARG0:[a-zA-Z0-9]+]]: tensor<20x4096x16xf16>
// CHECK-SAME:     %[[ARG1:[a-zA-Z0-9]+]]: tensor<20x1024x16xf16>
// CHECK-SAME:     %[[ARG2:[a-zA-Z0-9]+]]: tensor<20x1024x64xf16>
// CHECK-SAME:     %[[ARG3:.+]]: f16)
//  CHECK-DAG:   %[[EMPTY:.+]] = tensor.empty() : tensor<2x10x2048x2x2x32xf16>
//  CHECK-DAG:   %[[QUERY:.+]] = tensor.expand_shape %[[ARG0]] {{\[\[}}0, 1], [2, 3], [4]] output_shape [2, 10, 2048, 2, 16] : tensor<20x4096x16xf16> into tensor<2x10x2048x2x16xf16>
//  CHECK-DAG:   %[[KEY:.+]] = tensor.expand_shape %[[ARG1]] {{\[\[}}0, 1], [2], [3]] output_shape [2, 10, 1024, 16] : tensor<20x1024x16xf16> into tensor<2x10x1024x16xf16>
//  CHECK-DAG:   %[[CACHE:.+]] = tensor.expand_shape %[[ARG2]] {{\[\[}}0, 1], [2], [3, 4]] output_shape [2, 10, 1024, 2, 32] : tensor<20x1024x64xf16> into tensor<2x10x1024x2x32xf16>
//      CHECK:   %[[ATTENTION:.+]] = iree_linalg_ext.attention
// CHECK-SAME:       indexing_maps = [#[[MAP0]], #[[MAP1]], #[[MAP2]], #[[MAP3]]]
// CHECK-SAME:       ins(%[[QUERY]], %[[KEY]], %[[CACHE]], %[[ARG3]] :
// CHECK-SAME:       outs(%[[EMPTY]] :
//      CHECK:   util.return %[[ATTENTION]]

// -----


#map = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d2)>
#map1 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d2)>
#map2 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d3, d4)>
#map3 = affine_map<(d0, d1, d2, d3, d4) -> (d0, d1, d4)>

util.func public @attention_dynamic(%arg0: tensor<?x?x?xf16>, %arg1: tensor<?x?x?xf16>, %arg2: tensor<?x?x?xf16>, %arg3: f16) -> tensor<2x?x?x?xf16> {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %d0 = tensor.dim %arg0, %c0 : tensor<?x?x?xf16>
  %d1 = tensor.dim %arg0, %c1 : tensor<?x?x?xf16>
  %d2 = tensor.dim %arg0, %c2 : tensor<?x?x?xf16>
  %d3 = tensor.dim %arg1, %c1 : tensor<?x?x?xf16>
  %d4 = tensor.dim %arg2, %c2 : tensor<?x?x?xf16>
  %0 = tensor.empty(%d0, %d1, %d4) : tensor<?x?x?xf16>
  %1 = iree_linalg_ext.attention {indexing_maps = [#map, #map1, #map2, #map3]} ins(%arg0, %arg1, %arg2, %arg3 : tensor<?x?x?xf16>, tensor<?x?x?xf16>, tensor<?x?x?xf16>, f16) outs(%0 : tensor<?x?x?xf16>) -> tensor<?x?x?xf16>
  %split = arith.divsi %d0, %c2 : index
  %expanded = tensor.expand_shape %1 [[0, 1], [2], [3]] output_shape[2, %split, %d1, %d4]
      : tensor<?x?x?xf16> into tensor<2x?x?x?xf16>
  util.return %expanded : tensor<2x?x?x?xf16>
}

//  CHECK-DAG: #[[MAP0:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d2, d3)>
//  CHECK-DAG: #[[MAP1:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d4, d3)>
//  CHECK-DAG: #[[MAP2:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d4, d5)>
//  CHECK-DAG: #[[MAP3:.+]] = affine_map<(d0, d1, d2, d3, d4, d5) -> (d0, d1, d2, d5)>
//  CHECK-DAG: #[[MAP4:.+]] = affine_map<()[s0] -> (s0 floordiv 2)>
//      CHECK: func public @attention_dynamic(
// CHECK-SAME:     %[[ARG0:[a-zA-Z0-9]+]]: tensor<?x?x?xf16>
// CHECK-SAME:     %[[ARG1:[a-zA-Z0-9]+]]: tensor<?x?x?xf16>
// CHECK-SAME:     %[[ARG2:[a-zA-Z0-9]+]]: tensor<?x?x?xf16>
// CHECK-SAME:     %[[ARG3:.+]]: f16)
//  CHECK-DAG:   %[[C0:.+]] = arith.constant 0 : index
//  CHECK-DAG:   %[[C1:.+]] = arith.constant 1 : index
//  CHECK-DAG:   %[[C2:.+]] = arith.constant 2 : index
//  CHECK-DAG:   %[[D0:.+]] = tensor.dim %[[ARG0]], %[[C0]]
//  CHECK-DAG:   %[[D1:.+]] = tensor.dim %[[ARG0]], %[[C1]]
//  CHECK-DAG:   %[[D2:.+]] = tensor.dim %[[ARG0]], %[[C2]]
//  CHECK-DAG:   %[[D4:.+]] = tensor.dim %[[ARG2]], %[[C2]]
//  CHECK-DAG:   %[[SPLIT0:.+]] = arith.divui %[[D0]]
//  CHECK-DAG:   %[[VAL:.+]] = affine.apply #[[MAP4]]()[%[[D0]]]
//  CHECK-DAG:   %[[EMPTY:.+]] = tensor.empty(%[[VAL]], %[[D1]], %[[D4]]) : tensor<2x?x?x?xf16>
//  CHECK-DAG:   %[[QUERY:.+]] = tensor.expand_shape %[[ARG0]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, %[[SPLIT0]], %[[D1]], %[[D2]]]
//  CHECK-DAG:   %[[D5:.+]] = tensor.dim %[[ARG1]], %[[C0]]
//  CHECK-DAG:   %[[D6:.+]] = tensor.dim %[[ARG1]], %[[C1]]
//  CHECK-DAG:   %[[D7:.+]] = tensor.dim %[[ARG1]], %[[C2]]
//  CHECK-DAG:   %[[SPLIT1:.+]] = arith.divui %[[D5]], %[[C2]]
//  CHECK-DAG:   %[[KEY:.+]] = tensor.expand_shape %[[ARG1]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, %[[SPLIT1]], %[[D6]], %[[D7]]]
//  CHECK-DAG:   %[[D8:.+]] = tensor.dim %[[ARG2]], %[[C0]]
//  CHECK-DAG:   %[[D9:.+]] = tensor.dim %[[ARG2]], %[[C1]]
//  CHECK-DAG:   %[[SPLIT2:.+]] = arith.divui %[[D8]], %[[C2]]
//  CHECK-DAG:   %[[CACHE:.+]] = tensor.expand_shape %[[ARG2]] {{\[}}[0, 1], [2], [3]{{\]}} output_shape [2, %[[SPLIT2]], %[[D9]], %[[D4]]]
//      CHECK:   %[[ATTENTION:.+]] = iree_linalg_ext.attention
// CHECK-SAME:       indexing_maps = [#[[MAP0]], #[[MAP1]], #[[MAP2]], #[[MAP3]]]
// CHECK-SAME:       ins(%[[QUERY]], %[[KEY]], %[[CACHE]], %[[ARG3]] :
// CHECK-SAME:       outs(%[[EMPTY]] :
//      CHECK:   util.return %[[ATTENTION]]
