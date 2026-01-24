# Saverr API Documentation

## Overview

Saverr is a personal finance management API that provides endpoints for user authentication, bank account linking (via Plaid), transaction management, financial analytics, AI-powered chat assistance, savings goals, and financial planning.

### Base URL

```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/
```

### Authentication

Most endpoints require authentication via AWS Cognito JWT tokens. Include the token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Common Response Format

**Success Response:**

```json
{
  "statusCode": 200,
  "body": {
    // Response data
  }
}
```

**Error Response:**

```json
{
  "statusCode": 400,
  "body": {
    "error": "Error message description"
  }
}
```

### Common Error Codes

| Code | Description                                                        |
| ---- | ------------------------------------------------------------------ |
| 400  | Bad Request - Invalid input parameters                             |
| 401  | Unauthorized - Missing or invalid token                            |
| 404  | Not Found - Resource doesn't exist                                 |
| 500  | Internal Server Error                                              |
| 503  | Service Unavailable - External service (Plaid/Bedrock) unavailable |

---

## Authentication Endpoints

Authentication endpoints do **not** require JWT tokens.

---

### POST /auth/signup

Register a new user with AWS Cognito.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "name": "John Doe"
}
```

| Field    | Type   | Required | Description                                        |
| -------- | ------ | -------- | -------------------------------------------------- |
| email    | string | Yes      | Valid email address                                |
| password | string | Yes      | Min 8 chars with uppercase, lowercase, and numbers |
| name     | string | Yes      | User's full name (max 100 characters)              |

**Response (201 Created):**

```json
{
  "message": "User registered successfully",
  "user_confirmed": false,
  "confirmation_required": true,
  "user": {
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Errors:**

- `400` - Invalid email format or password requirements not met
- `409` - User already exists with this email (UsernameExistsException)

**Usage:**

1. Call this endpoint with user details
2. User receives a confirmation code via email
3. Call `/auth/confirm` with the code to activate the account

---

### POST /auth/login

Authenticate user and receive access/refresh tokens.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

| Field    | Type   | Required | Description          |
| -------- | ------ | -------- | -------------------- |
| email    | string | Yes      | User's email address |
| password | string | Yes      | User's password      |

**Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": "abc123-def456-ghi789",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Token Lifetimes:**

- `access_token`: 1 hour (3600 seconds)
- `refresh_token`: 30 days

**Errors:**

- `401` - Invalid email or password
- `400` - User not confirmed (email verification pending)

**Usage:**

1. Store both tokens securely (Keychain on iOS)
2. Use `access_token` in Authorization header for API calls
3. When `access_token` expires, use `/auth/refresh` with `refresh_token`

---

### POST /auth/confirm

Confirm user email registration with verification code.

**Request Body:**

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

| Field | Type   | Required | Description                              |
| ----- | ------ | -------- | ---------------------------------------- |
| email | string | Yes      | User's email address                     |
| code  | string | Yes      | 4+ digit confirmation code sent to email |

**Response (200 OK):**

```json
{
  "message": "Email confirmed successfully",
  "confirmed": true
}
```

**Errors:**

- `400` - Invalid code format
- `400` - Code mismatch (CodeMismatchException)
- `400` - Expired code (ExpiredCodeException)

**Usage:**
After successful confirmation, user can log in via `/auth/login`.

---

### POST /auth/refresh

Refresh an expired access token using a valid refresh token.

**Request Body:**

```json
{
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

| Field         | Type   | Required | Description                             |
| ------------- | ------ | -------- | --------------------------------------- |
| refresh_token | string | Yes      | Valid refresh token from previous login |

**Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "user": {
    "id": "abc123-def456-ghi789",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

**Errors:**

- `401` - Invalid or expired refresh token

**Usage:**
Call this endpoint when you receive a 401 error indicating an expired access token.

---

### POST /auth/resend-code

Resend email verification code for unconfirmed users.

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

| Field | Type   | Required | Description          |
| ----- | ------ | -------- | -------------------- |
| email | string | Yes      | User's email address |

**Response (200 OK):**

```json
{
  "message": "If an account exists with this email, a new code has been sent."
}
```

**Note:** Returns success even if user doesn't exist (security practice to prevent user enumeration).

**Errors:**

- `429` - Rate limit exceeded (LimitExceededException)
- `400` - User already confirmed

---

### POST /auth/forgot-password

Initiate password reset flow by sending a reset code to user's email.

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

| Field | Type   | Required | Description          |
| ----- | ------ | -------- | -------------------- |
| email | string | Yes      | User's email address |

**Response (200 OK):**

```json
{
  "message": "Password reset code sent to your email"
}
```

**Note:** Returns success even if user doesn't exist (security practice).

**Errors:**

- `429` - Rate limit exceeded

**Usage:**

1. Call this endpoint with user's email
2. User receives a reset code via email
3. Call `/auth/reset-password` with the code and new password

---

### POST /auth/reset-password

Complete password reset with verification code.

**Request Body:**

```json
{
  "email": "user@example.com",
  "code": "123456",
  "new_password": "NewSecurePass123"
}
```

| Field        | Type   | Required | Description                                                   |
| ------------ | ------ | -------- | ------------------------------------------------------------- |
| email        | string | Yes      | User's email address                                          |
| code         | string | Yes      | Reset code sent to email (4+ digits)                          |
| new_password | string | Yes      | New password (min 8 chars with uppercase, lowercase, numbers) |

**Response (200 OK):**

```json
{
  "message": "Password reset successfully"
}
```

**Errors:**

- `400` - Invalid or expired code
- `400` - Password doesn't meet requirements

---

## Account Endpoints

All account endpoints require authentication via `Authorization: Bearer <access_token>` header.

---

### GET /accounts

Fetch all linked bank accounts for the authenticated user.

**Response (200 OK):**

```json
{
  "accounts": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "institution_name": "Chase Bank",
      "account_name": "Checking Account",
      "account_type": "checking",
      "balance": 5000.0,
      "last_updated": "2024-01-21T12:00:00Z",
      "is_linked": true,
      "account_number_last4": "1234",
      "institution_logo": "building.columns"
    }
  ],
  "total_balance": 5000.0
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique account identifier |
| institution_name | string | Bank/institution name |
| account_name | string | Account name (e.g., "Checking", "Savings") |
| account_type | string | Type: checking, savings, credit, investment |
| balance | number | Current account balance |
| last_updated | ISO 8601 | Last balance update timestamp |
| is_linked | boolean | Whether account is actively linked |
| account_number_last4 | string | Last 4 digits of account number |
| institution_logo | string | SF Symbol icon name for display |
| total_balance | number | Sum of all linked account balances |

**Usage:**
Use this to display the user's account overview on the home screen.

---

### GET /accounts/{account_id}

Fetch details for a specific account.

**Path Parameters:**

| Parameter  | Type | Description            |
| ---------- | ---- | ---------------------- |
| account_id | UUID | The account identifier |

**Response (200 OK):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "institution_name": "Chase Bank",
  "account_name": "Checking Account",
  "account_type": "checking",
  "balance": 5000.0,
  "last_updated": "2024-01-21T12:00:00Z",
  "is_linked": true,
  "account_number_last4": "1234",
  "institution_logo": "building.columns",
  "routing_number_last4": "5678"
}
```

**Errors:**

- `400` - Invalid account_id format (not a valid UUID)
- `404` - Account not found or doesn't belong to user

---

### POST /accounts/link-token

Create a Plaid Link token for initializing the Plaid Link flow on the client.

**Request Body (optional):**

```json
{
  "access_token": "access-sandbox-xxx"
}
```

| Field        | Type   | Required | Description                                   |
| ------------ | ------ | -------- | --------------------------------------------- |
| access_token | string | No       | For update mode (re-linking expired accounts) |

**Response (200 OK):**

```json
{
  "link_token": "link-sandbox-af1a0311-da53-4636-b754-dd15cc058176",
  "expiration": "2024-01-21T16:00:00Z",
  "request_id": "Xvl8u4GlpK9UVmo"
}
```

**Token Lifetime:** 4 hours

**Errors:**

- `503` - Plaid service unavailable

**Usage (Plaid Link Flow):**

1. Call this endpoint to get a `link_token`
2. Initialize Plaid Link SDK on client with the token
3. User selects their bank and authenticates
4. Plaid returns a `public_token` to your client
5. Call `/accounts/link` with the `public_token` to complete linking

---

### POST /accounts/link

Exchange Plaid public token for access token and create account records.

**Request Body:**

```json
{
  "public_token": "public-sandbox-xxx",
  "institution_id": "ins_123"
}
```

| Field          | Type   | Required | Description                       |
| -------------- | ------ | -------- | --------------------------------- |
| public_token   | string | Yes      | Public token from Plaid Link flow |
| institution_id | string | No       | Institution identifier from Plaid |

**Response (200 OK):**

```json
{
  "account": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "institution_name": "Chase Bank",
    "account_name": "Checking Account",
    "account_type": "checking",
    "balance": 5000.0,
    "last_updated": "2024-01-21T12:00:00Z",
    "is_linked": true,
    "account_number_last4": "1234"
  },
  "link_status": "success",
  "accounts_linked": 1
}
```

**Note:** If the user has multiple accounts at the same institution (e.g., checking and savings), `accounts_linked` will reflect the total number of accounts created. The `account` field returns the primary account.

**Errors:**

- `400` - Invalid or expired public token
- `503` - Plaid service unavailable

---

### DELETE /accounts/{account_id}

Unlink a bank account and revoke Plaid access.

**Path Parameters:**

| Parameter  | Type | Description           |
| ---------- | ---- | --------------------- |
| account_id | UUID | The account to delete |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Account unlinked successfully"
}
```

