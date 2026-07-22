from app import create_app, db
from app.models import User

app = create_app()

with app.app_context():
    # Create all tables
    db.create_all()
    
    # Check if admin exists, create if not
    admin = User.query.filter_by(email='admin@rescuesphere.in').first()
    if not admin:
        admin = User(
            email='admin@rescuesphere.in',
            first_name='Admin',
            last_name='User',
            mobile='+91 99999 99999',
            role='admin'
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print("✅ Admin user created: admin@rescuesphere.in / admin123")
    
    print("✅ Database tables created successfully!")