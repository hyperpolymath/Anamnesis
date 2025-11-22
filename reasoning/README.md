# Reasoning Component (λProlog/ELPI)

Meta-reasoning about conversation structure, artifact lifecycles, and cross-conversation relationships using higher-order logic programming.

## Purpose

Use λProlog's Higher-Order Abstract Syntax (HOAS) and meta-reasoning capabilities to:

- Track artifact lifecycle state machines
- Detect multi-category membership (fuzzy boundaries)
- Resolve cross-conversation fragment references
- Identify conversation contamination
- Support episodic memory queries

## Technology Stack

- **ELPI** 2.0.6+ - Embeddable λProlog interpreter (OCaml-based)
- **Teyjus** 2.1.1 (alternative standalone implementation)
- **OCaml** 5.0+ - For embedding ELPI

## Directory Structure

```
reasoning/
├── core/
│   ├── types.elpi              # Type definitions
│   ├── ontology.elpi           # RDF schema awareness (anamnesis: namespace)
│   └── utils.elpi              # Helper predicates (list ops, etc.)
├── lifecycle/
│   ├── artifact_states.elpi    # Artifact state machine
│   └── transitions.elpi        # Valid state transitions
├── categorization/
│   ├── fuzzy_membership.elpi   # Multi-category membership logic
│   └── contamination.elpi      # Cross-project contamination detection
├── linking/
│   ├── cross_conversation.elpi # Fragment reference resolution
│   └── reference_resolution.elpi # Transitive reference closure
├── episodic/
│   ├── memory_queries.elpi     # Episode recall by criteria
│   └── temporal_reasoning.elpi # Time-based inference
├── test/
│   ├── test_lifecycle.elpi
│   ├── test_contamination.elpi
│   └── fixtures/
│       └── sample_conversations.pl
├── elpi_interface.ml           # OCaml embedding code
├── reasoner_port.ml            # Port executable
├── dune
└── README.md                   # This file
```

## Key Concepts

### Higher-Order Abstract Syntax (HOAS)

λProlog uses the meta-language's binding mechanisms for object-language bindings. This makes representing conversation context natural:

```prolog
% Conversation with nested context
conversation C Msgs :-
    pi msg\ (
        within_context C msg =>
        process_messages Msgs
    ).

% References respect scope automatically
artifact_reference MsgID ArtifactID :-
    within_context C MsgID,
    created_in C ArtifactID.
```

### Hypothetical Reasoning

Use `=>` for assumptions:

```prolog
% What if we categorize this conversation differently?
test_recategorization Conv OldCat NewCat Impact :-
    belongs_to Conv OldCat primary,
    (belongs_to Conv NewCat primary => compute_impact Conv Impact).
```

### Typed Logic Programming

λProlog has static polymorphic typing:

```prolog
type conversation   -> type.
type message        -> type.
type artifact       -> type.
type state          -> type.

type belongs_to     conversation -> category -> membership_type -> prop.
type has_state      artifact -> state -> timestamp -> prop.
```

## Building

### Install ELPI (OCaml-based)

```bash
# Via OPAM
opam install elpi

# Or build from source
git clone https://github.com/LPCIC/elpi.git
cd elpi
make
make install
```

### Install Teyjus (Alternative)

```bash
# Download from https://teyjus.cs.umn.edu/
wget https://github.com/teyjus/teyjus/releases/download/v2.1.1/teyjus-2.1.1.tar.gz
tar xzf teyjus-2.1.1.tar.gz
cd teyjus-2.1.1
./configure
make
sudo make install
```

### Build Reasoner Port

```bash
cd reasoning
dune build
```

## Usage

### Standalone ELPI

```bash
# Interactive
elpi

# Load module
elpi -load lifecycle/artifact_states.elpi

# Query
?- current_state artifact_123 1732291200 State.
State = modified.
```

### Embedded in OCaml

```ocaml
(* elpi_interface.ml *)
open Elpi.API

let () =
  let elpi = Setup.init ~silent:false () in
  Setup.load_file elpi "lifecycle/artifact_states.elpi";

  let query = "current_state artifact_123 1732291200 State" in
  match Execute.once elpi query with
  | Execute.Success data ->
      let state = Data.to_string (Data.look elpi data "State") in
      Printf.printf "State: %s\n" state
  | Execute.Failure ->
      Printf.printf "No solution\n"
```

### Via Port from Elixir

```elixir
# In Elixir orchestrator
{:ok, state} = Anamnesis.Ports.LambdaPrologPort.query(
  "current_state artifact_123 1732291200 State"
)
```

## Core Modules

### Artifact Lifecycle Tracking

