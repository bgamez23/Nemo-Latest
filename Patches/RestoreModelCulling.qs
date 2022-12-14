//#####################################################################
//# Purpose: Make models in front of player turn transparent          #
//#####################################################################

/**
 * This seems to be yet another features that never got completed.
 *
 * Source:
 *
 * void C3dActor::CullByOBB(lineSegment3d *ray)
 * {
 *   if (this->m_isHideCheck)
 *   {
 *     if (CheckLineSegmentOBBIntersect(ray, &this->m_oBoundingBox))
 *       this->m_node->SetAlpha();
 *   }
 * }
 *
 * C3dActor instances are always initialized with m_isHideCheck = false.
 * C3dNode::SetAlpha sets C3dNode::m_isAlphaForPlayer, but this variable
 * only affects lighting and not opacity. We can instead use
 * C3dActor::m_isHalfAlpha, which affects C3dActor::m_fadeAlphaCnt.
 *
 * Our desired result:
 *
 * void C3dActor::CullByOBB(lineSegment3d *ray)
 * {
 *   if (1)
 *   {
 *     if (CheckLineSegmentOBBIntersect(ray, &this->m_oBoundingBox))
 *       this->m_isHalfAlpha = 1;
 *   }
 * }
 *
 */

function RestoreModelCulling()
{

    //New clients - find 2 m_isHideCheck and skip.
    var offsets = pe.findCodes(" 80 BE 54 01 00 00 01");

    if (offsets.length === 2)
    {
        for (var i = 0; i < offsets.length; i++)
        {
            if (pe.fetchUByte(offsets[i] + 7) != 0x75)  //Check JNZ follow by m_isHideCheck
                return "Failed in Step 1a - No JNZ found.";
            pe.replaceHex(offsets[i] + 7, " 90 90");
        }
        return true;
    }

    //Step 1a - Locate C3dActor::CullByOBB (should be first instance in exe)
  // LEA EAX, [ESI+130h] (eax = &m_oBoundingBox)
  // PUSH EAX
    var pBase = pe.findCode(" 8D 86 30 01 00 00 50");
    if (pBase === -1)
        return "Failed in Step 1 - No match for C3dActor::CullByOBB!";

    //Step 2a - Locate the jump on m_isHideCheck
    var jmpCodes = [" 74 1D", " 74 1E", " 74 1F"]; //JZ LOC_END
    var pJmpHideCheck = -1;

    for (var i = 0; i < jmpCodes.length; i++)
    {
        pJmpHideCheck = pe.find(jmpCodes[i], pBase - 10, pBase);
        if (pJmpHideCheck !== -1)
            break;
    }

    if (pJmpHideCheck === -1)
        return "Failed in Step 2 - Missing jump condition for m_isHideCheck";

    //Step 2b - Change the JZ to NOP
    pe.replaceHex(pJmpHideCheck, " 90 90");

    //Step 3a - Find call to C3dNode::SetToAlpha
    // MOV ECX, DWORD PTR DS:[ESI]
    // CALL addr
    var pSetAlpha = pe.find(" 8B 0E E8", pBase + 7, pBase + 30);
    if (pSetAlpha === -1)
        return "Failed in Step 3 - Missing SetToAlpha call";

    //Step 3b - Change the MOV & CALL to m_isHalfAlpha assignment.
    // MOV BYTE PTR DS:[ESI+1ECh], 1h ; (m_isHalfAlpha = 1)
    pe.replaceHex(pSetAlpha, " C6 86 EC 01 00 00 01");

    return true;
}
