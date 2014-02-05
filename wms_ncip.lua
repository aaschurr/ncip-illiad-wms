--About NCIP_Addon
--
--Author:  Bill Jones III, SUNY Geneseo, IDS Project, jonesw@geneseo.edu
--Some Modifications by:  Lauren Magnuson, California State University Nothridge, lauren.magnuson@csun.edu
--System Addon used for ILLiad to communicate with WMS through NCIP protocol
--
--Description of Registered Event Handlers for ILLiad
--
--BorrowingRequestCheckedInFromLibrary 
--This will trigger whenever a non-cancelled transaction is processed from the Check In From Lending Library 
--batch processing form using the Check In, Check In Scan Now, or Check In Scan Later buttons.
--
--BorrowingRequestCheckedInFromCustomer
--This will trigger whenever an item is processed from the Check Item In batch processing form, 
--regardless of its status (such as if it were cancelled or never picked up by the customer).
--
--LendingRequestCheckOut
--This will trigger whenever a transaction is processed from the Lending Update Stacks Searching form 
--using the Mark Found or Mark Found Scan Now buttons. This will also work on the Lending Processing ribbon
--of the Request form for the Mark Found and Mark Found Scan Now buttons.
--
--LendingRequestCheckIn
--This will trigger whenever a transaction is processed from the Lending Returns batch processing form.

--[[Workflow
Receive Request; check availability, accept request, print pull slip, get call number location, pull from the shelf
pull sheet has the mailing address; only if in hand finalize the process in ILLiad; move it from in-stack searching
to "Item Found"; at that point the checkout is pushed to WMS; some kind of feedback message to indicate whether the request was successful--]] 


--local Settings = {};
--Change the way that Borrowing Libraries are noted in Aleph
--Borrowing Libraries will need to be pre-loaded into Aleph to match their borrowed item to their account
--Settings.Use_Borrowing_Barcodes = GetSetting("Use_Borrowing_Barcodes");
--Settings.Use_Lender_String = GetSetting("Use_Lender_String");
--Settings.Use_ILL_for_Library = GetSetting("Use_ILL_for_Library");

--Change Prefix Settings for Transactions
Settings.Use_Prefixes = GetSetting("Use_Prefixes");
Settings.Prefix_for_LibraryUseOnly = GetSetting("Prefix_for_LibraryUseOnly");
Settings.Prefix_for_RenewablesAllowed = GetSetting("Prefix_for_RenewablesAllowed");
Settings.Prefix_for_LibraryUseOnly_and_RenewablesAllowed = GetSetting("Prefix_for_LibraryUseOnly_and_RenewablesAllowed");

--NCIP Responder URL
Settings.NCIP_Responder_URL = GetSetting("NCIP_Responder_URL");

--Global variables for Testing
FromAgencyId = 129479;
--ToAngecyId must always match FromAgencyId
ToAgencyId = 129479;
UserAgency = 128807;
--UserId will always be the same - ILL Office account
--Settings.checkInItem = GetSetting("Users.UserName");




--checkInItem settings
--Settings.checkInItem_from_uniqueAgency_value = GetSetting("checkInItem_from_uniqueAgency_value");
checkInItem_from_uniqueAgency_value = 129479;
--Settings.checkInItem_to_uniqueAgency_value = GetSetting("checkInItem_to_uniqueAgency_value");
checkInItem_to_uniqueAgency_value  = 129479;
--Settings.checkInItem_uniqueItem_agency_value = GetSetting("checkInItem_uniqueItem_agency_value");
--WMS Registry ID to whom you are checking out the item
checkInItem_uniqueItem_agency_value = 128807;


