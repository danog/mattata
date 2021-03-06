local cats = {}
local HTTP = require('socket.http')
local functions = require('functions')
local telegram_api = require('telegram_api')
function cats:init(configuration)
	cats.command = 'cat'
	cats.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('cat').table
	cats.documentation = configuration.command_prefix .. 'cat - A random picture of a cat!'
end
function cats:action(msg, configuration)
	local api = configuration.apis.cats .. '&api_key=' .. configuration.keys.cats
	local str, res = HTTP.request(api)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	str = str:match('<img src="(.-)">')
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	functions.send_photo(msg.chat.id, functions.download_to_file(str), 'Meow!', msg.message_id)
end
return cats