**Behavior:**

- Revokes Plaid access token (if available)
- Removes account from database
- Associated transactions remain for historical data

**Errors:**

- `404` - Account not found

---

### POST /accounts/{account_id}/refresh

Refresh account balance from Plaid.

**Path Parameters:**

| Parameter  | Type | Description        |
| ---------- | ---- | ------------------ |
| account_id | UUID | Account to refresh |

**Response (200 OK):**

```json
{
  "balance": 5250.5,
  "last_updated": "2024-01-21T13:30:00Z"
}
```

**Errors:**

- `404` - Account not found
- `503` - Plaid service unavailable

**Usage:**
Call this when user pulls-to-refresh on the account detail screen.

---

### GET /accounts/{account_id}/transactions

Fetch transactions for a specific account with optional filtering and pagination.

**Path Parameters:**

| Parameter  | Type | Description |
| ---------- | ---- | ----------- |
| account_id | UUID | Account ID  |

**Query Parameters:**

| Parameter  | Type    | Default | Description                                |
| ---------- | ------- | ------- | ------------------------------------------ |
| start_date | string  | -       | Filter transactions >= date (YYYY-MM-DD)   |
| end_date   | string  | -       | Filter transactions <= date (YYYY-MM-DD)   |
| limit      | integer | 50      | Results per page (1-500)                   |
| offset     | integer | 0       | Pagination offset                          |
| category   | string  | -       | Filter by category name (case-insensitive) |

