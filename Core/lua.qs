//
// Copyright (C) 2021-2022  Andrei Karas (4144)
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

function registerLua()
{
    function lua_loadBefore(existingName, newNamesList, free)
    {
        checkArgs("lua.loadBefore", arguments, [["String", "Object"], ["String", "Object", "Number"]]);
        return lua.load(existingName, newNamesList, [], true, free);
    }

    function lua_loadAfter(existingName, newNamesList, free)
    {
        checkArgs("lua.loadAfter", arguments, [["String", "Object"], ["String", "Object", "Number"]]);
        return lua.load(existingName, [], newNamesList, true, free);
    }

    function lua_replace(existingName, newNamesList, free)
    {
        checkArgs("lua.replace", arguments, [["String", "Object"], ["String", "Object", "Number"]]);
        return lua.load(existingName, newNamesList, [], false, free);
    }

    function lua_getCLuaLoadInfo(stackOffset)
    {
        checkArgs("lua.getCLuaLoadInfo", arguments, [["Number"]]);
        var type = table.getValidated(table.CLua_Load_type);
        var obj = new Object();
        obj.type = type;
        obj.pushLine = "push dword ptr [esp + argsOffset + " + stackOffset + "]";
        if (type == 4)
        {
            obj.asmCopyArgs = asm.combine(
                obj.pushLine,
                obj.pushLine,
                obj.pushLine
            );
            obj.argsOffset = 0xc;
        }
        else if (type == 3)
        {
            obj.asmCopyArgs = asm.combine(
                obj.pushLine,
                obj.pushLine
            );
            obj.argsOffset = 0x8;
        }
        else if (type == 2)
        {
            obj.asmCopyArgs = asm.combine(
                obj.pushLine
            );
            obj.argsOffset = 0x4;
        }
        else
        {
            fatalError("Unsupported CLua_Load type");
        }

        return obj;
    }

    function lua_getLoadObj(origFile, beforeNameList, afterNameList, loadDefault)
    {
        checkArgs("lua.getLoadObj",
            arguments,
            [
                ["String", "Object", "Object", "Boolean"],
                ["String", "Array", "Array", "Boolean"]
            ]
        );

        consoleLog("Find original file name string");
        var origOffset = pe.stringVa(origFile);
        if (origOffset === -1)
            throw "LUAFL: Filename missing: " + origFile;

        var strHex = origOffset.packToHex(4);

        consoleLog("Find original file name usage");
        var type = table.getValidated(table.CLua_Load_type);
        var mLuaAbsHex = table.getSessionAbsHex4(table.CSession_m_lua_offset);
        var mLuaHex = table.getHex4(table.CSession_m_lua_offset);
        var CLua_Load = table.get(table.CLua_Load);

        if (type == 4)
        {
            var code =
                "8B 8E " + mLuaHex +          // 0 mov ecx, g_session.m_lua
                "6A ?? " +                    // 6 push 0
                "6A ?? " +                    // 8 push 1
                "68 " + strHex +              // 10 push offset aLuaFilesQues_3
                "E8 ";                        // 15 call CLua_Load
            var moveOffset = [0, 6];
            var pushFlagsOffset = [6, 4];
            var afterStolenCodeOffset = 10;
            var postOffset = 20;
            var otherOffset = 0;
            var otherOffset2 = 0;
            var callOffset = [16, 4];
            var hookLoader = pe.find(code);
            if (hookLoader === -1)
            {
                code =
                    "8B 0D " + mLuaAbsHex +       // 0 mov ecx, g_session.m_lua
                    "6A ?? " +                    // 6 push 0
                    "6A ?? " +                    // 8 push 1
                    "68 " + strHex +              // 10 push offset aLuaFilesQues_3
                    "E8 ";                        // 15 call CLua_Load
                moveOffset = [0, 6];
                pushFlagsOffset = [6, 4];
                afterStolenCodeOffset = 10;
                postOffset = 20;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [16, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "8B 8E " + mLuaHex +          // 0 mov ecx, [esi+5434h]
                    "53 " +                       // 6 push ebx
                    "6A ?? " +                    // 7 push 1
                    "68 " + strHex +              // 9 push offset aLuaFilesData_0
                    "E8 ";                        // 14 call CLua_Load
                moveOffset = [0, 6];
                pushFlagsOffset = [6, 3];
                afterStolenCodeOffset = 9;
                postOffset = 19;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [15, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "6A ?? " +                    // 0 push 0
                    "6A ?? " +                    // 2 push 1
                    "68 " + strHex +              // 4 push offset aLuaFilesWorl_1
                    "8B CE " +                    // 9 mov ecx, esi
                    "E8 "                         // 11 call CLua_Load
                moveOffset = [9, 2];
                pushFlagsOffset = [0, 4];
                afterStolenCodeOffset = 0;
                postOffset = 16;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [12, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "8B CE " +                    // 0 mov ecx, esi
                    "6A ?? " +                    // 2 push 0
                    "6A ?? " +                    // 4 push 1
                    "68 " + strHex +              // 6 push offset aLuaFilesWorldv
                    "89 B5 ?? ?? ?? FF " +        // 11 mov [ebp+var_2A0], esi
                    "E8 "                         // 17 call CLua_Load
                moveOffset = [0, 2];
                pushFlagsOffset = [2, 4];
                afterStolenCodeOffset = 6;
                postOffset = 22;
                otherOffset = [11, 6];
                otherOffset2 = 0;
                callOffset = [18, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "6A ?? " +                    // 0 push 0
                    "6A ?? " +                    // 2 push 1
                    "68 " + strHex +              // 4 push offset aLuaFilesWorl_2
                    "8B CF " +                    // 9 mov ecx, edi
                    "E8 "                         // 11 call CLua_Load
                moveOffset = [9, 2];
                pushFlagsOffset = [0, 4];
                afterStolenCodeOffset = 0;
                postOffset = 16;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [12, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "53 " +                       // 0 push ebx
                    "6A ?? " +                    // 1 push 1
                    "68 " + strHex +              // 3 push offset aLuaFilesWorl_2
                    "8B CE " +                    // 8 mov ecx, esi
                    "E8 "                         // 10 call CLua_Load
                moveOffset = [8, 2];
                pushFlagsOffset = [0, 3];
                afterStolenCodeOffset = 0;
                postOffset = 15;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [11, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "53 " +                       // 0 push ebx
                    "6A ?? " +                    // 1 push 1
                    "89 8D ?? ?? ?? FF " +        // 3 mov [ebp+var_164], ecx
                    "68 " + strHex +              // 9 push offset aLuaFilesWorldv
                    "8B CE " +                    // 14 mov ecx, esi
                    "89 B5 ?? ?? ?? FF " +        // 16 mov [ebp+lua], esi
                    "E8 "                         // 22 call CLua_Load
                moveOffset = [14, 2];
                pushFlagsOffset = [0, 3];
                afterStolenCodeOffset = 0;
                postOffset = 27;
                otherOffset = [3, 6];
                otherOffset2 = [16, 6];
                callOffset = [23, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                var code =
                    "6A ?? " +                    // 0 push 0
                    "6A ?? " +                    // 2 push 1
                    "68 " + strHex +              // 4 push offset aLuaFilesWorldv
                    "8B CF " +                    // 9 mov ecx, edi
                    "89 BD ?? ?? ?? FF " +        // 11 mov [ebp+lua], edi
                    "E8 "                         // 17 call CLua_Load
                moveOffset = [9, 2];
                pushFlagsOffset = [0, 4];
                afterStolenCodeOffset = 0;
                postOffset = 22;
                otherOffset = [11, 6];
                otherOffset2 = 0;
                callOffset = [18, 4];
                hookLoader = pe.find(code);
            }
        }
        else if (type == 3)
        {
            var code =
                "8B 8E " + mLuaHex +          // 0 mov ecx, g_session.m_lua
                "6A ?? " +                    // 6 push 1
                "68 " + strHex +              // 8 push offset aLuaFilesQues_3
                "E8 ";                        // 13 call CLua_Load
            var moveOffset = [0, 6];
            var pushFlagsOffset = [6, 2];
            var afterStolenCodeOffset = 8;
            var postOffset = 18;
            var otherOffset = 0;
            var otherOffset2 = 0;
            var callOffset = [14, 4];
            var hookLoader = pe.find(code);
            if (hookLoader === -1)
            {
                code =
                    "8B 0D " + mLuaAbsHex +       // 0 mov ecx, g_session.m_lua
                    "6A ?? " +                    // 6 push 1
                    "68 " + strHex +              // 8 push offset aLuaFilesQues_3
                    "E8 ";                        // 13 call CLua_Load
                moveOffset = [0, 6];
                pushFlagsOffset = [6, 2];
                afterStolenCodeOffset = 8;
                postOffset = 18;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [14, 4];
                hookLoader = pe.find(code);
            }
        }
        else if (type == 2)
        {
            var code =
                "8B 8E " + mLuaHex +          // 0 mov ecx, g_session.m_lua
                "68 " + strHex +              // 6 push offset aLuaFilesQues_3
                "E8 ";                        // 11 call CLua_Load
            var moveOffset = [0, 6];
            var pushFlagsOffset = 0;
            var afterStolenCodeOffset = 6;
            var postOffset = 16;
            var otherOffset = 0;
            var otherOffset2 = 0;
            var callOffset = [12, 4];
            var hookLoader = pe.find(code);
            if (hookLoader === -1)
            {
                code =
                    "8B 0D " + mLuaAbsHex +       // 0 mov ecx, g_session.m_lua
                    "68 " + strHex +              // 6 push offset aLuaFilesQues_3
                    "E8 ";                        // 11 call CLua_Load
                moveOffset = [0, 6];
                pushFlagsOffset = 0;
                afterStolenCodeOffset = 6;
                postOffset = 16;
                otherOffset = 0;
                otherOffset2 = 0;
                callOffset = [12, 4];
                hookLoader = pe.find(code);
            }
            if (hookLoader === -1)
            {
                code =
                    "8B 8E " + mLuaHex +          // 0 mov ecx, [esi+44D8h]
                    "83 C4 ?? " +                 // 6 add esp, 4
                    "68 " + strHex +              // 9 push offset aLuaFilesDatain
                    "E8 ";                        // 14 call CLua_Load
                moveOffset = [0, 6];
                pushFlagsOffset = 0;
                afterStolenCodeOffset = 9;
                postOffset = 19;
                otherOffset = [6, 3];
                otherOffset2 = 0;
                callOffset = [15, 4];
                hookLoader = pe.find(code);
            }
        }
        else
        {
            fatalError("Unsupported CLua_Load type");
        }

        if (hookLoader === -1)
            throw "LUAFL: CLua_Load call missing: " + origFile;

        var retLoader = hookLoader + postOffset;

        var callValue = pe.fetchRelativeValue(hookLoader, callOffset);
        if (callValue !== CLua_Load)
            throw "LUAFL: found wrong call function: " + origFile;

        consoleLog("Read stolen code");
        if (moveOffset !== 0)
        {
            var movStolenCode = pe.fetchHexBytes(hookLoader, moveOffset);
        }
        else
        {
            var movStolenCode = "";
        }
        if (pushFlagsOffset !== 0)
        {
            var pushFlagsStolenCode = pe.fetchHexBytes(hookLoader, pushFlagsOffset);
        }
        else
        {
            var pushFlagsStolenCode = "";
        }
        var customStolenCode = movStolenCode + pushFlagsStolenCode;
        if (otherOffset !== 0)
        {
            var otherStoleCode = pe.fetchHexBytes(hookLoader, otherOffset);
        }
        else
        {
            var otherStoleCode = "";
        }
        if (otherOffset2 !== 0)
        {
            otherStoleCode += pe.fetchHexBytes(hookLoader, otherOffset2);
        }
        if (afterStolenCodeOffset != 0)
        {
            var defaultStolenCode = pe.fetchHex(hookLoader, afterStolenCodeOffset);
        }
        else
        {
            var defaultStolenCode = customStolenCode;
        }

        consoleLog("Construct asm code with strings");
        var stringsCode = "";
        for (var i = 0; i < beforeNameList.length; i++)
        {
            stringsCode = asm.combine(
                stringsCode,
                "varb" + i + ":",
                asm.stringToAsm(beforeNameList[i] + "\x00")
            )
        }
        for (var i = 0; i < afterNameList.length; i++)
        {
            stringsCode = asm.combine(
                stringsCode,
                "vara" + i + ":",
                asm.stringToAsm(afterNameList[i] + "\x00")
            )
        }

        consoleLog("Create own code");

        var asmCode = asm.hexToAsm(otherStoleCode);

        consoleLog("Add before code");
        for (var i = 0; i < beforeNameList.length; i++)
        {
            var asmCode = asm.combine(
                asmCode,
                asm.hexToAsm(customStolenCode),
                "push varb" + i,
                "call CLua_Load"
            )
        }

        if (loadDefault === true)
        {
            consoleLog("Add default code");
            var asmCode = asm.combine(
                asmCode,
                asm.hexToAsm(defaultStolenCode),
                "push offset",
                "call CLua_Load"
            )
        }

        consoleLog("Add after code");
        for (var i = 0; i < afterNameList.length; i++)
        {
            var asmCode = asm.combine(
                asmCode,
                asm.hexToAsm(customStolenCode),
                "push vara" + i,
                "call CLua_Load"
            )
        }

        consoleLog("Add jmp and strings");
        var text = asm.combine(
            asmCode,
            "jmp continueAddr",
            asm.hexToAsm("00"),
            stringsCode
        )

        consoleLog("Set own code into exe");
        var vars = {
            "offset": origOffset,
            "CLua_Load": CLua_Load,
            "continueAddr": pe.rawToVa(retLoader)
        };

        var obj = Object();
        obj.hookAddrRaw = hookLoader;
        obj.asmText = text;
        obj.vars = vars;
        return obj;
    }

    function lua_load(origFile, beforeNameList, afterNameList, loadDefault, free)
    {
        checkArgs("lua.load",
            arguments,
            [
                ["String", "Object", "Object", "Boolean"],
                ["String", "Array", "Array", "Boolean"],
                ["String", "Object", "Object", "Boolean", "Number"],
                ["String", "Array", "Array", "Boolean", "Number"],
                ["String", "Object", "Object", "Boolean", "Undefined"],
                ["String", "Array", "Array", "Boolean", "Undefined"]
            ]
        );

        var loadObj = lua.getLoadObj(origFile, beforeNameList, afterNameList, loadDefault);

        if (typeof(free) === "undefined" || free === -1)
        {
            var obj = pe.insertAsmTextObj(loadObj.asmText, loadObj.vars);
            var free = obj.free;
        }
        else
        {
            pe.replaceAsmText(free, loadObj.asmText, loadObj.vars);
        }

        consoleLog("Set jmp to own code");
        pe.setJmpRaw(loadObj.hookAddrRaw, free, "jmp", 6);

        return true;
    }

    lua = new Object();
    lua.loadBefore = lua_loadBefore;
    lua.loadAfter = lua_loadAfter;
    lua.replace = lua_replace;
    lua.getCLuaLoadInfo = lua_getCLuaLoadInfo;
    lua.getLoadObj = lua_getLoadObj;
    lua.load = lua_load;
}
