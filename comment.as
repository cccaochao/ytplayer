﻿/** ytPlayer  飘移评论控制脚本 **/
var FLY_SPEED_FAST:Number = 2.5;		//快字幕速度：秒
var FLY_SPEED_NORMAL:Number = 4;	//中等速度字幕：秒
var FLY_SPEED_SLOW:Number = 5.5;		//慢字幕速度：秒

var FLY_FONTSIZE_BIG:Number = 26;		//字体大小，大：像素
var FLY_FONTSIZE_NORMAL:Number = 22;	//字体大小，中：像素
var FLY_FONTSIZE_SMALL:Number = 14;		//字体大小，小：像素
var FLY_FONTSIZE_SUBTITLE:Number = FLY_FONTSIZE_SMALL;	//字体大小，字幕：像素

var FLY_FONTCOLOR_DEFAULT:Number = 0xffffff;		//默认字体颜色：白

var FLY_TYPE_TOP:Number = 0x2;
var FLY_TYPE_BOTTOM:Number = 0x0;
var FLY_TYPE_FLY:Number = 0x3;

var FLY_LEVEL_RANGE:Number = 1000;
var FLY_LEVEL_FLY:Number = FLY_LEVEL_RANGE;
var FLY_LEVEL_TOP:Number =FLY_LEVEL_FLY + FLY_LEVEL_RANGE;
var FLY_LEVEL_BOTTOM:Number = FLY_LEVEL_TOP + FLY_LEVEL_RANGE;

var FLY_SUBTITLE_LINES:Number = 2;		//字幕占据的最大行数
var FLY_SUBTITLE_RANGE:Number = FLY_FONTSIZE_SUBTITLE * FLY_SUBTITLE_LINES;		//字幕占据的高度数素

var FLY_STARTING_X:Number = ytVideo._width;		//字幕初始位置：相对与影片
var FLY_FLASH_INTERVAL:Number = 30;		//字幕刷新间隔：毫秒

/* a1 表示评论位置， a0 表示是否飘移 */
var fly_type:Object ={top:0x2, bottom:0x0, fly:0x3};
/*
var fly_var_queue:Object = {
	cmtID:Number, cmtText:String, 
	sTime:Number, flyType:Number, flySpeed:Number, fontColor:Number, fontSize:Number
};
*/

var fly_var_indexNext = 0;
var fly_var_queueLength = 0;
var fly_var_queue:Array = new Array();
var _fly_var_channels:Array = new Array();		//Array(channelID, {cmtID:Number, channelBreadth:Number, deathTime:playTime-Seconds})
var fly_subtitle_redline = ytVideo._height;			//当前字幕所占据的高度
var _fly_var_level_accumulator = 0;

fly_get_xml();



//获取字幕源XML
function fly_get_xml(url){
	var nsCmt = new XML();
	tip_add("读取评论…");
	nsCmt.load("data.xml");
	
	nsCmt.onLoad = function(){
		//trace("length = " + this);
		var cmts = xml_getElementByTagName(this, "comments").childNodes;
		//trace(cmts[1].attributes["playTime"]);
		fly_var_queueLength = 0;
		fly_var_queue = new Array(cmts.length);
		for(var i = 0; i < cmts.length; i++){
			if(cmts[i].nodeName){
				dgrComments.addItem({片时:_sec2disTime(cmts[i].attributes["playTime"]), 内容:cmts[i].lastChild, 评论时间:_timestamp2date(cmts[i].attributes["commentTime"])});
				//压入弹幕数据库
				var newCmt:Object = {
					cmtID:cmts[i].attributes["id"],
					cmtText:cmts[i].lastChild,
					sTime:cmts[i].attributes["playTime"],	//单位：s，基于影片开始的时间戳
					fontColor:cmts[i].attributes["fontColor"],
					fontSize:cmts[i].attributes["fontSize"],
					flyType:cmts[i].attributes["flyType"],
					flySpeed:FLY_SPEED_NORMAL //单位：s
				}
				//一系列的判断
				if(newCmt.fontColor == "") newCmt.fontColor = FLY_FONTCOLOR_DEFAULT;
				if(newCmt.flyType == "") newCmt.flyType = FLY_TYPE_FLY;
				switch(newCmt.fontSize){
					case "small":
						newCmt.fontSize = FLY_FONTSIZE_SMALL;
						break;
					case "big":
						newCmt.fontSize = FLY_FONTSIZE_BIG;
						break;
					default:
						newCmt.fontSize = FLY_FONTSIZE_NORMAL;
						break;
				}
				switch(newCmt.flyType){
					case "bottom":
						newCmt.flyType = FLY_TYPE_BOTTOM;
						break;
					case "top":
						newCmt.flyType = FLY_TYPE_TOP;
						break;
					default:
						newCmt.flyType = FLY_TYPE_FLY;
						break;
				}
				fly_var_queue[fly_var_queueLength] = newCmt;
				fly_var_queueLength++;
			}
		}		
		fly_comment_new();
	}
}


