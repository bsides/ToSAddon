local addonName = "ShopHelper";
local verText = "0.80";
local autherName = "TOUKIBI";
local addonNameLower = string.lower(addonName);
local SlashCommandList = {"/sh", "/shophelper", "/shelper", "/ShopHelper"};
local CommandParamList = {
	reset = {jp = "価格の平均値設定をリセット", en = "Reset the paramaters of price average settings."}
  , resetall = {jp = "すべての設定をリセット", en = "Reset the all settings."}
  , jp = {jp = "日本語モードに切り替え", en = "Switch to Japanese mode.(日本語へ)"}
  , en = {jp = "Switch to English mode.", en = "Switch to English mode."};
};
local SettingFileName = "setting.json"
local FavoriteFileName = "favorite.json"

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][autherName] = _G['ADDONS'][autherName] or {};
_G['ADDONS'][autherName][addonName] = _G['ADDONS'][autherName][addonName] or {};

local Me = _G['ADDONS'][autherName][addonName];
Me.SettingFilePathName = string.format("../addons/%s/%s", addonNameLower, SettingFileName);
Me.FavoriteFilePathName = string.format("../addons/%s/%s", addonNameLower, FavoriteFileName);
local DebugMode = false;

-- ===== 露店手数料設定 =====
Me.CommissionRate = 0.3;

Me.BuyHistory = Me.BuyHistory or {};
Me.IsVillage = nil;
Me.loaded = false;

local MyEnums = {
	FavoriteState = {
		NoData = 0,
		Blocked = -3,
		Liked = 3,
		Favorite = 5,
		Friend = 9
	},
	DisplayState = {
		NoMark = 0,
		Never = -9,
		HateMark = -3,
		Dislike = -1,
		Liked = 1,
		Favorite = 3,
		Love = 9
	}
};

-- テキストリソース
local ResText = {
	jp = {
		Menu = {
			Title = "{#006666}==== %s ===={/}"
		  , Favorite = "お気に入り"
		  , AsNormal = "マークなし"
		  , Hate = "使いたくない"
		  , NeverShow = "見たくもない"
		  , LikeYou = "いいね"
		  , Close = "閉じる"
		},
		ShopName = {
			SquireBuff = "%s の修理商店"
		  , GemRoasting = "%sのジェムロースティング商店"
		  , AppraisalPC = "%s の鑑定商店"
		  , General = "%s の露店"
		},
		ComDic = {
			CostPrice = "原価"
		  , AveragePrice = "平均"
		  , CurrentPrice = "価格"
		  , BelowCost = "原価割れ"
		  , AtCost = "原価販売"
		  , NearCost = "ほぼ原価"
		  , GoodValue = "お値打ち"
		  , WithinAverage = "平均近く"
		  , ALittleExpensive = "高くない？"
		  , Expensive = "高いと思います"
		  , RipOff = "異常に高額!!"
		  , Empty = "予想外のパターン(バグ)"
		  , SaveTo = "保存先:"
		  , PriceRadix = "基数"
		  , UnknownSkillID = "スキルID[%s]"
		  , RuralCharge = "郊外割増 +"
		  , SelectAll = "全体選択"
		},
		Log = {
			ResetConfig = "設定がリセットされました"
		  , ResetAveragePrice = "平均価格がリセットされました"
		  , CallLoadSetting = "Me.LoadSettingが呼び出されました"
		  , CallSaveSetting = "Me.SaveSettingが呼び出されました"
		  , UseDefaultSetting = "Me.Settingが存在しないので標準の設定が呼び出されます"
		  , CannotGetSettingFrameHandle = "設定画面のハンドルが取得できませんでした"
		  , InitializeMe = "プログラムを初期化します"
		  , RedrawAllShopBaloon = "すべての露店バルーンを再描画します"
		  , BuySomething = "%sの%sを%ssで受けました。"
		  , UpdateAveragePrice = "%sの平均価格を%sに更新しました"
		  , IsSuburbMsg = "支払金額%ssですが、ここは郊外なので郊外割増の%ssを差し引いた金額%ssで記録します。"
		  , IsBelowCostMsg = "この価格は原価割れしているため、平均値推移に原価を記録します。"
		  , IsFartherValueMsg = "この価格は平均値からあまりに離れているため、平均値推移を更新しません。"
		  , IsShorterInterval = "まだ%d秒しか経過していないため、平均価格の更新は行いません。(設定待機時間:%d秒)"
		  , LoadTextResource = "文字情報の読み込みが完了しました"
		},
		Option = {
			Zone = {
				BelowCost = "原価割れ"
			  , NearCost = "ほぼ原価"
			  , GoodValue = "お値打ち"
			  , WithinAverage = "平均"
			  , ALittleExpensive = "高くない？"
			  , Expensive = "高い"
			  , RipOff = "異常に高い"
			}
		  , SettingFrameTitle = "Shop Helperの設定"
		  , Save = "保存"
		  , CloseMe = "閉じる"
		  , TabGeneralSetting = "基本設定"
		  , TabAverageSetting = "平均価格設定"
		  , TabHowToUse = "使い方"
		  , GeneralSetting = "全般設定"
		  , ShowMessageLog = "ログを表示する"
		  , ShowMsgBoxOnBuffShop = "バフ購入時の確認メッセージを表示しない"
		  , AddInfoToBaloon = "露店の看板に情報を追記する"
		  , EnableBaloonRightClick = "露店の看板の右クリックを有効にする"
		  , UpdateAverage = "平均値を更新する"
		  , AverageWeight = "移動平均の重み"
		  , AverageWeightUnit = ":"
		  , AverageUpdateInterval = "次の更新までの待機時間"
		  , AverageUpdateIntervalUnit = "秒"
		  , NoUpdateIfFartherValue = "値が平均から離れすぎているときは更新しない"
		},
		BtnText = {
			lblBuy = "{@st41}購入{/}"
		  , lblOngoing = "{@st41}{#FFAA33}バフ継続中{/}{/}"
		  , lblWarning = "{img NOTICE_Dm_! 32 32}{@st41}{#FF3333}高いよ？{/}{/}"
		  , lblSelectByDur = "残耐久度で選択"
		},
		WarnMsg = {
			Title = "価格確認"
		  , Body = "{#111111}この商品は{s24}{b}{ol}{#FF0000}異常に高い{/}{/}{/}{/}ですが、{nl}本当に購入してもいいですか？{/}"
		},
		Other = {
			DurabilityLeft = "次の耐久度を下回るものだけを選択"
		  , ShowDurGauge = "耐久度のゲージを表示する"
		  , ShowDurValue = "耐久度の数値を表示する"
		}
	},
	en = {
		Menu = {
			Title = "{#006666}==== %s ===={/}"
		  , Favorite = "It's my Favorite!!"
		  , AsNormal = "As normal."
		  , Hate = "I do not want to use."
		  , NeverShow = "Never show it!!"
		  , LikeYou = "Like!"
		  , Close = "Close"
		},
		ShopName = {
			SquireBuff = "%s's repair stalls"
		  , GemRoasting = "%s's Gem-roasting stalls"
		  , AppraisalPC = "%s's appreciation stalls"
		  , General = "%s's stalls"
		},
		ComDic = {
			CostPrice = "Cost price"
		  , AveragePrice = "Average price"
		  , CurrentPrice = "Current price"
		  , BelowCost = "Below cost"
		  , AtCost = "At cost price"
		  , NearCost = "Near cost price"
		  , GoodValue = "Good value"
		  , WithinAverage = "Within Average price range"
		  , ALittleExpensive = "Is't it a little expensive?"
		  , Expensive = "Expensive"
		  , RipOff = "Rip-off!"
		  , Empty = "Out of implementation(Bugs?)"
		  , SaveTo = "Storage destination:"
		  , PriceRadix = "Radix"
		  , UnknownSkillID = "Unknown Skill-ID [%s]"
		  , RuralCharge = "In the suburbs, raise the price"
		  , SelectAll = "Select All"
		},
		Log = {
			ResetConfig = "Configuration was resetted."
		  , ResetAveragePrice = "Data of average-prices was resetted."
		  , CallLoadSetting = "[Me.LoadSetting] was called"
		  , CallSaveSetting = "[Me.SaveSetting] was called"
		  , UseDefaultSetting = "Since [Me.Setting] does not exist, use the default settings."
		  , CannotGetSettingFrameHandle = "Failed to get the handle of setting dialog."
		  , InitializeMe = "Initialized the ShopHelper add-on."
		  , RedrawAllShopBaloon = "Updated signs of all the stalls"
		  , BuySomething = "Received %s's %s in %ss."
		  , UpdateAveragePrice = "The average price of %s has been updated to %s"
		  , IsSuburbMsg = "The payment amount is %ss, but since it is a suburb, minus a suburban charge of %ss. So, recorded at the amount of %ss."
		  , IsBelowCostMsg = "As this price is broken down, Recorded the cost in the average value transition."
		  , IsFartherValueMsg = "Since this price is too far from the average value, the average value transition was not updated."
		  , IsShorterInterval = "Since only %d seconds have elapsed, the average price was not renewed. (Standby time setting: %d seconds)"
		  , LoadTextResource = "Reading of character information is completed."
		},
		Option = {
			Zone = {
				BelowCost = "Below cost"
			  , NearCost = "Near cost"
			  , GoodValue = "Good value"
			  , WithinAverage = "Within Average"
			  , ALittleExpensive = "a little expensive"
			  , Expensive = "Expensive"
			  , RipOff = "Rip-off!"
			}
		  , SettingFrameTitle = "Settings  -Shop Helper-"
		  , Save = "Save"
		  , CloseMe = "Close"
		  , TabGeneralSetting = "Generals"
		  , TabAverageSetting = "Averages"
		  , TabHowToUse = "How to use"
		  , GeneralSetting = "General Settings"
		  , ShowMessageLog = "Enable log display to chat log"
		  , ShowMsgBoxOnBuffShop = "Disable confirmation messages when buying buffs"
		  , AddInfoToBaloon = "Enable Additional draws to the sign board"
		  , EnableBaloonRightClick = "Enable right-click-menus of sign board"
		  , UpdateAverage = "Update the average price"
		  , AverageWeight = "The weight of the moving average"
		  , AverageWeightUnit = " to "
		  , AverageUpdateInterval = "Interval to next update"
		  , AverageUpdateIntervalUnit = "seconds"
		  , NoUpdateIfFartherValue = "Disable update when the price is too far from the average"
		},
		BtnText = {
			lblBuy = "{@st41}Buy{/}"
		  , lblOngoing = "{@st41}{#FFAA33}Currently ongoing{/}{/}"
		  , lblWarning = "{@st41}{#FF3333}Not regret?{/}{/}"
		  , lblSelectByDur = "Select by durability value"
		},
		WarnMsg = {
			Title = "Warning!!"
		  , Body = "{#111111}This item is {nl}{s24}{b}{ol}{#FF0000}abnormally expensive{/}{/}{/}{/}.{nl}Are you sure you're not gonna regret this?{/}"
		},
		Other = {
			DurabilityLeft = "Select only those below the durability"
		  , ShowDurGauge = "Display durability gauge"
		  , ShowDurValue = "Display durability value"
		}
	}
};
Me.ResText = ResText;

