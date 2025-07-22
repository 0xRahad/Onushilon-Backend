# API Documentation - Onushilon Quiz Backend

## Base URL

```
http://localhost:5000/api
```

## Authentication

All protected routes require a Bearer token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Response Format

All API responses follow this format:

```json
{
  "status": "success" | "error",
  "message": "Response message",
  "data": {}, // Only present in success responses
  "errors": [] // Only present in validation error responses
}
```

---

## Authentication Endpoints

### 1. Register User

**POST** `/auth/register`

Register a new user account.

**Request Body:**

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "Password123"
}
```

**Validation Rules:**

- `name`: 2-50 characters, letters and spaces only
- `email`: Valid email format
- `password`: Minimum 6 characters, must contain uppercase, lowercase, and number

**Response (201):**

```json
{
  "status": "success",
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "createdAt": "2025-01-22T10:00:00.000Z"
    },
    "token": "jwt_token_here"
  }
}
```

### 2. Login User

**POST** `/auth/login`

Authenticate user and receive access token.

**Request Body:**

```json
{
  "email": "john@example.com",
  "password": "Password123"
}
```

**Response (200):**

```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "lastLogin": "2025-01-22T10:00:00.000Z"
    },
    "token": "jwt_token_here"
  }
}
```

### 3. Get User Profile

**GET** `/auth/profile`

Get current user's profile information.

**Headers:** `Authorization: Bearer <token>`

**Response (200):**

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "isActive": true,
      "lastLogin": "2025-01-22T10:00:00.000Z",
      "createdAt": "2025-01-22T08:00:00.000Z",
      "updatedAt": "2025-01-22T10:00:00.000Z"
    }
  }
}
```

### 4. Update User Profile

**PUT** `/auth/profile`

Update current user's profile information.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**

```json
{
  "name": "John Smith"
}
```

**Response (200):**

```json
{
  "status": "success",
  "message": "Profile updated successfully",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Smith",
      "email": "john@example.com",
      "role": "user",
      "updatedAt": "2025-01-22T10:15:00.000Z"
    }
  }
}
```

---

## Admin Endpoints

**Note:** All admin endpoints require admin role authentication.

### 1. Get All Users

**GET** `/admin/users`

Retrieve all users with pagination and filtering.

**Headers:** `Authorization: Bearer <admin_token>`

**Query Parameters:**

- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `role` (optional): Filter by role (user|moderator|admin)
- `isActive` (optional): Filter by status (true|false)
- `search` (optional): Search by name or email

**Example:** `/admin/users?page=1&limit=5&role=user&search=john`

**Response (200):**

```json
{
  "status": "success",
  "data": {
    "users": [
      {
        "id": "user_id",
        "name": "John Doe",
        "email": "john@example.com",
        "role": "user",
        "isActive": true,
        "lastLogin": "2025-01-22T10:00:00.000Z",
        "createdAt": "2025-01-22T08:00:00.000Z"
      }
    ],
    "pagination": {
      "current": 1,
      "total": 5,
      "count": 1,
      "totalUsers": 25
    }
  }
}
```

### 2. Get User by ID

**GET** `/admin/users/:id`

Get detailed information about a specific user.

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**

```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "isActive": true,
      "lastLogin": "2025-01-22T10:00:00.000Z",
      "createdAt": "2025-01-22T08:00:00.000Z",
      "updatedAt": "2025-01-22T10:00:00.000Z"
    }
  }
}
```

### 3. Update User Role

**PUT** `/admin/users/:id/role`

Change a user's role.

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**

```json
{
  "role": "moderator"
}
```

**Valid roles:** `user`, `moderator`, `admin`

**Response (200):**

```json
{
  "status": "success",
  "message": "User role updated to moderator",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "moderator",
      "updatedAt": "2025-01-22T10:30:00.000Z"
    }
  }
}
```

### 4. Update User Status

**PUT** `/admin/users/:id/status`

Activate or deactivate a user account.

**Headers:** `Authorization: Bearer <admin_token>`

**Request Body:**

```json
{
  "isActive": false
}
```

**Response (200):**

```json
{
  "status": "success",
  "message": "User deactivated successfully",
  "data": {
    "user": {
      "id": "user_id",
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "isActive": false,
      "updatedAt": "2025-01-22T10:35:00.000Z"
    }
  }
}
```

### 5. Delete User

**DELETE** `/admin/users/:id`

Permanently delete a user account.

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**

```json
{
  "status": "success",
  "message": "User deleted successfully"
}
```

### 6. Get System Statistics

**GET** `/admin/stats`

Get user statistics and recent activity.

**Headers:** `Authorization: Bearer <admin_token>`

**Response (200):**

```json
{
  "status": "success",
  "data": {
    "stats": {
      "totalUsers": 100,
      "activeUsers": 85,
      "inactiveUsers": 15,
      "usersByRole": {
        "user": 90,
        "moderator": 8,
        "admin": 2
      },
      "recentUsers": [
        {
          "name": "Jane Smith",
          "email": "jane@example.com",
          "role": "user",
          "createdAt": "2025-01-22T09:00:00.000Z"
        }
      ]
    }
  }
}
```

---

## Error Responses

### Validation Error (400)

```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Please provide a valid email address",
      "value": "invalid-email"
    }
  ]
}
```

### Authentication Error (401)

```json
{
  "status": "error",
  "message": "Access denied. No token provided."
}
```

### Authorization Error (403)

```json
{
  "status": "error",
  "message": "Access denied. Required role: admin"
}
```

### Not Found Error (404)

```json
{
  "status": "error",
  "message": "User not found"
}
```

### Server Error (500)

```json
{
  "status": "error",
  "message": "Server error during registration"
}
```

---

## User Roles

### User (Default)

- Can register and login
- Can update own profile
- Can access user-specific features (future quiz functionality)

### Moderator

- All user permissions
- Can moderate content (future implementation)
- Can manage quiz content (future implementation)

### Admin

- All moderator permissions
- Can manage all users
- Can change user roles
- Can activate/deactivate accounts
- Can delete users
- Can view system statistics

---

## Testing the API

### 1. Health Check

```bash
curl http://localhost:5000/api/health
```

### 2. Register a User

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123"
  }'
```

### 3. Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123"
  }'
```

### 4. Get Profile (with token)

```bash
curl -X GET http://localhost:5000/api/auth/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 5. Admin Login (using initial admin)

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@onushilon.com",
    "password": "admin123456"
  }'
```

### 6. Get All Users (Admin)

```bash
curl -X GET http://localhost:5000/api/admin/users \
  -H "Authorization: Bearer ADMIN_JWT_TOKEN"
```