**Example Request:**

```
GET /accounts/550e8400.../transactions?start_date=2024-01-01&end_date=2024-01-31&limit=20&category=food
```

**Response (200 OK):**

```json
{
  "transactions": [
    {
      "id": "txn-550e8400-e29b-41d4",
      "amount": 45.99,
      "description": "Starbucks Coffee",
      "date": "2024-01-20",
      "category_name": "Food And Drink",
      "is_income": false,
      "merchant": "Starbucks"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

**Transaction Fields:**
| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique transaction identifier |
| amount | number | Transaction amount (positive = expense, negative = income) |
| description | string | Transaction description |
| date | string | Transaction date (YYYY-MM-DD) |
| category_name | string | Category classification |
| is_income | boolean | True if this is income |
| merchant | string | Merchant name (if available) |

**Errors:**

- `404` - Account not found

---

### POST /accounts/{account_id}/sync

Sync transactions from Plaid using incremental sync API.

**Path Parameters:**

| Parameter  | Type | Description     |
| ---------- | ---- | --------------- |
| account_id | UUID | Account to sync |

**Query Parameters:**

| Parameter | Type    | Default | Description                                   |
| --------- | ------- | ------- | --------------------------------------------- |
| use_sync  | boolean | true    | Use /transactions/sync endpoint (recommended) |
| days      | integer | 30      | For legacy mode only (max 730)                |

**Response (200 OK):**

```json
{
  "synced": 150,
  "added": 145,
  "modified": 3,
  "removed": 2,
  "has_more": false,
  "cursor": "next_cursor_value"
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| synced | integer | Total transactions processed |
| added | integer | New transactions added |
| modified | integer | Existing transactions updated |
| removed | integer | Transactions removed (e.g., declined charges) |
| has_more | boolean | More transactions available (call again with cursor) |
| cursor | string | Cursor for next incremental sync |

**Errors:**

- `404` - Account not found
- `503` - Plaid service unavailable

**Usage:**

- Call after linking a new account to fetch initial transactions
- Call periodically (e.g., daily) to keep transactions up to date
- If `has_more` is true, call again to get remaining transactions

---

## Analytics Endpoints

All analytics endpoints require authentication.

---

### GET /analytics/budget-comparison

Compare budgeted vs actual spending for a specific month.

**Query Parameters:**

| Parameter | Type   | Required | Description                               |
| --------- | ------ | -------- | ----------------------------------------- |
| month     | string | Yes      | Month in format YYYY-MM (e.g., "2024-01") |

**Example Request:**

```
GET /analytics/budget-comparison?month=2024-01
```

**Response (200 OK):**

```json
{
  "budgeted": 5000.0,
  "actual": 4250.5,
  "is_over_budget": false,
  "percent_used": 0.8501,
  "by_category": [
    {
      "category_name": "Food & Dining",
      "budgeted": 800.0,
      "actual": 750.25,
      "is_over_budget": false
    },
    {
      "category_name": "Transportation",
      "budgeted": 400.0,
      "actual": 520.0,
      "is_over_budget": true
    }
  ]
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| budgeted | number | Total budgeted amount for the month |
| actual | number | Total actual spending |
| is_over_budget | boolean | True if actual > budgeted |
| percent_used | number | Ratio of actual/budgeted (0.85 = 85%) |
| by_category | array | Per-category breakdown |

**Errors:**

- `400` - Invalid month format

**Usage:**
Display a budget progress bar and category breakdown on the budget screen.

---

### GET /analytics/cash-flow

Get cash flow analysis showing inflows and outflows over a date range.

**Query Parameters:**

| Parameter   | Type   | Required | Default | Description                          |
| ----------- | ------ | -------- | ------- | ------------------------------------ |
| start_date  | string | Yes      | -       | Start date (YYYY-MM-DD)              |
| end_date    | string | Yes      | -       | End date (YYYY-MM-DD)                |
| granularity | string | No       | daily   | One of: "daily", "weekly", "monthly" |

**Example Request:**

```
GET /analytics/cash-flow?start_date=2024-01-01&end_date=2024-01-31&granularity=weekly
```

**Response (200 OK):**

```json
{
  "inflows": [
    { "date": "2024-01-01", "amount": 2500.0 },
    { "date": "2024-01-15", "amount": 2500.0 }
  ],
  "outflows": [
    { "date": "2024-01-02", "amount": 350.75 },
    { "date": "2024-01-05", "amount": 125.5 }
  ],
  "net_flow": 3524.25,
  "total_inflow": 5000.0,
  "total_outflow": 1475.75
}
```

**Granularity Options:**
| Value | Description |
|-------|-------------|
| daily | Group by individual days |
| weekly | Group by week (Monday start) |
| monthly | Group by calendar month |

**Errors:**

- `400` - Invalid date format or granularity value

**Usage:**
Display cash flow charts showing income vs expenses over time.

---

### GET /analytics/savings-progress

Track progress on all active savings goals with projections.

**Response (200 OK):**

```json
{
  "goals": [
    {
      "goal": {
        "id": "goal-123",
        "title": "Emergency Fund",
        "target_amount": 10000.0,
        "current_amount": 3500.0,
        "target_date": "2024-12-31",
        "progress": 0.35
      },
      "monthly_contribution": 583.33,
      "projected_completion_date": "2024-10-15",
      "on_track": true
    }
  ],
  "total_saved": 8500.0,
  "total_target": 25000.0,
  "overall_progress": 0.34
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| goals | array | Per-goal progress details |
| monthly_contribution | number | Estimated monthly savings rate |
| projected_completion_date | string | Projected date to reach goal |
| on_track | boolean | True if projected date <= target date |
| total_saved | number | Sum of all current_amounts |
| total_target | number | Sum of all target_amounts |
| overall_progress | number | Ratio of total_saved/total_target |

**Usage:**
Display savings dashboard with progress rings for each goal.

---

### GET /analytics/spending-by-category

Get spending breakdown by category with visual metadata.

**Query Parameters:**

| Parameter  | Type   | Required | Description             |
| ---------- | ------ | -------- | ----------------------- |
| start_date | string | Yes      | Start date (YYYY-MM-DD) |
| end_date   | string | Yes      | End date (YYYY-MM-DD)   |

**Example Request:**

```
GET /analytics/spending-by-category?start_date=2024-01-01&end_date=2024-01-31
```

**Response (200 OK):**

```json
{
  "categories": [
    {
      "category_name": "Food & Dining",
      "icon_name": "fork.knife",
      "color_hex": "#FF6B6B",
      "amount": 850.5,
      "percentage": 0.4502,
      "transaction_count": 42
    },
    {
      "category_name": "Transportation",
      "icon_name": "car",
      "color_hex": "#45B7D1",
      "amount": 520.0,
      "percentage": 0.2748,
      "transaction_count": 8
    }
  ],
  "total_spending": 1890.25
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| category_name | string | Category display name |
| icon_name | string | SF Symbol icon name for iOS |
| color_hex | string | Hex color code for visualization |
| amount | number | Total spending in category |
| percentage | number | Ratio of category/total spending |
| transaction_count | integer | Number of transactions |

**Category Icons and Colors:**

| Category          | Icon            | Color   |
| ----------------- | --------------- | ------- |
| Food & Dining     | fork.knife      | #FF6B6B |
| Transportation    | car             | #45B7D1 |
| Shopping          | bag             | #96CEB4 |
| Entertainment     | tv              | #FFEAA7 |
| Bills & Utilities | bolt            | #DDA0DD |
| Healthcare        | heart           | #FF6B6B |
| Travel            | airplane        | #74B9FF |
| Other             | ellipsis.circle | #95A5A6 |

**Errors:**

- `400` - Invalid date format

**Usage:**
Display pie/donut chart of spending breakdown.

---

## Chat Endpoints

All chat endpoints require authentication. These endpoints use Amazon Bedrock with Claude for AI-powered financial advice.

---

### POST /chat/message

Send a message to the AI financial advisor and receive a response.

**Request Body:**

```json
{
  "message": "How can I save more money each month?",
  "context": [
    { "is_from_user": true, "content": "I want to improve my finances" },
    {
      "is_from_user": false,
      "content": "I'd be happy to help! What's your main goal?"
    }
  ],
  "include_financial_context": true
}
```

| Field                     | Type    | Required | Default | Description                                 |
| ------------------------- | ------- | -------- | ------- | ------------------------------------------- |
| message                   | string  | Yes      | -       | User message (max 2000 chars)               |
| context                   | array   | No       | []      | Previous chat messages (last 10 used)       |
| include_financial_context | boolean | No       | true    | Include user's financial data in AI context |

**Context Message Format:**

```json
{
  "is_from_user": true,
  "content": "message text"
}
```

**Response (200 OK):**

```json
{
  "response": {
    "id": "msg-550e8400-e29b",
    "content": "Based on your spending patterns, here are some ways to save more money each month:\n\n1. **Reduce dining out** - You spent $450 on restaurants last month...",
    "timestamp": "2024-01-23T15:30:45.123Z",
    "message_type": "text",
    "suggestions": [
      "Create a budget",
      "Set a savings goal",
      "Review my spending"
    ]
  }
}
```

**Message Types:**
| Type | Description |
|------|-------------|
| text | Standard text response |
| goal_suggestion | Response includes goal recommendations |
| budget_advice | Response includes budget recommendations |
| celebration | Positive feedback (goal reached, etc.) |
| question | AI asking for clarification |
| plan_generated | Response includes financial plan |

**Errors:**

- `400` - Message too long or invalid format

**Usage:**
Implement a chat interface where users can ask financial questions.

---

### POST /chat/generate-plan

Generate a comprehensive personalized financial plan using AI.

**Request Body:**

```json
{
  "context": [
    { "is_from_user": true, "content": "I want to save for a house" }
  ],
  "include_transactions": true,
  "time_horizon_months": 24
}
```

| Field                | Type    | Required | Default | Description                            |
| -------------------- | ------- | -------- | ------- | -------------------------------------- |
| context              | array   | No       | []      | Chat conversation context              |
| include_transactions | boolean | No       | true    | Include spending summary in AI context |
| time_horizon_months  | integer | No       | 12      | Planning horizon (1-120 months)        |

**Response (200 OK):**

```json
{
  "plan": {
    "id": "plan-550e8400-e29b",
    "summary": "Based on your $3,500 monthly income and $2,200 in expenses, here's a 24-month plan to save for a house down payment...",
    "recommendations": [
      "Build an emergency fund covering 3-6 months of expenses",
      "Review and reduce unnecessary subscriptions",
      "Set up automatic savings transfers of $500/month"
    ],
    "monthly_target_savings": 1300.0,
    "generated_at": "2024-01-23T15:30:45.123Z",
    "is_active": true,
    "suggested_goals": [
      {
        "title": "House Down Payment",
        "target_amount": 40000.0,
        "target_date": "2026-01-23",
        "category": "purchase",
        "priority": 1
      },
      {
        "title": "Emergency Fund",
        "target_amount": 10000.0,
        "target_date": "2024-07-23",
        "category": "emergency",
        "priority": 2
      }
    ]
  }
}
```

**Note:** Creating a new plan automatically deactivates any existing active plans (one active plan per user).

**Usage:**

1. Gather user preferences via chat conversation
2. Call this endpoint to generate a personalized plan
3. Display plan summary and recommendations
4. Allow user to create suggested goals via `/goals` endpoint

---

### POST /chat/suggest-goals

Analyze transaction history and suggest personalized financial goals.

**Request Body:**

```json
{
  "date_range": {
    "start": "2023-07-01",
    "end": "2024-01-01"
  }
}
```

| Field      | Type   | Required | Default       | Description                                    |
| ---------- | ------ | -------- | ------------- | ---------------------------------------------- |
| date_range | object | No       | Last 6 months | Date range with `start` and `end` (YYYY-MM-DD) |

**Response (200 OK):**

```json
{
  "suggested_goals": [
    {
      "title": "Emergency Fund",
      "description": "Build a 3-month safety net for unexpected expenses",
      "target_amount": 6600.0,
      "suggested_target_date": "2024-07-23",
      "category": "emergency",
      "reasoning": "Based on your monthly expenses of $2,200, a 3-month emergency fund would be $6,600"
    },
    {
      "title": "Vacation Fund",
      "description": "Save for an annual vacation",
      "target_amount": 4000.0,
      "suggested_target_date": "2024-12-23",
      "category": "vacation",
      "reasoning": "You have $1,300 monthly savings capacity, making this achievable by end of year"
    }
  ]
}
```

**Fields:**
| Field | Type | Description |
|-------|------|-------------|
| title | string | Suggested goal name |
| description | string | Goal description |
| target_amount | number | Recommended target amount |
| suggested_target_date | string | Recommended deadline (YYYY-MM-DD) |
| category | string | Goal category |
| reasoning | string | AI explanation for the suggestion |

**Usage:**
Display goal suggestions with "Add Goal" buttons that call `/goals` to create.

---

## Goals Endpoints

All goals endpoints require authentication.

---

### POST /goals

Create a new financial goal.

**Request Body:**

```json
{
  "title": "Emergency Fund",
  "target_amount": 10000.0,
  "current_amount": 500.0,
  "description": "3-6 months of living expenses",
  "target_date": "2024-12-31",
  "category": "emergency"
}
```

| Field          | Type   | Required | Default  | Description                       |
| -------------- | ------ | -------- | -------- | --------------------------------- |
| title          | string | Yes      | -        | Goal title (max 200 chars)        |
| target_amount  | number | Yes      | -        | Target amount (must be > 0)       |
| current_amount | number | No       | 0        | Starting amount                   |
| description    | string | No       | -        | Goal description (max 1000 chars) |
| target_date    | string | No       | -        | Target date (YYYY-MM-DD)          |
| category       | string | No       | "custom" | Category (see below)              |

**Valid Categories:**
| Category | Description |
|----------|-------------|
| savings | General savings |
| debt_payoff | Paying off debt |
| emergency | Emergency fund |
| investment | Investment goals |
| purchase | Large purchase (car, house, etc.) |
| retirement | Retirement savings |
| vacation | Travel/vacation fund |
| custom | User-defined |

**Response (201 Created):**

```json
{
  "goal": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Emergency Fund",
    "description": "3-6 months of living expenses",
    "target_amount": 10000.0,
    "current_amount": 500.0,
    "target_date": "2024-12-31",
    "created_at": "2024-01-23T15:30:45.123Z",
    "category": "emergency",
    "is_ai_generated": false,
    "priority": 0,
    "progress": 0.05
  }
}
```

**Errors:**

- `400` - Missing title, invalid amount, or invalid category

---

### GET /goals

List all financial goals with optional filtering.

**Query Parameters:**

| Parameter | Type   | Default  | Description                             |
| --------- | ------ | -------- | --------------------------------------- |
| status    | string | "active" | Filter: "active", "completed", or "all" |
| category  | string | -        | Filter by category (case-insensitive)   |

**Example Request:**

```
GET /goals?status=active&category=emergency
```

**Response (200 OK):**

```json
{
  "goals": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Emergency Fund",
      "description": "3-6 months of living expenses",
      "target_amount": 10000.0,
      "current_amount": 3500.0,
      "target_date": "2024-12-31",
      "created_at": "2024-01-23T15:30:45.123Z",
      "category": "emergency",
      "is_ai_generated": false,
      "priority": 1,
      "progress": 0.35
    }
  ]
}
```

---

### GET /goals/{goal_id}

Get details for a specific goal.

**Path Parameters:**

| Parameter | Type | Description         |
| --------- | ---- | ------------------- |
| goal_id   | UUID | The goal identifier |

**Response (200 OK):**

```json
{
  "goal": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Emergency Fund",
    "description": "3-6 months of living expenses",
    "target_amount": 10000.0,
    "current_amount": 3500.0,
    "target_date": "2024-12-31",
    "created_at": "2024-01-23T15:30:45.123Z",
    "category": "emergency",
    "is_ai_generated": false,
    "priority": 1,
    "progress": 0.35
  }
}
```

**Errors:**

- `400` - Invalid goal_id format
- `404` - Goal not found

---

### PUT /goals/{goal_id}

Update an existing goal. Supports partial updates (only provided fields are updated).

**Path Parameters:**

| Parameter | Type | Description         |
| --------- | ---- | ------------------- |
| goal_id   | UUID | The goal identifier |

**Request Body (all fields optional):**

```json
{
  "title": "Updated Emergency Fund",
  "description": "6 months of living expenses",
  "target_amount": 15000.0,
  "current_amount": 5000.0,
  "target_date": "2025-06-30",
  "category": "emergency",
  "priority": 1
}
```

| Field          | Type    | Description                          |
| -------------- | ------- | ------------------------------------ |
| title          | string  | Updated title (max 200 chars)        |
| description    | string  | Updated description (max 1000 chars) |
| target_amount  | number  | New target (must be > 0)             |
| current_amount | number  | New current amount                   |
| target_date    | string  | New target date (YYYY-MM-DD)         |
| category       | string  | New category                         |
| priority       | integer | New priority (non-negative)          |

**Response (200 OK):**

```json
{
  "goal": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Updated Emergency Fund",
    "description": "6 months of living expenses",
    "target_amount": 15000.0,
    "current_amount": 5000.0,
    "target_date": "2025-06-30",
    "created_at": "2024-01-23T15:30:45.123Z",
    "category": "emergency",
    "is_ai_generated": false,
    "priority": 1,
    "progress": 0.3333
  }
}
```

**Errors:**

- `400` - No valid fields to update or invalid field values
- `404` - Goal not found

---

### DELETE /goals/{goal_id}

Permanently delete a financial goal.

**Path Parameters:**

| Parameter | Type | Description         |
| --------- | ---- | ------------------- |
| goal_id   | UUID | The goal identifier |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Goal deleted successfully"
}
```

