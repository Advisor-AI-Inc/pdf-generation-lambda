import os
import uuid
from playwright.async_api import async_playwright
from fastapi import FastAPI, Request, Response
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.gzip import GZipMiddleware
from fastapi import Body
from mangum import Mangum

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


@app.post("/pdf")
async def generate_pdf(request: Request, resume_data: dict = Body(...)):
    # Render the HTML with resumeData
    html_content = templates.get_template("base.html").render(
        {"request": request, "resumeData": resume_data}
    )

    # Save HTML to a temp file
    temp_file = f"/tmp/resume-{uuid.uuid4().hex}.html"
    with open(temp_file, "w", encoding="utf-8") as f:
        f.write(html_content)

    # Generate PDF using Playwright
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        await page.goto(f"file://{os.path.abspath(temp_file)}")
        pdf_bytes = await page.pdf(format="A4", print_background=True)
        await browser.close()

    os.remove(temp_file)  # Clean up

    student_name = resume_data["personal"]["name"].replace(" ", "_")
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename={student_name}_Resume.pdf"
        },
    )