-- コモンモジュール(の代わり)
local Toukibi = {
	CommonResText = {
		jp = {
			System = {
				NoSaveFileName = "設定の保存ファイル名が指定されていません"
			  , HasErrorOnSaveSettings = "設定の保存でエラーが発生しました"
			  , CompleteSaveSettings = "設定の保存が完了しました"
			  , ErrorToUseDefaults = "設定の読み込みでエラーが発生したのでデフォルトの設定を使用します。"
			  , CompleteLoadDefault = "デフォルトの設定の読み込みが完了しました。"
			  , CompleteLoadSettings = "設定の読み込みが完了しました"
			},
			Command = {
				ExecuteCommands = "コマンド '{#333366}%s{/}' が呼び出されました"
			  , ResetSettings = "設定をリセットしました。"
			  , InvalidCommand = "無効なコマンドが呼び出されました"
			  , AnnounceCommandList = "コマンド一覧を見るには[ %s ? ]を用いてください"
				},
			Help = {
				Title = string.format("{#333333}%sのパラメータ説明{/}", addonName),
				Description = string.format("{#92D2A0}%sは次のパラメータで設定を呼び出してください。{/}", addonName),
				ParamDummy = "[パラメータ]",
				OrText = "または",
				EnableTitle = "使用可能なコマンド"
			}
		},
		en = {
			System = {
				NoSaveFileName = "The filename of save settings is not specified.",
				HasErrorOnSaveSettings = "An error occurred while saving the settings.",
				CompleteSaveSettings = "Saving settings completed."
			},
			Command = {
				ExecuteCommands = "Command '{#333366}%s{/}' was called"
			  , ResetSettings = "The setting was reset."
			  , InvalidCommand = "Invalid command called"
			  , AnnounceCommandList = "Please use [ %s ? ] To see the command list"
				},
			Help = {
				Title = string.format("{#333333}Help for %s commands.{/}", addonName),
				Description = string.format("{#92D2A0}To change settings of '%s', please call the following command.{/}", addonName),
				ParamDummy = "[paramaters]",
				OrText = "or",
				EnableTitle = "Available commands"
			}
		}
	},
	
	Log = function(self, Caption)
		if Caption == nil then Caption = "てすと" end
		Caption = tostring(Caption) or "てすと";
		CHAT_SYSTEM(tostring(Caption));
	end,

	GetDefaultLangCode = function(self)
		if option.GetCurrentCountry() == "Japanese" then
			return "jp";
		else
			return "en";
		end
	end,

	GetTableLen = function(self, tbl)
		local n = 0;
		for _ in pairs(tbl) do
			n = n + 1;
		end
		return n;
	end,

	Split = function(self, str, delim)
		local ReturnValue = {};
		for match in string.gmatch(str, "[^" .. delim .. "]+") do
			table.insert(ReturnValue, match);
		end
		return ReturnValue;
	end,

	GetValue = function(self, obj, Key)
		if obj == nil then return nil end
		if Key == nil or Key == "" then return obj end
		local KeyList = self:Split(Key, ".");
		for i = 1, #KeyList do
			local index = KeyList[i]
			obj = obj[index];
			if obj == nil then return nil end
		end
		return obj;
	end,

	GetResData = function(self, TargetRes, Lang, Key)
		if TargetRes == nil then return nil end
		--CHAT_SYSTEM(string.format("TargetLang : %s", self:GetValue(TargetRes[Lang], Key)))
		--CHAT_SYSTEM(string.format("En : %s", self:GetValue(TargetRes["en"], Key)))
		--CHAT_SYSTEM(string.format("Jp : %s", self:GetValue(TargetRes["jp"], Key)))
		local CurrentRes = self:GetValue(TargetRes[Lang], Key) or self:GetValue(TargetRes["en"], Key) or self:GetValue(TargetRes["jp"], Key);
		return CurrentRes;
	end,

	GetResText = function(self, TargetRes, Lang, Key)
		local ReturnValue = self:GetResData(TargetRes, Lang, Key);
		if ReturnValue == nil then return "<No Data!!>" end
		if type(ReturnValue) == "string" then return ReturnValue end
		return tostring("tostring ==>" .. ReturnValue);
	end,

	-- ***** ログ表示関連 *****
	GetStyledText = function(self, Value, Styles)
		-- ValueにStylesで与えたスタイルタグを付加した文字列を返します
		local ReturnValue;
		if Styles == nil or #Styles == 0 then
			-- スタイル指定なし
			ReturnValue = Value;
		else
			local TagHeader = ""
			for i, StyleTag in ipairs(Styles) do
				TagHeader = TagHeader .. string.format( "{%s}", StyleTag);
			end
			ReturnValue = string.format( "%s%s%s", TagHeader, Value, string.rep("{/}", #Styles));
		end
		return ReturnValue;
	end,

	AddLog = function(self, Message, Mode, DisplayAddonName, OnlyDebugMode)
		if Message == nil then return end
		Mode = Mode or "Info";
		if (not DebugMode) and Mode == "Info" then return end
		if (not DebugMode) and OnlyDebugMode then return end
		local HeaderText = "";
		if DisplayAddonName then
			HeaderText = string.format("[%s]", addonName);
		end
		local MsgText = HeaderText .. Message;
		if Mode == "Info" then
			MsgText = self:GetStyledText(MsgText, {"#333333"});
		elseif Mode == "Warning" then
			MsgText = self:GetStyledText(MsgText, {"#331111"});
		elseif Mode == "Caution" then
			MsgText = self:GetStyledText(MsgText, {"#666622"});
		elseif Mode == "Notice" then
			MsgText = self:GetStyledText(MsgText, {"#333366"});
		else
			-- 何もしない
		end
		CHAT_SYSTEM(MsgText);
	end,

	-- 言語切替
	ChangeLanguage = function(self, Lang)
		local msg;
		if self.CommonResText[Lang] == nil then
			msg = string.format("Sorry, '%s' does not implement '%s' mode.{nl}Language mode has not been changed from '%s'.", 
								addonName, Lang, Me.Settings.Lang);
			self:AddLog(msg, "Warning", true, false)
			return;
		end
		Me.Settings.Lang = Lang;
		self:SaveTable(Me.SettingFilePathName, Me.Settings);
		if Me.Settings.Lang == "jp" then
			msg = "日本語モードに切り替わりました";
		else
			msg = string.format("Language mode has been changed to '%s'.", Lang);
		end
		self:AddLog(msg, "Notice", true, false);
	end,

	-- ヘルプテキストを自動生成する
	ShowHelpText = function(self)
		local ParamDummyText = "";
		if SlashCommandList ~= nil and SlashCommandList[1] ~= nil then
			ParamDummyText = ParamDummyText .. "{#333333}";
			ParamDummyText = ParamDummyText .. string.format("'%s %s'", SlashCommandList[1], self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.ParamDummy"));
			if SlashCommandList[2] ~= nil then
				ParamDummyText = ParamDummyText .. string.format(" %s '%s %s'", self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.OrText"), SlashCommandList[2], self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.ParamDummy"));
			end
			ParamDummyText = ParamDummyText .. "{/}{nl}";
		end
		local CommandHelpText = "";
		if CommandParamList ~= nil and self:GetTableLen(CommandParamList) > 0 then
			CommandHelpText = CommandHelpText .. string.format("{#333333}%s：", self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.EnableTitle"));
			for ParamName, DescriptionKey in pairs(CommandParamList) do
				local SpaceCount = 10 - string.len(ParamName);
				local SpaceText = ""
				if SpaceCount > 0 then
					SpaceText = string.rep(" ", SpaceCount)
				end
				CommandHelpText = CommandHelpText .. string.format("{nl}%s %s%s:%s", SlashCommandList[1], ParamName, SpaceText, self:GetResText(DescriptionKey, Me.Settings.Lang));
			end
			CommandHelpText = CommandHelpText .. "{/}{nl} "
		end
		
		self:AddLog(string.format("%s{nl}%s{nl}%s%s"
								, self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.Title")
								, self:GetResText(self.CommonResText, Me.Settings.Lang, "Help.Description")
								, ParamDummyText
								, CommandHelpText
								)
				  , "None", false, false);
	end,

	-- ***** 設定読み書き関連 *****
	SaveTable = function(self, FilePathName, objTable)
		if FilePathName == nil then
			self:AddLog(self:GetResText(self.CommonResText, Me.Settings.Lang, "System.NoSaveFileName"), "Warning", true, false);
		end
		local objFile, objError = io.open(FilePathName, "w")
		if objError then
			self:AddLog(string.format("%s:{nl}%s"
									, self:GetResText(self.CommonResText, Me.Settings.Lang, "System.HasErrorOnSaveSettings")
									, tostring(objError)), "Warning", true, false);
		else
			local json = require('json');
			objFile:write(json.encode(objTable));
			objFile:close();
			self:AddLog(self:GetResText(self.CommonResText, Me.Settings.Lang, "System.CompleteSaveSettings"), "Info", true, true);
		end
	end,

	LoadTable = function(self, FilePathName)
		local acutil = require("acutil");
		local objReadValue, objError = acutil.loadJSON(FilePathName);
		return objReadValue, objError;
	end,

	-- 既存の値がない場合にデフォルト値をマージする
	GetValueOrDefault = function(self, Value, DefaultValue, Force)
		Force = Force or false;
		if Force or Value == nil then
			return DefaultValue;
		else
			return Value;
		end
	end,

	-- ***** コンテキストメニュー関連 *****
	-- セパレータを挿入
	MakeCMenuSeparator = function(self, parent, width)
		width = width or 300;
		ui.AddContextMenuItem(parent, string.format("{img fullgray %s 1}", width), "None");
	end,

	-- コンテキストメニュー項目を作成
	MakeCMenuItem = function(self, parent, text, eventscp, icon, checked)
		local CheckIcon = "";
		local ImageIcon = "";
		local eventscp = eventscp or "None";
		if checked == nil then
			CheckIcon = "";
		elseif checked == true then
			CheckIcon = "{img socket_slot_check 24 24} ";
		elseif checked == false  then
			CheckIcon = "{img channel_mark_empty 24 24} ";
		end
		if icon == nil then
			ImageIcon = "";
		else
			ImageIcon = string.format("{img %s 24 24} ", icon);
		end
		ui.AddContextMenuItem(parent, string.format("%s%s%s", CheckIcon, ImageIcon, text), eventscp);
	end,

	-- イベントの飛び先を変更するためのプロシージャ
	SetHook = function(self, hookedFunctionStr, newFunction)
		if Me.HoockedOrigProc[hookedFunctionStr] == nil then
			Me.HoockedOrigProc[hookedFunctionStr] = _G[hookedFunctionStr];
			_G[hookedFunctionStr] = newFunction;
		else
			_G[hookedFunctionStr] = newFunction;
		end
	end 
};
Me.ComLib = Toukibi;
local function log(value)
	Toukibi:Log(value);
end

local ToukibiUI = {
	-- マージンを指定する
	SetMargin = function(self, pTarget, pLeft, pTop, pRight, pBottom)
		if pTarget ~= nil then
			local BeforeMargin = pTarget:GetMargin();
			pLeft = pLeft or BeforeMargin.left;
			pTop = pTop or BeforeMargin.top;
			pRight = pRight or BeforeMargin.right;
			pBottom = pBottom or BeforeMargin.bottom;
			pTarget:SetMargin(pLeft, pTop, pRight, pBottom);
		end
	end,

	-- テキストコントロールを追加
	AddRichText = function(self, BaseFrame, NewLabelName, NewText, NewLeft, NewTop, NewWidth, NewHeight, TextSize)
		local txtItem = tolua.cast(BaseFrame:CreateOrGetControl('richtext', NewLabelName, NewLeft, NewTop, NewWidth, NewHeight), "ui::CRichText"); 
		txtItem:SetTextAlign("left", "top"); 
		txtItem:SetText("{@st66}" .. NewText); 
		txtItem:SetGravity(ui.LEFT, ui.TOP);
		txtItem:ShowWindow(1);
		return txtItem;
	end,

	-- テキストコントロールを指定した領域の中心になるように追加
	AddRichTextToCenter = function(self, BaseFrame, NewLabelName, NewText, NewLeft, NewTop, NewWidth, NewHeight, TextSize)
		local objTextItem = self:AddRichText(BaseFrame, NewLabelName, NewText, NewLeft, NewTop, NewWidth, NewHeight, TextSize); 
		self:SetMargin(objTextItem, NewLeft + math.floor((NewWidth - objTextItem:GetWidth()) / 2), NewTop + math.floor((NewHeight - objTextItem:GetHeight()) / 2), 0, 0);
		return objTextItem;
	end,

	-- コントロールのテキストを変更する
	SetText = function(self, ctrl, NewText, Styles)
		local StyledText = NewText;
		if Styles ~= nil and #Styles > 0 then
			-- スタイル指定あり
			StyledText = Toukibi:GetStyledText(NewText, Styles);
		end
		if ctrl ~= nil then
			ctrl:SetText(StyledText);
		end
	end,

	-- コントロールのプロパティーに入っているテキストを入れ替える
	SetTextByKey = function(self, ctrl, propName, NewText, Styles)
		local StyledText = NewText;
		if Styles ~= nil and #Styles > 0 then -- スタイル指定あり
			StyledText = Toukibi:GetStyledText(NewText, Styles);
		end
		if ctrl ~= nil then
			ctrl:SetTextByKey(propName, StyledText);
		end
	end,

	-- ***** ボタン関連 *****
	AddButton = function(self, BaseFrame, NewLabelName, NewText, NewLeft, NewTop, NewWidth, NewHeight, TextSize)
		local objButton = tolua.cast(BaseFrame:CreateOrGetControl('button', NewLabelName, NewLeft, NewTop, NewWidth, NewHeight), "ui::CButton"); 
		objButton:SetText("{@st66}" .. NewText .. "{/}"); 
		objButton:SetGravity(ui.LEFT, ui.TOP);
		objButton:SetClickSound("button_click_big");
		objButton:SetOverSound("button_over");
		objButton:SetSkinName("test_normal_button");
		return objButton;
	end,

	-- チェックボックスの状態を設定する
	SetCheckedByName = function(self, frame, ControlName, pValue)
		if frame == nil then return nil end
		local TargetCheckBox = GET_CHILD(frame, ControlName, "ui::CCheckBox");
		if TargetCheckBox ~= nil then
			return self:SetChecked(TargetCheckBox, pValue);
		else
			return nil;
		end
	end,
	SetChecked = function(self, TargetCheckBox, pValue)
		if TargetCheckBox == nil then return nil end
		local intValue = 0;
		if type(pValue) == "boolean" and pValue then
			intValue = 1;
		elseif type(pValue) == "string" and (pValue ~= "" and pValue ~= "false" and pValue ~= "0") then
			intValue = 1;
		elseif type == nil then
			intValue = false;
		elseif type(pValue) == "number" and pValue ~= 0 then
			intValue = 1;
		end
		tolua.cast(TargetCheckBox, "ui::CCheckBox");
		TargetCheckBox:SetCheck(intValue);
	end,
	-- チェックボックスの状態を取得する
	GetCheckedByName = function(self, frame, ControlName)
		if frame == nil then return nil end
		local TargetCheckBox = GET_CHILD(frame, ControlName, "ui::CCheckBox");
		if TargetCheckBox ~= nil then
			return self:GetChecked(TargetCheckBox);
		else
			return nil;
		end
	end,
	GetChecked = function(self, TargetCheckBox)
		if TargetCheckBox == nil then return nil end
		tolua.cast(TargetCheckBox, "ui::CCheckBox");
		return TargetCheckBox:IsChecked() == 1;
	end,

	-- ***** チェックボックス関連 *****
	AddCheckBox = function(self, BaseFrame, NewLabelName, NewText, NewLeft, NewTop, NewWidth, NewHeight, TextSize)
		local objCheck = tolua.cast(BaseFrame:CreateOrGetControl('checkbox', NewLabelName, NewLeft, NewTop, NewWidth, NewHeight), "ui::CCheckBox");
		objCheck:SetText("{@st66}" .. NewText .. "{/}"); 
		objCheck:SetGravity(ui.LEFT, ui.TOP);
		objCheck:SetClickSound("button_click_big");
		objCheck:SetOverSound("button_over");
		objCheck:ShowWindow(1);
		return objCheck;
	end,

	-- ***** スライダー関連 *****
	-- スライダーを追加する
	AddSlider = function(self, BaseFrame, CtrlName, NewLeft, NewTop, NewWidth, NewHeight)
		local objSlider = tolua.cast(BaseFrame:CreateOrGetControl('slidebar', CtrlName, NewLeft, NewTop, NewWidth, NewHeight), "ui::CSlideBar"); 
		objSlider:SetGravity(ui.LEFT, ui.TOP);
		objSlider:ShowWindow(1);
		objSlider:SetClickSound("button_click_big");
		objSlider:SetOverSound("button_over");
		return objSlider;
	end,

	-- スライダーの値を設定する
	SetSliderValue = function(self, frame, ControlName, LabelName, pValue, pValueText)
		local objSlider = GET_CHILD(frame, ControlName, "ui::CSlideBar");
		if objSlider ~= nil then
			objSlider:SetLevel(pValue);
		end
		local txtTarget = GET_CHILD(frame, LabelName, "ui::CRichText");
		if txtTarget ~= nil then
			txtTarget:SetTextByKey("opValue", pValueText);
		end
	end,

	-- スライダーの値を取得する
	GetSliderValueByName = function(self, frame, ControlName)
		if frame == nil then return nil end
		local TargetSlider = GET_CHILD(frame, ControlName, "ui::CSlideBar");
		if TargetSlider ~= nil then
			return self:GetSliderValue(TargetSlider);
		else
			return nil;
		end
	end,
	GetSliderValue = function(self, TargetSlider)
		if TargetSlider == nil then return nil end
		tolua.cast(TargetSlider, "ui::CSlideBar");
		return TargetSlider:GetLevel();
	end,

	-- ***** ラジオボタン関連 *****
	-- 選択されているラジオボタンの名前を取得する
	GetSelectedRadioValue = function(self, SeedRadio)
		if SeedRadio == nil then return nil end
		local radioBtn = tolua.cast(SeedRadio, "ui::CRadioButton");
		radioBtn = radioBtn:GetSelectedButton();
		return string.match(radioBtn:GetName(),".-_(.+)");
	end,

	-- ***** テキストボックス関連 *****
	-- テキストボックスを追加
	AddTextBox = function(self, BaseFrame, NewObjName, pText, NewLeft, NewTop, NewWidth, NewHeight)
		local objTextBox = tolua.cast(BaseFrame:CreateOrGetControl("edit", NewObjName, NewLeft, NewTop, NewWidth, NewHeight), "ui::CEditControl");
		objTextBox:SetGravity(ui.LEFT, ui.TOP);
		objTextBox:EnableHitTest(1);
		objTextBox:SetSkinName("test_weight_skin");
		objTextBox:SetClickSound("button_click_big");
		objTextBox:SetOverSound("button_over");
		objTextBox:SetFontName("white_18_ol");
		objTextBox:SetOffsetXForDraw(0);
		objTextBox:SetOffsetYForDraw(-1);
		objTextBox:SetTextAlign("center", "center");
		objTextBox:SetText(pText);
		return objTextBox;
	end,

	GetNumValue = function(self, objTarget)
		if objTarget == nil then return nil end
		return GetNumberFromCommaText(objTarget:GetText());
	end


};
Me.UI = ToukibiUI;

-- 価格関連
local LibPrice = {
	-- 価格情報を取り出す
	GetPriceInfo = function(self, SkillID)
		local ReturnValue = {};
		if SkillID == 40203 then
			-- ブレス
			ReturnValue.CostPrice = math.floor(20 * 10 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 15;
			ReturnValue.DoAddInfo = true
		elseif SkillID == 40205 then
			-- サクラ
			ReturnValue.CostPrice = math.floor(35 * 10 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 10;
			ReturnValue.DoAddInfo = true
		elseif SkillID == 40201 then
			-- アスパ
			ReturnValue.CostPrice = math.floor(50 * 10 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 15;
			ReturnValue.DoAddInfo = true
		elseif SkillID == 10703 then
			-- 修理
			ReturnValue.CostPrice = math.floor(80 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 15;
			ReturnValue.DoAddInfo = true
		elseif SkillID == 21003 then
			-- ジェムロースティング
			ReturnValue.CostPrice = math.floor(3000 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 10;
			ReturnValue.DoAddInfo = true
		elseif SkillID == 31501 then
			-- 鑑定
			ReturnValue.CostPrice = math.floor(100 / (1 - Me.CommissionRate));
			ReturnValue.MaxLv = 5;
			ReturnValue.DoAddInfo = true
		end
		-- 転ばぬ先の杖
		ReturnValue.AveragePrice = Me.Settings.AverageData[tostring(SkillID)].Price or 100;
		ReturnValue.CostPrice = ReturnValue.CostPrice or 100;
		ReturnValue.Span = Me.Settings.AverageData[tostring(SkillID)].Radix or 20;
		ReturnValue.MaxLv = ReturnValue.MaxLv or 15;
		ReturnValue.Suburb = Me.Settings.AverageData[tostring(SkillID)].Suburb or 100;
		ReturnValue.DoAddInfo = ReturnValue.DoAddInfo or false;
		return ReturnValue;
	end,

	-- 数値にカンマを付けて文字列長を揃えたテキストに変換する
	GetCommaedTextEx = function(self, value, MaxTextLen, AfterTheDecimalPointLen, usePlusMark, AddSpaceAfterSign)
		local lMaxTextLen = MaxTextLen or 0;
		local lAfterTheDecimalPointLen = AfterTheDecimalPointLen or 0;
		local lusePlusMark = usePlusMark or false;
		local lAddSpaceAfterSign = AddSpaceAfterSign or lusePlusMark;

		if lAfterTheDecimalPointLen < 0 then lAfterTheDecimalPointLen = 0 end
		local IsNegative = (value < 0);
		local SourceValue = math.floor(math.abs(value) * math.pow(10, lAfterTheDecimalPointLen) + 0.5);
		local IntegerPartValue = math.floor(SourceValue * math.pow(10, -1 *lAfterTheDecimalPointLen));
		local DecimalPartValue = SourceValue - IntegerPartValue * math.pow(10, lAfterTheDecimalPointLen);
		local IntegerPartText = GetCommaedText(IntegerPartValue);
		local DecimalPartText = tostring(DecimalPartValue);

		-- 記号をつける
		local SignMark = "";
		if IsNegative then
			-- 負の数の場合は頭にマイナスをつける
			SignMark = "-";
		else
			-- 正の数の場合はusePlusMarkがTrueの場合のみ付加する
			if lusePlusMark then
				if Me.Settings.Lang == "jp" and IntegerPartValue == 0 and DecimalPartValue == 0 then
				-- 日本語の場合はゼロぴったり時に±を実装
					SignMark = "±";
				else
					SignMark = "+";
				end
			end
		end
		if lAddSpaceAfterSign and string.len(SignMark) > 0 then
			SignMark = " " .. SignMark .. " ";
		end
		-- 整数部を成形
		local RoughFinish = SignMark .. IntegerPartText;
		-- 小数部を成形
		if DecimalPartValue > 0 or lAfterTheDecimalPointLen > 0 then
			RoughFinish = RoughFinish .. string.format(string.format(".%%0%dd", lAfterTheDecimalPointLen), DecimalPartValue);
		end
		-- 長さに合わせて整形する
		-- すでに文字長オーバーの場合はそのまま返す
		if string.len(RoughFinish) >= lMaxTextLen then return RoughFinish end
		-- 挿入する空白を作成する
		local PaddingText = string.rep(" ", lMaxTextLen - string.len(RoughFinish));
		return PaddingText .. RoughFinish;
	end,

	-- スキルレベルに応じて色を決める
	GetBuffLvColor = function(self, SLv, MaxLv)
		local ResultValue = "FFFFFF";
		if MaxLv >= 15 then
			if SLv <= 6 then
				ResultValue = "FFFFFF";
			elseif SLv < 15 then
				ResultValue = "108CFF";
			elseif SLv == 15 then
				ResultValue = "9F30FF";
			elseif SLv > 15 then
				ResultValue = "FF4F00";
			end
		elseif MaxLv >= 10 then
			if SLv < 5 then
				ResultValue = "FFFFFF";
			elseif SLv <= 6 then
				ResultValue = "108CFF";
			elseif SLv == 10 then
				ResultValue = "9F30FF";
			elseif SLv > 10 then
				ResultValue = "FF4F00";
			end
		elseif MaxLv >= 5 then
			if SLv < 5 then
				ResultValue = "FFFFFF";
			elseif SLv == 5 then
				ResultValue = "9F30FF";
			elseif SLv > 5 then
				ResultValue = "FF4F00";
			end
		else
		end
		return ResultValue;
	end,

	-- 値段のテキスト情報を作成する
	GetPriceText = function(self, Price, PriceInfo)
		local ReturnValue = {};
		local CustomFormat = {};
		PriceInfo.AverageWithCharge = PriceInfo.AveragePrice;
		if Me.IsVillage == nil then
			Me.IsVillage = (GetClass("Map", session.GetMapName()).isVillage == "YES") or false;
		end
		if not Me.IsVillage then
			PriceInfo.AverageWithCharge = PriceInfo.AverageWithCharge + PriceInfo.Suburb;
		end
		ReturnValue.ImpressionValue = "Empty";
		if Price < PriceInfo.CostPrice then
			ReturnValue.ImpressionValue = "BelowCost"
			CustomFormat.Price = {"#0000FF"};
			CustomFormat.Impression = {"#0000FF"};
		elseif Price == PriceInfo.CostPrice then
			ReturnValue.ImpressionValue = "AtCost"
			CustomFormat.Price = {"#0000FF"};
			CustomFormat.Impression = {"#0000FF"};
		elseif Price <= PriceInfo.CostPrice + PriceInfo.Span * 3 then
			ReturnValue.ImpressionValue = "NearCost"
			CustomFormat.Price = {"@st41b", "#00CC00"};
			CustomFormat.Impression = {"#006633"};
		elseif Price < PriceInfo.AverageWithCharge - PriceInfo.Span * 2 then
			-- お値打ち1
			ReturnValue.ImpressionValue = "GoodValue"
			CustomFormat.Price = {"@st41b", "#9999FF"};
			CustomFormat.Impression = {"#3333FF"};
		elseif Price < PriceInfo.AverageWithCharge then
			-- お値打ち2 だけど大体平均
			ReturnValue.ImpressionValue = "WithinAverage"
			CustomFormat.Price = {"@st41b", "#CCCCFF"};
		elseif Price <= PriceInfo.AverageWithCharge + PriceInfo.Span * 5 then
			-- 普通
			ReturnValue.ImpressionValue = "WithinAverage"
			CustomFormat.Price = {"@st41b"};
		elseif Price <= PriceInfo.AverageWithCharge + PriceInfo.Span * 20 then
			-- ちょい高
			ReturnValue.ImpressionValue = "ALittleExpensive"
			CustomFormat.Price = {"@st41b", "#FF9999"};
		elseif Price >= PriceInfo.AverageWithCharge * 1.8 then
			-- 異常に高い2
			ReturnValue.ImpressionValue = "RipOff"
			CustomFormat.Price = {"img NOTICE_Dm_! 26 26", "@st41b", "#FF0000"};
		elseif Price >= PriceInfo.AverageWithCharge + PriceInfo.Span * 100 then
			-- 異常に高い1
			ReturnValue.ImpressionValue = "RipOff"
			CustomFormat.Price = {"img NOTICE_Dm_! 26 26", "@st41b", "#FF0000"};
		else
			ReturnValue.ImpressionValue = "Expensive"
			CustomFormat.Price = {"@st41b", "#FF3333"};
		end
		-- 備考の文字を作成する
		ReturnValue.PriceText = Toukibi:GetStyledText(self:GetCommaedTextEx(Price), CustomFormat.Price);
		ReturnValue.ImpressionText = Toukibi:GetStyledText(Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic." .. ReturnValue.ImpressionValue), CustomFormat.Impression);
		if ReturnValue.ImpressionValue == "BelowCost" or ReturnValue.ImpressionValue == "AtCost" then
			-- 原価を表示
			ReturnValue.ComparsionText = string.format("%s:%ss"
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													 , self:GetCommaedTextEx(PriceInfo.CostPrice));

			ReturnValue.ToolTipText = self:MakePriceToolTipText(Price, PriceInfo.CostPrice, PriceInfo.AverageWithCharge, not Me.IsVillage and PriceInfo.Suburb or 0);
		elseif ReturnValue.ImpressionValue == "AtCost" then
			-- 原価との比較のみ表示
			ReturnValue.ComparsionText = string.format("%s%s"
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													 , self:GetCommaedTextEx(Price - PriceInfo.CostPrice, 0, 0, true, true));
			ReturnValue.ToolTipText = self:MakePriceToolTipText(Price, PriceInfo.CostPrice, PriceInfo.AverageWithCharge, not Me.IsVillage and PriceInfo.Suburb or 0);
		elseif ReturnValue.ImpressionValue == "RipOff" and  Price >= PriceInfo.AverageWithCharge * 1.8 then
			-- 原価・平均との割合で表示(ぼったくり対応)
			ReturnValue.ComparsionText = string.format("%sx%s  %sx%s"
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice")
													 , self:GetCommaedTextEx(Price / PriceInfo.AverageWithCharge, nil, 2)
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													 , self:GetCommaedTextEx(Price / PriceInfo.CostPrice, nil, 2));

			ReturnValue.ToolTipText = self:MakePriceToolTipText(Price, PriceInfo.CostPrice, PriceInfo.AverageWithCharge, not Me.IsVillage and PriceInfo.Suburb or 0, true);
		else
			-- 通常表示(原価と平均比較)
			ReturnValue.ComparsionText = string.format("%s%s  %s%s"
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice")
													 , self:GetCommaedTextEx(Price - PriceInfo.AverageWithCharge, nil, nil, true)
													 , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													 , self:GetCommaedTextEx(Price - PriceInfo.CostPrice, nil, nil, true));

			ReturnValue.ToolTipText = self:MakePriceToolTipText(Price, PriceInfo.CostPrice, PriceInfo.AverageWithCharge, not Me.IsVillage and PriceInfo.Suburb or 0);
		end
		if ReturnValue.ImpressionValue == "RipOff" then ReturnValue.DoAlart = true end
		return ReturnValue;
	end,

	-- 価格参考のツールチップテキストを作成する
	MakePriceToolTipText = function(self, Price, CostPrice, AveragePrice, SuburbPrice, MultiplicationMode)
		local lMultiplicationMode = MultiplicationMode or false;
		local lSuburbPrice = SuburbPrice or 0;
		local ReturnText = "";
		if lMultiplicationMode then
			-- 倍率モード
			ReturnText = string.format("%s x %s   (%s:%ss){nl}%s x %s   (%s:%ss)"
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice"), self:GetCommaedTextEx(Price / AveragePrice, 7, 2)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice"), self:GetCommaedTextEx(AveragePrice, 7)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")   , self:GetCommaedTextEx(Price / CostPrice, 7, 2)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")   , self:GetCommaedTextEx(CostPrice, 7));
		else
			-- 通常モード
			local SuburbText = "";
			if lSuburbPrice > 0 then
				SuburbText = string.format("{#FF8888}%s %s{/}{nl}"
										, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.RuralCharge"), self:GetCommaedTextEx(lSuburbPrice))
			end
			ReturnText = string.format("%s%s %s   (%s:%ss){nl}%s %s   (%s:%ss)"
									, SuburbText
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice"), self:GetCommaedTextEx(Price - AveragePrice, 7, nil, true)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.AveragePrice"), self:GetCommaedTextEx(AveragePrice, 7)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")   , self:GetCommaedTextEx(Price - CostPrice, 7, nil, true)
									, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")   , self:GetCommaedTextEx(CostPrice, 7));

		end
		return ReturnText;
	end,

	-- 警告メッセージを作成する
	MakeWarningMsg = function(self, usrSkillID, SLv, Price)
		local BuffPriceInfo = self:GetPriceInfo(usrSkillID);
		local PriceTextData = self:GetPriceText(Price, BuffPriceInfo);
		local objSkill;
		objSkill = GetClassByType("Skill", usrSkillID);

		local msg_title = string.format("%s  {s40}{b}{ol}{#EEEEEE}%s{/}{/}{/}{/}  %s"
										, "{img shophelpericon_warning 56 56}{/}"
										, Toukibi:GetResText(ResText, Me.Settings.Lang, "WarnMsg.Title")
										, "{img shophelpericon_warning 56 56}{/}");

		local msg_body = string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "WarnMsg.Body"));
		
		local msg_skillinfo = string.format("{img icon_%s 60 60}{/}  %s Lv.%s"
											, objSkill.Icon
											, objSkill.Name
											, string.format("{@st41}{#%s}%d{/}{/}"
														, self:GetBuffLvColor(SLv, BuffPriceInfo.MaxLv)
														, SLv
														)
											);

		local msg_priceinfo = string.format("%s:%s {#111111}(%s){/}{nl} {nl}{#111111}{s16}%s{/}{/}"
											, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CurrentPrice")
											, PriceTextData.PriceText
											, PriceTextData.ImpressionText
											, PriceTextData.ToolTipText);

		return string.format("%s{nl} {nl}%s{nl} {nl} {nl}%s{nl} {nl}%s"
						, msg_title
						, msg_body
						, msg_skillinfo
						, msg_priceinfo);
	end,

	-- 最終使用時間を記憶して修正移動平均とsetting.jsonを更新する
	UpdateAverage = function(self, handle, skillID, LatestPrice)
		local OwnerFamilyName = info.GetFamilyName(handle);
		local objSkill = GetClassByType("Skill", skillID);
		local objSkillName = string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.UnknownSkillID"), skillID);
		if objSkill ~= nil then
			objSkillName = objSkill.Name;
		end
		Toukibi:AddLog(string.format( Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.BuySomething")
									, OwnerFamilyName
									, objSkillName
									, self:GetCommaedTextEx(LatestPrice)
									), "Info", true, false);

		if Me.IsVillage == nil then
			Me.IsVillage = (GetClass("Map", session.GetMapName()).isVillage == "YES") or false;
		end
		if Me.Settings.UpdateAverage then
			Me.BuyHistory[handle] = Me.BuyHistory[handle] or {};
			Me.BuyHistory[handle][skillID] = Me.BuyHistory[handle][skillID] or {};
			local CurrentHistory = Me.BuyHistory[handle][skillID];
			if CurrentHistory.LatestUse == nil or os.clock() - CurrentHistory.LatestUse >= Me.Settings.RecalcInterval then
				-- 修正移動平均を求めて平均値を更新する
				if not Me.IsVillage and Me.Settings.AverageData[tostring(skillID)].Suburb ~= nil then
					Toukibi:AddLog(string.format( Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.IsSuburbMsg")
												, self:GetCommaedTextEx(LatestPrice)
												, self:GetCommaedTextEx(Me.Settings.AverageData[tostring(skillID)].Suburb)
												, self:GetCommaedTextEx(LatestPrice - Me.Settings.AverageData[tostring(skillID)].Suburb)
								   ), "Notice", true, true);
					LatestPrice = LatestPrice - Me.Settings.AverageData[tostring(skillID)].Suburb
				end
				if Me.Settings.IgnoreAwayValue then
					local PriceInfo = self:GetPriceInfo(skillID);
					if PriceInfo.DoAddInfo and LatestPrice < PriceInfo.CostPrice then
						Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.IsBelowCostMsg"), "Notice", true, false);
						LatestPrice = PriceInfo.CostPrice;
					elseif PriceInfo.DoAddInfo and math.abs(LatestPrice - PriceInfo.AveragePrice) > PriceInfo.Span * 30 then
						Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.IsFartherValueMsg"), "Notice", true, false);
						return;
					end
				end
				Me.Settings.AverageData[tostring(skillID)].Price = (Me.Settings.AverageData[tostring(skillID)].Price * (Me.Settings.AverageNCount - 1) + LatestPrice) / Me.Settings.AverageNCount
				CurrentHistory.LatestUse = os.clock();
				Toukibi:AddLog(string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.UpdateAveragePrice")
							 , objSkillName
							 , self:GetCommaedTextEx(Me.Settings.AverageData[tostring(skillID)].Price, nil, 2)
							 ), "Info", true, false);

				-- 設定情報を保存する
				Toukibi:SaveTable(Me.SettingFilePathName, Me.Settings);
			else
				Toukibi:AddLog(string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.IsShorterInterval")
							 , os.clock() - CurrentHistory.LatestUse
							 , Me.Settings.RecalcInterval
							 ), "Info", true, false);
			end
		end
	end

}
Me.LibPrice = LibPrice;

-- ==================================
--      個別のプログラムここから
-- ==================================

-- ==================================
--  設定関連
-- ==================================

-- 設定書き込み
local function SaveSetting()
	Toukibi:SaveTable(Me.SettingFilePathName, Me.Settings);
	Toukibi:SaveTable(Me.FavoriteFilePathName, Me.FavoriteList);
end

function Me.Save()
	SaveSetting()
end

local function MargeAverageDataRecord(SkillID, Force, pPrice, pRadix, pSuburb)
	Me.Settings.AverageData[tostring(SkillID)] = Me.Settings.AverageData[tostring(SkillID)] or {};
	if Force then --リセット
		Me.Settings.AverageData[tostring(SkillID)].Price  = pPrice;
		Me.Settings.AverageData[tostring(SkillID)].Radix  = pRadix;
		Me.Settings.AverageData[tostring(SkillID)].Suburb = pSuburb;
	else --読み込み(ない場合はデフォルト適用)
		Me.Settings.AverageData[tostring(SkillID)].Price  = Me.Settings.AverageData[tostring(SkillID)].Price  or pPrice;
		Me.Settings.AverageData[tostring(SkillID)].Radix  = Me.Settings.AverageData[tostring(SkillID)].Radix  or pRadix;
		Me.Settings.AverageData[tostring(SkillID)].Suburb = Me.Settings.AverageData[tostring(SkillID)].Suburb or pSuburb;
	end
end

-- 平均価格をリセット
local function MargeDefaultPrice(Force, DoSave)
	DoSave = Toukibi:GetValueOrDefault(DoSave, true);
	-- ルートの入れ物
	Me.Settings.AverageData = Me.Settings.AverageData or {};
	MargeAverageDataRecord("dummy", true,  100,  1,  10); -- ダミー
	-- 各データ
	MargeAverageDataRecord("10703", Force,  170,  1,  15); -- リペア
	MargeAverageDataRecord("40203", Force,  750, 10, 100); -- ブレス
	MargeAverageDataRecord("40205", Force,  850, 10, 100); -- サクラ
	MargeAverageDataRecord("40201", Force, 1050, 10,  50); -- アスパ
	MargeAverageDataRecord("21003", Force, 6500, 50, 100); -- ジェムロースティング
	MargeAverageDataRecord("31501", Force,  170,  1,  15); -- 鑑定
	if Force then
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.ResetAveragePrice"), "Notice", true, false);
	end
	if DoSave then SaveSetting() end
end

-- デフォルト設定(ForceがTrueでない場合は、既存の値はそのまま引き継ぐ)
local function MargeDefaultSetting(Force, DoSave)
	DoSave = Toukibi:GetValueOrDefault(DoSave, true);
	Me.Settings = Me.Settings or {};
	Me.Settings.DoNothing				= Toukibi:GetValueOrDefault(Me.Settings.DoNothing			, false, Force);
	Me.Settings.Lang					= Toukibi:GetValueOrDefault(Me.Settings.Lang				, Toukibi:GetDefaultLangCode(), Force);
	Me.Settings.ShowMessageLog			= Toukibi:GetValueOrDefault(Me.Settings.ShowMessageLog		, false, Force);
	Me.Settings.ShowMsgBoxOnBuffShop	= Toukibi:GetValueOrDefault(Me.Settings.ShowMsgBoxOnBuffShop, true, Force);
	Me.Settings.UpdateAverage			= Toukibi:GetValueOrDefault(Me.Settings.UpdateAverage		, true, Force);
	Me.Settings.AddInfoToBaloon			= Toukibi:GetValueOrDefault(Me.Settings.AddInfoToBaloon		, true, Force);
	Me.Settings.EnableBaloonRightClick	= Toukibi:GetValueOrDefault(Me.Settings.EnableBaloonRightClick, true, Force);
	Me.Settings.AverageNCount			= Toukibi:GetValueOrDefault(Me.Settings.AverageNCount		, 30, Force);
	Me.Settings.RecalcInterval			= Toukibi:GetValueOrDefault(Me.Settings.RecalcInterval		, 60, Force);
	Me.Settings.IgnoreAwayValue			= Toukibi:GetValueOrDefault(Me.Settings.IgnoreAwayValue		, true, Force);
	Me.Settings.Repair_SelectByDur		= Toukibi:GetValueOrDefault(Me.Settings.Repair_SelectByDur	, true, Force);
	Me.Settings.Repair_DurValue			= Toukibi:GetValueOrDefault(Me.Settings.Repair_DurValue		, 3, Force);
	Me.Settings.Repair_ShowDurGauge		= Toukibi:GetValueOrDefault(Me.Settings.Repair_ShowDurGauge	, true, Force);
	Me.Settings.Repair_ShowDurValue		= Toukibi:GetValueOrDefault(Me.Settings.Repair_ShowDurValue	, false, Force);
	if Force then
		Toukibi:AddLog(Toukibi:GetResText(Toukibi.CommonResText, Me.Settings.Lang, "System.CompleteLoadDefault"), "Info", true, false);
	end
	if DoSave then SaveSetting() end
	MargeDefaultPrice(Force, DoSave);
end

-- 設定読み込み
local function LoadSetting()
	local objReadValue, objError = Toukibi:LoadTable(Me.SettingFilePathName);
	if objError then
		local CurrentLang = "en"
		if Me.Settings == nil then
			CurrentLang = Toukibi:GetDefaultLangCode() or CurrentLang;
		else
			CurrentLang = Me.Settings.Lang or CurrentLang;
		end
		Toukibi:AddLog(string.format("%s{nl}{#331111}%s{/}", Toukibi:GetResText(Toukibi.CommonResText, CurrentLang, "System.ErrorToUseDefaults"), tostring(objError)), "Caution", true, false);
		MargeDefaultSetting(true, false);
	else
		Me.Settings = objReadValue;
		MargeDefaultSetting(false, false);
	end
	Toukibi:AddLog(Toukibi:GetResText(Toukibi.CommonResText, Me.Settings.Lang, "System.CompleteLoadSettings"), "Info", true, false);
	-- お気に入り情報を読み出す
	objReadValue, objError = Toukibi:LoadTable(Me.FavoriteFilePathName);
	if objError then
		Me.FavoriteList = Me.FavoriteList or {};
		Me.SaveSetting();
	else
		Me.FavoriteList = objReadValue or {};
	end
	Me.Settings.OptionFrameIsAvailable = false;
end

function Me.Load()
	LoadSetting()
end

-- ===========================
--      露店お気に入り関連
-- ===========================

-- その人のお気に入り度を返す
function Me.GetFavoriteStatus(handle)
	local AID = world.GetActor(handle):GetPCApc():GetAID();
	local FavoriteItem = Me.FavoriteList[AID];
	local FavoriteState = MyEnums.FavoriteState.NoData;
	local DisplayState = MyEnums.DisplayState.NoMark;
	-- フレンドリストへ情報を照合する
	if session.friends.GetFriendByAID(FRIEND_LIST_BLOCKED, AID) ~= nil then
		-- ブロック対象者
		FavoriteState = MyEnums.FavoriteState.Blocked;
	elseif session.friends.GetFriendByAID(FRIEND_LIST_COMPLETE, AID) ~= nil then
		-- フレンド対象者
		FavoriteState = MyEnums.FavoriteState.Friend;
	end
	-- いいねしているかチェック
	if FavoriteState == MyEnums.FavoriteState.NoData and not session.world.IsIntegrateServer() then -- 統合サーバー状態でなければ
		if session.likeit.AmILikeYou(info.GetFamilyName(handle)) then
			FavoriteState = MyEnums.FavoriteState.Liked;
		end
	end
	if FavoriteItem ~= nil then
		-- カスタム記録値がある場合はその結果を使用する
		DisplayState = FavoriteItem;
	else
		-- カスタム記録値がない場合はいいね・フレンド・ブロック情報から結果を返す
		if FavoriteState == MyEnums.FavoriteState.Blocked then
			-- ブロック対象者
			DisplayState = MyEnums.DisplayState.HateMark;
		elseif FavoriteState == MyEnums.FavoriteState.Friend then
			-- フレンド対象者
			DisplayState = MyEnums.DisplayState.Liked;
		elseif FavoriteState == MyEnums.FavoriteState.Liked then
			-- いいね対象者
			DisplayState = MyEnums.DisplayState.Liked;
		end
	end
	return DisplayState, FavoriteState;
end

-- 看板に情報を追加する
local function AddToShopBaloon(title, sellType, handle, skillID, skillLv)
	-- 看板のフレームを再取得する
	local frame = ui.GetFrame("SELL_BALLOON_" .. handle);
	if frame == nil then return end
	-- CHAT_SYSTEM("SELL_BALLOON_" .. handle)
	local originalText = frame:GetUserValue("SHOPHELPER_ORIGINAL_TEXT");
	if originalText == nil or originalText == "None" then
		frame:SetUserValue("SHOPHELPER_ORIGINAL_TEXT", title);
		originalText = title;
	end
	-- オリジナルのテキストを保存しておく
	local NewLabelText = "";
	if Me.Settings.AddInfoToBaloon then
		-- 落書きする文字
		NewLabelText = originalText
		-- NewLabelText = "{img NOTICE_Dm_! 32 32}" .. originalText
	else
		-- 元の文字
		NewLabelText = originalText
	end
	local BasePic = frame:GetChild("bg");
	local lvBox = frame:GetChild("withLvBox");
	local lblNotmalText = frame:GetChild("text");
	local lvTitle = lvBox:GetChild('lv_title');
	if sellType == AUTO_SELL_BUFF or sellType == AUTO_SELL_GEM_ROASTING or sellType == AUTO_SELL_SQUIRE_BUFF or sellType == AUTO_SELL_ENCHANTERARMOR or sellType == AUTO_SELL_APPRAISE then
		ToukibiUI:SetTextByKey(lvTitle, "value", NewLabelText);
		lblNotmalText:ShowWindow(0);
		lvBox:ShowWindow(1);
	else
		ToukibiUI:SetTextByKey(lblNotmalText, "value", NewLabelText);
		lblNotmalText:ShowWindow(1);
		lvBox:ShowWindow(0);
	end	
	-- オリジナルのアイコンを上書きする
	local DisplayState = Me.GetFavoriteStatus(handle);
	-- CHAT_SYSTEM(string.format("[%s] %s: %s", handle, info.GetFamilyName(handle)	, DisplayState))
	DESTROY_CHILD_BYNAME(frame, "SHOPHELPER_");
	if Me.Settings.AddInfoToBaloon and DisplayState ~= nil and DisplayState ~= MyEnums.DisplayState.NoMark then
		local objAdditionalIcon = nil;
		if DisplayState <= MyEnums.DisplayState.HateMark then
			objAdditionalIcon = tolua.cast(frame:CreateOrGetControl("picture", "SHOPHELPER_ADDITIONAL_ICON", 22, 18, 28, 28), "ui::CPicture");
		elseif DisplayState >= MyEnums.DisplayState.Liked then
			objAdditionalIcon = tolua.cast(frame:CreateOrGetControl("picture", "SHOPHELPER_ADDITIONAL_ICON", 0, 0, 48, 48), "ui::CPicture");
		end
		if objAdditionalIcon ~= nil then
			objAdditionalIcon:EnableHitTest(0); 
			objAdditionalIcon:SetEnable(1);
			objAdditionalIcon:SetEnableStretch(1);
			objAdditionalIcon:EnableChangeMouseCursor(0);
			if DisplayState <= MyEnums.DisplayState.HateMark then
			--barrack_delete_btn_clicked
				objAdditionalIcon:SetImage("shophelpericon_warning"); 
			elseif DisplayState >= MyEnums.DisplayState.Favorite then
				objAdditionalIcon:SetImage("Hit_indi_icon"); 
			end
			objAdditionalIcon:ShowWindow(1); 
		end
		if DisplayState <= MyEnums.DisplayState.Never then
			frame:Resize(0, 0);
		else
			frame:Resize(300, 100);
		end
	else
		frame:Resize(300, 100);
	end
	BasePic:SetEventScript(ui.RBUTTONDOWN, 'TOUKIBI_SHOPHELPER_OPEN_BALOON_CONTEXT_MENU');
	lvBox:SetEventScript(ui.RBUTTONDOWN, 'TOUKIBI_SHOPHELPER_OPEN_BALOON_CONTEXT_MENU');
end

function Me.RedrawShopBaloon(handle)
	if handle == nil or info.IsPC(handle) ~= 1 then return end
	local frame = ui.GetFrame("SELL_BALLOON_" .. handle);
	if frame == nil then return end
	local sellType = frame:GetUserIValue("SELL_TYPE");
	local handle = frame:GetUserIValue("HANDLE");
	local originalText = frame:GetUserValue("SHOPHELPER_ORIGINAL_TEXT");
	if originalText == nil or originalText == "None" then
		if sellType == AUTO_SELL_BUFF or sellType == AUTO_SELL_GEM_ROASTING 
										or sellType == AUTO_SELL_SQUIRE_BUFF 
										or sellType == AUTO_SELL_ENCHANTERARMOR then

			originalText = frame:GetChild("withLvBox"):GetChild('lv_title'):GetTextByKey("value");
		else
			originalText = frame:GetChild("text"):GetTextByKey("value");
		end	
	end
	AddToShopBaloon(originalText, sellType, handle);
end

function Me.RedrawAllShopBaloon()
	local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 1000000, "ALL");
	for i = 1, selectedObjectsCount do
		Me.RedrawShopBaloon(GetHandle(selectedObjects[i]));
	end
end

-- ================================
--            バフ屋関連
-- ================================

-- 指定したバフがかかっているかをチェックする
function Me.BuffIsOngoing(SkillID)
	local dicBuffID = {};
	dicBuffID[40203] = 147; -- ブレス
	dicBuffID[40205] = 100; -- サクラ
	dicBuffID[40201] = 146; -- アスパ
	local handle = session.GetMyHandle();
	local buffCount = info.GetBuffCount(handle);
	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		if buff ~= nil and buff.buffID == dicBuffID[SkillID] then
			return true;
		end
	end
	return false;
end

-- バフショップのバフ項目に追加する
function Me.AddInfoToBuffSellerSlot(BaseFrame, info)
	if BaseFrame == nil then return nil end
	local ParentFrame = BaseFrame:GetTopParentFrame();
	if ParentFrame == nil then return nil end
	if ParentFrame:GetUserIValue("HANDLE") ==  session.GetMyHandle() then return nil end
	local BuffPriceInfo = LibPrice:GetPriceInfo(info.classID);
	if BuffPriceInfo.DoAddInfo then
		local PriceTextData = LibPrice:GetPriceText(info.price, BuffPriceInfo)
		local lblSLv = BaseFrame:GetChild("skilllevel");
		lblSLv:SetTextByKey("value", string.format("{@st41}{#%s}%d{/}{/}"
												, LibPrice:GetBuffLvColor(info.level, BuffPriceInfo.MaxLv)
												, info.level));

		local lblPrice = BaseFrame:GetChild("price")
		lblPrice:SetTextByKey("value", PriceTextData.PriceText);
		lblPrice:SetTextTooltip(PriceTextData.ToolTipText);

		-- ボタンを上へ動かす
		local objTextItem = ToukibiUI:AddRichTextToCenter(BaseFrame, "ShopHelper_lblPriceInfo", PriceTextData.ImpressionText, 250, 40, 150, 20, 16);
		objTextItem:SetTextTooltip(PriceTextData.ToolTipText);
		local BuyButton = BaseFrame:GetChild("btn");
		if BuyButton ~= nil then
			tolua.cast(BuyButton, 'ui::CButton');
			ToukibiUI:SetMargin(BuyButton, 280 - 30, nil, nil, nil);
			BuyButton:Resize(118 + 30, 45);
			if PriceTextData.DoAlart then
				BuyButton:SetText(Toukibi:GetResText(ResText, Me.Settings.Lang, "BtnText.lblWarning"));
			else
				BuyButton:SetText("");
				if Me.BuffIsOngoing(info.classID) then
					BuyButton:SetText(Toukibi:GetResText(ResText, Me.Settings.Lang, "BtnText.lblOngoing"));
				else
					BuyButton:SetText(Toukibi:GetResText(ResText, Me.Settings.Lang, "BtnText.lblBuy"));
				end
			end
			-- 購入時の注意フラグを追加する
			BaseFrame:SetUserValue("ImpressionValue", PriceTextData.ImpressionValue);
		end
	end
end

-- バフ商店の購入ボタンをクリックしたときの処理
function Me.btnBuyBuffAutosell_Click(ctrlSet, btn)
	local frame = ctrlSet:GetTopParentFrame();
	local sellType = frame:GetUserIValue("SELLTYPE");
	local groupName = frame:GetUserValue("GROUPNAME");
	local index = ctrlSet:GetUserIValue("INDEX");
	local itemInfo = session.autoSeller.GetByIndex(groupName, index);
	local buycount =  GET_CHILD(ctrlSet, "price");
	-- 勝手に埋め込んだパラメータを取り出す
	local DoAlart = (ctrlSet:GetUserValue("ImpressionValue") == "RipOff");
	if itemInfo == nil then
		return;
	end

	local cnt = 1;
	if buycount ~= nil then
		cnt = buycount:GetNumber();
	end

	local totalPrice = itemInfo.price * cnt;
	local myMoney = GET_TOTAL_MONEY();
	if totalPrice > myMoney or  myMoney <= 0 then
		ui.SysMsg(ClMsg("NotEnoughMoney"));
		return;
	end

	-- 飛び先も自前で偽装する(価格情報が欲しいため)
	local strscp = string.format("TOUKIBI_SHOPHELPER_EXEC_BUY_BUFF(%d, %d, %d, %d, %d, %d)", frame:GetUserIValue("HANDLE"), index, cnt, sellType, itemInfo.classID, itemInfo.price);
	if DoAlart then
		-- 価格データを作り直す(本当はポインター的な手法で渡したかった)
		local BuffPriceInfo = Me.GetPriceInfo(itemInfo.classID);
		local PriceTextData = Me.GetPriceText(itemInfo.price, BuffPriceInfo);
		local objSkill = GetClassByType("Skill", itemInfo.classID);

		local msg_title = string.format("%s  {s40}{b}{ol}{#CC0808}%s{/}{/}{/}{/}  %s"
									  , "{img NOTICE_Dm_! 56 56}{/}"
									  , Me.ResText[Me.Settings.Lang].data.WarningMsg.title
									  , "{img NOTICE_Dm_! 56 56}{/}");

		local msg_body = string.format(Me.ResText[Me.Settings.Lang].data.WarningMsg.body);
		
		local msg_skillinfo = string.format("{img icon_%s 60 60}{/}  %s Lv.%s"
										  , objSkill.Icon
										  , objSkill.Name
										  , string.format("{@st41}{#%s}%d{/}{/}"
														, Me.GetBuffLvColor(itemInfo.level, BuffPriceInfo.MaxLv)
														, itemInfo.level
														)
											);

		local msg_priceinfo = string.format("%s:%s {#111111}(%s){/}{nl} {nl}{#111111}{s16}%s{/}{/}"
										  , Me.ResText[Me.Settings.Lang].data.CurrentPrice
										  , PriceTextData.PriceText
										  , PriceTextData.ImpressionText
										  , PriceTextData.ToolTipText);

		local msg = string.format("%s{nl} {nl}%s{nl} {nl} {nl}%s{nl} {nl}%s"
								, msg_title
								, msg_body
								, msg_skillinfo
								, msg_priceinfo);
		
		ui.MsgBox(msg, strscp, "None");
	else
		if Me.Settings.ShowMsgBoxOnBuffShop then
			local msg = ClMsg("ReallyBuy?")
			ui.MsgBox(msg, strscp, "None");
		else
			TOUKIBI_SHOPHELPER_EXEC_BUY_BUFF(frame:GetUserIValue("HANDLE"), index, cnt, sellType, itemInfo.classID, itemInfo.price);
		end
	end
end

-- バフ屋のバフの購入アクション
function TOUKIBI_SHOPHELPER_EXEC_BUY_BUFF(handle, index, cnt, sellType, skillID, Price)
	-- すでにバフがかかっている場合はメッセージを出して強制的に処理中止する
	if Me.BuffIsOngoing(skillID) then
		local objSkill = GetClassByType("Skill", skillID);
		local objSkillName;
		if objSkill ~= nil then
			objSkillName = objSkill.Name;
		else
			objSkillName = string.format(Me.ResText[Me.Settings.Lang].data.UnknownSkillID, skillID);
		end
		ui.MsgBox(string.format(Me.ResText[Me.Settings.Lang].data.IsGoingMsg, objSkillName))
		return;
	end
	-- 最終使用時間を記憶する
	Me.LibPrice:UpdateAverage(handle, skillID, Price)
	EXEC_BUY_AUTOSELL(handle, index, cnt, sellType);
end

-- ================================
--            修理屋関連
-- ================================

-- ゲージのスキンを選択する(30/50/80/100で色が変わる)
local function GetGaugeSkin(current, max)
	local GaugeColor = "green";
	if current * 10 < max * 3 then
		GaugeColor = "red";
	elseif current * 10 < max * 5 then
		GaugeColor = "orange";
	elseif current * 10 < max * 8 then
		GaugeColor = "yellow";
	elseif current <= max then
		GaugeColor = "green";
	else
		GaugeColor = "blue_ongreen";
	end
	return "shophelper_" .. GaugeColor;
end

-- ゲージのスキンを選択する(30/50/80/100で色が変わる)
local function GetDurTextColor(current, max)
	local TextColor = "88FF88";
	if current * 10 < max * 3 then
		TextColor = "FF3333";
	elseif current * 10 < max * 5 then
		TextColor = "FF8800";
	elseif current * 10 < max * 8 then
		TextColor = "FFFF66";
	elseif current <= max then
		TextColor = "88FF88";
	else
		TextColor = "66AAFF";
	end
	return "#" .. TextColor;
end

-- 修理商店に情報を付加する
function Me.AddInfoToSquireBuff(BaseFrame)
	if BaseFrame == nil then return nil end
	if BaseFrame:GetUserIValue("HANDLE") == session.GetMyHandle() then return nil end

	local RepairFrame = BaseFrame:GetChild("repair");
	if RepairFrame ~= nil then
		-- 各種パネルの位置を下へ動かす
		ToukibiUI:SetMargin(RepairFrame:GetChild("TitleSkin"), nil, 94 + 20, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("Money"), nil, 102 + 20, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("reqitemMoney"), nil, 100 + 20, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("selectAllBtn"), nil, 135 + 50, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("selectEquipedBtn"), nil, 135 + 50, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("repairlistGbox"), nil, 140 + 60, nil, nil);
		-- できたスペースに追加情報を書き込む
		local OwnerFamilyName = tostring(info.GetFamilyName(BaseFrame:GetUserIValue("HANDLE")));
		local SLv = BaseFrame:GetUserIValue("SKILLLEVEL");
		local Price = BaseFrame:GetUserIValue("PRICE");
		local PriceInfo = LibPrice:GetPriceInfo(10703); -- リペアのスキルID
		local PriceTextData = LibPrice:GetPriceText(Price, PriceInfo)
		ToukibiUI:AddRichText(BaseFrame , "ShopHelper_lblOwnerInfo"
					 , string.format("{@st42b}{#%s}Lv.%d{/}{/}  %s"
					 			   , LibPrice:GetBuffLvColor(SLv, PriceInfo.MaxLv)
								   , SLv
								   , string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "ShopName.SquireBuff"), OwnerFamilyName)
					 				)
					 , 40, 120, 420, 20, 16);
		local lblPrice = ToukibiUI:AddRichText(BaseFrame
									  , "ShopHelper_lblPriceInfo"
									  , string.format("%s：%s  %s (%s)"
													, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													, PriceTextData.PriceText
													, PriceTextData.ImpressionText
													, PriceTextData.ComparsionText)
									  , 40, 200, 420, 20, 16);
		lblPrice:SetTextTooltip(PriceTextData.ToolTipText);
		-- 耐久度で選ぶUIを追加する
		local lblSelectByDur = ToukibiUI:AddRichText(RepairFrame , "ShopHelper_lblSelectByDur"
							, Toukibi:GetResText(ResText, Me.Settings.Lang, "Other.DurabilityLeft")
							, 20, 750, 240, 20, 16);
		local btnSelectByDur = ToukibiUI:AddButton(RepairFrame
									  , "ShopHelper_btnSelectByDur"
									  , Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.SelectAll")
									  , 0, 0, 120, 40);
		btnSelectByDur:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(btnSelectByDur, 0, 768, 20, 0);
		local sldDur = ToukibiUI:AddSlider(RepairFrame , "ShopHelper_sldDur", 60, 780, 200, 20);
		sldDur:SetMinSlideLevel(1);
		sldDur:SetMaxSlideLevel(12);
		sldDur:SetLevel(Me.Settings.Repair_DurValue);
		local lblDurValue = ToukibiUI:AddRichText(RepairFrame , "ShopHelper_lblDurValue"
							, Me.Settings.Repair_DurValue * 10 .. "％"
							, 0, 0, 60, 20, 16);
		lblDurValue:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(lblDurValue, 0, 778, 160, 0);

		local chkShowDurGauge = ToukibiUI:AddCheckBox(RepairFrame , "ShopHelper_chkShowDurGauge"
							, Toukibi:GetResText(ResText, Me.Settings.Lang, "Other.ShowDurGauge")
							, 40, 825, 240, 20, 16);
		ToukibiUI:SetChecked(chkShowDurGauge, Me.Settings.Repair_ShowDurGauge)

		local chkShowDurValue = ToukibiUI:AddCheckBox(RepairFrame , "ShopHelper_chkShowDurValue"
							, Toukibi:GetResText(ResText, Me.Settings.Lang, "Other.ShowDurValue")
							, 40, 850, 240, 20, 16);
		ToukibiUI:SetChecked(chkShowDurValue, Me.Settings.Repair_ShowDurValue)


		-- 購入時の注意フラグを追加する
		BaseFrame:SetUserValue("ImpressionValue", PriceTextData.ImpressionValue);

		btnSelectByDur:SetEventScript(ui.LBUTTONDOWN, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		btnSelectByDur:SetEventScriptArgNumber(ui.LBUTTONDOWN, 2);
		chkShowDurGauge:SetEventScript(ui.LBUTTONDOWN, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		chkShowDurGauge:SetEventScriptArgNumber(ui.LBUTTONDOWN, 1);
		chkShowDurValue:SetEventScript(ui.LBUTTONDOWN, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		chkShowDurValue:SetEventScriptArgNumber(ui.LBUTTONDOWN, 1);
		sldDur:SetEventScript(ui.LBUTTONDOWN, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		sldDur:SetEventScriptArgNumber(ui.LBUTTONDOWN, 0);
		sldDur:SetEventScript(ui.LBUTTONUP, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		sldDur:SetEventScriptArgNumber(ui.LBUTTONUP, 0);
		sldDur:SetEventScript(ui.MOUSEWHEEL, "TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED");
		sldDur:SetEventScriptArgNumber(ui.MOUSEWHEEL, 0);
		Me.AddDurGauge()
		
	end
end

-- 修理露店の装備一覧にゲージを表示する
function Me.AddDurGauge()
	local TopParent = ui.GetFrame("itembuffrepair");
	if TopParent == nil or TopParent:IsVisible() == 0 then return end
	-- スロットの中身を調べる
	local slotSet = GET_CHILD_RECURSIVELY(TopParent, "slotlist", "ui::CSlotSet")	
	local slotCount = slotSet:GetSlotCount();
	for i = 0, slotCount - 1 do
		local slot = slotSet:GetSlotByIndex(i);
		local objIcon = slot:GetIcon();
		if objIcon ~= nil then
			local iconInfo = objIcon:GetInfo();
			local objItem = GetIES(GET_ITEM_BY_GUID(iconInfo:GetIESID()):GetObject());
			local intValue = objItem.Dur;
			local intMaxValue = objItem.MaxDur;
	--log(string.format("%s:%s/%s", objItem.Name, objItem.Dur, objItem.MaxDur));
			DESTROY_CHILD_BYNAME(slot, "ShopHelper");
			if Me.Settings.Repair_ShowDurValue then
				local Offset = -2;
				if Me.Settings.Repair_ShowDurGauge then
					Offset = Offset + 6;
				end
				-- テキストを追加
				local txtDur = tolua.cast(slot:CreateOrGetControl("richtext", "ShopHelper_DurValue", 0, 0, 30, 16), "ui::CRichText");
				txtDur:SetGravity(ui.RIGHT, ui.BOTTOM);
				txtDur:SetMargin(0, 0, 0, Offset);
				txtDur:EnableHitTest(0);
				txtDur:SetText(string.format("{%s}{s12}{ol}%s{/}{/}{/}", GetDurTextColor(intValue, intMaxValue), math.ceil(objItem.Dur / 100)));
			end
			-- ゲージを追加
			local objDurGauge = tolua.cast(slot:CreateOrGetControl("gauge", "ShopHelper_DurGauge", 0, 0, 50, 6), "ui::CGauge");
			if objDurGauge ~= nil then
				if Me.Settings.Repair_ShowDurGauge then
					objDurGauge:ShowWindow(1);
					objDurGauge:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
					objDurGauge:SetMargin(0, 0, 0, 0);
					objDurGauge:SetSkinName(GetGaugeSkin(intValue, intMaxValue));
					if intValue > intMaxValue then intValue = intValue - intMaxValue end
					if DebugMode then
						objDurGauge:SetPoint(0,100); -- Gaugeのスキン変更を反映させるには値が変わる(厳密にはグラフィック更新)必要があるみたい
					end
					objDurGauge:SetPoint(intValue, intMaxValue);
				else
					objDurGauge:ShowWindow(0);
				end
			end
		end
	end
end

-- 修理商店の修理ボタンをクリックしたときの処理
function Me.btnBuySquireRepair_Click(frame)
	local ParentFrame = frame:GetTopParentFrame();
	-- パラメータを取り出す
	local SLv = ParentFrame:GetUserIValue("SKILLLEVEL");
	local RepairPrice = ParentFrame:GetUserIValue("PRICE");
	-- 勝手に埋め込んだパラメータを取り出す
	local DoAlart = (ParentFrame:GetUserValue("ImpressionValue") == "RipOff");
	if DoAlart then
		local strscp = string.format("TOUKIBI_SHOPHELPER_EXEC_SQUIRE_REPAIR('%s')", ParentFrame:GetName());
		local msg = LibPrice:MakeWarningMsg(10703, SLv, RepairPrice)
		ui.MsgBox(msg, strscp, "None");
	else
		TOUKIBI_SHOPHELPER_EXEC_SQUIRE_REPAIR(ParentFrame:GetName())
	end
end

-- 修理アクション
function TOUKIBI_SHOPHELPER_EXEC_SQUIRE_REPAIR(ParentFrameName)
	local ParentFrame = ui.GetFrame(ParentFrameName);
	local handle = ParentFrame:GetUserValue("HANDLE");
	local skillName = ParentFrame:GetUserValue("SKILLNAME");
	local RepairPrice = ParentFrame:GetUserIValue("PRICE");
	
	session.ResetItemList();
	local slotSet = GET_CHILD_RECURSIVELY(ParentFrame, "slotlist", "ui::CSlotSet")
	
	if slotSet:GetSelectedSlotCount() < 1 then
		ui.MsgBox(ScpArgMsg("SelectRepairItemPlz"))
		return;
	end

	-- 最終使用時間を記憶する
	LibPrice:UpdateAverage(handle, 10703, RepairPrice)

	for i = 0, slotSet:GetSelectedSlotCount() -1 do
		local slot = slotSet:GetSelectedSlot(i);
		local Icon = slot:GetIcon();
		local iconInfo = Icon:GetInfo();

		session.AddItemID(iconInfo:GetIESID());
	end
	session.autoSeller.BuyItems(handle, AUTO_SELL_SQUIRE_BUFF, session.GetItemIDList(), skillName);
	ReserveScript("TOUKIBI_SHOPHELPER_ADDDURGAUGE()", 0.3);
end

-- 修理完了の遅延コールバック(耐久度ゲージ更新用)
function TOUKIBI_SHOPHELPER_ADDDURGAUGE()
	Me.AddDurGauge()
end

-- 修理画面の追加コントロールの状態保存コールバック
function TOUKIBI_SHOPHELPER_REPAIRSETTING_CHANGED(frame, ctrl, text, number)
	-- 耐久度で選択関連のオプションを保存する
	local TopParent = ui.GetFrame("itembuffrepair");
	local RepairFrame = TopParent:GetChild("repair");
	if RepairFrame ~= nil then
		local ReadValue;
		ReadValue = ToukibiUI:GetSliderValueByName(RepairFrame, "ShopHelper_sldDur")
	--	log(tostring(ReadValue))
		GET_CHILD(RepairFrame, "ShopHelper_lblDurValue", "ui::CRichText"):SetText(string.format("{@st66}%s％{/}",ReadValue * 10));
		Me.Settings.Repair_DurValue = ReadValue;
		ReadValue = ToukibiUI:GetChecked(GET_CHILD(RepairFrame, "ShopHelper_chkShowDurGauge", "ui::CCheckBox"));
		Me.Settings.Repair_ShowDurGauge = ReadValue;
		ReadValue = ToukibiUI:GetChecked(GET_CHILD(RepairFrame, "ShopHelper_chkShowDurValue", "ui::CCheckBox"));
		Me.Settings.Repair_ShowDurValue = ReadValue;
	end
	SaveSetting()
--	log(tostring(number))
	if number == 1 then
		Me.AddDurGauge()
	elseif number == 2 then
		Me.SelectItem(false, Me.Settings.Repair_DurValue)
	end
end


function Me.SelectItem(OnlyEquip, DurValue)
	DurValue = DurValue or 1000;
	OnlyEquip = OnlyEquip or false;
	local TopParent = ui.GetFrame("itembuffrepair");
	if TopParent == nil or TopParent:IsVisible() == 0 then return end
	-- スロットの中身を調べる
	local slotSet = GET_CHILD_RECURSIVELY(TopParent, "slotlist", "ui::CSlotSet")	
	local slotCount = slotSet:GetSlotCount();
	local isselected = TopParent:GetUserValue("SELECTED");
	-- 一度選択を解除する
	for i = 0, slotCount - 1 do
		local slot = slotSet:GetSlotByIndex(i);
		if slot:GetIcon() ~= nil then
			slot:Select(0)
		end
	end

	local bolFound = false;
	local equipList = session.GetEquipItemList();
	local totalcont = 0;
	for i = 0, slotCount - 1 do
		local slot = slotSet:GetSlotByIndex(i);
		if slot:GetIcon() ~= nil then
			if (OnlyEquip and isselected == "SelectedEquiped") or (not OnlyEquip and isselected == "SelectedAll") then
				slot:Select(0)
			else
				local IsMatch = not OnlyEquip
				if not IsMatch then
					for i = 0, equipList:Count() - 1 do
						local equipItem = equipList:Element(i);					
						if equipItem:GetIESID() == slot:GetIcon():GetInfo():GetIESID() then
							IsMatch = true;
							break;
						end
					end
				end
				if IsMatch then
					local Icon = slot:GetIcon();
					local iconInfo = Icon:GetInfo();
					local invitem = GET_ITEM_BY_GUID(iconInfo:GetIESID());
					local itemobj = GetIES(invitem:GetObject());
					local needItem, needCount = ITEMBUFF_NEEDITEM_Squire_Repair(GetMyPCObject(), itemobj);
					if itemobj.MaxDur * DurValue > itemobj.Dur * 10 then
						slot:Select(1)
						totalcont = totalcont + needCount;
						bolFound = true;
					end
				end
			end
		end
	end
	slotSet:MakeSelectionList();
	
	UPDATE_SQIOR_REPAIR_MONEY(TopParent, totalcont);

	if bolFound then
		TopParent:SetUserValue("SELECTED", "SelectedAll");
	else
		TopParent:SetUserValue("SELECTED", "NotSelected");
	end
end


-- ================================
--      ジェムロースティング関連
-- ================================

-- ジェムロースティング店に情報を付加する
function Me.AddInfoToGemRoasting(BaseFrame)
	if BaseFrame == nil then return nil end
	if BaseFrame:GetUserIValue("HANDLE") ==  session.GetMyHandle() then return nil end

	local RepairFrame = BaseFrame:GetChild("roasting");
	if RepairFrame ~= nil then
		-- 各種パネルの位置を下へ動かす
		local TargetControl = nil;
		ToukibiUI:SetMargin(RepairFrame:GetChild("slot_bg_img"), nil, 50 + 30 + 60, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("slot"), nil, 110 + 30 + 60, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("slotName"), nil, 250 + 30 + 60, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("TitleSkin"), nil, 47 + 30, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("Money"), nil, 56 + 30, nil, nil);
		ToukibiUI:SetMargin(RepairFrame:GetChild("reqitemMoney"), nil, 56 + 30, nil, nil);

		TargetControl = RepairFrame:GetChild("effectGbox");
			ToukibiUI:SetMargin(RepairFrame:GetChild("effectGbox"), nil, 230 + 30 + 60, nil, nil);

		-- できたスペースに追加情報を書き込む
		local OwnerFamilyName = tostring(info.GetFamilyName(BaseFrame:GetUserIValue("HANDLE")));
		local SLv = BaseFrame:GetUserIValue("SKILLLEVEL");
		local Price = BaseFrame:GetUserIValue("PRICE");
		local PriceInfo = LibPrice:GetPriceInfo(21003);
		local PriceTextData = LibPrice:GetPriceText(Price, PriceInfo)

		ToukibiUI:AddRichText(BaseFrame
					 , "lblOwnerInfo"
					 , string.format("{@st42b}{#%s}Lv.%d{/}{/}  %s"
					 			   , LibPrice:GetBuffLvColor(SLv, PriceInfo.MaxLv)
								   , SLv
								   , string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "ShopName.GemRoasting"), OwnerFamilyName)
					 				)
					 , 40, 120, 420, 20, 16);
		local lblPrice = ToukibiUI:AddRichText(BaseFrame
									  , "lblPriceInfo"
									  , string.format("%s：%s  %s (%s)"
													, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													, PriceTextData.PriceText
													, PriceTextData.ImpressionText
													, PriceTextData.ComparsionText)
									  , 40, 200, 420, 20, 16);
		lblPrice:SetTextTooltip(PriceTextData.ToolTipText);
		-- 購入時の注意フラグを追加する
		BaseFrame:SetUserValue("ImpressionValue", PriceTextData.ImpressionValue);
	end
end

-- ジェムロースティング商店の確認ボタンをクリックしたときの処理
function Me.btnBuyGemRoasting_Click(frame)
	session.ResetItemList();

	local ParentFrame = frame:GetTopParentFrame();
	local SLv = ParentFrame:GetUserIValue("SKILLLEVEL");
	local Price = ParentFrame:GetUserIValue("PRICE");
	-- 勝手に埋め込んだパラメータを取り出す
	local DoAlart = (ParentFrame:GetUserValue("ImpressionValue") == "RipOff");

	if DoAlart then
		local strscp = string.format("TOUKIBI_SHOPHELPER_EXEC_GEM_ROASTING('%s')", ParentFrame:GetName());
		local msg = LibPrice:MakeWarningMsg(21003, SLv, Price)
		ui.MsgBox(msg, strscp, "None");
	else
		TOUKIBI_SHOPHELPER_EXEC_GEM_ROASTING(ParentFrame:GetName())
	end
end

--ジェムローストアクション
function TOUKIBI_SHOPHELPER_EXEC_GEM_ROASTING(ParentFrameName)
	session.ResetItemList();

	local ParentFrame = ui.GetFrame(ParentFrameName);
	local targetbox = ParentFrame:GetChild("roasting");
	local slot = GET_CHILD(targetbox, "slot", "ui::CSlot");
	local itemIESID = slot:GetUserValue("GEM_IESID");

	if itemIESID == "0" or itemIESID == "" then
		ui.MsgBox(ScpArgMsg("DropItemPlz"))
		return;
	end

	local handle = ParentFrame:GetUserValue("HANDLE");
	local skillName = ParentFrame:GetUserValue("SKILLNAME");
	local RoastPrice = ParentFrame:GetUserIValue("PRICE");
	-- 最終使用時間を記憶する
	LibPrice:UpdateAverage(handle, 21003, RoastPrice)

	session.AddItemID(itemIESID);
	session.autoSeller.BuyItems(handle, AUTO_SELL_GEM_ROASTING, session.GetItemIDList(), skillName);
end

-- ================================
--   アイテム鑑定関連 じゃかじゃん!!
-- ================================

-- 鑑定商店に情報を付加する
function Me.AddInfoToAppraisalPC(BaseFrame)
	if BaseFrame == nil then return nil end
	if BaseFrame:GetUserIValue("HANDLE") ==  session.GetMyHandle() then return nil end

	local AppraisalFrame = BaseFrame:GetChild("appraisalBox");
	if AppraisalFrame ~= nil then

		local groupName = BaseFrame:GetUserValue("GroupName");
		local groupInfo = session.autoSeller.GetByIndex(groupName, 0);
		local OwnerFamilyName = tostring(info.GetFamilyName(BaseFrame:GetUserIValue("HANDLE")));
		local SLv = groupInfo.level;
		local Price = groupInfo.price;
		local PriceInfo = LibPrice:GetPriceInfo(31501); -- 鑑定のスキルID
		local PriceTextData = LibPrice:GetPriceText(Price, PriceInfo)
	local sklName = GetClassByType("Skill", groupInfo.classID).ClassName;

		ToukibiUI:AddRichText(BaseFrame , "ShopHelper_lblOwnerInfo"
					 , string.format("{@st42b}{#%s}Lv.%d{/}{/}  %s"
					 			   , LibPrice:GetBuffLvColor(SLv, PriceInfo.MaxLv)
								   , SLv
								   , string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "ShopName.AppraisalPC"), OwnerFamilyName)
					 				)
					 , 40, 120, 420, 20, 16);
		local lblPrice = ToukibiUI:AddRichText(BaseFrame
									  , "ShopHelper_lblPriceInfo"
									  , string.format("%s：%s  %s (%s)"
													, Toukibi:GetResText(ResText, Me.Settings.Lang, "ComDic.CostPrice")
													, PriceTextData.PriceText
													, PriceTextData.ImpressionText
													, PriceTextData.ComparsionText)
									  , 40, 680, 420, 20, 16);

		lblPrice:SetTextTooltip(PriceTextData.ToolTipText);
		-- 購入時の注意フラグを追加する
		BaseFrame:SetUserValue("ImpressionValue", PriceTextData.ImpressionValue);

	end
end

-- 修理商店の修理ボタンをクリックしたときの処理
function Me.btnBuyAppraisal_Click(frame)
	local ParentFrame = frame:GetTopParentFrame();
	local groupName = ParentFrame:GetUserValue("GroupName");
	local groupInfo = session.autoSeller.GetByIndex(groupName, 0);
	-- 勝手に埋め込んだパラメータを取り出す
	local DoAlart = (ParentFrame:GetUserValue("ImpressionValue") == "RipOff");

	if DoAlart then
		local strscp = string.format("TOUKIBI_SHOPHELPER_EXEC_APPRAISAL_PC('%s')", ParentFrame:GetName());
		local msg = LibPrice:MakeWarningMsg(groupInfo.classID, groupInfo.level, groupInfo.price)
		ui.MsgBox(msg, strscp, "None");
	else
		TOUKIBI_SHOPHELPER_EXEC_APPRAISAL_PC(ParentFrame:GetName())
	end
end

-- 鑑定アクション
function TOUKIBI_SHOPHELPER_EXEC_APPRAISAL_PC(ParentFrameName)
	local frame = ui.GetFrame(ParentFrameName);
	local groupName = frame:GetUserValue("GroupName");
	local groupInfo = session.autoSeller.GetByIndex(groupName, 0);
	local handle = frame:GetUserIValue("HANDLE");
	local skillName = frame:GetUserValue("SKILLNAME");
	local slotSet = GET_CHILD_RECURSIVELY(frame, "slotlist", "ui::CSlotSet")
	
	session.ResetItemList();	
	
	-- check selected item
	if slotSet:GetSelectedSlotCount() < 1 then
		ui.MsgBox(ScpArgMsg("DON_T_HAVE_ITEM_TO_APPRAISAL"));
		return;
	end

	-- check money
	if handle ~= session.GetMyHandle() and GET_TOTAL_MONEY() < frame:GetUserIValue('TOTAL_MONEY') then
		ui.MsgBox(ScpArgMsg("Auto_SoJiKeumi_BuJogHapNiDa."));
		return;
	end

	-- 最終使用時間を記憶する
	LibPrice:UpdateAverage(handle, groupInfo.classID, groupInfo.price)

	for i = 0, slotSet:GetSelectedSlotCount() -1 do
		local slot = slotSet:GetSelectedSlot(i)
		local Icon = slot:GetIcon();
		local iconInfo = Icon:GetInfo();

		session.AddItemID(iconInfo:GetIESID());
	end

	session.autoSeller.BuyItems(handle, AUTO_SELL_APPRAISE, session.GetItemIDList(), skillName);

end









-- ================================
--          その他の機能
-- ================================

-- 全プレイヤーの名前を隠す
function TOUKIBI_SHOPHELPER_HIDE_PLAYERS()
	if keyboard.IsPressed(KEY_ALT) == 1 then
		-- Altキーが押されている間はキャラクター情報を非表示にする
		local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 1000000, "ALL");
		for i = 1, selectedObjectsCount do
			local handle = GetHandle(selectedObjects[i]);
			if handle ~= nil then
				if info.IsPC(handle) == 1 then
					local shopFrame = ui.GetFrame("SELL_BALLOON_" .. handle);
					-- 露店には何もしない
					if shopFrame == nil then
						local FrameName = "charbaseinfo1_" .. handle;
						local ytxtFrame = ui.GetFrame(FrameName);
						if ytxtFrame ~= nil then
							if ytxtFrame:IsVisible() == 1 then
								table.insert(Me.HiddenFrameList, FrameName);
								ytxtFrame:ShowWindow(0);
							end
						end
					end
				end
			end
		end
	else
		-- 押されていない場合は隠されたフレームをすべて元に戻す
		while table.maxn(Me.HiddenFrameList) >= 1 do
			local v = table.remove(Me.HiddenFrameList)
			local frame = ui.GetFrame(v);
			if frame ~= nil then
				frame:ShowWindow(1);
			end
		end
	end
end



function Me.Test()

end


-- ===========================
--          設定画面
-- ===========================

-- 価格コントロール部
local LibPriceCtrl = {

	-- 入力価格を取得する
	GetPriceInputValue = function(self, frame)
		if frame == nil then return end
		local AverageValue = ToukibiUI:GetNumValue(GET_CHILD(frame, "txtAverage", "ui::CEditControl"));
		local RadixValue = ToukibiUI:GetNumValue(GET_CHILD(frame, "txtRadix", "ui::CEditControl"));
		local SuburbValue = ToukibiUI:GetNumValue(GET_CHILD(frame, "txtSuburb", "ui::CEditControl"));
		return AverageValue, RadixValue, SuburbValue;
	end,

	-- 価格表記を更新する
	UpdatePriceText = function(self, parent, ControlBaseName, value, CurrentHighestValue)
		local ctrl = GET_CHILD(parent, "value_" .. ControlBaseName, "ui::CRichText");
		if ctrl == nil then return CurrentHighestValue end
		ToukibiUI:SetText(ctrl, LibPrice:GetCommaedTextEx(value), {"@st66b", "s16"});
		if value > CurrentHighestValue then
			ctrl:ShowWindow(1);
			GET_CHILD(parent, "zone_" .. ControlBaseName, "ui::CRichText"):ShowWindow(1);
			GET_CHILD(parent, "bar_" .. ControlBaseName, "ui::CRichText"):ShowWindow(1);
			GET_CHILD(parent, "pointer_" .. ControlBaseName, "ui::CRichText"):ShowWindow(1);
			return value;
		else
			ctrl:ShowWindow(0);
			GET_CHILD(parent, "zone_" .. ControlBaseName, "ui::CRichText"):ShowWindow(0);
			GET_CHILD(parent, "bar_" .. ControlBaseName, "ui::CRichText"):ShowWindow(0);
			GET_CHILD(parent, "pointer_" .. ControlBaseName, "ui::CRichText"):ShowWindow(0);
			return CurrentHighestValue;
		end
	end,
	UpdatePricePanel = function(self, ctrl)
		local pnlInput = nil;
		local Container = nil;
		if ctrl:GetName() == "pnlInput" then
			Container = ctrl:GetParent():GetParent();
			pnlInput = ctrl;
		else
			Container = ctrl;
			pnlInput = GET_CHILD(ctrl, "pnlInput", "ui::CGroupBox");
		end
		if Container ~= nil then
			-- 入力されている値を読む
			local AverageValue, RadixValue, SuburbValue = self:GetPriceInputValue(pnlInput);
			local pnlGauge = GET_CHILD(Container, "pnlGauge", "ui::CGroupBox");
			local SkillID = Container:GetUserValue("SkillID");
			if pnlGauge ~= nil and SkillID ~= nil then
				local PriceInfo = LibPrice:GetPriceInfo(tonumber(SkillID));
				local HighestValue = 0;
				HighestValue = self:UpdatePriceText(pnlGauge, "BelowCost", PriceInfo.CostPrice, HighestValue);
				HighestValue = self:UpdatePriceText(pnlGauge, "NearCost", PriceInfo.CostPrice + RadixValue * 3, HighestValue);
				HighestValue = self:UpdatePriceText(pnlGauge, "GoodValue", AverageValue - RadixValue * 2, HighestValue);
				HighestValue = self:UpdatePriceText(pnlGauge, "WithinAverage", AverageValue + RadixValue * 5, HighestValue);
				HighestValue = self:UpdatePriceText(pnlGauge, "ALittleExpensive", AverageValue + RadixValue * 20, HighestValue);
				local RipOffValue = math.min(AverageValue * 1.8, AverageValue + RadixValue * 100);
				HighestValue = self:UpdatePriceText(pnlGauge, "Expensive", RipOffValue, HighestValue);
			end
		end
	end,

	--目盛りを作成する
	CreateDivText = function(self, ParetFrame, name, left, right, text, value)
		local MarginBottom = 0;
		local textWidth = math.abs(right - left);
		local lblZone = tolua.cast(ParetFrame:CreateOrGetControl("richtext", "zone_" .. name, math.floor((left + right) / 2), 0, textWidth, 12),
								"ui::CRichText");
		lblZone:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
		ToukibiUI:SetMargin(lblZone, nil, nil, nil, MarginBottom);
		lblZone:EnableHitTest(0);
		lblZone:SetText(string.format("{@st66b}{s12}%s{/}{/}", text));

		if value ~= nil then
			local lblBar = tolua.cast(ParetFrame:CreateOrGetControl("richtext","bar_" .. name, right + 1, 0, 12, 12),
									"ui::CRichText");
			lblBar:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
			ToukibiUI:SetMargin(lblBar, nil, nil, nil, 6);
			lblBar:EnableHitTest(0);
			lblBar:SetText("{@st66b}{s12}|{/}{/}");

			local lblPointer = tolua.cast(ParetFrame:CreateOrGetControl("richtext","pointer_" .. name, right + 1, 0, 12, 12),
									"ui::CRichText");
			lblPointer:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
			ToukibiUI:SetMargin(lblPointer, nil, nil, nil, 22);
			lblPointer:EnableHitTest(0);
			lblPointer:SetText("{@st66b}{s12}▼{/}{/}");

			local MarginBottom = 36;
			local lblValue = tolua.cast(ParetFrame:CreateOrGetControl("richtext", "value_" .. name, right, 0, 60, 12),
									"ui::CRichText");
			lblValue:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
			ToukibiUI:SetMargin(lblValue, nil, nil, nil, MarginBottom);
			lblValue:EnableHitTest(0);
			lblValue:SetText(string.format("{@st66b}{s16}%s{/}{/}", LibPrice:GetCommaedTextEx(value)));
		end
	end,
	
	-- 価格のゲージを作成する
	CreatePriceGauge = function(self, ParentFrame, PriceInfo)
		local ParentWidth = ParentFrame:GetWidth();
		local height = 60;
		local pnlBase = tolua.cast(ParentFrame:CreateOrGetControl("groupbox", "pnlGauge", 0, 0, ParentWidth - 10, height), 
								"ui::CGroupBox");
		
		pnlBase:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
		ToukibiUI:SetMargin(pnlBase, nil, nil, nil, 5);
		pnlBase:EnableHitTest(0);
		pnlBase:SetSkinName("None");

		self:CreateDivText(pnlBase, "BelowCost", -275, -220, "原価割れ", PriceInfo.CostPrice);
		self:CreateDivText(pnlBase, "NearCost", -220, -165, "ほぼ原価", PriceInfo.CostPrice + PriceInfo.Span * 3);
		self:CreateDivText(pnlBase, "GoodValue", -165, -55, "お値打ち", PriceInfo.AveragePrice - PriceInfo.Span * 2);
		self:CreateDivText(pnlBase, "WithinAverage", -55, 55, "平均", PriceInfo.AveragePrice + PriceInfo.Span * 5);
		self:CreateDivText(pnlBase, "ALittleExpensive", 55, 165, "高くない？", PriceInfo.AveragePrice + PriceInfo.Span * 20);
		local RipOffValue = math.min(PriceInfo.AveragePrice * 1.8, PriceInfo.AveragePrice + PriceInfo.Span * 100);
		self:CreateDivText(pnlBase, "Expensive", 165, 220, "高い", RipOffValue);
		self:CreateDivText(pnlBase, "RipOff", 230, 275, "異常に高い");

		local gaugeHMargin = 20;
		local imageMarginTop = 60;
		local gaugeWidth = pnlBase:GetWidth() - gaugeHMargin * 2;
		local picGauge = tolua.cast(pnlBase:CreateOrGetControl("picture", "pricegauge", 0, 0, gaugeWidth, 6), "ui::CPicture");
		picGauge:SetGravity(ui.CENTER_HORZ, ui.BOTTOM);
		ToukibiUI:SetMargin(picGauge, nil, nil, nil, 20);
		picGauge:EnableHitTest(0);
		picGauge:SetEnableStretch(1);
		picGauge:SetImage("inventory_weight");
	end,

	-- 価格入力部を作る
	CreatePriceInputBox = function(self, BaseFrame, PriceInfo)
		local ParentWidth = 310;
		local height = 60;
		local pnlBase = tolua.cast(BaseFrame:CreateOrGetControl("groupbox", "pnlInput", 0, 8, ParentWidth , height), 
								"ui::CGroupBox");
		
		pnlBase:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(pnlBase, nil, nil, 10, nil);
		-- pnlBase:SetSkinName("test_frame_midle");
		pnlBase:EnableScrollBar(0);
		pnlBase:EnableHitTest(1);
		pnlBase:SetSkinName("None");

		local lblSuburb = tolua.cast(pnlBase:CreateOrGetControl("richtext", "lblSuburb", 0, 35, 40, 20), "ui::CRichText");
		lblSuburb:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(lblSuburb, nil, nil, 50, nil);
		lblSuburb:EnableHitTest(0);
		lblSuburb:SetText("{@st66b}郊外価格{/}");

		local txtSuburb = tolua.cast(pnlBase:CreateOrGetControl("edit", "txtSuburb", 0, 30, 50, 26), "ui::CEditControl");
		txtSuburb:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(txtSuburb, nil, nil, 0, nil);
		txtSuburb:EnableHitTest(1);
		txtSuburb:SetSkinName("test_weight_skin");
		txtSuburb:SetClickSound("button_click_big");
		txtSuburb:SetOverSound("button_over");
		txtSuburb:SetFontName("white_18_ol");
		txtSuburb:SetMaxLen(4);
		txtSuburb:SetOffsetXForDraw(0);
		txtSuburb:SetOffsetYForDraw(-1);
		txtSuburb:SetTextAlign("center", "center");
		txtSuburb:SetText(PriceInfo.Suburb);

		local lblRadix = tolua.cast(pnlBase:CreateOrGetControl("richtext", "lblRadix", 0, 5, 50, 20), "ui::CRichText");
		lblRadix:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(lblRadix, nil, nil, 50, nil);
		lblRadix:EnableHitTest(0);
		lblRadix:SetText("{@st66b}単位{/}");

		local txtRadix = tolua.cast(pnlBase:CreateOrGetControl("edit", "txtRadix", 0, 0, 50, 26), "ui::CEditControl");
		txtRadix:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(txtRadix, nil, nil, 0, nil);
		txtRadix:EnableHitTest(1);
		txtRadix:SetSkinName("test_weight_skin");
		txtRadix:SetClickSound("button_click_big");
		txtRadix:SetOverSound("button_over");
		txtRadix:SetFontName("white_18_ol");
		txtRadix:SetMaxLen(3);
		txtRadix:SetOffsetXForDraw(0);
		txtRadix:SetOffsetYForDraw(-1);
		txtRadix:SetTextAlign("center", "center");
		txtRadix:SetText(PriceInfo.Span);
		txtRadix:SetTypingScp("TOUKIBI_SHOPHELPER_PRICETEXT_CHANGED");

		local lblAverage = tolua.cast(pnlBase:CreateOrGetControl("richtext", "lblAverage", 0, 5, 40, 20), "ui::CRichText");
		lblAverage:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(lblAverage, nil, nil, 180, nil);
		lblAverage:EnableHitTest(0);
		lblAverage:SetText("{@st66b}平均値{/}");

		local txtAverage = tolua.cast(pnlBase:CreateOrGetControl("edit", "txtAverage", 0, 0, 80, 26), "ui::CEditControl");
		txtAverage:SetGravity(ui.RIGHT, ui.TOP);
		ToukibiUI:SetMargin(txtAverage, nil, nil, 100, nil);
		txtAverage:EnableHitTest(1);
		txtAverage:SetSkinName("test_weight_skin");
		txtAverage:SetClickSound("button_click_big");
		txtAverage:SetOverSound("button_over");
		txtAverage:SetFontName("white_18_ol");
		txtAverage:SetMaxLen(5);
		txtAverage:SetOffsetXForDraw(0);
		txtAverage:SetOffsetYForDraw(-1);
		txtAverage:SetTextAlign("center", "center");
		txtAverage:SetText(LibPrice:GetCommaedTextEx(PriceInfo.AveragePrice));
		txtAverage:SetTypingScp("TOUKIBI_SHOPHELPER_PRICETEXT_CHANGED");

	end,

	-- 価格設定コントロールを作成する
	CreateCtrl = function(self, BaseFrame, SkillID, Index)
		local width = BaseFrame:GetWidth() - 40;
		local height = 140;

		local pnlPriceBase = tolua.cast(BaseFrame:CreateOrGetControl("controlset", "pnlPrice_" .. SkillID, 
																	0, (height + 5) * (Index - 1), width, height), 
										"ui::CControlSet");

		pnlPriceBase:SetSkinName("test_skin_01_btn");
		pnlPriceBase:EnableHitTest(1);
		pnlPriceBase:SetGravity(ui.CENTER_HORZ, ui.TOP);
		local imageSize = 24;
		local imageMarginLeft = 20;
		local imageMarginRight = 2;
		local imageMarginTop = 10;
		local left = imageMarginLeft;
		local picSkillIcon = tolua.cast(pnlPriceBase:CreateOrGetControl("picture", "skillicon", left, imageMarginTop, imageSize, imageSize), "ui::CPicture");
		picSkillIcon:SetGravity(ui.LEFT, ui.TOP);
		picSkillIcon:EnableHitTest(0);
		picSkillIcon:SetEnableStretch(1);
		left = left + imageSize + imageMarginRight;

		local countControlWidth = 90;
		local textHMargin = 10;
		local textMarginTOP = 12;
		local nameWidth = width - left - countControlWidth - textHMargin * 2;
		local nameControl = pnlPriceBase:CreateOrGetControl("richtext", "name", left, textMarginTOP, nameWidth, 24);
		nameControl:SetGravity(ui.LEFT, ui.TOP);
		nameControl:EnableHitTest(0);
		nameControl:SetText("{@st66b}スキル名がありませんでした{/}");
		left = left + nameWidth;

		local objSkill = GetClassByType("Skill", SkillID);
		if objSkill ~= nil then
			picSkillIcon:SetImage("icon_" .. objSkill.Icon);
			nameControl:SetText(string.format("{@st66b}%s{/}", objSkill.Name));
		end
		-- スキル・価格情報を埋め込んでおく
		pnlPriceBase:SetUserValue("SkillID", SkillID);
		local PriceInfo = LibPrice:GetPriceInfo(SkillID)
		self:CreatePriceGauge(pnlPriceBase, PriceInfo);
		self:CreatePriceInputBox(pnlPriceBase, PriceInfo);
		self:UpdatePricePanel(pnlPriceBase);
	end,

	-- 言語切替対応
	ChangePricePanelLang = function(self, BaseContainer, LangMode)
		LangMode = LangMode or Me.Settings.Lang or "jp";
		if BaseContainer == nil then return end
		local pnlInput = GET_CHILD(BaseContainer, "pnlInput", "ui::CGroupBox");
		if pnlInput ~= nil then
			ToukibiUI:SetText(GET_CHILD(pnlInput, "lblSuburb", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "ComDic.RuralCharge"), {"@st66b"});
			ToukibiUI:SetText(GET_CHILD(pnlInput, "lblRadix", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "ComDic.PriceRadix"), {"@st66b"});
			ToukibiUI:SetText(GET_CHILD(pnlInput, "lblAverage", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "ComDic.AveragePrice"), {"@st66b"});
		end
		local pnlGauge = GET_CHILD(BaseContainer, "pnlGauge", "ui::CGroupBox");
		if pnlGauge ~= nil then
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_BelowCost", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.BelowCost"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_NearCost", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.NearCost"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_GoodValue", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.GoodValue"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_WithinAverage", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.WithinAverage"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_ALittleExpensive", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.ALittleExpensive"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_Expensive", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.Expensive"), {"@st66b", "s12"});
			ToukibiUI:SetText(GET_CHILD(pnlGauge, "zone_RipOff", "ui::CRichText"), 
							Toukibi:GetResText(ResText, LangMode, "Option.Zone.RipOff"), {"@st66b", "s12"});
		end
	end
};
Me.LibPriceCtrl = LibPriceCtrl;

