extends Node

func lerpd(a,b,k,t,d):
	return (
		a.lerp(b,1-(1-k)**(d/t)) if typeof(a)==TYPE_VECTOR2 
		else lerpf(a,b,1-(1-k)**(d/t))
		)
		
func Wait(t):
	await get_tree().create_timer(t).timeout
