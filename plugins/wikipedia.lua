local wikipedia = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function wikipedia:init(configuration)
	wikipedia.command = 'wikipedia <query>'
	wikipedia.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('wikipedia', true):t('wiki', true):t('w', true).table
	wikipedia.documentation = configuration.command_prefix .. 'wikipedia <query> - Returns an article from Wikipedia. Aliases: ' .. configuration.command_prefix .. 'w, ' .. configuration.command_prefix .. 'wiki.'
end
local get_title = function(search)
	for _,v in ipairs(search) do
		if not v.snippet:match('may refer to:') then
			return v.title
		end
	end
 	return false
end
function wikipedia:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, wikipedia.documentation)
		return
	else
		input = input:gsub('#', ' sharp')
	end
	local search_url = 'http://' .. configuration.wikipedia_language .. '.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch='
	local search_jstr, search_res = HTTPS.request(search_url .. URL.escape(input))
	if search_res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local search_jdat = JSON.decode(search_jstr)
	if search_jdat.query.searchinfo.totalhits == 0 then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local title = get_title(search_jdat.query.search)
	if not title then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local result_url = 'https://' .. configuration.wikipedia_language .. '.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exchars=4000&exsectionformat=plain&titles='
	local result_jstr, result_res = HTTPS.request(result_url .. URL.escape(title))
	if result_res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local _
	local text = JSON.decode(result_jstr).query.pages
	_, text = next(text)
	if not text then
		functions.send_reply(msg, configuration.errors.results)
		return
	else
		text = text.extract
	end
	text = text:gsub('</?.->', '')
	local l = text:find('\n')
	if l then
		text = text:sub(1, l-1)
	end
	local url = 'https://' .. configuration.wikipedia_language .. '.wikipedia.org/wiki/' .. URL.escape(title)
	title = title:gsub('%(.+%)', '')
	local output
	if string.match(text:sub(1, title:len()), title) then
		output = '*' .. title .. '*' .. text:sub(title:len()+1)
	else
		output = '*' .. title:gsub('%(.+%)', '') .. '*\n' .. text:gsub('%[.+%]','')
	end
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. url:gsub('%)', '\\)') .. '"}]]}')
end
return wikipedia