**Errors:**

- `404` - Goal not found

---

### POST /goals/{goal_id}/contribute

Add a contribution to a goal, incrementing its current amount.

**Path Parameters:**

| Parameter | Type | Description         |
| --------- | ---- | ------------------- |
| goal_id   | UUID | The goal identifier |

**Request Body:**

```json
{
  "amount": 500.0,
  "note": "Monthly savings deposit"
}
```

| Field  | Type   | Required | Description                       |
| ------ | ------ | -------- | --------------------------------- |
| amount | number | Yes      | Contribution amount (must be > 0) |
| note   | string | No       | Optional note (max 500 chars)     |

**Response (200 OK):**

```json
{
  "goal": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "current_amount": 4000.0,
    "progress": 0.4
  },
  "contribution": {
    "id": "contrib-550e8400",
    "amount": 500.0,
    "date": "2024-01-23T15:30:45.123Z",
    "note": "Monthly savings deposit"
  }
}
```

**Errors:**

- `400` - Invalid amount
- `404` - Goal not found

**Usage:**
Use this when users manually record a deposit toward their goal.

---

## Plans Endpoints

All plans endpoints require authentication.

---

### POST /plans

Create a new financial plan. Automatically deactivates existing active plans.

**Request Body:**

```json
{
  "summary": "Your personalized 12-month financial plan focused on building an emergency fund and paying off debt.",
  "recommendations": [
    "Build an emergency fund covering 3-6 months of expenses",
    "Pay off high-interest credit card debt first",
    "Set up automatic savings transfers"
  ],
  "monthly_target_savings": 1300.0,
  "goal_ids": ["goal-123", "goal-456"]
}
```

