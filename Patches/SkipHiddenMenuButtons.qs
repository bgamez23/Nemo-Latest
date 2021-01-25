//
// Copyright (C) 2018-2021  Andrei Karas (4144)
//
// Hercules is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//#############################################################
//# Purpose: Allow skip hidden menu buttons in                #
//# UIMenuIconWnd_virt56                                      #
//#############################################################

function SkipHiddenMenuButtons()
{
    // step 1 - search string status_doram
    var strHex = exe.findString("status_doram", RVA).packToHex(4);

    // step 2 - search start for do/while block in adding buttons
    var code =
        "8D B5 AB AB AB AB" +  // 0 lea esi, [ebp+names]
        "89 8D AB AB AB AB" +  // 6 mov [ebp+cnt2], ecx
        "8B 18" +              // 12 mov ebx, [eax]
        "81 FB AB AB 00 00" +  // 14 cmp ebx, 0A9h    <-- stole code here
        "75 AB" +              // 20 jnz short loc_577BA6
        "FF 35 AB AB AB AB" +  // 22 push g_session.jobId
        getEcxSessionHex() +   // 28 mov ecx, offset g_session
        "E8 AB AB AB AB" +     // 33 call is_doram_job
        "3C 01" +              // 38 cmp al, 1
        "75 0E" +              // 40 jnz short loc_577BA0
        "6A 0C" +              // 42 push 0Ch
        "68 " + strHex +       // 44 push offset "status_doram"
        "8B CE" +              // 45 mov ecx, esi
        "E8"                   // 47 call std_string_from_chars_size
    var nonA9Offset = 21;
    var a9Offset = 22;
    var stoleOffset = 14;
    var stoleSize = 6;
    var regName = "esi";
    var noSwitch = false;
    var jobIdOffset = [24, 4];
    var isDoramJobOffset = 34;
    var offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");

    if (offset === -1)
    {
        code =
            "8D BD AB AB AB AB " +        // 0 lea edi, [ebp+names]
            "C7 85 AB AB AB AB 00 00 00 00 " + // 6 mov [ebp+var_31C], 0
            "89 B5 AB AB AB AB " +        // 16 mov [ebp+var_310], esi
            "81 3E AB AB 00 00 " +        // 22 cmp dword ptr [esi], 0AEh
            "75 AB " +                    // 28 jnz short loc_5862FE
            "FF 35 AB AB AB AB " +        // 30 push g_session.jobId
            getEcxSessionHex() +          // 36 mov ecx, offset g_session
            "E8 AB AB AB AB " +           // 41 call is_doram_job
            "3C 01 " +                    // 46 cmp al, 1
            "75 AB " +                    // 48 jnz short loc_5862FE
            "6A 0C " +                    // 50 push 0Ch
            "68 " + strHex +              // 52 push offset aStatus_doram
            "8B CF " +                    // 57 mov ecx, edi
            "E8";                         // 59 call std_string_assign

        nonA9Offset = 29;
        a9Offset = 30;
        stoleOffset = 22;
        stoleSize = 6;
        regName = "edi";
        jobIdOffset = [32, 4];
        isDoramJobOffset = 42;
        noSwitch = false;
        offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    }
    if (offset === -1)
    {
        code =
            "8D BD AB AB AB AB " +        // 0 lea edi, [ebp+names]
            "C7 85 AB AB AB AB 00 00 00 00 " + // 6 mov [ebp+var_31C], 0
            "89 9D AB AB AB AB " +        // 16 mov [ebp+var_310], ebx
            "81 3B AB AB 00 00 " +        // 22 cmp dword ptr [ebx], 0AEh
            "75 AB " +                    // 28 jnz short loc_5862FE
            "FF 35 AB AB AB AB " +        // 30 push g_session.jobId
            getEcxSessionHex() +          // 36 mov ecx, offset g_session
            "E8 AB AB AB AB " +           // 41 call is_doram_job
            "3C 01 " +                    // 46 cmp al, 1
            "75 AB " +                    // 48 jnz short loc_5862FE
            "6A 0C " +                    // 50 push 0Ch
            "68 " + strHex +              // 52 push offset aStatus_doram
            "8B CF " +                    // 57 mov ecx, edi
            "E8";                         // 59 call std_string_assign

        nonA9Offset = 29;
        a9Offset = 30;
        stoleOffset = 22;
        stoleSize = 6;
        regName = "edi";
        jobIdOffset = [32, 4];
        isDoramJobOffset = 42;
        noSwitch = false;
        offset = exe.findCode(code, PTYPE_HEX, true, "\xAB");
    }

    if (offset === -1)
        return "Failed in step 2 - pattern not found";
    offset1 = offset;

    logFieldAbs("CSession::m_job", offset, jobIdOffset);
    logRawFunc("CSession_isDoramJob", offset, isDoramJobOffset);

    var nonA9JmpAddr = exe.Raw2Rva(exe.fetchByte(offset + nonA9Offset) + offset + nonA9Offset + 1);
    var a9JmpAddr = exe.Raw2Rva(offset + a9Offset);
    var patchAddr = offset + stoleOffset;

    // step 3 - search switch block and non default jmp in switch (using first one jump)
    code =
        "8D 83 AB AB AB AB" +     // 0 lea eax, [ebx-164h]
        "3D AB AB 00 00" +        // 6 cmp eax, 0A6h
        "77 0E" +                 // 11 ja short loc_577BC1
        "0F B6 80 AB AB AB AB" +  // 13 movzx eax, switch1[eax]
        "FF 24 85 AB AB AB AB";   // 20 jmp switch2[eax*4]
    var switch1Offset = 16;
    var switch2Offset = 23;
    offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);

    if (offset === -1)
    {
        var code =
            "8B 06 " +                    // 0 mov eax, [esi]
            "05 AB AB AB FF " +           // 2 add eax, 0FFFFFE97h
            "3D AB AB 00 00 " +           // 7 cmp eax, 0B5h
            "77 0E " +                    // 12 ja short loc_58631A
            "0F B6 80 AB AB AB AB " +     // 14 movzx eax, ds:switch1[eax]
            "FF 24 85 AB AB AB AB ";      // 21 jmp ds:switch2[eax*4]
        switch1Offset = 17;
        switch2Offset = 24;
        noSwitch = false;
        offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);
    }

    var jmpOffset1 = 0;
    var jmpOffset2 = 0;

    if (offset === -1)
    {
        code =
          " 2D AB AB 00 00"    //0 sub eax, 1E9h
        + " 0F 84 AB AB 00 00" //5 jz continueAddr
        + " 83 E8 AB"          //11 sub eax, 7h
        + " 0F 84 AB AB 00 00" //14 jz continueAddr
        ;
        noSwitch = true;
        jmpOffset1 = 7;
        jmpOffset2 = 16;
        offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);
    }

    if (offset === -1)
    {
        code =
          " 2D AB AB 00 00"    //0 sub eax, 1E9h
        + " 0F 84 AB AB 00 00" //5 jz continueAddr
        + " 2D AB AB 00 00"    //11 sub eax, 86h
        + " 0F 84 AB AB 00 00" //16 jz continueAddr
        ;

//        code = code.replace(" 83 E8 AB", " 2D AB AB 00 00"); //sub eax,86h
        noSwitch = true;
        jmpOffset1 = 7;
        jmpOffset2 = 18;
        offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);
    }

    if (offset === -1)
    {
        code =
          " 81 FB AB AB 00 00" //0 cmp ebx,162h
        + " 0F 84 AB AB 00 00" //6 jz continueAddr
        + " 81 FB AB AB 00 00" //12 cmp ebx,203h
        + " 0F 84 AB AB 00 00" //18 jz continueAddr
        ;
        noSwitch = true;
        jmpOffset1 = 8;
        jmpOffset2 = 20;
        offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);
    }

        if (offset === -1)
    {
        code =
          " 81 FB AB AB 00 00" //0 cmp ebx,164h
        + " 0F 84 AB AB 00 00" //6 jz continueAddr
        + " 81 FB AB AB 00 00" //12 cmp ebx,208h
        + " 7E AB"             //18 jle short
        + " 81 FB AB AB 00 00" //20 cmp ebx,20Ah
        + " 0F 8E AB AB 00 00" //26 jle continueAddr
        ;
        noSwitch = true;
        jmpOffset1 = 8;
        jmpOffset2 = 28;
        offset = exe.find(code, PTYPE_HEX, true, "\xAB", offset1, offset1 + 0x50);
    }


    if (offset === -1)
        return "Failed in Step 3 - switch not found";

    if (noSwitch)
    {
        var jmpAdd1 = exe.fetchDWord(offset + jmpOffset1);
        var jmpAdd2 = exe.fetchDWord(offset + jmpOffset2);
        var continueAddr = exe.Raw2Rva(offset + jmpOffset1 + 4) + jmpAdd1;
        var continueAddr2 = exe.Raw2Rva(offset + jmpOffset2 + 4) + jmpAdd2;
        if (continueAddr !== continueAddr2)
            return "Failed in Step 3.1 - Found wrong continueAddr";
    }
    else
    {
        // get switch jmp address for value 0
        var addr1 = exe.Rva2Raw(exe.fetchDWord(offset + switch1Offset));
        var addr2 = exe.Rva2Raw(exe.fetchDWord(offset + switch2Offset));
        var offset1 = exe.fetchUByte(addr1);
        var continueAddr = exe.fetchDWord(addr2 + 4 * offset1);
    }

    // step 4 - patch code

    // add own extra checks

    var vars = {
        "continueAddr": continueAddr,
        "a9JmpAddr": a9JmpAddr,
        "nonA9JmpAddr": nonA9JmpAddr,
    };

    var text = asm.combine(
        "mov eax, [" + regName + "]",  // strlen
        "cmp eax, 0",
        "jne _continue1",
        "jmp continueAddr",
        "_continue1:",
        asm.hexToAsm(exe.fetchHex(patchAddr, stoleSize)),  // cmp ebx, 0A9
        "jne _continue2",
        "jmp a9JmpAddr",
        "_continue2:",
        "jmp nonA9JmpAddr");

    var size = asm.textToHexVaLength(0, text, vars);

    var free = exe.findZeros(size);
    if (free === -1)
        return "Failed in Step 2 - Not enough free space";

    var obj = asm.textToHexRaw(free, text, vars);
    if (obj === false)
        return "Asm code error";

    exe.insert(free, size, obj, PTYPE_HEX);


    consoleLog("add jump to own code");

    var text = asm.combine(
        "push addr1",
        "ret"
    )
    var vars = {
        "addr1": exe.Raw2Rva(free),
    };

    var obj = asm.textToHexRaw(patchAddr, text, vars);
    if (obj === false)
        return "Asm code error";

    exe.replace(patchAddr, obj, PTYPE_HEX); // add jump to own code

    return true;
}

function SkipHiddenMenuButtons_()
{
    return (exe.findString("status_doram", RAW) !== -1);
}
