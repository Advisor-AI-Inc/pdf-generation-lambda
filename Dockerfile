# Base Lambda Python 3.11 image
FROM public.ecr.aws/lambda/python:3.11

# Set working directory
WORKDIR /var/task

# Copy app code and requirements
COPY . .
COPY requirements.txt .

# Install system packages needed by WeasyPrint
# Install system packages needed by WeasyPrint
RUN yum install -y \
    cairo \
    pango \
    gdk-pixbuf2 \
    libffi \
    libxml2 \
    libxslt \
    libjpeg-turbo \
    fontconfig \
    freetype \
    && yum clean all

# Create fonts directory and copy custom fonts
RUN mkdir -p /usr/share/fonts/custom
COPY fonts/*.ttf /usr/share/fonts/custom/

# Rebuild font cache so WeasyPrint can find them
RUN fc-cache -f -v

# Install Python dependencies into Lambda's default directory
RUN pip install -r requirements.txt --target .

# Define the Lambda handler
CMD ["main.handler"]
