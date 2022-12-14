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

function AddCLSRandomOption()
{
    lua.replace("Lua Files\\DataInfo\\AddRandomOption_F", ["lua files\\cls\\addrandomoption_f"]);

    lua.loadBefore("Lua Files\\DataInfo\\EnumVAR", ["lua files\\cls\\enumvar"]);
    lua.loadBefore("Lua Files\\DataInfo\\AddRandomOptionNameTable", ["lua files\\cls\\randomoption"]);

    return true;
}

function AddCLSRandomOption_()
{
    return pe.stringRaw("Lua Files\\DataInfo\\AddRandomOption_F") !== -1 || table.get(table.packetVersion) > 20140900;
}
