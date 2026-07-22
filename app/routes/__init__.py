from flask import Blueprint, render_template, request, session, redirect, url_for, flash, jsonify
from app.models import User, Incident, RescueTeam
from app import db
from werkzeug.security import generate_password_hash, check_password_hash
import re

main_bp = Blueprint('main', __name__)


# =============================================
# HOME PAGE
# =============================================

@main_bp.route('/')
def index():
    """Homepage - base.html"""
    return render_template('base.html')


@main_bp.route('/home')
def home():
    return redirect(url_for('main.index'))


# =============================================
# AUTHENTICATION ROUTES
# =============================================

@main_bp.route('/login', methods=['POST'])
def login():
    """Handle user login"""
    email = request.form.get('email')
    password = request.form.get('password')
    
    # Validate input
    if not email or not password:
        flash('Please provide both email and password.', 'danger')
        return render_template('base.html')
    
    # Find user by email
    user = User.query.filter_by(email=email).first()
    
    # Check if user exists and password is correct
    if user and user.check_password(password):
        # Store user in session
        session['user_id'] = user.id
        session['user_role'] = user.role
        session['user_name'] = user.first_name
        session['user_email'] = user.email
        session['logged_in'] = True
        
        flash(f'Welcome back, {user.first_name}!', 'success')
        
        # Redirect based on role
        if user.role == 'citizen':
            return redirect(url_for('main.citizen_dashboard'))
        elif user.role == 'rescue':
            return redirect(url_for('main.rescue_dashboard'))
        elif user.role == 'admin':
            return redirect(url_for('main.admin_dashboard'))
    else:
        flash('Invalid email or password. Please try again.', 'danger')
        return render_template('base.html')


@main_bp.route('/register', methods=['POST'])
def register():
    """Handle user registration"""
    # Get form data
    fullname = request.form.get('fullname')
    email = request.form.get('email')
    phone = request.form.get('phone')
    password = request.form.get('password')
    confirm_password = request.form.get('confirm_password')
    role = request.form.get('role', 'citizen')
    organization = request.form.get('organization', '')
    
    # =============================================
    # VALIDATION
    # =============================================
    
    # Check all required fields
    if not fullname or not email or not phone or not password:
        flash('All fields are required.', 'danger')
        return render_template('base.html')
    
    # Validate email format
    email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(email_pattern, email):
        flash('Please enter a valid email address.', 'danger')
        return render_template('base.html')
    
    # Validate password length
    if len(password) < 6:
        flash('Password must be at least 6 characters long.', 'danger')
        return render_template('base.html')
    
    # Check if passwords match
    if password != confirm_password:
        flash('Passwords do not match.', 'danger')
        return render_template('base.html')
    
    # Validate phone number (basic validation)
    if len(phone) < 10:
        flash('Please enter a valid phone number.', 'danger')
        return render_template('base.html')
    
    # Validate role
    if role not in ['citizen', 'rescue']:
        flash('Invalid role selected.', 'danger')
        return render_template('base.html')
    
    # =============================================
    # CHECK FOR EXISTING USER
    # =============================================
    
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        flash('This email is already registered. Please login or use a different email.', 'danger')
        return render_template('base.html')
    
    # =============================================
    # CREATE NEW USER
    # =============================================
    
    try:
        new_user = User(
            email=email,
            first_name=fullname,
            mobile=phone,
            role=role
        )
        new_user.set_password(password)
        
        db.session.add(new_user)
        db.session.commit()
        
        flash('Registration successful! Please login to continue.', 'success')
        return render_template('base.html')
    
    except Exception as e:
        db.session.rollback()
        flash(f'An error occurred: {str(e)}', 'danger')
        return render_template('base.html')


@main_bp.route('/logout')
def logout():
    """Logout user"""
    session.clear()
    flash('You have been logged out successfully.', 'info')
    return redirect(url_for('main.index'))


# =============================================
# DASHBOARD ROUTES (Role-Specific Templates)
# =============================================

