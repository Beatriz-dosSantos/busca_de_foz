extends Node

const ARQUIVO_PROGRESSO := "user://progresso.cfg"

var fase_atual: int = 1
var dano_onda: int = 10

func iniciar_jogo() -> void:
	fase_atual = 1
	dano_onda = 10

func avancar_fase() -> void:
	fase_atual += 1
	dano_onda *= 2

func salvar_progresso(cena: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progresso", "cena", cena)
	cfg.set_value("progresso", "fase_atual", fase_atual)
	cfg.set_value("progresso", "dano_onda", dano_onda)
	cfg.save(ARQUIVO_PROGRESSO)

func carregar_progresso() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO_PROGRESSO) != OK:
		return ""
	var cena: String = cfg.get_value("progresso", "cena", "")
	if cena == "" or not ResourceLoader.exists(cena):
		return ""
	fase_atual = cfg.get_value("progresso", "fase_atual", 1)
	dano_onda = cfg.get_value("progresso", "dano_onda", 10)
	return cena

func apagar_progresso() -> void:
	if FileAccess.file_exists(ARQUIVO_PROGRESSO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_PROGRESSO))
