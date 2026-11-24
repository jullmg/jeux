class_name ParkOuting
extends RefCounted
## "Papa, on va jouer au parc ?" (Julien, 2026-11-23: activities on demand with the parents). Charlotte asks Papa (his card in
## `house.gd _ask_dad`), and he takes her to the Parc du Pélican, across Masson, which she may not cross alone at seven:
## Papa comes along (`parc_pelican.gd _build_outing_papa`: he follows her at a few steps, cheers after each game and talks when
## clicked), and she plays as in any other visit. The gate asks whether they go home; Papa then walks her back. Not a quest: no
## step, no reward, any time nothing else is going on. The flag is `flags.park_outing`.

const FLAG := "park_outing"
const PARK := "res://scenes/parc_pelican.tscn"
## Where she comes out in the park: inside the gate, Papa beside her.
const START_X := 360.0
const LINES := ["Vas-y, ma grande, je te regarde !", "On est bien, ici, hein ?", "Prends ton temps, y a pas de presse.",
	"Tu veux que je te pousse sur la balançoire ?", "Moi aussi, quand j'étais petit, j'adorais le parc."]
const CHEERS := ["Bravo, Chachoue !", "Wow ! T'es vraiment bonne !", "Hé, regarde ça ! Super !", "Ha ha ! Encore, encore !", "C'est ça, ma grande !", "Quelle belle partie !"]


static func active() -> bool:
	return bool(GameState.flags.get(FLAG, false))


static func start() -> void:
	GameState.flags[FLAG] = true


static func end() -> void:
	GameState.flags.erase(FLAG)
