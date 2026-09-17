set search_path to blackboxdb_core;

-- show all functions exported in blackboxdb_core.
\df blackboxdb_core.*

-- show all aggregates exported
\da+ blackboxdb_core.*

-- Access methods + Operator families
\dA *blackboxdb*

\dAc * *blackboxdb*

\dAf * *blackboxdb*

\dX *blackboxdb*

-- This is last (Tables/indexes)
\d blackboxdb_core.*
