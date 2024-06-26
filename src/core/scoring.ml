let mk_star, active_mk_star, reset_mk_star =
  let mk_star = ref false in
  let old_gravity = ref (Global.gravity ()) in
  ( (fun () -> !mk_star)
  , (fun () ->
      let grav = Global.gravity () in
      old_gravity := grav;
      Global.set_gravity (10. *. grav);
      mk_star := true )
  , fun () ->
      Global.set_gravity !old_gravity;
      mk_star := false )

let get, update, add, set_factor =
  let scoring = ref 0. in
  let factor = ref 1. in
  ( (fun () -> !scoring)
  , (fun () -> scoring := !scoring +. (!factor *. 10. *. Global.gravity ()))
  , (fun x -> scoring := !scoring +. x)
  , fun x -> factor := x )

let get_wave, incr_wave =
  let wc = ref 0 in
  ( (fun () -> !wc)
  , fun () ->
      if not (mk_star ()) then Global.set_gravity (Global.gravity () *. 1.1);
      incr wc )
