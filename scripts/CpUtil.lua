CpUtil = {}

---Prints a table to an xml File recursively.
---Basically has the same function as DebugUtil.printTableRecursively() except for saving the prints to an xml file
---@param value table is the last relevant value from parent table
---@param depth number is the current depth of the iteration
---@param maxDepth number represent the max iterations 
---@param xmlFile number xmlFile to save in
---@param baseKey string parent key 
function CpUtil.printTableRecursivelyToXML(value, depth, maxDepth,xmlFile,baseKey)
	depth = depth or 0
	maxDepth = maxDepth or 3
	if depth > maxDepth then
		return
	end
	local key = string.format('%s.depth:%d',baseKey,depth)
	local k = 0
	for i,j in pairs(value) do
		local key = string.format('%s(%d)',key,k)
		local valueType = type(j) 
		setXMLString(xmlFile, key .. '#valueType', tostring(valueType))
		setXMLString(xmlFile, key .. '#index', tostring(i))
		setXMLString(xmlFile, key .. '#value', tostring(j))
		if valueType == "table" then
			CpUtil.printTableRecursivelyToXML(j,depth+1, maxDepth,xmlFile,key)
		end
		k = k + 1
	end
end

---Prints a global variable to an xml File.
---@param variableName string global variable to print to xmlFile
---@param maxDepth number represent the max iterations 
function CpUtil.printVariableToXML(variableName, maxDepth,printToSeparateXmlFiles)
	local baseKey = 'CpDebugPrint'
	local filePath
	if printToSeparateXmlFiles and tonumber(printToSeparateXmlFiles)>0 then 
		local fileName = string.gsub(variableName,":","_")..".xml"
		filePath = string.format("%s/%s",g_Courseplay.cpDebugPrintXmlFolderPath,fileName)
	else 
		filePath = g_Courseplay.cpDebugPrintXmlFilePathDefault
	end
	Courseplay.info("Trying to print to xml file: %s",filePath)
	local xmlFile = createXMLFile("xmlFile", filePath, baseKey);
	local xmlFileValid = xmlFile and xmlFile ~= 0 or false
	if not xmlFileValid then
		Courseplay.error("xmlFile(%s) not valid!",filePath)
		return 
	end
	setXMLString(xmlFile, baseKey .. '#maxDepth', tostring(maxDepth))
	local depth = maxDepth and math.max(1, tonumber(maxDepth)) or 1
	local value = CpUtil.getVariable(variableName)
	local valueType = type(value)
	local key = string.format('%s.depth:%d',baseKey,0)
	if value then
		setXMLString(xmlFile, key .. '#valueType', tostring(valueType))
		setXMLString(xmlFile, key .. '#variableName', tostring(variableName))
		if valueType == 'table' then		
			CpUtil.printTableRecursivelyToXML(value,1,depth,xmlFile,key)
			local mt = getmetatable(value)
			if mt and type(mt) == 'table' then
				CpUtil.printTableRecursivelyToXML(mt,1,depth,xmlFile,key..'-metaTable')
			end
		else 
			setXMLString(xmlFile, key .. '#valueType', tostring(valueType))
			setXMLString(xmlFile, key .. '#value', tostring(value))
		end
	else 
		setXMLString(xmlFile, key .. '#value', tostring(value))
	end
	saveXMLFile(xmlFile)
	delete(xmlFile)
end

---Prints a variable to the console or a xmlFile.
---@param variableName string name of the variable, can be multiple levels
---@param maxDepth number maximum depth, 1 by default
function CpUtil.printVariable(variableName, maxDepth)
	print(string.format('%s - %s', tostring(variableName), tostring(maxDepth)))
	local depth = maxDepth and math.max(1, tonumber(maxDepth)) or 1
	local value = CpUtil.getVariable(variableName)
	local valueType = type(value)
	if value then
		print(string.format('Printing %s (%s), depth %d', variableName, valueType, depth))
		if valueType == 'table' then
			DebugUtil.printTableRecursively(value, '  ', 1, depth)
			local mt = getmetatable(value)
			if mt and type(mt) == 'table' then
				print('-- metatable -->')
				DebugUtil.printTableRecursively(mt, '  ', 1, depth)
			end
		else
			print(variableName .. ': ' .. tostring(value))
		end
	else
		return(variableName .. ' is nil')
	end
	return('Printed variable ' .. variableName)
end


--- get a reference pointing to the global variable 'variableName'
-- can handle multiple levels (but not arrays, yet) like foo.bar
function CpUtil.getVariable(variableName)
	local f = getfenv(0).loadstring('return ' .. variableName)
	return f and f() or nil
end

--- Create a node at x,z, direction according to yRotation.
--- If rootNode is given, make that the parent node, otherwise the parent is the terrain root node
---@param name string
---@param x number
---@param z number
---@param yRotation number
---@param rootNode number
function CpUtil.createNode(name, x, z, yRotation, rootNode)
	local node = createTransformGroup(name)
	link(rootNode or g_currentMission.terrainRootNode, node)
	-- y is zero when we link to an existing node
	local y = rootNode and 0 or getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z);
	setTranslation( node, x, y, z );
	setRotation( node, 0, yRotation, 0);
	return node
end

--- Safely destroy a node
function CpUtil.destroyNode(node)
	if node and entityExists(node) then
		unlink(node)
		delete(node)
	end
end