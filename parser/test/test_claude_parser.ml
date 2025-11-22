open Anamnesis_parser

let sample_claude_json = {|
{
  "uuid": "test-conversation-uuid-001",
  "name": "Test Conversation",
  "created_at": "2025-11-22T10:00:00.000Z",
  "updated_at": "2025-11-22T10:05:00.000Z",
  "chat_messages": [
    {
      "uuid": "msg-1",
      "text": "Hello, please help me with OCaml",
      "sender": "human",
      "created_at": "2025-11-22T10:00:00.000Z"
    },
    {
      "uuid": "msg-2",
      "text": "I'd be happy to help with OCaml!",
      "sender": "assistant",
      "created_at": "2025-11-22T10:01:00.000Z"
    }
  ]
}
|}

let invalid_json = {|
{
  "not_a_conversation": true,
  "random_field": "value"
}
|}

let non_json_string = "This is not JSON at all!"

let test_detect_valid_claude_json () =
  let result = Claude_parser.detect sample_claude_json in
  Alcotest.(check bool) "Detects valid Claude JSON" true result

let test_detect_invalid_json () =
  let result = Claude_parser.detect invalid_json in
  Alcotest.(check bool) "Rejects invalid JSON structure" false result

let test_detect_non_json () =
  let result = Claude_parser.detect non_json_string in
  Alcotest.(check bool) "Rejects non-JSON string" false result

let test_parse_valid_claude_json () =
  match Claude_parser.parse sample_claude_json with
  | Ok conv ->
      let open Generic_conversation in
      Alcotest.(check string) "Conversation ID" "test-conversation-uuid-001" conv.id;
      Alcotest.(check (option string)) "Platform" (Some "Claude") conv.platform;
      Alcotest.(check int) "Message count" 2 (List.length conv.messages);
      let first_msg = List.hd conv.messages in
      Alcotest.(check string) "First message ID" "msg-1" first_msg.id;
      Alcotest.(check bool) "First message is User" true (first_msg.role = User)
  | Error msg ->
      Alcotest.failf "Expected successful parse, got error: %s" msg

let test_parse_invalid_json () =
  match Claude_parser.parse invalid_json with
  | Ok _ -> Alcotest.fail "Expected parse error for invalid JSON"
  | Error msg ->
      Alcotest.(check bool) "Error message not empty" true (String.length msg > 0)

let test_extract_artifacts_from_claude_message () =
  let claude_json_with_artifacts = {|
{
  "uuid": "conv-with-artifacts",
  "name": "Artifact Test",
  "created_at": "2025-11-22T10:00:00.000Z",
  "updated_at": "2025-11-22T10:05:00.000Z",
  "chat_messages": [
    {
      "uuid": "msg-with-art",
      "text": "Here's the code",
      "sender": "assistant",
      "created_at": "2025-11-22T10:00:00.000Z",
      "attachments": [
        {
          "id": "art-1",
          "type": "code",
          "title": "example.ml",
          "content": "let hello () = print_endline \"Hello\"",
          "language": "ocaml"
        }
      ]
    }
  ]
}
|} in
  match Claude_parser.parse claude_json_with_artifacts with
  | Ok conv ->
      let open Generic_conversation in
      let all_artifacts = extract_all_artifacts conv in
      Alcotest.(check bool) "Has artifacts" true (List.length all_artifacts > 0)
  | Error msg ->
      Alcotest.failf "Parse failed: %s" msg

let test_timestamp_parsing () =
  (* Test that ISO 8601 timestamps are converted to Unix floats correctly *)
  match Claude_parser.parse sample_claude_json with
  | Ok conv ->
      let open Generic_conversation in
      (* Timestamp should be positive Unix time *)
      Alcotest.(check bool) "Timestamp is positive" true (conv.timestamp > 0.0);
      (* Messages should have increasing timestamps *)
      let msg1_ts = (List.nth conv.messages 0).timestamp in
      let msg2_ts = (List.nth conv.messages 1).timestamp in
      Alcotest.(check bool) "Messages chronologically ordered" true (msg2_ts > msg1_ts)
  | Error msg ->
      Alcotest.failf "Parse failed: %s" msg

let () =
  let open Alcotest in
  run "Claude_parser" [
    "detection", [
      test_case "Detect valid Claude JSON" `Quick test_detect_valid_claude_json;
      test_case "Reject invalid JSON structure" `Quick test_detect_invalid_json;
      test_case "Reject non-JSON string" `Quick test_detect_non_json;
    ];
    "parsing", [
      test_case "Parse valid Claude JSON" `Quick test_parse_valid_claude_json;
      test_case "Handle invalid JSON" `Quick test_parse_invalid_json;
      test_case "Extract artifacts" `Quick test_extract_artifacts_from_claude_message;
      test_case "Parse timestamps correctly" `Quick test_timestamp_parsing;
    ];
  ]
