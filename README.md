# Onushilon Backend - Quiz App Authentication API

A robust authentication system for a quiz application with role-based access control.

## Features

- User registration and login
- Role-based authentication (User, Moderator, Admin)
- JWT token-based authentication
- Password hashing with bcrypt
- Input validation
- MongoDB integration
- CORS enabled
- Request logging

## Roles

- **User**: Regular users who can take quizzes
- **Moderator**: Can manage quizzes and moderate content
- **Admin**: Full system access, can manage users and moderators

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile (protected)

### Admin Routes

- `GET /api/admin/users` - Get all users (Admin only)
- `PUT /api/admin/users/:id/role` - Update user role (Admin only)
- `DELETE /api/admin/users/:id` - Delete user (Admin only)

## Setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Configure environment variables in `.env`

3. Start MongoDB

4. Run the development server:
   ```bash
   npm run dev
   ```

## Environment Variables

- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `JWT_EXPIRE` - JWT token expiration time
- `PORT` - Server port
- `NODE_ENV` - Environment (development/production)
- `ADMIN_EMAIL` - Initial admin email
- `ADMIN_PASSWORD` - Initial admin password
