class LineBotController < ApplicationController
  require "line/bot"

  skip_before_action :verify_authenticity_token

  def callback
    # LINEで送られてきたメッセージのデータを取得
    body = request.body.read

     # LINE以外からリクエストが来た場合 Error を返す
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request and return
    end

    # LINEで送られてきたメッセージを適切な形式に変形
    events = client.parse_events_from(body)

    events.each do |event|
      # LINE からテキストが送信された場合
      if (event.type === Line::Bot::Event::MessageType::Text)
        # LINE からテキストが送信されたときの処理を記述する
        message = event["message"]["text"]
        # binding.pry
        # 送信されたメッセージをデータベースに保存するコードを書こう
        @task = Task.create!(title: message)
        reply_message = {
           type: "text",
           text: "「#{message}を登録しました！" # LINE に返すメッセージを考えてみよう
         }
       client.reply_message(event["replyToken"], reply_message)
      end
    end

    # LINE の webhook API との連携をするために status code 200 を返す
    render json: { status: :ok }

  end

  private

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      end
    end

end
