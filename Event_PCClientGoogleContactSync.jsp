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
<%@include file="00_GoogleAPI.jsp"%>
<%@include file="00_ClientContact.jsp"%>

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
https://cms.gslssd.com/CallPro/Event_PCClientNewCDR.jsp?areacode=02&phonenumber1=26585888&accesscode=123456&callerphone=0988123456&recordtime=30&recordtimestart=2018-01-23 10:42&call_direction=0&recordfile=ringtone_04.wav&ring_time=10&talked_time=20&callername=John&calleraddr=台北市內湖區成功路四段&callercompany=Call-Pro&calleremail=hello@gmail.com
************************************呼叫範例*******************************/

String CLIENT_SECRET_FILE	= application.getRealPath(gcGoogleClientSecretFilePath);
/** Application name. */
String APPLICATION_NAME = "Call-Pro";

String ERROR_RESPONSE = "error";	//當發生錯誤時，回覆給client端的字串

String sAreaCode			= nullToString(request.getParameter("areacode"), "");			//監控電話的室話區碼
String sPhoneNumber			= nullToString(request.getParameter("phonenumber1"), "");		//監控電話的電話號碼
String sAuthorizationCode	= nullToString(request.getParameter("accesscode"), "");			//授權碼
String sClientData	 		= nullToString(request.getParameter("contactall"), "");			//PC端新增或修改的資料

