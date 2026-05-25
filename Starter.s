// ========================================================================================
//     TEAM  INFO
// Group member 1 name: Riya Bhatia
// Group member 1 PID: A18371861
// Group member 2 name: Calvin Hu
// Group member 2 PID: A19112164
// ========================================================================================

// ========================================================================================
// This is the data loading and runInference code. DO NOT MODIFY. 
// You can edit or run your own test cases by modifying the .txt data files
// ========================================================================================
// Load the initialized input matrices
LDA     X0, a
LDA     X1, b
LDA     X2, c
LDA     X3, stride
LDA     X4, base

LDUR    X5, [X3, #0] // load stride
ADD     X3, X5, XZR  // Set n = stride
LDUR    X4, [X4, #0] // load base 

runInference:
        // Input:
        //  X0: The address of (pointer to) the first value of matirx A.
        //  X1: The address of (pointer to) the first value of matirx B.
        //  X2: The address of (pointer to) the first value of matirx C.
        //  X3: The current matrix size needed (n)
        //  X4: The base
        //  X5: The stride of the matrices

        BL     recBlockMul

        // Print trace
        ADDI   X1, XZR, #10      // X1 = newline character
        PUTCHAR X1
        ADD    X1, X0, XZR       // X1 = trace value returned in X0
        PUTINT X1
        ADDI   X1, XZR, #10      // newline
        PUTCHAR X1

        // Print result matrix C
        LDA    X0, c               // base address of result matrix
        LDA    X6, stride          // load stride's address
        LDUR    X1, [X6, #0]       // set n = stride
        LDUR    X2, [X6, #0]       // set stride
        
        BL     PRINTMATRIX

        STOP

// ========================================================================================





////////////////////////////////
//                            //
//       getAddr              //
//                            //
////////////////////////////////
getAddr:
        //  Input:
        //  X5: The address of (pointer to) the first value of the matirx.
        //  X6: The row of the element(0 indexed).
        //  X7: The column of the element(0 indexed).
        //  X8: The stride of the matirx(how many elements to skip to get to the next row).

        //   Output:
        //   X5: The address of (pointer to) the desired element of the matrix.

        //YOUR CODE STARTS HERE
        MUL X12, X6, X8  //calculating row*stride
        ADD X12, X12, X7  //add the column for offset
        LSL X12, X12, #3 //offset should be *8
        ADD X5, X5, X12 //final element
        BR LR
        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//       baseMultiplyAdd      //
//                            //
////////////////////////////////
baseMultiplyAdd:
        //  Input:
        //  X0: The address of (pointer to) the first value of matirx A.
        //  X1: The address of (pointer to) the first value of matirx B.
        //  X2: The address of (pointer to) the first value of matirx C.
        //  X3: n
        //  X4: The stride of the matrices
        //
        //  Output:
        //  X0: The trace of the resulting n*n block of C.

        //YOUR CODE STARTS HERE
        SUBI SP, SP, #112
        STUR LR, [SP, #0]
        STUR FP, [SP, #8]
        ADD FP, SP, XZR
        STUR FP, [SP, #8]
        ADD FP, SP, XZR
        STUR X19, [SP, #16]
        STUR X20, [SP, #24]
        STUR X21, [SP, #32]
        STUR X22, [SP, #40]
        STUR X23, [SP, #48]
        STUR X24, [SP, #56]
        STUR X25, [SP, #64]
        STUR X26, [SP, #72]
        STUR X3,  [SP, #80]     // Store n
        STUR X4,  [SP, #88]     // Store stride

        ADD X19, X0, XZR        // X19 = A
        ADD X20, X1, XZR        // X20 = B
        ADD X21, X2, XZR        // X21 = C
        ADD X25, XZR, XZR       // X25 = t = 0
        ADD X22, XZR, XZR       // X22 = i = 0

loop_i:
        LDUR X3, [SP, #80]
        CMP X22, X3
        B.GE part2done
        ADD X23, XZR, XZR       // X23 = j = 0
loop_j:
        LDUR X3, [SP, #80]
        CMP X23, X3
        B.GE part2_j_done
        ADD X26, XZR, XZR       // X26 = sum = 0
        ADD X24, XZR, XZR       // X24 = k = 0
loop_k:
        LDUR X3, [SP, #80]
        CMP X24, X3
        B.GE part2_k_done
        // getAdder(A, i, k, stride)
        ADD X5, X19, XZR
        ADD X6, X22, XZR
        ADD X7, X24, XZR
        LDUR X8, [SP, #88]
        BL getAddr
        LDUR X9, [X5, #0]
        STUR X9, [SP, #96]

        // getAddr(B, k, j, stride)
        ADD X5, X20, XZR
        ADD X6, X24, XZR
        ADD X7, X23, XZR
        LDUR X8, [SP, #88]
        BL getAddr

        LDUR X10, [X5, #0]      // B[k][j]
        LDUR X9, [SP, #96]      // Restore A[i][k]
        MUL X11, X9, X10        // A * B
        ADD X26, X26, X11       // sum += A * B
        ADDI X24, X24, #1       // increment k

part2_k_done:
        // getAddr(C, i, j, stride)
        ADD X5, X21, XZR
        ADD X6, X22, XZR
        ADD X7, X23, XZR
        LDUR X8, [SP, #88]
        BL getAddr
        LDUR X9, [X5, #0]       // C[i][j]
        ADD X9, X9, X26         // C[i][j] + sum
        STUR X9, [X5, #0]       // C[i][j] += sum

        ADDI X23, X23, #1       // increment j
        B loop_j

part2_j_done:
        // getAddr(C, i, i, stride)
        ADD X5, X21, XZR
        ADD X6, X22, XZR
        ADD X7, X22, XZR
        LDUR X8, [SP, #88]
        BL getAddr
        LDUR X9, [X5, #0]
        ADD X25, X25, X9        // t += C[i][i]

        ADDI X22, X22, #1       // increment i
        B loop_i

part2done:
        ADD X0, X25, XZR        // return t

        LDUR X26, [SP, #72]
        LDUR X25, [SP, #64]
        LDUR X24, [SP, #56]
        LDUR X23, [SP, #48]
        LDUR X22, [SP, #40]
        LDUR X21, [SP, #32]
        LDUR X20, [SP, #24]
        LDUR X19, [SP, #16]
        LDUR FP, [SP, #8]
        LDUR LR, [SP, #0]
        ADDI SP, SP, #112
        BR LR
        
        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//       splitOffset          //
//                            //
////////////////////////////////
splitOffset:
        //  Input:
        //  X0: The address of (pointer to) the first value of the matirx.
        //  X1: n
        //  X2: 0-3 corresponding to the four quadrant of the matrix.
        //  X3: stride

        //   Output:
        //   X8: The address of (pointer to) the desired submatrix.


        //YOUR CODE STARTS HERE
        LSR X7, X1, #1  //divide by two by doing logical shift (half = n/2)
        CBNZ X2, caseNonZero
        ADD X8, X0, XZR //if quad == 0, return x8 as is (pointing to the base)
        BR 

        caseNonZero:
        ADD X4, XZR, #1 //for quadrant == 1 store in x4
        ADD X5, XZR, #2 //for quadrant == 2 store in x5
        ADD X6, XZR, #3 //for quadrant == 3 store in x6

        MUL X9, X7, X3 //half * stride 

        CMP X2, X4
        B.EQ case1

        CMP X2, X5
        B.EQ case2

        //if quad != 0, 1, 2
        ADD X9, X9, X7 //half*stride + half
        LSL X9, X9, #3  //offset *8
        ADD X8, X0, X9  //result = base + (half*stride+half)*8

        case1:
        LSL X7, X7, #3  //half*8
        ADD X8, X0, X7 //if quad == 1, result = base + half
        BR LR

        case2: 
        LSL X9, X9, #3  //8*(half*stride) offset calc
        ADD X8, X0, X9 //if quad == 2, result = base + (half*stride) 
        BR LR


        //YOUR CODE ENDS HERE





////////////////////////////////
//                            //
//       recBlockMul          //
//                            //
////////////////////////////////
recBlockMul:
        //  Input:
        //  X0: address of matrix A
        //  X1: address of matrix B
        //  X2: address of matrix C
        //  X3: current n
        //  X4: base
        //  X5: stride
        //
        //  Output:
        //  X0: sum of traces of all diagonal base-case blocks

        //YOUR CODE STARTS HERE



        //YOUR CODE ENDS HERE






// ========================================================================================
// Functions after this are for printing results. DO NOT MODIFY
// ========================================================================================
PRINTMATRIX:
        // Input:
        // X0: base address of matrix
        // X1: n (matrix dimension)
        // X2: stride

        SUBI   SP, SP, #40
        STUR   FP, [SP, #0]
        ADDI   FP, SP, #8
        STUR   LR, [SP, #8]

        // Save parameters
        STUR   X0, [SP, #16]     // save base
        STUR   X1, [SP, #24]     // save n
        STUR   X2, [SP, #32]     // save stride

        ADDI   X5, XZR, #32      // X5 = space character
        ADDI   X6, XZR, #10      // X6 = newline character
        ADDI   X3, XZR, #0       // i = 0 (row counter)

ROW_LOOP:
        LDUR   X1, [SP, #24]     // load n
        CMP    X3, X1            // if i >= n, done
        B.GE   PRINT_DONE

        ADDI   X4, XZR, #0       // j = 0 (col counter)

COL_LOOP:
        LDUR   X1, [SP, #24]     // load n
        CMP    X4, X1            // if j >= n, end row
        B.GE   END_ROW

        // Calculate address: base + (i * stride + j) * 8
        LDUR   X7, [SP, #16]     // load base
        MUL    X19, X3, X2       // i * stride
        ADD    X19, X19, X4      // i * stride + j
        LSL    X19, X19, #3      // * 8 for byte offset
        ADD    X7, X7, X19       // final address

        // Load and print value
        LDUR   X1, [X7, #0]      // load matrix[i][j]
        PUTINT X1

        // Print space
        PUTCHAR X5

        // j++
        ADDI   X4, X4, #1
        B      COL_LOOP

END_ROW:
        // Print newline
        PUTCHAR X6

        // i++
        ADDI   X3, X3, #1
        B      ROW_LOOP

PRINT_DONE:
        LDUR   LR, [SP, #8]
        LDUR   FP, [SP, #0]
        ADDI   SP, SP, #40
        BR     LR
