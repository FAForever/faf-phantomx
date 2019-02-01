local baseUIFile = UIFile
function UIFile(filespec, checkMods)
	local NukePingModPath = '/phantomxhook'
	#Ignore skin paths for texture loads out of the mod file.
	if string.find(filespec, NukePingModPath) == nil then
		return baseUIFile(filespec, checkMods)
	else
		return filespec
	end
end
