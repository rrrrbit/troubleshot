extends Camera2D
@export var renderGizmos: bool

@export_category("nodes")
@export var target : CollisionObject2D
@export var cursor : Node2D
@export_category("zones")
@export var boundaryPadding : Vector2
@export var targetZone : Vector2
@export var deadzone : Vector2
@export_category("offset")
@export var lookahead : Vector2
@export var cursorInfluence: Vector2
@export var groundedOffset: Vector2
@export_category("zoom")
@export var zoomOverVelocity : Curve
@export_category("smoothing")
@export var smoothK : float
@export var smoothT : float
@export var lookaheadSmoothK : float
@export var lookaheadSmoothT : float
@export var dzSmoothK : float
@export var dzSmoothT : float
@export var cursorSmoothK : float
@export var cursorSmoothT : float
@export var zoomSmoothK : float
@export var zoomSmoothT : float

var targetZoneRect : Rect2
var dzRect : Rect2
var boundaryRect : Rect2
var targetPos : Vector2
var offsetLookahead := Vector2.ZERO
var offsetCursor := Vector2.ZERO
var finalPos := Vector2.ZERO
var posRaw := Vector2.ZERO
var zoomScalar := 1.0


func _ready():
	finalPos = target.position

func _physics_process(delta):
	zoomScalar =  GLOBAL.lerpd(zoomScalar,
	zoomOverVelocity.sample(target.velocity.length()),
	zoomSmoothK, zoomSmoothT, delta
	) 
	
	zoom = Vector2.ONE * zoomScalar
	
	offsetCursor = GLOBAL.lerpd(offsetCursor,
		(cursor.global_position - target.global_position) * cursorInfluence,
		cursorSmoothK, cursorSmoothT, delta
		)
		
	offsetLookahead = GLOBAL.lerpd(offsetLookahead,
		target.velocity * lookahead,
		lookaheadSmoothK, lookaheadSmoothT, delta
		)
		
	targetPos = target.position + offsetLookahead + groundedOffset * (1 if target.is_on_floor() else -1 if target.ceilingcling else 0)

	finalPos = GLOBAL.lerpd(finalPos,
		finalPos + targetPos - targetPos.clamp(dzRect.position, dzRect.end),
		dzSmoothK, dzSmoothT, delta
		)

	finalPos = GLOBAL.lerpd(finalPos,
	finalPos + targetPos - targetPos.clamp(targetZoneRect.position, targetZoneRect.end),
	smoothK, smoothT, delta
	) 
	
	dzRect = Rect2(finalPos - deadzone/2/zoomScalar, deadzone/zoomScalar)
	targetZoneRect = Rect2(finalPos - targetZone/2/zoomScalar, targetZone/zoomScalar)
	
	var visibleRectSize = get_window().get_visible_rect().size
	boundaryRect = Rect2(finalPos - visibleRectSize/2/zoomScalar + boundaryPadding/zoomScalar, (visibleRectSize - boundaryPadding*2)/zoomScalar)

	finalPos += target.position - target.position.clamp(boundaryRect.position, boundaryRect.end)
	
	position = finalPos + offsetCursor 
	
	
	queue_redraw()

func _draw():
	if not renderGizmos: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	
	draw_rect(boundaryRect, Color.RED, false, -2.0)
	draw_rect(targetZoneRect, Color.WHITE, false, -2.0)
	draw_rect(dzRect, Color.DIM_GRAY, false, -2.0)
	draw_cross(target.position, Vector2.ONE*10)
	
	draw_cross(targetPos.clamp(targetZoneRect.position, targetZoneRect.end), Vector2.ONE*10, Color.RED)
	draw_cross(targetPos.clamp(dzRect.position, dzRect.end), Vector2.ONE*10, Color.YELLOW)
	
	draw_cross(target.position.clamp(boundaryRect.position, boundaryRect.end), Vector2.ONE*10, Color.GREEN)
	
	
	draw_cross(targetPos, Vector2.ONE*10, Color.GREEN)


func draw_cross(pos := Vector2.ZERO, size := Vector2(50,50), color := Color.WHITE, width := -2.0):
	draw_line(
		pos+Vector2(0,size.y/2),
		pos-Vector2(0,size.y/2),
		color,
		width
		)
		
	draw_line(
		pos+Vector2(size.x/2,0),
		pos-Vector2(size.x/2,0),
		color,
		width
		)
