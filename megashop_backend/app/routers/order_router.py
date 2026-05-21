from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/posts", tags=["Posts"])

posts = [
    {
        "id": 1,
        "user_id": "user_1",
        "caption": "New outfit today!",
        "image": "https://picsum.photos/300"
    }
]

@router.get("/")
def get_posts():
    return posts

@router.post("/")
def create_post(post: dict):
    new_post = {
        "id": len(posts) + 1,
        **post
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