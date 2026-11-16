# E08: Dangling or Unbound Table Reference
unbound_table = None
if unbound_table is None:
    raise NameError("Dangling table reference: unjoined table 'unbound_airport' is not bound in query from-clause")
