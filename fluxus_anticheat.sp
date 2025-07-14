/*
 * Fluxus Anticheat 1.0.0 Beta - Anticheat para CS:S (SourceMod)
 * Autor: regiselronds
 * Versão: 1.0.0 Beta
 * Licença: MIT
 * GitHub: https://github.com/FluxusAnticheat/FluxusAnticheat-1.0
 * 
 * ATENÇÃO: Este é apenas um teste/experimento. Use por sua conta e risco.
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Fluxus Anticheat"
#define PLUGIN_VERSION "1.0.0 Beta"
#define PLUGIN_AUTHOR "regiselronds"
#define PLUGIN_DESCRIPTION "Anticheat para CS:S - Apenas um teste/experimento"
#define ADMIN_STEAMID "SEU_STEAMID_AQUI" // Substitua pelo seu SteamID

/*
 * COMO CONFIGURAR ADMIN:
 * 1. Substitua "SEU_STEAMID_AQUI" pelo seu SteamID
 * 2. Para encontrar seu SteamID:
 *    - Vá em https://steamidfinder.com/
 *    - Digite seu nome de usuário
 *    - Copie o SteamID (formato: STEAM_0:1:XXXXXXXX)
 * 3. Exemplo: #define ADMIN_STEAMID "STEAM_0:1:123456789"
 * 
 * ATENÇÃO: Este é apenas um teste/experimento. Use por sua conta e risco.
 */

// Configurações otimizadas para CS:S
#define AIMBOT_THRESHOLD 100.0    // Reduzido para detectar aimbot mais precisamente
#define WALLHACK_ANGLE 25.0       // Mais sensível para wallhack
#define TRIGGERBOT_TICK 2         // Menos sensível
#define DUCK_TICKS 3
#define DUCK_LIMIT 40
#define BAN_THRESHOLD 3
#define AIMBOT_SHAKE_DELTA 3.0    // Menos sensível
#define AIMBOT_SHAKE_WINDOW 40    // Janela maior
#define AIMBOT_SHAKE_THRESHOLD 15 // Mais tolerante
#define WALLHACK_FOCUS_TICKS 30   // Reduzido para detectar wallhack mais rapidamente
#define SPEEDHACK_LIMIT 600.0

// Configurações de Bunnyhop (Ajustadas para evitar falsos positivos)
#define BHOP_CONSECUTIVE_JUMPS 15  // Pulos consecutivos para detectar
#define BHOP_SPEED_GAIN_THRESHOLD 80.0  // Ganho de velocidade mínimo
#define BHOP_SPEED_LIMIT 550.0    // Velocidade máxima permitida
#define BHOP_SPEED_TICKS 60       // Ticks para manter velocidade
#define BHOP_PERFECT_TIMING 5     // Pulos com timing perfeito
#define BHOP_STRAFE_CHANGES 25    // Mudanças de strafe para detectar

// Novas configurações para detecção melhorada
#define WALLHACK_SHOOT_ANGLE 15.0  // Ângulo para detectar tiro na parede
#define WALLHACK_SHOOT_TICKS 20    // Ticks para detectar tiro na parede
#define AIMBOT_SNAP_THRESHOLD 80.0 // Threshold para snap aimbot
#define AIMBOT_HEADSHOT_ANGLE 10.0 // Ângulo para detectar headshot sem mirar
#define AIMBOT_KILL_WITHOUT_AIM 5  // Detectar kill sem mirar no alvo

// Sistema de pontuação simplificado
#define SUSPICION_SCORE_LIMIT 20  // Aumentado para ser mais tolerante
#define AIMBOT_SCORE 4            // Mais pontos por aimbot
#define TRIGGERBOT_SCORE 3        // Pontos por triggerbot
#define BHOP_SCORE 2              // Pontos por bhop
#define WALLHACK_SCORE 3          // Pontos por wallhack
#define NO_RECOIL_SCORE 4         // Pontos por no recoil
#define CONVAR_SCORE 1            // Pontos por convar suspeita

// Limites de warnings por tipo de cheat
#define BHOP_WARNINGS_LIMIT 2      // Banido após 2 warnings
#define TRIGGERBOT_WARNINGS_LIMIT 2 // Banido após 2 warnings
#define DUCK_WARNINGS_LIMIT 2       // Banido após 2 warnings
#define SPEEDHACK_WARNINGS_LIMIT 1  // Banido após 1 warning
#define AIMBOT_WARNINGS_LIMIT 3     // Banido após 3 warnings
#define WALLHACK_WARNINGS_LIMIT 3   // Banido após 3 warnings
#define NO_RECOIL_WARNINGS_LIMIT 3  // Banido após 3 warnings
#define VARACAO_SHOTS_LIMIT 8       // Precisa atirar 8 vezes para ser suspeito

// Variáveis globais
new bool:g_AnticheatEnabled = true;
new bool:g_AlreadyBanned[MAXPLAYERS+1];
new bool:g_Reported[MAXPLAYERS+1];

// Sistema de pontuação
new g_SuspicionScore[MAXPLAYERS+1];
new g_LastScoreUpdate[MAXPLAYERS+1];
new bool:g_ScoreLogged[MAXPLAYERS+1];

// Warnings específicos
new g_BhopWarnings[MAXPLAYERS+1];
new g_TriggerbotWarnings[MAXPLAYERS+1];
new g_DuckWarnings[MAXPLAYERS+1];
new g_SpeedhackWarnings[MAXPLAYERS+1];
new g_AimbotWarnings[MAXPLAYERS+1];
new g_WallhackWarnings[MAXPLAYERS+1];
new g_NoRecoilWarnings[MAXPLAYERS+1];
new g_VaracaoShots[MAXPLAYERS+1];

// Variáveis de detecção
new g_AimbotShakeCount[MAXPLAYERS+1];
new g_AimbotShakeWindow[MAXPLAYERS+1];
new g_WallFocusTicks[MAXPLAYERS+1][MAXPLAYERS+1];
new g_BhopSpeedTicks[MAXPLAYERS+1];
new g_LastGroundTick[MAXPLAYERS+1];
new g_PerfectBhopCount[MAXPLAYERS+1];
new Float:g_LastPerfectBhopTime[MAXPLAYERS+1];
new Float:g_PerfectBhopSpeedSum[MAXPLAYERS+1];
new g_NoRecoilShots[MAXPLAYERS+1];
new g_NoRecoilHits[MAXPLAYERS+1];
new Float:g_LastShotPos[MAXPLAYERS+1][3];
new g_ConsecutivePerfectShots[MAXPLAYERS+1];
new g_LastWeapon[MAXPLAYERS+1];
new g_AimbotMathematicalPattern[MAXPLAYERS+1];
new Float:g_LastAngularVelocity[MAXPLAYERS+1];