function Me.OpenSettingFrame()
	Me.SettingFrame_BeforeDisplay();
end

function Me.CloseSettingFrame()
	local BaseFrame = ui.GetFrame("shophelper");
	if BaseFrame == nil then
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.CannotGetSettingFrameHandle"), "Warning", true, false);
		return;
	end
	Me.Settings.OptionFrameIsAvailable = false;
	local BodyGBox = GET_CHILD_GROUPBOX(BaseFrame, "pnlMain");
	if BodyGBox ~= nil then
		local PriceGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlPrice");
		if PriceGBox ~= nil then
			PriceGBox:RemoveAllChild();
		end
	end
	BaseFrame:ShowWindow(0);
end

function Me.SettingFrame_BeforeDisplay()
	local BaseFrame = ui.GetFrame("shophelper");
	if BaseFrame == nil then
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.CannotGetSettingFrameHandle"), "Warning", true, false);
		return;
	end
	Me.InitSettingValue(BaseFrame);
	Me.InitSettingText(BaseFrame);
	local BodyGBox = GET_CHILD_GROUPBOX(BaseFrame, "pnlMain");
	if BodyGBox ~= nil then
		local objTab = GET_CHILD(BodyGBox, "ShopHelperSettingTab", "ui::CTabControl");
		if objTab ~= nil then
			objTab:SelectTab(0);
		end
		Me.ChangeActiveTab(BodyGBox);
	end
	Me.Settings.OptionFrameIsAvailable = true;
	BaseFrame:ShowWindow(1);
