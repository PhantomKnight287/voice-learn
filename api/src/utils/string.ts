export function removePunctuation(input: string): string {
  // Define a regular expression that matches punctuation characters
  const punctuation = /[!"#\$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~]/g;

  // Use the replace method to remove all matched characters
  return input.replace(punctuation, '');
}
