# The Deliberate Mistake Suite (Compiler Error UX Benchmark)

This suite consists of **10 intentional semantic and type errors** commonly made during database development. It evaluates the developer ergonomics of statically-typed ORMs by measuring how the compiler reports mistakes.

---

## Evaluation Metrics

For each test case **E01 through E10**, run the compiler (e.g., `ghc -fno-diagnostics-show-caret` or `tsc --noEmit` or `cargo check`) and record:
1. **Error Line Count**: The total number of diagnostic lines emitted for the mistake. Concise diagnostics ($\le 10$ lines) score higher than voluminous tracebacks ($50+$ lines).
2. **Zero Internal Type Leakage**:
   - **PASS**: The error message mentions strictly the user's domain types (e.g., `Flight`, `Passenger`, `Text`, `Int`, `Maybe`).
   - **FAIL**: The error leaks framework-internal plumbing, type families, or typeclass mechanics (e.g., `Default Unpackspec`, `QGenExpr`, `SqlVal`, `Rel8able`, `TableSchema`, `PersistEntity`, `FieldDef`).

---

## The 10 Deliberate Mistake Scenarios

### E01: Type Mismatch in Equality Comparison
- **Bug**: Comparing an optional field `Maybe Text` (e.g., `f.actual_departure_status`) directly to a bare `Text` literal without wrapping in `Just` / handling nullability.
- **Expected Diagnostic**: Clear message stating that `Maybe Text` cannot be compared to `Text` without unpacking or using a nullable comparison operator.
- **Ideal Diagnostic (Hylo Style)**:
  ```text
  • Couldn't match expected type 'Text' with actual type 'Maybe Text'
    In the column comparison: flight.status == "On Time"
  ```
- **Internal Plumbing to Detect**: Leaks of `Default (Expr ...)` or nested constraint solver tracebacks.

---

### E02: Foreign Key Type Mismatch in Join Condition
- **Bug**: Joining two unrelated tables using mismatched key types—specifically equating `flight.flight_id` (a `FlightId`) with `passenger.passenger_id` (a `PassengerId`).
- **Expected Diagnostic**: Clear mismatch between `FlightId` and `PassengerId`.
- **Ideal Diagnostic**:
  ```text
  • Couldn't match type 'FlightId' with 'PassengerId'
    In join condition: flight.flight_id == passenger.passenger_id
  ```
- **Internal Plumbing to Detect**: `HasDefaultExpr`, `SqlType`, `FieldEquality`, `Rel8.Column`.

---

### E03: Missing Column in GROUP BY (Ungrouped Column in Projection)
- **Bug**: Projecting a raw, non-aggregated column (e.g., `flight.departure_airport`) while performing an aggregate query (`count(*)`) without including that column in the `GROUP BY` clause.
- **Expected Diagnostic**: Rejection at compile-time indicating that `departure_airport` is not an aggregate or part of the grouping keys.
- **Ideal Diagnostic**:
  ```text
  • Column 'departure_airport' must appear in GROUP BY clause or be used in an aggregate function
  ```
- **Internal Plumbing to Detect**: Leaks of `Aggregates`, `GroupByCols`, `QGenExpr`.

---

### E04: IO / Side-Effect Escape inside Pure Query/Transaction Monad
- **Bug**: Attempting to invoke an arbitrary `IO` action (such as `getCurrentTime` or `putStrLn`) directly inside a pure query builder comprehension or transaction monad without using the sanctioned lifting mechanism.
- **Expected Diagnostic**: Type mismatch showing `IO` cannot unify with `Query` or `Transaction`.
- **Ideal Diagnostic**:
  ```text
  • No instance for (MonadIO Query) arising from a use of 'putStrLn'
  ```

---

### E05: Nullability Violation on Non-Nullable Column
- **Bug**: Attempting to insert `Nothing` / `null` into a column defined in the database schema as `NOT NULL` (e.g. `airport.airport_name`).
- **Expected Diagnostic**: Immediate rejection that `Maybe a` cannot be assigned to non-nullable field `Text`.
- **Ideal Diagnostic**:
  ```text
  • Cannot assign 'Nothing' to non-nullable column 'airport_name'
  ```

---

### E06: Non-Existent Column Selection (Field Typo)
- **Bug**: Selecting a non-existent field from a table (e.g., `flight.flight_noo` instead of `flight.flight_no`).
- **Expected Diagnostic**: Field not in record or schema.
- **Ideal Diagnostic**:
  ```text
  • Record field 'flight_noo' does not exist in table 'Flight'
  ```

---

### E07: Window Function inside WHERE Clause
- **Bug**: Using a window function (e.g., `row_number()`) directly in the `WHERE` filter rather than inside a CTE or subquery.
- **Expected Diagnostic**: Statically preventing window expressions in the boolean filter position.
- **Ideal Diagnostic**:
  ```text
  • Window functions cannot be used in a WHERE clause
  ```

---

### E08: Dangling or Unbound Table Reference
- **Bug**: Referencing an alias or projected variable from a separate query scope that is not joined or in scope.
- **Expected Diagnostic**: Variable not in scope.

---

### E09: Mutating Immutable Primary Key in Changeset
- **Bug**: Attempting to modify `flight_id` or `account_id` within an update changeset.
- **Expected Diagnostic**: Primary key columns are read-only / immutable during partial updates.

---

### E10: Inner Query Scope Leakage
- **Bug**: Projecting a subquery with private aliases and attempting to reference an unexported inner column in the outer query expression.
- **Expected Diagnostic**: Unbound column in outer projection.

---

## Automation Script

The Deliberate Mistake Suite is tested by running:
```bash
python3 bench/runner/test_mistakes.py --orm <orm_name>
```
Which compiles each erroneous file `E01` through `E10` individually, captures `stderr`, counts lines, checks for internal leakage keywords, and logs results into `bench/results/<orm>.json`.
