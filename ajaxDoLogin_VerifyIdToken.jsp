<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@page import="com.google.api.client.googleapis.auth.oauth2.GoogleIdToken" %>
<%@page import="com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload" %>
<%@page import="com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier" %>


<%@page import="java.io.File" %>
<%@page import="java.io.IOException" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.Reader" %>
<%@page import="java.util.List" %>


<%@include file="00_constants.jsp"%>
<%@include file="00_utility.jsp"%>
<%@include file="00_GoogleAPI.jsp"%>

<%
request.setCharacterEncoding("utf-8");
response.setContentType("text/html;charset=utf-8");
response.setHeader("Pragma","no-cache"); 
response.setHeader("Cache-Control","no-cache"); 
response.setDateHeader("Expires", 0); 

out.clear();	//注意，一定要有out.clear();，要不然client端無法解析XML，會認為XML格式有問題

/*********************開始做事吧*********************/
JSONObject obj=new JSONObject();

String CLIENT_ID = "752431198126-sv9ffo8ujqr5ml1ql3v9af350opibkt6.apps.googleusercontent.com";

String sIdToken	= nullToString(request.getParameter("idToken"), "");

if (beEmpty(sIdToken)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

session.removeAttribute("Account_Sequence");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Bill_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Audit_Phone_Number");	//先清除 session 中的用戶資料

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String userId = "";  // Use this value as a key to identify a user.
String email = "";
boolean emailVerified = false;
String pictureUrl = "";
String familyName = "";
String name = "";
String givenName = "";

try{
	
    /** Global instance of the JSON factory. */
    JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();

    /** Global instance of the HTTP transport. */
    HttpTransport HTTP_TRANSPORT;
    HTTP_TRANSPORT = GoogleNetHttpTransport.newTrustedTransport();

	GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(HTTP_TRANSPORT, JSON_FACTORY)
		// Specify the CLIENT_ID of the app that accesses the backend:
		.setAudience(Collections.singletonList(CLIENT_ID))
		// Or, if multiple clients access the backend:
		//.setAudience(Arrays.asList(CLIENT_ID_1, CLIENT_ID_2, CLIENT_ID_3))
		.build();
	
	// (Receive idTokenString by HTTPS POST)
	
	GoogleIdToken idToken = verifier.verify(sIdToken);
	if (idToken != null) {
		Payload payload = idToken.getPayload();
		
		// Print user identifier
		userId = payload.getSubject();
		//System.out.println("User ID: " + userId);
		
		// Get profile information from payload
		email = payload.getEmail();
		name = (String) payload.get("name");	//這是完整的 Sunny Sun
		pictureUrl = (String) payload.get("picture");
		//String locale = (String) payload.get("locale");
		familyName = (String) payload.get("family_name");	//Sun
		givenName = (String) payload.get("given_name");		//Sunny
	} else {
		sResultCode = gcResultCodeNoLoginInfoFound;
		sResultText = gcResultTextNoLoginInfoFound;
		writeLog("error", "Exception when verify id_token: " + sResultText);
		obj.put("resultCode", gcResultCodeParametersNotEnough);
		obj.put("resultText", gcResultTextParametersNotEnough);
		out.print(obj);
		out.flush();
		return;
	}
}catch (Exception e){
	sResultCode = gcResultCodeUnknownError;
	sResultText = e.toString();
	writeLog("error", "Exception when verify id_token: " + e.toString());
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

writeLog("debug", "userId= " + userId);
writeLog("debug", "email= " + email);
writeLog("debug", "emailVerified= " + emailVerified);
writeLog("debug", "pictureUrl= " + pictureUrl);
writeLog("debug", "Name= " + name);
writeLog("debug", "familyName= " + familyName);
writeLog("debug", "givenName= " + givenName);

if (notEmpty(userId) && notEmpty(email)){	//Google正常回覆資料
	//將用戶資料寫到將回覆 client 端及紀錄到 session 的 JSON物件中
	name = nullToString(name, "");
	pictureUrl = nullToString(pictureUrl, "");
}else{
	writeLog("error", "Google respond empty userId or email");
	sResultCode = gcResultCodeUnknownError;
	sResultText = "無法取得您的Google ID或Email或token";
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (notEmpty(userId) && notEmpty(email)){	//Google正常回覆資料


//從 Google 取得 User ID 了，到資料庫查一下
String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();
String		sDate				= getDateTimeNow(gcDateFormatSlashYMDTime);
String		sUser				= "System";
int			i					= 0;
int			j					= 0;

/*
sSQL = "SELECT A.id, B.id, A.Account_Sequence, A.Account_Name, A.Account_Type, A.Bill_Type, A.Audit_Phone_Number";
sSQL += " FROM callpro_account_detail B LEFT JOIN callpro_account A";
sSQL += " ON B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " WHERE B.Google_ID='" + userId + "'";
sSQL += " AND A.Status='Active'";
sSQL += " AND A.Expiry_Date>'" + sDate + "'";
*/

sSQL = "SELECT A.id, B.id, A.Account_Sequence, A.Account_Name, A.Account_Type, A.Bill_Type, A.Audit_Phone_Number, C.Channel_Desc, B.Google_User_Name, B.Google_User_Picture_URL";
sSQL += " FROM callpro_account_detail B, callpro_account A LEFT JOIN callpro_line_channel C";
sSQL += " ON A.Line_Channel_Name=C.Line_Channel_Name";
sSQL += " WHERE B.Google_ID='" + userId + "'";
sSQL += " AND B.Main_Account_Sequence=A.Account_Sequence";
sSQL += " AND A.Status='Active'";
sSQL += " AND A.Expiry_Date>'" + sDate + "'";

//writeLog("debug", sSQL);

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	//檢查 Status
	s = (String[][])ht.get("Data");

	//更新 callpro_account_detail 中的資料
	sSQL = "UPDATE callpro_account_detail SET ";
	if (notEmpty(name)) sSQL += "Google_User_Name='" + name + "',";
	if (notEmpty(pictureUrl)) sSQL += "Google_User_Picture_URL='" + pictureUrl + "',";
	sSQL += "Update_User='" + sUser + "',";
	sSQL += "Update_Date='" + sDate + "'";
	if (s.length==1){	//只有一筆資料
		sSQL += ",Last_Login_Date='" + sDate + "'";
		sSQL += " WHERE id=" + s[0][1];
	}else{
		sSQL += " WHERE Google_ID='" + userId + "'";
	}
	sSQLList.add(sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);	//更新 callpro_account_detail 中的Google資料
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (!sResultCode.equals(gcResultCodeSuccess)){	//失敗
		writeLog("error", "更新 callpro_account_detail 失敗 (" + sResultCode + "): " + sResultText);
		out.print(obj);
		out.flush();
		return;
	}

	if (s.length==1){	//只有一筆資料
		writeLog("info", "User login successfully, callpro_account.id=" + s[0][0] + ", name=" + s[0][3]);
		session.setAttribute("Google_ID", userId);	//將登入用戶資料存入 session 中
		session.setAttribute("Account_Sequence", nullToString(s[0][2], ""));	//將登入用戶資料存入 session 中
		session.setAttribute("Account_Type", nullToString(s[0][4], ""));	//將登入用戶資料存入 session 中
		session.setAttribute("Bill_Type", nullToString(s[0][5], ""));	//將登入用戶資料存入 session 中
		session.setAttribute("Audit_Phone_Number", nullToString(s[0][6], ""));	//將登入用戶資料存入 session 中
		writeLog("debug", "用戶登入, Google_ID=" + userId);
		writeLog("debug", "用戶登入, Account_Sequence=" + nullToString(s[0][2], ""));
		writeLog("debug", "用戶登入, Account_Type=" + nullToString(s[0][4], ""));
		writeLog("debug", "用戶登入, Bill_Type=" + nullToString(s[0][5], ""));
		writeLog("debug", "用戶登入, Audit_Phone_Number=" + nullToString(s[0][6], ""));
		if (beEmpty(name)) name = nullToString(s[0][8], "");
		if (beEmpty(pictureUrl)) pictureUrl = nullToString(s[0][9], "");
	}else{
		String sRandom = generateTxId();	//產生一個隨機數回給browser，同時存入session，作為等一下用戶確認使用哪個帳號登入時使用
		session.setAttribute("Google_ID", userId);	//將登入用戶資料存入 session 中
		obj.put("RandomKey", sRandom);
		session.setAttribute("RandomKey", sRandom);	//將隨機數存入 session 中
	}	//if (s.length==1){	//只有一筆資料
	obj.put("recordCount", String.valueOf(s.length));
	String[] fields2 = {"aid", "bid", "Account_Sequence", "Account_Name", "Account_Type", "Bill_Type", "Audit_Phone_Number", "Channel_Desc"};
	//若不只一筆資料，須讓用戶選要以哪個身分登入
	List  l1 = new LinkedList();
	Map m1 = null;
	for (i=0;i<s.length;i++){
		m1 = new HashMap();
		for (j=0;j<fields2.length;j++){
			m1.put(fields2[j], nullToString(s[i][j], ""));
		}
		l1.add(m1);
	}
	obj.put("records", l1);
	obj.put("Google_ID", userId);
	obj.put("Google_User_Name", name);
	obj.put("Google_User_Picture_URL", pictureUrl);
}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料
	obj.put("resultCode", sResultCode);
	obj.put("resultText", "無法取得您的註冊資料，請重新註冊!");
	out.print(obj);
	out.flush();
	return;
}else{
	writeLog("error", "Fail to select callpro_account and callpro_account_detail data (" + sResultCode + "): " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

//將登入的 LINE 用戶資料寫到 session 中，以後的作業會用到
//session.setAttribute("UserProfile", obj);	//將登入用戶資料存入 session 中
/*
session.setAttribute("GoogleUserId", userId);	//將登入用戶資料存入 session 中
session.setAttribute("GoogleUserDisplayName", name);	//將登入用戶資料存入 session 中
session.setAttribute("GoogleUserPictureUrl", pictureUrl);	//將登入用戶資料存入 session 中
*/

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

