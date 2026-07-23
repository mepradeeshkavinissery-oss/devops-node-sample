const request = require('supertest');
const app = require('../src/server');
const { add, greet } = require('../src/utils');

describe('utils', () => {
  test('add sums two numbers', () => {
    expect(add(2, 3)).toBe(5);
    expect(add(-1, 1)).toBe(0);
  });

  test('greet returns a personalised message', () => {
    expect(greet('Asha')).toBe('Hello, Asha!');
  });

  test('greet falls back for invalid input', () => {
    expect(greet('')).toBe('Hello, guest!');
    expect(greet(null)).toBe('Hello, guest!');
  });
});

describe('routes', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET / returns a greeting payload', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.message).toContain('Hello');
  });

  test('GET /api/add adds query params', async () => {
    const res = await request(app).get('/api/add?a=4&b=6');
    expect(res.statusCode).toBe(200);
    expect(res.body.result).toBe(10);
  });

  test('GET /api/add rejects non-numbers', async () => {
    const res = await request(app).get('/api/add?a=foo&b=2');
    expect(res.statusCode).toBe(400);
  });
});
