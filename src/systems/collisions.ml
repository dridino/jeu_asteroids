open Component_defs

type t = box

let init _ = ()

let unregistered_lasers = ref []

let is_wall e =
  match e#object_type#get with Wall | Wall_bot -> true | _ -> false

let is_wall_bot e = e#object_type#get = Wall_bot

let is_ovni e = e#object_type#get = Ovni

let is_asteroid e = e#object_type#get = Asteroid

let is_laser e = e#object_type#get = Laser

let ovni_is_in_mortal_collision e1 e2 =
  (is_ovni e1 && is_asteroid e2)
  || (is_asteroid e1 && is_ovni e2)
  || (is_ovni e1 && is_wall_bot e2)
  || (is_wall_bot e1 && is_ovni e2)

let is_collision_between_laser_and_asteroid e1 e2 =
  (is_laser e1 && is_asteroid e2) || (is_asteroid e1 && is_laser e2)

let is_collision_between_asteroid_and_ovni e1 e2 =
  (is_ovni e1 && is_asteroid e2) || (is_asteroid e1 && is_ovni e2)

let is_collision_between_asteroid_and_asteroid e1 e2 =
  is_asteroid e1 && is_asteroid e2

let is_not_collision_between_asteroid_and_wall e1 e2 =
  let b = (is_asteroid e1 && is_wall e2) || (is_wall e1 && is_asteroid e2) in
  not b

let is_not_collision_between_laser_and_wall e1 e2 =
  let b = (is_laser e1 && is_wall e2) || (is_wall e1 && is_laser e2) in
  not b

let is_not_collision_between_asteroid_and_ovni e1 e2 =
  not (is_collision_between_asteroid_and_ovni e1 e2)

let is_not_collision_between_laser_and_ovni e1 e2 =
  let b = (is_ovni e1 && is_laser e2) || (is_laser e1 && is_ovni e2) in
  not b

let pass e1 e2 =
  let b =
    is_not_collision_between_asteroid_and_wall e1 e2
    && is_not_collision_between_laser_and_wall e1 e2
  in
  if Ovni.is_invincible () then
    b
    && is_not_collision_between_asteroid_and_ovni e1 e2
    && is_not_collision_between_laser_and_ovni e1 e2
  else b

