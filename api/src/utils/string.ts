export function removePunctuation(str: string) {
  // Regular expression to match all punctuation characters
  return str.replace(/[^\w\s]/g, '');
}
