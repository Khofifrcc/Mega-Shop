# Mega Shop Backend

Backend API untuk aplikasi social commerce **Mega Shop** menggunakan **FastAPI**.

Project backend dibagi berdasarkan fitur agar development lebih rapi, mudah dikerjakan paralel, dan mengurangi conflict antar anggota tim.

---

# Backend Team Division

## Orang 1 — Authentication & User

### Responsibility
- Register
- Login
- User profile
- Authentication logic
- Firebase Authentication integration

### Files
app/routers/user_router.py  
app/models/user_model.py  
app/schemas/user_schema.py  

### Endpoint
POST /users  
GET /users/{firebase_uid}  
PUT /users/{firebase_uid}  

### Tasks
- Setup Firebase Authentication
- Register & login user menggunakan Firebase
- Menjaga user session
- Get current user profile
- Edit user profile
- Validasi form login/register

---

## Orang 2 — Product, Post, Reels

### Responsibility
- Product API
- Feed/Post API
- Reels API
- Upload content
- Error handling API

### Files
app/routers/product_router.py  
app/routers/post_router.py  
app/routers/reel_router.py  

app/models/product_model.py  
app/models/post_model.py  
app/models/reel_model.py  

app/schemas/product_schema.py  
app/schemas/post_schema.py  
app/schemas/reel_schema.py  

### Endpoint
GET /products  
GET /products/{id}  
POST /products  

GET /posts  
POST /posts  
DELETE /posts/{id}  

GET /reels  
POST /reels  

### Tasks
- Get all products
- Product detail
- Upload product
- Create post/feed
- Delete post
- Get reels
- Upload reels/video
- Handle API error response

---

## Orang 3 — Cart, Checkout, Order

### Responsibility
- Cart system
- Checkout
- Order history
- Error handling checkout/cart

### Files
app/routers/cart_router.py  
app/routers/order_router.py  

app/models/cart_model.py  
app/models/order_model.py  

app/schemas/cart_schema.py  
app/schemas/order_schema.py  

### Endpoint
GET /cart/{firebase_uid}  
POST /cart  
DELETE /cart/{id}  

POST /checkout  
GET /orders/{firebase_uid}  

### Tasks
- Add to cart
- Remove cart item
- Get cart items
- Checkout flow
- Order history
- Quantity validation
- Total price validation
- Handle checkout/cart errors

---

# Shared Files

File berikut dipakai semua anggota tim dan tidak boleh diubah sembarangan:

main.py  
database.py  
requirements.txt  
README.md  

Jika ingin mengubah file shared:
- Diskusikan dengan tim terlebih dahulu
- Pull terbaru sebelum edit
- Pastikan tidak merusak endpoint anggota lain

---

# Rules Team

## Git Rules

- Jangan push langsung ke `main`
- Gunakan branch masing-masing
- Pull terbaru sebelum mulai coding
- Commit message harus jelas

### Example

```bash
git checkout -b feature/auth
git commit -m "add login endpoint"

## Install Dependencies

Jalankan command berikut di terminal:

```bash
pip install -r requirements.txt
```

Atau install manual:

```bash
pip install fastapi "uvicorn[standard]" sqlalchemy pydantic passlib bcrypt python-multipart
```
# Run Backend

```bash
cd megashop_backend
source .venv/bin/activate
pip install fastapi "uvicorn[standard]" sqlalchemy pydantic passlib bcrypt python-multipart
uvicorn main:app --reload

#teknoloji
Backend
Python FastAPI → REST API backend
Uvicorn → menjalankan FastAPI server
SQLAlchemy → database ORM
Pydantic → request & response validation
Database
SQLite → database development sederhana
Firebase
Firebase Authentication → authentication user
Firebase Storage (optional) → upload gambar produk / reels