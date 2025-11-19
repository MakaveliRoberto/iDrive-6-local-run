# Dockerfile for BMW iDrive 6 Local Web Interface
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install any additional dependencies if needed
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the system dump htdocs directory
COPY nbtevo-system-dump/sda32/opt/car/data/htdocs /app/htdocs

# Expose port 8080
EXPOSE 8080

# Set working directory to htdocs for serving
WORKDIR /app/htdocs

# Use Python's built-in HTTP server
CMD ["python3", "-m", "http.server", "8080", "--bind", "0.0.0.0"]

