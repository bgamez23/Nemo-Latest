//##################################################################################
//# Purpose: NOP out the JNE after LangType Comparison (but before PUSH 0 and      #
//#          PUSH 'questID2display.txt') in ITEM_INFO::InitItemInfoTables function #
//##################################################################################

function ReadQuestid2displaydottxt()
{
    //Step 1a - Find address of questID2display.txt
    var txtHex = pe.stringHex4("questID2display.txt");

    //Step 1b - Find its reference
    var code =
        " 6A 00" +       // PUSH 0
        " 68" + txtHex;  // PUSH addr2 ; "questID2display.txt"
    var offset = pe.findCode(code);//VC9+ Clients

    if (offset === -1)
    {
        code =
            " 6A 00" +       // PUSH 0
            " 8D ?? ??" +    // LEA reg32, [LOCAL.x]
            " 68" + txtHex;  // PUSH addr2 ; "questID2display.txt"
        offset = pe.findCode(code);//Older Clients
    }

    if (offset === -1)
        return "Failed in Step 1";

    //Step 2 - Replace JNE before PUSH 0 with NOP (for long JNE, byte at offset - 1 will be 0)
    if (pe.fetchByte(offset - 1) === 0)
        pe.replaceHex(offset - 6, " 90 90 90 90 90 90");
    else
        pe.replaceHex(offset - 2, " 90 90");

    return true;
}

function ReadQuestid2displaydottxt_()
{
    return !IsZero() && (pe.stringRaw("questID2display.txt") !== -1);
}
