# E10: Inner Query Scope Leakage
def query_scope():
    inner_column = "inner_subquery_col"

print(inner_column)
