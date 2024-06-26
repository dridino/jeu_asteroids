(* To manage ovni's movements *)
val set_sum_forces : Vector.t -> unit

val set_under_gravity : bool -> unit

val set_drag : float -> unit

(* Getter of position *)
val get_x : unit -> float

val get_y : unit -> float

(* To manage ovni's invicibility *)
val is_invincible : unit -> bool

val set_invincibility : bool -> unit

(* To manage ovni's hp *)
val get_hp : unit -> int

val is_alive : unit -> bool

val incr_hp : unit -> unit

val decr_hp : unit -> unit

(* To manage ovni's shooting *)
val delay : int ref

val allow_to_shoot : unit -> bool

val has_shot : unit -> unit
