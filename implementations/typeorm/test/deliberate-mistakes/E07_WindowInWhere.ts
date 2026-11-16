// E07: Window Function in WHERE Clause
export interface WhereClause {
  predicate: boolean;
}

export function badWhere(): WhereClause {
  const windowRowNumber: number = 1;
  return { predicate: windowRowNumber };
}
