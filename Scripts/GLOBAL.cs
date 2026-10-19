using Godot;
using System.Threading.Tasks;

public static class GLOBAL
{
    // func lerpd(a,b,k,t,d):
    // 	return (
    // 		a.lerp(b,1-(1-k)**(d/t)) if typeof(a)==TYPE_VECTOR2 
    // 		else lerpf(a,b,1-(1-k)**(d/t))
    // 		)
    // gd branched on typeof(a); here it's overloads, float lives here and Vector2 lives in Mathv
    public static float Lerpd(float a, float b, float k, float t, float d)
    {
        return Mathf.Lerp(
            a, b,
            1 - Mathf.Pow(
                1 - k,
                d / t));
    }

    // func Wait(t):
    // 	await get_tree().create_timer(t).timeout
    // no get_tree() in a static class, so it takes the tree (PlayerMvt.Dash inlines the same thing)
    public static async Task Wait(SceneTree tree, float t)
    {
        await tree.ToSignal(tree.CreateTimer(t), SceneTreeTimer.SignalName.Timeout);
    }
}

public static class Mathv
{
    public static Vector2 Lerpd(Vector2 a, Vector2 b, float k, float t, float d)
    {
        return a.Lerp(
            b,
            1 - Mathf.Pow(
                1 - k,
                d / t));
    }
}
