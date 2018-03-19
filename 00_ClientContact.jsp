<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8" %>

<%@page import="java.util.List" %>
<%@page import="java.util.Arrays" %>

<%!
/*********************************************************************************************************************/
public class ClientUsers {
    private List<ClientUser> users;

    public ClientUsers() {
    	this.users = new ArrayList<ClientUser>();
    }

    public ClientUsers(String contactall) {
    	this.users = new ArrayList<ClientUser>();
    	if (contactall==null || contactall.length()<1) return;
    	String[] aList = contactall.split("\\|");
    	if (aList==null || aList.length<1) return;
    	//writeLog("debug", "aList.length= " + aList.length);
    	//writeLog("debug", "after new");
    	ClientUser user = null;
    	for (int i=0;i<aList.length;i++){
    		if (aList[i].length()<1){
		    	//writeLog("debug", "null");
    		}else{
		    	//writeLog("debug", "aList[i]=" + aList[i]);
		    	user = new ClientUser(aList[i]);
		    	users.add(user);
		    	//writeLog("debug", "after init");
    		}
    	}
    }
    
    public ClientUser[] getUsers(){
    	return users.toArray(new ClientUser[0]);
    }

    public int getUserCount(){
    	return users.size();
    }
    
    public void addUser(ClientUser cu){
    	this.users.add(cu);
    }

    public String toString(){
    	String s = "";
    	ClientUser[] a = users.toArray(new ClientUser[0]);
    	if (a.length>0){
    		for (int i=0;i<a.length;i++){
    			s += a[i].toString() + "|";
    		}
    	}
    	return s;
    }
}

public class ClientUser {
	private String name;						//姓名
	private String group;						//群組
	private String occupation;					//職業職稱
	private String residence;					//城市
	private String address;						//地址
	private String organization;				//公司
	private String emailAddress;				//email
	private PhoneNumbers mobilePhoneNumbers;	//行動電話s
	private PhoneNumbers homePhoneNumbers;		//住家電話s
	private PhoneNumbers workPhoneNumbers;		//公司電話s

    public ClientUser() {
        this.name = "";
        this.group = "";
        this.occupation = "";
        this.residence = "";
        this.address = "";
        this.organization = "";
        this.emailAddress = "";
    	mobilePhoneNumbers	= new PhoneNumbers();
    	homePhoneNumbers	= new PhoneNumbers();
    	workPhoneNumbers	= new PhoneNumbers();
    }

    public ClientUser(String contactString) {
    	init(contactString);
    }

    public void init(String contactString) {
    	if (contactString==null || contactString.length()<1) return;
    	//writeLog("debug", "before new PhoneNumbers");
    	mobilePhoneNumbers	= new PhoneNumbers();
    	homePhoneNumbers	= new PhoneNumbers();
    	workPhoneNumbers	= new PhoneNumbers();
    	//writeLog("debug", "after new");
    	String[] aList = contactString.split("\\^");
    	//writeLog("debug", "after split");
    	if (aList.length!=8) return;
    	initAll(aList[0], aList[1], aList[2], aList[3], aList[4], aList[5], aList[6], aList[7]);
    }

    private void initAll(String name, String group, String occupation, String residence, String address, String organization, String emailAddress, String allPhoneNumbers) {
    	if (name==null || name.length()<1) return;
        this.name = (name==null?"":name);
        this.group = (group==null?"":group);
        this.occupation = (occupation==null?"":occupation);
        this.residence = (residence==null?"":residence);
        this.address = (address==null?"":address);
        this.organization = (organization==null?"":organization);
        this.emailAddress = (emailAddress==null?"":emailAddress);
        if (allPhoneNumbers!=null && allPhoneNumbers.length()>0){
        	String[] aList = allPhoneNumbers.split(";");
        	int i = 0;
        	String tmp = "";
        	for (i=0;i<aList.length;i++){
        		tmp = aList[i];
        		if (tmp!=null && tmp.length()>0){
	        		if (tmp.endsWith("1"))	this.mobilePhoneNumbers.addPhoneNumber(tmp.substring(0, tmp.length()-1));	//行動電話
	        		if (tmp.endsWith("2"))	this.homePhoneNumbers.addPhoneNumber(tmp.substring(0, tmp.length()-1));	//住家電話
	        		if (tmp.endsWith("3"))	this.workPhoneNumbers.addPhoneNumber(tmp.substring(0, tmp.length()-1));	//公司電話
        		}	//if (tmp!=null && tmp.length()>0){
        	}	//for (i=0;i<aList.length;i++){
        }	//if (allPhoneNumbers!=null && allPhoneNumbers.length()>0){
    }
    
