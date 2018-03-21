/**********這個檔案裡是一些公用的函數**********/

/**********全域變數**********/
var sServerBaseURL = "./";	//Server端接收 request 的 URL 路徑

/**********取得 server API 的 base URL**********/
function getServerBaseURL(){
	return sServerBaseURL;
}	//function getServerBaseURL(){

/**********判斷字串是否為空值**********/
function beEmpty(s){
	return (s==null || s=='undefined' || s.length<1);
}	//function scrollToTop(){

/**********判斷字串是否有值**********/
function notEmpty(s){
	return (s!=null && s!='undefined' && s.length>0);
}	//function scrollToTop(){

/**********將金額字串加上千位的逗點**********/
function toCurrency(s){
	if (beEmpty(s)) return "";	//字串為空
	if (isNaN(s))	return s;	//不是數字，回覆原字串
	
	var i = 0;
	var j = 0;
	var k = 0;
	var l = 0;
	var s2 = "";
	s = trim(s);
	i = s.length;			//i為字串長度
	if (i<4) return s;		//長度太短，不用加逗點，直接回覆原字串
	j = Math.floor(i/3);	//j為字串長度除以3的商數
	k = i % 3;				//k為字串長度除以3的餘數
	s2 = "";
	if (k>0) s2 = s.substring(0, k);
	for (l=0;l<j;l++){
		s2 = s2 + (s2==""?"":",") + s.substring(k+(l*3), k+(l+1)*3);
	}
	return s2;
}

/**********將字串的空白去掉**********/
function trim(stringToTrim){
	return stringToTrim.replace(/^\s+|\s+$/g,"");
}

/**********判斷字串開頭是否為指定的字**********/
String.prototype.startsWith = function(prefix)
{
    return (this.substr(0, prefix.length) === prefix);
}
 
/**********判斷字串結尾是否為指定的字**********/
String.prototype.endsWith = function(suffix)
{
    return (this.substr(this.length - suffix.length) === suffix);
}
 
/**********判斷字串是否包含指定的字**********/
String.prototype.contains = function(txt)
{
    return (this.indexOf(txt) >= 0);
}

/**********取得某個 URL 參數的值，例如 http://target.SchoolID/set?text=abc **********/
function getParameterByName( name ){
	name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
	var regexS = "[\\?&]"+name+"=([^&#]*)";
	var regex = new RegExp( regexS );
	var results = regex.exec( window.location.href );
	if( results == null )
		return "";
	else
		return decodeURIComponent(results[1].replace(/\+/g, " "));
}

/**********檢查email格式是否正確**********/
function isEmail(email) { 
	var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}

/**********顯示loading中的BlockUI**********/
function showBlockUI(){
	return;
/*
	$.blockUI({
		message: '<img src="images/loading.gif">資料更新中，請稍候...</img>',
		css: {
			border: 'none',
			background: 'none',
			color: '#00FF00'
		},
		overlayCSS:{
			backgroundColor: '#000000',
			opacity:         0.5,
			cursor:          'wait'
		}
	});
*/
	
	$.blockUI({ 
		message: '<img src="images/loading.gif">Retrieving data, please wait...</img>',
		css:{
			border: 'none',
			padding: '15px',
			backgroundColor: '#000',
			'-webkit-border-radius': '10px',
			'-moz-border-radius': '10px',
			opacity: 0.95,
			color: '#00FF00'
		}
	}); 

	//$('.blockOverlay').attr('title','以滑鼠點擊灰色區域可回到主畫面').click($.unblockUI);	//若加這一行且有使用JQuery UI Tooltip，則這一行字在BlockUI關閉後仍會殘留在IE畫面上(Chrome不會)
	//$('.blockOverlay').click($.unblockUI);	//若加這一行且有使用JQuery UI Tooltip，則這一行字在BlockUI關閉後仍會殘留在IE畫面上(Chrome不會)

}

/**********解除BlockUI**********/
function unBlockUI(){
	return;
	$.unblockUI();
}

/**********取得今天日期，格式為：2013/10/3**********/
function getCurrentDate(){
	var currDate = new Date();	//目前時間
	var txtCurrDate = currDate.getFullYear() + "-" + (currDate.getMonth()+1) + "-" + currDate.getDate();	//今天日期，格式為：2013/10/3
	return txtCurrDate;
}

/**********取得今天時間，格式為：13:50:50**********/
function getCurrentTime(){
	var currDate = new Date();	//目前時間
	
	var tHours = currDate.getHours() > 9 ? currDate.getHours() : '0'+currDate.getHours();
	var tMinutes = currDate.getMinutes() > 9 ? currDate.getMinutes() : '0'+currDate.getMinutes();
	var tSeconds = currDate.getSeconds() > 9 ? currDate.getSeconds() : '0'+currDate.getSeconds();
	return currDate= tHours +':'+ tMinutes +':'+ tSeconds;
}

/**********取得儲存在client端的變數值(從PC cookie或手機storage取得)**********/
function getLocalValue(key){
	var value = "";
	value = $.cookie(key);	//Browser，使用 cookie for JQuery
	if (beEmpty(value)) value="";
	return value;
}

