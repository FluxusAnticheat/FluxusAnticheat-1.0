# Fluxus Anticheat 1.0.0 Beta

**ATENÇÃO: Este é apenas um teste/experimento. Use por sua conta e risco.**

## 📋 Descrição

Fluxus Anticheat é um plugin de anticheat para Counter-Strike: Source desenvolvido em SourcePawn para SourceMod. Este projeto é experimental e foi criado para fins de estudo e teste.

## ⚠️ Aviso Importante

**Este anticheat é apenas um teste/experimento. Não é recomendado para uso em servidores de produção sem testes extensivos. Use por sua conta e risco.**

## 🚀 Características

### Detecções Implementadas

#### 🎯 **Aimbot**
- **Snap para Cabeça**: Detecta movimentos bruscos direto para a cabeça do inimigo
- **Kill sem Mirar**: Detecta quando o jogador mata alguém sem estar mirando no alvo
- **Headshot sem Mirar**: Detecta headshots quando não estava mirando no alvo
- **Aimbot Matemático**: Detecta movimentos matematicamente perfeitos
- **Flicks Consecutivos**: Detecta múltiplos flicks rápidos
- **Padrões Não Naturais**: Detecta movimentos muito consistentes

#### 🧱 **Wallhack**
- **Foco na Parede**: Detecta quando o jogador fica olhando para inimigos atrás de paredes
- **Tiro na Parede**: Detecta quando o jogador atira na parede onde está o inimigo
- **Varação**: Detecta tiros através de paredes

#### 🐰 **Bunnyhop**
- **Pulos Consecutivos + Ganho de Velocidade**: Detecta pulos consecutivos com aumento significativo de velocidade
- **Velocidade Anormal Mantida**: Detecta velocidade anormal mantida por muito tempo
- **Timing Perfeito + Strafe Rápido**: Detecta timing perfeito combinado com mudanças rápidas de strafe

#### 🔫 **Triggerbot**
- **Reação Instantânea**: Detecta tiros instantâneos quando inimigo entra na mira
- **Precisão Anormal**: Detecta precisão anormalmente alta
- **Mira Parada**: Detecta quando a mira fica muito parada antes do tiro

#### 🦆 **Duck Spam**
- **Spam de Agachamento**: Detecta agachamento muito rápido e repetitivo

#### ⚡ **Speedhack**
- **Velocidade Anormal**: Detecta velocidade acima do limite permitido

#### 🎯 **No Recoil/No Spread**
- **Tiros Perfeitos**: Detecta padrões de tiro muito perfeitos
- **Sem Recuo**: Detecta ausência de recuo nas armas

## ⚙️ Configurações

### Thresholds Principais
- **Aimbot Threshold**: 100° (movimento angular)
- **Wallhack Angle**: 25° (ângulo para detecção)
- **Bunnyhop Consecutive Jumps**: 15 pulos
- **Bunnyhop Speed Gain**: 80.0 unidades
- **Bunnyhop Speed Limit**: 550.0 unidades

### Sistema de Warnings
- **Aimbot**: 3 warnings = ban
- **Wallhack**: 3 warnings = ban
- **Bunnyhop**: 2 warnings = ban
- **Triggerbot**: 2 warnings = ban
- **Duck Spam**: 2 warnings = ban
- **Speedhack**: 1 warning = ban
- **No Recoil**: 3 warnings = ban

## 🛠️ Instalação

### Pré-requisitos
- SourceMod 1.10+
- Counter-Strike: Source
- Servidor dedicado

### Passos
1. Baixe o arquivo `fluxus_anticheat.smx`
2. Coloque na pasta `addons/sourcemod/plugins/`
3. Reinicie o servidor ou use `sm plugins reload fluxus_anticheat`

## 🔧 Configuração de Admin

### Como Configurar Admin no Código

1. **Abra o arquivo `fluxus_anticheat.sp`**
2. **Localize a linha:**
   ```sourcepawn
   #define ADMIN_STEAMID "SEU_STEAMID_AQUI"
   ```
3. **Substitua "SEU_STEAMID_AQUI" pelo seu SteamID**
4. **Para encontrar seu SteamID:**
   - Vá em https://steamidfinder.com/
   - Digite seu nome de usuário
   - Copie o SteamID (formato: STEAM_0:1:XXXXXXXX)
5. **Exemplo:**
   ```sourcepawn
   #define ADMIN_STEAMID "STEAM_0:1:123456789"
   ```

### Comandos de Admin
- `sm_fluxus_panel` - Abre o painel principal do anticheat
- `sm_fluxus_admin` - Abre o painel admin avançado
- `sm_fluxus_reset <jogador>` - Reseta contadores de um jogador

### Comandos Gerais
- `sm_fluxus_report <jogador>` - Reporta um jogador suspeito

## 📁 Estrutura do Projeto

```
FluxusAnticheat-1.0/
├── fluxus_anticheat.sp          # Código fonte principal
├── fluxus_anticheat.smx         # Plugin compilado
├── README.md                    # Este arquivo
└── LICENSE                      # Licença MIT
```

## 🔨 Compilação

Para compilar o plugin:

1. **Instale o SourceMod SDK**
2. **Use o compilador:**
   ```bash
   spcomp64.exe fluxus_anticheat.sp
   ```

## 📊 Detalhes Técnicos

### Detecção de Bunnyhop Melhorada
- **Pulos Consecutivos**: 15 pulos consecutivos
- **Ganho de Velocidade**: Mínimo de 80.0 unidades
- **Velocidade Máxima**: 550.0 unidades
- **Timing Perfeito**: 5 pulos com timing perfeito
- **Mudanças de Strafe**: 25 mudanças de direção

### Detecção de Aimbot Avançada
- **Snap Threshold**: 80° para detectar snaps
- **Headshot Angle**: 10° para detectar precisão na cabeça
- **Kill sem Mirar**: Ângulo > 45° = não estava mirando
- **Headshot sem Mirar**: Ângulo > 30° + headshot

### Detecção de Wallhack Preciso
- **Foco na Parede**: 30 ticks mirando em inimigo atrás da parede
- **Tiro na Parede**: 20 ticks + tiro na parede onde está inimigo
- **Ângulo de Detecção**: 15° para detectar foco na parede

## ⚠️ Limitações

- Este é um projeto experimental
- Pode gerar falsos positivos
- Não é 100% eficaz contra todos os cheats
- Requer testes extensivos antes do uso em produção

## 🤝 Contribuição

Este é um projeto experimental. Contribuições são bem-vindas, mas lembre-se que é apenas um teste.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 👨‍💻 Autor

**regiselronds**
- GitHub: [https://github.com/FluxusAnticheat/FluxusAnticheat-1.0](https://github.com/FluxusAnticheat/FluxusAnticheat-1.0)

## 📞 Suporte

Como este é um projeto experimental, o suporte é limitado. Use por sua conta e risco.

---

**ATENÇÃO: Este é apenas um teste/experimento. Use por sua conta e risco.** 