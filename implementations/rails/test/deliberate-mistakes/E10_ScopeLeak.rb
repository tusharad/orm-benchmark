# E10: Inner Query Scope Leakage
def run_query
  inner_scope = "inner"
end
puts inner_scope