--checkOutItem settings
--Settings.checkOutItem_from_uniqueAgency_value = GetSetting("checkOutItem_from_uniqueAgency_value");
--this is the main branch of the WMS library
checkOutItem_from_uniqueAgency_value = 129479;
--Settings.checkOutItem_to_uniqueAgency_value = GetSetting("checkOutItem_to_uniqueAgency_value");
--this is the main branch of the WMS library
checkOutItem_to_uniqueAgency_value = 129479;
--Settings.checkOutItem_uniqueUser_agency_value = GetSetting("checkOutItem_uniqueUser_agency_value");
--Store institution IDs in the ArielAddress field?
--Settings.UserAgency = GetSetting("LenderAddresses.ArielAddress");
--this is the WMS registry ID of the lender
checkOutItem_uniqueUser_agency_value = 128807;
--Settings.checkOutItem_uniqueItem_agency_value = GetSetting("checkOutItem_uniqueItem_agency_value");
checkOutItem_uniqueItem_agency_value = 128807;
--ItemIdValue = GetSetting("Transactions.ItemNumber");
--ItemBarcode
--Settings.checkOutItem_uniqueRequest_agency_value
checkOutItem_uniqueRequest_agency_value = 10176;


function Init()
	--RegisterSystemEventHandler("BorrowingRequestCheckedInFromLibrary", "BorrowingAcceptItem");
	--RegisterSystemEventHandler("BorrowingRequestCheckedInFromCustomer", "BorrowingCheckInItem");
	RegisterSystemEventHandler("LendingRequestCheckOut", "LendingCheckOutItem");
	RegisterSystemEventHandler("LendingRequestCheckIn", "LendingCheckInItem");
end



--Lending

function LendingCheckOutItem(transactionProcessedEventArgs)
	LogDebug("DEBUG -- BorrowingRequestCheckedInFromLibrary handler called.");
	LogDebug("TN: " .. transactionProcessedEventArgs.TransactionNumber);
	LogDebug("Type: " .. transactionProcessedEventArgs.RequestType:ToString());

	local checkOutItem = buildCheckOutItem();
	--value return is coi
	
		local results = '';
		luanet.load_assembly("System");
        WebClient = luanet.import_type("System.Net.WebClient");
        StreamReader = luanet.import_type("System.IO.StreamReader");
        myWebClient = WebClient();
        myStream = myWebClient.UploadValues(Settings.NCIP_Responder_URL, "POST", checkOutItem);
        sr = StreamReader(myStream);
        results = sr:ReadToEnd();
		LogDebug(results);
        myStream:Close();
		return results;
end

function LendingCheckInItem(transactionProcessedEventArgs)
	LogDebug("DEBUG -- LendingRequestCheckIn handler called.");
	LogDebug("TN: " .. transactionProcessedEventArgs.TransactionNumber);
	LogDebug("Type: " .. transactionProcessedEventArgs.RequestType:ToString());

	local lendCheckInItem = buildCheckInItem();
	
		local results = '';
		luanet.load_assembly("System");
        WebClient = luanet.import_type("System.Net.WebClient");
        StreamReader = luanet.import_type("System.IO.StreamReader");
        myWebClient = WebClient();
        myStream = myWebClient.UploadValues(Settings.NCIP_Responder_URL, "POST", lendCheckInItem);
        sr = StreamReader(myStream);
        results = sr:ReadToEnd();
		LogDebug(results);
        myStream:Close();
		return results;
end
 

--ReturnedItem XML Builder for Borrowing (Patron Returns) and Lending (Library Returns)
function buildCheckInItem()
--define the barcode?
--Transactions.ItemNumber;
local ttype = ''
local trantype = GetFieldValue("Transaction", "RequestType");
	if trantype = "Loan" then
		local ttype = GetFieldValue("Transaction", "TransactionNumber");		
	else if trantype = "Article"
		local ttype = GetFieldValue("Transaction", "ReferenceNumber");
	else
		local ttype = GetFieldValue("Transaction", "TransactionNumber");
	end


