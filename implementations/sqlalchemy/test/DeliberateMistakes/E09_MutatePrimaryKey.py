# E09: Mutation of Immutable Primary Key in Changeset
from types import MappingProxyType
changeset = MappingProxyType({"flight_id": 101})
changeset["flight_id"] = 999