// Novas variáveis para detecção melhorada de wallhack e aimbot
new g_WallShootTicks[MAXPLAYERS+1][MAXPLAYERS+1];  // Ticks mirando na parede onde está inimigo
new g_WallShootCount[MAXPLAYERS+1];                // Contador de tiros na parede
new g_AimbotSnapCount[MAXPLAYERS+1];               // Contador de snaps para cabeça
new g_AimbotKillWithoutAim[MAXPLAYERS+1];          // Contador de kills sem mirar
new g_LastAimTarget[MAXPLAYERS+1];                 // Último alvo que estava mirando
new g_LastAimTime[MAXPLAYERS+1];                   // Último tempo que mirou em alguém
new Float:g_LastAimAngles[MAXPLAYERS+1][3];        // Últimos ângulos de mira
new g_HeadshotWithoutAim[MAXPLAYERS+1];            // Headshots sem mirar no alvo

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = "https://github.com/FluxusAnticheat/FluxusAnticheat-1.0"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_fluxus_panel", Cmd_FluxusPanel, ADMFLAG_ROOT, "Abre o painel do Fluxus Anticheat");
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    PrintToServer("[Fluxus Anticheat] Plugin iniciado!");
    CreateTimer(600.0, Timer_Announce, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    RegConsoleCmd("sm_fluxus_report", Command_FluxusReport);
    RegAdminCmd("sm_fluxus_admin", Cmd_FluxusAdmin, ADMFLAG_ROOT, "Abre o painel admin do Fluxus Anticheat");
    RegAdminCmd("sm_fluxus_reset", Cmd_FluxusReset, ADMFLAG_ROOT, "Reseta contadores de um jogador");
    
    // Verificar ConVars do servidor
    CreateTimer(10.0, Timer_CheckServerConVars, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Announce(Handle timer)
{
    if (!g_AnticheatEnabled) return Plugin_Continue;
    PrintToChatAll("\x04[Fluxus Anticheat]\x01 Protegendo o servidor contra cheats!");
    return Plugin_Continue;
}

// Verificar ConVars do servidor
public Action Timer_CheckServerConVars(Handle timer)
{
    ConVar sv_cheats = FindConVar("sv_cheats");
    if (sv_cheats != null && sv_cheats.BoolValue)
    {
        PrintToServer("[Fluxus Anticheat] AVISO: sv_cheats está ativado!");
    }
    
    ConVar sv_pure = FindConVar("sv_pure");
    if (sv_pure != null && sv_pure.IntValue == 0)
    {
        PrintToServer("[Fluxus Anticheat] AVISO: sv_pure está desativado!");
    }
    
    return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
    if (IsClientInGame(client) && !IsFakeClient(client))
    {
        PrintToChat(client, "\x04[Fluxus Anticheat]\x01 Anticheat ativado neste servidor!");
        
        // Verificar ConVars suspeitas
        CreateTimer(5.0, Timer_CheckConVars, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnClientDisconnect(int client)
{
    g_AlreadyBanned[client] = false;
    
    // Resetar todos os contadores
    g_SuspicionScore[client] = 0;
    g_LastScoreUpdate[client] = 0;
    g_ScoreLogged[client] = false;
    g_Reported[client] = false;
    
    // Resetar warnings específicos
    g_BhopWarnings[client] = 0;
    g_TriggerbotWarnings[client] = 0;
    g_DuckWarnings[client] = 0;
    g_SpeedhackWarnings[client] = 0;
    g_AimbotWarnings[client] = 0;
    g_WallhackWarnings[client] = 0;
    g_NoRecoilWarnings[client] = 0;
    g_VaracaoShots[client] = 0;
    
    // Resetar variáveis de detecção
    g_AimbotShakeCount[client] = 0;
    g_AimbotShakeWindow[client] = 0;
    g_BhopSpeedTicks[client] = 0;
    g_PerfectBhopCount[client] = 0;
    g_PerfectBhopSpeedSum[client] = 0.0;
    g_NoRecoilShots[client] = 0;
    g_NoRecoilHits[client] = 0;
    g_ConsecutivePerfectShots[client] = 0;
    g_LastWeapon[client] = 0;
    g_AimbotMathematicalPattern[client] = 0;
    
    // Resetar novas variáveis de detecção melhorada
    g_WallShootCount[client] = 0;
    g_AimbotSnapCount[client] = 0;
    g_AimbotKillWithoutAim[client] = 0;
    g_LastAimTarget[client] = 0;
    g_LastAimTime[client] = 0;
    g_HeadshotWithoutAim[client] = 0;
    
    // Resetar arrays de foco de wallhack
    for (int i = 1; i <= MaxClients; i++)
    {
        g_WallFocusTicks[client][i] = 0;
        g_WallShootTicks[client][i] = 0;
    }
}

// Sistema de pontuação
void AddSuspicionScore(int client, int points, const char[] reason)
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
        return;
    
    g_SuspicionScore[client] += points;
    g_LastScoreUpdate[client] = GetGameTickCount();
    
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    
    PrintToServer("[Fluxus Anticheat] %s: +%d pontos (%s) - Total: %d/%d", 
        playerName, points, reason, g_SuspicionScore[client], SUSPICION_SCORE_LIMIT);
    
    // Alertar admins se a pontuação estiver alta
    if (g_SuspicionScore[client] >= 15 && !g_ScoreLogged[client])
    {
        PrintToChatAll("[Fluxus Anticheat] \x02%N\x01 está com pontuação alta de suspeita: \x04%d\x01", 
            client, g_SuspicionScore[client]);
        g_ScoreLogged[client] = true;
    }
    
    // Banir se atingir o limite
    if (g_SuspicionScore[client] >= SUSPICION_SCORE_LIMIT)
    {
        char banReason[128];
        Format(banReason, sizeof(banReason), "Pontuação de suspeita alta (%d/%d) - %s", 
            g_SuspicionScore[client], SUSPICION_SCORE_LIMIT, reason);
        FluxusBan(client, banReason);
    }
}

// Sistema de warnings específicos
void AddWarning(int client, int warningType, const char[] reason)
{
    if (client < 1 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
        return;
    
    char playerName[64];
    GetClientName(client, playerName, sizeof(playerName));
    
    switch(warningType)
    {
        case 1: // BHOP
        {
            g_BhopWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de BUNNYHOP (%d/%d) - %s", 
                client, g_BhopWarnings[client], BHOP_WARNINGS_LIMIT, reason);
            
            if (g_BhopWarnings[client] >= BHOP_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Bunnyhop detectado");
                g_BhopWarnings[client] = 0;
            }
        }
        case 2: // TRIGGERBOT
        {
            g_TriggerbotWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de TRIGGERBOT (%d/%d) - %s", 
                client, g_TriggerbotWarnings[client], TRIGGERBOT_WARNINGS_LIMIT, reason);
            
            if (g_TriggerbotWarnings[client] >= TRIGGERBOT_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Triggerbot detectado");
                g_TriggerbotWarnings[client] = 0;
            }
        }
        case 3: // DUCK
        {
            g_DuckWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de DUCK SPAM (%d/%d) - %s", 
                client, g_DuckWarnings[client], DUCK_WARNINGS_LIMIT, reason);
            
            if (g_DuckWarnings[client] >= DUCK_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Duck spam detectado");
                g_DuckWarnings[client] = 0;
            }
        }
        case 4: // SPEEDHACK
        {
            g_SpeedhackWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de SPEEDHACK (%d/%d) - %s", 
                client, g_SpeedhackWarnings[client], SPEEDHACK_WARNINGS_LIMIT, reason);
            
            if (g_SpeedhackWarnings[client] >= SPEEDHACK_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Speedhack detectado");
                g_SpeedhackWarnings[client] = 0;
            }
        }
        case 5: // AIMBOT
        {
            g_AimbotWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de AIMBOT (%d/%d) - %s", 
                client, g_AimbotWarnings[client], AIMBOT_WARNINGS_LIMIT, reason);
            
            if (g_AimbotWarnings[client] >= AIMBOT_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Aimbot detectado");
                g_AimbotWarnings[client] = 0;
            }
        }
        case 6: // WALLHACK
        {
            g_WallhackWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de WALLHACK (%d/%d) - %s", 
                client, g_WallhackWarnings[client], WALLHACK_WARNINGS_LIMIT, reason);
            
            if (g_WallhackWarnings[client] >= WALLHACK_WARNINGS_LIMIT)
            {
                FluxusBan(client, "Wallhack detectado");
                g_WallhackWarnings[client] = 0;
            }
        }
        case 7: // NO RECOIL
        {
            g_NoRecoilWarnings[client]++;
            PrintToChatAll("[Fluxus Anticheat] %N suspeito de NO RECOIL (%d/%d) - %s", 
                client, g_NoRecoilWarnings[client], NO_RECOIL_WARNINGS_LIMIT, reason);
            
            if (g_NoRecoilWarnings[client] >= NO_RECOIL_WARNINGS_LIMIT)
            {
                FluxusBan(client, "No Recoil detectado");
                g_NoRecoilWarnings[client] = 0;
            }
        }
    }
    
    PrintToServer("[Fluxus Anticheat] %s: Warning tipo %d (%s)", playerName, warningType, reason);
}

