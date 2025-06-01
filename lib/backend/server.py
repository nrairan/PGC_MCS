from flask import Flask, request, send_file

from process_image import process_image

app=Flask(__name__)

@app.route('/process', methods=['POST'])
def main():
    data=request.get_json()
    text=data.get('text')

    process_image(text,'App Logo - copia.png','App Logo - copia_text.png')

    return send_file()

if __name__ == '__main__':
    app.run(host='0.0.0', port=5000, debug=True)

