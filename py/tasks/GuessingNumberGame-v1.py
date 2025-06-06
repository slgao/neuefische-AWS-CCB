import random

secret_number = random.randint(1, 10)
guess = None
# print(secret_number)
# add max number of attempts
max_attempts = 5
num_attempt = 0
while guess != secret_number:
    try:
        guess = int(input("Guess a number between 1 and 10: "))
        if guess == secret_number:
            print("You guessed it!")
        else:
            num_attempt += 1
            if num_attempt >= max_attempts:
                print(f"You've used all {max_attempts} attempts. The secret number was {secret_number}.")
                break
            elif guess < secret_number:
                print("Hint: The secret number is higher.")
            else:
                print("Hint: The secret number is lower.")
            print("Try again!")
                
    except  ValueError:
        print('This is not a number!!')
