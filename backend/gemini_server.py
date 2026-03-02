import os

from flask import Flask, jsonify, request
from google import genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ.get('GEMINI_API_KEY')
if not api_key:
    raise RuntimeError('GEMINI_API_KEY is not set in environment variables.')

client = genai.Client(api_key=api_key)
BACKEND_VERSION = '2026-03-03-v4'
OFFLINE_FALLBACK_REPLY = (
    'AI is currently unavailable. Please try again tomorrow at exact 4:00pm.'
)
MODEL_CANDIDATES = [
    'gemini-2.5-flash',
    'models/gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'models/gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'models/gemini-2.0-flash',
]

app = Flask(__name__)


@app.get('/health')
def health():
    return jsonify({'status': 'ok', 'version': BACKEND_VERSION})


@app.get('/debug')
def debug():
    key = os.environ.get('GEMINI_API_KEY', '')
    key_tail = key[-4:] if len(key) >= 4 else 'none'
    return jsonify(
        {
            'status': 'ok',
            'version': BACKEND_VERSION,
            'model_candidates': MODEL_CANDIDATES,
            'api_key_tail': key_tail,
        }
    )


@app.post('/chat')
def chat():
    data = request.get_json(silent=True) or {}
    user_message = str(data.get('message', '')).strip()

    if not user_message:
        return jsonify({'error': 'message is required'}), 400

    try:
        print(f'Received message: {user_message[:120]}')
        response = _generate_reply(user_message)
        reply = (response.text or '').strip()
        return jsonify({'reply': reply})
    except Exception as error:
        print(f'Gemini error: {error}')
        if _is_quota_error(error):
            return jsonify(
                {
                    'reply': OFFLINE_FALLBACK_REPLY,
                    'fallback': True,
                    'reason': 'quota_exceeded',
                }
            )
        return jsonify({'error': f'failed to generate response: {error}'}), 500


def _generate_reply(user_message):
    errors = []

    for model_name in MODEL_CANDIDATES:
        try:
            return client.models.generate_content(
                model=model_name,
                contents=user_message,
            )
        except Exception as error:
            errors.append(f'{model_name}: {error}')

    raise RuntimeError(' | '.join(errors))


def _is_quota_error(error):
    error_text = str(error).lower()
    quota_signals = [
        'resource_exhausted',
        'quota exceeded',
        'rate limit',
        '429',
    ]
    return any(signal in error_text for signal in quota_signals)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