```prolog
% lifecycle/artifact_states.elpi

% State definitions
kind state type.
type created, modified, removed, evaluated state.

% Lifecycle event
type event state -> artifact_id -> timestamp -> prop.

% Valid state transitions
type valid_transition state -> state -> prop.
valid_transition created modified.
valid_transition created removed.
valid_transition modified modified.  % Can be modified multiple times
valid_transition modified evaluated.
valid_transition modified removed.
valid_transition evaluated removed.

% Get current state at timestamp T
type current_state artifact_id -> timestamp -> state -> prop.
current_state ArtID T State :-
    has_lifecycle ArtID Events,
    latest_event_before T Events (event State ArtID _).

% State machine validation
type validate_lifecycle artifact_id -> prop.
validate_lifecycle ArtID :-
    has_lifecycle ArtID Events,
    events_sorted_by_time Events SortedEvents,
    check_transitions SortedEvents.

type check_transitions list event -> prop.
check_transitions [].
check_transitions [_].
check_transitions [event S1 _ _, event S2 _ _ | Rest] :-
    valid_transition S1 S2,
    check_transitions [event S2 _ _ | Rest].
```

### Fuzzy Multi-Category Membership

```prolog
% categorization/fuzzy_membership.elpi

kind membership_type type.
type primary, secondary, tangential membership_type.

% Membership with strength
type belongs_to conversation -> category -> membership_type -> prop.
type membership_strength membership_type -> float -> prop.

membership_strength primary 1.0.
membership_strength secondary 0.6.
membership_strength tangential 0.3.

% Compute fuzzy membership score
type fuzzy_score conversation -> category -> float -> prop.
fuzzy_score Conv Cat Score :-
    belongs_to Conv Cat MType,
    membership_strength MType Score.

% Total membership (sum across categories)
type total_membership conversation -> float -> prop.
total_membership Conv Total :-
    findall Score (fuzzy_score Conv _ Score) Scores,
    sum_list Scores Total.

% Normalize memberships to sum to 1.0
type normalized_membership conversation -> category -> float -> prop.
normalized_membership Conv Cat NormScore :-
    fuzzy_score Conv Cat Score,
    total_membership Conv Total,
    Total > 0.0,
    NormScore is Score / Total.
```

### Contamination Detection

```prolog
% categorization/contamination.elpi

% Cross-project contamination: conversations sharing artifacts
type contaminates conversation -> conversation -> prop.
contaminates ConvA ConvB :-
    belongs_to ConvA CatA primary,
    belongs_to ConvB CatB primary,
    CatA \= CatB,
    discusses ConvA Art,
    discusses ConvB Art.

% Find all conversations contaminated by a given one
type contamination_spread conversation -> list conversation -> prop.
contamination_spread Conv Contaminated :-
    findall C (contaminates Conv C) Direct,
    mapM contamination_spread Direct Indirect,
    flatten Indirect IndirectList,
    append Direct IndirectList All,
    remove_duplicates All Contaminated.

% Contamination risk score (0.0 to 1.0)
type contamination_risk conversation -> float -> prop.
contamination_risk Conv Risk :-
    belongs_to Conv PrimaryProj primary,
    findall Cat (belongs_to Conv Cat _) AllCats,
    filter (\\c\\ c \= PrimaryProj) AllCats OtherCats,
    length OtherCats NumOther,
    length AllCats Total,
    Total > 0,
    Risk is NumOther / Total.
```

### Cross-Conversation Linking

```prolog
% linking/cross_conversation.elpi

% Fragment reference (message or artifact)
type fragment type.
type msg message -> fragment.
type art artifact -> fragment.

% Direct reference link
type link fragment -> reference_type -> fragment -> prop.

kind reference_type type.
type discusses, references, modifies, evaluates reference_type.

% Transitive closure
type linked fragment -> fragment -> prop.
linked F1 F2 :- link F1 _ F2.
linked F1 F3 :-
    link F1 _ F2,
    linked F2 F3.

% Find all fragments related to a given fragment
type find_related fragment -> list fragment -> prop.
find_related F Related :-
    findall G (link F _ G) Direct,
    findall H (link H _ F) Inverse,
    append Direct Inverse Related.

% Cross-conversation reference
type cross_conversation_ref fragment -> fragment -> conversation -> conversation -> prop.
cross_conversation_ref F1 F2 Conv1 Conv2 :-
    link F1 _ F2,
    in_conversation F1 Conv1,
    in_conversation F2 Conv2,
    Conv1 \= Conv2.
```

### Episodic Memory Queries

