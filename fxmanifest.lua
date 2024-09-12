fx_version 'cerulean'
game 'gta5'

author 'BVVS'
description 'Skrypt do zasłaniania tablic rejestracyjnych w FiveM'
version '0.0.1'


client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}


dependencies {
    'es_extended',
    'ox_target'
}
