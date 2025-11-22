(* Anamnesis Claude Conversation Parser
 * Parses Claude JSON export format to Generic Conversation
 *)

open Conversation_types_t

(* Parse Claude JSON *)

let parse_json json_string =
  try
    Ok (Conversation_types_j.claude_conversation_of_string json_string)
  with
  | Yojson.Json_error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)
  | Atdgen_runtime.Oj_run.Error (msg, _) ->
      Error (Printf.sprintf "JSON validation error: %s" msg)

(* Convert Claude format to Generic format *)

let claude_sender_to_speaker sender =
  match sender with
  | Human -> Generic_conversation.Human "user"
  | Assistant ->
      Generic_conversation.LLM
        { model = "claude"; provider = Some "anthropic" }

let claude_message_to_message (msg : claude_message) : message =
  {
    id = msg.uuid;
    speaker = claude_sender_to_speaker msg.sender;
    content = msg.text;
    timestamp = Ptime.of_rfc3339 msg.created_at |> Result.get_ok |> Ptime.to_float_s;
    references = None;
    metadata = None;
  }

let detect_artifact_in_content content =
  (* Simple heuristic: detect code blocks *)
  let code_fence_re = Re.Perl.compile_pat "```([a-z]+)?\n([^`]+)```" in
  match Re.exec_opt code_fence_re content with
  | None -> None
  | Some groups ->
      let language =
        try Some (Re.Group.get groups 1) with Not_found -> None
      in
      let code = Re.Group.get groups 2 in
      Some (language, code)

let extract_artifacts_from_messages (msgs : claude_message list) :
    artifact list =
  let artifact_id_counter = ref 0 in
  List.filter_map
    (fun (msg : claude_message) ->
      match detect_artifact_in_content msg.text with
      | None -> None
      | Some (lang_opt, code) ->
          incr artifact_id_counter;
          let lang = Option.value ~default:"unknown" lang_opt in
          let artifact_id =
            Printf.sprintf "artifact-%s-%d" msg.uuid !artifact_id_counter
          in
          Some
            {
              id = artifact_id;
              name = None;
              artifact_type = Code lang;
              content = code;
              created_in = msg.uuid;
              modified_in = None;
              current_state = Created;
              language = Some lang;
              metadata = None;
            })
    msgs

let claude_to_generic (claude : claude_conversation) : conversation =
  let messages = List.map claude_message_to_message claude.chat_messages in
  let artifacts = extract_artifacts_from_messages claude.chat_messages in
  {
    id = claude.uuid;
    platform = Some "claude";
    timestamp =
      Ptime.of_rfc3339 claude.created_at |> Result.get_ok |> Ptime.to_float_s;
    messages;
    artifacts = (if List.length artifacts > 0 then Some artifacts else None);
    metadata = Some [ ("name", claude.name) ];
  }

(* Format detection *)

let detect json_string =
  try
    let json = Yojson.Safe.from_string json_string in
    match Yojson.Safe.Util.member "uuid" json with
    | `String _ -> (
        match Yojson.Safe.Util.member "chat_messages" json with
        | `List _ -> true
        | _ -> false)
    | _ -> false
  with _ -> false

(* Main parse function *)

let parse json_string =
  match parse_json json_string with
  | Error e -> Error e
  | Ok claude_conv -> (
      let generic = claude_to_generic claude_conv in
      match Generic_conversation.validate_conversation generic with
      | Ok _ -> Ok generic
      | Error e ->
          Error (Printf.sprintf "Validation failed after parsing: %s" e))

(* Module conforming to ConversationFormat signature *)

module ClaudeFormat : sig
  val detect : string -> bool
  val parse : string -> (conversation, string) result
  val validate : conversation -> bool
end = struct
  let detect = detect
  let parse = parse

  let validate conv =
    match Generic_conversation.validate_conversation conv with
    | Ok _ -> true
    | Error _ -> false
end
