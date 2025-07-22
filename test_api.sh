#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3001/api"

echo -e "${BLUE}=== Onushilon Quiz Backend API Test Script ===${NC}"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}1. Testing Health Check...${NC}"
HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
echo "Response: $HEALTH_RESPONSE"
echo ""

# Test 2: Register a new user
echo -e "${YELLOW}2. Registering a new user...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123"
  }')

echo "Register Response: $REGISTER_RESPONSE"

# Extract token from register response
USER_TOKEN=$(echo $REGISTER_RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
echo -e "${GREEN}User Token: $USER_TOKEN${NC}"
echo ""

# Test 3: Login with the user
echo -e "${YELLOW}3. Logging in with the user...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Password123"
  }')

echo "Login Response: $LOGIN_RESPONSE"
echo ""

# Test 4: Get user profile
if [ ! -z "$USER_TOKEN" ]; then
  echo -e "${YELLOW}4. Getting user profile...${NC}"
  PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER_TOKEN")
  
  echo "Profile Response: $PROFILE_RESPONSE"
  echo ""
fi

# Test 5: Login as admin (if MongoDB is available)
echo -e "${YELLOW}5. Trying to login as admin...${NC}"
ADMIN_LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@onushilon.com",
    "password": "admin123456"
  }')

echo "Admin Login Response: $ADMIN_LOGIN_RESPONSE"

# Extract admin token
ADMIN_TOKEN=$(echo $ADMIN_LOGIN_RESPONSE | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

if [ ! -z "$ADMIN_TOKEN" ]; then
  echo -e "${GREEN}Admin Token: $ADMIN_TOKEN${NC}"
  echo ""
  
  # Test 6: Get all users (admin only)
  echo -e "${YELLOW}6. Getting all users (admin access)...${NC}"
  USERS_RESPONSE=$(curl -s -X GET "$BASE_URL/admin/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  echo "Users Response: $USERS_RESPONSE"
  echo ""
  
  # Test 7: Get admin stats
  echo -e "${YELLOW}7. Getting admin statistics...${NC}"
  STATS_RESPONSE=$(curl -s -X GET "$BASE_URL/admin/stats" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  
  echo "Stats Response: $STATS_RESPONSE"
  echo ""
fi

# Test 8: Test unauthorized access
echo -e "${YELLOW}8. Testing unauthorized access to admin endpoint...${NC}"
UNAUTHORIZED_RESPONSE=$(curl -s -X GET "$BASE_URL/admin/users")
echo "Unauthorized Response: $UNAUTHORIZED_RESPONSE"
echo ""

# Test 9: Test invalid token
echo -e "${YELLOW}9. Testing with invalid token...${NC}"
INVALID_TOKEN_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/profile" \
  -H "Authorization: Bearer invalid_token_here")
echo "Invalid Token Response: $INVALID_TOKEN_RESPONSE"
echo ""

echo -e "${BLUE}=== Test Complete ===${NC}"
echo -e "${GREEN}✅ Authentication API is working!${NC}"
echo ""
echo -e "${YELLOW}Note: Some tests may fail if MongoDB is not running locally.${NC}"
echo -e "${YELLOW}To use MongoDB, install and start it with: brew install mongodb && brew services start mongodb${NC}"