| Field                  | Type   | Required | Default | Description                                  |
| ---------------------- | ------ | -------- | ------- | -------------------------------------------- |
| summary                | string | Yes      | -       | Plan summary (max 2000 chars)                |
| recommendations        | array  | No       | []      | List of recommendations (each max 500 chars) |
| monthly_target_savings | number | No       | 0       | Target monthly savings                       |
| goal_ids               | array  | No       | []      | Associated goal IDs                          |

**Response (201 Created):**

```json
{
  "plan": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "summary": "Your personalized 12-month financial plan...",
    "recommendations": [
      "Build an emergency fund covering 3-6 months of expenses",
      "Pay off high-interest credit card debt first",
      "Set up automatic savings transfers"
    ],
    "monthly_target_savings": 1300.0,
    "generated_at": "2024-01-23T15:30:45.123Z",
    "is_active": true,
    "goal_ids": ["goal-123", "goal-456"]
  }
}
```

**Note:** Only one plan can be active at a time. Creating a new plan automatically deactivates all existing plans.

---

### GET /plans

List all financial plans for the authenticated user.

**Query Parameters:**

| Parameter   | Type    | Default | Description                 |
| ----------- | ------- | ------- | --------------------------- |
| active_only | boolean | true    | Filter to only active plans |

**Example Request:**

