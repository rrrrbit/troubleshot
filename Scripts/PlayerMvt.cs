using Godot;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

public partial class PlayerMvt : CharacterBody2D
{
    [ExportGroup("References")]
    [Export] private PlayerRigidBody rb;
    [Export] private Node2D cursor;
    [Export] private Sprite2D sprite;
    [Export] private RichTextLabel debugText;

    [ExportGroup("Debug")]
    [Export] private bool _renderGizmos;

    [ExportGroup("Jump")]
    [Export] private float _TIME_JUMP = .6f;
    [Export] private float _HEIGHT_JUMP = 160;
    [Export] private float _MULTIPLIER_WALL_JUMP = 1.25f;

    [ExportGroup("Horizontal Movement")]
    [Export] private float _SPEED_MAX = 1250;
    [Export] private float _ACCEL = 3000;

    [ExportGroup("Drag")]
    [Export] private float _DRAG_GROUND = 4500;
    [Export] private float _DRAG_AIR = 300;
    [Export] private float _DRAG_SLIDE = 500;
    [Export] private float _DRAG_Y_WALLCLING = 7.5f;

    [ExportGroup("Dash")]
    [Export] private float _VEL_DASH = 2500;
    [Export] private float _TIME_DASH = .125f;
    private float _velJump => -4 * _HEIGHT_JUMP / _TIME_JUMP;
    private float _playerGravity => 8 / _TIME_JUMP / _TIME_JUMP * _HEIGHT_JUMP;

    [ExportGroup("Visuals")]
    [Export] private Curve _squishOverVelocity;
    [Export] private Curve _skewOverVelocityX;
    [Export] private Curve _skewOverVelocityY;
    [Export] private Curve _holePosOverCursorPos; // unused in player.gd too


    private Vector2 _direction = Vector2.Zero;
    private Vector2 _velLast = Vector2.Zero;
    private Vector2 _velLastDash = Vector2.Zero;

    private bool _isDashing = false;
    private bool _hasBounced = false;
    private bool _isWallClinging = false;
    private bool _isOnFloor = false;
    private bool _isOnWall => _wallDirection != 0;
    public bool IsGrounded => _isOnFloor; // PlayerCamera reads this (gd: target.on_floor)

    private int _jumpsLeft = 1;
    private Vector2 _surfaceNormal = Vector2.Zero;
    private int _wallDirection = 0;
    private enum DragState
    {
        GROUND, 
        PIVOT, 
        SLIDE, 
        AIR,
        NONE,
    }
    private DragState _dragState;

    private ShaderMaterial _shader;
    private Vector2 _skewCurrent = Vector2.Zero;
    private Vector2 _skewAxesCurrent = Vector2.Zero;
    private float _squishCurrent = 0f;
    private Vector2 _squishDirCurrent = Vector2.Zero;
    private bool _snapSquishDirThisFrame = false;

    public override void _Ready()
    {
        // shader = $Sprite2D.material
        _shader = (ShaderMaterial)sprite.Material;
        _shader.SetShaderParameter("holeSize", 3f);
        Engine.TimeScale = 1;
    }

    public override void _Process(double delta)
    {
        _direction = new Vector2(
            Input.GetAxis("-x", "+x"), 
            - Input.GetAxis("-y", "+y")
            );

        // %HUD/debugText.text = ("vel: " + 
        debugText.Text = ("vel: " +
            Mathf.Round(Velocity.X) + ", " +
            Mathf.Round(Velocity.Y) +
            " speed: " + Mathf.Round(Velocity.Length()) +
            "\nfloor: " + _isOnFloor +
            "\nwall: " + _wallDirection +
            "\ndrag type: " + _dragState +
            "\n\nwallcling: " + _isWallClinging +
            "\n\nfps: " + Engine.GetFramesPerSecond()
            );

        QueueRedraw();
    }

