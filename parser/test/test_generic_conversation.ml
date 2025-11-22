open Anamnesis_parser

let test_validate_conversation_valid () =
  let open Generic_conversation in
  let valid_conv = {
    id = "test-conv-001";
    platform = Some "Claude";
    timestamp = 1732147200.0;
    messages = [
      {
        id = "msg-1";
        role = User;
        content = "Hello";
        timestamp = 1732147200.0;
        artifacts = None;
      };
      {
        id = "msg-2";
        role = Assistant;
        content = "Hi there!";
        timestamp = 1732147210.0;
        artifacts = None;
      };
    ];
    artifacts = None;
  } in
  match validate_conversation valid_conv with
  | Ok _ -> ()
  | Error msg -> Alcotest.failf "Expected valid conversation, got error: %s" msg

let test_validate_conversation_empty_id () =
  let open Generic_conversation in
  let invalid_conv = {
    id = "";
    platform = None;
    timestamp = 1732147200.0;
    messages = [];
    artifacts = None;
  } in
  match validate_conversation invalid_conv with
  | Ok _ -> Alcotest.fail "Expected validation error for empty ID"
  | Error msg ->
      Alcotest.(check bool) "Error mentions ID" true (String.contains msg 'I')

let test_validate_conversation_duplicate_message_ids () =
  let open Generic_conversation in
  let conv_with_dupes = {
    id = "test-conv-002";
    platform = Some "ChatGPT";
    timestamp = 1732147200.0;
    messages = [
      {
        id = "msg-1";
        role = User;
        content = "First";
        timestamp = 1732147200.0;
        artifacts = None;
      };
      {
        id = "msg-1";  (* Duplicate ID *)
        role = Assistant;
        content = "Second";
        timestamp = 1732147210.0;
        artifacts = None;
      };
    ];
    artifacts = None;
  } in
  match validate_conversation conv_with_dupes with
  | Ok _ -> Alcotest.fail "Expected validation error for duplicate message IDs"
  | Error msg ->
      Alcotest.(check bool) "Error mentions duplicate" true
        (String.contains msg 'd' || String.contains msg 'D')

let test_normalize_conversation () =
  let open Generic_conversation in
  let conv = {
    id = "test-conv-003";
    platform = Some "Mistral";
    timestamp = 1732147200.0;
    messages = [
      {
        id = "msg-1";
        role = User;
        content = "Test message";
        timestamp = 1732147200.0;
        artifacts = Some [
          {
            id = "art-1";
            artifact_type = Code;
            title = Some "test.ml";
            content = "let x = 1";
            language = Some "ocaml";
            lifecycle_state = Created;
          };
        ];
      };
    ];
    artifacts = Some [
      {
        id = "art-1";
        artifact_type = Code;
        title = Some "test.ml";
        content = "let x = 1";
        language = Some "ocaml";
        lifecycle_state = Created;
      };
    ];
  } in
  let normalized = normalize_artifacts conv in
  match normalized.artifacts with
  | Some arts ->
      Alcotest.(check int) "One unique artifact" 1 (List.length arts);
      let art = List.hd arts in
      Alcotest.(check string) "Artifact ID" "art-1" art.id
  | None -> Alcotest.fail "Expected artifacts in normalized conversation"

let test_extract_all_artifacts () =
  let open Generic_conversation in
  let conv = {
    id = "test-conv-004";
    platform = Some "Claude";
    timestamp = 1732147200.0;
    messages = [
      {
        id = "msg-1";
        role = User;
        content = "Create a function";
        timestamp = 1732147200.0;
        artifacts = Some [
          {
            id = "art-1";
            artifact_type = Code;
            title = Some "func.ml";
            content = "let f x = x + 1";
            language = Some "ocaml";
            lifecycle_state = Created;
          };
        ];
      };
      {
        id = "msg-2";
        role = Assistant;
        content = "Here's the doc";
        timestamp = 1732147210.0;
        artifacts = Some [
          {
            id = "art-2";
            artifact_type = Document;
            title = Some "README.md";
            content = "# Documentation";
            language = None;
            lifecycle_state = Created;
          };
        ];
      };
    ];
    artifacts = None;
  } in
  let all_artifacts = extract_all_artifacts conv in
  Alcotest.(check int) "Two artifacts extracted" 2 (List.length all_artifacts);
  let ids = List.map (fun a -> a.id) all_artifacts |> List.sort String.compare in
  Alcotest.(check (list string)) "Artifact IDs" ["art-1"; "art-2"] ids

let test_find_artifact_by_id () =
  let open Generic_conversation in
  let art1 = {
    id = "art-1";
    artifact_type = Code;
    title = Some "test.ml";
    content = "let x = 1";
    language = Some "ocaml";
    lifecycle_state = Created;
  } in
  let conv = {
    id = "test-conv-005";
    platform = Some "Claude";
    timestamp = 1732147200.0;
    messages = [];
    artifacts = Some [art1];
  } in
  match find_artifact_by_id conv "art-1" with
  | Some art -> Alcotest.(check string) "Found artifact" "art-1" art.id
  | None -> Alcotest.fail "Expected to find artifact art-1"

let test_count_messages_by_role () =
  let open Generic_conversation in
  let conv = {
    id = "test-conv-006";
    platform = Some "ChatGPT";
    timestamp = 1732147200.0;
    messages = [
      { id = "msg-1"; role = User; content = "Q1"; timestamp = 1732147200.0; artifacts = None; };
      { id = "msg-2"; role = Assistant; content = "A1"; timestamp = 1732147210.0; artifacts = None; };
      { id = "msg-3"; role = User; content = "Q2"; timestamp = 1732147220.0; artifacts = None; };
      { id = "msg-4"; role = Assistant; content = "A2"; timestamp = 1732147230.0; artifacts = None; };
      { id = "msg-5"; role = User; content = "Q3"; timestamp = 1732147240.0; artifacts = None; };
    ];
    artifacts = None;
  } in
  let (user_count, assistant_count) = count_messages_by_role conv in
  Alcotest.(check int) "User messages" 3 user_count;
  Alcotest.(check int) "Assistant messages" 2 assistant_count

let () =
  let open Alcotest in
  run "Generic_conversation" [
    "validation", [
      test_case "Valid conversation" `Quick test_validate_conversation_valid;
      test_case "Empty ID fails" `Quick test_validate_conversation_empty_id;
      test_case "Duplicate message IDs fail" `Quick test_validate_conversation_duplicate_message_ids;
    ];
    "normalization", [
      test_case "Normalize artifacts" `Quick test_normalize_conversation;
    ];
    "extraction", [
      test_case "Extract all artifacts" `Quick test_extract_all_artifacts;
      test_case "Find artifact by ID" `Quick test_find_artifact_by_id;
    ];
    "counting", [
      test_case "Count messages by role" `Quick test_count_messages_by_role;
    ];
  ]
