import setuptools

setuptools.setup(
    name="client",
    version="1.0",
    description="Simple RPC client",
    long_description=
        """
        Simple RPC client which executes functions for hello greeting
        and answer to the ultimate question on RPC server and prints
        result.
        """,
    url="https://example.com/",
    install_requires=[ "rpyc" ],
    packages=[ 'client' ],
    python_requires='>=3.5',
    entry_points={
        'console_scripts': [
            'client = client.client:main'
        ]
    },
)
