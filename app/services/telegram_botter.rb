require 'telegram/bot'
require 'openai'

# Services which start chatbot and run the api via the token established
class TelegramBotter
  def ask_openai(question)
    prompt = message.text.gsub('/question', '').strip

    open_ai_key = Rails.application.credentials.dig(:telegram_bot)

    client = Openai::Client.new(access_token: open_ai_key)

    response = Client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
        max_token: 50,
      }
    )

    response
  end

  def start_bot(token)
    Telegram::Bot::Client.run(token) do |bot|
      Rails.application.config.telegram_bot = bot
      bot.api.get_updates(offset: -1)

      bot.listen do |message|
        puts "Received message: #{message}"
        if message.text.start_with?('/question')
          puts "You asked a question in the chat with id: #{message.chat.id}"
          response = ask_openai(message)
          if response
            bot.api.send_message(chat_id: message.chat.id, text: response.dig("choices", 0, "message", "content") || "No response")
          else
            bot.api.send_message(chat_id: message.chat.id, text: 'Error processing your request')
          end
        end
      end
    end
  end
  rescue Telegram::Bot::Exceptions::ResponseError => e
    Rails.logger.error e
    Rails.application.config.telegram_bot.stop
    Rails.application.config.telegram_bot.api.delete_webhook

  Signal.trap("TERM") do
    puts "Shutting down bot..."
    Rails.application.config.telegram_bot.stop
    exit
  end

  Signal.trap("INT") do
    puts "Shutting down bot..."
    Rails.application.config.telegram_bot.stop
    exit
  end
end
