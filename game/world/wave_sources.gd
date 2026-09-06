extends RefCounted
## Five signed crossing swells, evaluated on the existing logical spring grid.
## Sources are world anchored. Their envelopes travel; scrolling never relocates them.

const SOURCE_COUNT := 5
const REFERENCE_LENGTH := 24.0
const CALM_AMPLITUDE := 0.12
const TEMPEST_AMPLITUDE := 1.05
const DIRECTIONS := [Vector2(1.0, 0.28), Vector2(-0.17, 1.0), Vector2(-0.86, 0.50), Vector2(-0.36, -0.93), Vector2(0.65, -0.76)]
const WAVELENGTHS := [24.0, 20.0, 28.0, 18.0, 32.0]
const PHASE_RATES := [1.0, 1.13, 0.91, 1.27, 0.79]
const CALM_WEIGHTS := [0.72, 0.19, 0.035, 0.03, 0.025]
const TEMPEST_WEIGHTS := [0.46, 0.40, 0.34, 0.28, 0.24]

var _offsets := PackedFloat64Array()
var _group_offsets := PackedFloat64Array()
var _wave_vectors := PackedVector2Array()

func configure(seed_value: int) -> void:
	# Separate stream: source variety must not consume weather/event random draws.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 0x57415645
	_offsets.resize(SOURCE_COUNT)
	_group_offsets.resize(SOURCE_COUNT)
	_wave_vectors.resize(SOURCE_COUNT)
	for index in SOURCE_COUNT:
		_offsets[index] = 0.0 if index == 0 else rng.randf_range(0.0, TAU)
		_group_offsets[index] = rng.randf_range(0.0, TAU)
		# The primary vector is deliberately unnormalized: breaker cycle tracking
		# uses this exact pre-existing (x + 0.28 z) / 24 phase convention.
		var direction: Vector2 = DIRECTIONS[index] if index == 0 else DIRECTIONS[index].normalized()
		_wave_vectors[index] = direction * (TAU / WAVELENGTHS[index])

func sample_height(point: Vector2, amplitude: float, primary_phase: float, clock: float) -> float:
	var energy := smoothstep(CALM_AMPLITUDE, TEMPEST_AMPLITUDE, amplitude)
	var height := 0.0
	for index in SOURCE_COUNT:
		height += _contribution(index, point, amplitude, energy, primary_phase, clock)
	return height

## Inspection only; no allocations are needed by the per-cell production sampler.
func contributions(point: Vector2, amplitude: float, primary_phase: float, clock: float) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	var energy := smoothstep(CALM_AMPLITUDE, TEMPEST_AMPLITUDE, amplitude)
	for index in SOURCE_COUNT:
		result.append(_contribution(index, point, amplitude, energy, primary_phase, clock))
	return result

func _contribution(index: int, point: Vector2, amplitude: float, energy: float, primary_phase: float, clock: float) -> float:
	var spatial_phase := _wave_vectors[index].dot(point)
	var phase: float = primary_phase * PHASE_RATES[index] + _offsets[index]
	# A long wave group slowly raises/lowers this source independently. The
	# group speed follows integrated swell phase; a small clock term dephases it.
	var envelope := 1.0 if index == 0 else 0.68 + 0.32 * sin(spatial_phase * 0.23 - primary_phase * (0.12 + index * 0.027) + clock * 0.018 + _group_offsets[index])
	var strength := amplitude * lerpf(CALM_WEIGHTS[index], TEMPEST_WEIGHTS[index], energy) * envelope
	return signed_wave(spatial_phase, phase, strength)

static func signed_wave(spatial_phase: float, phase: float, strength: float) -> float:
	# Keep the sign until AFTER summation: opposite phases subtract naturally.
	return strength * sin(spatial_phase - phase)
