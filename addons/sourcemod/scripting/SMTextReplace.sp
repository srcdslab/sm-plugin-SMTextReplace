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
	version = "1.2",
	url = ""
};

Handle g_Cvar_Randomcolor = INVALID_HANDLE;
int UseRandomColors = 0;
int CountColors = 0;

char TextColors[MAXTEXTCOLORS][256];

public void OnPluginStart()
{
	g_Cvar_Randomcolor = CreateConVar( "sm_textcol_random", "1", "Uses random colors that you defined. 1- random 0-Default");

	RegAdminCmd("sm_reloadstc", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads Text color's config file");
	RegAdminCmd("sm_test_stc", Command_Test, ADMFLAG_CONFIG, "Print a text with default [SM] in it.");

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
	HookConVarChange(g_Cvar_Randomcolor, OnConVarChanged);

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
	UseRandomColors = GetConVarInt(g_Cvar_Randomcolor);

	for (int X = 0; X < MAXTEXTCOLORS; X++)
	{
		//Format(TextColors[X], sizeof(TextColors), "");
		TextColors[X] = "";
	}

	char sPaths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPaths, sizeof(sPaths),"configs/sm_textcolors.cfg");
	Handle hFile = OpenFile(sPaths, "r");

	//int len;
	char sBuffer[256]; 
	CountColors = -1;

	while (ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
	{
		/*len = strlen(sBuffer);
		if (sBuffer[len-1] == '\n')
			sBuffer[--len] = '\0';*/

		TrimString(sBuffer);

		if(!StrEqual(sBuffer,"",false)){
			
			ReplaceString(sBuffer, sizeof(sBuffer), "*", "\x08");
			ReplaceString(sBuffer, sizeof(sBuffer), "&", "\x07");
			CountColors++;
			Format(TextColors[CountColors], sizeof(TextColors), "%s", sBuffer);
			PrintToChatAll("\x01%s", sBuffer);
		}
	}
	CloseHandle(hFile);
}

public Action TextMsg(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if(CountColors != -1)
	{
		if(reliable)
		{
			char buffer[256];
			if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
				PbReadString(bf, "params", buffer, sizeof(buffer), 0);
			else
				BfReadString(bf, buffer, sizeof(buffer));

			if(StrContains(buffer, "\x03[SM]") == 0 || StrContains(buffer, "\x01[SM]") == 0 || StrContains(buffer, "[SM]") == 0)
			{
				Handle pack;
				CreateDataTimer(0.0, timer_strip, pack);

				WritePackCell(pack, playersNum);
				for(int i = 0; i < playersNum; i++)
				{
					WritePackCell(pack, players[i]);
				}
				WritePackString(pack, buffer);
				ResetPack(pack);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action timer_strip(Handle timer, Handle pack)
{
	int playersNum = ReadPackCell(pack);
	int[] players = new int[playersNum];
	int client, count;

	for(int i = 0; i < playersNum; i++)
	{
		client = ReadPackCell(pack);
		if(IsClientInGame(client))
		{
			players[count++] = client;
		}
	}

	if(count < 1) return Plugin_Handled;
	
	playersNum = count;
	
	char buffer[255];
	ReadPackString(pack, buffer, sizeof(buffer));
	char QuickFormat[255];
	int ColorChoose = 0;
	if(UseRandomColors == 1) ColorChoose = GetRandomInt(0, CountColors);
	Format(QuickFormat, sizeof(QuickFormat), "%s", TextColors[ColorChoose]);
	ReplaceStringEx(buffer, sizeof(buffer), "[SM]", QuickFormat);

	CFormatColor(buffer, sizeof(buffer), -1);
	CAddWhiteSpace(buffer, sizeof(buffer));

	Handle SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	if (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(SayText2, "ent_idx", -1);
		PbSetBool(SayText2, "chat", true);
		PbSetString(SayText2, "msg_name", buffer);
		PbAddString(SayText2, "params", "");
		PbAddString(SayText2, "params", "");
		PbAddString(SayText2, "params", "");
		PbAddString(SayText2, "params", "");
		EndMessage();
	}
	else
	{
		BfWriteByte(SayText2, -1);
		BfWriteByte(SayText2, true);
		BfWriteString(SayText2, buffer);
		EndMessage();
	}

	return Plugin_Continue;
}
