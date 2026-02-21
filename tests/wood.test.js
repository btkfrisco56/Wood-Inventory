const request = require('supertest');
const path = require('path');
const fs = require('fs');

// Use a separate test database
process.env.DB_PATH = path.join(__dirname, 'test.db');

// Remove stale test DB before running
if (fs.existsSync(process.env.DB_PATH)) fs.unlinkSync(process.env.DB_PATH);

const app = require('../app');

afterAll(() => {
  if (fs.existsSync(process.env.DB_PATH)) fs.unlinkSync(process.env.DB_PATH);
});

describe('Wood Inventory API', () => {
  let createdId;

  test('GET /api/wood returns empty array initially', async () => {
    const res = await request(app).get('/api/wood');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test('POST /api/wood creates a record', async () => {
    const res = await request(app)
      .post('/api/wood')
      .field('species', 'White Oak')
      .field('width', '6')
      .field('thickness', '1.5')
      .field('length', '96')
      .field('quantity', '3')
      .field('condition', 'Kiln Dried')
      .field('source', 'Local mill')
      .field('notes', 'Beautiful ray fleck');

    expect(res.status).toBe(201);
    expect(res.body.species).toBe('White Oak');
    expect(res.body.quantity).toBe(3);
    expect(res.body.condition).toBe('Kiln Dried');
    createdId = res.body.id;
  });

  test('POST /api/wood rejects missing species', async () => {
    const res = await request(app)
      .post('/api/wood')
      .field('quantity', '1');
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/species/i);
  });

  test('GET /api/wood returns created record', async () => {
    const res = await request(app).get('/api/wood');
    expect(res.status).toBe(200);
    expect(res.body.length).toBe(1);
    expect(res.body[0].species).toBe('White Oak');
  });

  test('GET /api/wood/:id returns single record', async () => {
    const res = await request(app).get(`/api/wood/${createdId}`);
    expect(res.status).toBe(200);
    expect(res.body.id).toBe(createdId);
  });

  test('GET /api/wood/:id returns 404 for unknown id', async () => {
    const res = await request(app).get('/api/wood/9999');
    expect(res.status).toBe(404);
  });

  test('PUT /api/wood/:id updates a record', async () => {
    const res = await request(app)
      .put(`/api/wood/${createdId}`)
      .field('species', 'White Oak')
      .field('quantity', '5')
      .field('notes', 'Updated notes');
    expect(res.status).toBe(200);
    expect(res.body.quantity).toBe(5);
    expect(res.body.notes).toBe('Updated notes');
  });

  test('PUT /api/wood/:id returns 404 for unknown id', async () => {
    const res = await request(app)
      .put('/api/wood/9999')
      .field('species', 'Maple');
    expect(res.status).toBe(404);
  });

  test('DELETE /api/wood/:id deletes a record', async () => {
    const res = await request(app).delete(`/api/wood/${createdId}`);
    expect(res.status).toBe(204);
  });

  test('GET /api/wood returns empty after deletion', async () => {
    const res = await request(app).get('/api/wood');
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  test('DELETE /api/wood/:id returns 404 for unknown id', async () => {
    const res = await request(app).delete('/api/wood/9999');
    expect(res.status).toBe(404);
  });
});
