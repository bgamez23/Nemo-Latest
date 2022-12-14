//==================================================//
// Patch Functions wrapping over ExtendBox function //
//==================================================//

function ExtendChatBox()
{
  return ExtendBox(3);
}

function ExtendChatRoomBox()
{
  return ExtendBox(0);
}

function ExtendPMBox()
{
  return ExtendBox(2);
}

//##############################################################
//# Purpose: Change the Box Limit from 70 (0x46) to 234 (0xEA) #
//##############################################################

function ExtendBox(index)
{

  var offset_for_patch = 3;

  //Step 1 - Find the Box Limiter Code - Atleast 4 matches should be there
  //         MOV DWORD PTR DS:[EAX+byte], 0x46
  var offsets = pe.findCodes(" C7 40 ?? 46 00 00 00");

  // new client detected, so!
  if (offsets.length < 4)
  {
    offset_for_patch = 6;
    offsets = pe.findCodes(" C7 80 ?? ?? ?? ?? 46 00 00 00");
  }

  if (offsets.length < 4)
    return "Failed in Step 1";

  //Step 2 - Change the limit
  // 0 = Chat Room
  // 1 = Unknown
  // 2 = Private Message
  // 3 = Chat Box
  pe.replaceByte(offsets[index] + offset_for_patch, 0xEA);

  return true;
}
