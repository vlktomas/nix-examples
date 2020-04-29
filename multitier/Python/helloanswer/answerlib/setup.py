import setuptools

setuptools.setup(
    name="answerlib",
    version="1.0",
    description="Answer library",
    long_description=
        """
        Library which provides answer to the ultimate question.
        """,
    url="https://example.com/",
    install_requires=[ "numpy" ],
    packages=[ 'answerlib' ],
    python_requires='>=3.5',
)