end

function Me.InitSettingValue(BaseFrame)
	local BodyGBox = GET_CHILD_GROUPBOX(BaseFrame, "pnlMain");
	local LangGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlLang");
	local OptionGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlOption");
	local PriceGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlPrice");

	local CurrentRadio = GET_CHILD(LangGBox, "lang_en", "ui::CRadioButton");
	if Me.Settings.Lang == "jp" then
		CurrentRadio = GET_CHILD(LangGBox, "lang_jp", "ui::CRadioButton");
	end
	CurrentRadio:Select()
	ToukibiUI:SetCheckedByName(OptionGBox, "ShowMessageLog", Me.Settings.ShowMessageLog);
	ToukibiUI:SetCheckedByName(OptionGBox, "ShowMsgBoxOnBuffShop", not Me.Settings.ShowMsgBoxOnBuffShop);
	ToukibiUI:SetCheckedByName(OptionGBox, "AddInfoToBaloon", Me.Settings.AddInfoToBaloon);
	ToukibiUI:SetCheckedByName(OptionGBox, "EnableBaloonRightClick", Me.Settings.EnableBaloonRightClick);
	ToukibiUI:SetCheckedByName(OptionGBox, "UpdateAverage", Me.Settings.UpdateAverage);
	ToukibiUI:SetSliderValue(OptionGBox, "AverageNCount", "AverageNCount_text", math.floor(Me.Settings.AverageNCount / 10), Me.Settings.AverageNCount);
	ToukibiUI:SetSliderValue(OptionGBox, "RecalcInterval", "RecalcInterval_text", math.floor(Me.Settings.RecalcInterval / 10), Me.Settings.RecalcInterval);
	ToukibiUI:SetCheckedByName(OptionGBox, "NoUpdateIfFarther", Me.Settings.IgnoreAwayValue);

	PriceGBox:RemoveAllChild();
	LibPriceCtrl:CreateCtrl(PriceGBox, 40203, 1);
	LibPriceCtrl:CreateCtrl(PriceGBox, 40205, 2);
	LibPriceCtrl:CreateCtrl(PriceGBox, 40201, 3);
	LibPriceCtrl:CreateCtrl(PriceGBox, 10703, 4);
	LibPriceCtrl:CreateCtrl(PriceGBox, 21003, 5);
	LibPriceCtrl:CreateCtrl(PriceGBox, 31501, 6);

