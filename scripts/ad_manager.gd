extends Node

## AdManager: Singleton that interfaces with CrazyGames, Poki, and Web portals.
## Automatically mocks ad playback when running locally in the editor or desktop builds.

signal ad_started
signal ad_completed(rewarded: bool)

var is_web: bool = false
var crazygames_sdk: JavaScriptObject
var poki_sdk: JavaScriptObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	is_web = OS.has_feature("web")
	_initialize_sdks()

func _initialize_sdks() -> void:
	if not is_web:
		print("[AdManager] Running in non-web environment. Ad simulator enabled.")
		return

	# Check for CrazyGames SDK (window.CrazyGames.SDK)
	if JavaScriptBridge.eval("typeof window.CrazyGames !== 'undefined'"):
		crazygames_sdk = JavaScriptBridge.get_interface("CrazyGames")
		print("[AdManager] CrazyGames SDK detected.")

	# Check for Poki SDK (window.PokiSDK)
	elif JavaScriptBridge.eval("typeof window.PokiSDK !== 'undefined'"):
		poki_sdk = JavaScriptBridge.get_interface("PokiSDK")
		print("[AdManager] Poki SDK detected.")
	else:
		print("[AdManager] No portal SDK detected on window object.")

## Request a Rewarded Ad (e.g., Revive player, Double Gold)
func show_rewarded_ad(reward_name: String, on_success: Callable, on_fail: Callable = Callable()) -> void:
	emit_signal("ad_started")
	print("[AdManager] Requesting rewarded ad for: ", reward_name)

	if not is_web:
		# Simulate 1.5 second ad watch in local editor
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func():
			print("[AdManager] Simulated ad finished. Reward granted!")
			emit_signal("ad_completed", true)
			if on_success.is_valid():
				on_success.call()
		)
		return

	# Web implementation using JavaScriptBridge
	if crazygames_sdk:
		var cb_success = JavaScriptBridge.create_callback(func(_args):
			emit_signal("ad_completed", true)
			if on_success.is_valid():
				on_success.call()
		)
		var cb_error = JavaScriptBridge.create_callback(func(_args):
			emit_signal("ad_completed", false)
			if on_fail.is_valid():
				on_fail.call()
		)
		JavaScriptBridge.eval("""
			window.CrazyGames.SDK.ad.requestAd('rewarded', {
				adFinished: () => { window.godot_rewarded_success(); },
				adError: (err) => { window.godot_rewarded_fail(err); }
			});
		""")
	elif poki_sdk:
		JavaScriptBridge.eval("""
			window.PokiSDK.rewardedBreak().then((success) => {
				if (success) {
					window.godot_rewarded_success();
				} else {
					window.godot_rewarded_fail();
				}
			});
		""")
	else:
		# Fallback if opened as standalone web file without SDK
		emit_signal("ad_completed", true)
		if on_success.is_valid():
			on_success.call()

## Request an Interstitial Ad (e.g., between runs)
func show_interstitial_ad(on_complete: Callable = Callable()) -> void:
	emit_signal("ad_started")
	print("[AdManager] Showing interstitial ad...")

	if not is_web:
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			emit_signal("ad_completed", false)
			if on_complete.is_valid():
				on_complete.call()
		)
		return

	if crazygames_sdk:
		JavaScriptBridge.eval("window.CrazyGames.SDK.ad.requestAd('midroll');")
	elif poki_sdk:
		JavaScriptBridge.eval("window.PokiSDK.commercialBreak();")

	if on_complete.is_valid():
		on_complete.call()
