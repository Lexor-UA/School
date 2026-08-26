import json

files = ['uk.json', 'en.json', 'ru.json', 'de.json']

additions = {
    'uk': {
        'login_google': 'Увійти через Google',
        'login_email': 'Увійти через Email',
        'slogan': 'ПЛАВАЙ. ВДОСКОНАЛЮЙСЯ. НАДИХАЙ.',
        'welcome_back': 'З поверненням!',
        'login_desc': 'Увійдіть, щоб керувати заняттями,\nвідстежувати прогрес та досягати більшого.',
        'or': 'або',
        'feature_booking': 'Легке\nбронювання',
        'feature_progress': 'Трекінг\nпрогресу',
        'feature_goals': 'Досягнення\nцілей',
        'motto_bottom': 'Мистецтво води. Ваш шлях до досконалості.'
    },
    'en': {
        'login_google': 'Continue with Google',
        'login_email': 'Continue with Email',
        'slogan': 'SWIM. IMPROVE. INSPIRE.',
        'welcome_back': 'Welcome back!',
        'login_desc': 'Sign in to manage your lessons,\ntrack progress and achieve more.',
        'or': 'or',
        'feature_booking': 'Easy lesson\nbooking',
        'feature_progress': 'Track your\nprogress',
        'feature_goals': 'Achieve your\ngoals',
        'motto_bottom': 'The art of water. Your path to perfection.'
    },
    'ru': {
        'login_google': 'Войти через Google',
        'login_email': 'Войти через Email',
        'slogan': 'ПЛАВАЙ. СОВЕРШЕНСТВУЙСЯ. ВДОХНОВЛЯЙ.',
        'welcome_back': 'С возвращением!',
        'login_desc': 'Войдите, чтобы управлять занятиями,\nотслеживать прогресс и достигать большего.',
        'or': 'или',
        'feature_booking': 'Легкое\nбронирование',
        'feature_progress': 'Отслеживание\nпрогресса',
        'feature_goals': 'Достижение\nцелей',
        'motto_bottom': 'Искусство воды. Ваш путь к совершенству.'
    },
    'de': {
        'login_google': 'Weiter mit Google',
        'login_email': 'Weiter mit Email',
        'slogan': 'SCHWIMMEN. VERBESSERN. INSPIRIEREN.',
        'welcome_back': 'Willkommen zurück!',
        'login_desc': 'Melden Sie sich an, um Kurse zu verwalten,\nFortschritte zu verfolgen und mehr zu erreichen.',
        'or': 'oder',
        'feature_booking': 'Einfache\nBuchung',
        'feature_progress': 'Fortschritt\nverfolgen',
        'feature_goals': 'Ziele\nerreichen',
        'motto_bottom': 'Die Kunst des Wassers. Ihr Weg zur Perfektion.'
    }
}

for lang in files:
    path = f'c:/Users/Nelia/Desktop/School/assets/translations/{lang}'
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    lang_code = lang.split('.')[0]
    for k, v in additions[lang_code].items():
        data['auth'][k] = v
        
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Translations updated successfully.")