end

function Me.InitSettingText(BaseFrame, LangMode)
	LangMode = LangMode or Me.Settings.Lang or "jp";
	local BodyGBox = GET_CHILD_GROUPBOX(BaseFrame, "pnlMain");
	local OptionGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlOption");
	local PriceGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlPrice");

	ToukibiUI:SetText(GET_CHILD(BaseFrame, "title", "ui::CRichText"), 
					  Toukibi:GetResText(ResText, LangMode, "Option.SettingFrameTitle"), {"@st43"});
	local objTab = GET_CHILD(BodyGBox, "ShopHelperSettingTab", "ui::CTabControl");
	if objTab ~= nil then
		objTab:ChangeCaption(0, Toukibi:GetStyledText(Toukibi:GetResText(ResText, LangMode, "Option.TabGeneralSetting"), {"@st66b"}));
		objTab:ChangeCaption(1, Toukibi:GetStyledText(Toukibi:GetResText(ResText, LangMode, "Option.TabAverageSetting"), {"@st66b"}));
	end
	local TargetGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlOption");
	if TargetGBox ~= nil then
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "option_title", "ui::CRichText"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.GeneralSetting"), {"@st43"});
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "ShowMessageLog", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.ShowMessageLog"), {"@st66b"});
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "ShowMsgBoxOnBuffShop", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.ShowMsgBoxOnBuffShop"), {"@st66b"});
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "AddInfoToBaloon", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.AddInfoToBaloon"), {"@st66b"});
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "EnableBaloonRightClick", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.EnableBaloonRightClick"), {"@st66b"});
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "UpdateAverage", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.UpdateAverage"), {"@st66b"});

		local TargetControl = GET_CHILD(TargetGBox, "AverageNCount_text", "ui::CRichText");
		ToukibiUI:SetTextByKey(TargetControl, "opCaption", Toukibi:GetResText(ResText, LangMode, "Option.AverageWeight"));
		ToukibiUI:SetTextByKey(TargetControl, "opUnit", Toukibi:GetResText(ResText, LangMode, "Option.AverageWeightUnit"));
		local TargetControl = GET_CHILD(TargetGBox, "RecalcInterval_text", "ui::CRichText");
		ToukibiUI:SetTextByKey(TargetControl, "opCaption", Toukibi:GetResText(ResText, LangMode, "Option.AverageUpdateInterval"));
		ToukibiUI:SetTextByKey(TargetControl, "opUnit", Toukibi:GetResText(ResText, LangMode, "Option.AverageUpdateIntervalUnit"));
		ToukibiUI:SetText(GET_CHILD(TargetGBox, "NoUpdateIfFarther", "ui::CCheckBox"), 
						  Toukibi:GetResText(ResText, LangMode, "Option.NoUpdateIfFartherValue"), {"@st66b"});
	end
	TargetGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlPrice");
	local cnt = TargetGBox:GetChildCount();
	for i = 0, cnt - 1 do
		local ctrl = TargetGBox:GetChildByIndex(i);
		if string.find(ctrl:GetName(), "pnlPrice_") then
			LibPriceCtrl:ChangePricePanelLang(ctrl, LangMode)
		end
	end
	ToukibiUI:SetText(GET_CHILD(BodyGBox, "btn_excute", "ui::CButton"), 
						Toukibi:GetResText(ResText, LangMode, "Option.Save"), {"@st42"});
	ToukibiUI:SetText(GET_CHILD(BodyGBox, "btn_cencel", "ui::CButton"), 
						Toukibi:GetResText(ResText, LangMode, "Option.CloseMe"), {"@st42"});
