from app import create_app, db
from app.models import User
import sys

app = create_app()

with app.app_context():
    email = input("Enter email: ")
    new_password = input("Enter new password: ")
    
    user = User.query.filter_by(email=email).first()
    if user:
        user.set_password(new_password)
        db.session.commit()
        print(f"✅ Password updated for {email}")
    else:
        print(f"❌ User {email} not found")