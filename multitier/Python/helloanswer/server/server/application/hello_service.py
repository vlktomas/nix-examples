from server.domain.hello_repository import get_hello

def say_hello(greeting):
    if greeting != None:
        return get_hello(greeting)
    else:
        return get_hello('World')
