extends SceneTree

const LOG_NAME := "ModLoader:Setup"

const settings := {
	"IS_LOADER_SETUP_APPLIED": "application/run/is_loader_setup_applied",
	"IS_LOADER_SET_UP": "application/run/is_loader_set_up",
	"MOD_LOADER_AUTOLOAD": "autoload/ModLoader",
}

# see: [method ModLoaderUtils.register_global_classes_from_array]
const new_global_classes := [
	{
		"base": "Resource",
		"class": "ModData",
		"language": "GDScript",
		"path": "res://addons/mod_loader/mod_data.gd"
	}, {
		"base": "Node",
		"class": "ModLoaderUtils",
		"language": "GDScript",
		"path": "res://addons/mod_loader/mod_loader_utils.gd"
	}, {
		"base": "Resource",
		"class": "ModManifest",
		"language": "GDScript",
		"path": "res://addons/mod_loader/mod_manifest.gd"
	}
]

# IMPORTANT: use the ModLoaderUtils via this variable within this script!
# Otherwise, script compilation will break on first load since the class is not defined.
var modloaderutils: Node = load("res://addons/mod_loader/mod_loader_utils.gd").new()


func _init() -> void:
	try_setup_modloader()
	var _changescene_error: int = change_scene(ProjectSettings.get_setting("application/run/main_scene"))


# Set up the ModLoader, if it hasn't been set up yet
func try_setup_modloader() -> void:
	# Avoid doubling the setup work
	if is_loader_setup_applied():
		modloaderutils.log_info("ModLoader is available, mods can be loaded!", LOG_NAME)
		OS.set_window_title("%s (Modded)" % ProjectSettings.get_setting("application/config/name"))
		return

	setup_modloader()

	# If the loader is set up, but the override is not applied yet,
	# prompt the user to quit and restart the game.
	if is_loader_set_up() and not is_loader_setup_applied():
		modloaderutils.log_info("ModLoader is set up, but the game needs to be restarted", LOG_NAME)
		OS.alert("The Godot ModLoader has been set up. Restart the game to apply the changes. Confirm to quit.")
		ProjectSettings.set_setting(settings.IS_LOADER_SETUP_APPLIED, true)
		var _savecustom_error: int = ProjectSettings.save_custom(modloaderutils.get_override_path())
		quit()


# Set up the ModLoader as an autoload and register the other global classes.
# Saved as override.cfg besides the game executable to extend the existing project settings
func setup_modloader() -> void:
	modloaderutils.log_info("Setting up ModLoader", LOG_NAME)

	# Register all new helper classes as global
	modloaderutils.register_global_classes_from_array(new_global_classes)

	# Add ModLoader autoload (the * marks the path as autoload)
	ProjectSettings.set_setting(settings.MOD_LOADER_AUTOLOAD, "*res://addons/mod_loader/mod_loader.gd")
	ProjectSettings.set_setting(settings.IS_LOADER_SET_UP, true)

	# The game needs to be restarted first, bofore the loader is truly set up
	# Set this here and check it elsewhere to prompt the user for a restart
	ProjectSettings.set_setting(settings.IS_LOADER_SETUP_APPLIED, false)

	var _savecustom_error: int = ProjectSettings.save_custom(modloaderutils.get_override_path())
	modloaderutils.log_info("ModLoader setup complete", LOG_NAME)


func is_loader_set_up() -> bool:
	return is_project_setting_true(settings.IS_LOADER_SET_UP)


func is_loader_setup_applied() -> bool:
	if not root.get_node_or_null("/root/ModLoader") == null:
		if not is_project_setting_true(settings.IS_LOADER_SETUP_APPLIED):
			modloaderutils.log_info("ModLoader is already set up. No self setup required.", LOG_NAME)
		return true
	return false


static func is_project_setting_true(project_setting: String) -> bool:
	return ProjectSettings.has_setting(project_setting) and\
		ProjectSettings.get_setting(project_setting)



