from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user_models import User, Admin
from app.core.constants import UserRole


def main():
    db = SessionLocal()

    try:
        # هل فيه Admin موجود؟
        existing = db.query(User).filter(User.role == UserRole.ADMIN).first()
        if existing:
            print("⚠ Admin already exists:", existing.email)
            return

        user = User(
            email="admin@system.com",
            password_hash=hash_password("admin123!"),
            role=UserRole.ADMIN,
            is_active=True,
        )
        db.add(user)
        db.flush()  # للحصول على user.id

        admin = Admin(
            user_id=user.id,
            first_name="System",
            last_name="Admin",
        )
        db.add(admin)
        db.commit()

        print("====================================")
        print(" Super Admin Bootstrapped ")
        print("====================================")
        print("Email: admin@system.com")
        print("Password: admin123!")
        print("====================================")

    except Exception as e:
        db.rollback()
        print("❌ Bootstrap failed:", e)
    finally:
        db.close()


if __name__ == "__main__":
    main()