// Verificar ConVars suspeitas
public Action Timer_CheckConVars(Handle timer, any client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
    
    CheckSuspiciousConVars(client);
    return Plugin_Stop;
}

void CheckSuspiciousConVars(int client)
{
    // Verificar ConVars suspeitas do servidor
    ConVar sv_cheats = FindConVar("sv_cheats");
    
    if (sv_cheats != null && sv_cheats.BoolValue)
    {
        AddSuspicionScore(client, CONVAR_SCORE * 2, "ConVar suspeita: sv_cheats");
        PrintToServer("[Fluxus Anticheat] %N tem sv_cheats ativado", client);
    }
}

// Detecção de aimbot, wallhack, triggerbot, bunnyhop, duck spam
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (!g_AnticheatEnabled) return Plugin_Continue;
    if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Continue;
    
    DetectAimbot(client, angles, weapon);
    DetectBunnyhop(client, buttons);
    DetectDucking(client, buttons);
    DetectWallFocus(client, angles);
    DetectSpeedhack(client, vel);
    
    // Detectar tick em que toca o chão
    bool onGround = (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) != 0;
    int tick = GetGameTickCount();
    static bool wasOnGround[MAXPLAYERS+1];
    if (onGround && !wasOnGround[client])
    {
        g_LastGroundTick[client] = tick;
    }
    wasOnGround[client] = onGround;
    
    // Calcular speed para bunnyhop perfeito
    float speed = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1]);
    
    // Detectar bunnyhop perfeito
    float now = GetEngineTime();
    if ((buttons & IN_JUMP) && onGround)
    {
        if (tick == g_LastGroundTick[client])
        {
            if (now - g_LastPerfectBhopTime[client] > 0.5 || speed < 250.0)
            {
                g_PerfectBhopCount[client] = 0;
                g_PerfectBhopSpeedSum[client] = 0.0;
            }
            g_PerfectBhopCount[client]++;
            g_PerfectBhopSpeedSum[client] += speed;
            g_LastPerfectBhopTime[client] = now;
            float avgSpeed = g_PerfectBhopSpeedSum[client] / float(g_PerfectBhopCount[client]);
            
            if (g_PerfectBhopCount[client] >= 20 && avgSpeed > 320.0) // Aumentado threshold
            {
                AddWarning(client, 1, "Bunnyhop perfeito detectado");
                PrintToServer("[ANTICHEAT] %N por bunnyhop perfeito (velocidade média %.1f)", client, avgSpeed);
                g_PerfectBhopCount[client] = 0;
                g_PerfectBhopSpeedSum[client] = 0.0;
            }
        }
        else
        {
            g_PerfectBhopCount[client] = 0;
            g_PerfectBhopSpeedSum[client] = 0.0;
        }
    }
    return Plugin_Continue;
}

