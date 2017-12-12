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

String src		= nullToString(request.getParameter("src"), "");

if (beEmpty(src)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

String sLineGatewayUrlSendTextReply = gcLineGatewayUrlSendTextReply;

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

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);

out.print(obj);
out.flush();
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
				if (sMessageType.equals("text")){	//用戶傳送文字訊息過來
					sMessageText = (String) jsonObjectMessage.get("text");
					sReplyMessageText = sMessageText;
				}
				if (sMessageType.equals("sticker")){	//用戶傳送貼圖過來
					sReplyMessageText = "請傳送文字訊息給我，我看不懂你的貼圖啊 \uDBC0\uDC17";
				}
			}	//if (notEmpty(sMessageType)){
		}
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
		
	}	//while (iEvent.hasNext()) {

	writeLog("info", "Event parse OK!");
} catch (Exception e) {
	writeLog("error", "Parse failed exception: " + e.toString());
	e.printStackTrace();
	out.println("Parse failed!");
	return;
}

/* 這是用戶加入好友或解鎖電話管家訊息時，LINE 送來的 follow 通知
	{"events":[{"type":"follow","replyToken":"223f9cc52d6b42a487e1287fab800e56","source":{"userId":"Ue913331687d5757ccff454aab90f55cb","type":"user"},"timestamp":1508660591361}]}
*/
if (sType.equals("follow")){	//用戶加入好友，若DB已有此用戶(可能用戶之前封鎖現在解開)，把用戶狀態改為 follow
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	//如果有需要可以回訊息給用戶
	//sReplyMessageText = "歡迎加入電話管家";
	out.print(obj);
	out.flush();
	return;
}
if (sType.equals("unfollow")){	//用戶主動封鎖，把用戶狀態改為 unfollow
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	
	out.print(obj);
	out.flush();
	return;
}



if (beEmpty(sReplyMessageText) || sReplyMessageText.equals("主選單")){
	sReplyMessageText = generateMainMenu(sReplyToken, sSourceUserId, sSourceRoomId, sSourceGroupId, sSourceType);
}else{
	sReplyMessageText = generateTextMessage(sReplyToken, sReplyMessageText);
}


//回傳 Line 訊息給客戶
String	sResponse	= "";
try
{
	writeLog("debug", "Send reply message to Line: " + sReplyMessageText);
	
	URL u;
	u = new URL(sLineGatewayUrlSendTextReply + src);
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
}catch (IOException e){
	sResponse = e.toString();
	writeLog("error", "Exception when send message to Line: " + e.toString());
	sResultCode = gcResultCodeUnknownError;
	sResultText = sResponse;
}

if (sResultCode.equals(gcResultCodeSuccess)){
	writeLog("info", "Successfully send reply message to Line!");
}else{
	writeLog("error", "Failed to send reply message to Line: " + sResponse + "\nrequest body=" + sReplyMessageText);
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

<%!
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
%>