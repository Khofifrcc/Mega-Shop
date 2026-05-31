from fastapi import APIRouter, HTTPException
from app.schemas.product_schema import ProductCreate
from app.database import get_connection

router = APIRouter(prefix="/products", tags=["Products"])

@router.get("/")
def get_products():
    conn = get_connection()
    rows = conn.execute("""
        SELECT 
            products.*,
            users.username AS username,
            users.profile_photo AS profile_photo
        FROM products
        LEFT JOIN users ON products.user_id = users.firebase_uid
        ORDER BY products.id DESC
    """).fetchall()
    conn.close()
    return [dict(row) for row in rows]

@router.put("/{product_id}")
def update_product(product_id: int, product: ProductCreate):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE products
        SET name = ?, price = ?, description = ?, image = ?
        WHERE id = ? AND user_id = ?
        """,
        (
            product.name,
            product.price,
            product.description,
            product.image,
            product_id,
            product.user_id,
        ),
    )
    conn.commit()
    updated = cur.rowcount
    conn.close()

    if updated == 0:
        raise HTTPException(status_code=404, detail="Product not found")

    return {"message": "Product updated successfully"}

@router.get("/user/{user_id}")
def get_products_by_user(user_id: str):
    conn = get_connection()
    rows = conn.execute("""
        SELECT 
            products.*,
            users.username AS username,
            users.profile_photo AS profile_photo
        FROM products
        LEFT JOIN users ON products.user_id = users.firebase_uid
        WHERE products.user_id = ?
        ORDER BY products.id DESC
    """, (user_id,)).fetchall()
    conn.close()
    return [dict(row) for row in rows]

@router.post("/")
def create_product(product: ProductCreate):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO products (user_id, name, price, description, image)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            product.user_id,
            product.name,
            product.price,
            product.description,
            product.image,
        ),
    )
    conn.commit()
    new_id = cur.lastrowid
    conn.close()

    return {
        "message": "Product created successfully",
        "data": {"id": new_id, **product.dict()},
    }

@router.delete("/{product_id}")
def delete_product(product_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM products WHERE id = ?", (product_id,))
    conn.commit()
    deleted = cur.rowcount
    conn.close()

    if deleted == 0:
        raise HTTPException(status_code=404, detail="Product not found")

    return {"message": "Product deleted successfully"}

    