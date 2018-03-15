<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>


<%!

/*********************************************************************************************************************/
//產生LINE訊息格式的內容
private String generateLineTextMessage(String sRecepientType, String s[][], String sMessage){	//產生單一文字訊息
	/* 範例
		{"replyToken":"e627c4070a944e808486c9230ec6cf17","messages":[{"template":{"thumbnailImageUrl":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/images\/call-center-2537390_1280.jpg","text":"歡迎您使用電話管家服務\n請點選下方的服務","type":"buttons","title":"親愛的用戶您好!","actions":[{"label":"申請啟用LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyEnable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"},{"label":"申請取消LINE通知功能","type":"uri","uri":"https:\/\/cms.gslssd.com\/PhoneHousekeeper\/ApplyLineNotifyDisable.html?lineUserId=Ue913331687d5757ccff454aab90f55cb&lineUserType=user"}]},"altText":"選擇服務功能","type":"template"}]}
	*/
	int			i					= 0;
	int			j					= 0;

	JSONObject objPushMessage=new JSONObject();

	if (sRecepientType.equals("push")){
		objPushMessage.put("to", s[0][0]);
	}else{
		List  lMulticast = new LinkedList();
		for (i=0;i<s.length;i++){	//每個i代表一個 row
			lMulticast.add(s[i][0]);
		}
		objPushMessage.put("to", lMulticast);
	}

	List  lMessage = new LinkedList();
	Map mapMessage = null;

	mapMessage = new HashMap();
	mapMessage.put("type", "text");
	mapMessage.put("text", sMessage);
	lMessage.add(mapMessage);
	
	objPushMessage.put("messages", lMessage);	//一次最多可以傳 5 個訊息，這個 function 只傳 1 個訊息
	return objPushMessage.toString();
}	//private String generateLineTextMessage(String sRecepientType, String s[][], String sMessage){	//產生單一文字訊息


/*********************************************************************************************************************/
//Push Line 訊息給客戶
public java.lang.Boolean sendPushMessageToLine(String sLineGatewayUrl, String sPushMessage){
	String				sResultCode			= gcResultCodeSuccess;
	String				sResultText			= gcResultTextSuccess;
	java.lang.Boolean	bOK					= false;

	String	sResponse	= "";
	URL u;
	
	try
	{
		writeLog("debug", "Send push message to Line: " + sPushMessage);
		
		u = new URL(sLineGatewayUrl);
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
	}catch (Exception e){
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

}	//public java.lang.Boolean sendPushMessageToLine(String sLineGatewayUrl, String sPushMessage){


%>