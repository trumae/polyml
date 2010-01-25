(*
    Copyright David C. J. Matthews 2009
    
    Derived from code
    Copyright (c) 2000
        Cambridge University Technical Services Limited

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
    
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)
   
signature CODEGEN_TABLESIG =
sig
    type machineWord;

    type ttab;
    type code;
    type reg;   (* Machine registers *)
    type tests;
    type instrs;
    type addrs;
    type savedState;
    type regSet
    type operation
    type loopPush

    val ttabCreate: int * Universal.universal list -> ttab

    (* Register allocation *)
    val getRegister:    ttab * reg -> operation list;
    val getAnyRegister: ttab -> reg * operation list;
    val freeRegister:   ttab * reg -> unit;
    val addRegUse:      ttab * reg -> unit;
    val clearCache:     ttab -> unit;
    val removeRegistersFromCache: ttab * regSet -> unit;

    (* Stack handling *)
    type stackIndex;

    val noIndex: stackIndex;

    (* Push entries *)
    val pushReg:      ttab * reg  -> stackIndex;
    val pushStack:    ttab * int  -> stackIndex;
    val pushConst:    ttab * machineWord -> stackIndex;
    val pushCodeRef:  ttab * code -> stackIndex;
    val pushNonLocal: ttab * ttab * stackIndex * (unit -> stackIndex * operation list) -> stackIndex * operation list
    val pushAllBut:   ttab * ((stackIndex -> unit) -> unit) * regSet -> operation list
    val pushNonArguments: ttab * stackIndex list * regSet -> reg list * operation list
    val pushSpecificEntry: ttab * stackIndex -> operation list
    val incsp:        ttab -> stackIndex;
    val decsp:        ttab*int -> unit;
    val reserveStackSpace: ttab * int -> stackIndex * operation list

    (* Code entries *)
    val loadEntryToSet:    ttab * stackIndex * regSet * bool -> reg * stackIndex * operation list
    val loadToSpecificReg: ttab * reg * stackIndex * bool -> stackIndex * operation list
    val lockRegister:      ttab * reg -> unit;
    val unlockRegister:    ttab * reg -> unit;
    val loadIfArg:         ttab * stackIndex -> stackIndex * operation list
    val indirect:          int * stackIndex * ttab -> stackIndex * operation list
    val moveToVec:         stackIndex * stackIndex * int * instrs * ttab -> operation list

    val removeStackEntry: ttab*stackIndex -> unit;

    val resetButReload:   ttab * int -> operation list
    val pushValueToStack: ttab * stackIndex * int -> stackIndex * operation list
    val storeInStack:     ttab * stackIndex * int -> operation list
    val realstackptr:     ttab -> int
    val maxstack:         ttab -> int
    val parameterInRegister: reg * int * ttab -> stackIndex
    val incrUseCount:     ttab * stackIndex * int -> unit
    
    val setLifetime:      ttab * stackIndex * int -> unit

    type stackMark;

    val markStack: ttab -> stackMark;
    val unmarkStack: ttab * stackMark -> unit

    type labels;

    val noJump: labels;
    val isEmptyLabel: labels -> bool

    datatype mergeResult = NoMerge | MergeIndex of stackIndex;

    val unconditionalBranch: mergeResult * ttab -> labels * operation list
    val jumpBack: addrs ref * ttab -> operation list

    val fixup: labels * ttab -> operation list
    val merge: labels * ttab * mergeResult * stackMark -> mergeResult * operation list
    val mergeList: labels list * ttab * mergeResult * stackMark -> mergeResult * operation list

    type handler;

    val pushAddress: ttab * int -> handler * operation list
    val fixupH:      handler * int * ttab -> operation list

    val exiting: ttab -> unit;
    val haveExited: ttab -> bool

    type regHint
    val dataOp: stackIndex list * instrs * ttab * regHint -> stackIndex * operation list

    val compareAndBranch: stackIndex list * tests * ttab -> labels * operation list

    val saveState : ttab -> savedState
    val startCase : ttab * savedState -> addrs ref * operation list
    val compareLoopStates: ttab * savedState * stackIndex list -> regSet * loopPush list
    val restoreLoopState: ttab * savedState * regSet * loopPush list -> operation list

    (* Temporary checking that the stack has been emptied. *)
    val checkBlockResult: ttab * mergeResult -> unit

    val chooseRegister : ttab -> reg option

    val getRegisterSetForFunction: machineWord -> regSet
    val getRegisterSetForCode: code -> regSet

    val getFunctionRegSet: stackIndex * ttab -> regSet
    val addModifiedRegSet: ttab * regSet -> unit

    val getModifedRegSet: ttab -> regSet

    datatype argdest = ArgToRegister of reg | ArgToStack of int
    val getLoopDestinations: stackIndex list * ttab -> argdest list

    val callCode: stackIndex * bool * ttab -> operation list
    val jumpToCode: stackIndex * bool * reg option * ttab -> operation list

    structure Sharing:
    sig
        type code       = code
        and  instrs     = instrs
        and  reg        = reg
        and  tests      = tests
        and  addrs      = addrs
        and  operation  = operation 
        and  machineWord = machineWord
        and  ttab       = ttab
        and  savedState = savedState
        and  regSet     = regSet
        and  stackIndex = stackIndex
        and  stackMark  = stackMark
        and  labels     = labels
        and  handler    = handler
        and  regHint    = regHint
        and  argdest    = argdest
        and  loopPush   = loopPush
    end
end;