end

-- タブコントロールが押されたときのイベント
function TOUKIBI_SHOPHELPER_TAB_LMOUSEDOWN(frame, ctrl, str, num)
	local tabObj = frame:GetChild('ShopHelperSettingTab');
	local itembox_tab = tolua.cast(tabObj, "ui::CTabControl");
	local SelectedIndex = itembox_tab:GetSelectItemIndex();
	Me.ChangeActiveTab(frame, SelectedIndex);
end

function Me.ChangeActiveTab(frame, SelectedIndex)
	if frame == nil then return end
	SelectedIndex = SelectedIndex or 0;
	GET_CHILD_GROUPBOX(frame, "pnlLang"  ):ShowWindow((0 == SelectedIndex) and 1 or 0);
	GET_CHILD_GROUPBOX(frame, "pnlOption"):ShowWindow((0 == SelectedIndex) and 1 or 0);
	GET_CHILD_GROUPBOX(frame, "pnlPrice" ):ShowWindow((1 == SelectedIndex) and 1 or 0);
end

-- 言語切替
function TOUKIBI_SHOPHELPER_CHANGE_LANGMODE(frame, ctrl, str, num)
	local SelectedLang = ToukibiUI:GetSelectedRadioValue(ctrl);
	Me.InitSettingText(frame:GetTopParentFrame(), SelectedLang);
