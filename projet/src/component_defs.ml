open Ecs

(* Some type *)
type object_type_def =
  | Collidable
  | Asteroid
  | Ovni
  | Wall
  | Wall_bot
  | Screen

(* Some basic components *)
class object_type =
  object
    val object_type = Component.def Collidable

    method object_type = object_type
  end

class position =
  object
    val pos = Component.def Vector.zero

    method pos = pos
  end

class rect =
  object
    val rect = Component.def Rect.{ width = 0; height = 0 }

    method rect = rect
  end

class mass =
  object
    val mass = Component.def 0.

    method mass = mass
  end

class drag =
  object
    val drag = Component.def 0.

    method drag = drag
  end

class velocity =
  object
    val velocity = Component.def Vector.zero

    method velocity = velocity
  end

class sum_forces =
  object
    val sum_forces = Component.def Vector.zero

    method sum_forces = sum_forces
  end

class texture =
  object
    val texture = Component.def (Texture.color (Gfx.color 0 0 0 0))

    method texture = texture
  end

class id =
  object
    val id = Component.def ""

    method id = id
  end

class rebound =
  object
    val rebound = Component.def 0.

    method rebound = rebound
  end

(* Some complex components *)

class movable =
  object
    inherit position

    inherit drag

    inherit velocity
  end

class collidable =
  object
    inherit movable

    inherit mass

    inherit sum_forces

    inherit rebound

    inherit rect

    inherit object_type
  end

class drawable =
  object
    inherit position

    inherit rect

    inherit texture
  end

class box =
  object
    inherit drawable

    inherit! collidable

    inherit id
  end
