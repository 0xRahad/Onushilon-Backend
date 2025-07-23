# Onushilon Backend - Quiz App Authentication API

A robust authentication system for a quiz application with role-based access control and comprehensive manual validation.

## Features

- **User registration and login** with comprehensive validation
- **Role-based authentication** (User, Moderator, Admin)
- **JWT token-based authentication** with secure middleware
- **Password hashing** with bcrypt (salt rounds: 12)
- **Manual input validation** system (no external dependencies)
- **Input sanitization** and security middleware
- **MongoDB integration** with Mongoose
- **CORS enabled** for cross-origin requests
- **Request logging** with Morgan
- **NoSQL injection prevention**
- **Rate limiting ready** architecture

## Manual Validation System

This project uses a custom **manual validation system** instead of express-validator, providing:

- ✅ **Zero external dependencies** for validation
- ✅ **Full control** over validation logic
- ✅ **Better performance** (no middleware overhead)
- ✅ **Reusable validation utilities**
- ✅ **Consistent error handling**
- ✅ **Input sanitization** built-in

### Validation Features

| Component       | Validation Rules                     |
| --------------- | ------------------------------------ |
| **Email**       | Valid format, required for auth      |
| **Password**    | Min 6 characters, required           |
| **Phone**       | Min 10 digits, supports formatting   |
| **Age**         | Range 13-120 years                   |
| **Name**        | Min 2 characters after trimming      |
| **Role**        | Enum: user, moderator, admin         |
| **MongoDB IDs** | Valid ObjectId format (24 hex chars) |
| **Pagination**  | Page ≥ 1, Limit ≤ 100                |
| **Search**      | Max 100 chars, sanitized             |

## Roles & Permissions

- **User**: Regular users who can take quizzes
- **Moderator**: Can manage quizzes and moderate content
- **Admin**: Full system access, can manage users and moderators

## API Endpoints

### Authentication Routes (`/api/auth`)

| Method | Endpoint    | Description         | Auth Required |
| ------ | ----------- | ------------------- | ------------- |
| `POST` | `/register` | Register a new user | ❌            |
| `POST` | `/login`    | Login user          | ❌            |
| `GET`  | `/profile`  | Get user profile    | ✅            |
| `PUT`  | `/profile`  | Update user profile | ✅            |

### Admin Routes (`/api/admin`) - Admin Only

| Method   | Endpoint            | Description                             |
| -------- | ------------------- | --------------------------------------- |
| `GET`    | `/users`            | Get all users with pagination/filtering |
| `GET`    | `/users/:id`        | Get specific user by ID                 |
| `PUT`    | `/users/:id/role`   | Update user role                        |
| `PUT`    | `/users/:id/status` | Activate/deactivate user                |
| `DELETE` | `/users/:id`        | Delete user                             |
| `GET`    | `/stats`            | Get system statistics                   |

### Query Parameters for `/users`

- `page` - Page number (default: 1)
- `limit` - Items per page (default: 10, max: 100)
- `role` - Filter by role (user/moderator/admin)
- `isActive` - Filter by status (true/false)
- `search` - Search in name/email

## Setup & Installation

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Configure environment variables** in `.env`:

   ```env
   MONGODB_URI=mongodb://localhost:27017/onushilon
   JWT_SECRET=your-super-secret-jwt-key
   JWT_EXPIRE=7d
   PORT=3001
   NODE_ENV=development
   ```

3. **Start MongoDB**

4. **Run the development server:**

   ```bash
   npm run dev
   ```

5. **Run validation tests:**
   ```bash
   npm run test:validation
   ```

## Project Structure

```
Onushilon Backend/
├── config/
│   └── database.js          # MongoDB connection
├── controllers/
│   ├── authController.js    # Authentication logic with validation
│   └── adminController.js   # Admin operations with validation
├── middleware/
│   ├── auth.js             # JWT authentication & authorization
│   └── sanitization.js     # Input sanitization & security
├── models/
│   └── User.js             # User schema with methods
├── routes/
│   ├── auth.routes.js      # Authentication routes
│   └── admin.routes.js     # Admin routes
├── tests/
│   └── validation.test.js  # Validation system tests
├── utils/
│   ├── validators.js       # Manual validation utilities
│   └── responseHandler.js  # Consistent API responses
├── index.js                # Main application file
├── VALIDATION_GUIDE.md     # Comprehensive validation guide
└── package.json
```

## Validation Utilities (`utils/validators.js`)

```javascript
const {
  isValidEmail,
  isValidPhone,
  isValidAge,
  isValidPassword,
  isValidName,
  isValidRole,
  isValidObjectId,
  validatePagination,
  sanitizeSearchQuery,
} = require("./utils/validators");
```

## Security Features

- **Input Sanitization**: Automatic cleaning of all inputs
- **NoSQL Injection Prevention**: Blocks MongoDB operator injection
- **Password Hashing**: bcrypt with salt rounds 12
- **JWT Security**: Secure token generation and validation
- **Rate Limiting Ready**: Architecture supports rate limiting
- **CORS Protection**: Configurable cross-origin policies

## Testing

Run the validation test suite:

```bash
npm run test:validation
```

This will test all validation functions and display results in color-coded format.

## Environment Variables

- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `JWT_EXPIRE` - JWT token expiration time
- `PORT` - Server port
- `NODE_ENV` - Environment (development/production)
- `ADMIN_EMAIL` - Initial admin email
- `ADMIN_PASSWORD` - Initial admin password
