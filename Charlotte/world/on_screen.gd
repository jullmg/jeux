class_name OnScreen
extends RefCounted
## Is a thing on the screen, or about to be? Animated things far off screen don't need to be redrawn every frame (their
## `_draw` rebuilt) nor their pose recomputed: their logic carries on (walking, fleeing, coming back), only the drawing is
## skipped until they are near the view again. `margin` (screen px) keeps something just coming in from popping.


## True when `item` is visible and its origin lies within the view grown by `margin` (in its own viewport's screen space).
static func near(item: CanvasItem, margin := 320.0) -> bool:
	if not item.is_visible_in_tree():
		return false
	var p := item.get_global_transform_with_canvas().origin
	return item.get_viewport_rect().grow(margin).has_point(p)
