local baseUIFile = UIFile
function UIFile(filespec)
	local NukePingModPath = '/phantomxhook'
	#Ignore skin paths for texture loads out of the mod file.
	if string.find(filespec, NukePingModPath) == nil then
		return baseUIFile(filespec)
	else
		return filespec
	end
end