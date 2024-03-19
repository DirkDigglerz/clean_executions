 
fx_version 'cerulean' 
lua54 'yes' 
games { 'rdr3', 'gta5' } 
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.' 
author 'DirkScripts' 
description 'ElectricChair' 
version '1.0.0' 
 
shared_script{ 
  '@ox_lib/init.lua',
  'config.lua',
  'labels.lua',
  'shared/*.lua',
} 
 
client_script { 
  'client/*.lua',
} 
 
server_script { 
  'server/*.lua',
} 
 
dependencies { 
  'dirk-core', 
  'ox_lib',
} 