from flask import Flask, request, jsonify
from flask_cors import CORS
import pyodbc
import os
from dotenv import load_dotenv

load_dotenv()  # Carga variables desde .env si existe

app = Flask(__name__)
CORS(app)

# Cargar credenciales desde variables de entorno
db_server = os.getenv("DB_SERVER")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")

# Cadena de conexión
conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={db_server};"
    f"DATABASE={db_name};"
    f"UID={db_user};"
    f"PWD={db_password};"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
except Exception as e:
    print("❌ Error al conectar con SQL Server:", e)
    exit(1)

if __name__ == '_main_':
    app.run(host='0.0.0', port=5000, debug=True)
