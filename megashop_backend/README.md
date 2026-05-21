# Mega Shop Backend

Backend API untuk aplikasi social commerce **Mega Shop** menggunakan **FastAPI**.

Project backend dibagi berdasarkan fitur agar development lebih rapi, mudah dikerjakan paralel, dan mengurangi conflict antar anggota tim.

---

# Backend Team Division

# Backend Team Division

## Orang 1 — Authentication & User

### Responsibility
Mengelola sistem authentication dan data user menggunakan Firebase Authentication dan FastAPI.

### Technologies
- Firebase Authentication
- FastAPI
- Pydantic

### Features
- Register user
- Login user
- Logout user
- Menjaga user session
- Get current user profile
- Edit user profile
- Form validation
- Error handling authentication

### Files
```text
app/routers/user_router.py

app/models/user_model.py

app/schemas/user_schema.py
```

### Endpoint
```text
POST /users
GET /users/{firebase_uid}
PUT /users/{firebase_uid}
```

### Tasks
- Setup Firebase Authentication di Flutter
- Integrasi Firebase login/register
- Menyimpan data profile user ke backend
- Validasi input login dan register
- Menambahkan response error jika login gagal
- Menambahkan endpoint profile user
- Testing API menggunakan Swagger/Postman

---

## Orang 2 — Product, Post, Reels

### Responsibility
Mengelola fitur social commerce seperti product, feed/post, dan reels.

### Technologies
- FastAPI
- Pydantic
- Swagger Docs

### Features
- Product API
- Product detail
- Create product
- Feed/Post API
- Delete post
- Reels API
- Upload reels
- API validation
- Error handling API

### Files
```text
app/routers/product_router.py
app/routers/post_router.py
app/routers/reel_router.py

app/models/product_model.py
app/models/post_model.py
app/models/reel_model.py

app/schemas/product_schema.py
app/schemas/post_schema.py
app/schemas/reel_schema.py
```

### Endpoint
```text
GET /products
GET /products/{id}
POST /products

GET /posts
POST /posts
DELETE /posts/{id}

GET /reels
GET /reels/{id}
POST /reels
```

### Tasks
- Membuat Product API
- Membuat Feed/Post API
- Membuat Reels API
- Membuat schema validation
- Menambahkan error handling
- Testing API di Swagger Docs
- Menyiapkan struktur data untuk frontend Flutter

---

## Orang 3 — Cart, Checkout, Order

### Responsibility
Mengelola cart system, checkout, order history, dan database SQLite.

### Technologies
- FastAPI
- SQLAlchemy
- SQLite
- Pydantic

### Features
- Cart API
- Checkout API
- Order history
- SQLite database integration
- Quantity validation
- Total price validation
- Error handling checkout/cart

### Files
```text
app/routers/cart_router.py
app/routers/order_router.py

app/models/cart_model.py
app/models/order_model.py

app/schemas/cart_schema.py
app/schemas/order_schema.py

database.py
```

### Endpoint
```text
GET /cart/{firebase_uid}
POST /cart
DELETE /cart/{id}

POST /checkout
GET /orders/{firebase_uid}
```

### Tasks
- Setup SQLite database
- Setup SQLAlchemy
- Membuat cart system
- Membuat checkout flow
- Membuat order history
- Menambahkan validation quantity dan total harga
- Menambahkan error handling checkout
- Testing API menggunakan Swagger/Postman

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