void DetectAimbot(int client, float angles[3], int weapon)
{
    static float lastAngles[66][3];
    static int lastTarget[66];
    static int consecutiveFlicks[66];
    static int lastFlickTick[66];
    
    float delta = FloatAbs(angles[0] - lastAngles[client][0]) + FloatAbs(angles[1] - lastAngles[client][1]);
    int target = GetClientAimTarget(client, false);
    int tick = GetGameTickCount();
    
    if (client < 1 || client > MaxClients) return;
    
    // Verificar se o jogador está atirando
    int weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    bool isShooting = false;
    if (weaponEnt > 0)
    {
        char weaponName[64];
        GetEdictClassname(weaponEnt, weaponName, sizeof(weaponName));
        isShooting = (StrContains(weaponName, "weapon_", false) == 0 && !StrContains(weaponName, "knife", false) && !StrContains(weaponName, "grenade", false));
    }
    
    // Detecção matemática de aimbot (velocidade angular e aceleração)
    if (delta > 0.1) // Movimento detectado
    {
        float currentTime = GetEngineTime();
        static float lastTime[66];
        static float lastDelta[66];
        
        if (lastTime[client] > 0)
        {
            float timeDelta = currentTime - lastTime[client];
            float angularVelocity = delta / timeDelta;
            float acceleration = (angularVelocity - g_LastAngularVelocity[client]) / timeDelta;
            
            if (timeDelta > 0.001 && timeDelta < 0.1)
            {
                if (FloatAbs(acceleration) < 0.1 && angularVelocity > 150.0) // Aumentado threshold
                {
                    g_AimbotMathematicalPattern[client]++;
                    
                    if (g_AimbotMathematicalPattern[client] >= 8) // Aumentado threshold
                    {
                        AddWarning(client, 5, "Aimbot matemático detectado");
                        g_AimbotMathematicalPattern[client] = 0;
                    }
                }
                else
                {
                    g_AimbotMathematicalPattern[client] = 0;
                }
            }
            
            g_LastAngularVelocity[client] = angularVelocity;
        }
        
        lastTime[client] = currentTime;
        lastDelta[client] = delta;
    }
    
    // Detecção de snap aimbot para cabeça
    if (delta > AIMBOT_SNAP_THRESHOLD && target > 0 && target <= MaxClients && IsClientInGame(target) && !IsFakeClient(target))
    {
        // Verificar se o snap foi direto para a cabeça
        float targetPos[3], clientEye[3], targetHead[3];
        GetClientAbsOrigin(target, targetPos);
        GetClientEyePosition(client, clientEye);
        GetClientEyePosition(target, targetHead);
        
        // Calcular ângulo para a cabeça
        float dirToHead[3];
        MakeVectorFromPoints(clientEye, targetHead, dirToHead);
        NormalizeVector(dirToHead, dirToHead);
        
        float aimVec[3];
        GetAngleVectors(angles, aimVec, NULL_VECTOR, NULL_VECTOR);
        NormalizeVector(aimVec, aimVec);
        
        float dot = GetVectorDotProduct(aimVec, dirToHead);
        float angleToHead = ArcCosine(dot) * (180.0 / 3.14159265);
        
        // Se o snap foi direto para a cabeça
        if (angleToHead < AIMBOT_HEADSHOT_ANGLE && delta > 100.0)
        {
            g_AimbotSnapCount[client]++;
            
            if (g_AimbotSnapCount[client] >= 3) // 3 snaps para cabeça
            {
                AddWarning(client, 5, "Snap Aimbot para cabeça detectado");
                g_AimbotSnapCount[client] = 0;
            }
        }
        
        // Verificar flicks consecutivos
        if (tick - lastFlickTick[client] < 100)
        {
            consecutiveFlicks[client]++;
        }
        else
        {
            consecutiveFlicks[client] = 1;
        }
        lastFlickTick[client] = tick;
        
        if (consecutiveFlicks[client] >= 3) // Reduzido threshold
        {
            AddWarning(client, 5, "Flicks consecutivos");
        }
    }
    else
    {
        consecutiveFlicks[client] = 0;
    }
    
    // Detecção de padrões de aimbot
    if (target > 0 && target <= MaxClients && IsClientInGame(target) && !IsFakeClient(target))
    {
        if (delta > 1.0 && delta < AIMBOT_SHAKE_DELTA)
        {
            g_AimbotShakeCount[client]++;
        }
        g_AimbotShakeWindow[client]++;
        
        if (g_AimbotShakeWindow[client] >= AIMBOT_SHAKE_WINDOW)
        {
            if (g_AimbotShakeCount[client] >= AIMBOT_SHAKE_THRESHOLD)
            {
                AddWarning(client, 5, "Padrão não natural de aimbot");
            }
            g_AimbotShakeCount[client] = 0;
            g_AimbotShakeWindow[client] = 0;
        }
    }
    else
    {
        g_AimbotShakeCount[client] = 0;
        g_AimbotShakeWindow[client] = 0;
    }
    
    // Atualizar informações de mira
    if (target > 0 && target <= MaxClients && IsClientInGame(target) && !IsFakeClient(target))
    {
        g_LastAimTarget[client] = target;
        g_LastAimTime[client] = tick;
        g_LastAimAngles[client][0] = angles[0];
        g_LastAimAngles[client][1] = angles[1];
    }
    
    lastAngles[client][0] = angles[0];
    lastAngles[client][1] = angles[1];
    lastTarget[client] = target;
}

void DetectBunnyhop(int client, int buttons)
{
    int tick = GetGameTickCount();
    float vel[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    float speed = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1]);
    
    if (client < 1 || client > MaxClients) return;
    
    bool onGround = (GetEntProp(client, Prop_Send, "m_fFlags") & FL_ONGROUND) != 0;
    bool isJumping = (buttons & IN_JUMP) != 0;
    bool isStrafing = (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT);
    
    // Variáveis estáticas para rastrear padrões de bhop
    static int consecutiveJumps[66];
    static int lastJumpTime[66];
    static float lastSpeed[66];
    static int perfectTimingJumps[66];
    static int strafeChanges[66];
    static int lastStrafeTime[66];
    static int lastStrafeDirection[66];
    static float totalSpeedGain[66];
    static int speedGainCount[66];
    
    // Detectar quando o jogador toca o chão
    static bool wasOnGround[66];
    if (onGround && !wasOnGround[client])
    {
        // Jogador acabou de pousar
        consecutiveJumps[client]++;
        
        // Verificar timing do pulo (mais tolerante)
        if (tick - lastJumpTime[client] <= 3) // Aumentado para 3 ticks
        {
            perfectTimingJumps[client]++;
            
            // Calcular ganho de velocidade
            if (speed > lastSpeed[client] && lastSpeed[client] > 0)
            {
                float speedGain = speed - lastSpeed[client];
                totalSpeedGain[client] += speedGain;
                speedGainCount[client]++;
            }
        }
        else
        {
            // Reset se não foi timing perfeito
            perfectTimingJumps[client] = 0;
            totalSpeedGain[client] = 0.0;
            speedGainCount[client] = 0;
        }
        
        lastJumpTime[client] = tick;
    }
    else if (!onGround && wasOnGround[client])
    {
        // Jogador acabou de pular
        consecutiveJumps[client]++;
    }
    
    // Detectar mudanças de strafe (mais tolerante)
    if (isStrafing)
    {
        int currentStrafeDirection = 0;
        if (buttons & IN_MOVELEFT) currentStrafeDirection = -1;
        if (buttons & IN_MOVERIGHT) currentStrafeDirection = 1;
        
        if (currentStrafeDirection != 0 && currentStrafeDirection != lastStrafeDirection[client])
        {
            if (tick - lastStrafeTime[client] < 50) // Aumentado threshold
            {
                strafeChanges[client]++;
            }
            lastStrafeDirection[client] = currentStrafeDirection;
            lastStrafeTime[client] = tick;
        }
    }
    
    // DETECÇÃO 1: Pulos consecutivos + ganho de velocidade significativo
    if (consecutiveJumps[client] >= BHOP_CONSECUTIVE_JUMPS && speedGainCount[client] >= 3)
    {
        float avgSpeedGain = totalSpeedGain[client] / float(speedGainCount[client]);
        if (avgSpeedGain > BHOP_SPEED_GAIN_THRESHOLD)
        {
            AddWarning(client, 1, "Bunnyhop por pulos consecutivos + ganho de velocidade");
            consecutiveJumps[client] = 0;
            totalSpeedGain[client] = 0.0;
            speedGainCount[client] = 0;
        }
    }
    
    // DETECÇÃO 2: Velocidade anormal mantida por muito tempo
    if (speed > BHOP_SPEED_LIMIT && !onGround)
    {
        g_BhopSpeedTicks[client]++;
        if (g_BhopSpeedTicks[client] >= BHOP_SPEED_TICKS)
        {
            AddWarning(client, 1, "Bunnyhop por velocidade anormal mantida");
            g_BhopSpeedTicks[client] = 0;
        }
    }
    else
    {
        g_BhopSpeedTicks[client] = 0;
    }
    
    // DETECÇÃO 3: Timing perfeito + mudanças de strafe rápidas
    if (perfectTimingJumps[client] >= BHOP_PERFECT_TIMING && strafeChanges[client] >= BHOP_STRAFE_CHANGES)
    {
        if (tick - lastStrafeTime[client] < 10) // Mudanças muito rápidas
        {
            AddWarning(client, 1, "Bunnyhop com timing perfeito + strafe rápido");
            perfectTimingJumps[client] = 0;
            strafeChanges[client] = 0;
        }
    }
    
    // Resetar contadores se ficar muito tempo no chão
    if (onGround && tick - lastJumpTime[client] > 300) // 15 segundos
    {
        consecutiveJumps[client] = 0;
        perfectTimingJumps[client] = 0;
        strafeChanges[client] = 0;
        totalSpeedGain[client] = 0.0;
        speedGainCount[client] = 0;
    }
    
    wasOnGround[client] = onGround;
    lastSpeed[client] = speed;
}