    private void UpdateShader(float dt)
    {
        var cursorD = (cursor.GlobalPosition) - (GlobalPosition);
        var hole = (cursorD / 25).LimitLength(.25f);
        _shader.SetShaderParameter("holePos", hole);

        Vector2 squishDir = Vector2.Zero;
        if (_isOnFloor)
        {
            _shader.SetShaderParameter("squishPivot", Vector2.Down);
            squishDir = Vector2.Right;
            _snapSquishDirThisFrame = true;
        }
        else if (_isOnWall)
        {
            _shader.SetShaderParameter("squishPivot", new Vector2(_wallDirection, 0f));
            squishDir = Vector2.Up;
            _snapSquishDirThisFrame = true;
        }
        else
        {
            _shader.SetShaderParameter("squishPivot", Vector2.Zero);
            squishDir = Velocity;
        }

        var squishRatio = 1f;
        if (!_isOnFloor && !_isOnWall)
        {
            squishRatio = _squishOverVelocity.Sample(Velocity.Length());
        }

        if (_snapSquishDirThisFrame)
        {
            _squishDirCurrent = squishDir;
            _snapSquishDirThisFrame = false;
        }
        else
        {
            _squishDirCurrent = Mathv.Lerpd(_squishDirCurrent, squishDir, .5f, .05f, dt);
        }

        _squishCurrent = GLOBAL.Lerpd(_squishCurrent, squishRatio, .3f, .05f, dt);
        _shader.SetShaderParameter("squishRatio", _squishCurrent);
        _shader.SetShaderParameter("squishDir", _squishDirCurrent);

        Vector2 skewAxes = Vector2.Zero;
        Vector2 skewAmt = Vector2.Zero;
        if (_isOnFloor)
        {
            skewAxes = Vector2.Down;
            skewAmt.X = _skewOverVelocityX.Sample(Velocity.X);
        }
        else if (_isOnWall)
        {
            skewAxes.X = _direction.X;
            skewAmt.Y = _direction.X != 0 ? _skewOverVelocityY.Sample(Velocity.Y) * _direction.X : 0;
        }

        _skewCurrent = Mathv.Lerpd(_skewCurrent, skewAmt, .5f, .03f, dt);
        _skewAxesCurrent = Mathv.Lerpd(_skewAxesCurrent, skewAxes, .5f, .03f, dt);

        _shader.SetShaderParameter("shearPivot", _skewAxesCurrent);
        _shader.SetShaderParameter("shearAmts", _skewCurrent);
    }

    private void CalculateTouches()
    {
        _wallDirection = (IsTouching(Vector2.Right) ? 1 : 0) - (IsTouching(Vector2.Left) ? 1 : 0);
        _isOnFloor = IsTouching(Vector2.Down);
    }

    private bool IsTouching(Vector2 direction)
    {
        return MoveAndCollide(direction, true) != null;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;

        CalculateTouches();
        List<Vector2> normals = rb.GetAllCollisionNormals();

        Vector2 lastCollisionNormal = Vector2.Zero;
        if (GetLastSlideCollision() != null)
        {
            lastCollisionNormal = GetLastSlideCollision().GetNormal().Normalized();
        }
        _isWallClinging = _isOnWall && !_isOnFloor && normals.Any(x => x.Dot(_velLast) < 0);

        ApplyGravity(dt);

        if (_isDashing && lastCollisionNormal.Dot(_velLast) < 0)
        {
            Velocity = _velLast.Bounce(lastCollisionNormal) * (_hasBounced ? 1 : .7f);
            _hasBounced = true;
        }

        if (_isOnFloor) _jumpsLeft = 1;
            

        if (Input.IsActionJustPressed("dash") && !_direction.IsZeroApprox())
        {
            Velocity = Velocity with { Y = 0 };
            Dash(GetDashDirection() * _VEL_DASH);
        }

        HandleJump(normals);
        HandleXMvt(dt);
        _velLast = Velocity;
        MoveAndSlide();
        UpdateShader(dt);
    }

