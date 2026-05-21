from fastapi import APIRouter, HTTPException
from app.schemas.post_schema import PostCreate

router = APIRouter(prefix="/posts", tags=["Posts"])

posts = [
    {
        "id": 1,
        "user_id": "user_1",
        "caption": "New outfit today!",
        "image": "https://picsum.photos/600"
    }
]

@router.get("/")
def get_posts():
    return posts

@router.get("/{post_id}")
def get_post(post_id: int):
    for post in posts:
        if post["id"] == post_id:
            return post
    raise HTTPException(status_code=404, detail="Post not found")

@router.post("/")
def create_post(post: PostCreate):
    new_post = {
        "id": len(posts) + 1,
        **post.dict()
    }
    posts.append(new_post)
    return {
        "message": "Post created successfully",
        "data": new_post
    }

@router.put("/{post_id}")
def update_post(post_id: int, updated_post: PostCreate):
    for post in posts:
        if post["id"] == post_id:
            post.update(updated_post.dict())
            return {
                "message": "Post updated successfully",
                "data": post
            }
    raise HTTPException(status_code=404, detail="Post not found")

@router.delete("/{post_id}")
def delete_post(post_id: int):
    for post in posts:
        if post["id"] == post_id:
            posts.remove(post)
            return {
                "message": "Post deleted successfully"
            }
    raise HTTPException(status_code=404, detail="Post not found")