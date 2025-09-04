const request = require('supertest');
const app = require('../app');
const db = require('../database');

// Utility: Clear 'users' collection before each test (for isolation)
const clearUsers = async () => {
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();
  const promises = [];
  snapshot.forEach(doc => promises.push(usersRef.doc(doc.id).delete()));
  await Promise.all(promises);
};

// Utility: Register user for tests
const testEmail = 'parent@example.com';
const testPassword = 'test123';

beforeEach(async () => {
  await clearUsers();
});

describe('User Registration', () => {
  it('should register a new user', async () => {
    const response = await request(app).post('/users/register')
      .send({ email: testEmail, password: testPassword });
    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('id');
    expect(response.body.email).toBe(testEmail);
  });

  it('should not register existing user', async () => {
    await request(app).post('/users/register').send({ email: testEmail, password: testPassword });
    const res = await request(app).post('/users/register').send({ email: testEmail, password: testPassword });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error', 'User already exists');
  });
});

describe('User Login', () => {
  beforeEach(async () => {
    await request(app).post('/users/register').send({ email: testEmail, password: testPassword });
  });

  it('should log in a registered user', async () => {
    const response = await request(app).post('/users/login')
      .send({ email: testEmail, password: testPassword });
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('token');
  });

  it('should not log in with wrong password', async () => {
    const res = await request(app).post('/users/login')
      .send({ email: testEmail, password: 'wrongpass' });
    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('error', 'Invalid credentials');
  });
});

describe('Update Password', () => {
  let token, userId;
  beforeEach(async () => {
    const regRes = await request(app).post('/users/register').send({ email: testEmail, password: testPassword });
    userId = regRes.body.id;
    const loginRes = await request(app).post('/users/login').send({ email: testEmail, password: testPassword });
    token = loginRes.body.token;
  });

  it('should update user password', async () => {
    const newPassword = 'newPassword321';
    // /users/updatePassword expects authentication
    const response = await request(app).put('/users/updatePassword')
      .set('Authorization', `Bearer ${token}`)
      .send({ newPassword });
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('message', 'Password updated');

    // Try login with old password (should fail)
    const badLogin = await request(app).post('/users/login')
      .send({ email: testEmail, password: testPassword });
    expect(badLogin.status).toBe(400);

    // Try login with new password (should succeed)
    const goodLogin = await request(app).post('/users/login')
      .send({ email: testEmail, password: newPassword });
    expect(goodLogin.status).toBe(200);
    expect(goodLogin.body).toHaveProperty('token');
  });
});