@main_bp.route('/citizen/dashboard')
def citizen_dashboard():
    """Citizen dashboard"""
    if 'user_id' not in session or session.get('user_role') != 'citizen':
        flash('Please login as a citizen to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('citizen/dashboard.html', user=user)


@main_bp.route('/rescue/dashboard')
def rescue_dashboard():
    """Rescue team dashboard"""
    if 'user_id' not in session or session.get('user_role') != 'rescue':
        flash('Please login as a rescue team member to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('rescue/dashboard.html', user=user)


@main_bp.route('/admin/dashboard')
def admin_dashboard():
    """Admin dashboard"""
    if 'user_id' not in session or session.get('user_role') != 'admin':
        flash('Please login as an administrator to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('admin/dashboard.html', user=user)


# =============================================
# CITIZEN ROUTES
# =============================================

@main_bp.route('/citizen/report')
def citizen_report():
    """Citizen report emergency page"""
    if 'user_id' not in session or session.get('user_role') != 'citizen':
        flash('Please login as a citizen to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('citizen/report.html', user=user)


@main_bp.route('/citizen/status')
def citizen_status():
    """Citizen request status page"""
    if 'user_id' not in session or session.get('user_role') != 'citizen':
        flash('Please login as a citizen to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('citizen/status.html', user=user)


@main_bp.route('/citizen/notifications')
def citizen_notifications():
    """Citizen notifications page"""
    if 'user_id' not in session or session.get('user_role') != 'citizen':
        flash('Please login as a citizen to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('citizen/notifications.html', user=user)


# =============================================
# RESCUE TEAM ROUTES
# =============================================

@main_bp.route('/rescue/missions')
def rescue_missions():
    """Rescue team missions page"""
    if 'user_id' not in session or session.get('user_role') != 'rescue':
        flash('Please login as a rescue team member to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('rescue/missions.html', user=user)


@main_bp.route('/rescue/incidents')
def rescue_incidents():
    """Rescue team nearby incidents page"""
    if 'user_id' not in session or session.get('user_role') != 'rescue':
        flash('Please login as a rescue team member to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('rescue/incidents.html', user=user)


@main_bp.route('/rescue/notifications')
def rescue_notifications():
    """Rescue team notifications page"""
    if 'user_id' not in session or session.get('user_role') != 'rescue':
        flash('Please login as a rescue team member to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('rescue/notifications.html', user=user)


# =============================================
# ADMIN ROUTES
# =============================================

@main_bp.route('/admin/incidents')
def admin_incidents():
    """Admin incidents management page"""
    if 'user_id' not in session or session.get('user_role') != 'admin':
        flash('Please login as an administrator to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('admin/incidents.html', user=user)


@main_bp.route('/admin/resources')
def admin_resources():
    """Admin resources management page"""
    if 'user_id' not in session or session.get('user_role') != 'admin':
        flash('Please login as an administrator to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('admin/resources.html', user=user)


@main_bp.route('/admin/analytics')
def admin_analytics():
    """Admin analytics page"""
    if 'user_id' not in session or session.get('user_role') != 'admin':
        flash('Please login as an administrator to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('admin/analytics.html', user=user)


@main_bp.route('/admin/notifications')
def admin_notifications():
    """Admin notifications page"""
    if 'user_id' not in session or session.get('user_role') != 'admin':
        flash('Please login as an administrator to access this page.', 'warning')
        return redirect(url_for('main.index'))
    
    user = User.query.get(session['user_id'])
    return render_template('admin/notifications.html', user=user)


# =============================================
# API ROUTES (For AJAX calls)
# =============================================

@main_bp.route('/api/check_session')
def check_session():
    """Check if user is logged in"""
    if 'user_id' in session:
        return jsonify({
            'logged_in': True,
            'user': {
                'id': session['user_id'],
                'name': session.get('user_name'),
                'role': session.get('user_role'),
                'email': session.get('user_email')
            }
        })
    return jsonify({'logged_in': False})


@main_bp.route('/api/stats')
def api_stats():
    """Get system stats"""
    try:
        stats = {
            'total_incidents': Incident.query.count(),
            'active_incidents': Incident.query.filter(Incident.status != 'resolved').count(),
            'total_users': User.query.count(),
            'active_teams': RescueTeam.query.filter_by(is_available=True).count()
        }
        return jsonify(stats)
    except:
        return jsonify({
            'total_incidents': 0,
            'active_incidents': 0,
            'total_users': 0,
            'active_teams': 0
        })