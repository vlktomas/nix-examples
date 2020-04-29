from server.application.hello_service import say_hello

def hello(greeting=None):
    return say_hello(greeting)
