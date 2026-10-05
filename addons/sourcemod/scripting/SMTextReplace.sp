#include <sourcemod>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define MAXTEXTCOLORS 100

public Plugin myinfo =
{
	name = "Default SM Text Replacer",
	author = "Mitch/Bacardi",
	description = "Replaces the '[SM]' text with more color!",
	version = "1.2.3",
	url = ""
};

ConVar g_cvRandomColor;
int UseRandomColors = 0;
int CountColors = 0;

char TextColors[MAXTEXTCOLORS][256];

public void OnPluginStart()
{
	g_cvRandomColor = CreateConVar("sm_textcol_random", "1", "Uses random colors that you defined. 1- random 0-Default");

	RegAdminCmd("sm_reloadstc", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Text color's config file");
	RegAdminCmd("sm_test_stc", Command_Test, ADMFLAG_CONFIG, "Print a text with default [SM] in it.");

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
	g_cvRandomColor.AddChangeHook(OnConVarChanged);

	AutoExecConfig(true);
}

public Action Command_ReloadConfig(int client, int args)
{
	RefreshConfig();
	LogAction(client, -1, "Reloaded [SM] Text replacer config file");
	ReplyToCommand(client, "[STC] Reloaded config file.");
	return Plugin_Handled;
}

public Action Command_Test(int client, int args)
{
	if (client < 1)
		ReplyToCommand(client, "[STC] Can't see the display results from the server console.");
	else
		PrintToChat(client, "[SM] If you see prefix colored. That works!");
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	RefreshConfig();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	RefreshConfig();
}

stock void RefreshConfig()
{
	UseRandomColors = g_cvRandomColor.IntValue;

	for (int X = 0; X < MAXTEXTCOLORS; X++)
	{
		TextColors[X][0] = '\0';
	}

	char sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths), "configs/sm_textcolors.cfg");
	File hFile = OpenFile(sPaths, "r");

	CountColors = -1;

	if (hFile == null)
	{
		LogError("[STC] Could not open %s", sPaths);
		return;
	}

	char sBuffer[256];

	while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
	{
		TrimString(sBuffer);

		if (sBuffer[0] != '\0')
		{
			if (CountColors + 1 >= MAXTEXTCOLORS)
			{
				LogError("[STC] %s has more than %d colors defined, ignoring the rest", sPaths, MAXTEXTCOLORS);
				break;
			}

			ReplaceString(sBuffer, sizeof(sBuffer), "*", "\x08");
			ReplaceString(sBuffer, sizeof(sBuffer), "&", "\x07");
			CountColors++;
			strcopy(TextColors[CountColors], sizeof(TextColors[]), sBuffer);
			PrintToChatAll("\x01%s", sBuffer);
		}
	}
	delete hFile;
}

public Action TextMsg(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (CountColors == -1 || !reliable)
		return Plugin_Continue;

	char buffer[256];
	if (GetUserMessageType() == UM_Protobuf)
		view_as<Protobuf>(bf).ReadString("params", buffer, sizeof(buffer), 0);
	else
		view_as<BfRead>(bf).ReadString(buffer, sizeof(buffer));

	if (StrContains(buffer, "\x03[SM]") == 0 || StrContains(buffer, "\x01[SM]") == 0 || StrContains(buffer, "[SM]") == 0)
	{
		DataPack pack;
		CreateDataTimer(0.0, timer_strip, pack);

		pack.WriteCell(playersNum);
		for (int i = 0; i < playersNum; i++)
		{
			pack.WriteCell(GetClientUserId(players[i]));
		}
		pack.WriteString(buffer);
		pack.Reset();
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action timer_strip(Handle timer, DataPack pack)
{
	int playersNum = pack.ReadCell();
	int[] players = new int[playersNum];
	int client, count;

	for (int i = 0; i < playersNum; i++)
	{
		client = GetClientOfUserId(pack.ReadCell());
		if (client && IsClientInGame(client))
		{
			players[count++] = client;
		}
	}

	if (count < 1)
		return Plugin_Stop;

	playersNum = count;

	char buffer[256];
	pack.ReadString(buffer, sizeof(buffer));

	int ColorChoose = 0;
	if (UseRandomColors == 1)
		ColorChoose = GetRandomInt(0, CountColors);

	ReplaceStringEx(buffer, sizeof(buffer), "[SM]", TextColors[ColorChoose]);

	CFormatColor(buffer, sizeof(buffer), -1);

	Handle SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	if (SayText2 == null)
		return Plugin_Stop;

	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(SayText2);
		pb.SetInt("ent_idx", -1);
		pb.SetBool("chat", true);
		pb.SetString("msg_name", buffer);
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
		pb.AddString("params", "");
	}
	else
	{
		BfWrite bfw = UserMessageToBfWrite(SayText2);
		bfw.WriteByte(-1);
		bfw.WriteByte(true);
		bfw.WriteString(buffer);
	}
	EndMessage();

	return Plugin_Stop;
}
