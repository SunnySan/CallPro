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
<%@include file="00_LineAPI.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

/************************************呼叫範例*******************************
https://www.call-pro.net/CallPro/Event_PCClientSendInstantNotification.jsp?areacode=02&phonenumber1=26585888&accesscode=123456&callerphone=0988123456&callername=hellokitty&callerdetail=great
************************************呼叫範例*******************************/

String sLineGatewayUrlSendTextPush = gcLineGatewayUrlSendTextPush;

String sAlarmMessage		= nullToString(request.getParameter("message"), "");		//發送訊息內容

writeLog("info", "Send alarm: " + sAlarmMessage);

if (beEmpty(sAlarmMessage)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);

int			i					= 0;
int			j					= 0;

String		sLineChannelName	= "CallProA";
String		sRecepientType		= "";

//發給管理者
sSQL = "SELECT Line_User_ID FROM callpro_account";
sSQL += " WHERE Account_Type='A'";
sSQL += " AND Line_Channel_Name='" + sLineChannelName + "'";
sSQL += " AND Expiry_Date>'" + sDate + "'";
sSQL += " AND Status='Active'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	if (s.length==1){
		sRecepientType = "push";
	}else{
		sRecepientType = "multicast";
	}
}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
	obj.put("resultCode", sResultCode);
	obj.put("resultText", "此電話號碼尚未設定LINE通知對象!");
	out.print(obj);
	out.flush();
	return;
}else{
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

String sMessageBody = "";
String sPushMessage = "";

sMessageBody = sAlarmMessage + "\n訊息發送時間：" + sDate;

sPushMessage = generateLineTextMessage(sRecepientType, s, sMessageBody);

//Push Line 訊息給客戶
//writeLog("debug", "Send line push to the following URL: " + sLineGatewayUrlSendTextPush + sLineChannelName + "&type=" + sRecepientType);
if (!sendPushMessageToLine(sLineGatewayUrlSendTextPush + sLineChannelName + "&type=" + sRecepientType, sPushMessage)){
	sResultCode = gcResultCodeUnknownError;
	sResultText = gcResultTextUnknownError;

	java.lang.Boolean bOK = false;
	String sSubject = "Call-Pro系統障礙通知";
	String sBody = "";
	sBody = "系統管理者注意，";
	sBody += "<p>系統測試發送LINE訊息失敗，發送內容：" + sMessageBody + "<br>請檢查系統狀態是否正常。";
	sBody += "<p>Call-Pro維運中心";
	bOK = sendHTMLMail(gcDefaultEmailFromAddress, gcDefaultEmailFromName, gcAlarmEmailRecipientAddress, sSubject, sBody, "", "", "", "");
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

//查詢Whoscall網站
/*
sResponse = "";
try
{
	writeLog("debug", "Search Whoscall Web");
	
	u = new URL("https://whoscall.com/zh-TW/tw/" + (sType.equals("in")?sAParty:sBParty) + "/");
	HttpURLConnection uc = (HttpURLConnection)u.openConnection();
	uc.setRequestProperty ("Content-Type", "application/json");
	uc.setRequestProperty("contentType", "utf-8");
	uc.setRequestMethod("GET");
	uc.setDoInput(true);

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
		i = sResponse.indexOf("class=\"number-info__category");
		if (i>0){
			i = sResponse.indexOf(">", i);
			j = sResponse.indexOf("<", i);
			if (j>0 && j>i){
				sResponse = sResponse.substring(i+1, j).trim();
			}
		}
	}
}catch (IOException e){
	//sResponse = e.toString();
	sResponse = "";
}

if (notEmpty(sResponse)){
	writeLog("debug", "Whoscall result=" + sResponse);
	sMessageBody = "Whoscall查詢結果：\n" + sResponse;
	sPushMessage = generateTextMessage(sRecepientType, s, sMessageBody);
	
	//Push Line 訊息給客戶
	sResponse	= "";
	try
	{
		writeLog("debug", "Send Whoscall push message to Line: " + sPushMessage);
		
		u = new URL(sLineGatewayUrlSendTextPush + "&type=" + sRecepientType);
		HttpURLConnection uc = (HttpURLConnection)u.openConnection();
		uc.setRequestProperty ("Content-Type", "application/json");
		uc.setRequestProperty("contentType", "utf-8");
		uc.setRequestMethod("POST");
		uc.setDoOutput(true);
		uc.setDoInput(true);
	
		byte[] postData = sPushMessage.getBytes("UTF-8");	//避免中文亂碼問題
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
			JSONParser parser = new JSONParser();
			Object objBody = parser.parse(sResponse);
			JSONObject jsonObjectBody = (JSONObject) objBody;
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
		writeLog("info", "Successfully send Whoscall push message to Line!");
	}else{
		writeLog("error", "Failed to send Whoscall push message to Line: " + sResponse + "\nrequest body=" + sPushMessage);
	}

}
*/
%>
