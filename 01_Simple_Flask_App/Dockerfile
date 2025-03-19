# Install base python image
FROM python:3.9

# Set working directory
WORKDIR /app

# Copy src code into working directory
COPY src/app.py .

# Copy requirements.txt file
COPY requirements.txt .

# Install container dependencies
RUN pip install -r requirements.txt

# Run Flask application
CMD ["python", "app.py"]
