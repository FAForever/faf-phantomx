local File = '*.phx'
 

 

# Some functions

local function mount_dir(dir, mountpoint)

    table.insert(path, { dir = dir, mountpoint = mountpoint })

end

local function mount_contents(dir, mountpoint)

    LOG('checking '..dir)

    for _,entry in io.dir(dir..'\\*') do

        if entry != '.' and entry != '..' then

            local mp = string.lower(entry)

            mp = string.gsub(mp, '[.]scd$', '')

            mp = string.gsub(mp, '[.]zip$', '')

            mp = string.gsub(mp, '[.]faf$', '') 

            mp = string.gsub(mp, '[.]phx$', '')  

            mount_dir(dir..'\\'..entry, mountpoint..'/'..mp)

        end

    end

end

 

 

 

dofile(InitFileDir..'\\SupComDataPath.lua')

 

 

table.insert(hook, '/phantomxhook')

 

local oldPath = path

path = {}

 

mount_dir(InitFileDir..'\\..\\gamedata\\'..File, '/')

 

for k, v in oldPath do

    table.insert(path, v)

end
