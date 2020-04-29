from answerlib import answer
from server.domain.answer import Answer

def get_answer_value():
    value = answer()
    return Answer(value)
