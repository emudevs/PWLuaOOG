-- 1.3.6
require "scripts/binary"

Roles = {}
AlreadyGM = {}

function Connected()
	Console:Log("���������� �����������")
end

function Disconnected()
	Console:Log("���������� ���������")
	Console:Log("��� ������ ������� Enter")
	Console:ReadLine()
end

function Received(opcode, length)
	--Console:Log("������ ����� �� �������: 0x" .. NumToHex(opcode))
	if opcode == 0x01 then
		LogginAnnounce()
	elseif opcode == 0x03 then
		EnchashKey = ReceivedPacket:ReadBytes(ReceivedPacket:ReadByte())
		AuthSuccess()
		CMKey()
	elseif opcode == 0x04 then
		AccountKey = ReceivedPacket:ReadDword()
		RoleList(-1)
	elseif opcode == 0x05 then
		ErrorInfo(ReceivedPacket:ReadByte())
	elseif opcode == 0x47 then
		EnterWorld()
	elseif opcode == 0x53 then
		ReceivedPacket:Seek(4)
		local nextslot = ReceivedPacket:ReadDword()
		ReceivedPacket:Seek(8)
		if ReceivedPacket:ReadByte() == 1 then -- isChar
			local roleid = ReceivedPacket:ReadDword()
			Roles[#Roles + 1] = roleid
			local gender = ReceivedPacket:ReadByte()
			local race = ReceivedPacket:ReadByte()
			local occupation = ReceivedPacket:ReadByte()
			local level = ReceivedPacket:ReadDword()
			local level2 = ReceivedPacket:ReadDword() -- �����������/������
			local name = ReceivedPacket:ReadUString()
			RoleList_Re(roleid, gender, race, occupation, level, level2, name)
			RoleList(nextslot)
		else
			RoleList_End()
		end
	elseif opcode == 0x85 then
		ReceivedPacket:ReadByte() -- Type
		ReceivedPacket:ReadByte() -- Emotion
		local wid = ReceivedPacket:ReadDword()
		local nick = ReceivedPacket:ReadUString()
		local message = ReceivedPacket:ReadUString()
		if wid ~= 100 then -- FromWID
			Console:Warning(string.format("from %s: %s", nick, message))
			--GetAddCashSNArg()
			--PrivateChat(wid, nick, "^FF0000����");
			--PrivateChat(wid, nick, "^FF00FF&G�& ������: �����������, &" .. nick .. "&! � ��� ���� ����� ������, ����� ����� ��� ������ � ������� ���� ����!");
			--PrivateChat(wid, nick, "&G�& ������: ����");
			-- if string.find(message, "d_gm", 1, true) ~= nil then
				-- PrivateChat(wid, nick, "GM ����� ������������. ������ ��� �������� GM ������. ��� ������������� ��������� d_panel")
				-- AlreadyGM[wid] = 1
			-- elseif string.find(message, "d_item", 1, true) ~= nil or string.find(message, "d_ban", 1, true) ~= nil or string.find(message, "d_restart", 1, true) ~= nil then
				-- PrivateChat(wid, nick, "������ ������� �������� ������ ��� ���������������.")
			-- elseif string.find(message, "d_panel", 1, true) ~= nil then
				-- AlreadyGM[wid] = 2
				-- PrivateChat(wid, nick, "��������� �������:")
				-- PrivateChat(wid, nick, "d_item <id> � ��������� �������� � ������� �����.")
				-- PrivateChat(wid, nick, "d_ban <id> <time> <reason> � ���������� ���������.")
				-- PrivateChat(wid, nick, "d_restart � ������������ �������.")
			-- elseif AlreadyGM[wid] == nil then
				-- PrivateChat(wid, nick, "��� ������ GM �����. ��� ��������� ��������� � ������� ��� ������� d_gm")
				-- AlreadyGM[wid] = 0
			-- elseif AlreadyGM[wid] == 0 then
				-- PrivateChat(wid, nick, "��� ��������� GM ���� ��������� � ������� ��� ������� d_gm")
			-- elseif AlreadyGM[wid] == 1 then
				-- PrivateChat(wid, nick, "��� ��������� GM ������ ��������� � ������� ��� ������� d_panel")
			-- elseif AlreadyGM[wid] == 2 then
				-- PrivateChat(wid, nick, "��������� �������:")
				-- PrivateChat(wid, nick, "d_item <id> � ��������� �������� � ������� �����.")
				-- PrivateChat(wid, nick, "d_ban <id> <time> <reason> � ���������� ���������.")
				-- PrivateChat(wid, nick, "d_restart � ������������ �������.")
			-- end
		end
	elseif opcode == 0x7B then
		ReceivedPacket:Seek(9)
		local timeleft = ReceivedPacket:ReadDword()
		local setbantime = ReceivedPacket:ReadDword()
		local message = ReceivedPacket:ReadUString()
		Console:Warning(string.format("���� ��������.\n������� �������: %s\n�����, ���������� �� �������������: %s ���", message, math.floor(timeleft / 60)))
	end
end

function ReceivedSubPacket(opcode, length)
	--Console:Log("������ ����� " .. opcode)
	if opcode == 0x08 then
		Console:Success("�������� ����� � ���")
	elseif opcode == 0xDE then
		SendPacket:WriteDword(ReceivedPacket:ReadDword())
		SendPacket:WriteBytes({0x00, 0x00, 0x00, 0x00})
		SendPacket:PackContainer(0x61)
		SendPacket:Send(0x22)
		--PublicChat("{magic_code}<0><0:0>{magic_code}<0><0:0>{magic_code}<0><0:0>")
		--Console:Log("������� ����� ������� �� ����")
	end
end

function GetAddCashSNArg()
	SendPacket:WriteDword(RoleID, true)
	SendPacket:WriteDword(1, true)
	SendPacket:Send(0x202)
end

function PrivateChat(wid, nick, message)
	SendPacket:WriteByte(0x0A)
	SendPacket:WriteByte(0xE8)
	SendPacket:WriteByte(0x00)
	SendPacket:WriteDword(RoleID, true)
	SendPacket:WriteUString(nick)
	SendPacket:WriteDword(wid, true)
	SendPacket:WriteUString(message)
	SendPacket:WriteByte(0x00)
	SendPacket:WriteDword(wid, true)
	SendPacket:Send(0x60)
	Console:Success(string.format("to %s: %s", nick, message))
end

function SelectRole(roleindex)
	RoleID = Roles[roleindex]
	SendPacket:WriteDword(RoleID, true)
	SendPacket:WriteByte(0)
	SendPacket:Send(0x46)
	--Console:Log("��������� ����� 0x46")
end

function EnterWorld()
	SendPacket:WriteDword(RoleID, true)
	SendPacket:WriteBytes({0x00, 0x00, 0x00, 0x00})
	SendPacket:WriteBytes({0x00, 0x00, 0x00, 0x00})
	SendPacket:WriteBytes({0x00, 0x00, 0x00, 0x00})
	SendPacket:Send(0x48)
	--Console:Log("��������� ����� 0x48")
end

function RoleList(slot)
	SendPacket:WriteDword(AccountKey, true)
	SendPacket:WriteBytes({0x00, 0x00, 0x00, 0x00})
	SendPacket:WriteDword(slot, true)
	SendPacket:Send(0x52)
	--Console:Log("��������� ����� 0x52")
end

function CMKey()
	Math:RandomTable("SMKey", 16)
	SendPacket:WriteByte(#SMKey)
	SendPacket:WriteBytes(SMKey)
	SendPacket:WriteByte(0x01) -- Force
	Protocol:InitRC4(EnchashKey, SMKey, hash, login)
	SendPacket:Send(0x03)
	--Console:Log("��������� ����� 0x02")
end

function LogginAnnounce()
	SendPacket:WriteString(login)
	Crypt:GetHash(login, password, ReceivedPacket:ReadBytes(ReceivedPacket:ReadByte()), "hash")
	SendPacket:WriteByte(#hash)
	SendPacket:WriteBytes(hash)
	SendPacket:WriteBytes({0x00, 0x04, 0xFF, 0xFF, 0xFF, 0xFF}) -- ���� ��������� ���������
	SendPacket:Send(0x02)
	--Console:Log("��������� ����� 0x03")
end