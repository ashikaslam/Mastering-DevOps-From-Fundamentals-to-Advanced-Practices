const request = require('supertest');
const app = require('../src/app');

describe('GET /', () => {
  it('should return HTTP 200', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
  });
});