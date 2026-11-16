// E10: Inner Query Scope Leakage
export function badScope() {
  {
    const innerSubquery = "inner_table_subquery";
  }
  return innerSubquery;
}