    public String getName(){
    	return name;
    }

    public String getGroup(){
    	return group;
    }

    public String getOccupation(){
    	return occupation;
    }

    public String getResidence(){
    	return residence;
    }

    public String getAddress(){
    	return address;
    }

    public String getOrganization(){
    	return organization;
    }

    public String getEmailAddress(){
    	return emailAddress;
    }
    
    public PhoneNumbers getMobilePhoneNumbers(){
    	return mobilePhoneNumbers;
    }

    public PhoneNumbers getHomePhoneNumbers(){
    	return homePhoneNumbers;
    }

    public PhoneNumbers getWorkPhoneNumbers(){
    	return workPhoneNumbers;
    }

    public void setName(String name){
    	this.name = name;
    }

    public void setGroup(String group){
    	this.group = group;
    }

    public void setOccupation(String occupation){
    	this.occupation = occupation;
    }

    public void setResidence(String residence){
    	this.residence = residence;
    }

    public void setAddress(String address){
    	this.address = address;
    }

    public void setOrganization(String organization){
    	this.organization = organization;
    }

    public void setEmailAddress(String emailAddress){
    	this.emailAddress = emailAddress;
    }
    
    public void setMobilePhoneNumbers(PhoneNumbers mobilePhoneNumbers){
    	this.mobilePhoneNumbers = mobilePhoneNumbers;
    }

    public void setHomePhoneNumbers(PhoneNumbers homePhoneNumbers){
    	this.homePhoneNumbers = homePhoneNumbers;
    }

    public void setWorkPhoneNumbers(PhoneNumbers workPhoneNumbers){
    	this.workPhoneNumbers = workPhoneNumbers;
    }

    public String toString(){
    	String s = "";
    	String t = "";
    	String u = "";
    	if (name==null || name.length()<1) return "";
    	
    	//s = name + "^" + (group==null?"":group) + "^" + (occupation==null?"":occupation) + "^" + (residence==null?"":residence) + "^" + (address==null?"":address) + "^" + (organization==null?"":organization) + "^" + (emailAddress==null?"":emailAddress) + "^";
    	s = removeReservedSymbol(name) + "^" + "雲端" + "^" + removeReservedSymbol(occupation) + "^" + removeReservedSymbol(residence) + "^" + removeReservedSymbol(address) + "^" + removeReservedSymbol(organization) + "^" + removeReservedSymbol(emailAddress) + "^";

    	if (mobilePhoneNumbers!=null) t = mobilePhoneNumbers.toString("1");

		if (homePhoneNumbers!=null){
	    	u = homePhoneNumbers.toString("2");
	    	if (u.length()>0) t += u;
    	}

		if (workPhoneNumbers!=null){
	    	u = workPhoneNumbers.toString("3");
	    	if (u.length()>0) t += u;
    	}

    	s += t;
    	return s;
    }

}

public class PhoneNumbers {
	private List<String> phoneNumberList;

    public PhoneNumbers() {
    	//writeLog("debug", "in new PhoneNumbers");
    	this.phoneNumberList = new ArrayList<String>();
    	//writeLog("debug", "in2 new PhoneNumbers");
    }

    public void addPhoneNumber(String phoneNumber) {
        this.phoneNumberList.add(phoneNumber);
    }
    
    public String[] getPhoneNumberList(){
    	return phoneNumberList.toArray(new String[0]);
    }
    
    public int getPhoneNumberCount(){
    	if (phoneNumberList==null) return 0;
    	return phoneNumberList.size();
    }
    
    public String toString(String type){
    	String s = "";
    	if (phoneNumberList!=null && phoneNumberList.size()>0){
	    	String[] a = phoneNumberList.toArray(new String[0]);
    		for (int i=0;i<a.length;i++){
    			s += removeReservedSymbol(a[i]) + type + ";";
    		}
    	}
    	return s;
    }
    
}

private String removeReservedSymbol(String sOrig){
	if (sOrig==null || sOrig.length()<1) return "";
	String s = sOrig;
	s = s.replaceAll("\\^", "");
	s = s.replaceAll("\\|", "");
	s = s.replaceAll(";", "");
	return s;
}
%>