void DetectDucking(int client, int buttons)
{
    int tick = GetGameTickCount();
    if (client < 1 || client > MaxClients) return;
    
    static bool wasDucking[66];
    static int lastDuckTick[66];
    static int duckCount[66];
    bool isDucking = (buttons & IN_DUCK) != 0;
    
    if (isDucking && !wasDucking[client])
    {
        if (tick - lastDuckTick[client] < DUCK_TICKS)
        {
            duckCount[client]++;
            if (duckCount[client] >= DUCK_LIMIT)
            {
                AddWarning(client, 3, "Duck spam detectado");
                duckCount[client] = 0;
            }
        }
        else
        {
            duckCount[client] = 1;
        }
        lastDuckTick[client] = tick;
    }
    
    wasDucking[client] = isDucking;
}

void DetectWallFocus(int client, float angles[3])
{
    float eye[3], aimVec[3], targetPos[3];
    GetClientEyePosition(client, eye);
    GetAngleVectors(angles, aimVec, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(aimVec, aimVec);
    int maxClients = MaxClients;
    
    for (int i = 1; i <= maxClients; i++)
    {
        if (i == client || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i)) continue;
        GetClientAbsOrigin(i, targetPos);
        float dirToTarget[3];
        MakeVectorFromPoints(eye, targetPos, dirToTarget);
        NormalizeVector(dirToTarget, dirToTarget);
        float dot = GetVectorDotProduct(aimVec, dirToTarget);
        float angleDiff = ArcCosine(dot) * (180.0 / 3.14159265);
        
        // Detecção de foco na parede onde está o inimigo
        if (angleDiff < WALLHACK_SHOOT_ANGLE)
        {
            if (!IsVisible(client, i))
            {
                g_WallFocusTicks[client][i]++;
                g_WallShootTicks[client][i]++;
                
                if (g_WallFocusTicks[client][i] >= WALLHACK_FOCUS_TICKS)
                {
                    AddWarning(client, 6, "Wallhack por foco atrás da parede");
                    g_WallFocusTicks[client][i] = 0;
                }
                
                // Detectar se está atirando na parede onde está o inimigo
                int weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                if (weaponEnt > 0)
                {
                    char weaponName[64];
                    GetEdictClassname(weaponEnt, weaponName, sizeof(weaponName));
                    bool isGun = (StrContains(weaponName, "weapon_", false) == 0 && !StrContains(weaponName, "knife", false) && !StrContains(weaponName, "grenade", false));
                    
                    if (isGun && g_WallShootTicks[client][i] >= WALLHACK_SHOOT_TICKS)
                    {
                        g_WallShootCount[client]++;
                        
                        if (g_WallShootCount[client] >= 3) // 3 tiros na parede
                        {
                            AddWarning(client, 6, "Wallhack atirando na parede onde está inimigo");
                            g_WallShootCount[client] = 0;
                        }
                    }
                }
            }
            else
            {
                g_WallFocusTicks[client][i] = 0;
                g_WallShootTicks[client][i] = 0;
            }
        }
        else
        {
            g_WallFocusTicks[client][i] = 0;
            g_WallShootTicks[client][i] = 0;
        }
    }
}

void DetectSpeedhack(int client, float vel[3])
{
    float speed = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1]);
    
    if (speed > SPEEDHACK_LIMIT)
    {
        AddWarning(client, 4, "Speedhack detectado");
    }
}

bool IsVisible(int client, int target)
{
    float start[3], end[3];
    GetClientEyePosition(client, start);
    GetClientEyePosition(target, end);
    Handle trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayers, client);
    bool visible = TR_DidHit(trace) ? (TR_GetEntityIndex(trace) == target) : false;
    CloseHandle(trace);
    return visible;
}

public bool TraceEntityFilterPlayers(int entity, int contentsMask, any data)
{
    return entity > 0 && entity <= MaxClients;
}