```
GET /plans?active_only=true
```

**Response (200 OK):**

```json
{
  "plans": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "summary": "Your personalized 12-month financial plan...",
      "recommendations": [
        "Build an emergency fund",
        "Pay off credit card debt"
      ],
      "monthly_target_savings": 1300.0,
      "generated_at": "2024-01-23T15:30:45.123Z",
      "is_active": true
    }
  ]
}
```

---

### PUT /plans/{plan_id}/deactivate

Deactivate a specific financial plan.

**Path Parameters:**

| Parameter | Type | Description         |
| --------- | ---- | ------------------- |
| plan_id   | UUID | The plan identifier |

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Plan deactivated"
}
```

**Errors:**

- `404` - Plan not found

---

## API Summary Table

| Category      | Endpoint                        | Method | Auth | Description              |
| ------------- | ------------------------------- | ------ | ---- | ------------------------ |
| **Auth**      | /auth/signup                    | POST   | No   | Register new user        |
|               | /auth/login                     | POST   | No   | Authenticate user        |
|               | /auth/confirm                   | POST   | No   | Confirm email            |
|               | /auth/refresh                   | POST   | No   | Refresh access token     |
|               | /auth/resend-code               | POST   | No   | Resend verification code |
|               | /auth/forgot-password           | POST   | No   | Initiate password reset  |
|               | /auth/reset-password            | POST   | No   | Complete password reset  |
| **Accounts**  | /accounts                       | GET    | Yes  | List all accounts        |
|               | /accounts/{id}                  | GET    | Yes  | Get account details      |
|               | /accounts/link-token            | POST   | Yes  | Create Plaid Link token  |
|               | /accounts/link                  | POST   | Yes  | Link new account         |
|               | /accounts/{id}                  | DELETE | Yes  | Unlink account           |
|               | /accounts/{id}/refresh          | POST   | Yes  | Refresh balance          |
|               | /accounts/{id}/transactions     | GET    | Yes  | Get transactions         |
|               | /accounts/{id}/sync             | POST   | Yes  | Sync from Plaid          |
| **Analytics** | /analytics/budget-comparison    | GET    | Yes  | Budget vs actual         |
|               | /analytics/cash-flow            | GET    | Yes  | Cash flow analysis       |
|               | /analytics/savings-progress     | GET    | Yes  | Goal progress            |
|               | /analytics/spending-by-category | GET    | Yes  | Spending breakdown       |
| **Chat**      | /chat/message                   | POST   | Yes  | Send chat message        |
|               | /chat/generate-plan             | POST   | Yes  | Generate financial plan  |
|               | /chat/suggest-goals             | POST   | Yes  | Get goal suggestions     |
| **Goals**     | /goals                          | GET    | Yes  | List goals               |
|               | /goals                          | POST   | Yes  | Create goal              |
|               | /goals/{id}                     | GET    | Yes  | Get goal details         |
|               | /goals/{id}                     | PUT    | Yes  | Update goal              |
|               | /goals/{id}                     | DELETE | Yes  | Delete goal              |
|               | /goals/{id}/contribute          | POST   | Yes  | Add contribution         |
| **Plans**     | /plans                          | GET    | Yes  | List plans               |
|               | /plans                          | POST   | Yes  | Create plan              |
|               | /plans/{id}/deactivate          | PUT    | Yes  | Deactivate plan          |

---

## Rate Limiting

API requests are rate limited per user:

| Endpoint Type       | Limit               |
| ------------------- | ------------------- |
| Standard endpoints  | 100 requests/minute |
| AI Chat endpoints   | 20 requests/minute  |
| Analytics endpoints | 50 requests/minute  |

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642781234
```

---

## Environment Variables

The API requires these environment variables:

| Variable              | Description                                           |
| --------------------- | ----------------------------------------------------- |
| COGNITO_USER_POOL_ID  | AWS Cognito User Pool ID                              |
| COGNITO_CLIENT_ID     | Cognito App Client ID                                 |
| COGNITO_CLIENT_SECRET | Cognito App Client Secret (optional)                  |
| PLAID_CLIENT_ID       | Plaid API Client ID                                   |
| PLAID_SECRET          | Plaid API Secret                                      |
| PLAID_ENV             | Plaid environment (sandbox, development, production)  |
| BEDROCK_MODEL_ID      | Amazon Bedrock model ID (defaults to Claude 3 Sonnet) |
| DYNAMODB_TABLE_PREFIX | Prefix for DynamoDB table names                       |

---

## Security Considerations

- All API calls use HTTPS
- Store tokens securely (Keychain on iOS, Secure Storage on Android)
- Implement certificate pinning for production
- Never log sensitive financial data
- Plaid handles bank credentials (app never sees them)
- JWTs are validated via Cognito authorizer on API Gateway