if (beEmpty(sAreaCode) || beEmpty(sPhoneNumber) || beEmpty(sAuthorizationCode)){
	writeLog("info", "Parameters not enough, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode);
	obj.put("resultCode", gcResultCodeParametersNotEnough);
	obj.put("resultText", gcResultTextParametersNotEnough);
	//out.print(obj);
	//out.flush();
	out.print(ERROR_RESPONSE);
	return;
}

if (!isValidPhoneOwner(sAreaCode, sPhoneNumber, sAuthorizationCode, "")){
	writeLog("error", "Authorization failed, areacode= " + sAreaCode + ", phonenumber1= " + sPhoneNumber + ", accesscode= " + sAuthorizationCode);
	obj.put("resultCode", gcResultCodeParametersValidationError);
	obj.put("resultText", gcResultTextParametersValidationError);
	//out.print(obj);
	//out.flush();
	out.print(ERROR_RESPONSE);
	return;
}

Hashtable	ht					= new Hashtable();
String		sResultCode			= gcResultCodeSuccess;
String		sResultText			= gcResultTextSuccess;

String		s[][]				= null;
String		sSQL				= "";
List<String> sSQLList			= new ArrayList<String>();

int			i					= 0;
int			j					= 0;

String		sRefreshToken			= "";
String		sContactSyncToken		= "";
String		sCallproAccountDetailRowId	= "";
java.lang.Boolean bHasPerson		= false;
String		sContactResourceName	= "";	//某個Person的resource name，刪除或更新google聯絡人時要用到
String		sContactListResponse	= "";	//要回覆給client端的聯絡人資訊
ClientUsers		uploadUsers							= null;	//Client上傳的聯絡人物件
ClientUser[]	aUploadUsers						= null;
String			sClientContactName					= "";
String			sClientContactGroup					= "";
String			sClientContactOccupation			= "";
String			sClientContactResidence				= "";
String			sClientContactAddress				= "";
String			sClientContactOrganization			= "";
String			sClientContactEmailAddress			= "";
PhoneNumbers	pnClientContactMobilePhoneNumbers	= null;
PhoneNumbers	pnClientContactHomePhoneNumbers		= null;
PhoneNumbers	pnClientContactWorkPhoneNumbers		= null;
String			sGoogleEmail						= "";

//確認門號主人狀態正常且已取得Google帳號
sSQL = "SELECT B.Google_Refresh_Token, B.Google_People_API_SyncToken, B.id, B.Google_Email";
sSQL += " FROM callpro_account A, callpro_account_detail B";
sSQL += " WHERE A.Audit_Phone_Number='" + sAreaCode + sPhoneNumber + "'";
sSQL += " AND (A.Account_Type='O' OR A.Account_Type='T')";
sSQL += " AND A.Status='Active'";
sSQL += " AND A.Account_Sequence=B.Main_Account_Sequence";

ht = getDBData(sSQL, gcDataSourceName);

sResultCode = ht.get("ResultCode").toString();
sResultText = ht.get("ResultText").toString();

if (sResultCode.equals(gcResultCodeSuccess)){	//有資料
	s = (String[][])ht.get("Data");
	if (beEmpty(s[0][0])){
		obj.put("resultCode", gcResultCodeNoDataFound);
		obj.put("resultText", "無法取得該門號主人Google帳號的Refresh Token，請門號主人至Google移除Call Pro服務後重新註冊");
		//out.print(obj);
		//out.flush();
		out.print(ERROR_RESPONSE);
		return;
	}
	sRefreshToken = s[0][0];
	sContactSyncToken = s[0][1];
	sCallproAccountDetailRowId = s[0][2];
	sGoogleEmail = s[0][3];
}else{
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	//out.print(obj);
	//out.flush();
	out.print(ERROR_RESPONSE);
	return;
}	//if (sResultCode.equals(gcResultCodeSuccess)){	//有資料

/****************初始化Client上傳的聯絡人物件*********************/
if (notEmpty(sClientData)){
	uploadUsers = new ClientUsers(sClientData);
}

/****************搜尋Google聯絡人資料*********************/

try{
	
    /** Global instance of the JSON factory. */
    JsonFactory JSON_FACTORY = JacksonFactory.getDefaultInstance();

    /** Global instance of the HTTP transport. */
    HttpTransport HTTP_TRANSPORT;
    HTTP_TRANSPORT = GoogleNetHttpTransport.newTrustedTransport();

	GoogleCredential credential = getGoogleCredential(sRefreshToken, CLIENT_SECRET_FILE);
	if (credential==null){	//取得 credential 失敗
		writeLog("error", "無法取得 Google credential");
		sendFullLoginMailToGoogle(sGoogleEmail);
		obj.put("resultCode", gcResultCodeUnknownError);
		obj.put("resultText", "無法取得 Google credential");
		out.print(obj);
		out.flush();
		return;
	}
	
	PeopleService peopleService = new PeopleService.Builder(HTTP_TRANSPORT, JSON_FACTORY, credential).build();
	
	if (uploadUsers!=null && uploadUsers.getUserCount()>0){
		//取得所有Google聯絡人姓名資料
		List<Person> connectionsAllName = getAllContacts(peopleService);
		writeLog("debug", "取得所有Google聯絡人姓名資料，總筆數= " + String.valueOf(connectionsAllName.size()));
		aUploadUsers = uploadUsers.getUsers();

		//找看看Client上傳的聯絡人姓名是否已在Google聯絡人中，如果有的話就將Google中的聯絡人刪除
		if (connectionsAllName.size()>0){	//找看看Client上傳的聯絡人姓名是否已在Google聯絡人中，如果有的話就將Google中的聯絡人刪除
			for (i=0;i<aUploadUsers.length;i++){
				sClientContactName = aUploadUsers[i].getName();
	            for (Person person : connectionsAllName) {
	            	if (sClientContactName.equals(person.getNames().get(0).getDisplayName())){	//找到了
	            		//將Google中的聯絡人刪除
	            		sContactResourceName = person.getResourceName();
	            		writeLog("info", "刪除 Google 聯絡人，姓名= " + sClientContactName + ", ContactResourceName=" + sContactResourceName);
	            		peopleService.people().deleteContact(sContactResourceName).execute();
	            		break;
	            	}	//if (sClientContactName.equals(person.getNames().get(0).getDisplayName())){	//找到了
	            }	//for (Person person : connections) 
			}	//for (i=0;i<aUploadUsers.length;i++){
		}	//if (connectionsAllName.size()>0){	//找看看Client上傳的聯絡人姓名是否已在Google聯絡人中，如果有的話就將Google中的聯絡人刪除
		
		//將Client上傳的聯絡人新增至Google聯絡人
		for (i=0;i<aUploadUsers.length;i++){
			sClientContactName					= aUploadUsers[i].getName();
			sClientContactGroup					= aUploadUsers[i].getGroup();
			sClientContactOccupation			= aUploadUsers[i].getOccupation();
			sClientContactResidence				= aUploadUsers[i].getResidence();
			sClientContactAddress				= aUploadUsers[i].getAddress();
			sClientContactOrganization			= aUploadUsers[i].getOrganization();
			sClientContactEmailAddress			= aUploadUsers[i].getEmailAddress();
			pnClientContactMobilePhoneNumbers	= aUploadUsers[i].getMobilePhoneNumbers();
			pnClientContactHomePhoneNumbers		= aUploadUsers[i].getHomePhoneNumbers();
			pnClientContactWorkPhoneNumbers		= aUploadUsers[i].getWorkPhoneNumbers();

			Person contactToCreate = new Person();

			List<Name> names = new ArrayList<Name>();
			names.add(new Name().setDisplayName(sClientContactName).setFamilyName(sClientContactName).setDisplayNameLastFirst(sClientContactName));
			contactToCreate.setNames(names);

			/*改成放在 Organization 的 Title
			List<Occupation> occupations = new ArrayList<Occupation>();
			occupations.add(new Occupation().setValue(sClientContactOccupation));
			contactToCreate.setOccupations(occupations);
			*/

			List<Residence> residences = new ArrayList<Residence>();
			residences.add(new Residence().setValue(sClientContactResidence));
			contactToCreate.setResidences(residences);

			List<Address> addresses = new ArrayList<Address>();
			addresses.add(new Address().setStreetAddress(sClientContactAddress));
			contactToCreate.setAddresses(addresses);

			List<Organization> organizations = new ArrayList<Organization>();
			organizations.add(new Organization().setTitle(sClientContactOccupation).setName(sClientContactOrganization));
			//organizations.add(new Organization().setName(sClientContactOrganization));
			contactToCreate.setOrganizations(organizations);

			List<EmailAddress> emailAddresses = new ArrayList<EmailAddress>();
			emailAddresses.add(new EmailAddress().setValue(sClientContactEmailAddress));
			contactToCreate.setEmailAddresses(emailAddresses);
			
			List<PhoneNumber> phoneNumbers = new ArrayList<PhoneNumber>();
			String[] numbers = null;
			int k = 0;
			if (pnClientContactMobilePhoneNumbers.getPhoneNumberCount()>0){
				numbers = pnClientContactMobilePhoneNumbers.getPhoneNumberList();
	            for (k=0;k<numbers.length;k++) {
	            	phoneNumbers.add(new PhoneNumber().setType("mobile").setValue(numbers[k]));
	            }
			}
			if (pnClientContactHomePhoneNumbers.getPhoneNumberCount()>0){
				numbers = pnClientContactHomePhoneNumbers.getPhoneNumberList();
	            for (k=0;k<numbers.length;k++) {
	            	phoneNumbers.add(new PhoneNumber().setType("home").setValue(numbers[k]));
	            }
			}
			if (pnClientContactWorkPhoneNumbers.getPhoneNumberCount()>0){
				numbers = pnClientContactWorkPhoneNumbers.getPhoneNumberList();
	            for (k=0;k<numbers.length;k++) {
	            	phoneNumbers.add(new PhoneNumber().setType("work").setValue(numbers[k]));
	            }
			}
			contactToCreate.setPhoneNumbers(phoneNumbers);

       		writeLog("info", "新增 Google 聯絡人，姓名= " + sClientContactName);
			Person createdContact = peopleService.people().createContact(contactToCreate).execute();
		}	//for (i=0;i<aUploadUsers.length;i++){
	}else{
		writeLog("debug", "Client無新增或修改的聯絡人資料，準備看Google有無更新資料");
	}	//if (uploadUsers.getUserCount()>0){
	
	//取得上次同步後，有異動的Google聯絡人詳細資料
	ListConnectionsResponse lcr = getUpdatedContacts(peopleService, sContactSyncToken);
	//ListConnectionsResponse lcr = getUpdatedContacts(peopleService, "");
	if (lcr==null){
		writeLog("error", "取得上次同步後，有異動的Google聯絡人詳細資料時發生錯誤");
		out.print(ERROR_RESPONSE);
		return;
	}
	String sNewContactSyncToken = lcr.getNextSyncToken();
	List<Person> connectionsUpdated = lcr.getConnections();
	if (connectionsUpdated!=null && connectionsUpdated.size()>0){	//Google上有更新的聯絡人，傳回給PC Client
		writeLog("info", "取得上次同步後，有異動的Google聯絡人詳細資料，筆數= " + String.valueOf(connectionsUpdated.size()));
		//把Google的 List<Person> 物件轉換成為要回覆給PC Client的格式
		String sResponse = convertGooglePersonListToResponseString(connectionsUpdated, aUploadUsers);
		out.print(sResponse);
	}else{
		writeLog("info", "本次無異動的Google聯絡人，將更新SyncToken至DB後結束作業");
	}	//if (connectionsUpdated!=null && connectionsUpdated.size()>0){	//Google上有更新的聯絡人，傳回給PC Client
	
	if (notEmpty(sNewContactSyncToken)){	//有新的SyncToken，更新至DB
		sSQL = "UPDATE callpro_account_detail";
		sSQL += " SET Google_People_API_SyncToken='" + sNewContactSyncToken + "'";
		sSQL += " WHERE id=" + sCallproAccountDetailRowId;
		sSQLList.add(sSQL);
		//有執行就好，不管成功或失敗都不影響回覆PC Client的資料
		ht = updateDBData(sSQLList, gcDataSourceName, false);
	}	//if (notEmpty(sNewContactSyncToken)){	//有新的SyncToken，更新至DB
}catch (Exception e){
	writeLog("error", "Google People API Error" + e.toString());
	sResultCode = gcResultCodeUnknownError;
	sResultText = "無法使用Google People API，請稍後再試!<br>" + e.toString();
	obj.put("resultCode", sResultCode);
	obj.put("resultText", sResultText);
	//out.print(obj);
	//out.flush();
	out.print(ERROR_RESPONSE);
	return;
}finally{
}

obj.put("resultCode", sResultCode);
obj.put("resultText", sResultText);
//out.print(obj);
if (notEmpty(sContactListResponse)){
	out.print(sContactListResponse);
	out.flush();
}

writeLog("info", "程式處理完畢!電話主人是：" + sAreaCode + sPhoneNumber);

%>

<%!
//取得所有Google聯絡人姓名資料
private List<Person> getAllContacts(PeopleService peopleService){
	List<Person> connectionsAllName = new ArrayList<Person>();
	try{
		String pageToken = "";
        // Request 10 connections.
        //https://developers.google.com/resources/api-libraries/documentation/people/v1/java/latest/
        ListConnectionsResponse response = null;
        while(true){
	        if (pageToken.length()<1){
		        response = peopleService.people().connections()
		                .list("people/me")
		                .setPageSize(200)
		                .setPersonFields("names")
		                .execute();
	    	}else{
		        response = peopleService.people().connections()
		                .list("people/me")
		                .setPageSize(200)
		                .setPersonFields("names")
		                .setPageToken(pageToken)
		                .execute();
	    	}
	
	        // Print display name of connections if available.
	        List<Person> connections = response.getConnections();
	        if (connections != null && connections.size() > 0) {
	            for (Person person : connections) {
	            	connectionsAllName.add(person);
	            }	//for (Person person : connections) 
	        }	//if (connections != null && connections.size() > 0) 
			pageToken = response.getNextPageToken();
			if (beEmpty(pageToken)) break;
		}	//while{
	} catch (Exception e) {
		writeLog("error", "Search Google contact error: " + e.toString());
		return null;
	}
	return connectionsAllName;
}

//取得上次同步後，有異動的Google聯絡人詳細資料
private ListConnectionsResponse getUpdatedContacts(PeopleService peopleService, String sContactSyncToken){
	ListConnectionsResponse lcr = new ListConnectionsResponse();
	String sNewSyncToken = "";
	List<Person> connectionsAll = new ArrayList<Person>();
	//String sFieldList = "names,memberships,occupations,residences,addresses,organizations,emailAddresses,phoneNumbers";
	String sFieldList = "names,memberships,residences,addresses,organizations,emailAddresses,phoneNumbers";
	try{
		String pageToken = "";
        // Request 10 connections.
        //https://developers.google.com/resources/api-libraries/documentation/people/v1/java/latest/
        ListConnectionsResponse response = null;
        while(true){
	        if (pageToken.length()<1){
	        	if (beEmpty(sContactSyncToken)){
			        response = peopleService.people().connections()
			                .list("people/me")
			                .setPageSize(200)
			                .setPersonFields(sFieldList)
			                .setRequestSyncToken(true)
			                .execute();
	        	}else{
			        response = peopleService.people().connections()
			                .list("people/me")
			                .setPageSize(200)
			                .setPersonFields(sFieldList)
			                .setSyncToken(sContactSyncToken)
			                .setRequestSyncToken(true)
			                .execute();
	        	}
	    	}else{
		        response = peopleService.people().connections()
		                .list("people/me")
		                .setPageSize(200)
		                .setPersonFields(sFieldList)
		                .setPageToken(pageToken)
		                .setRequestSyncToken(true)
		                .execute();
	    	}
	
	        // Print display name of connections if available.
	        List<Person> connections = response.getConnections();
	        if (connections != null && connections.size() > 0) {
	            for (Person person : connections) {
	            	connectionsAll.add(person);
	            }	//for (Person person : connections) 
	        }	//if (connections != null && connections.size() > 0) 
			pageToken = response.getNextPageToken();
			sNewSyncToken = response.getNextSyncToken();
			if (beEmpty(pageToken)) break;
		}	//while{
		lcr.setConnections(connectionsAll);
		lcr.setNextSyncToken(sNewSyncToken);
	} catch (Exception e) {
		writeLog("error", "Search Google updated contact error: " + e.toString());
		return null;
	}
	return lcr;
}

//把Google的 List<Person> 物件轉換成為要回覆給PC Client的格式
private String convertGooglePersonListToResponseString(List<Person> connectionsUpdated, ClientUser[] aUploadUsers){
	String s = "";
	ClientUser cu;
	List<PhoneNumber> pns;
	PhoneNumbers mobileNumbers;
	PhoneNumbers homeNumbers;
	PhoneNumbers workNumbers;
	String sNumber = "";
	int i = 0;
	int j = 0;
	String sTemp = "";
	String sClientContactName = "";
	java.lang.Boolean bFound = false;

	for (Person person : connectionsUpdated) {
		cu = new ClientUser();
		i++;

		try{
			sTemp = (person.getNames().get(0).getDisplayName()==null?"":person.getNames().get(0).getDisplayName());
		}catch (Exception e){
			sTemp = "";
		}
		writeLog("debug", "第" + String.valueOf(i) + "筆，姓名： " + sTemp);
		if (beEmpty(sTemp)){	//沒有姓名的話就跳過
			writeLog("debug", "此筆無姓名，跳過");
			continue;
		}
		cu.setName(sTemp);

		//看看這個姓名是否是我們剛剛新增至Google的，如果是就跳過
		bFound = false;
		if (aUploadUsers!=null && aUploadUsers.length>0){
			bFound = false;
			for (j=0;j<aUploadUsers.length;j++){
				sClientContactName = aUploadUsers[j].getName();
				if (sTemp.equals(sClientContactName)){
					writeLog("debug", "此筆資料是本次PC Client上傳後新增至Google的聯絡人，跳過");
					bFound = true;
					continue;
				}
			}
			if (bFound) continue;
		}
		
		try{
			sTemp = (person.getMemberships().get(0).getContactGroupMembership().getContactGroupId()==null?"":person.getMemberships().get(0).getContactGroupMembership().getContactGroupId());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "group: " + sTemp);
		cu.setGroup(sTemp);

		/*
		try{
			sTemp = (person.getOccupations().get(0).getValue()==null?"":person.getOccupations().get(0).getValue());
		}catch (Exception e){
			sTemp = "";
		}
		*/
		try{
			sTemp = (person.getOrganizations().get(0).getTitle()==null?"":person.getOrganizations().get(0).getTitle());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "sTemp: " + sTemp);
		cu.setOccupation(sTemp);

		try{
			sTemp = (person.getResidences().get(0).getValue()==null?"":person.getResidences().get(0).getValue());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "person.getResidences().get(0).getValue(): " + person.getResidences().get(0).getValue());
		cu.setResidence(sTemp);

		try{
			sTemp = (person.getAddresses().get(0).getStreetAddress()==null?"":person.getAddresses().get(0).getStreetAddress());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "person.getAddresses().get(0).getStreetAddress(): " + person.getAddresses().get(0).getStreetAddress());
		cu.setAddress(sTemp);

		try{
			sTemp = (person.getOrganizations().get(0).getName()==null?"":person.getOrganizations().get(0).getName());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "person.getOrganizations().get(0).getName(): " + person.getOrganizations().get(0).getName());
		cu.setOrganization(sTemp);

		try{
			sTemp = (person.getEmailAddresses().get(0).getValue()==null?"":person.getEmailAddresses().get(0).getValue());
		}catch (Exception e){
			sTemp = "";
		}
		//writeLog("debug", "person.getEmailAddresses().get(0).getValue(): " + person.getEmailAddresses().get(0).getValue());
		cu.setEmailAddress(sTemp);

		try{
			mobileNumbers = new PhoneNumbers();
			homeNumbers = new PhoneNumbers();
			workNumbers = new PhoneNumbers();

			pns = person.getPhoneNumbers();
			for (PhoneNumber pn : pns) {
				sTemp = pn.getType();
				sNumber = pn.getValue();
				if (notEmpty(sTemp)){
					if (sTemp.equals("mobile")){
						if (notEmpty(sNumber)) mobileNumbers.addPhoneNumber(sNumber);
					}else if (sTemp.equals("home")){
						if (notEmpty(sNumber)) homeNumbers.addPhoneNumber(sNumber);
					}else if (sTemp.equals("work")){
						if (notEmpty(sNumber)) workNumbers.addPhoneNumber(sNumber);
					}
				}
			}	//for (PhoneNumber pn : pns) {
			cu.setMobilePhoneNumbers(mobileNumbers);
			cu.setHomePhoneNumbers(homeNumbers);
			cu.setWorkPhoneNumbers(workNumbers);
		}catch(Exception e){
			mobileNumbers = null;
			homeNumbers = null;
			workNumbers = null;
		}

		//writeLog("debug", "cu.toString(): " + cu.toString());
		s += cu.toString() + "|";
	}	//for (Person person : connectionsUpdated) {
	//writeLog("debug", "Response= " + s);
	return s;
}

%>
