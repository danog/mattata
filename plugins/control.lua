local control = {}
local mattata = require('mattata')
local functions = require('functions')
function control:init(configuration)
	control.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('reload', true).table
end
function control:action(msg, configuration)
	if msg.from.id ~= configuration.owner_id then
		return
	end
	for pac, _ in pairs(package.loaded) do
		if pac:match('^plugins%.') then
				package.loaded[pac] = nil
		end
	end
	package.loaded['telegram_api'] = nil
	package.loaded['functions'] = nil
	package.loaded['configuration'] = nil
	if not msg.text_lower:match('%-configuration') then
		for k, v in pairs(require('configuration')) do
			configuration[k] = v
		end
	end
	mattata.init(self, configuration)
	print(self.info.first_name .. ' is reloading...')
	functions.send_reply(msg, self.info.first_name .. ' is reloading...')
end
return control