(* Anamnesis Generic Conversation Module
 * Normalized conversation representation
 *)

(* Re-export generated types *)
include Conversation_types_t

(* Equality functions *)

let equal_speaker s1 s2 =
  match (s1, s2) with
  | Human h1, Human h2 -> String.equal h1 h2
  | LLM llm1, LLM llm2 ->
      String.equal llm1.model llm2.model
      && Option.equal String.equal llm1.provider llm2.provider
  | _ -> false

let equal_lifecycle_state s1 s2 =
  match (s1, s2) with
  | Created, Created -> true
  | Modified, Modified -> true
  | Removed, Removed -> true
  | Evaluated, Evaluated -> true
  | _ -> false

let equal_artifact_type t1 t2 =
  match (t1, t2) with
  | Code l1, Code l2 -> String.equal l1 l2
  | Documentation, Documentation -> true
  | Configuration, Configuration -> true
  | Other s1, Other s2 -> String.equal s1 s2
  | _ -> false

let equal_message m1 m2 =
  String.equal m1.id m2.id &&
  equal_speaker m1.speaker m2.speaker &&
  String.equal m1.content m2.content &&
  Float.equal m1.timestamp m2.timestamp

let equal_artifact a1 a2 =
  String.equal a1.id a2.id &&
  Option.equal String.equal a1.name a2.name &&
  equal_artifact_type a1.artifact_type a2.artifact_type &&
  equal_lifecycle_state a1.current_state a2.current_state

let equal conv1 conv2 =
  String.equal conv1.id conv2.id &&
  Option.equal String.equal conv1.platform conv2.platform &&
  Float.equal conv1.timestamp conv2.timestamp &&
  List.equal equal_message conv1.messages conv2.messages &&
  Option.equal (List.equal equal_artifact) conv1.artifacts conv2.artifacts

(* Display functions *)

let string_of_speaker = function
  | Human h -> Printf.sprintf "Human(%s)" h
  | LLM llm ->
      let provider =
        match llm.provider with
        | Some p -> p
        | None -> "unknown"
      in
      Printf.sprintf "LLM(%s, %s)" llm.model provider

let string_of_lifecycle_state = function
  | Created -> "created"
  | Modified -> "modified"
  | Removed -> "removed"
  | Evaluated -> "evaluated"

let string_of_artifact_type = function
  | Code lang -> Printf.sprintf "code(%s)" lang
  | Documentation -> "documentation"
  | Configuration -> "configuration"
  | Other s -> Printf.sprintf "other(%s)" s

let string_of_message msg =
  Printf.sprintf "Message{id=%s, speaker=%s, timestamp=%f}" msg.id
    (string_of_speaker msg.speaker) msg.timestamp

let string_of_artifact art =
  Printf.sprintf "Artifact{id=%s, type=%s, state=%s}" art.id
    (string_of_artifact_type art.artifact_type)
    (string_of_lifecycle_state art.current_state)

let string_of_conversation conv =
  let platform = Option.value ~default:"unknown" conv.platform in
  let artifacts =
    Option.value ~default:[] conv.artifacts |> List.length
  in
  Printf.sprintf
    "Conversation{id=%s, platform=%s, messages=%d, artifacts=%d}" conv.id
    platform
    (List.length conv.messages)
    artifacts

(* Utility functions *)

let get_message_by_id conv msg_id =
  List.find_opt (fun m -> String.equal m.id msg_id) conv.messages

let get_artifact_by_id conv art_id =
  match conv.artifacts with
  | None -> None
  | Some arts -> List.find_opt (fun a -> String.equal a.id art_id) arts

let get_messages_by_speaker conv speaker_pred =
  List.filter (fun m -> speaker_pred m.speaker) conv.messages

let get_llm_messages conv =
  get_messages_by_speaker conv (function LLM _ -> true | _ -> false)

let get_human_messages conv =
  get_messages_by_speaker conv (function Human _ -> true | _ -> false)

let get_artifacts_by_state conv state =
  match conv.artifacts with
  | None -> []
  | Some arts ->
      List.filter
        (fun a -> equal_lifecycle_state a.current_state state)
        arts

let get_created_artifacts conv = get_artifacts_by_state conv Created
let get_modified_artifacts conv = get_artifacts_by_state conv Modified
let get_removed_artifacts conv = get_artifacts_by_state conv Removed
let get_evaluated_artifacts conv = get_artifacts_by_state conv Evaluated

(* Metadata helpers *)

let get_metadata_value metadata key =
  match metadata with
  | None -> None
  | Some kvs -> List.assoc_opt key kvs

let set_metadata_value metadata key value =
  let kvs = Option.value ~default:[] metadata in
  Some ((key, value) :: List.filter (fun (k, _) -> k <> key) kvs)

(* Validation *)

let validate_conversation conv =
  let errors = ref [] in

  (* Check IDs are non-empty *)
  if String.equal conv.id "" then
    errors := "Conversation ID cannot be empty" :: !errors;

  (* Check message IDs are unique *)
  let msg_ids = List.map (fun m -> m.id) conv.messages in
  let unique_ids =
    List.sort_uniq String.compare msg_ids
  in
  if List.length msg_ids <> List.length unique_ids then
    errors := "Duplicate message IDs found" :: !errors;

  (* Check timestamps are non-negative *)
  if conv.timestamp < 0.0 then
    errors := "Conversation timestamp cannot be negative" :: !errors;

  List.iter
    (fun m ->
      if m.timestamp < 0.0 then
        errors :=
          Printf.sprintf "Message %s has negative timestamp" m.id :: !errors)
    conv.messages;

  (* Check artifact references *)
  (match conv.artifacts with
  | None -> ()
  | Some arts ->
      List.iter
        (fun art ->
          if String.equal art.id "" then
            errors := "Artifact ID cannot be empty" :: !errors;
          (* Check created_in references valid message *)
          if not (Option.is_some (get_message_by_id conv art.created_in)) then
            errors :=
              Printf.sprintf "Artifact %s: created_in references unknown message %s"
                art.id art.created_in
              :: !errors;
          (* Check modified_in references valid messages *)
          (match art.modified_in with
          | None -> ()
          | Some msg_ids ->
              List.iter
                (fun msg_id ->
                  if not (Option.is_some (get_message_by_id conv msg_id)) then
                    errors :=
                      Printf.sprintf
                        "Artifact %s: modified_in references unknown message %s"
                        art.id msg_id
                      :: !errors)
                msg_ids))
        arts);

  match !errors with
  | [] -> Ok conv
  | errs -> Error (String.concat "; " (List.rev errs))
