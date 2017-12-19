<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

String lineChannel		= nullToString(request.getParameter("lineChannel"), "");

if (beEmpty(lineChannel)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

InputStream	is			= null;
String		contentStr	= "";

//取得POST內容
//範例：{"events":[{"type":"message","replyToken":"8ae2399e5479413aad4da654b0779fec","source":{"userId":"Ue913331687d5757ccff454aab90f55cb","type":"user"},"timestamp":1508602936037,"message":{"type":"text","id":"6875441678650","text":"h"}}]}

try {
	is = request.getInputStream();
	contentStr= IOUtils.toString(is, "utf-8");
} catch (IOException e) {
	e.printStackTrace();
	writeLog("error", "\nUnable to get request body: " + e.toString());
	return;
}

writeLog("debug", "\n***********************************************************************************************");
writeLog("debug", "Receive Line message: " + contentStr);

/*
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();
*/
//out.close();

//解析JSON參數
JSONParser parser = new JSONParser();

String	sType = "";
String	sReplyToken = "";
String	sSourceUserId = "";
String	sSourceRoomId = "";
String	sSourceGroupId = "";
String	sSourceType = "";
String	sTimestamp = "";
String	sMessageType = "";
String	sMessageId = "";
String	sMessageText = "";
String	sReplyMessageText = "請傳送文字訊息給我 \uDBC0\uDC84";

Object objBody = null;
JSONObject jsonObjectBody = null;

try {
	objBody = parser.parse(contentStr);
	jsonObjectBody = (JSONObject) objBody;

	// loop array，一次request可能包含多個event
	JSONArray aEvents = (JSONArray) jsonObjectBody.get("events");
	Iterator<String> iEvent = aEvents.iterator();
	Object objEvent = new Object();
	JSONObject jsonObjectEvent = new JSONObject();
	Object objSource = new Object();
	JSONObject jsonObjectSource = new JSONObject();
	Object objMessage = new Object();
	JSONObject jsonObjectMessage = new JSONObject();

	while (iEvent.hasNext()) {
		objEvent = iEvent.next();
		jsonObjectEvent = (JSONObject) objEvent;
		sType = (String) jsonObjectEvent.get("type");
		if (notEmpty(sType) && (sType.equals("message")||sType.equals("follow"))){
			sReplyToken = (String) jsonObjectEvent.get("replyToken");
		}
		objSource = jsonObjectEvent.get("source");
		jsonObjectSource = (JSONObject) objSource;
		sSourceUserId = (String) jsonObjectSource.get("userId");
		sSourceRoomId = (String) jsonObjectSource.get("roomId");
		sSourceGroupId = (String) jsonObjectSource.get("groupId");
		sSourceType = (String) jsonObjectSource.get("type");
		sTimestamp = (String) jsonObjectEvent.get("timestamp").toString();
		if (notEmpty(sType) && sType.equals("message")){
			objMessage = jsonObjectEvent.get("message");
			jsonObjectMessage = (JSONObject) objMessage;
			sMessageType = (String) jsonObjectMessage.get("type");
			sMessageId = (String) jsonObjectMessage.get("id");
			if (notEmpty(sMessageType)){
				if (sMessageType.equals("sticker")){	//用戶傳送貼圖過來
					sReplyMessageText = "請傳送文字訊息給我，我看不懂你的貼圖啊 \uDBC0\uDC17";
				}else if (sMessageType.equals("text")){	//用戶傳送文字訊息過來
					sMessageText = (String) jsonObjectMessage.get("text");
					sMessageText = sMessageText.toLowerCase();
					sReplyMessageText = sMessageText;
					if (notEmpty(sMessageText)){	//用戶傳入文字訊息，判斷用戶資料並做對應的處理
						if (sMessageText.indexOf("功能說明")>0){	//由LINE@Manager設定的關鍵字回覆即可
							continue;
						}else if (sMessageText.indexOf("\"")>-1 || sMessageText.indexOf("'")>-1){
							sReplyMessageText = "訊息中請勿使用單引號或雙引號!";
						} else if (sMessageText.startsWith("A,") || sMessageText.startsWith("a,")){			//Admin傳來的指令
							sReplyMessageText = processAdminCommand(sSourceUserId, lineChannel, sMessageText);
						}else if (sMessageText.startsWith("1,") || sMessageText.startsWith("2,") || sMessageText.startsWith("3,")){	//加盟商傳來的指令
							sReplyMessageText = processDealerCommand(sSourceUserId, lineChannel, sMessageText);
						}else{	//其他指令，可能是傳來授權碼
							sReplyMessageText = processOtherCommand(sSourceUserId, lineChannel, sMessageText);
						}
					}	//if (notEmpty(sMessageText)){	//用戶傳入文字訊息，判斷用戶資料並做對應的處理
					/*
					if (notEmpty(sMessageText)){	//用戶傳入文字訊息，判斷用戶資料並做對應的處理
						ht = getAccountProfileByLineId(lineChannel, sSourceUserId, gcDataSourceName);
						sResultCode = ht.get("ResultCode").toString();
						sResultText = ht.get("ResultText").toString();
						if (!sResultCode.equals(gcResultCodeSuccess)){	//用戶資料找不到，或有問題
							if (sResultCode.equals(gcResultCodeNoDataFound)){	//找不到用戶資料，
							}else{	//DB有問題
								sReplyMessageText = sResultText;
							}	//if (sResultCode.equals(gcResultCodeNoDataFound)){	//找不到用戶資料，
						}else{	//有用戶資料，看看是不是傳入幫下一層人設定的授權碼
						}	//if (!sResultCode.equals(gcResultCodeSuccess)){	//用戶資料找不到，或有問題
					}	//if (notEmpty(sMessageText)){	//用戶傳入文字訊息，判斷用戶資料並做對應的處理
					*/
				}	//if (sMessageType.equals("sticker")){	//用戶傳送貼圖過來
			}	//if (notEmpty(sMessageType)){
		}	//if (notEmpty(sType) && sType.equals("message")){
		writeLog("debug", "Line channel= " + lineChannel);
		writeLog("debug", "Event type= " + sType);
		writeLog("debug", "Event replyToken= " + sReplyToken);
		writeLog("debug", "Event source userId= " + sSourceUserId);
		writeLog("debug", "Event source roomId= " + sSourceRoomId);
		writeLog("debug", "Event source groupId= " + sSourceGroupId);
		writeLog("debug", "Event source type= " + sSourceType);
		writeLog("debug", "Event timestamp= " + sTimestamp);
		writeLog("debug", "Event message type= " + sMessageType);
		writeLog("debug", "Event message id= " + sMessageId);
		writeLog("debug", "Event message text= " + sMessageText);
		writeLog("info", "System reply message text= " + sReplyMessageText);
		if (beEmpty(sReplyMessageText) || sReplyMessageText.equals("主選單")){
			sReplyMessageText = generateMainMenu(sReplyToken, sSourceUserId, sSourceRoomId, sSourceGroupId, sSourceType);
		}else{
			sReplyMessageText = generateTextMessage(sReplyToken, sReplyMessageText);
		}

		/* 這是用戶加入好友或解鎖電話管家訊息時，LINE 送來的 follow 通知
			{"events":[{"type":"follow","replyToken":"223f9cc52d6b42a487e1287fab800e56","source":{"userId":"Ue913331687d5757ccff454aab90f55cb","type":"user"},"timestamp":1508660591361}]}
		*/
		if (sType.equals("follow")){	//用戶加入好友，若DB已有此用戶(可能用戶之前封鎖現在解開)，把用戶狀態改為 follow
			writeLog("info", "用戶加入官網服務(或解除封鎖)");
			if (updateUserStatus(sSourceUserId, lineChannel, sType)){
				sReplyMessageText = "";	//不用回覆任何訊息，由LINE@MANAGER裡面設定的Greeting messages自動回覆
			}else{
				sReplyMessageText = "啟用您的帳號失敗，請稍後再試!";
			}
		}
		if (sType.equals("unfollow")){	//用戶主動封鎖，把用戶狀態改為 unfollow，從此不會發訊息給用戶，用戶也無法登入官網WEB
			writeLog("info", "用戶封鎖官網服務");
			updateUserStatus(sSourceUserId, lineChannel, sType);
			sReplyMessageText = "";	//沒甚麼好說的了，這時候傳訊息的話LINE會回覆 400 error
		}

		//回傳 Line 訊息給客戶
		if (notEmpty(sReplyMessageText)){
			if (!sendReplyMessageToLine(lineChannel, sReplyMessageText)){
				sResultCode = gcResultCodeUnknownError;
				sResultText = gcResultTextUnknownError;
			}
		}
	}	//while (iEvent.hasNext()) {

	writeLog("info", "All events are processed!");
} catch (Exception e) {
	writeLog("error", "Parse failed exception: " + e.toString());
	e.printStackTrace();
	sResultCode = gcResultCodeUnknownError;
	sResultText = gcResultTextUnknownError;
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

writeLog("debug", obj.toString());

%>

<%!
	/*********************************************************************************************************************/
	//處理由 Admin 送來的指令，return需要Reply給LINE的訊息
	private String processAdminCommand (String sLineUserId, String sLineChannel, String sMessageText){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sStatus				= "";
		String		sReplyMessageText	= "";
		List<String> sSQLList			= new ArrayList<String>();
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		String		sUser				= "System";
		String		sSequence			= "";
		String		sAuthorizationCode	= "";
		
		if (sMessageText.length()<3) return "訊息格式錯誤";
		
		sSQL = "SELECT A.Account_Sequence, DATE_FORMAT(A.Expiry_Date, '%Y-%m-%d %H:%i:%s'), A.Status";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Line_User_ID='" + sLineUserId + "'";
		sSQL += " AND A.Line_Channel_Name='" + sLineChannel + "'";
		sSQL += " AND A.Account_Type='A'";
	
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			if (isExpired(s[0][1])){
				return "您的帳號已過期，無法進行此操作";
			}
			sStatus = nullToString(s[0][2], "");
			if (!sStatus.equals("Active")){
				return "您的帳號狀態為非使用中，無法進行此操作";
			}
			
			sAuthorizationCode = sMessageText.substring(2);
			if (isDuplicateAuthorizationCode(sAuthorizationCode)){
				return "目前系統中有相同的授權碼待用戶註冊帳號，請稍後使用此授權碼再試一次，或換一個授權碼!";
			}
			//開始建立加盟商的授權碼
			sSequence = getSequence(gcDataSourceName);	//取得新的Account_Sequence序號
			sSQL = "INSERT INTO callpro_account (Create_User, Create_Date, Update_User, Update_Date, Account_Sequence, Account_Name, Account_Type, Line_User_ID, Line_Channel_Name, Parent_Account_Sequence, Audit_Phone_Number, Expiry_Date, Status) VALUES (";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += sSequence + ",";
			sSQL += "'" + sAuthorizationCode + "',";
			sSQL += "'" + "D" + "',";
			sSQL += "'" + "" + "',";
			sSQL += "'" + "" + "',";
			sSQL += "'" + s[0][0] + "',";
			sSQL += "'" + "" + "',";
			sSQL += "'" + "2099-12-31 23:59:59" + "',";
			sSQL += "'" + "Init" + "'";
			sSQL += ")";
			sSQLList.add(sSQL);
			ht = updateDBData(sSQLList, gcDataSourceName, false);
			sResultCode = ht.get("ResultCode").toString();
			sResultText = ht.get("ResultText").toString();
			
			if (sResultCode.equals(gcResultCodeSuccess)){	//成功
				return "執行成功，請加盟商於5分鐘內輸入授權碼" + sAuthorizationCode + "+逗點+Gmail帳號，例如以下內容：\n" + sAuthorizationCode + ",abc@gmail.com";
			}else{
				writeLog("error", "Failed to insert data, SQL= " + sSQL + ", sResultText=" + sResultText);
				return "作業失敗，錯誤訊息：" + sResultText;
			}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
			return "系統中沒有您的管理者帳號，無法進行此操作";
		}else{	//有誤
			return "無法取得您的帳號資訊，無法進行此操作，錯誤訊息：" + sResultText;
		}
		//return sReplyMessageText;
	}	//private String processAdminCommand (String sLineUserId, String sLineChannel, String sMessageText){

	/*********************************************************************************************************************/
	//處理由 加盟商 送來的指令，return需要Reply給LINE的訊息
	private String processDealerCommand (String sLineUserId, String sLineChannel, String sMessageText){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sStatus				= "";
		String		sReplyMessageText	= "";
		List<String> sSQLList			= new ArrayList<String>();
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		String		sUser				= "System";
		String		sSequence			= "";
		String		sAuthorizationCode	= "";
		String		sAccountType		= "";
		String		sBillType			= "";
		
		if (sMessageText.length()<3) return "訊息格式錯誤";
		
		sSQL = "SELECT A.Account_Sequence, DATE_FORMAT(A.Expiry_Date, '%Y-%m-%d %H:%i:%s'), A.Status";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Line_User_ID='" + sLineUserId + "'";
		sSQL += " AND A.Line_Channel_Name='" + sLineChannel + "'";
		sSQL += " AND A.Account_Type='D'";
		sSQL += " AND A.Status='Active'";
	
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			if (isExpired(s[0][1])){
				return "您的帳號已過期，無法進行此操作";
			}
			/*
			sStatus = nullToString(s[0][2], "");
			if (!sStatus.equals("Active")){
				return "您的帳號狀態為非使用中，無法進行此操作";
			}
			*/
			
			sAuthorizationCode = sMessageText.substring(2);
			if (isDuplicateAuthorizationCode(sAuthorizationCode)){
				return "目前系統中有相同的授權碼(電話號碼)待用戶註冊帳號，請稍後使用此授權碼再試一次，或換一個授權碼!";
			}
			if (isDuplicateAuditPhoneNumber(sAuthorizationCode)){
				return "目前系統中已有此電話號碼的主人資料，不需重複建立此電話主人帳號!";
			}
			//開始建立電話主人的授權碼
			sSequence = getSequence(gcDataSourceName);	//取得新的Account_Sequence序號
			if (sMessageText.startsWith("1,")){	//試用版
				sAccountType = "T";
				sBillType = "A";
			}
			if (sMessageText.startsWith("2,")){	//入門版
				sAccountType = "O";
				sBillType = "B";
			}
			if (sMessageText.startsWith("3,")){	//進階版
				sAccountType = "O";
				sBillType = "A";
			}
			
			if (sAccountType.equals("O")){	//加盟商想新增非試用的電話主人帳號，檢查這個加盟商的Purchase_Quantity 減 Provision_Quantity 是否還夠用
				if (isExceedPurchaseQuantity(s[0][0])){
					return "您所購買的門號數已經用滿了，無法再開通新的用戶，請先購買新的門號!";
				}
			}

			sSQL = "INSERT INTO callpro_account (Create_User, Create_Date, Update_User, Update_Date, Account_Sequence, Account_Name, Account_Type, Bill_Type, Line_User_ID, Line_Channel_Name, Parent_Account_Sequence, Audit_Phone_Number, Expiry_Date, Status) VALUES (";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += "'" + sUser + "',";
			sSQL += "'" + sDate + "',";
			sSQL += sSequence + ",";
			sSQL += "'" + sAuthorizationCode + "',";
			sSQL += "'" + sAccountType + "',";
			sSQL += "'" + sBillType + "',";
			sSQL += "'" + "" + "',";
			sSQL += "'" + "" + "',";
			sSQL += "'" + s[0][0] + "',";
			sSQL += "'" + sAuthorizationCode + "',";
			sSQL += "'" + "2099-12-31 23:59:59" + "',";
			sSQL += "'" + "Init" + "'";
			sSQL += ")";
			sSQLList.add(sSQL);
			ht = updateDBData(sSQLList, gcDataSourceName, false);
			sResultCode = ht.get("ResultCode").toString();
			sResultText = ht.get("ResultText").toString();
			
			if (sResultCode.equals(gcResultCodeSuccess)){	//成功
				if (sMessageText.startsWith("2,")){	//試用版
					return "執行成功，請電話主人於5分鐘內輸入以下授權碼：\n" + sAuthorizationCode;
				}else{
					return "執行成功，請電話主人於5分鐘內輸入授權碼" + sAuthorizationCode + "+逗點+Gmail帳號，例如以下內容：\n" + sAuthorizationCode + ",abc@gmail.com";
				}
			}else{
				writeLog("error", "Failed to insert data, SQL= " + sSQL + ", sResultText=" + sResultText);
				return "作業失敗，錯誤訊息：" + sResultText;
			}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
			return "系統中沒有您的加盟商帳號、或您的帳號未啟用，無法進行此操作";
		}else{	//有誤
			return "無法取得您的帳號資訊，無法進行此操作，錯誤訊息：" + sResultText;
		}
		//return sReplyMessageText;
	}	//private String processDealerCommand (String sLineUserId, String sLineChannel, String sMessageText){

	/*********************************************************************************************************************/
	//處理其他指令，可能是用戶傳來授權碼，return需要Reply給LINE的訊息
	private String processOtherCommand (String sLineUserId, String sLineChannel, String sMessageText){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sStatus				= "";
		String		sReplyMessageText	= "";
		String		aMsg[]				= null;
		String		sGoogleEmail		= "";
		List<String> sSQLList			= new ArrayList<String>();
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		String		sUser				= "System";
		String		sRowId				= "";
		String		sAccountType		= "";
		String		sBillType			= "";
		String		sAccountSequence	= "";
		
		if (beEmpty(sMessageText)) return "請輸入訊息";
		aMsg = sMessageText.split(",");
		if (aMsg.length==2){
			sMessageText = aMsg[0];
			sGoogleEmail = aMsg[1].toLowerCase();
			if (sGoogleEmail.indexOf("@gmail.com")<1) return "GMail信箱格式錯誤";
		}
		
		sSQL = "SELECT A.id, A.Account_Sequence, A.Account_Name, A.Account_Type, A.Bill_Type, A.Parent_Account_Sequence, A.Audit_Phone_Number, DATE_FORMAT(A.Expiry_Date, '%Y-%m-%d %H:%i:%s'), A.Status";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Account_Name='" + sMessageText + "'";
		sSQL += " AND A.Status='Init'";
		sSQL += " AND DATE_ADD( A.Create_Date , INTERVAL 5 MINUTE )>'" + sDate + "'";
	
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			if (isExpired(s[0][7])){
				return "您的帳號已過期，無法進行此操作";
			}
			//開始註冊帳號
			sRowId = s[0][0];
			sAccountSequence = nullToString(s[0][1], "");
			sAccountType = nullToString(s[0][3], "");
			sBillType = nullToString(s[0][4], "");
			if (beEmpty(sAccountType)){
				return "無法取得您的帳號類型，請您的門號管理者、商家重新申請授權碼!";
			}

			//檢查此用戶在相同的 Line Channel 底下是否已經有相同角色的帳號，不允許一個Line ID在同個Line Channel底下有相同類型的帳號
			if (isDuplicateAccountTypeUnderSameLineChannel(sLineUserId, sLineChannel, sAccountType, nullToString(s[0][6], ""))){
				return "您在此產品中已有相同功能的帳號，不需重複申請帳號";
			}

			if (sAccountType.equals("D") || ((sAccountType.equals("O")||sAccountType.equals("T"))&&!sBillType.equals("B"))){
				if (aMsg.length<2){
					return "請輸入您的授權碼+逗點+Gmail帳號，例如以下內容：\n" + aMsg[0] + "," + "abc@gmail.com";
				}
				if (!sendVerificationMailToGoogle(aMsg[1], sAccountSequence)){	//加盟商、非基本版的門號擁有者下一步須進行Google帳號註冊
					return "Gmail通知信發送失敗，請確認您的Gmail郵件地址是否正確，然後再試一次!";
				}
			}
			
			sSQL = "UPDATE callpro_account SET";
			sSQL += " Update_User='" + sUser + "'";
			sSQL += " ,Update_Date='" + sDate + "'";
			sSQL += " ,Line_User_ID='" + sLineUserId + "'";
			sSQL += " ,Line_Channel_Name='" + sLineChannel + "'";
			sSQL += " ,Send_Notification='" + "Y" + "'";
			if (sAccountType.equals("D") || ((sAccountType.equals("O")||sAccountType.equals("T"))&&!sBillType.equals("B"))){
				sSQL += " ,Status='" + "Google" + "'";	//加盟商、非基本版的門號擁有者下一步須進行Google帳號註冊
			}else{
				sSQL += " ,Status='" + "Active" + "'";
			}
			sSQL += " WHERE id=" + sRowId;
			sSQLList.add(sSQL);
			
			if (!sAccountType.equals("M") && !sAccountType.equals("U")){	//經銷商及門號擁有者須新增一筆資料至callpro_account_detail
				//先將舊資料砍掉，應該不會有舊資料，這只是以防萬一
				sSQL = "DELETE FROM callpro_account_detail";
				sSQL += " WHERE Main_Account_Sequence=" + sAccountSequence;
				sSQLList.add(sSQL);

				sSQL = "INSERT INTO callpro_account_detail (Create_User, Create_Date, Update_User, Update_Date, Google_ID, Google_User_Name, Google_User_Picture_URL, Google_Email, Contact_Phone, Contact_Address, Tax_ID_Number, Purchase_Quantity, Provision_Quantity, Member_Quantity, Last_Login_Date, Main_Account_Sequence) VALUES (";
				sSQL += "'" + sUser + "',";
				sSQL += "'" + sDate + "',";
				sSQL += "'" + sUser + "',";
				sSQL += "'" + sDate + "',";
				sSQL += "'" + "" + "',";
				sSQL += "'" + "" + "',";
				sSQL += "'" + "" + "',";
				if (sAccountType.equals("D") || ((sAccountType.equals("O")||sAccountType.equals("T"))&&!sBillType.equals("B"))){
					if (aMsg.length>1){
						sSQL += "'" + aMsg[1] + "',";
					}else{
						sSQL += "'" + "" + "',";
					}
				}else{
					sSQL += "'" + "" + "',";
				}
				
				sSQL += "'" + "" + "',";
				sSQL += "'" + "" + "',";
				sSQL += "'" + "" + "',";
				sSQL += (sAccountType.equals("D")?"30":"1") + ",";
				sSQL += (sAccountType.equals("D")?"0":"1") + ",";
				sSQL += (sAccountType.equals("D")?"0":"0") + ",";
				sSQL += "null" + ",";
				sSQL += "'" + sAccountSequence + "'";
				sSQL += ")";
				sSQLList.add(sSQL);
				
				if (sAccountType.equals("O")){	//這是電話主人帳號，將所屬加盟商的Provision_Quantity加1
					sSQL = "UPDATE callpro_account_detail SET";
					sSQL += " Update_User='" + sUser + "'";
					sSQL += " ,Update_Date='" + sDate + "'";
					sSQL += " ,Provision_Quantity=Provision_Quantity+1";
					sSQL += " WHERE Main_Account_Sequence=" + s[0][5];
					sSQLList.add(sSQL);
				}
			}	//if (!sAccountType.equals("M") && !sAccountType.equals("U")){	//經銷商及門號擁有者須新增一筆資料至callpro_account_detail

			ht = updateDBData(sSQLList, gcDataSourceName, false);
			sResultCode = ht.get("ResultCode").toString();
			sResultText = ht.get("ResultText").toString();
			
			if (sResultCode.equals(gcResultCodeSuccess)){	//成功
				if (sAccountType.equals("D") || ((sAccountType.equals("O")||sAccountType.equals("T"))&&!sBillType.equals("B"))){
					return "您的帳號已確認，請至Gmail信箱收取通知信，點選通知信中的網頁連結以註冊您的Google帳號!";
				}else{
					return "太棒了，您的帳號已經註冊完成!";
				}
			}else{
				writeLog("error", "Failed to insert data, SQL= " + sSQL + ", sResultText=" + sResultText);
				return "作業失敗，錯誤訊息：" + sResultText;
			}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，可能還沒設授權碼或授權碼輸入錯誤
			return "系統中沒有您輸入的授權碼資料(或授權碼已過期)，請確認授權碼是否正確，或請您的門號管理者、商家幫您以此授權碼申請帳號";
		}else{	//有誤
			return "無法取得您輸入的授權碼資訊，錯誤訊息：" + sResultText;
		}
		//return sReplyMessageText;
	}	//private String processOtherCommand (String sLineUserId, String sLineChannel, String sMessageText){

	/*********************************************************************************************************************/
	//檢查目前(5分鐘內)是否有重複的授權碼在等待用戶輸入
	private java.lang.Boolean isDuplicateAuthorizationCode(String sAuthorizationCode){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		
		sSQL = "SELECT A.Account_Sequence";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Account_Name='" + sAuthorizationCode + "'";
		sSQL += " AND A.Status='Init'";
		sSQL += " AND DATE_ADD( Create_Date , INTERVAL 5 MINUTE )>'" + sDate + "'";
		//writeLog("debug", "SQL= " + sSQL);
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			return true;
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，可能還沒設授權碼或授權碼輸入錯誤
			return false;
		}else{	//有誤
			writeLog("error", "Failed to check duplicate authorization code, SQL= " + sSQL + ", sResultText=" + sResultText);
			return true;
		}
	}	//private java.lang.Boolean isDuplicateAuthorizationCode(String sAuthorizationCode){

	/*********************************************************************************************************************/
	//加盟商想新增非試用的電話主人帳號，檢查這個加盟商的Purchase_Quantity 減 Provision_Quantity 是否還夠用
	private java.lang.Boolean isExceedPurchaseQuantity(String sAccountSequence){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		int			i					= 0;
		int			j					= 0;
		
		sSQL = "SELECT A.Purchase_Quantity, A.Provision_Quantity";
		sSQL += " FROM callpro_account_detail A";
		sSQL += " WHERE A.Main_Account_Sequence=" + sAccountSequence;

		//writeLog("debug", "SQL= " + sSQL);
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			s = (String[][])ht.get("Data");
			i = Integer.parseInt(s[0][0]);
			j = Integer.parseInt(s[0][1]);
			if ((i-j)<1) return true;
			else return false;
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，不對
			return true;
		}else{	//有誤
			writeLog("error", "Failed to check Exceed Purchase Quantity, SQL= " + sSQL + ", sResultText=" + sResultText);
			return true;
		}
	}	//private java.lang.Boolean isExceedPurchaseQuantity(String sAccountSequence){

	/*********************************************************************************************************************/
	//檢查目前系統中是否已有此電話號碼的主人資料
	private java.lang.Boolean isDuplicateAuditPhoneNumber(String sAuthorizationCode){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		
		sSQL = "SELECT A.Account_Sequence";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Audit_Phone_Number='" + sAuthorizationCode + "'";
		sSQL += " AND (A.Account_Type='O' OR A.Account_Type='T')";
		sSQL += " AND A.Status<>'Init'";
		//writeLog("debug", "SQL= " + sSQL);
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			return true;
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，OK
			return false;
		}else{	//有誤
			writeLog("error", "Failed to check duplicate Audit Phone Number, SQL= " + sSQL + ", sResultText=" + sResultText);
			return true;
		}
	}	//private java.lang.Boolean isDuplicateAuditPhoneNumber(String sAuthorizationCode){

	/*********************************************************************************************************************/
	//檢查此用戶在相同的 Line Channel 底下是否已經有相同角色的帳號，不允許一個Line ID在同個Line Channel底下有相同類型的帳號
	private java.lang.Boolean isDuplicateAccountTypeUnderSameLineChannel(String sLineUserId, String sLineChannel, String sAccountType, String sAuditPhoneNumber){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		
		sSQL = "SELECT A.id";
		sSQL += " FROM callpro_account A";
		sSQL += " WHERE A.Line_User_ID='" + sLineUserId + "'";
		sSQL += " AND A.Line_Channel_Name='" + sLineChannel + "'";
		if (sAccountType.equals("O") || sAccountType.equals("T")){
			sSQL += " AND (A.Account_Type='O' OR A.Account_Type='T')";
			sSQL += " AND Audit_Phone_Number='" + sAuditPhoneNumber + "'";
		}
		if (sAccountType.equals("M") || sAccountType.equals("U")){
			sSQL += " AND (A.Account_Type='M' OR A.Account_Type='U')";
			sSQL += " AND Audit_Phone_Number='" + sAuditPhoneNumber + "'";
		}
		sSQL += " AND A.Status<>'Init'";
		//writeLog("debug", "SQL= " + sSQL);
		ht = getDBData(sSQL, gcDataSourceName);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
			return true;
		}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，可能還沒設授權碼或授權碼輸入錯誤
			return false;
		}else{	//有誤
			writeLog("error", "Failed to check duplicate Account Type Under Same Line Channel, SQL= " + sSQL + ", sResultText=" + sResultText);
			return true;
		}
	}	//private java.lang.Boolean isDuplicateAccountTypeUnderSameLineChannel(String sLineUserId, String sLineChannel, String sAccountType){

	/*********************************************************************************************************************/
	//發送Gmail帳號註冊信給用戶輸入的Gmail address
	private java.lang.Boolean sendVerificationMailToGoogle(String gmailAddress, String sAccountSequence){
		java.lang.Boolean bOK = false;
		String sSubject = "Call-Pro帳號註冊通知信";
		String sBody = "";
		String sLink = gcSystemUri + "GoogleAccountRegistration.html?s=" + sAccountSequence + "&m=" + URLEncoder.encode(gmailAddress);
		sBody = "親愛的用戶您好，";
		sBody += "<p>感謝您使用Call-Pro服務，您的LINE帳號已確認，請點選下方連結註冊您的Google帳號，若未申請Call-Pro服務則請勿點選下方連結!";
		sBody += "<p><a href='" + sLink + "'>" + sLink + "</a>";
		sBody += "<p>Call-Pro祝您有美好的一天";
		bOK = sendHTMLMail(gcDefaultEmailFromAddress, gcDefaultEmailFromName, gmailAddress, sSubject, sBody, "", "", "", "");
		return bOK;

	}	//private java.lang.Boolean sendVerificationMailToGoogle(String gmailAddress, String sAccountSequence){

	/*********************************************************************************************************************/
	//用戶加入官方帳號、封鎖、解除封鎖時，變更DB中的用戶狀態
	//sStatus可能是 follow 或 unfollow
	private java.lang.Boolean updateUserStatus(String sLinrUserId, String sLineChannelName, String sStatus){
		Hashtable	ht					= new Hashtable();
		String		sSQL				= "";
		String		s[][]				= null;
		String		sResultCode			= gcResultCodeSuccess;
		String		sResultText			= gcResultTextSuccess;
		String		sDBStatus			= "unfollow";
		List<String> sSQLList			= new ArrayList<String>();
		String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
		String		sUser				= "System";
		sSQL = "UPDATE callpro_account SET Status ='";
		if (sStatus.equals("unfollow")) sDBStatus = "Unfollow";
		if (sStatus.equals("follow")) sDBStatus = "Active";
		sSQL += sDBStatus + "'";
		sSQL += " WHERE Line_User_ID='" + sLinrUserId + "'";
		sSQL += " AND Line_Channel_Name='" + sLineChannelName + "'";
		sSQL += " AND Status='";
		if (sStatus.equals("unfollow")) sDBStatus = "Active";
		if (sStatus.equals("follow")) sDBStatus = "Unfollow";
		sSQL += sDBStatus + "'";
		sSQLList.add(sSQL);
		ht = updateDBData(sSQLList, gcDataSourceName, false);
		sResultCode = ht.get("ResultCode").toString();
		sResultText = ht.get("ResultText").toString();
		
		if (sResultCode.equals(gcResultCodeSuccess)){	//成功
			return true;
		}else{
			return false;
		}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
	}	//private java.lang.Boolean updateUserStatus(String sLinrUserId, String sLineChannelName, String sStatus){

	/*********************************************************************************************************************/
	private String generateMainMenu(String sReplyToken, String sSourceUserId, String sSourceRoomId, String sSourceGroupId, String sSourceType){	//產生主選單
		/* 範例
			{"replyToken":"e627c4070a944e808486c9230ec6cf17","messages":[{"template":{"thumbnailImageUrl":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/images\/call-center-2537390_1280.jpg","text":"歡迎您使用電話管家服務\n請點選下方的服務","type":"buttons","title":"親愛的用戶您好!","actions":[{"label":"申請啟用LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyEnable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"},{"label":"申請取消LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyDisable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"}]},"altText":"選擇服務功能","type":"template"}]}
		*/
		JSONObject objReplyMessage=new JSONObject();

		objReplyMessage.put("replyToken", sReplyToken);
		List  l1 = new LinkedList();
		Map m1 = null;
		m1 = new HashMap();
		
		//以下是template類型的主選單
		m1.put("type", "template");
		m1.put("altText", "選擇服務功能");
		Map mapTemplate = null;
		mapTemplate = new HashMap();
		mapTemplate.put("type", "buttons");
		mapTemplate.put("thumbnailImageUrl", "https://cms.gslssd.com/PhoneHousekeeper/images/call-center-2537390_1024.jpg");
		mapTemplate.put("title", "親愛的用戶您好!");
		mapTemplate.put("text", "歡迎您使用電話管家服務\n請點選下方的服務");
		List  l2 = new LinkedList();
		Map mapAction = null;

		mapAction = new HashMap();
		mapAction.put("type", "uri");
		mapAction.put("label", "申請啟用LINE通知功能");
		//mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/ApplyLineNotifyEnable.html?lineUserId=" + sSourceUserId + "&lineUserType=" + sSourceType);
		mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/index.html?action=applylinenotification&lineUserId=" + nullToString(sSourceUserId, "") + "&lineRoomId=" + nullToString(sSourceRoomId, "") + "&lineGroupId=" + nullToString(sSourceGroupId, "") + "&lineUserType=" + nullToString(sSourceType, ""));
		l2.add(mapAction);

		mapAction = new HashMap();
		mapAction.put("type", "uri");
		mapAction.put("label", "申請取消LINE通知功能");
		//mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/ApplyLineNotifyDisable.html?lineUserId=" + sSourceUserId + "&lineUserType=" + sSourceType);
		mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/index.html?action=cancellinenotification&lineUserId=" + nullToString(sSourceUserId, "") + "&lineRoomId=" + nullToString(sSourceRoomId, "") + "&lineGroupId=" + nullToString(sSourceGroupId, "") + "&lineUserType=" + nullToString(sSourceType, ""));
		l2.add(mapAction);

		mapAction = new HashMap();
		mapAction.put("type", "uri");
		mapAction.put("label", "電話記錄查詢");
		mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/index.html?action=checkphonecallhistory");
		l2.add(mapAction);

		mapAction = new HashMap();
		mapAction.put("type", "uri");
		mapAction.put("label", "造訪電話管家網站");
		mapAction.put("uri", "https://cms.gslssd.com/PhoneHousekeeper/index.html");
		l2.add(mapAction);

		mapTemplate.put("actions", l2);
		m1.put("template", mapTemplate);
		l1.add(m1);
		objReplyMessage.put("messages", l1);	//一次最多可以傳 5 個訊息
		return objReplyMessage.toString();
	}	//private String generateMainMenu(String sReplyToken, String sSourceUserId, String sSourceType){	//產生主選單

	private String generateTextMessage(String sReplyToken, String sReplyMessageText){	//產生文字回覆訊息
		/* 範例
			{"replyToken":"e627c4070a944e808486c9230ec6cf17","messages":[{"template":{"thumbnailImageUrl":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/images\/call-center-2537390_1280.jpg","text":"歡迎您使用電話管家服務\n請點選下方的服務","type":"buttons","title":"親愛的用戶您好!","actions":[{"label":"申請啟用LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyEnable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"},{"label":"申請取消LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyDisable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"}]},"altText":"選擇服務功能","type":"template"}]}
		*/
		JSONObject objReplyMessage=new JSONObject();

		objReplyMessage.put("replyToken", sReplyToken);
		List  l1 = new LinkedList();
		Map m1 = null;
		m1 = new HashMap();
		//以下是文字訊息
		m1.put("type", "text");
		m1.put("text", sReplyMessageText);
		l1.add(m1);
		objReplyMessage.put("messages", l1);	//一次最多可以傳 5 個訊息
		return objReplyMessage.toString();
	}	//private String generateTextMessage(String sReplyToken, String sReplyMessageText){	//產生文字回覆訊息
	
	//回傳 Line 訊息給客戶
	private java.lang.Boolean sendReplyMessageToLine(String lineChannel, String sReplyMessageText){
		String		sLineGatewayUrlSendTextReply	= gcLineGatewayUrlSendTextReply;
		String		sResponse						= "";
		String		sResultCode						= "";
		String		sResultText						= "";
		//解析JSON參數
		JSONParser	parser							= new JSONParser();
		Object		objBody							= null;
		JSONObject	jsonObjectBody					= null;

		try
		{
			writeLog("debug", "Send reply message to Line: " + sReplyMessageText);
			
			URL u;
			u = new URL(sLineGatewayUrlSendTextReply + lineChannel);
			HttpURLConnection uc = (HttpURLConnection)u.openConnection();
			uc.setRequestProperty ("Content-Type", "application/json");
			uc.setRequestProperty("contentType", "utf-8");
			uc.setRequestMethod("POST");
			uc.setDoOutput(true);
			uc.setDoInput(true);
		
			byte[] postData = sReplyMessageText.getBytes("UTF-8");	//避免中文亂碼問題
			OutputStream os = uc.getOutputStream();
			os.write(postData);
			os.close();
		
			InputStream in = uc.getInputStream();
			BufferedReader r = new BufferedReader(new InputStreamReader(in));
			StringBuffer buf = new StringBuffer();
			String line;
			while ((line = r.readLine())!=null) {
				buf.append(line);
			}
			in.close();
			sResponse = buf.toString();	//取得回應值
			if (notEmpty(sResponse)){
				//解析JSON參數
				parser = new JSONParser();
				objBody = parser.parse(sResponse);
				jsonObjectBody = (JSONObject) objBody;
				sResultCode = (String) jsonObjectBody.get("resultCode");
				sResultText = (String) jsonObjectBody.get("resultText");
			}else{
				sResultCode = gcResultCodeUnknownError;
				sResultText = gcResultTextUnknownError;
			}
		}catch (Exception e){
			sResponse = e.toString();
			writeLog("error", "Exception when send message to Line: " + e.toString());
			sResultCode = gcResultCodeUnknownError;
			sResultText = sResponse;
		}
		
		if (sResultCode.equals(gcResultCodeSuccess)){
			writeLog("info", "Successfully send reply message to Line!");
			return true;
		}else{
			writeLog("error", "Failed to send reply message to Line: " + sResponse + "\nrequest body=" + sReplyMessageText);
			return false;
		}
	}	//private java.lang.Boolean sendReplyMessageToLine(String lineChannel, String sReplyMessageText){
%>