class Post < ApplicationRecord
  after_create :instruct_bot

  def instruct_bot
    bot = Rails.application.config.telegram_bot
    token = Rails.application.credentials.dig(:telegram_bot)
    chat_id = '-4269585544'

    url = Rails.application.routes.url_helpers.post_url(self, host: 'https://0.0.0.0:3000')

    keyboard = [[
      Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Read this post', url: url)
    ]]

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

    bot.api.send_message(chat_id: chat_id, text: "New post created: *#{:title}*", reply_markup: markup, parse_mode: 'Markdown')
  end
end
