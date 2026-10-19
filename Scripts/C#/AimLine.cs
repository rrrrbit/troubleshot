using Godot;

public partial class AimLine : Line2D
{
    [ExportGroup("References")]
    [Export] private Node2D player;
    [Export] private Node2D cursor;

    public override void _Process(double delta)
    {
        SetPointPosition(0, player.GlobalPosition);
        SetPointPosition(1, player.GlobalPosition + cursor.Position);
    }
}
