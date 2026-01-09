;; SPDX-License-Identifier: AGPL-3.0-or-later
;; NEUROSYM.scm - Neurosymbolic integration config for anamnesis

(define neurosym-config
  `((version . "1.0.0")
    (symbolic-layer
      ((type . "lambda-prolog")
       (implementation . "ELPI")
       (reasoning . ("deductive" "hypothetical" "meta-level"))
       (verification . "type-checked")
       (capabilities
         ("Higher-order abstract syntax (HOAS)")
         ("Typed logic programming")
         ("Hypothetical reasoning with =>")
         ("Tabled predicates for memoization"))))
    (neural-layer
      ((embeddings . #t)
       (type . "reservoir-computing")
       (implementation . "ReservoirComputing.jl")
       (fine-tuning . #f)
       (capabilities
         ("Echo State Networks (ESN)")
         ("Graph embeddings via spectral features")
         ("Knowledge-Augmented Neural Networks (KBANN)")
         ("Conversation sequence prediction"))))
    (integration
      ((symbolic-to-neural
         ("Rule structure → Network topology (KBANN)")
         ("RDF triples → Graph embeddings")
         ("Category membership → Supervision signal"))
       (neural-to-symbolic
         ("Embeddings → Similarity for linking")
         ("Predictions → Candidate hypotheses for λProlog")
         ("Clustering → Category suggestions"))
       (hybrid-queries
         ("SPARQL for structured retrieval")
         ("λProlog for reasoning over results")
         ("ESN for similarity-based expansion"))))))
