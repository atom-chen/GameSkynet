-------------------------------------------------------------------------------
-- @file VBase.lua
--
-- @ author xzben 2015/05/19
--
-- 所有显示View的base类
-------------------------------------------------------------------------------

local VBase = class("VBase", core.EventDispatcher)

---@field map_table [plist] = bool #__loadFrameSet  当前界面已经加载的Frame的集合
VBase.__loadFrameSet = nil
---@field map_table [plist] = bool #__loadAnimatSet  当前界面已经加载的Animate的集合
VBase.__loadAnimatSet = nil

---@field map_table [plist_format] = plist
VBase.__loadFrameAnimateSet = nil

---@field bool 标记是否加载过资源
VBase._haveLoadResource = nil


local loadFrameSetCount = {}
local loadAnimateSetCount = {}
local loadFramesAnimateSetCount = {}

---@function 节点 enter 事件回调
local root_on_enter = nil
--@function 节点 exit 事件回调
local root_on_exit = nil

function VBase:ctor()
    self.__loadFrameSet = {}
    self.__loadAnimatSet = {}
    self.__loadFrameAnimateSet = {}
    self._haveLoadResource = false

    local function handlercallback(event)
        if "enter" == event then
            root_on_enter(self)
        elseif "exit" == event then
            root_on_exit(self)
        end
    end
    self:registerScriptHandler(handlercallback)
end
--------------------------------------------资源加载 相关逻辑--------------------------------------------------------------------------
function VBase:loadFrame( plistFile )
    if nil == loadFrameSetCount[plistFile] or loadFrameSetCount[plistFile] <= 0 then

        local fullPath = plistFile..".plist";
        if not cc.FileUtils:getInstance():isFileExist(fullPath) then 
            return false
        end

        cc.SpriteFrameCache:getInstance():addSpriteFrames(fullPath);
        loadFrameSetCount[plistFile] = 0

        cclog("loadFrame:", plistFile)
    end

    if self.__loadFrameSet[plistFile] then
        loadFrameSetCount[plistFile] = loadFrameSetCount[plistFile] + 1
        self.__loadFrameSet[plistFile] = true
    end
    
    self._haveLoadResource = true
    return true
end

function VBase:removeFrame( plistFile )
    if  loadFrameSetCount[plistFile] == nil or loadFrameSetCount[plistFile] <= 0 then return end

    loadFrameSetCount[plistFile] = loadFrameSetCount[plistFile] - 1
    if loadFrameSetCount[plistFile] <= 0 then
        local fullPath = plistFile..".plist";
        cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(fullPath);

        loadFrameSetCount[plistFile] = nil
        cclog("removeFrame:", plistFile)
    end
end

function VBase:loadAnimateByFrames(framePlist, frameFormat, begin_index, end_index, delay)
    if nil == loadFramesAnimateSetCount[frameFormat] or loadFramesAnimateSetCount[frameFormat] <= 0 then
        self:loadFrame(framePlist)

        local animation = cc.Animation:create()
        for i = begin_index, end_index, 1 do
            local frameName = string.format(frameFormat, i)
            print("frameName", frameName)
            local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
            assert(frame)
            animation:addSpriteFrame(frame)
        end
        animation:setDelayPerUnit(delay)
        cc.AnimationCache:getInstance():addAnimation(animation, frameFormat);

        loadFramesAnimateSetCount[frameFormat] = 0
    end

    if not self.__loadFrameAnimateSet[frameFormat] then
        loadFramesAnimateSetCount[frameFormat] = loadFramesAnimateSetCount[frameFormat] + 1
        self.__loadFrameAnimateSet[frameFormat] = framePlist
    end

    self._haveLoadResource = true

    return true
end

function VBase:removeAnimationByFrames( animateName , framePlist )
    if  loadFramesAnimateSetCount[animateName] == nil or loadFramesAnimateSetCount[animateName] <= 0 then return end

    loadFramesAnimateSetCount[animateName] = loadFramesAnimateSetCount[animateName] - 1
    if loadFramesAnimateSetCount[animateName] <= 0 then
        self:removeFrame(framePlist)
        cc.AnimationCache:getInstance():removeAnimation(animateName);
        loadFramesAnimateSetCount[animateName] = nil
        cclog("removeAnimate:", animateName)
    end
end

function VBase:loadAnimate( plistFile )
    if nil == loadAnimateSetCount[plistFile] or loadAnimateSetCount[plistFile] <= 0 then
        local framePlist = plistFile..".plist"
        local animatePlist = plistFile.."_ani.plist"

        if not cc.FileUtils:getInstance():isFileExist(framePlist) or not cc.FileUtils:getInstance():isFileExist(animatePlist) then 
            return false
        end

        cc.SpriteFrameCache:getInstance():addSpriteFrames(framePlist);
        cc.AnimationCache:getInstance():addAnimations(animatePlist);

        loadAnimateSetCount[plistFile] = 0
        cclog("loadAnimate:", plistFile)
    end
    
    if not self.__loadAnimatSet[plistFile] then
        loadAnimateSetCount[plistFile] = loadAnimateSetCount[plistFile] + 1
        self.__loadAnimatSet[plistFile] = true
    end

    self._haveLoadResource = true

    return true
end

function VBase:removeAnimate( plistFile )
    if  loadAnimateSetCount[plistFile] == nil or loadAnimateSetCount[plistFile] <= 0 then return end

    loadAnimateSetCount[plistFile] = loadAnimateSetCount[plistFile] - 1
    if loadAnimateSetCount[plistFile] <= 0 then
        local framePlist = plistFile..".plist"
        local animatePlist = plistFile.."_ani.plist"

        cc.SpriteFrameCache:getInstance():removeSpriteFramesFromFile(framePlist);

        local animateFrames = cc.FileUtils:getInstance():getValueMapFromFile(animatePlist)
        local animations = animateFrames["animations"]

        for key, value in animations do
            cc.AnimationCache:getInstance():removeAnimation(key);
        end
        loadAnimateSetCount[plistFile] = nil
        cclog("removeAnimate:", plistFile)
    end
end

function VBase:animation( animateName )
    return cc.AnimationCache:getInstance():getAnimation(animateName);
end

function VBase:animate( animateName )
    return cc.Animate:create(self:animation(animateName))
end

function VBase:clearResources()
    for plist in pairs(self.__loadAnimatSet) do
        self:removeAnimate(plist)
    end

    for plist in pairs(self.__loadFrameSet) do
        self:removeFrame(plist)
    end

    for animateName, framePlist in pairs(self.__loadFrameAnimateSet) do
        self:removeAnimationByFrames(animateName, framePlist)
    end

    if self._haveLoadResource then
        game.instance():session():setNeedToRemoveUnusedCached(true)
    end
end
----------------------------------------------------------------------------------------------------------------------
root_on_enter = function(self)
    print("VBase on_enter")
    
    if self.handleKeyBackClicked then
        print("VBase:root_on_enter()")
        game.instance():session():registerKeybackListener(self.handleKeyBackClicked, self)
    end

    if self.handleKeyMenuClicked then
        game.instance():session():registerKeyMenuListener(self.handleKeyMenuClicked, self)
    end

    if self.on_enter then
        self:on_enter()
    end
end

root_on_exit = function(self)
    print("VBase on_exit")
    
    if self.handleKeyBackClicked then
        game.instance():session():unregisterKeybackListener(self.handleKeyBackClicked, self)
    end

    if self.handleKeyMenuClicked then
        game.instance():session():unregisterKeyMenuListener(self.handleKeyMenuClicked, self)
    end

    if self.on_exit then
        self:on_exit()
    end

    self:clearResources()
end

return VBase