```prolog
% episodic/memory_queries.elpi

% Recall conversations by criteria
type recall_by query -> list conversation -> prop.

% Query types
kind query type.
type by_speaker string -> query.
type by_timerange timestamp -> timestamp -> query.
type by_project category -> query.
type by_artifact artifact_id -> query.
type by_keywords list string -> query.

% Recall implementations
recall_by (by_speaker Speaker) Convs :-
    findall C (has_speaker C Speaker) Convs.

recall_by (by_timerange Start End) Convs :-
    findall C (
        has_timestamp C T,
        T >= Start,
        T =< End
    ) Convs.

recall_by (by_project Proj) Convs :-
    findall C (belongs_to C Proj _) Convs.

recall_by (by_artifact ArtID) Convs :-
    findall C (discusses C ArtID) Convs.

% Recall by intersection of criteria
type recall_all list query -> list conversation -> prop.
recall_all [] AllConvs :- findall C (conversation C) AllConvs.
recall_all [Q] Convs :- recall_by Q Convs.
recall_all [Q1, Q2 | Rest] Convs :-
    recall_by Q1 C1,
    recall_all [Q2 | Rest] C2,
    intersection C1 C2 Convs.
```

## Testing

### Unit Tests (ELPI)

```prolog
% test/test_lifecycle.elpi
:- use_module lifecycle/artifact_states.

test "valid transition created to modified" :-
    valid_transition created modified.

test "invalid transition evaluated to created" :-
    not (valid_transition evaluated created).

test "current state with multiple events" :-
    has_lifecycle art1 [
        event created art1 1000,
        event modified art1 2000,
        event modified art1 3000
    ],
    current_state art1 2500 State,
    State = modified.

% Run tests
:- run_tests.
```

### Integration Tests (OCaml)

```ocaml
(* test/test_elpi_integration.ml *)
open Elpi.API

let test_artifact_lifecycle () =
  let elpi = Setup.init ~silent:true () in
  Setup.load_file elpi "lifecycle/artifact_states.elpi";
  Setup.load_file elpi "test/fixtures/sample_data.elpi";

  let query = "current_state artifact_123 1732291200 State" in
  match Execute.once elpi query with
  | Execute.Success data ->
      let state = Data.to_string (Data.look elpi data "State") in
      assert (state = "modified")
  | Execute.Failure ->
      failwith "Query failed"

let () =
  test_artifact_lifecycle ();
  print_endline "All tests passed"
```

## Integration with Elixir

### Port Interface

```ocaml
(* reasoner_port.ml *)
open Elpi.API

let main () =
  let elpi = Setup.init ~silent:true () in

  (* Load all modules *)
  List.iter (Setup.load_file elpi) [
    "core/types.elpi";
    "lifecycle/artifact_states.elpi";
    "categorization/fuzzy_membership.elpi";
    "categorization/contamination.elpi";
    "linking/cross_conversation.elpi";
    "episodic/memory_queries.elpi";
  ];

  (* Port communication loop *)
  while true do
    let len_bytes = really_input_string stdin 4 in
    let len = Int32.to_int (Bytes.get_int32_be (Bytes.of_string len_bytes) 0) in
    let request = really_input_string stdin len in

    let (query, context) = decode_request request in

    (* Execute query *)
    let result = match Execute.once elpi query with
      | Execute.Success data -> extract_bindings data
      | Execute.Failure -> `Error "no solution"
    in

    let response = encode_response result in
    let len = String.length response in
    output_bytes stdout (Bytes.create 4);
    output_string stdout response;
    flush stdout
  done

let () = main ()
```

## Performance

- **Tabling/Memoization**: ELPI supports tabled predicates for caching
- **Indexing**: First-argument indexing for fast clause selection
- **Incremental**: Can add facts without reloading entire database
- **Target**: <100ms for typical queries

## Troubleshooting

### "Predicate not found"

Ensure module is loaded:

```prolog
:- use_module "lifecycle/artifact_states.elpi".
```

### Stack Overflow

Limit recursion depth or use tabling:

```prolog
:- table linked/2.  % Memoize transitive closure
```

### Type Errors

Check type declarations:

```prolog
% Explicit typing helps debugging
type my_predicate artifact -> state -> prop.
```

## References

- [ELPI Documentation](https://lpcic.github.io/elpi/)
- [λProlog Tutorial](https://www.lix.polytechnique.fr/Labo/Dale.Miller/lProlog/)
- Miller & Nadathur (2012). _Programming with Higher-Order Logic_
- Research: `/docs/research/lambda-prolog-meta-reasoning.adoc`
- Architecture: `/docs/architecture/system-architecture.adoc`

## Next Steps

1. Implement core type definitions
2. Create artifact lifecycle module
3. Add contamination detection
4. Implement episodic memory queries
5. Test on proving-ground conversations
6. Integrate with OCaml/Elixir via port
