extends Node2D
class_name AudioPlayer

const AUDIO_PATH = "res://Assets/Audio/"

static func play(n: String, p, keep: bool = false, v: float = 0.0) -> void:
	var r = load(AUDIO_PATH + n)
	var a = AudioStreamPlayer2D.new()
	a.name = n
	a.stream = r
	a.volume_db = v
	p.add_child(a)
	a.play()
	
	if not keep:
		await a.finished
		a.queue_free()
