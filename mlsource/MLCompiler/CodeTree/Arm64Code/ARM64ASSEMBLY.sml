(*
    Copyright (c) 2021 David C. J. Matthews

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    Licence version 2.1 as published by the Free Software Foundation.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public Licence for more details.
    
    You should have received a copy of the GNU Lesser General Public
    Licence along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)

functor ARM64ASSEMBLY (
    structure Debug: DEBUG
    and       Pretty: PRETTYSIG
    and       CodeArray: CODEARRAYSIG
) : Arm64Assembly =

struct
    open CodeArray Address
    
    exception InternalError = Misc.InternalError
    
    exception Fallback (* Define this here in case we want to raise it. *)

    infix 5 << <<+ <<- >> >>+ >>- ~>> ~>>+ ~>>- (* Shift operators *)
    infix 3 andb orb xorb andbL orbL xorbL andb8 orb8 xorb8
    
    val op << = Word.<< and op >> = Word.>> and op ~>> = Word.~>>
    and op andb = Word.andb and op orb = Word.orb

    val wordToWord8 = Word8.fromLargeWord o Word.toLargeWord
    and word8ToWord = Word.fromLargeWord o Word8.toLargeWord
    
    type instr = word
    
    
    datatype xReg = XReg of Word8.word | XZero | XSP
    
    (* 31 in the register field can either mean the zero register or
       the hardware stack pointer.  Which meaning depends on the instruction. *)
    fun xRegOrXZ(XReg w) = w
    |   xRegOrXZ XZero = 0w31
    |   xRegOrXZ XSP = raise InternalError "XSP not valid here"
    
    and xRegOrXSP(XReg w) = w
    |   xRegOrXSP XZero = raise InternalError "XZero not valid here"
    |   xRegOrXSP XSP = 0w31
    
    (* There are cases where it isn't clear. *)
    and xRegOnly (XReg w) = w
    |   xRegOnly XZero = raise InternalError "XZero not valid here"
    |   xRegOnly XSP = raise InternalError "XSP not valid here"

    val X0  = XReg 0w0  and X1  = XReg 0w1  and X2 = XReg 0w2   and X3  = XReg 0w3
    and X4  = XReg 0w4  and X5  = XReg 0w5  and X6 = XReg 0w6   and X7  = XReg 0w7
    and X8  = XReg 0w8  and X9  = XReg 0w9  and X10= XReg 0w10  and X11 = XReg 0w11
    and X12 = XReg 0w12 and X13 = XReg 0w13 and X14= XReg 0w14  and X15 = XReg 0w15
    and X16 = XReg 0w16 and X17 = XReg 0w17 and X18= XReg 0w18  and X19 = XReg 0w19
    and X20 = XReg 0w20 and X21 = XReg 0w21 and X22= XReg 0w22  and X23 = XReg 0w23
    and X24 = XReg 0w24 and X25 = XReg 0w25 and X26= XReg 0w26  and X27 = XReg 0w27
    and X28 = XReg 0w28 and X29 = XReg 0w29 and X30= XReg 0w30
    
    val X_MLHeapLimit       = X25 (* ML Heap limit pointer *)
    and X_MLAssemblyInt     = X26 (* ML assembly interface pointer. *)
    and X_MLHeapAllocPtr    = X27 (* ML Heap allocation pointer. *)
    and X_MLStackPtr        = X28 (* ML Stack pointer. *)
    and X_LinkReg           = X30 (* Link reg - return address *)

    datatype code =
    Code of 
    {
        instructions:   instr list ref,        (* Code in reverse order. *)
        constVec:       machineWord list ref, (* Constant area constant values. *)
        functionName:   string,               (* Name of the function. *)
        printAssemblyCode:bool,               (* Whether to print the code when we finish. *)
        printStream:    string->unit          (* The stream to use *)
    }

    fun codeCreate (name, parameters) = 
    let
        val printStream = Pretty.getSimplePrinter(parameters, [])
    in
        Code
        {
            instructions     = ref nil,
            constVec         = ref [],
            functionName     = name,
            printAssemblyCode = Debug.getParameter Debug.assemblyCodeTag parameters,
            printStream    = printStream
        }
    end
    
    fun addInstr (instr, Code{instructions, ...}) =
        instructions := instr :: ! instructions

    val retCode  = 0wxD65F03C0
    and nopCode  = 0wxD503201F
    and incMLSP1 = 0wx9100239C
    
    
    fun genRetCode code = addInstr(retCode, code)
    and genIncMLSP1 code = addInstr(incMLSP1, code)
    
    (* Push a register to the ML stack. This uses a pre-increment store to x28 *)
    fun genPushReg(xReg, code) =
        addInstr(0wxF81F8F80 orb word8ToWord(xRegOnly xReg), code)
    
    (* Pop a register from the ML stack. *)
    fun genPopReg(xReg, code) =
        addInstr(0wxF8408780 orb word8ToWord(xRegOnly xReg), code)
    
    
    (* Move an unsigned constant into the low 16-bits of a register. *)
    fun genMoveShortConstToReg(xReg, constnt, code) =
    if constnt < 0 orelse constnt >= 65536
    then raise InternalError "genMoveShortConstToReg: constant out of range"
    else addInstr(0wxD2800000 orb (Word.fromInt constnt << 0w5) orb word8ToWord(xRegOnly xReg), code)
    
    (* Size of each code word. *)
    fun codeSize _ = 1 (* Number of 32-bit words *)

    fun foldCode startIc foldFn ops =
    let
        fun doFold(oper :: operList, ic) =
            doFold(operList,
                (* Get the size BEFORE any possible change. *)
                ic + Word.fromInt(codeSize oper) * 0w4 before foldFn(oper, ic))
        |   doFold(_, ic) = ic
    in
        doFold(ops, startIc)
    end

    
    fun genCode(ops, Code {constVec, ...}) =
    let
    
        (* First pass - set the labels. *)
        fun setLabelsAndSizes ops = Word.fromInt(List.length ops)
        val codeSize = setLabelsAndSizes ops (* Number of 32-bit instructions *)
        val wordsOfCode = (codeSize + 0w1) div 0w2 (* Round up to 64-bits *)
        val paddingWord = if Word.andb(codeSize, 0w1) = 0w1 then [nopCode] else []

        val segSize   = wordsOfCode + Word.fromInt(List.length(! constVec)) + 0w4 (* 4 extra words *)
        val codeVec = byteVecMake segSize


        fun genCodeWords(code, byteNo) =
        (
            (* Little-endian order *)
            byteVecSet(codeVec, byteNo, wordToWord8 code);
            byteVecSet(codeVec, byteNo+0w1, wordToWord8(code >> 0w8));
            byteVecSet(codeVec, byteNo+0w2, wordToWord8(code >> 0w16));
            byteVecSet(codeVec, byteNo+0w3, wordToWord8(code >> 0w24))
        )
        
    in
        foldCode 0w0 genCodeWords (ops @ paddingWord);
        (codeVec (* Return the completed code. *), wordsOfCode (* And the size in 64-bit words. *))
    end

    (* Store a 64-bit value in the code *)
    fun set64(value, wordNo, seg) =
    let
        val addrs = wordNo * 0w8
        fun putBytes(value, a, seg, i) =
        if i = 0w8 then ()
        else
        (
            byteVecSet(seg, a+i, Word8.fromInt(value mod 256));
            putBytes(value div 256, a, seg, i+0w1)
        )
    in
        putBytes(value, addrs, seg, 0w0)
    end
    
   
    (* Print the instructions in the code. *)
    fun printCode (codeVec, functionName, wordsOfCode, printStream) =
    let
        val numInstructions = wordsOfCode * 0w2 (* Words is number of 64-bit words *)
    
        fun printHex (v, n) =
        let
            val s = Word.fmt StringCvt.HEX v
            val pad = CharVector.tabulate(Int.max(0, n-size s), fn _ => #"0")
        in
            printStream pad; printStream s
        end


        (* Each instruction is 32-bytes. *)
        fun printWordAt wordNo =
        let
            val byteNo = wordNo << 0w2
            val () = printHex(byteNo, 6)  (* Address *)
            val () = printStream "\t"
            val wordValue =
                word8ToWord (codeVecGet (codeVec, byteNo)) orb
                (word8ToWord (codeVecGet (codeVec, byteNo+0w1)) << 0w8) orb
                (word8ToWord (codeVecGet (codeVec, byteNo+0w2)) << 0w16) orb
                (word8ToWord (codeVecGet (codeVec, byteNo+0w3)) << 0w24)
            val () = printHex(wordValue, 8) (* Instr as hex *)
            val () = printStream "\t"
        in
            if wordValue = 0wxD65F03C0
            then printStream "ret"

            else if wordValue = 0wxD503201F
            then printStream "nop"

            else if (wordValue andb 0wxffe00000) = 0wxD2800000
            then
            let
                (* Move immediate, zeroing the rest of the register and with no shift. *)
                val rD = wordValue andb 0wx1f
                val imm16 = (wordValue andb 0wx1fffe) >> 0w5
            in
                printStream "mov\tx"; printStream(Word.fmt StringCvt.DEC rD);
                printStream ",#"; printStream(Word.fmt StringCvt.DEC imm16)
            end

            else if (wordValue andb 0wxffe00c00) = 0wxF8000C00
            then
            let
                (* Store with pre-indexing *)
                val rT = wordValue andb 0wx1f
                and rN = (wordValue andb 0wx3e0) >> 0w5
                and imm9 = (wordValue andb 0wx1ff000) >> 0w12
                val imm9Text =
                    if imm9 > 0wxff
                    then "-" ^ Word.fmt StringCvt.DEC (0wx200 - imm9)
                    else Word.fmt StringCvt.DEC imm9
            in
                printStream "str\tx"; printStream(Word.fmt StringCvt.DEC rT);
                printStream ",[x"; printStream(Word.fmt StringCvt.DEC rN);
                printStream ",#"; printStream imm9Text; printStream "]!"
            end

            else if (wordValue andb 0wxffe00c00) = 0wxF8400400
            then
            let
                (* Load with post-indexing *)
                val rT = wordValue andb 0wx1f
                and rN = (wordValue andb 0wx3e0) >> 0w5
                and imm9 = (wordValue andb 0wx1ff000) >> 0w12
                val imm9Text =
                    if imm9 > 0wxff
                    then "-" ^ Word.fmt StringCvt.DEC(0wx200 - imm9)
                    else Word.fmt StringCvt.DEC imm9
            in
                printStream "ldr\tx"; printStream(Word.fmt StringCvt.DEC rT);
                printStream ",[x"; printStream(Word.fmt StringCvt.DEC rN); printStream "],#";
                printStream imm9Text
            end

            else if (wordValue andb 0wxffc00000) = 0wx91000000
            then
            let
                (* Add a 12-bit immediate with no shift. *)
                val rD = wordValue andb 0wx1f
                and rN = (wordValue andb 0wx3e0) >> 0w5
                and imm16 = (wordValue andb 0wx3ffc00) >> 0w10
            in
                printStream "add\tx"; printStream(Word.fmt StringCvt.DEC rD);
                printStream ",x"; printStream(Word.fmt StringCvt.DEC rN);
                printStream ",#"; printStream(Word.fmt StringCvt.DEC imm16)
            end

            else printStream "?"
            ;
            printStream "\n"
        end
        
        fun printAll i =
            if i = numInstructions then ()
            else (printWordAt i; printAll(i+0w1))
    in
        printStream functionName;
        printStream ":\n";
        printAll 0w0
    end

    (* Adds the constants onto the code, and copies the code into a new segment *)
    fun generateCode {code as Code{ instructions = ref instrs, printAssemblyCode, printStream, functionName, constVec, ...},
                      maxStack, resultClosure} =
    let

        local
            val codeList = List.rev instrs
            (* Add a stack check.  We need to do this for native code. *)
        in
            val codeList =
                if maxStack < 128
                then codeList
                else raise InternalError "TODO" (* SimpleCode[opcode_stackSize16, Word8.fromInt maxStack, Word8.fromInt(maxStack div 256)] :: codeList *)
        end

        val (byteVec, wordsOfCode) = genCode(codeList, code)

        (* +3 for profile count, function name and constants count *)
        val numOfConst = List.length(! constVec)
        val segSize   = wordsOfCode + Word.fromInt numOfConst + 0w4
        val firstConstant = wordsOfCode + 0w3 (* Add 3 for no of consts, fn name and profile count. *)
    
        (* Put in the number of constants. This must go in before
           we actually put in any constants. *)
        local
            val lastWord = segSize - 0w1
        in
            val () = set64(numOfConst + 2, wordsOfCode, byteVec)
            (* Set the last word of the code to the (negative) byte offset of the start of the code area
               from the end of this word. *)
            val () = set64((numOfConst + 3) * ~8, lastWord, byteVec) 
        end

        (* Now we've filled in all the size info we need to convert the segment
           into a proper code segment before it's safe to put in any ML values. *)
        val codeVec = byteVecToCodeVec(byteVec, resultClosure)

        local
            val name     : string = functionName
            val nameWord : machineWord = toMachineWord name
        in
            val () = codeVecPutWord (codeVec, wordsOfCode+0w1, nameWord)
        end
        (* Profile ref.  A byte ref used by the profiler in the RTS. *)
        local
            val v = RunCall.allocateByteMemory(0w1, Word.fromLargeWord(Word8.toLargeWord(Word8.orb(F_mutable, F_bytes))))
            fun clear 0w0 = ()
            |   clear i = (assignByte(v, i-0w1, 0w0); clear (i-0w1))
            val () = clear(wordSize)
        in
            val () = codeVecPutWord (codeVec, wordsOfCode+0w2, toMachineWord v)
        end

        (* and then copy the constants from the constant list. *)
        local
            fun setConstant(value, num) =
            (
                codeVecPutWord (codeVec, firstConstant + num, value);
                num+0w1
            )
        in
            val _ = List.foldl setConstant 0w0 (!constVec)
        end
    in
        if printAssemblyCode
        then (* print out the code *)
            (printCode (codeVec, functionName, wordsOfCode, printStream); printStream"\n")
        else ();
        codeVecLock(codeVec, resultClosure)
    end (* copyCode *)


    structure Sharing =
    struct
        type code = code
        type closureRef = closureRef
        type instr = instr
        type xReg = xReg
    end
end;

