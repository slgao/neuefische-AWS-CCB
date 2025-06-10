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


def delete_user_and_home(username, use_os=False):
    if use_os:
        # Delete user and their home directory
        print(f"Deleting user '{username}' and their home directory...")
        result = os.system(f"sudo userdel -r {username}")
        if result == 0:
            print(f"User '{username}' deleted successfully.")
        else:
            print(f"Failed to delete user '{username}'.")

    else:
        try:
            subprocess.run(["sudo", "userdel", "-r", username], check=True)
            print(f"User '{username}' deleted successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to delete user '{username}': {e}")


def del_user_and_homedir():
    # Define the username
    username = input("Give a username you want to delete:")
    # Check if the user already exists
    if not user_exists(username):
        print(f"User '{username}' does not exist.")
        return
    delete_user_and_home(username)


if __name__ == "__main__":
    del_user_and_homedir()
