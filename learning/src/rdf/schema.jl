# Anamnesis RDF Schema Constants
# Vocabulary URIs for the Anamnesis ontology

module Schema

export ANAMNESIS, RDF, RDFS, XSD

# Namespace structs
struct Namespace
    base::String
end

Base.getindex(ns::Namespace, sym::Symbol) = string(ns.base, sym)
Base.getproperty(ns::Namespace, sym::Symbol) = string(ns.base, sym)

# Standard namespaces
const RDF = Namespace("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
const RDFS = Namespace("http://www.w3.org/2000/01/rdf-schema#")
const XSD = Namespace("http://www.w3.org/2001/XMLSchema#")

# Anamnesis namespace
const ANAMNESIS = Namespace("http://anamnesis.hyperpolymath.org/ns#")

# Common RDF predicates
const TYPE = RDF[:type]
const LABEL = RDFS[:label]
const COMMENT = RDFS[:comment]

# Anamnesis Classes
const CONVERSATION = ANAMNESIS[:Conversation]
const MESSAGE = ANAMNESIS[:Message]
const ARTIFACT = ANAMNESIS[:Artifact]
const LIFECYCLE_EVENT = ANAMNESIS[:LifecycleEvent]
const PROJECT = ANAMNESIS[:Project]
const SPEAKER = ANAMNESIS[:Speaker]
const STATE = ANAMNESIS[:State]

# Anamnesis Properties
const CONTAINS = ANAMNESIS[:contains]
const PART_OF = ANAMNESIS[:partOf]
const DISCUSSES = ANAMNESIS[:discusses]
const SPEAKER_PROP = ANAMNESIS[:speaker]
const CONTENT = ANAMNESIS[:content]
const TIMESTAMP = ANAMNESIS[:timestamp]
const CREATED_IN = ANAMNESIS[:createdIn]
const MODIFIED_IN = ANAMNESIS[:modifiedIn]
const STATE_PROP = ANAMNESIS[:state]
const HAS_LIFECYCLE = ANAMNESIS[:hasLifecycle]
const BELONGS_TO = ANAMNESIS[:belongsTo]
const MEMBERSHIP_STRENGTH = ANAMNESIS[:membershipStrength]
const REFERENCES = ANAMNESIS[:references]

# States
const STATE_CREATED = ANAMNESIS[:StateCreated]
const STATE_MODIFIED = ANAMNESIS[:StateModified]
const STATE_REMOVED = ANAMNESIS[:StateRemoved]
const STATE_EVALUATED = ANAMNESIS[:StateEvaluated]

end # module Schema
