﻿/***********YTdonghuaPlayer************/
/*******	writer.as		***********/
/*****	用以控制评论提交和输入	******/
/**************************************/

var _writer_var_fontsize = FLY_FONTSIZE_NORMAL;
var _writer_var_fontcolor = FLY_FONTCOLOR_DEFAULT;
var _writer_var_commentmode = FLY_TYPE_FLY;
var _writer_var_issubtitle = false;

function writer_submit(){
	var t = _level0.commentWriter.txtWriterInput;
	if(t.length == 0) return false;
	
	var playTime = _video_get_time() - 0.1;	//把评论时间提前0.1s
	if(playTime <= 0) playTime = 0.1;			//另外0.1s之前不允许评论
	
	trace(ns.time);
	
	//添加新的评论到屏幕上
	var newCmt = Array(t.text, {fontSize:_writer_var_fontsize, 
								 fontColor:_writer_var_fontcolor,
								 flyType:_writer_var_commentmode, 
								 sTime:playTime,
								 flySpeed:FLY_SPEED_NORMAL,
								 isSubtitle:_writer_var_issubtitle,
								 commentTime:(new Date())
						});
	comment_add_comment(newCmt[0], newCmt[1])
	
	//提交评论到服务器
	writer_send(newCmt[0], newCmt[1]);
	t.text = "";
}

function writer_send(con, attr){
	var url = URL_PREFIX + "savecomment.php?content=" + con + 
				"&fontsize=" + attr.fontSize + 
				"&color=" + attr.fontColor + 
				"&mode=" + attr.flyType +
				"&playtime=" + (attr.sTime * 1000) + 
				"&id=" + video_var_flvid;
	var xml = new XML();
	xml.load(url);
}


//评论样式窗口显示关闭
function writer_flytype_window_hide(){
	_level0.flyTypeWindow._visible = false;
}
function writer_flytype_window_show(){
	_level0.flyTypeWindow._visible = true;
}

//=====v====v======v======评论样式设置部分========
function writer_flytype_set(t){
	switch(t){
		case "top":
			_writer_var_commentmode = FLY_TYPE_TOP;
			break;
		case "bottom":
			_writer_var_commentmode = FLY_TYPE_BOTTOM;
			break;
		case "subtitle":
			_writer_var_commentmode = FLY_TYPE_SUBTITLE;
			break;
		default:
			_writer_var_commentmode = FLY_TYPE_FLY;
			break;
	}
	
	if(t == "subtitle"){
		_writer_subtitle_enable(true);
	}
	else{
		_writer_subtitle_enable(false);
	}
	
	writer_flytype_window_hide();
}

function writer_fontsize_set(s){
	var found = false;
	//查询此s值在列表中的位置
	var l:List = commentWriter.cmbWriterFontSize;
	for(var i = 0; i < l.length; i++){
		if(l.getItemAt(i).data == s){
			l.selectedIndex = i;
			found = true;
			i = l.length;
		}
	}
	if(!found){
		_writer_var_fontsize = FLY_FONTSIZE_NORMAL;
	}
}
	
	
function _writer_subtitle_enable(flag){
	_writer_var_issubtitle = flag;
	if(flag){
		writer_fontsize_set(FLY_FONTSIZE_SUBTITLE);
	}
	commentWriter.cmbWriterFontSize.enabled = !flag;
	trace("setto=" + commentWriter.cmbWriterFontSize.enabled);
}
//==^=====^====^======评论样式设置部分========