end

-- スライダーの値が変わった時のイベント
function TOUKIBI_SHOPHELPER_SLIDER_CHANGED(frame, ctrl, str, num)
	tolua.cast(ctrl, "ui::CSlideBar");
	local ControlName = ctrl:GetName();
	local SettingName = nil;
	local CurrentValue = nil;
	local BuddyText = nil;
	if ControlName == "AverageNCount" or ControlName == "RecalcInterval" then
		SettingName = ControlName;
		CurrentValue = num * 10;
		BuddyText = GET_PARENT(ctrl):GetChild(ControlName .. "_text");
	end
	if SettingName ~= nil then
		ToukibiUI:SetTextByKey(BuddyText, "opValue", CurrentValue)
	end
end

-- テキストボックスに入力された時のイベント
function TOUKIBI_SHOPHELPER_PRICETEXT_CHANGED(parent, ctrl)
	if Me.Settings ~= nil and Me.Settings.OptionFrameIsAvailable then
		LibPriceCtrl:UpdatePricePanel(parent, ctrl)
	end
end

-- 設定反映
function Me.ExecSetting()
	local BaseFrame = ui.GetFrame("shophelper");
	if BaseFrame == nil then
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.CannotGetSettingFrameHandle"), "Warning", true, false);
		return;
	end
	local BodyGBox = GET_CHILD_GROUPBOX(BaseFrame, "pnlMain");
	if BodyGBox == nil then return end
	local LangGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlLang");
	Me.Settings.Lang = ToukibiUI:GetSelectedRadioValue(LangGBox:GetChild("lang_jp"));
	local ModeGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlOption");
	Me.Settings.ShowMessageLog = ToukibiUI:GetCheckedByName(ModeGBox, "ShowMessageLog");
	Me.Settings.ShowMsgBoxOnBuffShop = not ToukibiUI:GetCheckedByName(ModeGBox, "ShowMsgBoxOnBuffShop");
	Me.Settings.AddInfoToBaloon = ToukibiUI:GetCheckedByName(ModeGBox, "AddInfoToBaloon");
	Me.Settings.EnableBaloonRightClick = ToukibiUI:GetCheckedByName(ModeGBox, "EnableBaloonRightClick");
	Me.Settings.UpdateAverage = ToukibiUI:GetCheckedByName(ModeGBox, "UpdateAverage");
	local intValue;
	intValue = ToukibiUI:GetSliderValueByName(ModeGBox, "AverageNCount");
	if intValue ~= nil then
		Me.Settings.AverageNCount = intValue * 10
	end
	intValue = ToukibiUI:GetSliderValueByName(ModeGBox, "RecalcInterval");
	if intValue ~= nil then
		Me.Settings.RecalcInterval = intValue * 10
	end
	Me.Settings.IgnoreAwayValue = ToukibiUI:GetCheckedByName(ModeGBox, "NoUpdateIfFarther");

	local PriceGBox = GET_CHILD_GROUPBOX(BodyGBox, "pnlPrice");
	if PriceGBox ~= nil then
		local cnt = PriceGBox:GetChildCount();
		for i = 0, cnt - 1 do
			local Container = PriceGBox:GetChildByIndex(i);
			if string.find(Container:GetName(), "pnlPrice_") then
				-- 入力されている値を読む
				local SkillID = Container:GetUserValue("SkillID");
				local AverageValue, RadixValue, SuburbValue = LibPriceCtrl:GetPriceInputValue(GET_CHILD(Container, "pnlInput", "ui::CGroupBox"));
	-- CHAT_SYSTEM(string.format("%s: %s, %s, %s", SkillID, AverageValue, RadixValue, SuburbValue))
				Me.Settings.AverageData[tostring(SkillID)].Price = AverageValue;
				Me.Settings.AverageData[tostring(SkillID)].Radix = RadixValue;
				Me.Settings.AverageData[tostring(SkillID)].Suburb = SuburbValue;
			end
		end
	end

	SaveSetting();
	Me.CloseSettingFrame();
	Me.RedrawAllShopBaloon();
