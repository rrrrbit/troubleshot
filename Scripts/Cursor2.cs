using Godot;

public partial class Cursor2 : Node2D
{
    [ExportGroup("Aim")]
    [Export] private float _sensitivity = 1; // px / deg
    [Export] private Vector2 _sensitivity2 = new(500, 2.5f);
    [Export] private float _range = 1000;
    [Export] private bool _locked; // unused in cursor2.gd too

    private enum AimType
    {
        CARTESIAN,
        FIXED_ANGULAR,
        DISTANCE_SCALED,
    }
    [Export] private AimType _aimType = AimType.DISTANCE_SCALED;

    public override void _Ready()
    {
        Input.MouseMode = Input.MouseModeEnum.Captured;
        //GlobalPosition = GetParent<Node2D>().GlobalPosition;
    }

    public override void _Input(InputEvent @event)
    {
        // if event.is_class("InputEventMouseMotion"):
        if (@event is InputEventMouseMotion motion)
        {
            var d = motion.ScreenRelative;
            d = _aimType switch
            {
                AimType.CARTESIAN => CartesianD(d, _sensitivity),
                AimType.FIXED_ANGULAR => FixedAngularD(Position, d, _sensitivity),
                AimType.DISTANCE_SCALED => DistanceScaledD(Position, d, _sensitivity, _sensitivity2),
                _ => d
            };

            Position += d;

            if ((GlobalPosition - GetParent<Node2D>().GlobalPosition).LengthSquared() > Mathf.Pow(_range, 2))
            {
                Position = (GlobalPosition - GetParent<Node2D>().GlobalPosition).LimitLength(_range); //clamp
            }
            QueueRedraw();
        }
    }

    private Vector2 CartesianD(Vector2 rawD, float sens)
    {
        return rawD * sens;
    }

    private Vector2 FixedAngularD(Vector2 pos, Vector2 rawD, float sens)
    {
        Vector2 right = new Vector2(-pos.Y, pos.X).Normalized();
        Vector2 tang = rawD.Project(right);
        float angle = Mathf.DegToRad(rawD.Dot(right) / sens);
        float arcLength = angle * pos.Length();
        Vector2 adjustedTang = right * arcLength;
        return rawD * adjustedTang.Length() / tang.Length();
    }

    private Vector2 DistanceScaledD(Vector2 pos, Vector2 rawD, float zero, Vector2 neutral)
    {
        return rawD * ((neutral.Y - zero) / neutral.X * pos.Length() + zero);
    }

    public override void _Draw()
    {
        DrawSetTransformMatrix(Transform.AffineInverse());
        DrawCircle(Vector2.Zero, _sensitivity2.X, Colors.HotPink, false, 3);
    }
}
