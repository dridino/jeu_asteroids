(* WINDOW *)
let window, init =
  let window_r = ref None in
  ( (fun () ->
      match !window_r with
      | Some w -> w
      | None -> failwith "Uninitialized window" )
  , fun str ->
      let w = Gfx.create str in
      window_r := Some w )

(* DIMENSION SCREEN *)
let height = 900

let width = 2 * height

(* FONT *)
let font = Gfx.load_font "monospace" "" 24

let big_font = Gfx.load_font "monospace" "" 256

(* WALL *)
let wall_l = 80

(* OVNI *)

let ovni_w, ovni_h =
  let factor = 2.5 in
  (int_of_float (19. *. factor), int_of_float (32. *. factor))

(* ASTEROIDS *)
let asteroid_size = 60

(* GRAVITY *)
let gravity, set_gravity =
  let gravity_r = ref 0.015 in
  ((fun () -> !gravity_r), fun v -> gravity_r := v)

(* SCORING *)
let scoring, increase_scoring =
  let scoring_r = ref 0. in
  ((fun () -> !scoring_r), fun n -> scoring_r := !scoring_r +. n)

(* WAVE COUNTER *)
let get_wave, incr_wave =
  let wc = ref 0 in
  ((fun () -> !wc), fun () -> incr wc)

(* HASHTABL TEXTURES *)
type kind_texture =
  | Ovni
  | Asteroid
  | Laser

let get_texture, set_texture, textures_are_ready =
  let (htbl : (kind_texture, Gfx.surface Gfx.resource) Hashtbl.t) =
    Hashtbl.create 16
  in
  ( (fun s -> Hashtbl.find htbl s)
  , (fun s t -> Hashtbl.replace htbl s t)
  , fun () ->
      Hashtbl.fold
        (fun _key value acc -> acc || not (Gfx.resource_ready value))
        htbl false )

(* (id, dir, (x, y)) *)
let asteroids_to_add : (string * float * (float * float)) list ref = ref []

let add_asteroid id dir pos =
  asteroids_to_add := (id, dir, pos) :: !asteroids_to_add

let reset_asteroids_to_add () = asteroids_to_add := []
