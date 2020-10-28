#pragma once
/*
    Title: bytecode.h - Header for common code for the byte-code interpreter

    Copyright (c) 2006, 2015-17, 2020 David C.J. Matthews

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

*/
#ifndef BYTECODE_H_INCLUDED
#define BYTECODE_H_INCLUDED

#include "globals.h"

class TaskData;

class ByteCodeInterpreter
{
protected:
    ByteCodeInterpreter();
    ~ByteCodeInterpreter();

    enum _returnValue {
        ReturnTailCall,
        ReturnCall,
        ReturnReturn
    };
    enum _returnValue RunInterpreter(TaskData* taskData);

    virtual void SaveInterpreterState(POLYCODEPTR pc, stackItem* sp) = 0;
    virtual void LoadInterpreterState(POLYCODEPTR& pc, stackItem*& sp) = 0;
    virtual void ClearExceptionPacket() = 0;
    virtual PolyWord GetExceptionPacket() = 0; // Exception packet is set via TaskData::SetException
    virtual stackItem* GetHandlerRegister() = 0;
    virtual void SetHandlerRegister(stackItem* hr) = 0;
    virtual void CheckStackAndInterrupt(POLYUNSIGNED space, POLYCODEPTR& pc, stackItem*& sp) = 0;

    void GarbageCollect(ScanAddress* process);
    bool mixedCode;
    int numTailArguments;

private:
    PolyObject *overflowPacket, *dividePacket;

private:
    inline PolyObject* allocateMemory(TaskData* taskData, POLYUNSIGNED words, POLYCODEPTR& pc, stackItem*& sp);
    inline PolyObject* ByteCodeInterpreter::boxDouble(TaskData* taskData, double d, POLYCODEPTR& pc, stackItem*& sp);
    inline double ByteCodeInterpreter::unboxDouble(PolyWord p);
    inline float ByteCodeInterpreter::unboxFloat(PolyWord p);
    inline PolyObject* ByteCodeInterpreter::boxFloat(TaskData* taskData, float f, POLYCODEPTR& pc, stackItem*& sp);

#ifdef PROFILEOPCODES
    unsigned frequency[256], arg1Value[256], arg2Value[256];
#endif
};

extern struct _entrypts byteCodeEPT[];

#endif

