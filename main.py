from weasyprint import HTML
from fastapi import FastAPI, Request, Response
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.gzip import GZipMiddleware
from fastapi import Body
from mangum import Mangum
import os
import json

app = FastAPI(title="Resume Generator")
handler = Mangum(app)

app.mount("/static", StaticFiles(directory="static"), name="static")
app.add_middleware(GZipMiddleware)

templates = Jinja2Templates(directory="templates")


@app.post("/")
async def index(request: Request, resume_data: dict = Body(...)):
    return templates.TemplateResponse(
        "base.html", {"request": request, "resumeData": resume_data}
    )

@app.get("/preview") 
async def preview(request: Request):
    # You can optionally provide default dummy data for development
    with open("./sample_input.json", "r") as f:
        resume_data = json.load(f)

    return templates.TemplateResponse(
        "base.html", {"request": request, "resumeData": resume_data}
    )


@app.post("/pdf")
async def generate_pdf(request: Request, resume_data: dict = Body(...)):
    # Render the HTML
    html_content = templates.get_template("base.html").render(
        {"request": request, "resumeData": resume_data}
    )

   # Use file URI base_url to resolve local static files
    base_path = os.path.abspath("static")  # absolute path to your static folder
    base_url = f"file://{base_path}/"

    # Generate PDF
    pdf_bytes = HTML(string=html_content, base_url=base_url).write_pdf()

    student_name = resume_data["personal"]["name"].replace(" ", "_")
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename={student_name}_Resume.pdf"
        },
    )