// Triggerbot e wallhack via evento de dano
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!g_AnticheatEnabled || !IsClientInGame(attacker) || !IsClientInGame(victim) || IsFakeClient(attacker) || attacker == victim)
        return;

    // Variáveis para detecção de triggerbot
    static int lastAttackTick[66];
    static int consecutiveTriggerHits[66];
    static int triggerbotShots[66];
    static int triggerbotHits[66];
    static float lastAimAngles[66][3];
    static int lastAimTick[66];
    static bool wasAimingAtTarget[66];
    
    int tick = GetGameTickCount();
    int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    char weaponName[64];
    if (weapon > 0)
        GetEdictClassname(weapon, weaponName, sizeof(weaponName));
    else
        weaponName[0] = '\0';
    
    bool isGun = (StrContains(weaponName, "weapon_", false) == 0 && !StrContains(weaponName, "knife", false) && !StrContains(weaponName, "grenade", false));
    
    if (isGun)
    {
        triggerbotHits[attacker]++;
        g_NoRecoilHits[attacker]++;
        
        // Detecção de no recoil/no spread
        if (weapon != g_LastWeapon[attacker])
        {
            g_NoRecoilShots[attacker] = 0;
            g_ConsecutivePerfectShots[attacker] = 0;
            g_LastWeapon[attacker] = weapon;
        }
        
        // Verificar se o tiro foi perfeito
        float hitPos[3];
        GetClientAbsOrigin(victim, hitPos);
        
        if (g_NoRecoilShots[attacker] > 0)
        {
            float distance = GetVectorDistance(hitPos, g_LastShotPos[attacker]);
            
            if (distance < 8.0) // Aumentado threshold
            {
                g_ConsecutivePerfectShots[attacker]++;
                
                if (g_ConsecutivePerfectShots[attacker] >= 12) // Aumentado threshold
                {
                    AddWarning(attacker, 7, "No Recoil/No Spread detectado");
                    g_ConsecutivePerfectShots[attacker] = 0;
                }
            }
            else
            {
                g_ConsecutivePerfectShots[attacker] = 0;
            }
        }
        
        g_LastShotPos[attacker][0] = hitPos[0];
        g_LastShotPos[attacker][1] = hitPos[1];
        g_LastShotPos[attacker][2] = hitPos[2];
    }
    
    // Detecção de triggerbot por reação instantânea
    if (isGun && (tick - lastAttackTick[attacker] <= TRIGGERBOT_TICK))
    {
        float attackerEye[3], victimOrigin[3], aimAngles[3], dirToVictim[3];
        GetClientEyePosition(attacker, attackerEye);
        GetClientAbsOrigin(victim, victimOrigin);
        GetClientEyeAngles(attacker, aimAngles);
        MakeVectorFromPoints(attackerEye, victimOrigin, dirToVictim);
        NormalizeVector(dirToVictim, dirToVictim);
        float aimVec[3];
        GetAngleVectors(aimAngles, aimVec, NULL_VECTOR, NULL_VECTOR);
        NormalizeVector(aimVec, aimVec);
        float dot = GetVectorDotProduct(aimVec, dirToVictim);
        float angleDiff = ArcCosine(dot) * (180.0 / 3.14159265);
        
        if (angleDiff < 15.0) // Aumentado threshold
        {
            consecutiveTriggerHits[attacker]++;
            
            if (wasAimingAtTarget[attacker])
            {
                triggerbotShots[attacker]++;
                
                if (triggerbotShots[attacker] >= 10) // Aumentado threshold
                {
                    float triggerAccuracy = float(triggerbotHits[attacker]) / float(triggerbotShots[attacker]);
                    if (triggerAccuracy > 0.85) // Aumentado threshold
                    {
                        AddWarning(attacker, 2, "Triggerbot por precisão anormal");
                    }
                    triggerbotShots[attacker] = 0;
                    triggerbotHits[attacker] = 0;
                }
            }
            
            if (consecutiveTriggerHits[attacker] >= 8) // Aumentado threshold
            {
                AddWarning(attacker, 2, "Triggerbot por reação instantânea");
                consecutiveTriggerHits[attacker] = 0;
            }
        }
        else
        {
            consecutiveTriggerHits[attacker] = 0;
        }
    }
    else
    {
        consecutiveTriggerHits[attacker] = 0;
    }
    
    // Detecção de triggerbot por mira parada
    if (tick - lastAimTick[attacker] < 50)
    {
        float currentAngles[3];
        GetClientEyeAngles(attacker, currentAngles);
        float angleDelta = FloatAbs(currentAngles[0] - lastAimAngles[attacker][0]) + FloatAbs(currentAngles[1] - lastAimAngles[attacker][1]);
        
        if (angleDelta < 8.0) // Aumentado threshold
        {
            wasAimingAtTarget[attacker] = true;
        }
        else
        {
            wasAimingAtTarget[attacker] = false;
        }
        lastAimAngles[attacker][0] = currentAngles[0];
        lastAimAngles[attacker][1] = currentAngles[1];
    }
    else
    {
        wasAimingAtTarget[attacker] = false;
    }
    
    lastAttackTick[attacker] = tick;
    lastAimTick[attacker] = tick;

    // Wallhack por foco prolongado
    if (g_WallFocusTicks[attacker][victim] >= WALLHACK_FOCUS_TICKS && !IsVisible(attacker, victim))
    {
        float vel[3];
        GetEntPropVector(attacker, Prop_Data, "m_vecVelocity", vel);
        float speed = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1]);
        
        if (speed < 50.0)
        {
            AddWarning(attacker, 6, "Wallhack por foco prolongado");
        }
    }
    g_WallFocusTicks[attacker][victim] = 0;

    // Detecção de varação (wallhack através de paredes)
    if (!IsVisible(attacker, victim))
    {
        g_VaracaoShots[attacker]++;
        
        if (g_VaracaoShots[attacker] >= VARACAO_SHOTS_LIMIT)
        {
            AddWarning(attacker, 6, "Varação detectada");
            g_VaracaoShots[attacker] = 0;
        }
    }
    
    // Wallhack por ângulo extremo
    float attackerEye[3], victimOrigin[3], aimAngles[3], dirToVictim[3];
    GetClientEyePosition(attacker, attackerEye);
    GetClientAbsOrigin(victim, victimOrigin);
    GetClientEyeAngles(attacker, aimAngles);
    MakeVectorFromPoints(attackerEye, victimOrigin, dirToVictim);
    NormalizeVector(dirToVictim, dirToVictim);
    float aimVec[3];
    GetAngleVectors(aimAngles, aimVec, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(aimVec, aimVec);
    float dot = GetVectorDotProduct(aimVec, dirToVictim);
    float angleDiff = ArcCosine(dot) * (180.0 / 3.14159265);
    
    if (angleDiff > WALLHACK_ANGLE * 3) // Aumentado threshold
    {
        AddWarning(attacker, 6, "Wallhack por ângulo extremo");
    }
}

