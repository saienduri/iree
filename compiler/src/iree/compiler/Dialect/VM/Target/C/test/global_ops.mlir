// RUN: iree-compile --compile-mode=vm --output-format=vm-c --iree-vm-c-module-optimize=false %s | FileCheck %s

vm.module @global_ops {
  // check the generated state struct
  // CHECK-LABEL: struct global_ops_state_t {
  // CHECK-SAME: iree_allocator_t allocator;
  // CHECK-SAME: uint8_t rwdata[8];
  // CHECK-SAME: iree_vm_ref_t refs[1];
  // CHECK-SAME: iree_vm_buffer_t rodata_buffers[1];
  // CHECK-SAME: iree_vm_function_t imports[1];
  // CHECK-SAME: };

  vm.global.i32 mutable @c42 = 42 : i32
  vm.global.i32 mutable @c107_mut = 107 : i32

  vm.export @test_global_load_i32
  // CHECK: static iree_status_t global_ops_test_global_load_i32([[ARGS:[^)]*]]) {
  vm.func @test_global_load_i32() -> i32 {
    // CHECK-NEXT: struct global_ops_state_t* v5;
    // CHECK-NEXT: uint8_t* v6;
    // CHECK-NEXT: int32_t v7;
    // CHECK-NEXT: iree_status_t v8;
    // CHECK-NEXT: ;
    // CHECK-NEXT: v5 = v3;
    // CHECK-NEXT: v6 = v5->rwdata;
    // CHECK-NEXT: v7 = vm_global_load_i32(v6, 0);
    %value = vm.global.load.i32 @c42 : i32
    vm.return %value : i32
  }

  vm.export @test_global_store_i32
  // CHECK: static iree_status_t global_ops_test_global_store_i32([[ARGS:[^)]*]]) {
  vm.func @test_global_store_i32() -> i32 {
    // CHECK-NEXT: int32_t v5;
    // CHECK-NEXT: struct global_ops_state_t* v6;
    // CHECK-NEXT: uint8_t* v7;
    // CHECK-NEXT: struct global_ops_state_t* v8;
    // CHECK-NEXT: uint8_t* v9;
    // CHECK-NEXT: int32_t v10;
    // CHECK-NEXT: iree_status_t v11;
    // CHECK-NEXT: v5 = 17;
    %c17 = vm.const.i32 17
    // CHECK-NEXT: ;
    // CHECK-NEXT: v6 = v3;
    // CHECK-NEXT: v7 = v6->rwdata;
    // CHECK-NEXT: vm_global_store_i32(v7, 4, v5);
    vm.global.store.i32 %c17, @c107_mut : i32
    // CHECK-NEXT: ;
    // CHECK-NEXT: v8 = v3;
    // CHECK-NEXT: v9 = v8->rwdata;
    // CHECK-NEXT: v10 = vm_global_load_i32(v9, 4);
    %value = vm.global.load.i32 @c107_mut : i32
    vm.return %value : i32
  }
}
