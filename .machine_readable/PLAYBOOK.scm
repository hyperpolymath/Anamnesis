;; SPDX-License-Identifier: AGPL-3.0-or-later
;; PLAYBOOK.scm - Operational runbook for anamnesis

(define playbook
  `((version . "1.0.0")
    (procedures
      ((build
         (parser . "cd parser && dune build")
         (orchestrator . "cd orchestrator && mix deps.get && mix compile")
         (learning . "cd learning && julia --project=. -e 'using Pkg; Pkg.instantiate()'")
         (visualization . "cd visualization && npm install && npm run res:build")
         (all . "just build"))
       (test
         (parser . "cd parser && dune runtest")
         (orchestrator . "cd orchestrator && mix test")
         (learning . "cd learning && julia --project=. test/runtests.jl")
         (visualization . "cd visualization && npm test")
         (all . "just test"))
       (deploy
         (virtuoso . "docker run -d -p 8890:8890 -e DBA_PASSWORD=anamnesis --name virtuoso openlink/virtuoso-opensource-7")
         (orchestrator . "cd orchestrator && MIX_ENV=prod mix phx.server"))
       (rollback
         (stop-services . "docker stop virtuoso && pkill -f 'mix phx.server'")
         (restore-db . "docker exec virtuoso isql-v 'EXEC=checkpoint;'"))
       (debug
         (check-ports . "lsof -i :4000 -i :8890 -i :1111")
         (parser-logs . "cd parser && dune exec -- ./bin/parser_port.exe --help")
         (elixir-console . "cd orchestrator && iex -S mix")
         (julia-repl . "cd learning && julia --project=."))))
    (alerts
      ((virtuoso-down . "docker ps | grep virtuoso || echo 'Virtuoso not running'")
       (port-crashed . "Check orchestrator logs for port exit status")))
    (contacts
      ((maintainer . "hyperpolymath")
       (repository . "https://github.com/hyperpolymath/anamnesis")))))
