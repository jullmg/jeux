class_name Fluidity
extends RefCounted
## Garder le jeu fluide quel que soit l'écran : la 3D est calculée à une taille proche du 1080p puis agrandie (les
## textes et les boutons restent à la pleine résolution), et un écran rapide est tenu à 60 images régulières.

## Le nombre de pixels en 3D qu'un M1 Pro dessine confortablement à plus de 60 images par seconde.
const BUDGET := 2_100_000.0
const LOWEST := 0.5

## Pendant les mesures de performance : aucune limite, pour voir la marge réelle.
static var measuring := false


## La part de la largeur (et de la hauteur) réellement calculée pour une fenêtre de cette taille.
static func scale_for(window: Vector2i) -> float:
	var pixels := float(maxi(1, window.x * window.y))
	var wanted := sqrt(BUDGET / pixels)
	# Presque à la bonne taille : autant tout calculer.
	return 1.0 if wanted > 0.94 else maxf(LOWEST, wanted)


## Les images par seconde à ne pas dépasser (0 : la cadence de l'écran suffit). Sur un écran à 120 Hz, des images
## tantôt à 8 ms, tantôt à 17 ms saccadent : mieux vaut 60 images bien espacées.
static func cap_for(refresh: float) -> int:
	return 60 if refresh >= 100.0 else 0


static func apply(window: Window) -> void:
	var scale := scale_for(window.size)
	var upscaler := Viewport.SCALING_3D_MODE_BILINEAR
	if scale < 1.0 and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		upscaler = Viewport.SCALING_3D_MODE_METALFX_SPATIAL \
			if RenderingServer.get_current_rendering_driver_name() == "metal" else Viewport.SCALING_3D_MODE_FSR
	if window.scaling_3d_mode != upscaler:
		window.scaling_3d_mode = upscaler
	if not is_equal_approx(window.scaling_3d_scale, scale):
		window.scaling_3d_scale = scale
	var cap := 0 if measuring else cap_for(DisplayServer.screen_get_refresh_rate(window.current_screen))
	if Engine.max_fps != cap:
		Engine.max_fps = cap
