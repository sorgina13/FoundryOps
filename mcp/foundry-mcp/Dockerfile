FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir -e . && pip install uvicorn

# Copy source
COPY src/ src/

EXPOSE 8080

# Default: SSE transport on port 8080
ENV MCP_TRANSPORT=sse
ENV MCP_SERVER_PORT=8080
ENV LOG_LEVEL=INFO

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8080/health').raise_for_status()"

CMD ["python", "-m", "foundry_mcp"]
