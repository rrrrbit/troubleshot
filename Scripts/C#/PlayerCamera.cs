using Godot;

public partial class PlayerCamera : Camera2D
{
    [ExportGroup("References")]
    [Export] private PlayerMvt target; // gd: CollisionObject2D (duck typed .velocity/.on_floor), C# needs the real type
    [Export] private Node2D cursor;

    [ExportGroup("Debug")]
    [Export] private bool _renderGizmos;

    [ExportGroup("Zones")]
    [Export] private Vector2 _boundaryPadding = new(100, 100);
    [Export] private Vector2 _targetZone = new(50, 400);
    [Export] private Vector2 _deadzone;

    [ExportGroup("Offset")]
    [Export] private Vector2 _lookahead = new(.2f, .2f);
    [Export] private Vector2 _cursorInfluence = new(.3f, .3f);
    [Export] private Vector2 _groundedOffset = new(0, -50);

    [ExportGroup("Zoom")]
    [Export] private Curve _fovOverVelocity;
    [Export] private Curve _fovOverCursorDist;

    [ExportGroup("Smoothing")]
    [Export] private float _smoothK = .25f;
    [Export] private float _smoothT = .02f;
    [Export] private float _lookaheadSmoothK = .25f;
    [Export] private float _lookaheadSmoothT = .1f;
    [Export] private float _dzSmoothK = .25f;
    [Export] private float _dzSmoothT = .2f;
    [Export] private float _cursorSmoothK = .25f;
    [Export] private float _cursorSmoothT = .05f;
    [Export] private float _zoomSmoothK = .1f;
    [Export] private float _zoomSmoothT = .1f;

    private Rect2 _rectTargetZone;
    private Rect2 _rectDeadzone;
    private Rect2 _rectBoundary;
    private Vector2 _posTarget;
    private Vector2 _offsetLookahead = Vector2.Zero;
    private Vector2 _offsetCursor = Vector2.Zero;
    private Vector2 _posFinal = Vector2.Zero;
    private float _zoomScalar = 1f;

    public override void _Ready()
    {
        _posFinal = target.Position;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;

        _zoomScalar = GLOBAL.Lerpd(
            _zoomScalar,
            _fovOverVelocity.Sample(target.Velocity.Length()) + _fovOverCursorDist.Sample((cursor.GlobalPosition - target.GlobalPosition).Length()),
            _zoomSmoothK, _zoomSmoothT, dt
            );

        Zoom = Vector2.One / _zoomScalar;

        _offsetCursor = Mathv.Lerpd(
            _offsetCursor,
            (cursor.GlobalPosition - target.GlobalPosition) * _cursorInfluence,
            _cursorSmoothK, _cursorSmoothT, dt
            );

        _offsetLookahead = Mathv.Lerpd(
            _offsetLookahead,
            target.Velocity * _lookahead,
            _lookaheadSmoothK, _lookaheadSmoothT, dt
            );

        _posTarget = target.Position + _offsetLookahead + _groundedOffset * (target.IsGrounded ? 1 : 0);

        _posFinal = Mathv.Lerpd(
            _posFinal,
            _posFinal + _posTarget - _posTarget.Clamp(_rectDeadzone.Position, _rectDeadzone.End),
            _dzSmoothK, _dzSmoothT, dt
            );

        _posFinal = Mathv.Lerpd(
            _posFinal,
            _posFinal + _posTarget - _posTarget.Clamp(_rectTargetZone.Position, _rectTargetZone.End),
            _smoothK, _smoothT, dt
            );

        _rectDeadzone = new Rect2(_posFinal - _deadzone / 2 / _zoomScalar, _deadzone / _zoomScalar);
        _rectTargetZone = new Rect2(_posFinal - _targetZone / 2 / _zoomScalar, _targetZone / _zoomScalar);

        var visibleRectSize = GetWindow().GetVisibleRect().Size;
        _rectBoundary = new Rect2(_posFinal - visibleRectSize / 2 / _zoomScalar + _boundaryPadding / _zoomScalar, (visibleRectSize - _boundaryPadding * 2) / _zoomScalar);

        _posFinal += target.Position - target.Position.Clamp(_rectBoundary.Position, _rectBoundary.End);

        Position = _posFinal + _offsetCursor;

        QueueRedraw();
    }

    public override void _Draw()
    {
        if (!_renderGizmos) return;
        DrawSetTransformMatrix(GlobalTransform.AffineInverse());

        DrawRect(_rectBoundary, Colors.Red, false, -2f);
        DrawRect(_rectTargetZone, Colors.White, false, -2f);
        DrawRect(_rectDeadzone, Colors.DimGray, false, -2f);
        DrawCross(target.Position, Vector2.One * 10);

        DrawCross(_posTarget.Clamp(_rectTargetZone.Position, _rectTargetZone.End), Vector2.One * 10, Colors.Red);
        DrawCross(_posTarget.Clamp(_rectDeadzone.Position, _rectDeadzone.End), Vector2.One * 10, Colors.Yellow);

        DrawCross(target.Position.Clamp(_rectBoundary.Position, _rectBoundary.End), Vector2.One * 10, Colors.Green);

        DrawCross(_posTarget, Vector2.One * 10, Colors.Green);
    }

    // func draw_cross(pos := Vector2.ZERO, size := Vector2(50,50), color := Color.WHITE, width := -2.0):
    // C# default args have to be compile-time constants, so size/color are nullable and filled in below
    private void DrawCross(Vector2 pos = default, Vector2? size = null, Color? color = null, float width = -2f)
    {
        var s = size ?? new Vector2(50, 50);
        var c = color ?? Colors.White;

        DrawLine(
            pos + new Vector2(0, s.Y / 2),
            pos - new Vector2(0, s.Y / 2),
            c,
            width
            );

        DrawLine(
            pos + new Vector2(s.X / 2, 0),
            pos - new Vector2(s.X / 2, 0),
            c,
            width
            );
    }
}
