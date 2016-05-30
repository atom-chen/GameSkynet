-------------------------------------------------------------------------------
-- @file CocoStudioHelper.lua
--
-- @ author xzben 2014/05/16
--
-- cocostudio 的辅助工具，用于读取从cocostudio中导出的文件
-------------------------------------------------------------------------------
CocoStudioHelper = CocoStudioHelper or {}

--[[
CocoStudioHelper.load_scene
CocoStudioHelper.init_ui_controls
CocoStudioHelper.load_ui
--]]
local LOADED_WIDGET = {}
local AUTO_COUNT 	= {}

local function get_auto_node(layer_json_file)
	local function on_enter()
		if not AUTO_COUNT[layer_json_file] then
			AUTO_COUNT[layer_json_file] = 0
		end
		AUTO_COUNT[layer_json_file] = AUTO_COUNT[layer_json_file] + 1
	end

	local function on_exit()
		if not AUTO_COUNT[layer_json_file] then
			return
		end
		AUTO_COUNT[layer_json_file] = AUTO_COUNT[layer_json_file] - 1
		if AUTO_COUNT[layer_json_file] <= 0 then
			LOADED_WIDGET[layer_json_file]:release()
			LOADED_WIDGET[layer_json_file] = nil
		end
	end

	return Helper.create_auto_node(on_enter, on_exit)
end


local function load_widget(init_layer_obj, layer_json_file)
	local filename, ext = Helper.split_filename_ext(layer_json_file)
	local widget = LOADED_WIDGET[layer_json_file]
	if widget then
		local retwidget = widget:clone()
		retwidget:addChild(get_auto_node(layer_json_file))
		return retwidget
	end

	if ext == "csb" then
	 	widget = ccs.GUIReader:getInstance():widgetFromBinaryFile(layer_json_file)
	elseif ext == "json" then
		widget = ccs.GUIReader:getInstance():widgetFromJsonFile(layer_json_file)
	else
		return nil
	end

	LOADED_WIDGET[layer_json_file] = widget
	LOADED_WIDGET[layer_json_file]:retain()

	local retwidget = widget:clone()
	retwidget:addChild(get_auto_node(layer_json_file))
	--print("get new widget !!!!")
	return retwidget
end

--[[
	用于加载 cocostudio 导出的场景
--]]
function CocoStudioHelper.load_scene(init_layer_obj, scene_file)
	init_layer_obj.widget_ = ccs.SceneReader:getInstance():createNodeWithSceneFile(scene_file)
	init_layer_obj:addChild(init_layer_obj.widget_)

	init_layer_obj.get_component_by_name = function (self, componet_name, obj_name)
		local node = Helper.seek_child_by_name(self.widget_, componet_name)
		if node then
			return node:getComponent(obj_name):getNode()
		end
	end

	init_layer_obj.get_component_by_tag = function (self, tag, obj_name)
		local node = Helper.seek_child_by_tag(self.widget_, tag)
		if node then
			return node:getComponent(obj_name):getNode()
		end
	end
end

--[[
	用户遍历初始化 cocostudio 导出的 layer
--]]
function CocoStudioHelper.init_ui_controls(init_layer_obj, table_control_map)
	init_layer_obj.controls_ = {}
	for _, theControl in ipairs(table_control_map) do
		init_layer_obj.controls_[theControl.tag_name] = Helper.seek_child_by_name(init_layer_obj, theControl.tag_name)
		assert(init_layer_obj.controls_[theControl.tag_name] ~= nil, string.format("can't load control: "..theControl.tag_name))
	end
	
	-- 通过控件名字获取控件
	init_layer_obj.get_control_by_name = function (layer_obj, control_name)
		if layer_obj.controls_[control_name]  then
			return layer_obj.controls_[control_name]
		end

		local control_obj = Helper.seek_child_by_name(layer_obj, control_name)
		assert(control_obj~=nil, string.format("can't find the control by name [%s]", tostring(control_name)))
		layer_obj.controls_[control_name] = control_obj

		return control_obj
	end

	-- 通过名字从控件中获得子控件
	init_layer_obj.get_control_child_by_name = function (layer_obj, control_obj, child_name )
		local child_obj = Helper.seek_child_by_name(control_obj, child_name)
		assert(child_obj~=nil, string.format("can't find the control by name [%s]", tostring(child_name)))
		return child_obj
	end

	-- 初始化控件
	for _, theControl in ipairs(table_control_map) do
		if theControl.init_callback then 
			theControl.init_callback(init_layer_obj, init_layer_obj.controls_[theControl.tag_name])
		end
	end
	
	return true
end

--
-- init_layer_obj 		要构造的 layer 对象
-- layer_json_file 		要构造 layer 需要加载的 json/csb 文件路径
-- table_control_map 	初始化结构表，格式如下
-- talbe = {
--	{
--		tag_name 		= 控件对应的 json 标签名字
--		init_callback 	= 控件对应的初始化回调函数 function (self, control_obj) end layer 为构造的layerobj
--	}
--}
function CocoStudioHelper.load_ui(init_layer_obj, layer_json_file, table_control_map )
	init_layer_obj.widget_ = load_widget(init_layer_obj, layer_json_file)

	init_layer_obj:addChild(init_layer_obj.widget_)

	size = init_layer_obj:getContentSize()
	init_layer_obj.widget_:setContentSize(size)
	init_layer_obj.widget_:ignoreAnchorPointForPosition(false)
	init_layer_obj.widget_:setAnchorPoint(cc.p(0.5,0.5))
    init_layer_obj.widget_:setPosition(size.width/2, size.height/2)

   	return CocoStudioHelper.init_ui_controls(init_layer_obj,table_control_map) 
end

return CocoStudioHelper