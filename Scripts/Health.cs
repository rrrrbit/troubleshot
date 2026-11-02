/*

Stability is the singular resource combining health, ammo and energy in TRBLSHOT. It is reduced when taking damage, firing or dashing, and regenerated on kills or successful parries. 

When stability is below 0%, the player is "unstable" and can only survive for a limited time before dying and having to restart the level. In this state, wallcling and dash are less effective and [certain weapons] are disabled, but [certain other weapons] are free.

*/

using Godot;
using Microsoft.Win32;

namespace TROUBLESHOT.Scripts;
[GlobalClass]
public partial class Health : Node
{
    [Export] public float healthCurrent;
    [Export] public float healthMax;

    [Signal] public delegate void DiedEventHandler();
    [Signal] public delegate void HealthChangedEventHandler(float healthChange);

    public void ChangeHealth(float changeValue)
    {
        healthCurrent += changeValue;
        EmitSignal(SignalName.HealthChanged);
        if(healthCurrent <= 0)
        {
            EmitSignal(SignalName.Died);
        }
    }
}