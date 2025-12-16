from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import os
import time
from werkzeug.utils import secure_filename
from datetime import datetime

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024 * 1024  # 16GB max file size


@app.route('/')
def index():
    return send_from_directory('.', 'index.html')


@app.route('/upload', methods=['POST'])
def upload_file():
    start_time = time.time()

    if 'files' not in request.files:
        return jsonify({'error': 'No files provided'}), 400

    files = request.files.getlist('files')
    uploaded_files = []

    for file in files:
        if file.filename == '':
            continue

        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{filename}"

        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        file_size = os.path.getsize(filepath)
        uploaded_files.append({
            'filename': filename,
            'size': file_size
        })

    upload_time = time.time() - start_time

    return jsonify({
        'success': True,
        'files': uploaded_files,
        'upload_time': round(upload_time, 2),
        'count': len(uploaded_files)
    })


@app.route('/stats', methods=['GET'])
def get_stats():
    files = os.listdir(app.config['UPLOAD_FOLDER'])
    total_size = sum(
        os.path.getsize(os.path.join(app.config['UPLOAD_FOLDER'], f))
        for f in files
    )

    return jsonify({
        'file_count': len(files),
        'total_size': total_size,
        'total_size_mb': round(total_size / (1024 * 1024), 2)
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