end

-- ===========================
--      右クリックメニュー
-- ===========================

--コンテキストメニュー表示 
function TOUKIBI_SHOPHELPER_OPEN_BALOON_CONTEXT_MENU(frame, ctrl)
	if not Me.Settings.EnableBaloonRightClick then return end
	if session.world.IsIntegrateServer() == true then
		ui.SysMsg(ScpArgMsg("CantUseThisInIntegrateServer"));
		return;
	end
	local handle = frame:GetUserIValue("HANDLE");
	-- タイトル
	local TitleText = frame:GetUserValue("SHOPHELPER_ORIGINAL_TEXT") or string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "ShopName.General"), info.GetFamilyName(handle));
	local Title = string.format(Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.Title"), TitleText);
	local context = ui.CreateContextMenu("SHOPHELPER_BALOON_RBTN", Title, 0, 0, 320, 0);
	-- 内容
	local DisplayState = Me.GetFavoriteStatus(handle);
	local Liked = session.likeit.AmILikeYou(info.GetFamilyName(handle)) or false;
	Toukibi:MakeCMenuSeparator(context, 300);
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.Favorite"), string.format("TOUKIBI_SHOPHELPER_CHANGE_DISPLAYSTATE(%s, %s)", handle, MyEnums.DisplayState.Favorite), nil, (DisplayState == MyEnums.DisplayState.Favorite));
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.AsNormal"), string.format("TOUKIBI_SHOPHELPER_CHANGE_DISPLAYSTATE(%s, %s)", handle, MyEnums.DisplayState.NoMark), nil, (DisplayState == MyEnums.DisplayState.NoMark));
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.Hate"), string.format("TOUKIBI_SHOPHELPER_CHANGE_DISPLAYSTATE(%s, %s)", handle, MyEnums.DisplayState.HateMark), nil, (DisplayState == MyEnums.DisplayState.HateMark));
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.NeverShow"), string.format("TOUKIBI_SHOPHELPER_CHANGE_DISPLAYSTATE(%s, %s)", handle, MyEnums.DisplayState.Never), nil, (DisplayState == MyEnums.DisplayState.Never));
	Toukibi:MakeCMenuSeparator(context, 300.1);
	local strRequestLikeItScp = string.format("SEND_PC_INFO(%d)", handle);
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.LikeYou"), strRequestLikeItScp, nil, Liked);
	Toukibi:MakeCMenuSeparator(context, 300.2);
	Toukibi:MakeCMenuItem(context, Toukibi:GetResText(ResText, Me.Settings.Lang, "Menu.Close"));
	context:Resize(320, context:GetHeight());
	ui.OpenContextMenu(context);
	return context;
end 

-- ***** コンテキストメニューのイベント受け *****
-- True/Falseの切り替え
function TOUKIBI_SHOPHELPER_TOGGLEPROP(Name, Value)
	if Name == nil then return end
	if Me.Settings == nil then return end
	if Value == "nil" or type(Value) ~= "boolean" then
		Me.Settings[Name] = not Me.Settings[Name];
	else
		Me.Settings[Name] = Value;
	end
	SaveSetting();
end
-- 値の変更
function TOUKIBI_SHOPHELPER_CHANGEPROP(Name, Value)
	if Name == nil then return end
	if Me.Settings == nil then return end
	if Value == "nil" then Value = nil end
	Me.Settings[Name] = Value
	SaveSetting();
end
-- マーク変更
function TOUKIBI_SHOPHELPER_CHANGE_DISPLAYSTATE(handle, value)
	if handle == nil then return end
	local AID = world.GetActor(handle):GetPCApc():GetAID();
	if value == MyEnums.DisplayState.NoMark then value = nil end
	Me.FavoriteList[AID] = value;
	-- お気に入り情報を保存
	Toukibi:SaveTable(Me.FavoriteFilePathName, Me.FavoriteList);
	Me.RedrawShopBaloon(handle)
end





-- ===========================
--      コマンド受け取り
-- ===========================

function TOUKIBI_SHOPHELPER_PROCESS_COMMAND(command)
	Toukibi:AddLog(string.format(Toukibi:GetResText(Toukibi.CommonResText, Me.Settings.Lang, "Command.ExecuteCommands"), SlashCommandList[1] .. " " .. table.concat(command, " ")), "Info", true, true);
	local cmd = ""; 
	if #command > 0 then 
		cmd = table.remove(command, 1); 
	else 
		Me.OpenSettingFrame();
		return;
	end 
	if cmd == "reset" then 
		-- 平均値をリセット
		MargeDefaultPrice(true, false); 
		return; 
	elseif cmd == "resetall" then
		-- すべてをリセット
		MargeDefaultSetting(true, false);
		return;
	elseif cmd == "refresh" and DebugMode then
		-- プログラムをリセット
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.InitializeMe", "Notice", true, false));
		Me.RefreshMe(Me.addon, Me.SettingFrame);
		return;
	elseif cmd == "redraw" and DebugMode then
		-- 露店の再描画
		Toukibi:AddLog(Toukibi:GetResText(ResText, Me.Settings.Lang, "Log.RedrawAllShopBaloon", "Notice", true, false));
		Me.RedrawAllShopBaloon();
		return;
	elseif cmd == "jp" or cmd == "ja" or cmd == "en" or string.len(cmd) == 2 then
		if cmd == "ja" then cmd = "jp" end
		-- 言語モードと勘違いした？
		Toukibi:ChangeLanguage(cmd);
		return;
	elseif cmd ~= nil and cmd ~= "?" and cmd ~= "" then
		local strError = Toukibi:GetResText(Toukibi.CommonResText, Me.Settings.Lang, "Command.InvalidCommand");
		if #SlashCommandList > 0 then
			strError = strError .. string.format("{nl}" .. Toukibi:GetResText(Toukibi.CommonResText, Me.Settings.Lang, "Command.AnnounceCommandList"), SlashCommandList[1]);
		end
		Toukibi:AddLog(strError, "Warning", true, false);
	end 
	Me.ComLib:ShowHelpText()
end

-- ===========================
--      イベント受け取り
-- ===========================

function Me.AUTOSELLER_BALLOON_HOOKED(title, sellType, handle, skillID, skillLv) 
	-- CHAT_SYSTEM("AUTOSELLER_BALLOON_HOOKED実行");
	-- デフォルト状態のショップバルーンを作ってもらう
	Me.HoockedOrigProc["AUTOSELLER_BALLOON"](title, sellType, handle, skillID, skillLv); 
	AddToShopBaloon(title, sellType, handle, skillID, skillLv); 
end 

-- フックイベント中継
-- 修理/ジェムロースティング店を開くイベント
function Me.OPEN_ITEMBUFF_UI_HOOKED(groupName, sellType, handle) 
	Me.HoockedOrigProc["OPEN_ITEMBUFF_UI"](groupName, sellType, handle); 
	local groupInfo = session.autoSeller.GetByIndex(groupName, 0);
	if groupInfo == nil then return end
	local sklName = GetClassByType("Skill", groupInfo.classID).ClassName;
-- log(sklName .. ", " .. tostring(sellType) .. " : " .. tostring(handle))
	if "Squire_Repair" == sklName then
		Me.AddInfoToSquireBuff(ui.GetFrame("itembuffrepair"));
	elseif "Alchemist_Roasting" == sklName then
		Me.AddInfoToGemRoasting(ui.GetFrame("itembuffgemroasting"));
	elseif sklName == 'Appraiser_Apprise' then
		Me.AddInfoToAppraisalPC(ui.GetFrame("appraisal_pc"));
	end
end 

-- バフ屋の各バフの項目が描画される時のイベント
function Me.UPDATE_BUFFSELLER_SLOT_TARGET_HOOKED(ctrlSet, info)
	Me.HoockedOrigProc["UPDATE_BUFFSELLER_SLOT_TARGET"](ctrlSet, info);
	Me.AddInfoToBuffSellerSlot(ctrlSet, info);
end


-- バフ屋の購入ボタンを押した時のイベント
function Me.BUY_BUFF_AUTOSELL_HOOKED(ctrlSet, btn)
	Me.btnBuyBuffAutosell_Click(ctrlSet, btn);
	-- 元の処理は下の通りだけど置き換えて元の処理には返さない
	-- Me.HoockedOrigProc["BUY_BUFF_AUTOSELL"](ctrlSet, btn);
end

-- 修理商店の修理ボタンを押した時のイベント (さりげに公式がスペルミス)
function Me.SQIORE_REPAIR_EXCUTE_HOOKED(parent)
	Me.btnBuySquireRepair_Click(parent)
	-- 元の処理は下の通りだけど置き換えて元の処理には返さない
	-- Me.HoockedOrigProc["SQIORE_REPAIR_EXCUTE"](parent);
end

-- ジェムロースティング商店の確認ボタンを押した時のイベント
function Me.GEMROASTING_EXCUTE_HOOKED(parent)
	Me.btnBuyGemRoasting_Click(parent)
	-- 元の処理は下の通りだけど置き換えて元の処理には返さない
	-- Me.HoockedOrigProc["GEMROASTING_EXCUTE"](parent);
end

-- 鑑定商店の鑑定ボタンを押した時のイベント
function Me.APPRAISAL_PC_EXECUTE_HOOKED(frame)
	Me.btnBuyAppraisal_Click(frame)
	-- 元の処理は下の通りだけど置き換えて元の処理には返さない
	-- Me.HoockedOrigProc["APPRAISAL_PC_EXECUTE"](frame);
end

-- 設定画面オープン
function TOUKIBI_SHOPHELPER_OPEN_SETTING()
	Me.SettingFrame_BeforeDisplay();
end

-- 設定保存
function TOUKIBI_SHOPHELPER_EXEC_SETTING()
	Me.ExecSetting();
end

-- 設定画面クローズ
function TOUKIBI_SHOPHELPER_CLOSE_SETTING()
	Me.CloseSettingFrame();
end


-- ==================================
--  初期化関連
-- ==================================
-- For Debbug use
if DebugMode then ShopHelper = Me end

Me.HoockedOrigProc = Me.HoockedOrigProc or {};
function SHOPHELPER_ON_INIT(addon, frame)
	Me.addon = addon;
	Me.SettingFrame = frame
	Me.RefreshMe(addon, frame);

	addon:RegisterMsg("FPS_UPDATE", "TOUKIBI_SHOPHELPER_HIDE_PLAYERS");

	-- 現在地情報
	Me.IsVillage = (GetClass("Map", session.GetMapName()).isVillage == "YES") or false;
	-- 非表示中のフレームのリスト
	Me.HiddenFrameList = Me.HiddenFrameList or {};
	-- 読み込み完了処理を記述
	if not Me.loaded then
		session.ui.GetChatMsg():AddSystemMsg("[Add-ons]" .. addonName .. verText .. " loaded!", true);
	end
	Me.loaded = true;
end

function Me.RefreshMe()
	--Me.SetResText()


	-- 設定を読み込む
	if not Me.Loaded then
		Me.Loaded = true;
		LoadSetting();
	end

	-- フックしたいイベントを記述
	Toukibi:SetHook("AUTOSELLER_BALLOON", Me.AUTOSELLER_BALLOON_HOOKED); 
	Toukibi:SetHook("OPEN_ITEMBUFF_UI", Me.OPEN_ITEMBUFF_UI_HOOKED);
	Toukibi:SetHook("UPDATE_BUFFSELLER_SLOT_TARGET", Me.UPDATE_BUFFSELLER_SLOT_TARGET_HOOKED);
	Toukibi:SetHook("BUY_BUFF_AUTOSELL", Me.BUY_BUFF_AUTOSELL_HOOKED);
	Toukibi:SetHook("SQIORE_REPAIR_EXCUTE", Me.SQIORE_REPAIR_EXCUTE_HOOKED);
	Toukibi:SetHook("GEMROASTING_EXCUTE", Me.GEMROASTING_EXCUTE_HOOKED);
	Toukibi:SetHook("APPRAISAL_PC_EXECUTE", Me.APPRAISAL_PC_EXECUTE_HOOKED);
	-- CHAT_SYSTEM("{#333333}[ShopHelper]イベントのフック登録が完了しました{/}");

	-- スラッシュコマンドを登録する
	local acutil = require("acutil");
	for i = 1, #SlashCommandList do
		acutil.slashCommand(SlashCommandList[i], TOUKIBI_SHOPHELPER_PROCESS_COMMAND);
	end
	Toukibi:AddLog("Refresh処理が完了しました", "Info", true, true);
	
end