let update dt el =
  let len_el = Array.length el in
  for i = 0 to len_el - 1 do
    let e1 = el.(i) in
    let pos1 = e1#pos#get in
    let box1 = e1#rect#get in
    let v1 = e1#velocity#get in
    let m1 = e1#mass#get in
    for j = i + 1 to len_el - 1 do
      let e2 = el.(j) in
      (* les composants du rectangle r1 *)
      let m2 = e2#mass#get in
      (* Une double boucle qui évite de comparer deux fois
         les objets : si on compare A et B, on ne compare pas B et A.
         Il faudra améliorer cela si on a beaucoup (> 30) objets simultanément.
      *)
      if j > i && (Float.is_finite m1 || Float.is_finite m2) && pass e1 e2 then begin
        (* les composants du rectangle r2 *)
        let pos2 = e2#pos#get in
        let box2 = e2#rect#get in
        (* les vitesses *)
        let v2 = e2#velocity#get in
        (* [1] la soustraction de Minkowski *)
        let s_pos, s_rect = Rect.mdiff pos2 box2 pos1 box1 in
        (* [2] si intersection et un des objets et mobile, les objets rebondissent *)
        if
          Rect.has_origin s_pos s_rect
          && not (Vector.is_zero v1 && Vector.is_zero v2)
        then begin
          (* modif hp *)
          if ovni_is_in_mortal_collision e1 e2 then Ovni.decr_hp ();

          (*
            Si collision entre asteroid et (ovni ou asteroid)
            alors on active la gravité sur la/les asteroid(s)
          *)
          let drag = 0.01 in
          let rebound = 0.75 in
          if is_collision_between_asteroid_and_asteroid e1 e2 then begin
            e1#under_gravity#set true;
            e1#rebound#set rebound;
            e1#drag#set drag;

            e2#under_gravity#set true;
            e2#rebound#set rebound;
            e2#drag#set drag
          end
          else if is_collision_between_asteroid_and_ovni e1 e2 then begin
            if is_asteroid e1 then begin
              e1#under_gravity#set true;
              e1#rebound#set rebound;
              e1#drag#set drag
            end
            else if is_asteroid e2 then begin
              e2#under_gravity#set true;
              e2#rebound#set rebound;
              e2#drag#set drag
            end
          end;

          (* On brise en 4 l'asteroid si possible et on supprime le laser *)
          if is_collision_between_laser_and_asteroid e1 e2 then begin
            if e1#object_type#get = Asteroid then (
              if not (List.mem e2#id#get !unregistered_lasers) then (
                Entities.lasers#unregister e2;
                Entities.asteroids#unregister e1;
                unregistered_lasers := e2#id#get :: !unregistered_lasers ) )
            else if not (List.mem e1#id#get !unregistered_lasers) then (
              Entities.lasers#unregister e1;
              Entities.asteroids#unregister e2;
              unregistered_lasers := e1#id#get :: !unregistered_lasers )
          end
          else
            (* [3] le plus petit des vecteurs a b c d *)
            let a = Vector.{ x = s_pos.x; y = 0.0 } in
            let b = Vector.{ x = float s_rect.width +. s_pos.x; y = 0.0 } in
            let c = Vector.{ x = 0.0; y = s_pos.y } in
            let d = Vector.{ x = 0.0; y = float s_rect.height +. s_pos.y } in
            let n =
              List.fold_left
                (fun min_v v ->
                  if Vector.norm v <= Vector.norm min_v then v else min_v )
                d [ a; b; c ]
            in
            (*  [4] rapport des vitesses et déplacement des objets *)
            let n_v1 = Vector.norm v1 in
            let n_v2 = Vector.norm v2 in
            let s = 1.01 /. (n_v1 +. n_v2) in
            let n1 = n_v1 *. s in
            let n2 = n_v2 *. s in
            let delta_pos1 = Vector.mult n1 n in
            let delta_pos2 = Vector.mult (-.n2) n in
            let pos1 = Vector.add pos1 delta_pos1 in
            let pos2 = Vector.add pos2 delta_pos2 in
            let s_pos, s_rect = Rect.mdiff pos2 box2 pos1 box1 in
            if Rect.has_origin s_pos s_rect then begin
              Gfx.debug "%f, %f, %d x %d\n" s_pos.Vector.x s_pos.Vector.y
                s_rect.Rect.width s_rect.Rect.height
            end;
            e1#pos#set pos1;
            e2#pos#set pos2;

            (* [5] On normalise n (on calcule un vecteur de même direction mais de norme 1) *)
            let n = Vector.normalize n in
            (* [6] Vitesse relative entre v2 et v1 *)
            let v = Vector.sub v1 v2 in

            (* Préparation au calcul de l'impulsion *)
            (* Elasticité fixe. En pratique, l'elasticité peut être stockée dans
               les objets comme un composant : 1 pour la balle et les murs, 0.5 pour
               des obstacles absorbants, 1.2 pour des obstacles rebondissant, … *)
            let e = max e1#rebound#get e2#rebound#get in
            (* normalisation des masses *)
            let m1, m2 =
              if Float.is_infinite m1 && Float.is_infinite m2 then
                if n_v1 = 0.0 then (m1, 1.0)
                else if n_v2 = 0.0 then (1.0, m2)
                else (0.0, 0.0)
              else (m1, m2)
            in
            (* [7] calcul de l'impulsion *)
            (*
              let jbase = -.(1.0 +. e) *. Vector.dot v n in
              let m1divm2 = m1 /. m2 in
              let m2divm1 = m2 /. m1 in
              let j1 = jbase /. (1.0 +. m1divm2) in
              let j2 = jbase /. (1.0 +. m2divm1) in
              *)
            let j =
              -.(1.0 +. e) *. Vector.dot v n /. ((1. /. m1) +. (1. /. m2))
            in
            (* [8] calcul des nouvelles vitesses *)
            let new_v1 = Vector.add v1 (Vector.mult (j /. m1) n) in
            let new_v2 = Vector.sub v2 (Vector.mult (j /. m2) n) in
            (* [9] mise à jour des vitesses *)
            e1#velocity#set new_v1;
            e2#velocity#set new_v2
        end
      end
    done
  done

let update dt el =
  let tab_el = Array.of_seq el in
  for i = 0 to 3 do
    update dt tab_el
  done;
  unregistered_lasers := []
