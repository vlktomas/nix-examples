from server.domain.answer_repository import get_answer_value

def compute_answer():
    answer = get_answer_value()
    return f"Answer to the Ultimate Question of Life, the Universe, and Everything: {answer.value}"
