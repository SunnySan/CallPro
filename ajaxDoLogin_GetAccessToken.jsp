<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>
<%@ page trimDirectiveWhitespaces="true" %>

<%@page import="java.net.InetAddress" %>
<%@page import="org.json.simple.JSONObject" %>
<%@page import="org.json.simple.parser.JSONParser" %>
<%@page import="org.json.simple.parser.ParseException" %>
<%@page import="org.json.simple.JSONArray" %>
<%@page import="org.apache.commons.io.IOUtils" %>
<%@page import="java.util.*" %>

<%@page import="com.google.api.client.auth.oauth2.Credential" %>
<%@page import="com.google.api.client.auth.oauth2.StoredCredential" %>
<%@page import="com.google.api.client.googleapis.auth.oauth2.*" %>
<%@page import="com.google.api.client.http.javanet.NetHttpTransport" %>
<%@page import="com.google.api.client.json.jackson2.JacksonFactory" %>

<%@page import="java.io.File" %>
<%@page import="java.io.IOException" %>
<%@page import="java.io.InputStreamReader" %>
<%@page import="java.io.Reader" %>
<%@page import="java.util.List" %>


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

String authorizationCode	= nullToString(request.getParameter("GoogleCode"), "");

if (beEmpty(authorizationCode)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

//writeLog("debug", "Receive Google Authorization Code= " + authorizationCode);

session.removeAttribute("Account_Sequence");	//先清除 session 中的用戶資料
session.removeAttribute("Account_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Bill_Type");	//先清除 session 中的用戶資料
session.removeAttribute("Audit_Phone_Number");	//先清除 session 中的用戶資料

String CLIENT_SECRET_FILE	= application.getRealPath(gcGoogleClientSecretFilePath);
String TOKEN_REQUEST_URL	= gcGoogleUrlForGettingAccessToken;
String REDIRECT_URI			= gcGoogleAccessTokenRedirectUri;

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String accessToken = "";
String refreshToken = "";
String userId = "";  // Use this value as a key to identify a user.
String email = "";
boolean emailVerified = false;
String pictureUrl = "";
String familyName = "";
String name = "";
String givenName = "";

//向 Google 取得 Access Token
writeLog("debug", "Trying to get Google access token, Authorization Code= " + authorizationCode);

try{
	// Exchange auth code for access token
	GoogleClientSecrets clientSecrets =
	    GoogleClientSecrets.load(
	        JacksonFactory.getDefaultInstance(), new FileReader(CLIENT_SECRET_FILE));
	GoogleTokenResponse tokenResponse =
	          new GoogleAuthorizationCodeTokenRequest(
	              new NetHttpTransport(),
	              JacksonFactory.getDefaultInstance(),
	              TOKEN_REQUEST_URL,
	              clientSecrets.getDetails().getClientId(),
	              clientSecrets.getDetails().getClientSecret(),
	              authorizationCode,
	              REDIRECT_URI)  // Specify the same redirect URI that you use with your web
	                             // app. If you don't have a web version of your app, you can
	                             // specify an empty string.
	              .execute();
	
	
	accessToken = nullToString(tokenResponse.getAccessToken(), "");
	refreshToken = nullToString(tokenResponse.getRefreshToken(), "");
	writeLog("debug", "tokenResponse= " + tokenResponse);
	writeLog("debug", "refresh token= " + refreshToken);
	//以下是tokenResponse範例
	//{"access_token":"ya29.GlvzBF8ZiYm7a3WT-A18g3OFnWF9aGP6nSTEy69QIMC8__XJVKF1o7lEbe8P6Y62uhiMo4AwTz1oZ0zV2GBfOspr0nfooNdJ5Jn4zFPV6Ek001R16bn3S9JQF4N8","expires_in":3599,"id_token":"eyJhbGciOiJSUzI1NiIsImtpZCI6ImY0MGYxYTVmNGQ0OWVmOGY3YTI3ZjQ5NThhOTZkYjgzNWRiY2M0MmMifQ.eyJhenAiOiI4MzU3ODA3NjUxNzEtaGRvMjZqcjZja2Z1bGJpMjljMzNmYzdlYjZqZWE5Ym8uYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI4MzU3ODA3NjUxNzEtaGRvMjZqcjZja2Z1bGJpMjljMzNmYzdlYjZqZWE5Ym8uYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDM3OTQ3MjE1NzQ0ODg4MTMzODIiLCJlbWFpbCI6ImRpZWdvc3VuODg4QGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdF9oYXNoIjoiR0VfTzdpQU55Z0J0YWl2d0w2d1lVQSIsImlzcyI6Imh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbSIsImlhdCI6MTUwOTI4NjA2OCwiZXhwIjoxNTA5Mjg5NjY4LCJuYW1lIjoiU3VubnkgU3VuIiwicGljdHVyZSI6Imh0dHBzOi8vbGg2Lmdvb2dsZXVzZXJjb250ZW50LmNvbS8tS3Fwc2xxUFhpclkvQUFBQUFBQUFBQUkvQUFBQUFBQUFBQUEvQU5RMGtmNlhuYkNwRVF4ZWU2X3JUOENUVTI4VUZsOWFJQS9zOTYtYy9waG90by5qcGciLCJnaXZlbl9uYW1lIjoiU3VubnkiLCJmYW1pbHlfbmFtZSI6IlN1biJ9.dn8b2M-cIG8rxyWuZGn0Suxc_jpLRiyCuhIg0yl1YbfIDfQbqZGeC_HnkdcYN39aShf_Sv-CGE9BH8ku7SoThV1o-47qaJQCFS7BTpFgtQLny8VT6L16Pllk0ELexZUw_yS0V_9WCnsAcqedmJoKtyA1_rxgpo4RWDOqy9SgRZ5K_DWjGhqyFjznTyghkzd3e-jHWBWu4BEa9cas0Tmbk-VT4G_1Y9TPwSQKWsiHsVoL9lFI-xTq0cqahiqpu0SLYXIERKW-8_RzJWVnE28cBkj6lEl2x3gp6xtAEFNZcdbM6nZpznCqDMAuXpWD9Y-7Oau9uIY28NYZPJoq74mX1g","token_type":"Bearer"}
	
	// Use access token to call API
	
	// Get profile info from ID token
	GoogleIdToken idToken = tokenResponse.parseIdToken();
	GoogleIdToken.Payload payload = idToken.getPayload();
	userId = payload.getSubject();  // Use this value as a key to identify a user.
	email = payload.getEmail();
	emailVerified = Boolean.valueOf(payload.getEmailVerified());
	name = (String) payload.get("name");	//這是完整的 Sunny Sun
	pictureUrl = (String) payload.get("picture");
	//String locale = (String) payload.get("locale");
	familyName = (String) payload.get("family_name");	//Sun
	givenName = (String) payload.get("given_name");		//Sunny
}catch (Exception e){
	writeLog("error", "Error while getting access token from Google= " + e.toString());
	sResultCode = gcResultCodeUnknownError;
	sResultText = "無法取得Google Token，請稍後再試!<br>" + e.toString();
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}
writeLog("info", "accessToken= " + accessToken);
writeLog("info", "userId= " + userId);
writeLog("info", "email= " + email);
writeLog("info", "emailVerified= " + emailVerified);
writeLog("info", "pictureUrl= " + pictureUrl);
writeLog("info", "Name= " + name);
writeLog("info", "familyName= " + familyName);
writeLog("info", "givenName= " + givenName);

if (notEmpty(userId) && notEmpty(email) && notEmpty(accessToken)){	//Google正常回覆資料
	//將用戶資料寫到將回覆 client 端及紀錄到 session 的 JSON物件中
	name = nullToString(name, "");
	pictureUrl = nullToString(pictureUrl, "");
}else{
	writeLog("error", "Google respond empty userId or email or accessToken");
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

sSQL = "SELECT A.id, B.id, A.Account_Sequence, A.Account_Name, A.Account_Type, A.Bill_Type, A.Audit_Phone_Number, C.Channel_Desc";
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
	sSQL += "Google_Refresh_Token='" + refreshToken + "',";
	sSQL += "Update_User='" + sUser + "',";
	sSQL += "Update_Date='" + sDate + "',";
	sSQL += "Google_User_Name='" + name + "',";
	sSQL += "Google_User_Picture_URL='" + pictureUrl + "'";
	if (s.length==1){	//只有一筆資料
		sSQL += ",Last_Login_Date='" + sDate + "'";
		sSQL += " WHERE id=" + s[0][1];
	}else{
		sSQL += " WHERE Google_ID='" + userId + "'";
	}
	sSQLList.add(sSQL);
	//writeLog("debug", "更新 callpro_account_detail, SQL= " + sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);	//更新 callpro_account_detail 中的 Google_Refresh_Token
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
		writeLog("info", "用戶登入, Google_ID=" + userId);
		writeLog("info", "用戶登入, Account_Sequence=" + nullToString(s[0][2], ""));
		writeLog("info", "用戶登入, Account_Type=" + nullToString(s[0][4], ""));
		writeLog("info", "用戶登入, Bill_Type=" + nullToString(s[0][5], ""));
		writeLog("info", "用戶登入, Audit_Phone_Number=" + nullToString(s[0][6], ""));
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