/**********將變數值儲存在client端(PC cookie或手機storage)**********/
function setLocalValue(key, value, expires){	//若expires為空值，則僅存在此session中
	if (beEmpty(key)) return;
	$.cookie(key, value, { expires: expires, path: '/' });	//Browser，使用 cookie for JQuery，預設儲存30天
	return;
}

/**********顯示類似alert的message box**********/
function msgBox(msg, callbackClose){
	if ( typeof(dialogMessage) == "undefined"){
		$('body').append('<div id="dialogMessage" title="System Info."></div>');
	}
	$('#dialogMessage').html(msg);

	if (!beEmpty($('#dialogMessage').dialog( "instance" ))){
		$('#dialogMessage').dialog("destroy");
	}
	if (callbackClose==null){
		$( "#dialogMessage" ).dialog({
			modal: true,
			buttons: {
				Ok: function() {
					$( this ).dialog( "close" );
				}
			}
		});
	}else{
		$( "#dialogMessage" ).dialog({
			modal: true,
			buttons: {
				Ok: function() {
					$( this ).dialog( "close" );
					callbackClose
				}
			},
			close: callbackClose
		});
	}
}

/**********從 Server 擷取資料**********/
function getDataFromServer(sProgram, sData, sResponseType, SuccessCallback, bBlockUI){
	/*****************************************************************
	sProgram		server端程式名稱，例如 xxx.jsp
	sData			要post給server的資料
	sResponseType	希望server端回覆的資料類型，可為 json 或 xml
	SuccessCallback	成功從server取得資料時的處理程式(function)
	bBlockUI		是否顯示BlockUI，若未輸入此參數則預設為顯示BlockUI
	*****************************************************************/
	if (beEmpty(bBlockUI)) bBlockUI = true;
	bBlockUI = false;	//這個專案不用BlockUI，用AdminLTE的 Loading States <div class="overlay"> 代替
	if (beEmpty(sData)) sData = "ResponseType=" + sResponseType; else sData += "&ResponseType=" + sResponseType;
	$.ajax({
		url: sServerBaseURL + sProgram,
		type: 'POST', //根據實際情況，可以是'POST'或者'GET'
		beforeSend : (bBlockUI==true?showBlockUI:null),
		complete   : (bBlockUI==true?unBlockUI:null),
		data: sData,
		dataType: sResponseType, //指定數據類型，注意server要有一行：response.setContentType("text/xml;charset=utf-8");
		timeout: 1200000, //設置timeout時間，以千分之一秒為單位，1000 = 1秒
		error: function (){	//錯誤提示
			msgBox('System busy!!');
		},
		success: function (data){ //ajax請求成功後do something with response data
			SuccessCallback(data);
		}	//success: function (data){ //ajax請求成功後do something with response data
	});	//$.ajax({
	return false;
}	//function sServerBaseURL(sProgram, sData, sResponseType, SuccessCallback){

function clearCookie(){	//清除 cookie 中的登入資料
	setLocalValue("Account_Sequence", "");
	setLocalValue("Account_Name", "");
	setLocalValue("Account_Type", "");
	setLocalValue("Bill_Type", "");
	setLocalValue("Audit_Phone_Number", "");
	setLocalValue("Google_ID", "");
	setLocalValue("Google_User_Name", "");
	setLocalValue("Google_User_Picture_URL", "");
	return true;
}

//用戶登出
function doLogout(){
	clearCookie();
	var sData = "";
	getDataFromServer("ajaxDoLogout.jsp", sData, "json", function(data){
		location.href = "/index.html";
	});	//getDataFromServer("xxx.jsp", sData, "json", function(data){
}

//將 Status 欄位的英文轉成中文
function translateStatus(Status){
	var s = Status;
	if (s=="Active"){
		s="正常";
	}else if (s=="Suspend"){
		s="停用";
	}else if (s=="Unfollow"){
		s="未加入LINE";
	}else if (s=="Google"){
		s="待Google綁定";
	}else if (s=="Init"){
		s="初始中";
	}else if (s=="Delete"){
		s="已刪除";
	}
	return s;
}

//將電話主人類別轉成中文
function translateBillType(Bill_Type){
	var s = Bill_Type;
	if (s=="A"){
		s="進階版";
	}else if (s=="B"){
		s="入門版";
	}
	return s;
}

