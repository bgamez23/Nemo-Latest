//#######################################################################################
//# Purpose: Change all JZ/JNZ/CMOVNZ after g_readFolderFirst comparison to NOP/JMP/MOV #
//#          (Also sets g_readFolderFirst to 1 in the process as failsafe).             #
//#######################################################################################

function ReadDataFolderFirst()
{
    //Step 1a - Find address of "loading" (g_readFolderFirst is assigned just above it)
    var offset = pe.stringVa("loading");
    if (offset === -1)
        return "Failed in Step 1 - loading not found";

    //Step 1b - Find its reference
    var code =
        " 74 07"                    //JZ SHORT addr - skip the below code
      + " C6 05 ?? ?? ?? ?? 01"     //MOV BYTE PTR DS:[g_readFolderFirst], 1
      + " 68" + offset.packToHex(4) //PUSH offset ; "loading"
    ;

    var repl = " 90 90";  //Change JZ SHORT to NOPs
    var gloc = 4;  //relative position from offset2 where g_readFolderFirst is
    var firstOffset = 0;

    var offset2 = pe.findCode(code);

    if (offset2 === -1)
    {
        code =
            " 0F 45 ??"                 //CMOVNZ reg32_A, reg32_B
          + " 88 ?? ?? ?? ?? ??"        //MOV BYTE PTR DS:[g_readFolderFirst], reg8_A
          + " 68" + offset.packToHex(4) //PUSH offset ; "loading"
        ;

        repl = " 90 8B";  //change CMOVNZ to NOP + MOV
        gloc = 5;
        firstOffset = 0;

        offset2 = pe.findCode(code);
    }

    if (offset2 === -1)
    {   // 2019-02-13+
        code =
            "0F B6 0D ?? ?? ?? ?? " +     // 0 movzx ecx, g_readFolderFirst
            "85 C0 " +                    // 7 test eax, eax
            "68 " + offset.packToHex(4) + // 9 push offset aLoading
            "0F 45 CE " +                 // 14 cmovnz ecx, esi
            "88 0D ";                     // 17 mov g_readFolderFirst, cl
        repl = " 90 8B";  //change CMOVNZ to NOP + MOV
        gloc = 3;
        firstOffset = 14;
        offset2 = pe.findCode(code);
    }

    if (offset2 === -1)
        return "Failed in Step 1 - loading reference missing";

    //Step 1c - Change conditional instruction to permanent setting - as a failsafe
    pe.replaceHex(offset2 + firstOffset, repl);

    //===================================================================//
    // Client also compares g_readFolderFirst even before it is assigned //
    // sometimes hence we also fix up the comparisons.                   //
    //===================================================================//

    //Step 2a - Extract g_readFolderFirst
    var gReadFolderFirst = pe.fetchDWord(offset2 + gloc);

    //Step 2b - Look for Comparison Pattern 1 - VC9+ Clients
    var offsets = pe.findCodes(" 80 3D" + gReadFolderFirst.packToHex(4) + " 00"); //CMP DWORD PTR DS:[g_readFolderFirst], 0

    if (offsets.length !== 0)
    {
        for (var i = 0; i < offsets.length; i++)
        {
            //Step 2c - Find the JZ SHORT below each Comparison
            offset = pe.find(" 74 ?? E8", offsets[i] + 0x7, offsets[i] + 0x20);  //JZ SHORT addr followed by a CALL
            if (offset === -1)
                return "Failed in Step 2 - Iteration No." + i;

            //Step 2d - NOP out the JZ
            pe.replaceHex(offset, " 90 90");
        }

        return true;
    }

    //Step 3a - Look for Comparison Pattern 2 - Older clients
    offsets = pe.findCodes(" A0" + gReadFolderFirst.packToHex(4)); //MOV AL, DWORD PTR DS:[g_readFolderFirst]
    if (offsets === -1)
        return "Failed in Step 3 - No Comparisons found";

    for (var i = 0; i < offsets.length; i++)
    {
        //Step 4b - Find the JZ below each Comparison
        offset = pe.find(" 0F 84 ?? ?? 00 00", offsets[i] + 0x5, offsets[i] + 0x20);  //JZ addr
        if (offset === -1)
            return "Failed in Step 3 - Iteration No." + i;

        //Step 4c - Replace with 6 NOPs
        pe.replaceHex(offset, " 90 90 90 90 90 90");
    }

    return true;
}
