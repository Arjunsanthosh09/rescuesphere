from app import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    first_name = db.Column(db.String(100))
    last_name = db.Column(db.String(100))
    mobile = db.Column(db.String(20))
    role = db.Column(db.Enum('citizen', 'rescue', 'admin'), nullable=False, default='citizen')
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check if password matches hash"""
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<User {self.email}>'


class Incident(db.Model):
    __tablename__ = 'incidents'
    
    id = db.Column(db.Integer, primary_key=True)
    incident_id = db.Column(db.String(20), unique=True, nullable=False)
    disaster_type = db.Column(db.String(50), nullable=False)
    severity = db.Column(db.Enum('critical', 'high', 'medium', 'low'), nullable=False)
    location = db.Column(db.String(255), nullable=False)
    district = db.Column(db.String(100))
    people_affected = db.Column(db.Integer, default=0)
    people_rescued = db.Column(db.Integer, default=0)
    status = db.Column(db.Enum('pending', 'assigned', 'in_progress', 'resolved'), default='pending')
    description = db.Column(db.Text)
    reported_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    assigned_team_id = db.Column(db.Integer, db.ForeignKey('rescue_teams.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Incident {self.incident_id}>'


class RescueTeam(db.Model):
    __tablename__ = 'rescue_teams'
    
    id = db.Column(db.Integer, primary_key=True)
    team_code = db.Column(db.String(20), unique=True, nullable=False)
    team_name = db.Column(db.String(255), nullable=False)
    leader_name = db.Column(db.String(255))
    member_count = db.Column(db.Integer, default=0)
    district = db.Column(db.String(100))
    is_available = db.Column(db.Boolean, default=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<RescueTeam {self.team_code}>'


class Resource(db.Model):
    __tablename__ = 'resources'
    
    id = db.Column(db.Integer, primary_key=True)
    resource_type = db.Column(db.Enum('personnel', 'vehicle', 'medical', 'supply', 'equipment'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    total = db.Column(db.Integer, default=0)
    deployed = db.Column(db.Integer, default=0)
    available = db.Column(db.Integer, default=0)
    district = db.Column(db.String(100))
    
    def __repr__(self):
        return f'<Resource {self.name}>'


class Shelter(db.Model):
    __tablename__ = 'shelters'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    address = db.Column(db.Text)
    district = db.Column(db.String(100))
    capacity = db.Column(db.Integer, default=0)
    occupied = db.Column(db.Integer, default=0)
    is_open = db.Column(db.Boolean, default=True)
    contact = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Shelter {self.name}>'


class Notification(db.Model):
    __tablename__ = 'notifications'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    message = db.Column(db.Text)
    type = db.Column(db.Enum('alert', 'info', 'update', 'warning'), default='info')
    is_read = db.Column(db.Boolean, default=False)
    link = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<Notification {self.title}>'