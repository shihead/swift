// RUN: %empty-directory(%t)
// RUN: cp -r %S/Inputs/transitive/* %t

// rdar://problem/70012853
// XFAIL: OS=windows-msvc

//
// This test establishes a "transitive" chain of modules that import one another
// and ensures that a cross-module incremental build rebuilds all modules
// involved in the chain.
//
// Module C    Module B    Module A
// -------- -> -------- -> --------
//    |                        ^
//    |                        |
//    -------------------------
//

//
// Set up a clean incremental build of all three modules
//

// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/C.swiftmodule -enable-experimental-cross-module-incremental-build -module-name C -I %t -output-file-map %t/C.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC -DOLD %t/C.swift
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/B.swiftmodule -enable-experimental-cross-module-incremental-build -module-name B -I %t -output-file-map %t/B.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/B.swift
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/A.swiftmodule -enable-experimental-cross-module-incremental-build -module-name A -I %t -output-file-map %t/A.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/A.swift

//
// Now change C and ensure that B and A rebuild because of the change to
// an incremental external dependency.
//

// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/C.swiftmodule -enable-experimental-cross-module-incremental-build -module-name C -I %t -output-file-map %t/C.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC -DNEW %t/C.swift 2>&1 | %FileCheck -check-prefix MODULE-C %s
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/B.swiftmodule -enable-experimental-cross-module-incremental-build -module-name B -I %t -output-file-map %t/B.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/B.swift 2>&1 | %FileCheck -check-prefix MODULE-B %s
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/A.swiftmodule -enable-experimental-cross-module-incremental-build -module-name A -I %t -output-file-map %t/A.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/A.swift 2>&1 | %FileCheck -check-prefix MODULE-A %s

// MODULE-C: Incremental compilation has been disabled

// MODULE-B: Queuing because of incremental external dependencies: {compile: B.o <= B.swift}
// MODULE-B: Job finished: {compile: B.o <= B.swift}
// MODULE-B: Job finished: {merge-module: B.swiftmodule <= B.o}

// MODULE-A: Queuing because of incremental external dependencies: {compile: A.o <= A.swift}
// MODULE-A: Job finished: {compile: A.o <= A.swift}
// MODULE-A: Job finished: {merge-module: A.swiftmodule <= A.o}

//
// And ensure that the null build really is null.
//

// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/C.swiftmodule -enable-experimental-cross-module-incremental-build -module-name C -I %t -output-file-map %t/C.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC -DNEW %t/C.swift 2>&1 | %FileCheck -check-prefix MODULE-C-NULL %s
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/B.swiftmodule -enable-experimental-cross-module-incremental-build -module-name B -I %t -output-file-map %t/B.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/B.swift 2>&1 | %FileCheck -check-prefix MODULE-B-NULL %s
// RUN: cd %t && %swiftc_driver -c -incremental -emit-dependencies -emit-module -emit-module-path %t/A.swiftmodule -enable-experimental-cross-module-incremental-build -module-name A -I %t -output-file-map %t/A.json -working-directory %t -driver-show-incremental -driver-show-job-lifecycle -DUSEC %t/A.swift 2>&1 | %FileCheck -check-prefix MODULE-A-NULL %s

// MODULE-C-NULL: Job skipped: {compile: C.o <= C.swift}
// MODULE-C-NULL: Job skipped: {merge-module: C.swiftmodule <= C.o}

// MODULE-B-NULL: Job skipped: {compile: B.o <= B.swift}
// MODULE-B-NULL: Job skipped: {merge-module: B.swiftmodule <= B.o}

// MODULE-A-NULL: Job skipped: {compile: A.o <= A.swift}
// MODULE-A-NULL: Job skipped: {merge-module: A.swiftmodule <= A.o}