--CheckIn XML Builder Modified for WMS
local ci = '';
	ci = ci .. '<NCIPMessage xmlns="http://www.niso.org/2008/ncip" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ncip="http://www.niso.org/2008/ncip" xsi:schemaLocation="http://www.niso.org/2008/ncip" http://www.niso.org/schemas/ncip/v2_01/ncip_v2_01.xsd" ncip:version="http://www.niso.org/schemas/ncip/v2_01/ncip_v2_01.xsd">'
	ci = ci .. '<CheckInItem>'
	ci = ci .. '<InitiationHeader>'
	ci = ci .. '<FromAgencyId>'
	ci = ci .. '<AgencyId ncip:Scheme="http://oclc.org/ncip/schemes/agencyid.scm">'.. checkInItem_from_uniqueAgency_value .. '</AgencyId>'
	ci = ci .. '</FromAgencyId>'
	ci = ci .. '<ToAgencyId>'
	ci = ci .. '<AgencyId>'.. checkInItem_to_uniqueAgency_value .. '</AgencyId>'
	ci = ci .. '</AgencyId>'
	ci = ci .. '</ToAgencyId>'
	ci = ci .. '<ApplicationProfileType ncip:Scheme="http://oclc.org/ncip/schemes/application-profile/platform.scm"> Version 2011 </ApplicationProfileType>' 
    ci = ci .. '</InitiationHeader>'
    ci = ci .. '<ItemId>'
    ci = ci .. '<AgencyId>'.. checkInItem_uniqueItem_agency_value..'</AgencyId>'
    ci = ci .. '<ItemIdentifierValue>'.. ttype .. '</ItemIdentifierValue>'
    ci = ci .. '</ItemId>'
	ci = ci .. '</UniqueItemId>'
	ci = ci .. '</CheckInItem>'
	ci = ci .. '</NCIPMessage>'
	return ci;
end

--CheckOut XML Builder Modified for WMS
function buildCheckOutItem()
  local coi = '';
  --local pseudopatron = GetFieldValue("Transaction", "LenderString");
  local pseudopatron = 98562587;
	coi = coi ..'<NCIPMessage ncip:version="http://www.niso.org/schemas/ncip/v2_01/ncip_v2_01.xsd" xmlns="http://www.niso.org/2008/ncip" xmlns:ncip="http://www.niso.org/2008/ncip" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.niso.org/2008/ncip http://www.niso.org/schemas/ncip/v2_01/ncip_v2_01.xsd">'
	coi = coi ..'<CheckOutItem>'
	coi = coi ..'<InitiationHeader>'
	coi = coi ..'<FromAgencyId>'
	coi = coi ..'<AgencyId ncip:Scheme="http://oclc.org/ncip/schemes/agencyid.scm">' .. checkOutItem_from_uniqueAgency_value .. '</AgencyId>'
	coi = coi ..'</FromAgencyId>'
	coi = coi ..'<ToAgencyId>' 
	coi = coi ..'<AgencyId>' .. checkOutItem_to_uniqueAgency_value .. '</AgencyId>'
	coi = coi ..'</ToAgencyId>'
	coi = coi ..'<ApplicationProfileType ncip:Scheme="http://oclc.org/ncip/schemes/application-profile/platform.scm"> Version 2011 </ApplicationProfileType>'  
	coi = coi ..'</InitiationHeader>'	
	coi = coi ..'<UserId>'  
  coi = coi ..'<AgencyId>' .. checkOutItem_uniqueUser_agency_value .. '</AgencyId>'
  coi = coi ..'<UserIdentifierValue>' .. pseudopatron .. '</UserIdentifierValue>'  
  coi = coi ..'</UserId>'
	coi = coi ..'<ItemId>'
	coi = coi ..'<AgencyId>' .. checkOutItem_uniqueItem_agency_value .. '</AgencyId>'
	coi = coi ..'<ItemIdentifierValue>' .. checkOutItem_uniqueRequest_agency_value .. '</ItemIdentifierValue>'
	coi = coi ..'</ItemId>' 
  coi = coi ..'</CheckOutItem>'
	coi = coi ..'</NCIPMessage>'
	return coi;
end


