#!/bin/env fish

if not set -q bot_token
    echo 'You need to pass the bot_token environment variable'
    exit 1
end

function send_message
    argparse 'chat-id=' 'text=' 'parse-mode=' -- $argv

    set ret (curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" \
        -F "chat_id=$_flag_chat_id" \
        -F "parse_mode=$_flag_parse_mode" \
        -F "text=$_flag_text")

    if [ (echo $ret | jq -r '.ok') = true ]
        return 0
    else
        return 1
    end
end

function get_updates
    argparse 'offset=' -- $argv

    set ret (curl -s -X POST "https://api.telegram.org/bot$bot_token/getUpdates" \
        -F "offset=$_flag_offset")

    if [ (echo $ret | jq -r '.ok') = true ]
        echo $ret | jq -r '.result'
        return 0
    else
        return 1
    end

end

function handle_update
    if [ (echo $argv | jq -r .message.chat.type) != private ]
        echo 'non-private message received, skipping...'
        return 0
    end

    set chat_id (echo $argv | jq -r .message.chat.id)
    set text (echo $argv | jq -r .message.text)

    switch $text
        case '/start'
            send_message --chat-id=$chat_id --text='hello, you started the bot'
        case 'hi'
            send_message --chat-id=$chat_id --text='hello'
    end
end

set last_offset 0

while true

    for update in (get_updates --offset=$last_offset | jq -c '.[]')
        set -g last_offset (math (echo $update | jq -r '.update_id') '+' '1')
        handle_update $update
    end
end