//字幕队列控制，出队列
function fly_comment_new(){
	var comment = fly_var_queue[fly_var_indexNext];
	var channel = _fly_channel_request(comment);		//请求通道
	//创建文本实例
	//trace(channel[1] + ", " + channel[0] + ", " + comment.cmtText);
	var txt:TextField = _level0.createTextField(null, channel[1], FLY_STARTING_X, channel[0], 1, 1);
	txt.autoSize = true;
	txt.text = comment.cmtText;
	//txt.antiAliasType = "ADVANCED";
	//txt.sharpness = 400;			
	//设置样式
	txt.setTextFormat(_fly_comment_get_style(comment.fontColor, comment.fontSize));
	//设置非飘移字体的位置
	if(comment.flyType != FLY_TYPE_FLY){
		txt._visible = false;
		txt._x = (ytVideo._width - txt.textWidth) / 2;
	}
		
	//显示
	fly_show(txt, FLY_SPEED_NORMAL, comment.sTime, comment.flyType, comment.cmtID);
	
	//设置下一次显示字体的事件
	fly_var_indexNext++;
	//trace("fly_comment_new " + fly_var_indexNext + "~~" + fly_var_queueLength);
	if(fly_var_indexNext < fly_var_queueLength){
		var nextTime = (fly_var_queue[fly_var_indexNext].sTime - comment.sTime) * 1000;
		if(nextTime <= 0) nextTime = 1;		//如果已经超过了下一个字幕显示的时间延迟1ms后立刻显示下一字幕
		setTimeout(fly_comment_new, nextTime);
		//trace("fly_comment_new-->nextTime=" + nextTime + "	" + fly_var_queue[fly_var_indexNext].cmtText);
	}
}
	
//获取字体格式对象，返回 TextFormat
function _fly_comment_get_style(fColor, fSize){
	var s:TextFormat = new TextFormat;
	s.bold = true;
	s.size = fSize;
	s.color = int("0x" + fColor);
	return s;
}
	

//评论显示开始
function fly_show(txt:TextField, speed:Number, startTime:Number, flyType:Number, cmtID:Number){
	if(flyType == FLY_TYPE_FLY){		//飘移的字幕
		//trace("fly_show=" + speed + "=" + startTime + " = " + getTimer());
		setTimeout(_fly_move, (startTime - _video_get_time()) * 1000, txt, speed, startTime, cmtID);
	}
	else{		//定点显示的字幕
		txt._visible = true;
		setTimeout(_fly_delete, speed * 1000, cmtID, txt);
	}
}

