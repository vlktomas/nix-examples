import setuptools

setuptools.setup(
    name="hellolib",
    version="1.0",
    description="Hello library",
    long_description=
        """
        Library which provides hello greeting.
        """,
    url="https://example.com/",
    packages=[ 'hellolib' ],
    python_requires='>=3.5',
)
