import logging
import json
import os
from datetime import datetime
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes
from config import BOT_TOKEN, CHANNEL_ID, CHANNEL_ID_NUMERIC, PROJECTS_INFO, CATEGORIES, ADMIN_IDS

# Настройка логирования
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Файл для хранения данных о пользователях (абсолютный путь)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
USERS_FILE = os.path.join(BASE_DIR, 'users_data.json')

def load_users_data():
    """Загружает данные о пользователях из файла"""
    if os.path.exists(USERS_FILE):
        try:
            with open(USERS_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Ошибка при загрузке данных пользователей: {e}")
            return {}
    return {}

def save_users_data(users_data):
    """Сохраняет данные о пользователях в файл"""
    try:
        with open(USERS_FILE, 'w', encoding='utf-8') as f:
            json.dump(users_data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.error(f"Ошибка при сохранении данных пользователей: {e}")

def save_user(user_id, username, first_name, last_name=None):
    """Сохраняет информацию о пользователе"""
    users_data = load_users_data()
    
    if str(user_id) not in users_data:
        users_data[str(user_id)] = {
            'username': username,
            'first_name': first_name,
            'last_name': last_name,
            'first_seen': datetime.now().isoformat(),
            'last_seen': datetime.now().isoformat(),
            'total_interactions': 0
        }
    else:
        users_data[str(user_id)]['last_seen'] = datetime.now().isoformat()
        users_data[str(user_id)]['total_interactions'] = users_data[str(user_id)].get('total_interactions', 0) + 1
    
    save_users_data(users_data)

async def check_subscription(update: Update, context: ContextTypes.DEFAULT_TYPE) -> bool:
    """Проверяет, подписан ли пользователь на канал"""
    try:
        user_id = update.effective_user.id
        logger.info(f"Проверяем подписку пользователя {user_id} на канал {CHANNEL_ID}")
        
        # Используем числовой ID канала для более надежной проверки
        channel_id = CHANNEL_ID_NUMERIC if CHANNEL_ID_NUMERIC else CHANNEL_ID
        
        # Пробуем получить информацию о пользователе в канале
        member = await context.bot.get_chat_member(channel_id, user_id)
        logger.info(f"Статус пользователя в канале: {member.status}")
        
        # Проверяем статус подписки
        is_subscribed = member.status in ['member', 'administrator', 'creator']
        logger.info(f"Пользователь подписан: {is_subscribed}")
        
        return is_subscribed
    except Exception as e:
        logger.error(f"Ошибка при проверке подписки: {e}")
        # В случае ошибки считаем, что пользователь не подписан
        return False

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /start"""
    user = update.effective_user
    logger.info(f"Пользователь {user.first_name} (ID: {user.id}) запустил бота")
    
    # Сохраняем информацию о пользователе
    save_user(user.id, user.username or '', user.first_name or '', user.last_name)
    
    # Проверяем подписку на канал
    is_subscribed = await check_subscription(update, context)
    logger.info(f"Результат проверки подписки: {is_subscribed}")
    
    if not is_subscribed:
        keyboard = [
            [InlineKeyboardButton("📢 Подписаться на канал", url="https://t.me/robsvrtg")],
            [InlineKeyboardButton("🔄 Проверить подписку", callback_data="check_subscription")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        channel_link = f"https://t.me/{CHANNEL_ID.replace('@', '')}"
        await update.message.reply_text(
            f"Привет, {user.first_name}! 👋\n\n"
            f"Для использования бота необходимо подписаться на наш канал: {CHANNEL_ID}\n\n"
            "После подписки нажмите кнопку 'Проверить подписку' или команду /start для продолжения.",
            reply_markup=reply_markup
        )
        return
    
    # Если пользователь подписан, показываем главное меню
    logger.info("Пользователь подписан, показываем главное меню")
    await show_main_menu(update, context)

async def show_main_menu(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Показывает главное меню с кнопками категорий"""
    keyboard = [
        [InlineKeyboardButton("📈 Фарм поинтов трейдингом", callback_data="category_trading")],
        [InlineKeyboardButton("💰 Фарм стейблкоинами (стейкинг)", callback_data="category_staking")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    text = (
        "🤖 <b>Добро пожаловать в Perps Farming бот </b>\n\n"
        "Мы предоставляем информацию о Perp DEX проектах, в которых сейчас идут кампании по фармингу поинтов или токенов.\n\n"
        "<b>Следить за обновлениями проекта можно тут: t.me/perpsfarming</b>\n\n"
        "Будем благодарны за любые отзывы и предложения по улучшению бота.\n\n"
        "Если вы отрабатываете конкретный проект и у вас есть информация по поинтам, будем благодарны если поделитесь с нами.\n\n"
        "Писать сюда: @RobSVR\n\n"
        "<b>⬇️Выберите тип фарминга из двух вариантов ниже⬇️</b>"
    )
    
    if update.callback_query:
        await update.callback_query.edit_message_text(
            text=text,
            reply_markup=reply_markup,
            parse_mode='HTML'
        )
    else:
        await update.message.reply_text(
            text=text,
            reply_markup=reply_markup,
            parse_mode='HTML'
        )

async def show_category_projects(update: Update, context: ContextTypes.DEFAULT_TYPE, category: str) -> None:
    """Показывает проекты в выбранной категории"""
    query = update.callback_query
    await query.answer()
    
    if category not in CATEGORIES:
        await query.edit_message_text("❌ Категория не найдена.")
        return
    
    category_info = CATEGORIES[category]
    projects = category_info['projects']
    
    # Создаем кнопки для проектов в категории
    keyboard = []
    
    # Добавляем специальную кнопку для категории trading
    if category == 'trading':
        keyboard.append([InlineKeyboardButton("📈 Стратегии торговли для поинтов", callback_data="trading_strategies")])
        keyboard.append([])  # Пустая строка для разделения
    
    for project_key in projects:
        if project_key in PROJECTS_INFO and category in PROJECTS_INFO[project_key]['categories']:
            project_name = PROJECTS_INFO[project_key]['name']
            # Добавляем эмодзи для каждого проекта
            emoji_map = {
                'backpack': '🎒',
                'lighter': '🔥',
                'aster': '⭐',
                'avantis': '🚀'
            }
            emoji = emoji_map.get(project_key, '📊')
            keyboard.append([InlineKeyboardButton(f"{emoji} {project_name}", callback_data=f"project_{project_key}_{category}")])
    
    # Добавляем кнопку "Назад"
    keyboard.append([InlineKeyboardButton("🔙 Назад к категориям", callback_data="back_to_categories")])
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    if category == 'trading':
        text = (
            f"📊 <b>{category_info['name']}</b>\n\n"
            "В этой категории проекты отрабатываются путем трейдинга токенов. Чаще всего от вас требуется как можно больше торговать(набивать большой объем торговли), плюс дополнительные факторы.\n\n"
            "От проекта к проекту факторы торговли влияющие на количество поинтов/очков/токенов меняются.\n\n"
            "<b>Внутри каждого проекта вы найдете:</b>\n"
            "1. Общая информация по проекту\n"
            "2. Информацию по получению поинтов\n"
            "3. Цена поинта на пре-маркете(если есть)\n"
            "4. More... Coming soon...\n\n"
            "<b>Выберите проект для получения подробной информации:</b>"
        )
    elif category == 'staking':
        text = (
            f"📊 <b>{category_info['name']}</b>\n\n"
            "В этой категории мы можем зарабатывать поинты/прибыль в проекте путем стейка наших стейблкоинов(USDC/USDT и так далее).\n\n"
            "Условия и доходность отличаются от проекта к проекту.\n\n"
            "Все проекты дают какую-то доходность, но не все проекты выделяют поинты/токены на будущие дропы для стейкинга.\n\n"
            "<b>Внутри каждого проекта вы найдете:</b>\n"
            "1. Общая информация по проекту\n"
            "2. Какая награда\n"
            "3. Доходность\n"
            "4. More... Coming soon...\n\n"
            "<b>Выберите проект для получения подробной информации:</b>"
        )
    else:
        text = f"📊 <b>{category_info['name']}</b>\n\nВыберите проект для получения подробной информации:"
    
    await query.edit_message_text(
        text=text,
        reply_markup=reply_markup,
        parse_mode='HTML'
    )

async def handle_category_selection(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик выбора категории"""
    query = update.callback_query
    await query.answer()
    
    # Извлекаем категорию из callback_data
    # Формат: category_{category_name}
    category = query.data.replace("category_", "")
    
    await show_category_projects(update, context, category)

async def handle_project_info(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик нажатий на кнопки проектов"""
    query = update.callback_query
    await query.answer()
    
    
    # Извлекаем название проекта и категорию из callback_data
    # Формат: project_{project_key}_{category}
    parts = query.data.split("_")
    if len(parts) < 3:
        await query.edit_message_text("❌ Неверный формат данных.")
        return
    
    project_key = parts[1]
    category = parts[2]
    
    if project_key not in PROJECTS_INFO:
        await query.edit_message_text("❌ Проект не найден.")
        return
    
    if category not in PROJECTS_INFO[project_key]['categories']:
        await query.edit_message_text("❌ Категория не найдена для этого проекта.")
        return
    
    project = PROJECTS_INFO[project_key]
    project_category_info = project['categories'][category]
    
    # Создаем клавиатуру с кнопками
    keyboard = [
        [InlineKeyboardButton("🌐 Веб-сайт", url=project_category_info['website'])],
     [InlineKeyboardButton("🔙 Назад к проектам", callback_data=f"category_{category}")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    text = (
        f"📊 <b>{project['name']}</b>\n\n"
        f"{project_category_info['description']}"
    )
    
    await query.edit_message_text(
        text=text,
        reply_markup=reply_markup,
        parse_mode='HTML'
    )

async def check_subscription_callback(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик кнопки проверки подписки"""
    query = update.callback_query
    await query.answer()
    
    # Проверяем подписку заново
    is_subscribed = await check_subscription(update, context)
    
    if is_subscribed:
        await query.edit_message_text("✅ Отлично! Вы подписаны на канал. Переходим к главному меню...")
        await show_main_menu(update, context)
    else:
        keyboard = [
            [InlineKeyboardButton("📢 Подписаться на канал", url="https://t.me/robsvrtg")],
            [InlineKeyboardButton("🔄 Проверить подписку", callback_data="check_subscription")]
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await query.edit_message_text(
            f"❌ Вы еще не подписаны на канал {CHANNEL_ID}\n\n"
            "Пожалуйста, подпишитесь на канал и нажмите кнопку 'Проверить подписку'.",
            reply_markup=reply_markup
        )

async def back_to_menu(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Возврат к главному меню"""
    query = update.callback_query
    await query.answer()
    await show_main_menu(update, context)

async def back_to_categories(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Возврат к категориям"""
    query = update.callback_query
    await query.answer()
    await show_main_menu(update, context)

async def show_trading_strategies(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Показывает стратегии торговли для поинтов"""
    query = update.callback_query
    await query.answer()
    
    text = (
        "📈 <b>Стратегии торговли для получения поинтов:</b>\n\n"
        "<b>1. Классическая торговля</b>\n"
        "Если вы умеете торговать в плюс, поздравляю, просто торгуйте как и обычно, вдобавок получая поинты.\n"
        "Вероятнее всего лучшая стратегия - скальпинг, так как позволяет набивать объемы.\n\n"
        "<b>2. Дельта нейтральная стратегия</b>\n"
        "Лучшая для тех, кто не умеет торговать.\n\n"
        "Суть стратегии - вставать в противоположные сделки на разных биржах.\n"
        "На одной бирже встаете в шорт, на другой в лонг. Потом одновременно закрываете.\n"
        "Теряете на комиссиях, но при этом почти независимы от движения курса вверх-вниз.\n\n"
        "<b>3. Набивание объема</b>\n"
        "Встаем в шорт/лонг и через пару секунд закрываем сделку.\n\n"
        "Из плюсов, так вы сможете быстро набить объем, возможно с минимальными потерями. "
        "Но при этом вы 100% теряете деньги как минимум на комиссиях и проект может не выдать за это поинты."
    )
    
    # Создаем клавиатуру с кнопкой "Назад"
    keyboard = [
        [InlineKeyboardButton("🔙 Назад к проектам", callback_data="category_trading")]
    ]
    reply_markup = InlineKeyboardMarkup(keyboard)
    
    await query.edit_message_text(
        text=text,
        reply_markup=reply_markup,
        parse_mode='HTML'
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /help"""
    help_text = (
        "🤖 <b>Справка по боту</b>\n\n"
        "<b>Доступные команды:</b>\n"
        "/start - Запустить бота и показать главное меню\n"
        "/help - Показать эту справку\n\n"
        "<b>Как пользоваться:</b>\n"
        "1. Подпишитесь на наш канал\n"
        "2. Нажмите /start\n"
        "3. Выберите интересующий проект\n"
        "4. Получите подробную информацию\n\n"
        "<b>Поддерживаемые проекты:</b>\n"
        "• Backpack, Lighter, Aster, Avantis"
    )
    
    await update.message.reply_text(help_text, parse_mode='HTML')

async def stats_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /stats - показывает статистику пользователей"""
    user = update.effective_user
    
    # Проверяем, является ли пользователь администратором
    if ADMIN_IDS and user.id not in ADMIN_IDS:
        await update.message.reply_text("❌ У вас нет прав для выполнения этой команды.")
        return
    
    users_data = load_users_data()
    total_users = len(users_data)
    
    if total_users == 0:
        await update.message.reply_text("📊 <b>Статистика бота</b>\n\n" + "Пользователей пока нет.", parse_mode='HTML')
        return
    
    # Подсчитываем активных пользователей (которые использовали бота за последние 7 дней)
    from datetime import datetime, timedelta
    week_ago = (datetime.now() - timedelta(days=7)).isoformat()
    active_users = sum(1 for user_info in users_data.values() if user_info.get('last_seen', '') >= week_ago)
    
    # Подсчитываем общее количество взаимодействий
    total_interactions = sum(user_info.get('total_interactions', 0) for user_info in users_data.values())
    
    stats_text = (
        "📊 <b>Статистика бота</b>\n\n"
        f"👥 <b>Всего пользователей:</b> {total_users}\n"
        f"🟢 <b>Активных за неделю:</b> {active_users}\n"
        f"💬 <b>Всего взаимодействий:</b> {total_interactions}\n"
    )
    
    await update.message.reply_text(stats_text, parse_mode='HTML')

def main() -> None:
    """Основная функция запуска бота"""
    if not BOT_TOKEN:
        logger.error("BOT_TOKEN не установлен! Создайте файл .env с токеном бота.")
        return
    
    # Создаем приложение
    application = Application.builder().token(BOT_TOKEN).build()
    
    # Добавляем обработчики
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("stats", stats_command))
    application.add_handler(CallbackQueryHandler(handle_project_info, pattern="^project_"))
    application.add_handler(CallbackQueryHandler(handle_category_selection, pattern="^category_"))
    application.add_handler(CallbackQueryHandler(show_trading_strategies, pattern="^trading_strategies$"))
    application.add_handler(CallbackQueryHandler(back_to_menu, pattern="^back_to_menu$"))
    application.add_handler(CallbackQueryHandler(back_to_categories, pattern="^back_to_categories$"))
    application.add_handler(CallbackQueryHandler(check_subscription_callback, pattern="^check_subscription$"))
    
    # Запускаем бота
    logger.info("Бот запущен...")
    application.run_polling()

if __name__ == '__main__':
    main()