//内部 刷新评论位置
function _fly_move(txt:TextField, speed:Number, startTime:Number, cmtID:Number){
	//计算当前字幕的x坐标（可能是负值）
	var timePass:Number = _video_get_time() - startTime;
	//trace("_fly_move timePass=" + timePass + " " + getTimer());
	if(timePass > speed){
		_fly_delete(cmtID, txt);
		return false;	//若已经超出时间则退出
	}
	var txtX = (FLY_STARTING_X + txt.textWidth) * (timePass / speed);		//字幕离开起点的距离
	txtX = FLY_STARTING_X - txtX;
	if(video_var_playing && false){
		txtX = (txt.textWidth + FLY_STARTING_X) / (speed * 1000 / FLY_FLASH_INTERVAL);
		txt._x -= txtX;
	}
	else{
		txt._x = txtX;
		//debug = debug + "\n" + ns.time + "," + startTime + "," + timePass + "," + getTimer() + "," + txtX;
	}
	//trace(txtX);
	setTimeout(_fly_move, FLY_FLASH_INTERVAL, txt, speed, startTime, cmtID);
}

//内部 删除评论
var debug:String;
function _fly_delete(cmtID:Number, txt:TextField){
	//释放通道
	_fly_channel_release(cmtID);
	//删除文本实例
	txt.removeTextField();
	//trace(debug);
}

//内部 通道占用
function _fly_channel_occupy(chl){
	//如果数组空则直接push进去
	//trace("current = " + _fly_var_channels.length);
	if(_fly_var_channels.length == 0){
		_fly_var_channels.push(chl);
		return false;
	}
	//数组不空才需要查找
	var i = 0;
	while(i < _fly_var_channels.length){
		if(_fly_var_channels[i][0] >= chl[0]){
			break;
		}
		i++;
	}
	_fly_var_channels.splice(i, 0, chl);
	//trace(_fly_var_channels);
}
	

//内部 通道释放
function _fly_channel_release(cmtID){
	for(var i = 0; i < _fly_var_channels.length; i++){
		if(_fly_var_channels[i][1].cmtID == cmtID){
			_fly_var_channels.splice(i, 1);
			i = _fly_var_channels.length;
		}
	}
}		