    private void HandleXMvt(float dt)
    {
        if (!_isDashing)
        {
            if (_direction.X != 0 && Mathf.Abs(Velocity.X) <= _SPEED_MAX)
            {
                Velocity += Vector2.Right * _ACCEL * _direction.X * dt;
                _dragState = Mathf.Sign(_direction.X) != Mathf.Sign(Velocity.X) ? DragState.PIVOT : DragState.NONE;
            }
            else if (_isOnFloor)
            {
                if (Input.IsActionPressed("-y")) _dragState = DragState.SLIDE;
                else _dragState = DragState.GROUND;
            }
            else _dragState = DragState.AIR;
            HandleDrag(dt);
        }
    }

    private void HandleDrag(float dt)
    {
        float drag = _dragState switch
        {
            DragState.GROUND => _DRAG_GROUND,
            DragState.PIVOT => _DRAG_GROUND,
            DragState.SLIDE => _DRAG_SLIDE,
            DragState.AIR => _DRAG_AIR,
            DragState.NONE => 0,
            _ => 0
        };
        Velocity = Velocity with { X = Mathf.MoveToward(Velocity.X, 0, drag * dt) };
    }

    private void HandleJump(List<Vector2> normals)
    {
        if (Input.IsActionPressed("jump"))
        {
            if (_isOnWall && normals.Any(x => Mathf.Sign(x.X) == Mathf.Sign(_direction.X)))
            {
                GD.Print("wallbounce");
            }
            if (_isOnFloor)
            {
                GD.Print("floor jump");
                Velocity = Velocity with { Y = _velJump + (_isDashing && _velLastDash.X == 0 ? Velocity.Y : 0) }; // if dashed downwards, jump higher
            }
            else if (_isWallClinging && !_isDashing && _direction.X != 0)
            {
                GD.Print("wall jump");
                Velocity = new Vector2(
                    _wallDirection * _velJump,
                    _velJump * _MULTIPLIER_WALL_JUMP
                    );
            }

            if (!_isOnFloor && _jumpsLeft > 0 && Input.IsActionJustPressed("jump"))
            {
                GD.Print("air jump");
                Velocity = Velocity with { Y = _velJump };
                _jumpsLeft--;
            }
        }
    }

    private void ApplyGravity(float dt)
    {
        if (!_isOnFloor && !_isDashing)
        {
            Velocity += Vector2.Down * _playerGravity * dt;
        }
        if (_isWallClinging && Velocity.Y > 0)
        {
            Velocity += Vector2.Up * _DRAG_Y_WALLCLING * Velocity.Y * dt;
        }
    }

    private Vector2 GetDashDirection()
    {
        var dir = _direction.Normalized();
        if (_isWallClinging)
        {
            return dir * new Vector2(-1, 1);
        }
        else if (_isOnFloor)
        {
            return new Vector2(_direction.X, 0);
        }
        else
        {
            return dir;
        }
    }

    public override void _Draw()
    {
        if (!_renderGizmos) return;

        DrawSetTransformMatrix(GlobalTransform.AffineInverse());
        List<Vector2> pos = rb.GetAllCollisionPoints();
        List<Vector2> norm = rb.GetAllCollisionNormals();

        for (int i = 0; i < pos.Count; i++)
        {
            DrawLine(pos[i], pos[i] + norm[i] * 50f, Colors.White, -2);
        }
        DrawLine(Position, Position + _direction.Normalized() * 50, Colors.Red, -2);
        DrawLine(Position, Position + Velocity / 10f, Colors.Green, -2);
    }

    private async Task Dash(Vector2 direction)
    {
        var prevVel = Velocity;
        _velLastDash = direction.Normalized();
        Velocity = direction;
        _isDashing = true;
        _hasBounced = false;

        await ToSignal(GetTree().CreateTimer(_TIME_DASH), SceneTreeTimer.SignalName.Timeout);

        if (!_hasBounced)
        {
            if (Input.IsActionPressed("dash"))
            {
                GD.Print("long dash");
                Velocity -= (Velocity - prevVel) * .25f;
            }
            else if(Velocity.Dot(prevVel) < 0)
            {
                GD.Print("short dash brake");
                Velocity = direction * .1f;
            }
            else
            {
                GD.Print("short dash");
                Velocity = prevVel;
            }
        }
        else
        {
            GD.Print("bounce");
        }

        _isDashing = false;
        _hasBounced = false;
    }
}
