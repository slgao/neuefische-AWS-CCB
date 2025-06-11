# Function to check if a number is prime
def is_prime(n):
    # A prime number is a natural number greater than 1 that
    # is not a product of two smaller natural numbers.
    if n <= 1:
        return False
    # 2 and 3 are prime numbers
    elif n <= 3:
        return True
    for i in range(2, int(n**.5) + 1):
        if n % i == 0:
            return False
    return True

def create_file_with_content(str_content, file_name="./results.txt", mode="w"):
    with open(file_name, mode) as file:
        file.write(str_content)



def main():
    max_num_prime_per_line = 15
    file_name = "./results.txt"
    # Print 1 to 250
    num_prime_per_line = 0
    create_file_with_content("Show prime numbers from 1 to 250:\n", file_name=file_name)
    for i in range(1, 251):
        # Check if the number is prime
        if is_prime(i):
            # Write the number into a txt file
            with open("./results.txt", "a") as file:
                file.write(f"{i}  ")
                num_prime_per_line += 1
                # If the number of prime number exceeds the max number, print in a newline
                if num_prime_per_line == max_num_prime_per_line:
                    file.write("\n")
                    num_prime_per_line = 0


if __name__ == "__main__":
    main()
