import pytest

from calculator.calc import add, subtract, multiply, divide


def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0
    assert add(0, 0) == 0


def test_subtract():
    assert subtract(2, 1) == 1
    assert subtract(0, 0) == 0
    assert subtract(1, -1) == 2


def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(-1, 1) == -1
    assert multiply(0, 100) == 0


def test_divide():
    assert divide(6, 2) == 3
    assert divide(-6, 2) == -3
    assert divide(0, 1) == 0
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)
    with pytest.raises(TypeError):
        divide("a", "b")