//在頁面填入一些預設值
function pageInit(){
	var myGoogleId = getLocalValue("Google_ID");
	var myAccountType = getLocalValue("Account_Type");
	var myAccountName = getLocalValue("Account_Name");
	var myGoogleName = getLocalValue("Google_User_Name");
	var myGooglePicture = getLocalValue("Google_User_Picture_URL");
	var myAuditPhoneNumber = getLocalValue("Audit_Phone_Number");
	if (beEmpty(myGoogleId) || beEmpty(myAccountType)){
		var me = window.location.pathname;
		var i = me.lastIndexOf("/");
		me = me.substring(i+1);	//目前的網頁名稱
		var s = "";
		if (me=="AdmOwnerCallLog.html"){
			var callerPhoneNumber = getParameterByName("callerPhoneNumber");
			if (notEmpty(callerPhoneNumber)) s = "?callerPhoneNumber=" + callerPhoneNumber;
		}
		alert("無法取得您的登入資訊，請重新登入!");
		location.href = "login_simple.html" + s;
	}
	
	if (beEmpty(myAccountName)) myAccountName = "無法取得註冊名稱";
	if (beEmpty(myGoogleName)) myGoogleName = "請問您貴姓大名？";
	if (beEmpty(myGooglePicture)) myGooglePicture = "images/JohnDoe.jpg";
	
	$('.sys-user-image').attr('src', myGooglePicture);
	if (beEmpty(myAuditPhoneNumber)){
		$('.sys-user-name').text(myGoogleName);
	}else{
		$('.sys-user-name').text(myAuditPhoneNumber);
	}
	$('.sys-user-account-name').text(myAccountName);
	var myType = "歡迎您";
	if (myAccountType=="A") myType = "系統管理者";
	if (myAccountType=="D") myType = "加盟商您好!";
	if (myAccountType=="O" || myAccountType=="T") myType = "電話主人您好!";
	$('#sys-account-type').text(" " + myType);
	
	generateMainMenu();
}

//產生主選單
function generateMainMenu() {
	var myAccountType = getLocalValue("Account_Type");
	var s = "";
	var s1 = "";
	var me = window.location.pathname;
	var i = me.lastIndexOf("/");
	me = me.substring(i+1);	//目前的網頁名稱

	var pageName = "";
	var bFound = false;
	s += "<li class='header'>請選擇您要執行的功能</li>";
	
	if (myAccountType=="O" || myAccountType=="T"){	//電話主人
		pageName = "AdmOwnerCallLog.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-table'></i> <span>通話記錄查詢</span></a></li>";
		pageName = "AdmOwnerMemberManagement.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-user'></i> <span>子帳號管理</span></a></li>";
		pageName = "AdmOwnerMyProfile.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-check-square'></i> <span>我的設定</span></a></li>";

		s1 = "";
		pageName = "AdmOwnerReport_DailyCallStatistics.html";
		if (pageName==me) bFound = true;
		s1 += "		<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-circle-o'></i> 每日通話統計</a></li>";
		pageName = "AdmOwnerReport_MonthlyCallStatistics.html";
		if (pageName==me) bFound = true;
		s1 += "		<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-circle-o'></i> 每月通話統計</a></li>";
		s += generateSeconeLevelMenu("fa-line-chart", bFound, "我的報表", s1);
	}else if (myAccountType=="D"){	//加盟商
		pageName = "AdmDealerCRM.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-table'></i> <span>客戶資料管理</span></a></li>";

		s1 = "";
		pageName = "AdmDealerReport_CustomerAccountStatistics.html";
		if (pageName==me) bFound = true;
		s1 += "		<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-circle-o'></i> 客戶資料統計</a></li>";
		s += generateSeconeLevelMenu("fa-line-chart", bFound, "我的報表", s1);
	}else if (myAccountType=="A"){	//系統管理者
		pageName = "AdmAdminDealerManagement.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-table'></i> <span>加盟商資料管理</span></a></li>";
		pageName = "AdmAdminPhoneOwnerManagement.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-table'></i> <span>電話主人資料管理</span></a></li>";
		pageName = "AdmAdminSendTestNotification.html";
		s += "<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-comment'></i> <span>LINE通知訊息測試</span></a></li>";

		s1 = "";
		pageName = "AdmAdminrReport_DealerStatistics.html";
		if (pageName==me) bFound = true;
		s1 += "		<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-circle-o'></i> 加盟商資料統計</a></li>";
		pageName = "AdmAdminrReport_PhoneOwnerStatistics.html";
		if (pageName==me) bFound = true;
		s1 += "		<li" + (pageName==me?" class='active'":"") + "><a href='" + pageName + "'><i class='fa fa-circle-o'></i> 電話主人資料統計</a></li>";
		s += generateSeconeLevelMenu("fa-line-chart", bFound, "我的報表", s1);
	}	//if (myAccountType=="O" || myAccountType=="T"){	//電話主人
	
	if (notEmpty(s)) $('#sys-main-menu').append(s);
}	//function generateMainMenu() {

//產生有第二層選單的HTML
function generateSeconeLevelMenu(levelOneIcon, bFound, firstLevelName, secondLevelHtml){
	var s = "";
	s += "<li class='treeview" + (bFound?" active":"") + "'>";
	s += "	<a href='#'>";
	s += "		<i class='fa " + levelOneIcon + "'></i> <span>" + firstLevelName + "</span>";
	s += "		<span class='pull-right-container'>";
	s += "			<i class='fa fa-angle-left pull-right'></i>";
	s += "		</span>";
	s += "	</a>";
	s += "	<ul class='treeview-menu'>";
	s += secondLevelHtml;
	s += "	</ul>";
	s += "</li>";
	
	return s;
}