//内部 核心 通道请求
function _fly_channel_request(cmt){
	var cl = Array(1, 1);	//(通道，层) cl-->Channel Level
	var chl = new Array(0, {cmtID:cmt.cmtID, channelBreadth:cmt.fontSize + 2, deathTime:(cmt.sTime + cmt.flySpeed)})
	
	//分配层
	_fly_var_level_accumulator++;
	var lvl = _fly_var_level_accumulator % FLY_LEVEL_RANGE;
	
	//分配通道
	switch(cmt.flyType){
		case FLY_TYPE_BOTTOM:			
			//设置查找初始位置
			if(chl[1].isSubtitle){
				chl[0] = ytVideo._height - chl[1].channelBreadth;
			}
			else{
				chl[0] = FLY_SUBTITLE_REDLINE - chl[1].channelBreadth;
			}
			
			//从尾开始查找可用的通道，因为第二页以后就是负的通道ID，所以基本上不会与FLY和TOP的字幕相互影响
			var fFlag = false;
			var stIndex = _fly_var_channels.length - 1;
			
			//查找到已有的通道头小于我们的初始通道尾的通道
			while(stIndex > 0 && !fFlag){
				if(_fly_var_channels[stIndex][0] <= chl[0] + chl[1].channelBreadth){
					fFlag = true;
				}
				else{
					fFlag--;
				}
			}
			//如果找不到通道尾小于我们初始通道的通道的话，则可以直接使用现在的通道
			if(stIndex == 0){
				fFlag = true;
			}
			
			//如果还没有能分配通道，则进行查找分配
			if(!fFlag){
				while(!fFlag && stIndex >= 0){
					//把我们的分配到他头上去
					chl[0] = _fly_var_channels[stIndex][0] - chl[1].channelBreadth - 1;
					//如果我们的头通道小于等于他的尾通道，则会发生冲突
					var itTail = _fly_var_channels[stIndex][0] + _fly_var_channels[stIndex][1].channelBreadth;
					if(chl[0] <= itTail){
						stIndex--;
					}
					else{
						fFlag = true;
					}
				}
				//如果已经找到通道头还没有找到可用通道，则直接分配到上一个通道的头通道去
				if(stIndex < 0){
					chl[0] = _fly_var_channels[0][0] - chl[1].channelBreadth - 1;
					fFlag = true;
				}
			}

			//对负数的通道取模
			
			if(chl[0] <= 0){
				var modNum = 0;
				if(chl[1].isSubtitle){
					modNum = (ytVideo._height - chl[1].channelBreadth);
				}
				else{
					modNum = FLY_SUBTITLE_REDLINE - chl[1].channelBreadth;
				}
				chl[0] = chl[0] % modNum + modNum;
			}

			cl[1] = FLY_LEVEL_BOTTOM + lvl;
			break;
			
		
		//默认的飘移字幕和顶部字幕的通道分配
		default:

			//从头开始查找可用的通道，直到字幕红线为止
			var fFlag = false;
			//先设置查找初始数组索引，从通道ID为0处开始查找
			var stIndex = 0;
			if(_fly_var_channels.length != 0){
				while(!fFlag && stIndex <= _fly_var_channels.length){
					if(_fly_var_channels[stIndex] >= 0){
						fFlag = true;
					}
					else{
						stIndex++;
					}
				}
				//如果到了数组末尾还找不到大于0的通道就可以从分配通道1
				if(stIndex == _fly_var_channels.length){
					fFlag = true;
					chl[0] = 1;
				}
				else{
					fFlag = false;
				}
			}
		
			//循环查找可用的通道
			while(!fFlag){
				chl[0]++;
				if(_fly_var_channels.length == 0){	//如果已经分配的通道数为0则可以直接分配1号通道
					fFlag = true;
				}
				else{			//否则就要查找可用的通道
					//trace(_fly_var_channels[stIndex][0] + " > " + chl[0] + chl[1].channelBreadth);
					if(_fly_var_channels[stIndex][0] > chl[0] + chl[1].channelBreadth){		//如果该通道头大于本通道尾，继续判断
						//还要判断我们的通道尾有没有超过下一个通道的头
						if(stIndex + 1 == _fly_var_channels.length){	//后面已经没有通道了，可以分配
							fFlag = true;
						}
						else if(_fly_var_channels[stIndex + 1][0] > chl[0] + chl[1].channelBreadth){	//否则还要判断一下
							fFlag = true;
						}
					}
		
					if(!fFlag){	//否则，计算是否能在该通道占用者消失前使用该通道
						
						//……额……这里实现起来比较复杂，先留着……
						
						//如果还是不行的话就只能死翘翘了，继续查找吧
						if(!fFlag){
							chl[0] = _fly_var_channels[stIndex][0] + _fly_var_channels[stIndex][1].channelBreadth + 1;
							stIndex++;
							//trace(stIndex + " >= " + _fly_var_channels.length);
							if(stIndex >= _fly_var_channels.length){
								fFlag = true;
							}
						}
					}
					
				}
			}
			//trace(chl[0] + "	" + chl[1].deathTime);
			//超过字幕红线的必须从头取模，另加一个小偏移量，避免通道ID完全一致
			if(chl[0] + chl[1].channelBreadth >= fly_subtitle_redline){
				chl[0] = chl[0] % FLY_SUBTITLE_RANGE + Math.round(chl[0] % FLY_SUBTITLE_RANGE);
			}
			
			//查找终于完毕了
			cl[0] = chl[0];
			
			cl[1] = cmt.flyType + lvl;
			break;
			
/*		case FLY_TYPE_TOP:
			cl[0] = (ytVideo._y + chl[1].channelBreadth);
			cl[1] = FLY_LEVEL_TOP + lvl;
			break;
*/

	}
	
	_fly_channel_occupy(chl);
	
	return cl;
}


//囧的XML的getElementByTagName函数 递归查找（注意是Element而不是Elements哦）
function xml_getElementByTagName(xml, nodeName){
	for(var i = 0; i < xml.childNodes.length; i++){
		if(xml.childNodes[i].nodeName == nodeName){
			return xml.childNodes[i]
		}
		else{
			if(xml.childNodes[i].nodeName){
				var node = xml_getElementByTagName(xml.childNodes[i], nodeName);
				if(node.nodeName == nodeName) return node;
			}
		}
	}
}