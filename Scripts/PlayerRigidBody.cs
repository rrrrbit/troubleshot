using Godot;
using System;
using System.Collections.Generic;

public partial class PlayerRigidBody : RigidBody2D
{
    private PhysicsDirectBodyState2D _physicsState;

    public override void _IntegrateForces(PhysicsDirectBodyState2D state)
    {
        _physicsState = state;
    }

    public List<Vector2> GetAllCollisionNormals()
    {
        List<Vector2> normals = new();
        if (_physicsState != null)
        {
            for (int i = 0; i < _physicsState.GetContactCount(); i++)
            {
                normals.Add(_physicsState.GetContactLocalNormal(i));
            }
        }
        return normals;
    }

    public List<Vector2> GetAllCollisionPoints()
    {
        List<Vector2> points = new();
        if (_physicsState != null)
        {
            for (int i = 0; i < _physicsState.GetContactCount(); i++)
            {
                points.Add(_physicsState.GetContactLocalPosition(i));
            }
        }
        return points;
    }
}
