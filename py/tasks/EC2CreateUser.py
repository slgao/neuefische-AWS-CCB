import os
import subprocess


# function to check if the specified user exists using os.system
def user_exists(username, use_os=False):
    if use_os:
        return os.system(f"id -u {username} > /dev/null 2>&1") == 0
    else:
        try:
            subprocess.run(["id", "-u", username], capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False


def create_user_and_home(username, password="password123", use_os=False):
    if use_os:
        os.system(f"sudo useradd -m {username}")
        os.system(f"echo '{username}:{password}' | sudo chpasswd")
        print(f"User '{username}' and their home directory created.")
        return
    else:
        try:
            # Create user with home directory
            subprocess.run(["sudo", "useradd", "-m", username], check=True)
            # Set password for the user
            subprocess.run(
                ["sudo", "chpasswd"], input=f"{username}:{password}\n".encode(), check=True
            )
            print(f"User '{username}' and their home directory created.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to create user '{username}': {e}")
            return


def assign_user_home_dir(username, use_os=False):
    if use_os:
        # Ensure the home directory is owned by the new user
        os.system(f"sudo chown -R {username}:{username} /home/{username}")
        print(f"Home directory for '{username}' is set up and owned by the user.")
    else:
        try:
            subprocess.run(
                ["sudo", "chown", "-R", username + ":" + username, "/home/" + username],
                check=True,
            )
            print(f"Home directory for '{username}' is set up and owned by the user.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to set up home directory for '{username}': {e}")


def add_user_and_homedir():
    # Define the username
    username = input("Give a username you want to created:")
    # Check if the user already exists
    if user_exists(username):
        print(f"User '{username}' already exists.")
    else:
        # Create the user and home directory
        create_user_and_home(username)
        assign_user_home_dir(username)


if __name__ == "__main__":
    add_user_and_homedir()