// Evento de morte
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    // Resetar contadores do jogador que morreu
    if (IsClientInGame(victim) && !IsFakeClient(victim))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            g_WallFocusTicks[i][victim] = 0;
            g_WallShootTicks[i][victim] = 0;
        }
    }
    
    if (!g_AnticheatEnabled || !IsClientInGame(attacker) || !IsClientInGame(victim) || IsFakeClient(attacker) || attacker == victim)
        return;
        
    static float lastAngles[66][3];
    float angles[3];
    GetClientEyeAngles(attacker, angles);
    float delta = FloatAbs(angles[0] - lastAngles[attacker][0]) + FloatAbs(angles[1] - lastAngles[attacker][1]);
    
    // Detecção de flick no abate
    if (delta > AIMBOT_THRESHOLD * 2)
    {
        AddWarning(attacker, 5, "Aimbot por flick no abate");
    }
    
    // Detecção de kill sem mirar no alvo
    float attackerEye[3], victimPos[3], aimVec[3], dirToVictim[3];
    GetClientEyePosition(attacker, attackerEye);
    GetClientAbsOrigin(victim, victimPos);
    GetAngleVectors(angles, aimVec, NULL_VECTOR, NULL_VECTOR);
    MakeVectorFromPoints(attackerEye, victimPos, dirToVictim);
    
    NormalizeVector(aimVec, aimVec);
    NormalizeVector(dirToVictim, dirToVictim);
    
    float dot = GetVectorDotProduct(aimVec, dirToVictim);
    float angleToVictim = ArcCosine(dot) * (180.0 / 3.14159265);
    
    // Se não estava mirando no alvo quando matou
    if (angleToVictim > 45.0) // Ângulo muito grande = não estava mirando
    {
        g_AimbotKillWithoutAim[attacker]++;
        
        if (g_AimbotKillWithoutAim[attacker] >= AIMBOT_KILL_WITHOUT_AIM)
        {
            AddWarning(attacker, 5, "Aimbot matando sem mirar no alvo");
            g_AimbotKillWithoutAim[attacker] = 0;
        }
    }
    else
    {
        g_AimbotKillWithoutAim[attacker] = 0;
    }
    
    // Detecção de headshot sem mirar
    bool isHeadshot = event.GetBool("headshot", false);
    if (isHeadshot && angleToVictim > 30.0)
    {
        g_HeadshotWithoutAim[attacker]++;
        
        if (g_HeadshotWithoutAim[attacker] >= 3)
        {
            AddWarning(attacker, 5, "Aimbot headshot sem mirar no alvo");
            g_HeadshotWithoutAim[attacker] = 0;
        }
    }
    
    lastAngles[attacker][0] = angles[0];
    lastAngles[attacker][1] = angles[1];
}

// Função de banimento
void FluxusBan(int client, const char[] motivo)
{
    if (g_AlreadyBanned[client]) return;
    g_AlreadyBanned[client] = true;
    char steamid[32];
    char timeStr[32];
    char playerName[64];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    GetClientName(client, playerName, sizeof(playerName));
    FormatTime(timeStr, sizeof(timeStr), "%d/%m/%Y %H:%M");
    
    char banMsg[192];
    Format(banMsg, sizeof(banMsg), "Banido by Fluxus Anticheat | Motivo: %s | Data: %s | SteamID: %s", motivo, timeStr, steamid);
    
    PrintToServer("[Fluxus Anticheat] BAN: %s (SteamID: %s) - Motivo: %s - Data: %s", playerName, steamid, motivo, timeStr);
    
    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteString(banMsg);
    CreateTimer(0.5, Timer_BanClient, pack, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_BanClient(Handle timer, any data)
{
    DataPack pack = view_as<DataPack>(data);
    pack.Reset();
    int userid = pack.ReadCell();
    char banMsg[192];
    pack.ReadString(banMsg, sizeof(banMsg));
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client))
    {
        BanClient(client, 0, BANFLAG_AUTO, banMsg);
        KickClient(client, banMsg);
    }
    delete pack;
    return Plugin_Stop;
}

// Comandos
public Action Command_FluxusReport(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Uso: sm_fluxus_report <jogador>");
        return Plugin_Handled;
    }
    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int target = FindTarget(client, targetName, true, false);
    if (target > 0)
    {
        g_Reported[target] = true;
        PrintToChatAll("[Fluxus Anticheat] %N foi reportado!", target);
    }
    return Plugin_Handled;
}

// Painel admin
public Action Cmd_FluxusPanel(int client, int args)
{
    if (!IsAdmin(client))
    {
        PrintToChat(client, "[Fluxus Anticheat] Acesso negado.");
        return Plugin_Handled;
    }
    Menu menu = new Menu(MenuHandler_FluxusPanel);
    menu.SetTitle("Fluxus Anticheat - Painel Admin");
    menu.AddItem("toggle", g_AnticheatEnabled ? "Desativar Anticheat" : "Ativar Anticheat");
    menu.AddItem("warns", "Ver Jogadores Suspeitos");
    menu.AddItem("unban", "Desbanir por SteamID");
    menu.Display(client, 30);
    return Plugin_Handled;
}

public int MenuHandler_FluxusPanel(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        if (StrEqual(info, "toggle"))
        {
            g_AnticheatEnabled = !g_AnticheatEnabled;
            PrintToChatAll("[Fluxus Anticheat] Anticheat %s!", g_AnticheatEnabled ? "ativado" : "desativado");
        }
        else if (StrEqual(info, "warns"))
        {
            ShowSuspectsMenu(client);
        }
        else if (StrEqual(info, "unban"))
        {
            PrintToChat(client, "[Fluxus Anticheat] Use: sm_unban <steamid>");
        }
    }
    return 0;
}

void ShowSuspectsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Suspects);
    menu.SetTitle("Jogadores Suspeitos");
    char name[64], info[8], displayName[128];
    int maxClients = MaxClients;
    for (int i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && (g_SuspicionScore[i] > 0 || g_Reported[i]))
        {
            GetClientName(i, name, sizeof(name));
            IntToString(i, info, sizeof(info));
            Format(displayName, sizeof(displayName), "%s [%d pts]", name, g_SuspicionScore[i]);
            menu.AddItem(info, displayName);
        }
    }
    menu.Display(client, 30);
}

public int MenuHandler_Suspects(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(item, info, sizeof(info));
        int target = StringToInt(info);
        if (IsClientInGame(target))
        {
            ShowSuspectActionsMenu(client, target);
        }
    }
    return 0;
}

void ShowSuspectActionsMenu(int client, int target)
{
    Menu menu = new Menu(MenuHandler_SuspectActions);
    char name[64];
    GetClientName(target, name, sizeof(name));
    char info[8];
    IntToString(target, info, sizeof(info));
    menu.SetTitle("Ações para %s", name);
    menu.AddItem(info, "Banir");
    menu.AddItem(info, "Kickar");
    menu.AddItem(info, "Spectar");
    menu.Display(client, 30);
}

public int MenuHandler_SuspectActions(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(item, info, sizeof(info));
        int target = StringToInt(info);
        if (item == 0) // Banir
        {
            FluxusBan(target, "Banido pelo admin via painel");
        }
        else if (item == 1) // Kickar
        {
            KickClient(target, "Kickado pelo admin via painel Fluxus Anticheat");
            PrintToChatAll("[Fluxus Anticheat] %N foi kickado pelo admin!", target);
        }
        else if (item == 2) // Spectar
        {
            ForcePlayerSuicide(client);
            ChangeClientTeam(client, 1);
            SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
            PrintToChat(client, "[Fluxus Anticheat] Agora spectando %N.", target);
        }
    }
    return 0;
}

