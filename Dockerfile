# Use AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.11

# Copy requirements and install dependencies
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt

# Copy your application code
COPY . ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (this replaces the Handler field)
CMD ["main.handler"]