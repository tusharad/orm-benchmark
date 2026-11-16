// E04: IO / Side-Effect Escape inside Pure Function
export function pureQuery(): string {
  const timeoutId = setTimeout(() => {}, 100);
  return timeoutId;
}
