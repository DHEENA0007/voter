import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "voting_backend.settings")
django.setup()

from django.contrib.auth.models import User

def seed_admin():
    username = 'admin'
    password = 'admin'  # Simple password as requested or implied for easy access
    email = 'admin@example.com'

    if not User.objects.filter(username=username).exists():
        User.objects.create_superuser(username, email, password)
        print(f"Superuser '{username}' created.")
    else:
        print(f"Superuser '{username}' already exists.")
        u = User.objects.get(username=username)
        u.set_password(password)
        u.save()
        print(f"Superuser '{username}' password updated.")

    # Write to user.txt in the root of the workspace
    # absolute path to be safe: /run/media/dheena/Leave you files/voter/user.txt
    file_path = '/run/media/dheena/Leave you files/voter/user.txt'
    with open(file_path, 'w') as f:
        f.write(f"Username: {username}\n")
        f.write(f"Password: {password}\n")
    print(f"Credentials saved to {file_path}")

if __name__ == '__main__':
    seed_admin()
