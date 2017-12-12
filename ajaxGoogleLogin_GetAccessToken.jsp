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

String authorizationCode = nullToString(request.getParameter("GoogleCode"), "");
if (beEmpty(authorizationCode)){
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	out.print(obj);
	out.flush();
	return;
}

//writeLog("debug", "Receive Google Authorization Code= " + authorizationCode);
//session.removeAttribute("UserProfile");	//先清除 session 中的用戶資料
session.removeAttribute("GoogleUserId");	//先清除 session 中的用戶資料
session.removeAttribute("GoogleUserDisplayName");	//先清除 session 中的用戶資料
session.removeAttribute("GoogleUserPictureUrl");	//先清除 session 中的用戶資料

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
writeLog("debug", "accessToken= " + accessToken);
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
	obj.put("GoogleUserId", userId);
	obj.put("GoogleUserDisplayName", name);
	obj.put("GoogleUserPictureUrl", pictureUrl);
}else{
	writeLog("error", "Google respond empty userId or email");
	sResultCode = gcResultCodeUnknownError;
	sResultText = "無法取得您的Google ID或Email";
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

sSQL = "SELECT A.Status";
sSQL += " FROM phk_google_subscriber A";
sSQL += " WHERE A.Google_ID='" + userId + "'";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

sSQL = "";
if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	//檢查 Status
	s = (String[][])ht.get("Data");
	if (beEmpty(s[0][0]) || (!s[0][0].equals("Init") && !s[0][0].equals("Active"))){	//帳號狀態不對
		sResultCode = gcResultCodeAccountWasSuspended;
		sResultText = gcResultTextAccountWasSuspended;
		out.print(obj);
		out.flush();
		return;
	}
	
	//更新既有資料
	sSQL = "UPDATE phk_google_subscriber SET ";
	sSQL += "Update_User='" + sUser + "',";
	sSQL += "Update_Date='" + sDate + "',";
	sSQL += "Google_User_Name='" + name + "',";
	sSQL += "Google_User_Picture_URL='" + pictureUrl + "',";
	sSQL += "Google_Email='" + email + "',";
	if (notEmpty(refreshToken)) sSQL += "Google_Refresh_Token='" + refreshToken + "',";
	sSQL += "Last_Login_Date='" + sDate + "'";
	sSQL += " WHERE Google_ID='" + userId + "'";
	sSQLList.add(sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//成功
		writeLog("info", "Updated phk_google_subscriber data, Google user id= " + userId);
	}else{
		writeLog("error", "Fail to update phk_google_subscriber data (" + sResultCode + "): " + sResultText);
		out.print(obj);
		out.flush();
		return;
	}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
}else if (sResultCode.equals(gcResultCodeNoDataFound)){	//沒資料，新增一筆資料
	if (beEmpty(refreshToken)){	//沒有refreshToken，會造成以後的Google API無法使用，不能寫入DB
		writeLog("error", "Going to insert into phk_google_subscriber but has no Refresh Token");
		obj.put("resultCode", gcResultCodeUnknownError);
		obj.put("resultText", "無法取得您Google帳號的RefreshToken，請到您Google帳號的應用程式管理中移除電話管家服務，然後重新登入一次");
		out.print(obj);
		out.flush();
		return;
	}
	sSQL = "INSERT INTO phk_google_subscriber (Create_User, Create_Date, Update_User, Update_Date, Google_ID, Google_User_Name, Google_User_Picture_URL, Google_Email, Google_Refresh_Token, Last_Login_Date, Status) VALUES (";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + sUser + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + userId + "',";
	sSQL += "'" + name + "',";
	sSQL += "'" + pictureUrl + "',";
	sSQL += "'" + email + "',";
	sSQL += "'" + refreshToken + "',";
	sSQL += "'" + sDate + "',";
	sSQL += "'" + "Init" + "'";
	sSQL += ")";
	sSQLList.add(sSQL);
	ht = updateDBData(sSQLList, gcDataSourceName, false);
	sResultCode = ht.get("ResultCode").toString();
	sResultText = ht.get("ResultText").toString();
	if (sResultCode.equals(gcResultCodeSuccess)){	//成功
		writeLog("info", "Inserted data into phk_google_subscriber, Google user id= " + userId);
	}else{
		writeLog("error", "Fail to insert data into phk_google_subscriber (" + sResultCode + "): " + sResultText);
		out.print(obj);
		out.flush();
		return;
	}	//if (sResultCode.equals(gcResultCodeSuccess)){	//成功
}else{
	writeLog("error", "Fail to select phk_google_subscriber data (" + sResultCode + "): " + sResultText);
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	out.print(obj);
	out.flush();
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

//將登入的 LINE 用戶資料寫到 session 中，以後的作業會用到
//session.setAttribute("UserProfile", obj);	//將登入用戶資料存入 session 中
session.setAttribute("GoogleUserId", userId);	//將登入用戶資料存入 session 中
session.setAttribute("GoogleUserDisplayName", name);	//將登入用戶資料存入 session 中
session.setAttribute("GoogleUserPictureUrl", pictureUrl);	//將登入用戶資料存入 session 中

//回覆 client 端
obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
out.print(obj);
out.flush();

%>

