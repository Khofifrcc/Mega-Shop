from fastapi import APIRouter, HTTPException
from app.schemas.post_schema import PostCreate
from app.database import get_connection

router = APIRouter(prefix="/posts", tags=["Posts"])


@router.get("/")
def get_posts():
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM posts ORDER BY id DESC"
    ).fetchall()
    conn.close()

    return [dict(row) for row in rows]


@router.get("/user/{user_id}")
def get_posts_by_user(user_id: str):
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM posts WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    conn.close()

    return [dict(row) for row in rows]


@router.post("/")
def create_post(post: PostCreate):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO posts (user_id, caption, image)
        VALUES (?, ?, ?)
        """,
        (
            post.user_id,
            post.caption,
            post.image,
        ),
    )

    conn.commit()
    new_id = cur.lastrowid
    conn.close()

    return {
        "message": "Post created successfully",
        "data": {
            "id": new_id,
            **post.dict(),
        },
    }


@router.delete("/{post_id}")
def delete_post(post_id: int):
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "DELETE FROM posts WHERE id = ?",
        (post_id,),
    )

    conn.commit()
    deleted = cur.rowcount
    conn.close()

    if deleted == 0:
        raise HTTPException(
            status_code=404,
            detail="Post not found",
        )

    return {
        "message": "Post deleted successfully"
    }