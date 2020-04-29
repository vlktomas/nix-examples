import setuptools

setuptools.setup(
    name="server",
    version="1.0",
    description="Simple RPC server",
    long_description=
        """
        Simple RPC server which exposes functions to get hello greeting
        and answer to the ultimate question.
        """,
    url="https://example.com/",
    install_requires=[ "rpyc", "hellolib", "answerlib" ],
    packages=[ 'server', 'server.application', 'server.domain', 'server.presentation' ],
    python_requires='>=3.5',
    entry_points={
        'console_scripts': [
            'server = server.server:main'
        ]
    },
)
