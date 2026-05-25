-- Snowflake and Databricks keywords missing from the standard tree-sitter-sql grammar.
-- USE/DATABASE/SCHEMA are in the grammar but included here as a fallback for parse errors.
local kw = {
  -- Snowflake
  "USE", "DATABASE", "SCHEMA",
  "WAREHOUSE", "STAGE", "STREAM", "TASK", "PIPE",
  "QUALIFY", "CLONE", "UNDROP", "SHARE", "FLATTEN",
  "INTEGRATION", "SAMPLE", "PIVOT", "UNPIVOT",
  "COPY", "INTO", "PURGE", "VARIANT", "NETWORK", "FILE",
  "DYNAMIC", "ICEBERG", "SHOW", "LIST", "PUT", "GET",
  "RESUME", "SUSPEND", "MONITOR",
  -- Databricks
  "ZORDER", "RESTORE", "CLUSTER", "LIVE",
  "STREAMING", "APPLY", "EXPECT",
  "DBPROPERTIES", "MSCK", "REPAIR", "REFRESH", "GENERATE",
}
vim.fn.matchadd("@keyword", [[\c\<]] .. table.concat(kw, [[\>\|\c\<]]) .. [[\>]])