bool IsAdmin(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    return StrEqual(steamid, ADMIN_STEAMID) || StrEqual(steamid, "STEAM_0:1:498668800") || StrEqual(steamid, "U:1:997337601");
}

// Comando para abrir painel admin
public Action Cmd_FluxusAdmin(int client, int args)
{
    if (!IsAdmin(client))
    {
        PrintToChat(client, "[Fluxus Anticheat] Acesso negado.");
        return Plugin_Handled;
    }
    Menu menu = new Menu(MenuHandler_FluxusAdmin);
    menu.SetTitle("Painel Admin - Fluxus Anticheat");
    menu.AddItem("giveweapons", "Pegar Armas");
    menu.AddItem("ban", "Banir Jogador");
    menu.AddItem("unban", "Desbanir por SteamID");
    menu.AddItem("spectate", "Spectar Jogador");
    menu.AddItem("kick", "Kickar Jogador");
    menu.AddItem("close", "Fechar Painel");
    menu.Display(client, 30);
    return Plugin_Handled;
}

public int MenuHandler_FluxusAdmin(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));
        if (StrEqual(info, "giveweapons"))
        {
            GiveAdminWeapons(client);
            PrintToChat(client, "[Fluxus Anticheat] Armas entregues!");
        }
        else if (StrEqual(info, "ban"))
        {
            ShowSuspectsMenu(client);
        }
        else if (StrEqual(info, "unban"))
        {
            PrintToChat(client, "[Fluxus Anticheat] Use: sm_unban <steamid>");
        }
        else if (StrEqual(info, "spectate"))
        {
            ShowSuspectsMenuSpectate(client);
        }
        else if (StrEqual(info, "kick"))
        {
            ShowSuspectsMenuKick(client);
        }
        else if (StrEqual(info, "close"))
        {
            PrintToChat(client, "[Fluxus Anticheat] Painel fechado.");
        }
    }
    return 0;
}

// Dar armas ao admin
void GiveAdminWeapons(int client)
{
    GivePlayerItem(client, "weapon_ak47");
    GivePlayerItem(client, "weapon_m4a1");
    GivePlayerItem(client, "weapon_awp");
    GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client, "weapon_hegrenade");
    GivePlayerItem(client, "weapon_flashbang");
    GivePlayerItem(client, "weapon_smokegrenade");
}

// Menus para spectar e kickar jogadores suspeitos
void ShowSuspectsMenuSpectate(int client)
{
    Menu menu = new Menu(MenuHandler_SuspectsSpectate);
    menu.SetTitle("Spectar Jogador Suspeito");
    char name[64], info[8];
    int maxClients = MaxClients;
    for (int i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientName(i, name, sizeof(name));
            IntToString(i, info, sizeof(info));
            menu.AddItem(info, name);
        }
    }
    menu.Display(client, 30);
}

public int MenuHandler_SuspectsSpectate(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(item, info, sizeof(info));
        int target = StringToInt(info);
        if (IsClientInGame(target))
        {
            ForcePlayerSuicide(client);
            ChangeClientTeam(client, 1);
            SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
            SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
            PrintToChat(client, "[Fluxus Anticheat] Agora spectando %N.", target);
        }
    }
    return 0;
}

void ShowSuspectsMenuKick(int client)
{
    Menu menu = new Menu(MenuHandler_SuspectsKick);
    menu.SetTitle("Kickar Jogador Suspeito");
    char name[64], info[8];
    int maxClients = MaxClients;
    for (int i = 1; i <= maxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientName(i, name, sizeof(name));
            IntToString(i, info, sizeof(info));
            menu.AddItem(info, name);
        }
    }
    menu.Display(client, 30);
}

public int MenuHandler_SuspectsKick(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_Select)
    {
        char info[8];
        menu.GetItem(item, info, sizeof(info));
        int target = StringToInt(info);
        if (IsClientInGame(target))
        {
            KickClient(target, "Kickado pelo admin via painel Fluxus Anticheat");
            PrintToChatAll("[Fluxus Anticheat] %N foi kickado pelo admin!", target);
        }
    }
    return 0;
}

// Comando para resetar contadores de um jogador
public Action Cmd_FluxusReset(int client, int args)
{
    if (!IsAdmin(client))
    {
        PrintToChat(client, "[Fluxus Anticheat] Acesso negado.");
        return Plugin_Handled;
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "Uso: sm_fluxus_reset <jogador>");
        return Plugin_Handled;
    }
    
    char targetName[64];
    GetCmdArg(1, targetName, sizeof(targetName));
    int target = FindTarget(client, targetName, true, false);
    
    if (target > 0 && IsClientInGame(target))
    {
        // Resetar todos os contadores
        g_SuspicionScore[target] = 0;
        g_LastScoreUpdate[target] = 0;
        g_ScoreLogged[target] = false;
        g_Reported[target] = false;
        
        // Resetar warnings específicos
        g_BhopWarnings[target] = 0;
        g_TriggerbotWarnings[target] = 0;
        g_DuckWarnings[target] = 0;
        g_SpeedhackWarnings[target] = 0;
        g_AimbotWarnings[target] = 0;
        g_WallhackWarnings[target] = 0;
        g_NoRecoilWarnings[target] = 0;
        g_VaracaoShots[target] = 0;
        
        // Resetar variáveis de detecção
        g_AimbotShakeCount[target] = 0;
        g_AimbotShakeWindow[target] = 0;
        g_BhopSpeedTicks[target] = 0;
        g_PerfectBhopCount[target] = 0;
        g_PerfectBhopSpeedSum[target] = 0.0;
        g_NoRecoilShots[target] = 0;
        g_NoRecoilHits[target] = 0;
        g_ConsecutivePerfectShots[target] = 0;
        g_LastWeapon[target] = 0;
        g_AimbotMathematicalPattern[target] = 0;
        
        // Resetar novas variáveis de detecção melhorada
        g_WallShootCount[target] = 0;
        g_AimbotSnapCount[target] = 0;
        g_AimbotKillWithoutAim[target] = 0;
        g_LastAimTarget[target] = 0;
        g_LastAimTime[target] = 0;
        g_HeadshotWithoutAim[target] = 0;
        
        // Resetar arrays de foco de wallhack
        for (int i = 1; i <= MaxClients; i++)
        {
            g_WallFocusTicks[target][i] = 0;
            g_WallFocusTicks[i][target] = 0;
            g_WallShootTicks[target][i] = 0;
            g_WallShootTicks[i][target] = 0;
        }
        
        PrintToChat(client, "[Fluxus Anticheat] Contadores de %N foram resetados!", target);
        PrintToChat(target, "[Fluxus Anticheat] Seus contadores foram resetados por um admin!");
    }
    else
    {
        ReplyToCommand(client, "[Fluxus Anticheat] Jogador não encontrado.");
    }
    
    return Plugin_Handled;
}