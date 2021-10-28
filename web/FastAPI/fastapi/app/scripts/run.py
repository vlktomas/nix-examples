import uvicorn


def dev():
    uvicorn.run("app.main:app", reload=True)

