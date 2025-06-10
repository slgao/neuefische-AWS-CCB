# Define add, subtract, multiply, and divide functions
def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b


# Define a main function to demonstrate the calculator
def main():
    print("Simple Calculator")
    print("Enter two numbers:")
    try:
        a = float(input("First number: "))
        b = float(input("Second number: "))

        print("\nChoose an operation:")
        print("1. Add")
        print("2. Subtract")
        print("3. Multiply")
        print("4. Divide")

        choice = input("Enter your choice (1/2/3/4): ")

        if choice == "1":
            result = add(a, b)
            operation = "Addition"
        elif choice == "2":
            result = subtract(a, b)
            operation = "Subtraction"
        elif choice == "3":
            result = multiply(a, b)
            operation = "Multiplication"
        elif choice == "4":
            result = divide(a, b)
            operation = "Division"
        else:
            print("Invalid choice!")
            return

        print(f"\n{operation} Result: {result}")

    except ValueError:
        print("Invalid input! Please enter numeric values.")
    except ZeroDivisionError as e:
        print(e)


if __name__ == "__main__":
    main()
