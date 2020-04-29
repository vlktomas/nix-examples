import setuptools

setuptools.setup(
    name="answer",
    version="1.0",
    description="Asnwer",
    long_description=
        """
        A program that prints answer to the ultimate question.
        """,
    url="https://example.com/",
    packages=[ 'answer' ],
    python_requires='>=3.5',
    entry_points={
        'console_scripts': [
            'answer = answer.__main__:main'
        ]
    },
)
