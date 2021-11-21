(*
    Copyright David C. J. Matthews 2021

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License version 2.1 as published by the Free Software Foundation.
    
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.
    
    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*)

signature ARM64ALLOCATEREGISTERS =
sig
    type intSet and extendedBasicBlock and regProperty and xReg
    type address = Address.address 
    
    type conflictState =
    {
        conflicts: intSet, realConflicts: xReg list
    }

    datatype allocateResult =
        AllocateSuccess of xReg vector
    |   AllocateFailure of intSet list
    
    val allocateRegisters :
        {
            blocks: extendedBasicBlock vector,
            regStates: conflictState vector,
            regProps: regProperty vector
        } -> allocateResult

    val nGenRegs: int

    structure Sharing:
    sig
        type intSet             = intSet
        and extendedBasicBlock  = extendedBasicBlock
        and regProperty         = regProperty
        and xReg                = xReg
        and allocateResult      = allocateResult
    end
end;