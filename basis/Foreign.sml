(*
    Title:      Foreign Function Interface: main part
    Author:     David Matthews
    Copyright   David Matthews 2015-16, 2018

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

signature FOREIGN =
sig
    exception Foreign of string

    structure Memory:
    sig
        eqtype volatileRef
        val volatileRef: SysWord.word -> volatileRef
        val setVolatileRef: volatileRef * SysWord.word -> unit
        val getVolatileRef: volatileRef -> SysWord.word
        
        eqtype voidStar
        val voidStar2Sysword: voidStar -> SysWord.word
        val sysWord2VoidStar: SysWord.word -> voidStar
        val null: voidStar

        val ++ : voidStar * word -> voidStar
        val -- : voidStar * word -> voidStar
        
        (* Remember an address except across loads. *)
        val memoise: ('a -> voidStar) ->'a -> unit -> voidStar
        
        exception Memory

        (* malloc - allocate memory.  N.B. argument is the number of bytes.
           Raises Memory exception if it cannot allocate. *)
        val malloc: word -> voidStar
        (* free - free allocated memory. *)
        val free: voidStar -> unit

        val get8:  voidStar * Word.word -> Word8.word
        val get16: voidStar * Word.word -> Word.word
        val get32: voidStar * Word.word -> Word32.word
        val get64: voidStar * Word.word -> SysWord.word
        val set8:  voidStar * Word.word * Word8.word -> unit
        val set16: voidStar * Word.word * Word.word -> unit
        val set32: voidStar * Word.word * Word32.word -> unit
        val set64: voidStar * Word.word * SysWord.word -> unit

        val getFloat:   voidStar * Word.word -> real
        val getDouble:  voidStar * Word.word -> real
        val setFloat:   voidStar * Word.word * real -> unit
        val setDouble:  voidStar * Word.word * real -> unit

        val getAddress: voidStar * Word.word -> voidStar
        val setAddress: voidStar * Word.word * voidStar -> unit
    end
    
    structure System:
    sig
        type voidStar = Memory.voidStar
        type externalSymbol
        val loadLibrary: string -> voidStar
        and loadExecutable: unit -> voidStar
        and freeLibrary: voidStar -> unit
        and getSymbol: voidStar * string -> voidStar
        and externalFunctionSymbol: string -> externalSymbol
        and externalDataSymbol: string -> externalSymbol
        and addressOfExternal: externalSymbol -> voidStar
    end
    
    structure LibFFI:
    sig
        eqtype abi
        (* List of ABIs defined in libffi for this platform. *)
        val abiList: (string * abi) list
        (* The default Abi. *)
        val abiDefault:         abi

        (* Type codes. *)
        val ffiTypeCodeVoid:    Word.word
        and ffiTypeCodeInt:     Word.word
        and ffiTypeCodeFloat:   Word.word
        and ffiTypeCodeDouble:  Word.word
        and ffiTypeCodeUInt8:   Word.word
        and ffiTypeCodeSInt8:   Word.word
        and ffiTypeCodeUInt16:  Word.word
        and ffiTypeCodeSInt16:  Word.word
        and ffiTypeCodeUInt32:  Word.word
        and ffiTypeCodeSInt32:  Word.word
        and ffiTypeCodeUInt64:  Word.word
        and ffiTypeCodeSInt64:  Word.word
        and ffiTypeCodeStruct:  Word.word
        and ffiTypeCodePointer: Word.word

        (* Predefined types.  These are addresses so have to be reloaded
           in each session. *)
        eqtype ffiType
        val ffiType2voidStar: ffiType -> Memory.voidStar
        val voidStar2ffiType: Memory.voidStar -> ffiType

        val getFFItypeVoid: unit -> ffiType
        and getFFItypeUint8: unit -> ffiType
        and getFFItypeSint8: unit -> ffiType
        and getFFItypeUint16: unit -> ffiType
        and getFFItypeSint16: unit -> ffiType
        and getFFItypeUint32: unit -> ffiType
        and getFFItypeSint32: unit -> ffiType
        and getFFItypeUint64: unit -> ffiType
        and getFFItypeSint64: unit -> ffiType
        and getFFItypeFloat: unit -> ffiType
        and getFFItypeDouble: unit -> ffiType
        and getFFItypePointer: unit -> ffiType
        and getFFItypeUChar: unit -> ffiType
        and getFFItypeSChar: unit -> ffiType
        and getFFItypeUShort: unit -> ffiType
        and getFFItypeSShort: unit -> ffiType
        and getFFItypeUint: unit -> ffiType
        and getFFItypeSint: unit -> ffiType
        and getFFItypeUlong: unit -> ffiType
        and getFFItypeSlong: unit -> ffiType
        
        val extractFFItype:
            ffiType -> { size: word, align: word, typeCode: word, elements: ffiType list }
        val createFFItype:
            { size: word, align: word, typeCode: word, elements: ffiType list } -> ffiType

        eqtype cif
        val cif2voidStar: cif -> Memory.voidStar
        val voidStar2cif: Memory.voidStar -> cif
        val createCIF: abi * ffiType * ffiType list -> cif
        val callFunction:
            { cif: cif, function: Memory.voidStar, result: Memory.voidStar, arguments: Memory.voidStar } -> unit

        val createCallback:
            (Memory.voidStar * Memory.voidStar -> unit) * cif -> Memory.voidStar
        val freeCallback: Memory.voidStar -> unit
    end
    
    structure Error:
    sig
        type syserror = LibrarySupport.syserror
        val getLastError: unit -> SysWord.word
        val setLastError: SysWord.word -> unit
        val fromWord: SysWord.word -> syserror
        and toWord: syserror -> SysWord.word
    end
    
    type library
    type symbol
    val loadLibrary: string -> library
    val loadExecutable: unit -> library
    val getSymbol: library -> string  -> symbol
    val symbolAsAddress: symbol -> Memory.voidStar
    val externalFunctionSymbol: string -> symbol
    and externalDataSymbol: string -> symbol

    structure LowLevel:
    sig
        type ctype =
        {
            size: Word.word, (* Size in bytes *)
            align: Word.word, (* Alignment *)
            ffiType: unit -> LibFFI.ffiType
        }
        
        val cTypeVoid: ctype
        and cTypePointer: ctype
        and cTypeInt8: ctype
        and cTypeChar: ctype
        and cTypeUint8: ctype
        and cTypeUchar: ctype
        and cTypeInt16: ctype
        and cTypeUint16: ctype
        and cTypeInt32: ctype
        and cTypeUint32: ctype
        and cTypeInt64: ctype
        and cTypeUint64: ctype
        and cTypeInt: ctype
        and cTypeUint: ctype
        and cTypeLong: ctype
        and cTypeUlong: ctype
        and cTypeFloat: ctype
        and cTypeDouble: ctype
        
        val cStruct: ctype list -> ctype

        val callwithAbi: LibFFI.abi -> ctype list -> ctype -> symbol -> Memory.voidStar * Memory.voidStar -> unit
        val call: ctype list -> ctype -> symbol -> Memory.voidStar * Memory.voidStar -> unit
        
        val cFunctionWithAbi:
            LibFFI.abi -> ctype list -> ctype -> (Memory.voidStar * Memory.voidStar -> unit) -> Memory.voidStar
        val cFunction:
            ctype list -> ctype -> (Memory.voidStar * Memory.voidStar -> unit) -> Memory.voidStar
    end

    type 'a conversion

    val makeConversion:
        {
            load: Memory.voidStar -> 'a, (* Load a value from C memory *)
            store: Memory.voidStar * 'a -> unit -> unit, (* Store value and return free function. *)
            ctype: LowLevel.ctype
        } -> 'a conversion

    val breakConversion:
        'a conversion ->
        {
            load: Memory.voidStar -> 'a, (* Load a value from C memory *)
            store: Memory.voidStar * 'a -> unit -> unit, (* Store value and return free function. *)
            ctype: LowLevel.ctype
        }

    val cVoid: unit conversion
    val cPointer: Memory.voidStar conversion
    val cInt8: int conversion
    val cUint8: int conversion
    val cChar: char conversion
    val cUchar: Word8.word conversion
    val cInt16: int conversion
    val cUint16: int conversion
    val cInt32: int conversion
    val cUint32: int conversion
    val cInt64: int conversion
    val cUint64: int conversion
    val cInt32Large: LargeInt.int conversion
    val cUint32Large: LargeInt.int conversion
    val cInt64Large: LargeInt.int conversion
    val cUint64Large: LargeInt.int conversion
    val cShort: int conversion
    val cUshort: int conversion
    val cInt: int conversion
    val cUint: int conversion
    val cLong: int conversion
    val cUlong: int conversion
    val cIntLarge: LargeInt.int conversion
    val cUintLarge: LargeInt.int conversion
    val cLongLarge: LargeInt.int conversion
    val cUlongLarge: LargeInt.int conversion
    val cString: string conversion
    val cByteArray: Word8Vector.vector conversion
    val cFloat: real conversion
    val cDouble: real conversion
    
    (* When a pointer e.g. a string may be null. *)
    val cOptionPtr: 'a conversion -> 'a option conversion

    type 'a closure
    
    val cFunction: ('a->'b) closure conversion

    val buildClosure0withAbi: (unit -> 'a) * LibFFI.abi * unit * 'a conversion -> (unit -> 'a) closure
    val buildClosure0: (unit -> 'a) * unit * 'a conversion -> (unit -> 'a) closure
    val buildClosure1withAbi: ('a -> 'b) * LibFFI.abi * 'a conversion * 'b conversion -> ('a -> 'b) closure
    val buildClosure1:  ('a -> 'b) * 'a conversion * 'b conversion -> ('a -> 'b) closure
    val buildClosure2withAbi:
         ('a * 'b -> 'c) * LibFFI.abi * ('a conversion * 'b conversion) * 'c conversion -> ('a * 'b -> 'c) closure
    val buildClosure2: ('a * 'b -> 'c) * ('a conversion * 'b conversion) * 'c conversion -> ('a * 'b -> 'c) closure
    val buildClosure3withAbi:
         ('a * 'b *'c -> 'd) * LibFFI.abi * ('a conversion * 'b conversion * 'c conversion) * 'd conversion ->
            ('a * 'b *'c -> 'd) closure
    val buildClosure3: ('a * 'b *'c -> 'd) * ('a conversion * 'b conversion * 'c conversion) * 'd conversion ->
            ('a * 'b *'c -> 'd) closure
    val buildClosure4withAbi:
         ('a * 'b * 'c  * 'd -> 'e) * LibFFI.abi * ('a conversion * 'b conversion * 'c conversion* 'd conversion) * 'e conversion ->
            ('a * 'b * 'c * 'd -> 'e) closure
    val buildClosure4:
        ('a * 'b * 'c  * 'd -> 'e) * ('a conversion * 'b conversion * 'c conversion* 'd conversion) * 'e conversion ->
            ('a * 'b * 'c * 'd -> 'e) closure
    val buildClosure5withAbi:
        ('a * 'b * 'c * 'd * 'e -> 'f) *
            LibFFI.abi * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion) * 'f conversion ->
            ('a * 'b * 'c * 'd * 'e -> 'f) closure
    val buildClosure5:
        ('a * 'b * 'c * 'd * 'e -> 'f) *
        ('a conversion * 'b conversion * 'c conversion* 'd conversion * 'e conversion) * 'f conversion ->
            ('a * 'b * 'c * 'd * 'e -> 'f) closure
    val buildClosure6withAbi:
        ('a * 'b * 'c * 'd * 'e * 'f -> 'g) * LibFFI.abi *
            ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion) * 'g conversion ->
            ('a * 'b * 'c * 'd * 'e * 'f -> 'g) closure
    val buildClosure6:
        ('a * 'b * 'c * 'd * 'e * 'f -> 'g) *
            ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion) * 'g conversion ->
            ('a * 'b * 'c * 'd * 'e * 'f -> 'g) closure

    (* Remove the "free" from a conversion.  Used if extra memory allocated
       by the argument must not be freed when the function returns.  *)
    val permanent: 'a conversion -> 'a conversion

    (* Call by reference.  *)
    val cStar: 'a conversion -> 'a ref conversion
    (* Pass a const pointer *)
    val cConstStar: 'a conversion -> 'a conversion
    
    (* Fixed size vector.  It is treated as a struct and passed by value or embedded in a structure. *)
    val cVectorFixedSize: int * 'a conversion -> 'a vector conversion
    (* Pass an ML vector as a pointer to a C array. *)
    and cVectorPointer: 'a conversion -> 'a vector conversion
    (* Pass an ML array as a pointer to a C array and, on return, update each element of
       the ML array from the C array. *)
    and cArrayPointer: 'a conversion -> 'a array conversion

    (* structs. *)
    val cStruct2: 'a conversion * 'b conversion -> ('a * 'b) conversion
    val cStruct3: 'a conversion * 'b conversion * 'c conversion -> ('a*'b*'c)conversion
    val cStruct4: 'a conversion * 'b conversion * 'c conversion * 'd conversion -> ('a*'b*'c*'d)conversion
    val cStruct5: 'a conversion * 'b conversion * 'c conversion * 'd conversion *
                      'e conversion -> ('a*'b*'c*'d*'e)conversion
    val cStruct6: 'a conversion * 'b conversion * 'c conversion * 'd conversion *
                      'e conversion * 'f conversion -> ('a*'b*'c*'d*'e*'f)conversion
    val cStruct7: 'a conversion * 'b conversion * 'c conversion * 'd conversion *
                      'e conversion * 'f conversion * 'g conversion -> ('a*'b*'c*'d*'e*'f*'g)conversion
    val cStruct8: 'a conversion * 'b conversion * 'c conversion * 'd conversion *
                      'e conversion * 'f conversion * 'g conversion * 'h conversion -> ('a*'b*'c*'d*'e*'f*'g*'h)conversion
    val cStruct9: 'a conversion * 'b conversion * 'c conversion * 'd conversion *
                       'e conversion * 'f conversion * 'g conversion * 'h conversion * 'i conversion ->
                       ('a*'b*'c*'d*'e*'f*'g*'h*'i)conversion
    val cStruct10: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion -> ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j)conversion
    val cStruct11: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion -> ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k)conversion
    val cStruct12: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion ->
                   ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l)conversion
    val cStruct13: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion ->
                   ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m)conversion
    val cStruct14: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion ->
                   ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n)conversion
    val cStruct15: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion -> ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o)conversion
    val cStruct16: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion * 'p conversion -> ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p)conversion
    val cStruct17: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion * 'p conversion * 'q conversion ->
                    ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q)conversion
    val cStruct18: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion * 'p conversion * 'q conversion * 'r conversion ->
                    ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r)conversion
    val cStruct19: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion * 'p conversion * 'q conversion * 'r conversion * 's conversion ->
                    ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r*'s)conversion
    val cStruct20: 'a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion * 'g conversion *
                   'h conversion * 'i conversion * 'j conversion * 'k conversion * 'l conversion * 'm conversion * 'n conversion *
                   'o conversion * 'p conversion * 'q conversion * 'r conversion * 's conversion * 't conversion ->
                    ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r*'s*'t)conversion

    val buildCall0withAbi: LibFFI.abi * symbol * unit * 'a conversion -> unit -> 'a
    val buildCall0: symbol * unit * 'a conversion -> unit -> 'a
    val buildCall1withAbi: LibFFI.abi * symbol * 'a conversion * 'b conversion -> 'a -> 'b
    val buildCall1: symbol * 'a conversion * 'b conversion -> 'a -> 'b
    val buildCall2withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion) * 'c conversion -> 'a * 'b -> 'c
    val buildCall2:
        symbol * ('a conversion * 'b conversion) * 'c conversion -> 'a * 'b -> 'c
    val buildCall3withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion) * 'd conversion -> 'a * 'b * 'c -> 'd
    val buildCall3:
        symbol * ('a conversion * 'b conversion * 'c conversion) * 'd conversion -> 'a * 'b * 'c -> 'd
    val buildCall4withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion) * 'e conversion ->
            'a * 'b * 'c * 'd -> 'e
    val buildCall4:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion) * 'e conversion ->
            'a * 'b * 'c * 'd -> 'e
    val buildCall5withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion) * 'f conversion ->
            'a * 'b * 'c * 'd * 'e -> 'f
    val buildCall5:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion) * 'f conversion ->
            'a * 'b * 'c * 'd * 'e -> 'f
    val buildCall6withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion) *
                'g conversion -> 'a * 'b * 'c * 'd * 'e * 'f -> 'g
    val buildCall6:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion * 'f conversion) *
                'g conversion -> 'a * 'b * 'c * 'd * 'e * 'f -> 'g
    val buildCall7withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion) *
                'h conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g -> 'h
    val buildCall7:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion) *
                'h conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g -> 'h
    val buildCall8withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion) *
                'i conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h -> 'i
    val buildCall8:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion) *
                'i conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h -> 'i
    val buildCall9withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion) *
                'j conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i -> 'j
    val buildCall9:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion) *
                'j conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i -> 'j
    val buildCall10withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion) *
                'k conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j -> 'k
    val buildCall10:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion) *
                'k conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j -> 'k
    val buildCall11withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion) *
                'l conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k -> 'l
    val buildCall11:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion) *
             'l conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k  -> 'l
    val buildCall12withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion) * 'm conversion ->
                'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l -> 'm
    val buildCall12:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion) * 'm conversion ->
             'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l -> 'm
    val buildCall13withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion * 'm conversion) *
            'n conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm -> 'n
    val buildCall13:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion * 'm conversion) *
            'n conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm -> 'n
    val buildCall14withAbi:
        LibFFI.abi * symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion * 'm conversion * 'n conversion) *
            'o conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm * 'n -> 'o
    val buildCall14:
        symbol * ('a conversion * 'b conversion * 'c conversion * 'd conversion * 'e conversion *
             'f conversion * 'g conversion * 'h conversion * 'i conversion * 'j conversion * 'k conversion *
             'l conversion * 'm conversion * 'n conversion) *
            'o conversion -> 'a * 'b * 'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm * 'n -> 'o
end;

structure Foreign:> FOREIGN =
struct
    fun id x = x
    exception Foreign = RunCall.Foreign

    open ForeignConstants
    
    structure Memory = ForeignMemory
    infix 6 ++ --

    (* Internal utility function. *)
    fun alignUp(s, align) = Word.andb(s + align-0w1, ~ align)
    
    local
        val ffiGeneralCall = RunCall.rtsCallFull2 "PolyFFIGeneral"
    in
        fun ffiGeneral(code: int, arg: 'a): 'b = RunCall.unsafeCast(ffiGeneralCall(RunCall.unsafeCast(code, arg)))
    end
   
    structure System =
    struct
        type voidStar = Memory.voidStar
        type externalSymbol = voidStar
        fun loadLibrary(s: string): voidStar = ffiGeneral (2, s)
        and loadExecutable(): voidStar = ffiGeneral (3, ())
        and freeLibrary(s: voidStar): unit = ffiGeneral (4, s)
        and getSymbol(lib: voidStar, s: string): voidStar = ffiGeneral (5, (lib, s))
        
        (* Create an external symbol object.  The first word of this is filled in with the
           address after the code is exported and linked.
           On a small number of platforms different relocations are required for functions
           and for data. *)
        val externalFunctionSymbol: string -> externalSymbol = RunCall.rtsCallFull1 "PolyFFICreateExtFn"
        and externalDataSymbol: string -> externalSymbol = RunCall.rtsCallFull1 "PolyFFICreateExtData"
        
        (* An external symbol is a memory cell containing the value in the first word
           followed by the symbol name.  Because the first word is the value it can
           be treated as a Sysword.word value.
           When it is created the value is zero and the address of the target is only
           set once the symbol has been exported and the value set by the linker. *)
        fun addressOfExternal(ext: externalSymbol): voidStar =
            if Memory.voidStar2Sysword ext = 0w0
            then raise Foreign "External symbol has not been set"
            else ext
    end
    
    structure Error =
    struct
        type syserror = LibrarySupport.syserror
        fun toWord (s: syserror): SysWord.word = RunCall.unsafeCast s
        and fromWord (w: SysWord.word) : syserror = RunCall.unsafeCast w
        local
            val callGetError = RunCall.rtsCallFast1 "PolyFFIGetError"
        in
            fun getLastError(): SysWord.word =
            let
                val mem = RunCall.allocateByteMemory(0w1, 0wx41)
                val () = callGetError mem
                val () = RunCall.clearMutableBit mem
            in
                RunCall.unsafeCast mem
            end 
        end
        val setLastError: SysWord.word -> unit = RunCall.rtsCallFast1 "PolyFFISetError"
    end

    structure LibFFI =
    struct
        type abi = Word.word
        val abiList: (string * abi) list = ffiGeneral (50, ())

        local
            fun getConstant (n: int) : Word.word = ffiGeneral (51, n)
        in
            val abiDefault          = getConstant 0
            
            and ffiTypeCodeVoid     = getConstant 1
            and ffiTypeCodeInt      = getConstant 2
            and ffiTypeCodeFloat    = getConstant 3
            and ffiTypeCodeDouble   = getConstant 4
            and ffiTypeCodeUInt8    = getConstant 5
            and ffiTypeCodeSInt8    = getConstant 6
            and ffiTypeCodeUInt16   = getConstant 7
            and ffiTypeCodeSInt16   = getConstant 8
            and ffiTypeCodeUInt32   = getConstant 9
            and ffiTypeCodeSInt32   = getConstant 10
            and ffiTypeCodeUInt64   = getConstant 11
            and ffiTypeCodeSInt64   = getConstant 12
            and ffiTypeCodeStruct   = getConstant 13
            and ffiTypeCodePointer  = getConstant 14
        end

        type ffiType = Memory.voidStar
        val ffiType2voidStar = id
        and voidStar2ffiType = id

        local
            fun getFFItype (n: int) (): ffiType = ffiGeneral (52, n)
        in
            val getFFItypeVoid      = getFFItype 0
            and getFFItypeUint8     = getFFItype 1
            and getFFItypeSint8     = getFFItype 2
            and getFFItypeUint16    = getFFItype 3
            and getFFItypeSint16    = getFFItype 4
            and getFFItypeUint32    = getFFItype 5
            and getFFItypeSint32    = getFFItype 6
            and getFFItypeUint64    = getFFItype 7
            and getFFItypeSint64    = getFFItype 8
            and getFFItypeFloat     = getFFItype 9
            and getFFItypeDouble    = getFFItype 10
            and getFFItypePointer   = getFFItype 11
            and getFFItypeUChar     = getFFItype 12
            and getFFItypeSChar     = getFFItype 13
            and getFFItypeUShort    = getFFItype 14
            and getFFItypeSShort    = getFFItype 15
            and getFFItypeUint      = getFFItype 16
            and getFFItypeSint      = getFFItype 17
            and getFFItypeUlong     = getFFItype 18
            and getFFItypeSlong     = getFFItype 19
        end

        fun extractFFItype (s: ffiType) =
        let
            val (size: word, align: word, typ: word, elem: Memory.voidStar) =
                ffiGeneral (53, s)
            (* Unpack the "elements". *)
            open Memory
            fun loadElements i =
            let
                val a = getAddress(elem, i)
            in
                if a = null
                then []
                else a :: loadElements(i+0w1)
            end
            val elements =
                if elem = sysWord2VoidStar 0w0
                then []
                else loadElements 0w0
        in
            { size=size, align=align, typeCode = typ, elements = elements }
        end
        
        (* Construct a new FFItype in allocated memory. *)
        fun createFFItype { size: word, align: word, typeCode: word, elements: ffiType list }: ffiType =
            ffiGeneral (54, (size, align, typeCode, elements))

        type cif = Memory.voidStar
        val cif2voidStar = id
        and voidStar2cif = id

        (* Construct and prepare a CIF in allocated memory. *)
        fun createCIF (abi: abi, resultType: ffiType, argTypes: ffiType list): cif =
            ffiGeneral (55, (abi, resultType, argTypes))

        (* Call a function. We have to pass some space for the result *)
        fun callFunction
            { cif: cif, function: Memory.voidStar, result: Memory.voidStar, arguments: Memory.voidStar }: unit =
            ffiGeneral (56, (cif, function, result, arguments))

        (* Create a callback.  Returns the C function. *)
        fun createCallback(f: Memory.voidStar * Memory.voidStar -> unit, cif: cif): Memory.voidStar =
            ffiGeneral (57, (f, cif))
        
        (* Free a callback.  This takes the C function address returned by createCallback *)
        fun freeCallback(cb: Memory.voidStar): unit =
            ffiGeneral (58, cb)
    end

    type library = unit -> Memory.voidStar
    type symbol = unit -> Memory.voidStar

    (* Load the library but memoise it so if we reference the library in another
       session we will reload it.  We load the library immediately so that if
       there is an error we get the error immediately. *)
    fun loadLibrary (name: string): library = Memory.memoise System.loadLibrary name
    and loadExecutable (): library  = Memory.memoise System.loadExecutable ()
    
    (* To get a symbol we memoise a function that forces a library load if necessary
       and then gets the symbol. *)
    fun getSymbol(lib: library) (name: string): symbol =
        Memory.memoise (fn s => System.getSymbol(lib(), s)) name

    (* This forces the symbol to be loaded.  The result is NOT memoised. *)
    fun symbolAsAddress(s: symbol): Memory.voidStar = s()
    
    (* Create an external symbol.  This can only be used after linking. *)
    fun externalFunctionSymbol(name: string): symbol =
        let
            val r = System.externalFunctionSymbol name
        in
            fn () => System.addressOfExternal r
        end
    
    and externalDataSymbol(name: string): symbol =
        let
            val r = System.externalDataSymbol name
        in
            fn () => System.addressOfExternal r
        end

    structure LowLevel =
    struct
        type ctype =
        {
            size: Word.word, (* Size in bytes *)
            align: Word.word, (* Alignment *)
            ffiType: unit -> LibFFI.ffiType
        }
         
        local
            open LibFFI Memory            
        in
            val cTypeVoid = 
                { size= #size saVoid, align= #align saVoid, ffiType = memoise getFFItypeVoid () }
            val cTypePointer = 
                { size= #size saPointer, align= #align saPointer, ffiType = memoise getFFItypePointer () }
            val cTypeInt8 =
                { size= #size saSint8, align= #align saSint8, ffiType = memoise getFFItypeSint8 () }
            val cTypeChar = cTypeInt8
            val cTypeUint8 = 
                { size= #size saUint8, align= #align saUint8, ffiType = memoise getFFItypeUint8 () }
            val cTypeUchar = cTypeUint8
            val cTypeInt16 =
                { size= #size saSint16, align= #align saSint16, ffiType = memoise getFFItypeSint16 () }
            val cTypeUint16 =
                { size= #size saUint16, align= #align saUint16, ffiType = memoise getFFItypeUint16 () }
            val cTypeInt32 =
                { size= #size saSint32, align= #align saSint32, ffiType = memoise getFFItypeSint32 () }
            val cTypeUint32 =
                { size= #size saUint32, align= #align saUint32, ffiType = memoise getFFItypeUint32 () }
            val cTypeInt64 =
                { size= #size saSint64, align= #align saSint64, ffiType = memoise getFFItypeSint64 () }
            val cTypeUint64 =
                { size= #size saUint64, align= #align saUint64, ffiType = memoise getFFItypeUint64 () }
            val cTypeInt =
                { size= #size saSint, align= #align saSint, ffiType = memoise getFFItypeSint () }
            val cTypeUint =
                { size= #size saUint, align= #align saUint, ffiType = memoise getFFItypeUint () }
            val cTypeLong =
                { size= #size saSlong, align= #align saSlong, ffiType = memoise getFFItypeSlong () }
            val cTypeUlong =
                { size= #size saUlong, align= #align saUlong, ffiType = memoise getFFItypeUlong () }
            val cTypeFloat =
                { size= #size saFloat, align= #align saFloat, ffiType = memoise getFFItypeFloat () }
            val cTypeDouble =
                { size= #size saDouble, align= #align saDouble, ffiType = memoise getFFItypeDouble () }

            fun cStruct(fields: ctype list): ctype =
            let
                (* The total alignment is the maximum alignment of the fields. *)
                val align = foldl(fn ({align, ...}, a) => Word.max(align, a)) 0w1 fields
                (* Each field needs to be on its alignment.  Finally we round up the size
                   to the total alignment. *)
                val size =
                    alignUp(foldl(fn ({align, size, ...}, s) => alignUp(s, align) + size) 0w0 fields, align)

                val types = map #ffiType fields

                (* Make the type but only when it's used. *)
                fun ffiType () =
                    LibFFI.createFFItype {
                        size = size, align = align, typeCode=LibFFI.ffiTypeCodeStruct,
                        elements = map (fn t => t()) types }
            in
                {align=align, size=size, ffiType=memoise ffiType ()}
            end

            fun callwithAbi (abi: abi) (argTypes: ctype list) (resType: ctype): symbol -> voidStar * voidStar -> unit =
            let
                fun getType ctype = Memory.voidStar2Sysword(#ffiType ctype ())
                (* Compile the intermediate function. *)
                val functionCaller: LargeWord.word * LargeWord.word * LargeWord.word -> unit =
                    RunCall.foreignCall(Word.toInt abi, List.map getType argTypes, getType resType)

                (* The result function. *)
                fun callFunction (fnAddr: unit->voidStar) (args, resMem) =
                    functionCaller(voidStar2Sysword(fnAddr()), voidStar2Sysword args, voidStar2Sysword resMem)
            in
                callFunction
            end

            fun call x = callwithAbi abiDefault x (* Have to make it a fun to avoid value restriction *)

            (* Build a call-back function.  Returns a function to take the actual ML function,
               create a callback and then return the address. *)
            fun cFunctionWithAbi (abi: abi) (argTypes: ctype list) (resType: ctype):
                    (voidStar * voidStar -> unit) -> voidStar =
            let
                fun buildCif () = createCIF (abi, #ffiType resType (), map (fn {ffiType, ...} => ffiType ()) argTypes)
                val cif: unit->cif = memoise buildCif ()
            in
                fn cbFun => createCallback(cbFun, cif())
            end
            
            fun cFunction x = cFunctionWithAbi abiDefault x
        end

    end

    type 'a conversion =
    {
        load: Memory.voidStar -> 'a, (* Load a value from C memory *)
        store: Memory.voidStar * 'a -> unit -> unit, (* Store a value in C memory *)
        updateML: Memory.voidStar * 'a -> unit, (* Update ML value after call - only used in cStar. *)
        updateC: Memory.voidStar * 'a -> unit,  (* Update C value after callback - only used in cStar. *)
        ctype: LowLevel.ctype
    }
    
    fun makeConversion { load, store, ctype } =
        { load = load, store = store, ctype = ctype, updateML = fn _ => (), updateC = fn _ => () }

    fun breakConversion({load, store, ctype, ... }: 'a conversion) =
        { load = load, store = store, ctype = ctype }

    (* Conversions *)
    local
        open LibFFI Memory LowLevel
        fun checkRangeShort(i, min, max) = if i < min orelse i > max then raise Overflow else i
        fun checkRangeLong(i: LargeInt.int, min, max) = if i < min orelse i > max then raise Overflow else i
        fun noFree _ = () (* None of these allocate extra memory or need to update. *)
    in
        val cVoid: unit conversion =
            makeConversion{ load=fn _ => (), store=fn _ => noFree, ctype = cTypeVoid }

        (* cPointer should only be used to base other conversions on. *)
        val cPointer: voidStar conversion =
            makeConversion { load=fn a => getAddress(a, 0w0), store=fn(a, v) => (setAddress(a, 0w0, v); noFree),
                             ctype = cTypePointer }

        local
            fun load(m: voidStar): int = Word8.toIntX(get8(m, 0w0))
            fun store(m: voidStar, i: int) =
                (set8(m, 0w0, Word8.fromInt(checkRangeShort(i, ~128, 127))); noFree)
        in
            val cInt8: int conversion =
                makeConversion { load=load, store=store, ctype = cTypeInt8 }
        end

        local
            (* Char is signed in C but unsigned in ML. *)
            fun load(m: voidStar): char = Char.chr(Word8.toInt(get8(m, 0w0)))
            fun store(m: voidStar, i: char) =
                (set8(m, 0w0, Word8.fromInt(Char.ord i)); noFree)
        in
            val cChar: char conversion =
                makeConversion{ load=load, store=store, ctype = cTypeChar }
        end

        local
            (* Uchar - convert as Word8.word. *)
            fun load(m: voidStar): Word8.word = get8(m, 0w0)
            fun store(m: voidStar, i: Word8.word) = (set8(m, 0w0, i); noFree)
        in
            val cUchar: Word8.word conversion =
                makeConversion{ load=load, store=store, ctype = cTypeUchar }
        end

        local
            fun load(m: voidStar): int = Word8.toInt(get8(m, 0w0))
            fun store(m: voidStar, i: int) =
                (set8(m, 0w0, Word8.fromInt(checkRangeShort(i, 0, 255))); noFree)
        in
            val cUint8: int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeUint8 }
        end

        local
            (* Because the word length is greater than the length returned by
               get16 we have to do something special to get the sign bit correct.
               That isn't necessary in the other cases. *)
            fun load(m: voidStar): int =
            let
                (* Could be done with shifts *)
                val r = Word.toInt(get16(m, 0w0))
            in
                if r >= 32768
                then r - 65536
                else r
            end
            fun store(m: voidStar, i: int) =
                (set16(m, 0w0, Word.fromInt(checkRangeShort(i, ~32768, 32767))); noFree)
        in
            val cInt16: int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeInt16 }
        end

        local
            fun load(m: voidStar): int = Word.toInt(get16(m, 0w0))
            fun store(m: voidStar, i: int) =
                (set16(m, 0w0, Word.fromInt(checkRangeShort(i, 0, 65535))); noFree)
        in
            val cUint16: int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeUint16 }
        end

        local
            fun load(m: voidStar): int = Word32.toIntX(get32(m, 0w0))
            val checkRange =
                if wordSize = 0w4 andalso isSome (Int.maxInt)
                then fn i => i (* We're using fixed precision 31-bit - no check necessary. *)
                else
                let
                    (* These will overflow on fixed precision 31-bit. *)
                    val max32 = Int32.toInt(valOf Int32.maxInt)
                    val min32 = ~max32 - 1
                in
                    fn i => checkRangeShort(i, min32, max32)
                end
            fun store(m: voidStar, i: int) =
                (set32(m, 0w0, Word32.fromInt(checkRange i)); noFree)
        in
            val cInt32: int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeInt32 }
        end

        local
            fun load(m: voidStar): LargeInt.int = Word32.toLargeIntX(get32(m, 0w0))
            fun store(m: voidStar, i: LargeInt.int) =
                (set32(m, 0w0, Word32.fromLargeInt(checkRangeLong(i, ~2147483648, 2147483647))); noFree)
        in
            val cInt32Large: LargeInt.int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeInt32 }
        end

        local
            fun load(m: voidStar): int = Word32.toInt(get32(m, 0w0))
            val checkRange =
                if wordSize = 0w4 andalso isSome (Int.maxInt)
                then fn i => if i < 0 then raise Overflow else i (* Fixed precision 31-bit *)
                else
                let
                    (* This will overflow on fixed precision 31-bit. *)
                    val max32 = Int32.toInt(valOf Int32.maxInt)
                    val max32Unsigned = max32 * 2 + 1
                in
                    fn i => checkRangeShort(i, 0, max32Unsigned)
                end
            fun store(m: voidStar, i: int) =
                (set32(m, 0w0, Word32.fromInt(checkRange i)); noFree)
        in
            val cUint32: int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeUint32 }
        end

        local
            fun load(m: voidStar): LargeInt.int = Word32.toLargeInt(get32(m, 0w0))
            fun store(m: voidStar, i: LargeInt.int) =
                (set32(m, 0w0, Word32.fromLargeInt(checkRangeLong(i, 0, 4294967295))); noFree)
        in
            val cUint32Large: LargeInt.int conversion =
                makeConversion{ load=load, store=store, ctype = cTypeUint32 }
        end

        local
            fun loadLarge(m: voidStar): LargeInt.int =
                if sysWordSize = 0w4
                then
                let
                    val v1 = get32(m, 0w0) and v2 = get32(m, 0w1)
                in
                    if bigEndian
                    then IntInf.<<(Word32.toLargeIntX v1, 0w32) + Word32.toLargeInt v2
                    else IntInf.<<(Word32.toLargeIntX v2, 0w32) + Word32.toLargeInt v1
                end
                else SysWord.toLargeIntX(get64(m, 0w0))
            
            fun loadShort(m: voidStar): int =
                if sysWordSize = 0w4
                then Int.fromLarge(loadLarge m)
                else SysWord.toIntX(get64(m, 0w0))

            val max = IntInf.<<(1, 0w63) - 1 and min = ~ (IntInf.<<(1, 0w63))

            fun storeLarge(m: voidStar, i: LargeInt.int) =
                if sysWordSize = 0w4
                then
                let
                    val _ = checkRangeLong(i, min, max)
                    val lo = Word32.fromLargeInt i and hi = Word32.fromLargeInt (IntInf.~>>(i, 0w32))
                in
                    if bigEndian
                    then (set32(m, 0w0, hi); set32(m, 0w1, lo))
                    else (set32(m, 0w0, lo); set32(m, 0w1, hi));
                    noFree
                end
                else (set64(m, 0w0, SysWord.fromLargeInt(checkRangeLong(i, min, max))); noFree)
          
            fun storeShort(m: voidStar, i: int) =
                if sysWordSize = 0w4 orelse not (isSome Int.maxInt)
                then (* 32-bit or arbitrary precision. *) storeLarge(m, LargeInt.fromInt i)
                else (* Fixed precision 64-bit - no need for a range check. *)
                    (set64(m, 0w0, SysWord.fromInt i); noFree)
        in
            val cInt64: int conversion =
                makeConversion{ load=loadShort, store=storeShort, ctype = cTypeInt64 }
            and cInt64Large: LargeInt.int conversion =
                makeConversion{ load=loadLarge, store=storeLarge, ctype = cTypeInt64 }
        end

        local
            fun loadLarge(m: voidStar): LargeInt.int =
                if sysWordSize = 0w4
                then
                let
                    val v1 = get32(m, 0w0) and v2 = get32(m, 0w1)
                in
                    if bigEndian
                    then IntInf.<<(Word32.toLargeInt v1, 0w32) + Word32.toLargeInt v2
                    else IntInf.<<(Word32.toLargeInt v2, 0w32) + Word32.toLargeInt v1
                end
                else SysWord.toLargeInt(get64(m, 0w0))
            
            fun loadShort(m: voidStar): int =
                if wordSize = 0w4
                then Int.fromLarge(loadLarge m)
                else SysWord.toInt(get64(m, 0w0))

            val max = IntInf.<<(1, 0w64) - 1

            fun storeLarge(m: voidStar, i: LargeInt.int) =
                if sysWordSize = 0w4
                then
                let
                    val _ = checkRangeLong(i, 0, max)
                    val lo = Word32.fromLargeInt i and hi = Word32.fromLargeInt (IntInf.~>>(i, 0w32))
                in
                    if bigEndian
                    then (set32(m, 0w0, hi); set32(m, 0w1, lo))
                    else (set32(m, 0w0, lo); set32(m, 0w1, hi));
                    noFree
                end
                else (set64(m, 0w0, SysWord.fromLargeInt(checkRangeLong(i, 0, max))); noFree)
          
            fun storeShort(m: voidStar, i: int) =
                if sysWordSize = 0w4 orelse not (isSome Int.maxInt)
                then (* 32-bit or arbitrary precision. *) storeLarge(m, LargeInt.fromInt i)
                else if i < 0 (* Fixed precision 64-bit - just check it's not negative. *)
                then raise Overflow
                else (set64(m, 0w0, SysWord.fromInt i); noFree)
        in
            val cUint64: int conversion =
                makeConversion{ load=loadShort, store=storeShort, ctype = cTypeUint64 }
            and cUint64Large: LargeInt.int conversion =
                makeConversion{ load=loadLarge, store=storeLarge, ctype = cTypeUint64 }
        end

        local
            fun load(m: voidStar): real = getFloat(m, 0w0)
            fun store(m: voidStar, v: real) = (setFloat(m, 0w0, v); noFree)
        in
            val cFloat: real conversion =
                makeConversion{ load=load, store=store, ctype = cTypeFloat }
        end

        local
            fun load(m: voidStar): real = getDouble(m, 0w0)
            fun store(m: voidStar, v: real) = (setDouble(m, 0w0, v); noFree)
        in
            val cDouble: real conversion =
                makeConversion{ load=load, store=store, ctype = cTypeDouble }
        end

        val cShort =
            if #size saSShort = #size saSint16 then cInt16
            (*else if #size saSShort = #size saSint32 then cInt32*)
            else raise Foreign "Unable to find type for short"

        val cUshort = 
            if #size saUShort = #size saUint16 then cUint16
            (*else if #size saUShort = #size saUint32 then cUint32*)
            else raise Foreign "Unable to find type for unsigned"

        val cInt =
            (*if #size saSint = #size saSint16 then cInt16
            else *)if #size saSint = #size saSint32 then cInt32
            else if #size saSint = #size saSint64 then cInt64
            else raise Foreign "Unable to find type for int"

        val cIntLarge =
            (*if #size saSint = #size saSint16 then cInt16
            else *)if #size saSint = #size saSint32 then cInt32Large
            else if #size saSint = #size saSint64 then cInt64Large
            else raise Foreign "Unable to find type for int"

        val cUint = 
            (*if #size saUint = #size saUint16 then cUint16
            else *)if #size saUint = #size saUint32 then cUint32
            else if #size saUint = #size saUint64 then cUint64
            else raise Foreign "Unable to find type for unsigned"

        val cUintLarge = 
            (*if #size saUint = #size saUint16 then cUint16
            else *)if #size saUint = #size saUint32 then cUint32Large
            else if #size saUint = #size saUint64 then cUint64Large
            else raise Foreign "Unable to find type for unsigned"

        val cLong =
            (*if #size saSlong = #size saSint16 then cInt16
            else *)if #size saSlong = #size saSint32 then cInt32
            else if #size saSlong = #size saSint64 then cInt64
            else raise Foreign "Unable to find type for long"

        val cLongLarge =
            (*if #size saSlong = #size saSint16 then cInt16
            else *)if #size saSlong = #size saSint32 then cInt32Large
            else if #size saSlong = #size saSint64 then cInt64Large
            else raise Foreign "Unable to find type for long"

        val cUlong = 
            (*if #size saUlong = #size saUint16 then cUint16
            else *)if #size saUlong = #size saUint32 then cUint32
            else if #size saUlong = #size saUint64 then cUint64
            else raise Foreign "Unable to find type for unsigned long"

        val cUlongLarge = 
            (*if #size saUlong = #size saUint16 then cUint16
            else *)if #size saUlong = #size saUint32 then cUint32Large
            else if #size saUlong = #size saUint64 then cUint64Large
            else raise Foreign "Unable to find type for unsigned long"

        local
            fun load(s: voidStar): string =
            let
                (* The location contains the address of the string. *)
                val sAddr = getAddress(s, 0w0)
                fun sLen i = if get8(sAddr, i) = 0w0 then i else sLen(i+0w1)
                val length = sLen 0w0
                fun loadChar i =
                    Char.chr(Word8.toInt(get8(sAddr, Word.fromInt i)))
            in
                CharVector.tabulate(Word.toInt length, loadChar)
            end

            fun store(v: voidStar, s: string) =
            let
                val sLen = Word.fromInt(String.size s)
                val sMem = malloc(sLen + 0w1)
                val () = CharVector.appi(fn(i, ch) => set8(sMem, Word.fromInt i, Word8.fromInt(Char.ord ch))) s
                val () = set8(sMem, sLen, 0w0)
            in
                setAddress(v, 0w0, sMem);
                fn () => Memory.free sMem
            end

        in
            val cString: string conversion =
                makeConversion { load=load, store=store, ctype = cTypePointer }
        end

        (* This is used if we want to pass NULL rather than a pointer in some cases. *)
        fun cOptionPtr({load, store, updateML, updateC, ctype}:'a conversion): 'a option conversion =
            if #typeCode(extractFFItype(#ffiType ctype ())) <> ffiTypeCodePointer
            then raise Foreign "cOptionPtr must be applied to a pointer type"
            else
            let
                fun loadOpt(s: voidStar) =
                    if getAddress(s, 0w0) = null then NONE else SOME(load s)

                fun storeOpt(v: voidStar, NONE) = (setAddress(v, 0w0, null); fn _ => ())
                |   storeOpt(v: voidStar, SOME s) = store(v, s)
                
                (* Do we have update here? *)
                fun updateMLOpt(_, NONE) = ()
                |   updateMLOpt(v: voidStar, SOME s) = updateML(v, s)
                
                fun updateCOpt(_, NONE) = ()
                |   updateCOpt(v, SOME s) = updateC(v, s)
            in
                { load=loadOpt, store=storeOpt, updateML = updateMLOpt,
                  updateC = updateCOpt, ctype = cTypePointer }
            end

        local
            (* Word8Vector.vector to C array of bytes.  It is only possible to
               do this one way because conversion from a C array requires
               us to know the size. *)
            fun load _ = raise Foreign "cByteArray cannot convert from C to ML"

            fun store(v: voidStar, s: Word8Vector.vector) =
            let
                open Word8Vector
                val sLen = Word.fromInt(length s)
                val sMem = malloc sLen
                val () = appi(fn(i, b) => set8(sMem, Word.fromInt i, b)) s
            in
                setAddress(v, 0w0, sMem);
                fn () => Memory.free sMem
            end

        in
            val cByteArray: Word8Vector.vector conversion =
                makeConversion{ load=load, store=store, ctype = cTypePointer }
        end
    end

    (* Remove the free part from the store fn.  This is intended for situations
       where an argument should not be deleted once the function completes. *)
    fun permanent({load, store, ctype, updateML, updateC }: 'a conversion): 'a conversion =
    let
        fun storeP args = (ignore (store args); fn () => ())
    in
        { load=load, store=storeP, updateML = updateML, updateC = updateC, ctype=ctype }
    end
 
    val op ++ = Memory.++

    fun cStruct2(a: 'a conversion, b: 'b conversion): ('a*'b)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ... }} = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {align=alignb, ... }} = b
        
        val offsetb = alignUp(sizea, alignb)
        fun load s = (loada s, loadb(s ++ offsetb))
        and store (x, (a, b)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b)
        in
            fn () => ( freea(); freeb() )
        end
        and updateML(s, (a, b)) = (updateMLa(s, a); updateMLb(s ++ offsetb, b))
        and updateC(x, (a, b)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b))
    in
        {load=load, store=store, updateML = updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb]}
    end

    fun cStruct3(a: 'a conversion, b: 'b conversion, c: 'c conversion): ('a*'b*'c)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {align=alignc, ...} } = c
       
        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)

        fun load s = (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc))
        and store (x, (a, b, c)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
        in
            fn () => ( freea(); freeb(); freec() )
        end
        and updateML(s, (a, b, c)) = (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c))
        and updateC(x, (a, b, c)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec]}
    end

    fun cStruct4(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion): ('a*'b*'c*'d)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {align=alignd, ...} } = d
 
        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)

        fun load s = (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd))
        and store (x, (a, b, c, d)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d)
        in
            fn () => ( freea(); freeb(); freec(); freed() )
        end
        and updateML(s, (a, b, c, d)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c); updateMLd(s ++ offsetd, d))
        and updateC(x, (a, b, c, d)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped]}
    end

    fun cStruct5(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                 e: 'e conversion): ('a*'b*'c*'d*'e)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {align=aligne, ...} } = e

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd), loade(s ++ offsete))
        and store (x, (a, b, c, d, e)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e)
        in
            fn () => ( freea(); freeb(); freec(); freed(); freee() )
        end
        and updateML(s, (a, b, c, d, e)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c);
             updateMLd(s ++ offsetd, d); updateMLe(s ++ offsete, e))
        and updateC(x, (a, b, c, d, e)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee]}
    end

    fun cStruct6(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                 e: 'e conversion, f: 'f conversion): ('a*'b*'c*'d*'e*'f)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {align=alignf, ...} } = f

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf))
        and store (x, (a, b, c, d, e, f)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
        in
            fn () => ( freea(); freeb(); freec(); freed(); freee(); freef() )
        end
        and updateML(s, (a, b, c, d, e, f)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c); updateMLd(s ++ offsetd, d);
             updateMLe(s ++ offsete, e); updateMLf(s ++ offsetf, f))
        and updateC(x, (a, b, c, d, e, f)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef]}
    end

    fun cStruct7(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                 e: 'e conversion, f: 'f conversion, g: 'g conversion): ('a*'b*'c*'d*'e*'f*'g)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {align=aligng, ...} } = g

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg))
        and store (x, (a, b, c, d, e, f, g)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g)
        in
            fn () => ( freea(); freeb(); freec(); freed(); freee(); freef(); freeg() )
        end
        and updateML(s, (a, b, c, d, e, f, g)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c); updateMLd(s ++ offsetd, d);
             updateMLe(s ++ offsete, e); updateMLf(s ++ offsetf, f); updateMLg(s ++ offsetg, g))
        and updateC(x, (a, b, c, d, e, f, g)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC, ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg]}
    end

    fun cStruct8(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                 e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion):
                    ('a*'b*'c*'d*'e*'f*'g*'h)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {align=alignh, ...} } = h

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg), loadh(s ++ offseth))
        and store (x, (a, b, c, d, e, f, g, h)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h)
        in
            fn () => ( freea(); freeb(); freec(); freed(); freee(); freef(); freeg(); freeh() )
        end
        and updateML(s, (a, b, c, d, e, f, g, h)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c); updateMLd(s ++ offsetd, d);
             updateMLe(s ++ offsete, e); updateMLf(s ++ offsetf, f); updateMLg(s ++ offsetg, g);
             updateMLh(s ++ offseth, h))
        and updateC(x, (a, b, c, d, e, f, g, h)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh]}
    end

    fun cStruct9(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                 e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                 i: 'i conversion): ('a*'b*'c*'d*'e*'f*'g*'h*'i)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {align=aligni, ...} } = i

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti))
        and store (x, (a, b, c, d, e, f, g, h, i)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
        in
            fn () => ( freea(); freeb(); freec(); freed(); freee(); freef(); freeg(); freeh(); freei() )
        end
        and updateML(s, (a, b, c, d, e, f, g, h, i)) =
            (updateMLa(s, a); updateMLb(s ++ offsetb, b); updateMLc(s ++ offsetc, c); updateMLd(s ++ offsetd, d);
             updateMLe(s ++ offsete, e); updateMLf(s ++ offsetf, f); updateMLg(s ++ offsetg, g);
             updateMLh(s ++ offseth, h); updateMLi(s ++ offseti, i))
        and updateC(x, (a, b, c, d, e, f, g, h, i)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei]}
    end

    fun cStruct10(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {align=alignj, ...} } = j

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj))
        and store (x, (a, b, c, d, e, f, g, h, i, j)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej]}
    end

    fun cStruct11(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {align=alignk, ...} } = k

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek]}
    end
    
    fun cStruct12(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {align=alignl, ...} } = l

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel]}
    end
    
    fun cStruct13(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {align=alignm, ...} } = m

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem]}
    end
    
    nonfix o

    fun cStruct14(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {align=alignn, ...} } = n

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen]}
    end

    fun cStruct15(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {align=aligno, ...} } = o

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen(); freeo()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo]}
    end

    fun cStruct16(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion, p: 'p conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {size=sizeo, align=aligno, ...} } = o
        and {load=loadp, store=storep, updateML=updateMLp, updateC=updateCp, ctype = ctypep as {align=alignp, ...} } = p

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)
        val offsetp = alignUp(offseto + sizeo, alignp)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto), loadp(s ++ offsetp))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
            and freep = storep(x ++ offsetp, p)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef();
                    freeg(); freeh(); freei(); freej(); freek(); freel();
                    freem(); freen(); freeo(); freep()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o); updateMLp(x ++ offsetp, p))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o); updateCp(x ++ offsetp, p))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo, ctypep]}
    end

    fun cStruct17(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion, p: 'p conversion,
                  q: 'q conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {size=sizeo, align=aligno, ...} } = o
        and {load=loadp, store=storep, updateML=updateMLp, updateC=updateCp, ctype = ctypep as {size=sizep, align=alignp, ...} } = p
        and {load=loadq, store=storeq, updateML=updateMLq, updateC=updateCq, ctype = ctypeq as {align=alignq, ...} } = q

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)
        val offsetp = alignUp(offseto + sizeo, alignp)
        val offsetq = alignUp(offsetp + sizep, alignq)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto), loadp(s ++ offsetp),
             loadq(s ++ offsetq))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
            and freep = storep(x ++ offsetp, p) and freeq = storeq(x ++ offsetq, q)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen(); freeo(); freep(); freeq()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o); updateMLp(x ++ offsetp, p);
             updateMLq(x ++ offsetq, q))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o); updateCp(x ++ offsetp, p);
             updateCq(x ++ offsetq, q))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo, ctypep, ctypeq]}
    end

    fun cStruct18(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion, p: 'p conversion,
                  q: 'q conversion, r: 'r conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {size=sizeo, align=aligno, ...} } = o
        and {load=loadp, store=storep, updateML=updateMLp, updateC=updateCp, ctype = ctypep as {size=sizep, align=alignp, ...} } = p
        and {load=loadq, store=storeq, updateML=updateMLq, updateC=updateCq, ctype = ctypeq as {size=sizeq, align=alignq, ...} } = q
        and {load=loadr, store=storer, updateML=updateMLr, updateC=updateCr, ctype = ctyper as {align=alignr, ...} } = r

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)
        val offsetp = alignUp(offseto + sizeo, alignp)
        val offsetq = alignUp(offsetp + sizep, alignq)
        val offsetr = alignUp(offsetq + sizeq, alignr)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto), loadp(s ++ offsetp),
             loadq(s ++ offsetq), loadr(s ++ offsetr))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
            and freep = storep(x ++ offsetp, p) and freeq = storeq(x ++ offsetq, q) and freer = storer(x ++ offsetr, r)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen(); freeo(); freep(); freeq(); freer()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o); updateMLp(x ++ offsetp, p);
             updateMLq(x ++ offsetq, q); updateMLr(x ++ offsetr, r))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o); updateCp(x ++ offsetp, p);
             updateCq(x ++ offsetq, q); updateCr(x ++ offsetr, r))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo, ctypep, ctypeq, ctyper]}
    end

    fun cStruct19(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion, p: 'p conversion,
                  q: 'q conversion, r: 'r conversion, s: 's conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r*'s)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {size=sizeo, align=aligno, ...} } = o
        and {load=loadp, store=storep, updateML=updateMLp, updateC=updateCp, ctype = ctypep as {size=sizep, align=alignp, ...} } = p
        and {load=loadq, store=storeq, updateML=updateMLq, updateC=updateCq, ctype = ctypeq as {size=sizeq, align=alignq, ...} } = q
        and {load=loadr, store=storer, updateML=updateMLr, updateC=updateCr, ctype = ctyper as {size=sizer, align=alignr, ...} } = r
        and {load=loads, store=stores, updateML=updateMLs, updateC=updateCs, ctype = ctypes as {align=aligns, ...} } = s

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)
        val offsetp = alignUp(offseto + sizeo, alignp)
        val offsetq = alignUp(offsetp + sizep, alignq)
        val offsetr = alignUp(offsetq + sizeq, alignr)
        val offsets = alignUp(offsetr + sizer, aligns)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto), loadp(s ++ offsetp),
             loadq(s ++ offsetq), loadr(s ++ offsetr), loads(s ++ offsets))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
            and freep = storep(x ++ offsetp, p) and freeq = storeq(x ++ offsetq, q) and freer = storer(x ++ offsetr, r)
            and frees = stores(x ++ offsets, s)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen(); freeo(); freep(); freeq(); freer(); frees()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o); updateMLp(x ++ offsetp, p);
             updateMLq(x ++ offsetq, q); updateMLr(x ++ offsetr, r); updateMLs(x ++ offsets, s))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o); updateCp(x ++ offsetp, p);
             updateCq(x ++ offsetq, q); updateCr(x ++ offsetr, r); updateCs(x ++ offsets, s))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo, ctypep, ctypeq, ctyper, ctypes]}
    end

    fun cStruct20(a: 'a conversion, b: 'b conversion, c: 'c conversion, d: 'd conversion,
                  e: 'e conversion, f: 'f conversion, g: 'g conversion, h: 'h conversion,
                  i: 'i conversion, j: 'j conversion, k: 'k conversion, l: 'l conversion,
                  m: 'm conversion, n: 'n conversion, o: 'o conversion, p: 'p conversion,
                  q: 'q conversion, r: 'r conversion, s: 's conversion, t: 't conversion):
                  ('a*'b*'c*'d*'e*'f*'g*'h*'i*'j*'k*'l*'m*'n*'o*'p*'q*'r*'s*'t)conversion =
    let
        val {load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype = ctypea as {size=sizea, ...} } = a
        and {load=loadb, store=storeb, updateML=updateMLb, updateC=updateCb, ctype = ctypeb as {size=sizeb, align=alignb, ...} } = b
        and {load=loadc, store=storec, updateML=updateMLc, updateC=updateCc, ctype = ctypec as {size=sizec, align=alignc, ...} } = c
        and {load=loadd, store=stored, updateML=updateMLd, updateC=updateCd, ctype = ctyped as {size=sized, align=alignd, ...} } = d
        and {load=loade, store=storee, updateML=updateMLe, updateC=updateCe, ctype = ctypee as {size=sizee, align=aligne, ...} } = e
        and {load=loadf, store=storef, updateML=updateMLf, updateC=updateCf, ctype = ctypef as {size=sizef, align=alignf, ...} } = f
        and {load=loadg, store=storeg, updateML=updateMLg, updateC=updateCg, ctype = ctypeg as {size=sizeg, align=aligng, ...} } = g
        and {load=loadh, store=storeh, updateML=updateMLh, updateC=updateCh, ctype = ctypeh as {size=sizeh, align=alignh, ...} } = h
        and {load=loadi, store=storei, updateML=updateMLi, updateC=updateCi, ctype = ctypei as {size=sizei, align=aligni, ...} } = i
        and {load=loadj, store=storej, updateML=updateMLj, updateC=updateCj, ctype = ctypej as {size=sizej, align=alignj, ...} } = j
        and {load=loadk, store=storek, updateML=updateMLk, updateC=updateCk, ctype = ctypek as {size=sizek, align=alignk, ...} } = k
        and {load=loadl, store=storel, updateML=updateMLl, updateC=updateCl, ctype = ctypel as {size=sizel, align=alignl, ...} } = l
        and {load=loadm, store=storem, updateML=updateMLm, updateC=updateCm, ctype = ctypem as {size=sizem, align=alignm, ...} } = m
        and {load=loadn, store=storen, updateML=updateMLn, updateC=updateCn, ctype = ctypen as {size=sizen, align=alignn, ...} } = n
        and {load=loado, store=storeo, updateML=updateMLo, updateC=updateCo, ctype = ctypeo as {size=sizeo, align=aligno, ...} } = o
        and {load=loadp, store=storep, updateML=updateMLp, updateC=updateCp, ctype = ctypep as {size=sizep, align=alignp, ...} } = p
        and {load=loadq, store=storeq, updateML=updateMLq, updateC=updateCq, ctype = ctypeq as {size=sizeq, align=alignq, ...} } = q
        and {load=loadr, store=storer, updateML=updateMLr, updateC=updateCr, ctype = ctyper as {size=sizer, align=alignr, ...} } = r
        and {load=loads, store=stores, updateML=updateMLs, updateC=updateCs, ctype = ctypes as {size=sizes, align=aligns, ...} } = s
        and {load=loadt, store=storet, updateML=updateMLt, updateC=updateCt, ctype = ctypet as {align=alignt, ...} } = t

        val offsetb = alignUp(sizea, alignb)
        val offsetc = alignUp(offsetb + sizeb, alignc)
        val offsetd = alignUp(offsetc + sizec, alignd)
        val offsete = alignUp(offsetd + sized, aligne)
        val offsetf = alignUp(offsete + sizee, alignf)
        val offsetg = alignUp(offsetf + sizef, aligng)
        val offseth = alignUp(offsetg + sizeg, alignh)
        val offseti = alignUp(offseth + sizeh, aligni)
        val offsetj = alignUp(offseti + sizei, alignj)
        val offsetk = alignUp(offsetj + sizej, alignk)
        val offsetl = alignUp(offsetk + sizek, alignl)
        val offsetm = alignUp(offsetl + sizel, alignm)
        val offsetn = alignUp(offsetm + sizem, alignn)
        val offseto = alignUp(offsetn + sizen, aligno)
        val offsetp = alignUp(offseto + sizeo, alignp)
        val offsetq = alignUp(offsetp + sizep, alignq)
        val offsetr = alignUp(offsetq + sizeq, alignr)
        val offsets = alignUp(offsetr + sizer, aligns)
        val offsett = alignUp(offsets + sizes, alignt)

        fun load s =
            (loada s, loadb(s ++ offsetb), loadc(s ++ offsetc), loadd(s ++ offsetd),
             loade(s ++ offsete), loadf(s ++ offsetf), loadg(s ++ offsetg),
             loadh(s ++ offseth), loadi(s ++ offseti), loadj(s ++ offsetj),
             loadk(s ++ offsetk), loadl(s ++ offsetl), loadm(s ++ offsetm),
             loadn(s ++ offsetn), loado(s ++ offseto), loadp(s ++ offsetp),
             loadq(s ++ offsetq), loadr(s ++ offsetr), loads(s ++ offsets), loadt(s ++ offsett))
        and store (x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t)) =
        let
            val freea = storea(x, a) and freeb = storeb(x ++ offsetb, b) and freec = storec(x ++ offsetc, c)
            and freed = stored(x ++ offsetd, d) and freee = storee(x ++ offsete, e) and freef = storef(x ++ offsetf, f)
            and freeg = storeg(x ++ offsetg, g) and freeh = storeh(x ++ offseth, h) and freei = storei(x ++ offseti, i)
            and freej = storej(x ++ offsetj, j) and freek = storek(x ++ offsetk, k) and freel = storel(x ++ offsetl, l)
            and freem = storem(x ++ offsetm, m) and freen = storen(x ++ offsetn, n) and freeo = storeo(x ++ offseto, o)
            and freep = storep(x ++ offsetp, p) and freeq = storeq(x ++ offsetq, q) and freer = storer(x ++ offsetr, r)
            and frees = stores(x ++ offsets, s) and freet = storet(x ++ offsett, t)
        in
            fn () =>
                (
                    freea(); freeb(); freec(); freed(); freee(); freef(); freeg();
                    freeh(); freei(); freej(); freek(); freel(); freem();
                    freen(); freeo(); freep(); freeq(); freer(); frees(); freet()
                )
        end
        and updateML(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t)) =
            (updateMLa(x, a); updateMLb(x ++ offsetb, b); updateMLc(x ++ offsetc, c); updateMLd(x ++ offsetd, d);
             updateMLe(x ++ offsete, e); updateMLf(x ++ offsetf, f); updateMLg(x ++ offsetg, g);
             updateMLh(x ++ offseth, h); updateMLi(x ++ offseti, i); updateMLj(x ++ offsetj, j);
             updateMLk(x ++ offsetk, k); updateMLl(x ++ offsetl, l); updateMLm(x ++ offsetm, m);
             updateMLn(x ++ offsetn, n); updateMLo(x ++ offseto, o); updateMLp(x ++ offsetp, p);
             updateMLq(x ++ offsetq, q); updateMLr(x ++ offsetr, r); updateMLs(x ++ offsets, s); updateMLt(x ++ offsett, t))
        and updateC(x, (a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t)) =
            (updateCa(x, a); updateCb(x ++ offsetb, b); updateCc(x ++ offsetc, c); updateCd(x ++ offsetd, d);
             updateCe(x ++ offsete, e); updateCf(x ++ offsetf, f); updateCg(x ++ offsetg, g);
             updateCh(x ++ offseth, h); updateCi(x ++ offseti, i); updateCj(x ++ offsetj, j);
             updateCk(x ++ offsetk, k); updateCl(x ++ offsetl, l); updateCm(x ++ offsetm, m);
             updateCn(x ++ offsetn, n); updateCo(x ++ offseto, o); updateCp(x ++ offsetp, p);
             updateCq(x ++ offsetq, q); updateCr(x ++ offsetr, r); updateCs(x ++ offsets, s); updateCt(x ++ offsett, t))
    in
        {load=load, store=store, updateML=updateML, updateC=updateC,
         ctype = LowLevel.cStruct[ctypea, ctypeb, ctypec, ctyped, ctypee, ctypef, ctypeg, ctypeh, ctypei, ctypej,
                                  ctypek, ctypel, ctypem, ctypen, ctypeo, ctypep, ctypeq, ctyper, ctypes, ctypet]}
    end

    (* Conversion for call-by-reference. *)
    local
        open Memory LowLevel
    in
        fun cStar({load=loada, store=storea, ctype=ctypea, ...}: 'a conversion): 'a ref conversion =
        let
            fun store(m, ref s) =
            let
                (* When we pass a ref X into a cStar cX function we need to
                   allocate a memory cell big enough for a cX value.  Then
                   we copy the current value of the ML into this.  We set
                   the argument, a pointer, to the address of the cell. *)
                val mem = malloc(#size ctypea)
                val () = setAddress(m, 0w0, mem)
                val freea = storea(mem, s)
            in
                fn () => (free mem; freea())
            end
            
            (* Called to update the ML value when the C . *)
            fun updateML(m, s) = s := loada(getAddress(m, 0w0))

            (* Used when an ML callback receives a cStar argument. *)
            fun load s = ref(loada(getAddress(s, 0w0)))
            
            (* Used when a callback has returned to update the C value.
               If storea allocates then there's nothing we can do. *)
            fun updateC(m, ref s) = ignore(storea(getAddress(m, 0w0), s))
        in
            {load=load, store=store, updateML=updateML, updateC=updateC, ctype = cTypePointer}
        end

        (* Similar to cStar but without the need to update the result. *)
        fun cConstStar({load=loada, store=storea, updateML=updateMLa, updateC=updateCa, ctype=ctypea}: 'a conversion): 'a conversion =
        let
            fun load s = loada(getAddress(s, 0w0))
            
            fun store(m, s) =
            let
                val mem = malloc(#size ctypea)
                val () = setAddress(m, 0w0, mem)
                val freea = storea(mem, s)
            in
                fn () => (free mem; freea())
            end
            
            (* Do we have to do anything here?  Could we pass a const pointer
               to a structure with variable fields? *)
            fun updateML(m, s) = updateMLa(getAddress(m, 0w0), s)
            and updateC(m, s) = updateCa(getAddress(m, 0w0), s)
        in
            {load=load, store=store, updateML=updateML, updateC=updateC, ctype = cTypePointer}
        end

        (* Fixed size vector.  It is treated as a struct and passed by value or embedded in a structure. *)
        fun cVectorFixedSize(n,
            {load=loadEl, store=storeEl, updateML=updateMLel, updateC=updateCel,
             ctype={size=sizeEl, align=alignEl, ffiType=ffiTypeEl}, ...}: 'a conversion)
                : 'a vector conversion =
        let
            val arraySize = sizeEl * Word.fromInt n
            fun ffiTypeArray () =
                LibFFI.createFFItype {
                    size = arraySize, align = alignEl, typeCode=LibFFI.ffiTypeCodeStruct,
                    elements = List.tabulate (n, fn _ => ffiTypeEl()) }
            val arrayType = { size = arraySize, align = alignEl, ffiType = ffiTypeArray }

            fun load(v: voidStar): 'a vector =
                Vector.tabulate(n, fn i => loadEl(v ++ Word.fromInt i))

            fun store(v: voidStar, s: 'a vector) =
            let
                val sLen = Vector.length s
                val _ = sLen <= n orelse raise Foreign "vector too long"
                (* Store the values.  Make a list of the free fns in case they allocate *)
                val frees = Vector.foldli(fn(i, el, l) => storeEl(v ++ Word.fromInt i, el) :: l) [] s;
            in
                fn () => List.app (fn f => f()) frees
            end
            
            (* If we have a ref in here we need to update *)
            fun updateML(v, s) = Vector.appi(fn (i, el) => updateMLel(v ++ Word.fromInt i, el)) s
            and updateC(v, s) = Vector.appi(fn (i, el) => updateCel(v ++ Word.fromInt i, el)) s
        in
            { load = load, store = store, updateML=updateML, updateC=updateC, ctype = arrayType }
        end

        (* Pass an ML vector as a pointer to a C array. *)
        fun cVectorPointer
            ({store=storeEl, updateML=updateMLel, ctype={size=sizeEl, ...}, ...}: 'a conversion)
                : 'a vector conversion =
        let
            (* We can't determine the size so can't construct a suitable ML value. *)
            fun load _ = raise Foreign "Cannot return a cVectorPointer from C to ML"
            
            fun store(m, s) =
            let
                val mem = malloc(sizeEl * Word.fromInt(Vector.length s))
                val () = setAddress(m, 0w0, mem)
                (* Store the values.  Make a list of the free fns in case they allocate *)
                val frees = Vector.foldli(fn(i, el, l) => storeEl(mem ++ (sizeEl * Word.fromInt i), el) :: l) [] s;
            in
                fn () => (List.app (fn f => f()) frees; free mem)
            end
            
            (* This is only appropriate if the elements are refs. *)
            fun updateML(v, s) =
            let
                val addr = getAddress(v, 0w0)
            in
                Vector.appi(fn (i, el) => updateMLel(addr ++ (sizeEl * Word.fromInt i), el)) s
            end
            (* updateC can't actually be used because we can't load a suitable value *)
            and updateC _ = raise Foreign "Cannot return a cVectorPointer from C to ML"
        in
            {load=load, store=store, updateML=updateML, updateC=updateC, ctype = cTypePointer}
        end

        (* Pass an ML array as a pointer to a C array and, on return, update each element of
           the ML array from the C array. *)
        fun cArrayPointer
            ({load=loadEl, store=storeEl, ctype={size=sizeEl, ...}, ...}: 'a conversion) : 'a array conversion =
        let
            (* We can't determine the size so can't construct a suitable ML value. *)
            fun load _ = raise Foreign "Cannot return a cArrayPointer from C to ML"
            
            fun store(m, s) =
            let
                val mem = malloc(sizeEl * Word.fromInt(Array.length s))
                val () = setAddress(m, 0w0, mem)
                (* Store the values.  Make a list of the free fns in case they allocate *)
                val frees = Array.foldli(fn(i, el, l) => storeEl(mem ++ (sizeEl * Word.fromInt i), el) :: l) [] s;
            in
                fn () => (List.app (fn f => f()) frees; free mem)
            end
            
            (* updateML is used after a C function returns.  It needs to update each element. *)
            fun updateML(v, s) =
            let
                val addr = getAddress(v, 0w0)
            in
                Array.modifyi(fn (i, _) => loadEl(addr ++ (sizeEl * Word.fromInt i))) s
            end

            (* updateC can't actually be used because we can't load a suitable value *)
            and updateC _ = raise Foreign "Cannot return a cArrayPointer from C to ML"
        in
            {load=load, store=store, updateML=updateML, updateC=updateC, ctype = cTypePointer}
        end
    end

    (* Calls with conversion. *)
    (* Note: it may be possible to have general functions to compute offsets
       but we don't do that because this way the compiler can compute the offsets
       as constants during inline expansion. *)
    local
        open LibFFI Memory LowLevel
    in
    
        fun buildCall0withAbi(abi: abi, fnAddr, (), {ctype = resType, load= resLoad, ...} : 'a conversion): unit->'a =
        let
            val callF = callwithAbi abi [] resType fnAddr
        in
            fn () =>
            let
                val rMem = malloc(#size resType)
            in
                let
                    val () = callF(Memory.null, rMem)
                    val result = resLoad rMem
                in
                    free rMem;
                    result
                end handle exn => (free rMem; raise exn)
            end
        end

        fun buildCall0(symbol, argTypes, resType) = buildCall0withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall1withAbi (abi: abi, fnAddr,
            { ctype = argType, store = argStore, updateML = argUpdate, ...}: 'a conversion,
            { ctype = resType, load= resLoad, ...}: 'b conversion): 'a ->'b =
        let
            val callF = callwithAbi abi [argType] resType fnAddr
            (* Allocate space for argument and result. *)
            val argOffset = alignUp(#size resType, #align argType)
            val argSpace = argOffset + #size argType
        in
            fn x =>
            let
                val rMem = malloc argSpace
                val argAddr = rMem ++ argOffset
                val freea = argStore (argAddr, x)
                fun freeAll () = (freea(); free rMem)
            in
                let
                    val () = callF(argAddr, rMem)
                    val result = resLoad rMem
                in
                    argUpdate (argAddr, x);
                    freeAll ();
                    result
                end handle exn => (freeAll (); raise exn)
            end
        end

        fun buildCall1(symbol, argTypes, resType) = buildCall1withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall2withAbi (abi: abi, fnAddr,
            (arg1Conv: 'a conversion, arg2Conv: 'b conversion), resConv: 'c conversion): 'a * 'b -> 'c =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi [#ctype arg1Conv, #ctype arg2Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} = cStruct2(arg1Conv, arg2Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall2(symbol, argTypes, resType) = buildCall2withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall3withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion), resConv: 'd conversion): 'a * 'b *'c -> 'd =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} = cStruct3(arg1Conv, arg2Conv, arg3Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall3(symbol, argTypes, resType) = buildCall3withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall4withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion),
                resConv: 'e conversion): 'a * 'b *'c * 'd -> 'e =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct4(arg1Conv, arg2Conv, arg3Conv, arg4Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall4(symbol, argTypes, resType) = buildCall4withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall5withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion), resConv: 'f conversion): 'a * 'b *'c * 'd * 'e -> 'f =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct5(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall5(symbol, argTypes, resType) = buildCall5withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall6withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion), resConv: 'g conversion): 'a * 'b *'c * 'd * 'e * 'f -> 'g =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct6(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall6(symbol, argTypes, resType) = buildCall6withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall7withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion),
            resConv: 'h conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g -> 'h =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct7(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall7(symbol, argTypes, resType) = buildCall7withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall8withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion),
            resConv: 'i conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h -> 'i =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct8(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall8(symbol, argTypes, resType) = buildCall8withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall9withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion),
            resConv: 'j conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i -> 'j =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct9(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv, arg9Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall9(symbol, argTypes, resType) = buildCall9withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall10withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion, arg10Conv: 'j conversion),
            resConv: 'k conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j -> 'k =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv, #ctype arg10Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct10(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv,
                          arg9Conv, arg10Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall10(symbol, argTypes, resType) = buildCall10withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall11withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion, arg10Conv: 'j conversion, arg11Conv: 'k conversion),
            resConv: 'l conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k -> 'l =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv, #ctype arg10Conv, #ctype arg11Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct11(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv,
                          arg9Conv, arg10Conv, arg11Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall11(symbol, argTypes, resType) = buildCall11withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall12withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion, arg10Conv: 'j conversion, arg11Conv: 'k conversion, arg12Conv: 'l conversion),
            resConv: 'm conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l -> 'm =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv, #ctype arg10Conv, #ctype arg11Conv, #ctype arg12Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct12(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv,
                          arg9Conv, arg10Conv, arg11Conv, arg12Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall12(symbol, argTypes, resType) = buildCall12withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall13withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion, arg10Conv: 'j conversion, arg11Conv: 'k conversion, arg12Conv: 'l conversion,
             arg13Conv: 'm conversion),
            resConv: 'n conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm -> 'n =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv, #ctype arg10Conv, #ctype arg11Conv, #ctype arg12Conv,
                 #ctype arg13Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct13(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv,
                          arg9Conv, arg10Conv, arg11Conv, arg12Conv, arg13Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall13(symbol, argTypes, resType) = buildCall13withAbi (abiDefault, symbol, argTypes, resType)

        fun buildCall14withAbi (abi: abi, fnAddr,
            (arg1Conv:  'a conversion, arg2Conv:  'b conversion, arg3Conv:  'c conversion, arg4Conv:  'd conversion,
             arg5Conv:  'e conversion, arg6Conv:  'f conversion, arg7Conv:  'g conversion, arg8Conv:  'h conversion,
             arg9Conv:  'i conversion, arg10Conv: 'j conversion, arg11Conv: 'k conversion, arg12Conv: 'l conversion,
             arg13Conv: 'm conversion, arg14Conv: 'n conversion),
            resConv: 'o conversion): 'a * 'b *'c * 'd * 'e * 'f * 'g * 'h * 'i * 'j * 'k * 'l * 'm * 'n -> 'o =
        let
            val { ctype = resType, load = resLoad, ...} = resConv
            val callF = callwithAbi abi
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv,
                 #ctype arg7Conv, #ctype arg8Conv, #ctype arg9Conv, #ctype arg10Conv, #ctype arg11Conv, #ctype arg12Conv,
                 #ctype arg13Conv, #ctype arg14Conv] resType fnAddr
            val { store=storeArgs, ctype={size=argSize, ...}, updateML=updateArgs, ...} =
                cStruct14(arg1Conv, arg2Conv, arg3Conv, arg4Conv, arg5Conv, arg6Conv, arg7Conv, arg8Conv,
                          arg9Conv, arg10Conv, arg11Conv, arg12Conv, arg13Conv, arg14Conv)
            val resultOffset = alignUp(argSize, #align resType)
            val argResSpace = resultOffset + #size resType
        in
            fn mlArgs =>
            let
                val rMem = malloc argResSpace
                val freeArgs = storeArgs(rMem, mlArgs)
                fun freeAll() = (freeArgs(); free rMem)
                val resultAddr = rMem++resultOffset
            in
                let
                    val () = callF(rMem, resultAddr)
                    val result = resLoad resultAddr
                in
                    updateArgs(rMem, mlArgs);
                    freeAll();
                    result
                end handle exn => (freeAll(); raise exn)
            end
        end

        fun buildCall14(symbol, argTypes, resType) = buildCall14withAbi (abiDefault, symbol, argTypes, resType)

    end

    (* A closure is a memoised address.  *)
    type 'a closure = unit -> Memory.voidStar

    local
        open Memory LowLevel
        fun load _ = raise Foreign "Cannot return a closure"
        (* "dememoise" the value when we store it.  This means that the closure is actually
           created when the value is first stored and then it is cached. *)
        and store(v, cl: ('a->'b) closure) = (Memory.setAddress(v, 0w0, cl()); fn () => ())
    in
        val cFunction: ('a->'b) closure conversion =
            makeConversion { load=load, store=store, ctype = LowLevel.cTypePointer }
    end

    local
        open LibFFI Memory LowLevel
    in
        fun buildClosure0withAbi(f: unit-> 'a, abi: abi, (), resConv: 'a conversion): (unit->'a) closure =
        let
            fun callback (f: unit -> 'a) (_: voidStar, res: voidStar): unit =
                ignore(#store resConv (res, f ()))
            (* Ignore the result of #store resConv.  What this means is if the
               callback returns something, e.g. a string, that requires
               dynamic allocation there will be a memory leak. *)

            val makeCallback = cFunctionWithAbi abi [] (#ctype resConv)
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure0(f, argConv, resConv) = buildClosure0withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure1withAbi (f: 'a -> 'b, abi: abi, argConv: 'a conversion, resConv: 'b conversion) : ('a -> 'b) closure =
        let
            fun callback (f: 'a -> 'b) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                val arg1 = #load argConv arg1Addr
                val result = f arg1
                val () = #updateC argConv (arg1Addr, arg1)
            in
                ignore(#store resConv (res, result))
            end

            val makeCallback = cFunctionWithAbi abi [#ctype argConv] (#ctype resConv)
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end
   
        fun buildClosure1(f, argConv, resConv) = buildClosure1withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure2withAbi
            (f: 'a * 'b -> 'c, abi: abi, (arg1Conv: 'a conversion, arg2Conv: 'b conversion), resConv: 'c conversion) :
                ('a * 'b -> 'c) closure =
        let
            fun callback (f: 'a *'b -> 'c) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                and arg2Addr = getAddress(args, 0w1)
                val arg1 = #load arg1Conv arg1Addr
                and arg2 = #load arg2Conv arg2Addr

                val result = f (arg1, arg2)

                val () = #updateC arg1Conv(arg1Addr, arg1)
                and () = #updateC arg2Conv(arg2Addr, arg2)
            in
                ignore(#store resConv (res, result))
            end
        
            val argTypes = [#ctype arg1Conv, #ctype arg2Conv]
            and resType = #ctype resConv

            val makeCallback = cFunctionWithAbi abi argTypes resType
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure2(f, argConv, resConv) = buildClosure2withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure3withAbi
            (f, abi, (arg1Conv: 'a conversion, arg2Conv: 'b conversion, arg3Conv: 'c conversion), resConv: 'd conversion) =
        let
            fun callback (f: 'a *'b * 'c -> 'd) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                and arg2Addr = getAddress(args, 0w1)
                and arg3Addr = getAddress(args, 0w2)
                val arg1 = #load arg1Conv arg1Addr
                and arg2 = #load arg2Conv arg2Addr
                and arg3 = #load arg3Conv arg3Addr

                val result = f (arg1, arg2, arg3)

                val () = #updateC arg1Conv(arg1Addr, arg1)
                and () = #updateC arg2Conv(arg2Addr, arg2)
                and () = #updateC arg3Conv(arg3Addr, arg3)
            in
                ignore(#store resConv (res, result))
            end
        
            val argTypes =
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv]
            and resType = #ctype resConv

            val makeCallback = cFunctionWithAbi abi argTypes resType
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure3(f, argConv, resConv) = buildClosure3withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure4withAbi
            (f, abi,
                (arg1Conv: 'a conversion, arg2Conv: 'b conversion, arg3Conv: 'c conversion, arg4Conv: 'd conversion),
             resConv: 'e conversion) =
        let
            fun callback (f: 'a *'b * 'c * 'd -> 'e) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                and arg2Addr = getAddress(args, 0w1)
                and arg3Addr = getAddress(args, 0w2)
                and arg4Addr = getAddress(args, 0w3)
                val arg1 = #load arg1Conv arg1Addr
                and arg2 = #load arg2Conv arg2Addr
                and arg3 = #load arg3Conv arg3Addr
                and arg4 = #load arg4Conv arg4Addr

                val result = f (arg1, arg2, arg3, arg4)

                val () = #updateC arg1Conv(arg1Addr, arg1)
                and () = #updateC arg2Conv(arg2Addr, arg2)
                and () = #updateC arg3Conv(arg3Addr, arg3)
                and () = #updateC arg4Conv(arg4Addr, arg4)
            in
                ignore(#store resConv (res, result))
            end
        
            val argTypes =
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv, #ctype arg4Conv]
            and resType = #ctype resConv

            val makeCallback = cFunctionWithAbi abi argTypes resType
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure4(f, argConv, resConv) = buildClosure4withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure5withAbi
            (f, abi,
                (arg1Conv: 'a conversion, arg2Conv: 'b conversion, arg3Conv: 'c conversion,
                 arg4Conv: 'd conversion, arg5Conv: 'e conversion),
             resConv: 'f conversion) =
        let
            fun callback (f: 'a *'b * 'c * 'd * 'e -> 'f) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                and arg2Addr = getAddress(args, 0w1)
                and arg3Addr = getAddress(args, 0w2)
                and arg4Addr = getAddress(args, 0w3)
                and arg5Addr = getAddress(args, 0w4)
                val arg1 = #load arg1Conv arg1Addr
                and arg2 = #load arg2Conv arg2Addr
                and arg3 = #load arg3Conv arg3Addr
                and arg4 = #load arg4Conv arg4Addr
                and arg5 = #load arg5Conv arg5Addr

                val result = f (arg1, arg2, arg3, arg4, arg5)

                val () = #updateC arg1Conv(arg1Addr, arg1)
                and () = #updateC arg2Conv(arg2Addr, arg2)
                and () = #updateC arg3Conv(arg3Addr, arg3)
                and () = #updateC arg4Conv(arg4Addr, arg4)
                and () = #updateC arg5Conv(arg5Addr, arg5)
            in
                ignore(#store resConv (res, result))
            end
        
            val argTypes =
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv,
                     #ctype arg4Conv, #ctype arg5Conv]
            and resType = #ctype resConv

            val makeCallback = cFunctionWithAbi abi argTypes resType
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure5(f, argConv, resConv) = buildClosure5withAbi(f, abiDefault, argConv, resConv)

        fun buildClosure6withAbi
            (f, abi,
                (arg1Conv: 'a conversion, arg2Conv: 'b conversion, arg3Conv: 'c conversion,
                 arg4Conv: 'd conversion, arg5Conv: 'e conversion, arg6Conv: 'f conversion),
             resConv: 'g conversion) =
        let
            fun callback (f: 'a *'b * 'c * 'd * 'e * 'f -> 'g) (args: voidStar, res: voidStar): unit =
            let
                val arg1Addr = getAddress(args, 0w0)
                and arg2Addr = getAddress(args, 0w1)
                and arg3Addr = getAddress(args, 0w2)
                and arg4Addr = getAddress(args, 0w3)
                and arg5Addr = getAddress(args, 0w4)
                and arg6Addr = getAddress(args, 0w5)
                val arg1 = #load arg1Conv arg1Addr
                and arg2 = #load arg2Conv arg2Addr
                and arg3 = #load arg3Conv arg3Addr
                and arg4 = #load arg4Conv arg4Addr
                and arg5 = #load arg5Conv arg5Addr
                and arg6 = #load arg6Conv arg6Addr

                val result = f (arg1, arg2, arg3, arg4, arg5, arg6)

                val () = #updateC arg1Conv(arg1Addr, arg1)
                and () = #updateC arg2Conv(arg2Addr, arg2)
                and () = #updateC arg3Conv(arg3Addr, arg3)
                and () = #updateC arg4Conv(arg4Addr, arg4)
                and () = #updateC arg5Conv(arg5Addr, arg5)
                and () = #updateC arg6Conv(arg6Addr, arg6)
            in
                ignore(#store resConv (res, result))
            end
        
            val argTypes =
                [#ctype arg1Conv, #ctype arg2Conv, #ctype arg3Conv,
                     #ctype arg4Conv, #ctype arg5Conv, #ctype arg6Conv]
            and resType = #ctype resConv

            val makeCallback = cFunctionWithAbi abi argTypes resType
        in
            Memory.memoise (fn () => makeCallback(callback f)) ()
        end

        fun buildClosure6(f, argConv, resConv) = buildClosure6withAbi(f, abiDefault, argConv, resConv)

    end
end;
