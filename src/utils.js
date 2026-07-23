// Small, pure functions so students have something meaningful to test
// and so SonarQube has real code (and coverage) to analyze.

function add(a, b) {
  return a + b;
}

function greet(name) {
  if (!name || typeof name !== 'string') {
    return 'Hello, guest!';
  }
  return `Hello, ${name}!`;
}

module.exports = { add, greet };
