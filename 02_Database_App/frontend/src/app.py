import streamlit as st
import pyodbc

# Database connection details
server = "sqlserver-service"
database = "mydatabase"
username = "sa"
password = "YourPassword123"

st.title('Users')

# Connect to SQL Server
try:
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password}"
    )
    cursor = conn.cursor()

    # Fetch some data
    cursor.execute("SELECT TOP 10 * FROM users")
    rows = cursor.fetchall()

    st.write(rows)

except Exception as e:
    st.error(f"Database connection failed: {e}")
