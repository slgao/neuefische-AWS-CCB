import os


# function to check if the specified user exists using os.system
def user_exists(username):
    return os.system(f"id -u {username} > /dev/null 2>&1") == 0

def create_user_and_home(username):
    os.system(f"sudo useradd -m {username}")
    os.system(f"echo '{username}:password' | sudo chpasswd")
    print(f"User '{username}' and their home directory created.")
    return


def assign_user_home_dir(username):
    # Ensure the home directory is owned by the new user
    os.system(f"sudo chown {username}:{username} /home/{username}")
    print(f"Home directory for '{username}' is set up and owned by the user.")


def delete_user_and_home(username):
    if not user_exists(username):
        print(f"User '{username}' does not exist.")
        return
    else:
        # Delete user and their home directory
        print(f"Deleting user '{username}' and their home directory...")
        result = os.system(f"sudo userdel -r {username}")

    if result == 0:
        print(f"User '{username}' deleted successfully.")
    else:
        print(f"Failed to delete user '{username}'.")


def add_user_home():
    # Define the username
    username = input("Give a username you want to be created:")
    # Check if the user already exists
    if user_exists(username):
        print(f"User '{username}' already exists.")
    else:
        # Create the user and home directory
        create_user_and_home(username)
        assign_user_home_dir(username)


def del_user_home():
    # Define the username
    username = input("Give a username you want to be deleted:")
    delete_user_and_home(username)


if __name__ == "__main__":
    add_user_home()
    # del_suer_home()
