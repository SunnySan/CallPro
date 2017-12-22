<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>


<%!
/*********************************************************************************************************************/
//
public java.lang.Boolean sendPushMessageToLine(String sRecepientType, String sLineUserId, String sPushMessage){
	String				sResultCode			= gcResultCodeSuccess;
	String				sResultText			= gcResultTextSuccess;
	java.lang.Boolean	bOK					= false;

	try
	{
		writeLog("debug", "Send push message to Line: " + sPushMessage);
		
		u = new URL(gcLineGatewayUrlSendTextPush + "&type=" + sRecepientType);
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
		bOK = true;
		writeLog("info", "Successfully send push message to Line: " + sPushMessage);
	}else{
		writeLog("error", "Failed to send push message to Line: " + sResponse + "\nrequest body=" + sPushMessage);
	}
	
	return bOK;

}	//public java.lang.Boolean sendPushMessageToLine(String sRecepientType, String sLineUserId, String sPushMessage){

%>