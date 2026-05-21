from fastapi import APIRouter, HTTPException
from app.schemas.post_schema import PostCreate

router = APIRouter(prefix="/posts", tags=["Posts"])

posts = []

@router.get("/")
def get_posts():
    return posts

@router.post("/")
def create_post(post: PostCreate):
    new_post = {
        "id": len(posts) + 1,
        **post.dict()
    }
    posts.append(new_post)
    return new_post

@router.delete("/{post_id}")
def delete_post(post_id: int):
    for post in posts:
        if post["id"] == post_id:
            posts.remove(post)
            return {"message": "Post deleted successfully"}

    raise HTTPException(status_code=404, detail="Post not found")